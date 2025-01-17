# Microphysics 1M

The `Microphysics1M.jl` module describes a 1-moment bulk parameterization of
  cloud microphysical processes.
The module is based on the ideas of
  [Kessler1995](@cite),
  [Grabowski1998](@cite)
  and [Kaul2015](@cite).

The cloud microphysics variables are expressed as specific humidities:
  - `q_tot` - total water specific humidity,
  - `q_vap` - water vapor specific humidity,
  - `q_liq` - cloud water specific humidity,
  - `q_ice` - cloud ice specific humidity,
  - `q_rai` - rain specific humidity,
  - `q_sno` - snow specific humidity.

## Assumed particle size relationships

Particles are assumed to follow power-law relationships involving the mass(radius),
denoted by ``m(r)``, the cross section(radius), denoted by ``a(r)``, and the
terminal velocity(radius), denoted by ``v_{term}(r)``, respectively.
The coefficients are defined in the
  [CLIMAParameters.jl](https://github.com/CliMA/CLIMAParameters.jl) package
  and are shown in the table below.
For rain and ice they correspond to spherical liquid water drops
  and ice particles, respectively.
There is no assumed particle shape for snow, and the relationships are
  empirical.

```math
m(r) = \chi_m \, m_0 \left(\frac{r}{r_0}\right)^{m_e + \Delta_m}
```
```math
a(r) = \chi_a \, a_0 \left(\frac{r}{r_0}\right)^{a_e + \Delta_a}
```
```math
v_{term}(r) = \chi_v \, v_0 \left(\frac{r}{r_0}\right)^{v_e + \Delta_v}
```
where:
 - ``r`` is the particle radius,
 - ``r_0`` is the typical particle radius used to nondimensionalize,
 - ``m_0, \, m_e, \, a_0, \, a_e, \, v_0, \, v_e \,`` are the default
   coefficients,
 - ``\chi_m``, ``\Delta_m``, ``\chi_a``, ``\Delta_a``, ``\chi_v``, ``\Delta_v``
   are the coefficients that can be used during model calibration to expand
   around the default values.
   Without calibration all ``\chi`` parameters are set to 1
   and all ``\Delta`` parameters are set to 0.

The above coefficients, similarly to all other microphysics parameters,
  are not hardcoded in the final microphysics parameterizations.
The goal is to allow easy flexibility when calibrating the scheme.
With that said, the assumption about the shape of the particles is used three
  times when deriving the microphysics formulae:
 - The mass transfer equation (\ref{eq:mass_rate}) used in snow autoconversion,
   rain evaporation, snow sublimation and snow melt rates is derived assuming
   spherical particle shapes. To correct for non-spherical shape it should be
   multiplied by a function of the particle aspect ratio.
 - The geometric collision kernel used for deriving rain-snow accretion rate
   assumes that both colliding particles are spherical.
   It does not take into account the reduced cross-section of snow particles
   that is used when modeling snow - cloud liquid water
   and snow - cloud ice accretion.
 - In the definition of the Reynolds number that is used when computing
   ventilation factors.

|    symbol     |         definition                      | units           | default value                                   | reference |
|---------------|-----------------------------------------|-----------------|-------------------------------------------------|-----------|
|``r_0^{rai}``  | typical rain drop radius                | ``m``           | ``10^{-3} ``                                    |           |
|``m_0^{rai}``  | coefficient in ``m(r)`` for rain        | ``kg``          | ``\frac{4}{3} \, \pi \, \rho_{water} \, r_0^3`` |           |
|``m_e^{rai}``  | exponent in ``m(r)`` for rain           | -               | ``3``                                           |           |
|``a_0^{rai}``  | coefficient in ``a(r)`` for rain        | ``m^2``         | ``\pi \, r_0^2``                                |           |
|``a_e^{rai}``  | exponent in ``a(r)`` for rain           | -               | ``2``                                           |           |
|``v_e^{rai}``  | exponent in ``v_{term}(r)`` for rain    | -               | ``0.5``                                         |           |
|               |                                         |                 |                                                 |           |
|``r_0^{ice}``  | typical ice crystal radius              | ``m``           | ``10^{-5} ``                                    |           |
|``m_0^{ice}``  | coefficient in ``m(r)`` for ice         | ``kg``          | ``\frac{4}{3} \, \pi \, \rho_{ice} \, r_0^3``   |           |
|``m_e^{ice}``  | exponent in ``m(r)`` for ice            | -               | ``3``                                           |           |
|               |                                         |                 |                                                 |           |
|``r_0^{sno}``  | typical snow crystal radius             | ``m``           | ``10^{-3} ``                                    |           |
|``m_0^{sno}``  | coefficient in ``m(r)`` for snow        | ``kg``          | ``0.1 \,  r_0^2``                               | eq (6b) [Grabowski1998](@cite) |
|``m_e^{sno}``  | exponent in ``m(r)`` for snow           | -               | ``2``                                           | eq (6b) [Grabowski1998](@cite) |
|``a_0^{sno}``  | coefficient in ``a(r)`` for snow        | ``m^2``         | ``0.3 \pi \, r_0^2``                            | ``\alpha`` in eq(16b) [Grabowski1998](@cite).|
|``a_e^{sno}``  | exponent in ``a(r)`` for snow           | -               | ``2``                                           |           |
|``v_0^{sno}``  | coefficient in ``v_{term}(r)`` for snow | ``\frac{m}{s}`` | ``2^{9/4} r_0^{1/4}``                           | eq (6b) [Grabowski1998](@cite) |
|``v_e^{sno}``  | exponent in ``v_{term}(r)`` for snow    | -               | ``0.25``                                        | eq (6b) [Grabowski1998](@cite) |

where:
 - ``\rho_{water}`` is the density of water,
 - ``\rho_{ice}`` is the density of ice.

The terminal velocity of an individual rain drop is defined by the balance
  between the gravitational acceleration (taking into account
  the density difference between water and air) and the drag force.
Therefore the ``v_0^{rai}`` is defined as
```math
\begin{equation}
v_0^{rai} =
  \left(
    \frac{8}{3 \, C_{drag}} \left( \frac{\rho_{water}}{\rho} -1 \right)
  \right)^{1/2} (g r_0^{rai})^{1/2}
\label{eq:vdrop}
\end{equation}
```
where:
 - ``g`` is the gravitational acceleration,
 - ``C_{drag}`` is the drag coefficient,
 - ``\rho`` is the density of air.

!!! note

    It would be great to replace the above simple power laws
    with more accurate relationships.
    For example:
    [Khvorostyanov2002](@cite)
    or
    [Karrer2020](@cite)

## Assumed particle size distributions

The particle size distributions are assumed to follow
  Marshall-Palmer distribution
  [Marshall1948](@cite)
  eq. 1:
```math
\begin{equation}
  n(r) = n_{0} exp\left(- \lambda \, r \right)
\end{equation}
```
where:
 - ``n_{0}`` and ``\lambda`` are the Marshall-Palmer distribution parameters.

The ``n_0`` for rain and ice is assumed constant.
The ``n_0`` for snow is defined as
```math
\begin{equation}
  n_0^{sno} = \mu^{sno} \left(\frac{\rho}{\rho_0} q_{sno}\right)^{\nu^{sno}}
\end{equation}
```
where:
 - ``\mu^{sno}`` and ``\nu^{sno}`` are the coefficients
 - ``\rho_0`` is the typical air density used to nondimensionalize the equation
   and is equal to ``1 \, kg/m^3``

The coefficients are defined in
  [CLIMAParameters.jl](https://github.com/CliMA/CLIMAParameters.jl)
package and are shown in the table below.

|    symbol       |         definition                           | units              | default value                             | reference  |
|-----------------|----------------------------------------------|--------------------|-------------------------------------------|------------|
|``n_{0}^{rai}``  | rain drop size distribution parameter        | ``\frac{1}{m^4}``  | ``16 \cdot 10^6``                         | eq (2) [Marshall1948](@cite) |
|``n_{0}^{ice}``  | cloud ice size distribution parameter        | ``\frac{1}{m^4}``  | ``2 \cdot 10^7``                          | bottom of page 4396 [Kaul2015](@cite) |
|``\mu^{sno}``    | snow size distribution parameter coefficient | ``\frac{1}{m^4}``  | ``4.36 \cdot 10^9 \, \rho_0^{\nu^{sno}}`` | eq (A1) [Kaul2015](@cite) |
|``\nu^{sno}``    | snow size distribution parameter exponent    | ``-``              | ``0.63``                                  | eq (A1) [Kaul2015](@cite) |

The ``\lambda`` parameter is defined as
```math
\begin{equation}
\lambda =
  \left(
    \frac{ \Gamma(m_e + \Delta_m + 1) \, \chi_m \, m_0 \, n_0}
         {q \, \rho \, (r_0)^{m_e + \Delta_m}}
  \right)^{\frac{1}{m_e + \Delta_m + 1}}
\end{equation}
```
where:
 - ``q`` is rain, snow or ice specific humidity
 - ``\chi_m``, ``m_0``, ``m_e``, ``\Delta_m``, ``r_0``, and ``n_0``
   are the corresponding mass(radius) and size distribution parameters
 - ``\Gamma()`` is the gamma function

The cloud-ice size distribution is used
  when computing snow autoconversion rate and rain sink due to accretion.
In other derivations cloud ice, similar to cloud liquid water,
  is treated as continuous.

!!! note
     - Do we want to keep the ``n_0`` for rain constant
       and ``n_0`` for snow empirical?

     - Do we want to test different size distributions?

## Parameterized processes

Parameterized processes include:
  - autoconversion of rain and snow,
  - accretion,
  - evaporation of rain water,
  - sublimation, vapor deposition and melting of snow,
  - sedimentation of rain and snow with mass weighted average terminal velocity
    (cloud water and cloud ice are part of the working fluid and
    do not sediment).

Parameters used in the parameterization are defined in
  [CLIMAParameters.jl](https://github.com/CliMA/CLIMAParameters.jl) package.
They consist of:

|    symbol                  |         definition                                        | units                    | default value          | reference |
|----------------------------|-----------------------------------------------------------|--------------------------|------------------------|-----------|
|``C_{drag}``                | rain drop drag coefficient                                | -                        | ``0.55``               | ``C_{drag}`` is such that the mass averaged terminal velocity is close to [Grabowski1996](@cite) |
|``\tau_{acnv\_rain}``       | cloud liquid to rain water autoconversion timescale       | ``s``                    | ``10^3``               | eq (5a) [Grabowski1996](@cite) |
|``\tau_{acnv\_snow}``       | cloud ice to snow autoconversion timescale                | ``s``                    | ``10^2``               |           |
|``q_{liq\_threshold}``      | cloud liquid to rain water autoconversion threshold       | -                        | ``5 \cdot 10^{-4}``    | eq (5a) [Grabowski1996](@cite) |
|``q_{ice\_threshold}``      | cloud ice snow autoconversion threshold                   | -                        | ``1 \cdot 10^{-6}``    |           |
|``r_{is}``                  | threshold particle radius between ice and snow            | ``m``                    | ``62.5 \cdot 10^{-6}`` | abstract [Harrington1995](@cite) |
|``E_{lr}``                  | collision efficiency between rain drops and cloud droplets| -                        | ``0.8``                | eq (16a) [Grabowski1998](@cite) |
|``E_{ls}``                  | collision efficiency between snow and cloud droplets      | -                        | ``0.1``                | Appendix B [Rutledge1983](@cite) |
|``E_{ir}``                  | collision efficiency between rain drops and cloud ice     | -                        | ``1``                  | Appendix B [Rutledge1984](@cite) |
|``E_{is}``                  | collision efficiency between snow and cloud ice           | -                        | ``0.1``                | bottom page 3649 [Morrison2008](@cite) |
|``E_{rs}``                  | collision efficiency between rain drops and snow          | -                        | ``1``                  | top page 3650 [Morrison2008](@cite) |
|``a_{vent}^{rai}, b_{vent}^{rai}`` | rain drop ventilation factor coefficients          | -                        | ``1.5 \;``,``\; 0.53`` | chosen such that at ``q_{tot}=15 g/kg`` and ``T=288K`` the evap. rate is close to empirical evap. rate in [Grabowski1996](@cite) |
|``a_{vent}^{sno}, b_{vent}^{sno}`` | snow ventilation factor coefficients               | -                        | ``0.65 \;``,``\; 0.44``| eq (A19) [Kaul2015](@cite) |
|``K_{therm}``               | thermal conductivity of air                               | ``\frac{J}{m \; s \; K}``| ``2.4 \cdot 10^{-2}``  |           |
|``\nu_{air}``               | kinematic viscosity of air                                | ``\frac{m^2}{s}``        | ``1.6 \cdot 10^{-5}``  |           |
|``D_{vapor}``               | diffusivity of water vapor                                | ``\frac{m^2}{s}``        | ``2.26 \cdot 10^{-5}`` |           |

## Ventilation factor

The ventilation factor parameterizes the increase in the mass and heat exchange
  for falling particles.
Following [SeifertBeheng2006](@cite)
  eq. 24  the ventilation factor is defined as:
```math
\begin{equation}
  F(r) = a_{vent} + b_{vent}  N_{Sc}^{1/3} N_{Re}(r)^{1/2}
\label{eq:ventil_factor}
\end{equation}
```
where:
 - ``a_{vent}``, ``b_{vent}`` are coefficients,
 - ``N_{Sc}`` is the Schmidt number,
 - ``N_{Re}`` is the Reynolds number of a falling particle.

The Schmidt number is assumed constant:
```math
N_{Sc} = \frac{\nu_{air}}{D_{vapor}}
```
where:
 - ``\nu_{air}`` is the kinematic viscosity of air,
 - ``D_{vapor}`` is the diffusivity of water.

The Reynolds number of a spherical drop is defined as:
```math
N_{Re} = \frac{2 \, r \, v_{term}(r)}{\nu_{air}}
```
Applying the terminal velocity(radius) relationship results in
```math
\begin{equation}
F(r) = a_{vent} +
       b_{vent} \,
       \left(\frac{\nu_{air}}{D_{vapor}}\right)^{\frac{1}{3}} \,
       \left(\frac{2 \, \chi_v \, v_0}
                  {r_0^{v_e + \Delta_v} \, \nu_{air}}\right)^{\frac{1}{2}} \,
       r^{\frac{v_e + \Delta_v + 1}{2}}
\label{eq:vent_factor}
\end{equation}
```

## Terminal velocity

The mass weighted terminal velocity ``v_t`` is defined following
[Ogura1971](@cite):
```math
\begin{equation}
  v_t = \frac{\int_0^\infty n(r) \, m(r) \, v_{term}(r) \, dr}
             {\int_0^\infty n(r) \, m(r) \, dr}
\label{eq:vt}
\end{equation}
```
Integrating over the assumed Marshall-Palmer distribution and using the
  ``m(r)`` and ``v_{term}(r)`` relationships results in
```math
\begin{equation}
  v_t = \chi_v \, v_0 \, \left(\frac{1}{r_0 \, \lambda}\right)^{v_e + \Delta_v}
        \frac{\Gamma(m_e + v_e + \Delta_m + \Delta_v + 1)}
             {\Gamma(m_e + \Delta_m + 1)}
\end{equation}
```

!!! note

    Assuming a constant drag coefficient is an approximation and it should
    be size and flow dependent, see for example
    [here](https://www1.grc.nasa.gov/beginners-guide-to-aeronautics/drag-of-a-sphere/).
    In general we should implement these terminal velocity parameterizations:
    [Khvorostyanov2002](@cite)
    or
    [Karrer2020](@cite)

## Rain autoconversion

Rain autoconversion defines the rate of conversion form cloud liquid water
  to rain water due to collisions between cloud droplets.
It is parameterized following
  [Kessler1995](@cite):

```math
\begin{equation}
  \left. \frac{d \, q_{rai}}{dt} \right|_{acnv} =
    \frac{max(0, q_{liq} - q_{liq\_threshold})}{\tau_{acnv\_rain}}
\end{equation}
```
where:
 - ``q_{liq}`` - liquid water specific humidity,
 - ``\tau_{acnv\_rain}`` - timescale,
 - ``q_{liq\_threshold}`` - autoconversion threshold.

!!! note
    This is the simplest possible autoconversion parameterization.
    It would be great to implement others and test the impact on precipitation.
    See for example
    [Wood2005](@cite)
    Table 1 for other simple choices.

## Snow autoconversion

Snow autoconversion defines the rate of conversion form cloud ice to snow due
  the growth of cloud ice by water vapor deposition.
It is defined as the change of mass of cloud ice for cloud ice particles
  larger than threshold ``r_{is}``.
See [Harrington1995](@cite)
  for derivation.

```math
\begin{equation}
  \left. \frac{d \, q_{sno}}{dt} \right|_{acnv} =
  \frac{1}{\rho} \frac{d}{dt}
    \left( \int_{r_{is}}^{\infty} m(r) n(r) dr \right) =
    \left. \frac{1}{\rho} \frac{dr}{dt} \right|_{r=r_{is}} m(r_{is}) n(r_{is})
    + \frac{1}{\rho} \int_{r_{is}}^{\infty} \frac{dm}{dt} n(r) dr
\end{equation}
```
The ``\frac{dm}{dt}`` is obtained by solving the water vapor diffusion equation
  in spherical coordinates and linking the changes in temperature at the drop
  surface to the changes in saturated vapor pressure via the Clausius-Clapeyron
  equation, following
  [Mason2010](@cite).

For the simplest case of spherical particles and not taking into account
  ventilation effects:
```math
\begin{equation}
\frac{dm}{dt} = 4 \pi \, r \, (S - 1) \, G(T)
\label{eq:mass_rate}
\end{equation}
```
where:
 - ``S(q_{vap}, q_{vap}^{sat}) = \frac{q_{vap}}{q_{vap}^{sat}}`` is saturation,
 - ``q_{vap}^{sat}``
     is the saturation vapor specific humidity (over ice in this case),
 - ``G(T) = \left(\frac{L_s}{KT} \left(\frac{L_s}{R_v T} - 1 \right) + \frac{R_v T}{p_{vap}^{sat} D} \right)^{-1}``
     combines the effects of thermal conductivity and water diffusivity.
 - ``L_s`` is the latent heat of sublimation,
 - ``K_{thermo}`` is the thermal conductivity of air,
 - ``R_v`` is the gas constant of water vapor,
 - ``D_{vapor}`` is the diffusivity of water vapor

Using eq. (\ref{eq:mass_rate}) and the assumed ``m(r)`` relationship we obtain
```math
\begin{equation}
\frac{dr}{dt} = \frac{4 \pi \, (S - 1)}{\chi_m \, (m_e + \Delta_m)}
  \, \left( \frac{r_0}{r} \right)^{m_e + \Delta_m}
  \, \frac{G(T) \, r^2}{m_0}
\label{eq:r_rate}
\end{equation}
```
Finally the snow autoconversion rate is computed as
```math
\begin{equation}
  \left. \frac{d \, q_{sno}}{dt} \right|_{acnv} =
   \frac{1}{\rho} 4 \pi \, (S-1) \, G(T) \,
   n_0^{ice} \, exp(-\lambda_{ice} r_{is})
   \left( \frac{r_{is}^2}{m_e^{ice} + \Delta_m^{ice}} +
   \frac{r_{is} \lambda_{ice} +1}{\lambda_{ice}^2} \right)
\end{equation}
```
!!! note
    We should include ventilation effects.

    For non-spherical particles the mass rate of growth
    should be multiplied by a function depending on the particle aspect ratio.
    For functions proposed for different crystal habitats see
    [Harrington1995](@cite) Appendix B.

We also have a simplified version of snow autoconversion rate,
  to be used in modeling configurations that
  don't allow supersaturation to be present in the computational domain.
It is formulated similarly to the rain autoconversion:
```math
\begin{equation}
  \left. \frac{d \, q_{sno}}{dt} \right|_{acnv} =
    \frac{max(0, q_{ice} - q_{ice\_threshold})}{\tau_{acnv\_snow}}
\end{equation}
```
where:
 - ``q_{liq}`` - liquid water specific humidity,
 - ``\tau_{acnv\_rain}`` - timescale,
 - ``q_{liq\_threshold}`` - autoconversion threshold.

## Accretion

Accretion defines the rates of conversion between different categories due to
  collisions between particles.

For the case of collisions between cloud water (liquid water or ice)
  and precipitation (rain or snow) the sink of cloud water is defined as:

```math
\begin{equation}
\left. \frac{d \, q_{c}}{dt} \right|_{accr} =
  - \int_0^\infty n_p(r) \, a^p(r) \, v_{term}(r) \, E_{cp} \, q_{c} \, dr
\label{eq:accr_1}
\end{equation}
```
where:
 - ``c`` subscript indicates cloud water category (cloud liquid water or ice)
 - ``p`` subscript indicates precipitation category (rain or snow)
 - ``E_{cp}`` is the collision efficiency.

Integrating over the distribution yields:
```math
\begin{equation}
\left. \frac{d \, q_c}{dt} \right|_{accr} =
  - n_{0}^p \, \Pi_{a, v}^p \, q_c \, E_{cp} \,
    \Gamma(\Sigma_{a, v}^p + 1) \,
    \frac{1}{\lambda^p} \,
    \left( \frac{1}{r_0^p \lambda^p}
    \right)^{\Sigma_{a, v}^p}
\label{eq:accrfin}
\end{equation}
```
where:
 - ``\Pi_{a, v}^p = a_0^p \, v_0^p \, \chi_a^p \, \chi_v^p``
 - ``\Sigma_{a, v}^p = a_e^p + v_e^p + \Delta_a^p + \Delta_v^p``

For the case of cloud liquid water and rain and cloud ice and snow collisions,
  the sink of cloud water becomes simply the source for precipitation.
For the case of cloud liquid water and snow collisions
  for temperatures below freezing, the sink of cloud liquid water is
  a source for snow.
For temperatures above freezing, the accreted cloud droplets
  along with some melted snow are converted to rain.
In this case eq. (\ref{eq:accrfin}) describes the sink of cloud liquid water.
The sink of snow is proportional to the sink of cloud liquid water with
  the coefficient ``\frac{c_{vl}}{L_f}(T - T_{freeze})``,
  where ``c_{vl}`` is the isochoric specific heat of liquid water,
 ``L_f`` is the latent heat of freezing,
  and ``T_{freeze}`` is the freezing temperature.

The collisions between cloud ice and rain create snow.
The source of snow in this case is a sum of sinks from cloud ice and rain.
The sink of cloud ice is defined by eq. (\ref{eq:accrfin}).
The sink of rain is defined as:

```math
\begin{equation}
\left. \frac{d \, q_{rai}}{dt} \right|_{accr\_ri} =
  - \int_0^\infty \int_0^\infty
  \frac{1}{\rho} \, E_{ir} \, n_i(r_i) \, n_r(r_r) \, a_r(r_r) \, m_r(r_r)
  \, v_{term}(r_r) \, d r_i d r_r
\label{eq:accr_ir}
\end{equation}
```
where:
 - ``E_{ir}`` is the collision efficiency between rain and cloud ice
 - ``n_i`` and ``n_r`` are the cloud ice and rain size distributions
 - ``m_r``, ``a_r`` and ``v_{term}`` are the mass(radius),
     cross section(radius) and terminal velocity(radius) relations for rain
 - ``r_i`` and ``r_r`` mark integration over cloud ice and rain size
     distributions

Integrating eq.(\ref{eq:accr_ir}) yields:
```math
\begin{equation}
\left. \frac{d \, q_{rai}}{dt} \right|_{accr\_ri} =
  - \frac{1}{\rho} \, E_{ir} \, n_0^{rai} \, n_0^{ice} \,
  \Pi_{m, a, v}^{rai}
  \Gamma(\Sigma_{m, a, v}^{rai} + 1) \,
  \frac{1}{\lambda^{ice} \, \lambda^{rai}} \,
  \left( \frac{1}{r_0^{rai} \, \lambda^{rai}}
  \right)^{\Sigma_{m, a, v}^{rai}}
\end{equation}
```
where:
 - ``\Pi_{m, a, v}^{rai} =  m_0^{rai} \, a_0^{rai} \, v_0^{rai} \, \chi_m^{rai} \, \chi_a^{rai} \, \chi_v^{rai}``
 - ``\Sigma_{m, a, v}^{rai} = m_e^{rai} + a_e^{rai} + v_e^{rai} + \Delta_m^{rai} + \Delta_a^{rai} + \Delta_v^{rai}``


Collisions between rain and snow result in snow in temperatures below freezing
  and in rain in temperatures above freezing.
The source term is defined as:
```math
\begin{equation}
\left. \frac{d \, q_i}{dt} \right|_{accr} =
    \int_0^\infty \int_0^\infty \frac{1}{\rho}
    n_i(r_i) \, n_j(r_j) \, a(r_i, r_j) \, m_j(r_j) \, E_{ij} \,
    \left|v_{term}(r_i) - v_{term}(r_j)\right| \, dr_i dr_j
\label{eq:accr_sr1}
\end{equation}
```
where
- ``i`` stands for rain (``T>T_{freezing}``) or snow (``T<T_{freezing}``)
- ``j`` stands for snow (``T>T_{freezing}``) or rain (``T<T_{freezing}``)
- ``a(r_i, r_j)`` is the crossection of the two colliding particles

There are two additional assumptions that we make to integrate
  eq.(\ref{eq:accr_sr1}):
- ``\left|v_{term}(r_i) - v_{term}(r_j)\right| \approx \left| v_{ti} - v_{tj} \right|``
  We approximate the terminal velocity difference for each particle pair with
  a difference between mass-weighted mean terminal velocities and move it
  outside of the integral.
  See the discussion in [Ikawa\_and\_Saito\_1991](https://www.mri-jma.go.jp/Publish/Technical/DATA/VOL_28/28_005.pdf)
  page 88.

- We assume that ``a(r_i, r_j) = \pi (r_i + r_j)^2``.
  This corresponds to a geometric formulation of the collision kernel,
  aka cylindrical formulation, see
  [Wang2006](@cite)
  for discussion.

The eq.(\ref{eq:accr_sr1}) can then be integrated as:
```math
\begin{align}
\left. \frac{d \, q_i}{dt} \right|_{accr} & =
    \frac{1}{\rho} \, \pi \, n_0^{i} \, n_0^{j} \,
    m_0^j \, \chi_m^j \, \left(\frac{1}{r_0^j}\right)^{m_e^j + \Delta_m^j}
    \, E_{ij} \left| v_{ti} - v_{tj} \right|
    \int_0^\infty \int_0^\infty
    (r_i + r_j)^2
    r_{j}^{m_e^j + \Delta_m^j} \,
    exp(- \lambda_j r_j) \,
    exp(- \lambda_i r_i) \,
    dr_i dr_j \\
    & =
    \frac{1}{\rho} \, \pi \, n_0^{i} \, n_0^{j} \, m_0^j \, \chi_m^j \,
    E_{ij} \left| v_{ti} - v_{tj} \right| \,
    \left( \frac{1}{r_0^j} \right)^{m_e^j + \Delta_m^j}
    \left(
        \frac{2 \Gamma(m_e^j + \Delta_m^j + 1)}{\lambda_i^3 \lambda_j^{m_e^j + \Delta_m^j + 1}}
        + \frac{2 \Gamma(m_e^j + \Delta_m^j + 2)}{ \lambda_i^2 \lambda_j^{m_e^j + \Delta_m^j + 2}}
        + \frac{\Gamma(m_e^j + \Delta_m^j + 3)}{\lambda_i \lambda_j^{m_e^j + \Delta_m^j + 3}}
    \right)
\end{align}
```

!!! note
    Both of the assumptions needed to integrate the snow-rain accretion rate
    could be revisited:

    The discussion on page 88 in
    [Ikawa\_and\_Saito\_1991](https://www.mri-jma.go.jp/Publish/Technical/DATA/VOL_28/28_005.pdf)
    suggests an alternative approximation of the velocity difference.

    The ``(r_i + r_j)^2`` assumption for the crossection is inconsistent
    with the snow crossection used when modelling collisions with cloud water
    and cloud ice.


## Rain evaporation and snow sublimation

We start from a similar equation as when computing snow autoconversion rate
but integrate it from ``0`` to ``\infty``.

```math
\begin{equation}
  \left. \frac{dq}{dt} \right|_{evap\_subl} =
    \frac{1}{\rho} \int_{0}^{\infty} \frac{dm(r)}{dt} n(r) dr
\end{equation}
```
In contrast to eq.(\ref{eq:mass_rate}), now we are taking into account
  ventilation effects:

```math
\begin{equation}
  \frac{dm}{dt} = 4 \pi \, r \, (S - 1) \, G(T) \, F(r)
\label{eq:mass_rate2}
\end{equation}
```
where:
 - ``F(r)`` is the rain drop ventilation factor
   defined in (\ref{eq:ventil_factor})
 - saturation S is computed over water or ice

The final integral is:

```math
\begin{align}
\left. \frac{dq}{dt} \right|_{evap\_subl} & =
    \frac{4 \pi n_0}{\rho} (S - 1) G(T)
    \int_0^\infty
    \left(
       a_{vent} +
       b_{vent} \,
         \left(\frac{\nu_{air}}{D_{vapor}} \right)^{\frac{1}{3}} \,
         \left(\frac{r}{r_0} \right)^{\frac{v_e + \Delta_v}{2}} \,
         \left(\frac{2 \, \chi_v \, v_0 \, r}{\nu_{air}} \right)^{\frac{1}{2}}
    \right)
    r \, exp(-\lambda r) dr \\
    & =
    \frac{4 \pi n_0}{\rho} (S - 1) G(T) \lambda^{-2}
    \left(
       a_{vent} +
       b_{vent} \,
         \left(\frac{\nu_{air}}{D_{vapor}} \right)^{\frac{1}{3}} \,
         \left(\frac{1}{r_0 \, \lambda} \right)^{\frac{v_e + \Delta_v}{2}} \,
         \left(\frac{2 \, \chi_v \, v_0}{\nu_{air} \, \lambda} \right)^{\frac{1}{2}} \,
         \Gamma\left( \frac{v_e + \Delta_v + 5}{2} \right)
    \right)
\end{align}
```
For the case of rain we only consider evaporation (``S - 1 < 0``).
For the case of snow we consider both the source term due to vapor deposition
 on snow (``S - 1 > 0``) and the sink due to vapor sublimation (``S - 1 < 0``).

!!! note
    We should take into account the non-spherical snow shape.
    Modify the Reynolds number and growth equation.

## Snow melt

If snow occurs in temperatures above freezing it is melting into rain.
The sink for snow is parameterized again as
```math
\begin{equation}
  \left. \frac{dq}{dt} \right|_{melt} =
    \frac{1}{\rho} \int_{0}^{\infty} \frac{dm(r)}{dt} n(r) dr
\end{equation}
```
For snow melt
```math
\begin{equation}
  \frac{dm}{dt} = 4 \pi \, r \, \frac{K_{thermo}}{L_f} (T - T_{freeze}) \, F(r)
\label{eq:mass_rate3}
\end{equation}
```
where:
 - ``F(r)`` is the ventilation factor defined in (\ref{eq:ventil_factor})
 - ``L_f`` is the latent heat of freezing.

If ``T > T_{freeze}``:
```math
\begin{equation}
\left. \frac{dq}{dt} \right|_{evap\_subl} =
    \frac{4 \pi \, n_0 \, K_{thermo}}{\rho \, L_f} (T - T_{freeze}) \lambda^{-2}
    \left(
       a_{vent} +
       b_{vent} \,
         \left( \frac{\nu_{air}}{D_{vapor}} \right)^{\frac{1}{3}} \,
         \left( \frac{1}{r_0 \, \lambda} \right)^{\frac{v_e + \Delta_v}{2}} \,
         \left( \frac{2 \, \chi_v \, v_0}{\nu_{air} \, \lambda} \right)^{\frac{1}{2}} \,
         \Gamma \left( \frac{v_e + \Delta_v + 5}{2} \right)
    \right)
\end{equation}
```
## Example figures

```@example example_figures
import Plots

import Thermodynamics
import CloudMicrophysics
import CLIMAParameters

const PL = Plots
const CMT = CloudMicrophysics.CommonTypes
const CM1 = CloudMicrophysics.Microphysics1M
const TD = Thermodynamics
const CP = CLIMAParameters
const CMP = CloudMicrophysics.Parameters

include(joinpath(pkgdir(CloudMicrophysics), "test", "create_parameters.jl"))
FT = Float64
toml_dict = CP.create_toml_dict(FT; dict_type = "alias")
const param_set = cloud_microphysics_parameters(toml_dict)
thermo_params = CMP.thermodynamics_params(param_set)

const liquid = CMT.LiquidType()
const ice = CMT.IceType()
const rain = CMT.RainType()
const snow = CMT.SnowType()

# eq. 5d in [Grabowski1996](@cite)
function terminal_velocity_empirical(q_rai::DT, q_tot::DT, ρ::DT, ρ_air_ground::DT) where {DT<:Real}
    rr  = q_rai / (DT(1) - q_tot)
    vel = DT(14.34) * ρ_air_ground^DT(0.5) * ρ^-DT(0.3654) * rr^DT(0.1346)
    return vel
end

# eq. 5b in [Grabowski1996](@cite)
function accretion_empirical(q_rai::DT, q_liq::DT, q_tot::DT) where {DT<:Real}
    rr  = q_rai / (DT(1) - q_tot)
    rl  = q_liq / (DT(1) - q_tot)
    return DT(2.2) * rl * rr^DT(7/8)
end

# eq. 5c in [Grabowski1996](@cite)
function rain_evap_empirical(q_rai::DT, q::TD.PhasePartition, T::DT, p::DT, ρ::DT) where {DT<:Real}

    ts_neq = TD.PhaseNonEquil_ρTq(thermo_params, ρ, T, q)
    q_sat  = TD.q_vap_saturation(thermo_params, ts_neq)
    q_vap  = q.tot - q.liq
    rr     = q_rai / (DT(1) - q.tot)
    rv_sat = q_sat / (DT(1) - q.tot)
    S      = q_vap/q_sat - DT(1)

    ag, bg = 5.4 * 1e2, 2.55 * 1e5
    G = DT(1) / (ag + bg / p / rv_sat) / ρ

    av, bv = 1.6, 124.9
    F = av * (ρ/DT(1e3))^DT(0.525)  * rr^DT(0.525) + bv * (ρ/DT(1e3))^DT(0.7296) * rr^DT(0.7296)

    return DT(1) / (DT(1) - q.tot) * S * F * G
end

# example values
q_liq_range  = range(1e-8, stop=5e-3, length=100)
q_ice_range  = range(1e-8, stop=5e-3, length=100)
q_rain_range = range(1e-8, stop=5e-3, length=100)
q_snow_range = range(1e-8, stop=5e-3, length=100)
ρ_air, ρ_air_ground = 1.2, 1.22
q_liq, q_ice, q_tot = 5e-4, 5e-4, 20e-3

PL.plot( q_rain_range * 1e3, [CM1.terminal_velocity(param_set, rain, ρ_air, q_rai) for q_rai in q_rain_range],     linewidth=3, xlabel="q_rain or q_snow [g/kg]", ylabel="terminal velocity [m/s]", label="Rain-CLIMA")
PL.plot!(q_snow_range * 1e3, [CM1.terminal_velocity(param_set, snow, ρ_air, q_sno) for q_sno in q_snow_range],     linewidth=3, label="Snow-CLIMA")
PL.plot!(q_rain_range * 1e3, [terminal_velocity_empirical(q_rai, q_tot, ρ_air, ρ_air_ground) for q_rai in q_rain_range], linewidth=3, label="Rain-Empirical")
PL.savefig("terminal_velocity.svg") # hide

T = 273.15
PL.plot( q_liq_range * 1e3, [CM1.conv_q_liq_to_q_rai(param_set, q_liq) for q_liq in q_liq_range], linewidth=3, xlabel="q_liq or q_ice [g/kg]", ylabel="autoconversion rate [1/s]", label="Rain")
PL.plot!(q_ice_range * 1e3, [CM1.conv_q_ice_to_q_sno(param_set, TD.PhasePartition(q_tot, 0., q_ice), ρ_air, T-5)  for q_ice in q_ice_range], linewidth=3, label="Snow T=-5C")
PL.plot!(q_ice_range * 1e3, [CM1.conv_q_ice_to_q_sno(param_set, TD.PhasePartition(q_tot, 0., q_ice), ρ_air, T-10) for q_ice in q_ice_range], linewidth=3, label="Snow T=-10C")
PL.plot!(q_ice_range * 1e3, [CM1.conv_q_ice_to_q_sno(param_set, TD.PhasePartition(q_tot, 0., q_ice), ρ_air, T-15) for q_ice in q_ice_range], linewidth=3, label="Snow T=-15C")
PL.savefig("autoconversion_rate.svg") # hide

PL.plot( q_rain_range * 1e3, [CM1.accretion(param_set, liquid, rain, q_liq, q_rai, ρ_air) for q_rai in q_rain_range], linewidth=3, xlabel="q_rain or q_snow [g/kg]", ylabel="accretion rate [1/s]", label="Liq+Rain-CLIMA")
PL.plot!(q_rain_range * 1e3, [CM1.accretion(param_set, ice,    rain, q_ice, q_rai, ρ_air) for q_rai in q_rain_range], linewidth=3, label="Ice+Rain-CLIMA")
PL.plot!(q_snow_range * 1e3, [CM1.accretion(param_set, liquid, snow, q_liq, q_sno, ρ_air) for q_sno in q_snow_range], linewidth=3, label="Liq+Snow-CLIMA")
PL.plot!(q_snow_range * 1e3, [CM1.accretion(param_set, ice,    snow, q_ice, q_sno, ρ_air) for q_sno in q_snow_range], linewidth=4, linestyle=:dash, label="Ice+Snow-CLIMA")
PL.plot!(q_rain_range * 1e3, [accretion_empirical(q_rai, q_liq, q_tot) for q_rai in q_rain_range], linewidth=3, label="Liq+Rain-Empirical")
PL.savefig("accretion_rate.svg") # hide

q_ice = 1e-6
PL.plot(q_rain_range * 1e3, [CM1.accretion_rain_sink(param_set, q_ice, q_rai, ρ_air) for q_rai in q_rain_range], linewidth=3, xlabel="q_rain or q_snow [g/kg]", ylabel="accretion rain sink rate [1/s]", label="q_ice=1e-6")
q_ice = 1e-5
PL.plot!(q_rain_range * 1e3, [CM1.accretion_rain_sink(param_set, q_ice, q_rai, ρ_air) for q_rai in q_rain_range], linewidth=3, xlabel="q_rain or q_snow [g/kg]", ylabel="accretion rain sink rate [1/s]", label="q_ice=1e-5")
q_ice = 1e-4
PL.plot!(q_rain_range * 1e3, [CM1.accretion_rain_sink(param_set, q_ice, q_rai, ρ_air) for q_rai in q_rain_range], linewidth=3, xlabel="q_rain or q_snow [g/kg]", ylabel="accretion rain sink rate [1/s]", label="q_ice=1e-4")
PL.savefig("accretion_rain_sink_rate.svg") # hide

q_sno = 1e-6
PL.plot(q_rain_range * 1e3, [CM1.accretion_snow_rain(param_set, rain, snow, q_rai, q_sno, ρ_air) for q_rai in q_rain_range], linewidth=3, xlabel="q_rain [g/kg]", ylabel="snow-rain accretion rate [1/s] T>0", label="q_snow=1e-6")
q_sno = 1e-5
PL.plot!(q_rain_range * 1e3, [CM1.accretion_snow_rain(param_set, rain, snow, q_rai, q_sno, ρ_air) for q_rai in q_rain_range], linewidth=3, label="q_snow=1e-5")
q_sno = 1e-4
PL.plot!(q_rain_range * 1e3, [CM1.accretion_snow_rain(param_set, rain, snow, q_rai, q_sno, ρ_air) for q_rai in q_rain_range], linewidth=3, label="q_snow=1e-4")
PL.savefig("accretion_snow_rain_above_freeze.svg") # hide

q_rai = 1e-6
PL.plot(q_snow_range * 1e3, [CM1.accretion_snow_rain(param_set, snow, rain, q_sno, q_rai, ρ_air) for q_sno in q_snow_range], linewidth=3, xlabel="q_snow [g/kg]", ylabel="snow-rain accretion rate [1/s] T<0", label="q_rain=1e-6")
q_rai = 1e-5
PL.plot!(q_snow_range * 1e3, [CM1.accretion_snow_rain(param_set, snow, rain, q_sno, q_rai, ρ_air) for q_sno in q_snow_range], linewidth=3, label="q_rain=1e-5")
q_rai = 1e-4
PL.plot!(q_snow_range * 1e3, [CM1.accretion_snow_rain(param_set, snow, rain, q_sno, q_rai, ρ_air) for q_sno in q_snow_range], linewidth=3, label="q_rain=1e-4")
PL.savefig("accretion_snow_rain_below_freeze.svg") # hide

# example values
T, p = 273.15 + 15, 90000.
ϵ = 1. / CMP.molmass_ratio(param_set)
p_sat = TD.saturation_vapor_pressure(thermo_params, T, TD.Liquid())
q_sat = ϵ * p_sat / (p + p_sat * (ϵ - 1.))
q_rain_range = range(1e-8, stop=5e-3, length=100)
q_tot = 15e-3
q_vap = 0.15 * q_sat
q_ice = 0.
q_liq = q_tot - q_vap - q_ice
q = TD.PhasePartition(q_tot, q_liq, q_ice)
R = TD.gas_constant_air(thermo_params, q)
ρ = p / R / T

PL.plot(q_rain_range * 1e3,  [CM1.evaporation_sublimation(param_set, rain, q, q_rai, ρ, T) for q_rai in q_rain_range], xlabel="q_rain [g/kg]", linewidth=3, ylabel="rain evaporation rate [1/s]", label="ClimateMachine")
PL.plot!(q_rain_range * 1e3, [rain_evap_empirical(q_rai, q, T, p, ρ) for q_rai in q_rain_range], linewidth=3, label="empirical")
PL.savefig("rain_evaporation_rate.svg") # hide

# example values
T, p = 273.15 - 15, 90000.
ϵ = 1. / CMP.molmass_ratio(param_set)
p_sat = TD.saturation_vapor_pressure(thermo_params, T, TD.Ice())
q_sat = ϵ * p_sat / (p + p_sat * (ϵ - 1.))
q_snow_range = range(1e-8, stop=5e-3, length=100)
q_tot = 15e-3
q_vap = 0.15 * q_sat
q_liq = 0.
q_ice = q_tot - q_vap - q_liq
q = TD.PhasePartition(q_tot, q_liq, q_ice)
R = TD.gas_constant_air(thermo_params, q)
ρ = p / R / T

PL.plot(q_snow_range * 1e3,  [CM1.evaporation_sublimation(param_set, snow, q, q_sno, ρ, T) for q_sno in q_snow_range], xlabel="q_snow [g/kg]", linewidth=3, ylabel="snow deposition sublimation rate [1/s]", label="T<0")

T, p = 273.15 + 15, 90000.
ϵ = 1. / CMP.molmass_ratio(param_set)
p_sat = TD.saturation_vapor_pressure(thermo_params, T, TD.Ice())
q_sat = ϵ * p_sat / (p + p_sat * (ϵ - 1.))
q_snow_range = range(1e-8, stop=5e-3, length=100)
q_tot = 15e-3
q_vap = 0.15 * q_sat
q_liq = 0.
q_ice = q_tot - q_vap - q_liq
q = TD.PhasePartition(q_tot, q_liq, q_ice)
R = TD.gas_constant_air(thermo_params, q)
ρ = p / R / T

PL.plot!(q_snow_range * 1e3,  [CM1.evaporation_sublimation(param_set, snow, q, q_sno, ρ, T) for q_sno in q_snow_range], xlabel="q_snow [g/kg]", linewidth=3, ylabel="snow deposition sublimation rate [1/s]", label="T>0")
PL.savefig("snow_sublimation_deposition_rate.svg") # hide

T=273.15
PL.plot( q_snow_range * 1e3,  [CM1.snow_melt(param_set, q_sno, ρ, T+2) for q_sno in q_snow_range], xlabel="q_snow [g/kg]", linewidth=3, ylabel="snow melt rate [1/s]", label="T=2C")
PL.plot!(q_snow_range * 1e3,  [CM1.snow_melt(param_set, q_sno, ρ, T+4) for q_sno in q_snow_range], xlabel="q_snow [g/kg]", linewidth=3, label="T=4C")
PL.plot!(q_snow_range * 1e3,  [CM1.snow_melt(param_set, q_sno, ρ, T+6) for q_sno in q_snow_range], xlabel="q_snow [g/kg]", linewidth=3, label="T=6C")
PL.savefig("snow_melt_rate.svg") # hide

```
![](terminal_velocity.svg)
![](autoconversion_rate.svg)
![](accretion_rate.svg)
![](accretion_rain_sink_rate.svg)
![](accretion_snow_rain_below_freeze.svg)
![](accretion_snow_rain_above_freeze.svg)
![](rain_evaporation_rate.svg)
![](snow_sublimation_deposition_rate.svg)
![](snow_melt_rate.svg)

