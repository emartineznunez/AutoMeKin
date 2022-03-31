from abc import ABCMeta, abstractmethod
import numpy as np
from numpy.random import standard_normal
from ase import units


class MDIntegrator:

    def __init__(self, forces, velocity, mol):
        self.mol = mol
        self.masses = mol.get_masses()
        self.forces = forces
        self.oldForces = forces
        self.currentVel = velocity
        self.HalfVel = velocity
        self.oldVel = velocity
        self.pos = mol.get_positions()
        self.oldPos = mol.get_positions()
        self.currentPos = mol.get_positions()
        self.newPos = mol.get_positions()


    @abstractmethod
    def mdStep(self, forces, timestep, mol):
        pass


class VelocityVerlet(MDIntegrator):

    #This method returns the new positions after a single md timestep
    @abstractmethod
    def mdStepPos(self, forces, timestep, mol):

        self.forces = forces

         #Get Acceleration from masses and forces
        accel = self.forces[:] / self.masses[:,None]

        # keep track of position prior to update in case we need to revert
        self.oldPos = self.currentPos

        # Then get the next half step velocity and update the position.
        # NB currentVel is one full MD step behind currentPos
        self.HalfVel = self.currentVel + accel * timestep * 0.5
        self.currentPos = self.currentPos + (self.HalfVel * timestep)

        # Return positions
        mol.set_positions(self.currentPos)

    def mdStepVel(self, forces, timestep, mol):

        #Store forces from previous step and then update
        self.oldForces = self.forces
        self.forces = forces

        # Store old velocities
        self.oldVel = self.currentVel

         #Get Acceleration from masses and forces
        accel = self.forces[:] / self.masses[:,None]

        #Use recent half velocity to update the velocities
        self.currentVel = self.HalfVel + ( accel * timestep * 0.5 )
     

        # Return positions
        mol.set_velocities(self.currentVel)


class Langevin(MDIntegrator):

    def __init__(self, temperature, friction, forces, velocity, mol,timestep):
        self.friction = friction
        self.temp = temperature
        # Get coefficients
        super(Langevin,self).__init__(forces, velocity, mol)
        self.sigma = np.sqrt(2 * self.temp * self.friction / self.masses)
        self.c1 = timestep / 2. - timestep * timestep * self.friction / 8.
        self.c2 = timestep * self.friction / 2 - timestep * timestep * self.friction * self.friction / 8.
        self.c3 = np.sqrt(timestep) * self.sigma / 2. - timestep**1.5 * self.friction * self.sigma / 8.
        self.c5 = timestep**1.5 * self.sigma / (2 * np.sqrt(3))
        self.c4 = self.friction / 2. * self.c5

            #This method returns the new positions after a single md timestep
    @abstractmethod
    def mdStepPos(self, forces, timestep, mol):

        self.forces = forces

         #Get Acceleration from masses and forces
        accel = self.forces[:] / self.masses[:,None]

        # keep track of position prior to update in case we need to revert
        self.oldPos = self.currentPos

        # Get two normally distributed variables
        self.xi = standard_normal(size=(len(self.masses), 3))
        self.eta = standard_normal(size=(len(self.masses), 3))

        # Then get the next half step velocity and update the position.
        # NB currentVel is one full MD step behind currentPos
        self.HalfVel = self.currentVel + (self.c1 * accel - self.c2 * self.HalfVel + self.c3[:,None] * self.xi - self.c4[:,None] * self.eta)
        self.currentPos = self.currentPos + timestep * self.HalfVel + self.c5[:,None] * self.eta

        # Return positions
        mol.set_positions(self.currentPos)

    def mdStepVel(self, forces, timestep, mol,damped):

        #Store forces from previous step and then update
        self.oldForces = self.forces
        self.forces = forces

        # Store old velocities
        self.oldVel = self.currentVel

         #Get Acceleration from masses and forces
        accel = self.forces[:] / self.masses[:,None]

        #Use recent half velocity to update the velocities
        self.currentVel = self.HalfVel + (self.c1 * accel - self.c2 * self.HalfVel + self.c3[:,None] * self.xi - self.c4[:,None] * self.eta)

        if damped: self.currentVel = self.currentVel * 0.01

        # Return positions
        mol.set_velocities(self.currentVel)

