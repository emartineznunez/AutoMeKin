from abc import ABCMeta, abstractmethod
import numpy as np
from numpy.random import standard_normal
from ase import units


# Class to track constraints and calculate required derivatives
# Inversion procedure occurs in MDintegrator class
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
        self.constrained = True


    @abstractmethod
    def constrain(self, del_phi):
        pass

    @abstractmethod
    def constrain2(self, del_phi1, del_phi2):
        pass

    @abstractmethod
    def mdStep(self, forces, timestep, mol):
        pass


class VelocityVerlet(MDIntegrator):

    # Modify the stored velocities to satisfy a single BXD constraint
    @abstractmethod
    def constrain(self, del_phi):

        # Revert positions and forces to time prior to BXD inversion
        self.currentPos = self.oldPos
        self.currentVel = self.oldVel
        self.forces = self.oldForces

        # Temporarily flatten 3 by n matrices into vectors to get dot products.
        a = ((np.tile(self.masses, (3, 1))).transpose()).flatten()
        b = del_phi.flatten()
        c = self.currentVel.flatten()

        # Get Lagrangian constraint
        lamb =  (-2.0 * np.vdot(b,c)) / np.vdot(b , (b * (1 / a)))

        # Modify velocities
        self.currentVel = self.currentVel + ( lamb * del_phi * (1/self.masses)[:,None])
        self.constrained = True

    @abstractmethod
    def constrain2(self, del_phi1, del_phi2):

        # Revert positions and forces to time prior to BXD inversion
        self.currentPos = self.oldPos
        self.currentVel = self.oldVel
        self.forces = self.oldForces

        # Temporarily flatten 3 by n matrices into vectors to get dot products.
        a = ((np.tile(self.masses, (3, 1))).transpose()).flatten()
        b = np.flatten(del_phi1)
        c = np.flatten(del_phi2)
        d = np.flatten(self.currentVel)

        # In the two constraint case the simulataneous equations can be solved analytically. This should be gneralised in the future
        # Here we save the various coefficients from the various permuations of dot products containing the two constraints
        c1 = np.vdot(b,(b * (1 / a)))
        c2 = np.vdot(b,(c * (1 / a)))
        c3 = np.vdot(c,(b * (1 / a)))
        c4 = np.vdot(c,(c * (1 / a)))
        c5 = np.vdot(b,d)
        c6 = np.vdot(c,d)

        lamb2 = (( c3 * c4) - ( c1 * c6 ))/(( c2 * c3 ) - ( c1 * c4 ))
        lamb1 = (c3 - lamb2 * c2) / c1


        # Update velocities
        self.currentVel = self.currentVel + ( lamb1 * del_phi1 * ( 1 / self.masses[:,None] ) ) + ( lamb2 * del_phi2 * ( 1 / self.masses[:,None] ) )
        self.constrained = True

    #This method returns the new positions after a single md timestep
    @abstractmethod
    def mdStepPos(self, forces, timestep, mol):

        # If we have been constrined then forces have already been reset
        # Otherwise store foces provided to function
        if self.constrained:
            self.constrained = False
        else:
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

        # Modify the stored velocities to satisfy a single BXD constraint
    @abstractmethod
    def constrain(self, del_phi):

        # Revert positions and forces to time prior to BXD inversion
        self.currentPos = self.oldPos
        self.currentVel = self.oldVel
        self.forces = self.oldForces


        # Temporarily flatten 3 by n matrices into vectors to get dot products.
        a = ((np.tile(self.masses, (3, 1))).transpose()).flatten()
        b = del_phi.flatten()
        c = self.currentVel.flatten()

        # Get Lagrangian constraint
        lamb =  (-2.0 * np.vdot(b,c)) / np.vdot(b , (b * (1 / a)))


        # Update velocities
        self.currentVel = self.currentVel + ( lamb * del_phi * (1/self.masses)[:,None])
        self.constrained = True

    @abstractmethod
    def constrain2(self, del_phi1, del_phi2):

        # Revert positions and forces to time prior to BXD inversion
        self.currentPos = self.oldPos
        self.currentVel = self.oldVel
        self.forces = self.oldForces

        # Temporarily flatten 3 by n matrices into vectors to get dot products.
        a = ((np.tile(self.masses, (3, 1))).transpose()).flatten()
        b = np.flatten(del_phi1)
        c = np.flatten(del_phi2)
        d = np.flatten(self.currentVel)

        # In the two constraint case the simulataneous equations can be solved analytically. This should be gneralised in the future
        # Here we save the various coefficients from the various permuations of dot products containing the two constraints
        c1 = np.vdot(b,(b * (1 / a)))
        c2 = np.vdot(b,(c * (1 / a)))
        c3 = np.vdot(c,(b * (1 / a)))
        c4 = np.vdot(c,(c * (1 / a)))
        c5 = np.vdot(b,d)
        c6 = np.vdot(c,d)

        lamb2 = (( c3 * c4) - ( c1 * c6 ))/(( c2 * c3 ) - ( c1 * c4 ))
        lamb1 = (c3 - lamb2 * c2) / c1


        # Update velocities
        self.currentVel = self.currentVel + ( lamb1 * del_phi1 * ( 1 / self.masses[:,None] ) ) + ( lamb2 * del_phi2 * ( 1 / self.masses[:,None] ))

        # Let MDstep method know a constraint has occured and not to update the forces
        self.constrained = True

            #This method returns the new positions after a single md timestep
    @abstractmethod
    def mdStepPos(self, forces, timestep, mol):

        # If we have been constrined then forces have already been reset
        # Otherwise store foces provided to function
        if self.constrained:
            self.constrained = False
        else:
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

    def mdStepVel(self, forces, timestep, mol):

        #Store forces from previous step and then update
        self.oldForces = self.forces
        self.forces = forces

        # Store old velocities
        self.oldVel = self.currentVel

         #Get Acceleration from masses and forces
        accel = self.forces[:] / self.masses[:,None]

        #Use recent half velocity to update the velocities
        self.currentVel = self.HalfVel + (self.c1 * accel - self.c2 * self.HalfVel + self.c3[:,None] * self.xi - self.c4[:,None] * self.eta)

        # Return positions
        mol.set_velocities(self.currentVel)

