---
title: Kinetics section
layout: home
parent: Input files
grand_parent: Tutorial
nav_order: 4
---

# Kinetics 

This part is employed to provide details for the kinetics calculations at the $\scriptstyle{(}$experimental$\scriptstyle{)}$
conditions you want to simulate. _This section is compulsory except for association_.

An example is given as follows.
```
--Kinetics--
Energy 150
```
The kinetics simulations will be carried out for a canonical, fixed temperature, or microcanonical, fixed
energy, ensemble, which have their associated keywords:

List of `Keyword value(s)` for this section:

{: .important }   
`Energy value`   
[`value` is an integer; default value: `0` ]   
`value` is the energy in kcal/mol for which microcanonical rate coefficients will be calculated.

{: .important }   
`Temperature value`   
[`value` is an integer; default value: `298`]   
`value` is the temperature in K for which thermal rate coefficients will be calculated. At present, only
temperatures in the range 100 - 9999 K are allowed.
