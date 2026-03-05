# 2D Particle Process Shader

This project includes a highly configurable particle process shader geared towards 2D particle simulations.
It is supposed to be a drop-in replacement for Godot's own built in [ParticleProcessMaterial](https://docs.godotengine.org/en/stable/classes/class_particleprocessmaterial.html#particleprocessmaterial),
with some additional nice-to-have features, such as path and target follow behaviour,
and perlin noise, a much cheaper (albeit less interesting) randomization effect than [turbulence](https://docs.godotengine.org/en/stable/tutorials/3d/particles/turbulence.html).

In addition to these features, it also allows the user to specify exactly what functionality they want, and will only show shader variables relevant for this functionality in the editor. For example, if perlin noise is the only feature I want to use, the compiled shader will not define uniform variables for random alpha, etc..

## Examples

There are three examples included in this project:

### noise_spread.tscn

Demonstrates the perlin noise effect, and also random RGB and alpha.


<div align="center">
<img src="https://github.com/user-attachments/assets/d629ec8c-8ea2-4bc4-b45c-bcb21a4929a1" width="40%" alt="path_follow">
</div>

### path_follow.tscn


Showcases the particle shader's path following behaviour, with some perlin noise for a bit of randomness.

<div align="center">
<img src="https://github.com/user-attachments/assets/a98122e6-38c1-401e-bea1-7ec51d87c4c6" width="40%" alt="path_follow">
</div>

### target_follow.tscn

Shows the particles following a target set to the user's mouse position.

<div align="center">
<img src="https://github.com/user-attachments/assets/2fd80290-b0d9-4eae-98c7-e492190f3db9" width="40%" alt="path_follow">
</div>

## How to Use

Create your own particles shader and include this project's particle simulation shader with:

```c
#include "res://shaders/particle_simulation.gdshaderinc"
```

Then add preprocessor macro defines above the `#include` line to enable the desired functionality.
For example, the noise spread scene in this project defines:

```c
#define RANDOM_RGB
#define RANDOM_ALPHA
#define RANDOM_COLOUR
#define EMISSION_SHAPE_RING
#define APPLY_NOISE
```

After adding the defines, you will see and be able to modify any relevant shader variables in the inspector, just like with the built-in particle process material.

### Macros and Uniforms

The following macros and uniforms are unique to this shader:

- `APPLY_TARGET_FOLLOW`: Enable target follow
    - `target_pos`: target position
    - `target_mode_active`: enable / disable targeting
    - `min_target_distance`: distance from the target within which a particle will be deactivated
    - `target_follow_speed`: speed
    - `target_follow_stiffness`: how sharp a particle will turn to move toward the target
- `APPLY_PATH_FOLLOW`: Enable path follow with path of up to 50 points (`MAX_PATH_LENGTH` can be modified but is not a uniform variable).
    - `path`: Array of vec2 path points.
    - `path_length`: number of vec2 path points to follow (must be `<=MAX_PATH_LENGTH`)
    - `path_follow_speed`: speed
    - `path_follow_stiffness`: how sharp a particle will turn when proceeding along the path
    - `point_distance_threshold`: minimum distance from a path point for it to be considered 'reached'
- `APPLY_NOISE`: Enable perlin noise randomization. Noise generation performs three iterations with varying frequency and amplitude.
    - `use_random_seed`: whether or noise will be unique to each particle or shared between all (random seed is false for the noise spread example).
    - `noise_influence_min`: min of range for how much the noise should influence particle movement
    - `noise_influence_max`: max of range for how much the noise should influence particle movement
    - `noise_frequency`: how noisy your noise
    - `noise_persistence`: how much amplitude should be scaled for each of three iterations.
    - `noise_lacunarity`: how much frequency should be scaled for each of three iterations.

You may recognize these from Godot's `ParticleProcessMaterial`:

- `EMISSION_SHAPE_RING`
- `APPLY_ANGULAR_VELOCITY`
- `APPLY_ORBIT_VELOCITY`
- `APPLY_RADIAL_VELOCITY`
- `APPLY_ACCELERATIONS`
- `APPLY_DAMPING`
- `RANDOM_RGB`
- `RANDOM_ALPHA`
- `RANDOM_HUE`
- `APPLY_ALPHA_CURVE`

## A Note on the Code

I wrote much of this shader code with optimization in mind,
however I never tested it against a less-optimized version so it very well could be that all of the branchless
logic and preprocessor macros don't actually do anything for performance.

That said, I had a great time writing the code. I hope anyone who experiments with it will find some use for it.
