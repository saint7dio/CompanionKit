# CompanionKit Design Language

## Veya

Veya is CompanionKit’s canonical included companion. The personal display name
is configurable, but the character identity remains Veya. Veya is an original,
wingless soul-orb: a living light with an organic asymmetric body, luminous
core, restrained aura, short attached spirit tail, minimal eyes, and no fixed
animal anatomy.

The supplied concept board is visual direction only. CompanionKit ships a
repository-owned procedural SwiftUI renderer and an original vector app icon;
the board is not a runtime asset.

### Non-negotiable silhouette rules

- No wings, side fins that read as wings, ears, paws, whiskers, animal muzzle,
  franchise silhouette, or copied mascot feature.
- The tail must remain a soft attached energy taper, never a wing pair.
- Veya must read as one compact soul-like body at Small, Medium, and Large sizes.
- Expressions use eyes, optional minimal mouth, deformation, aura, and motion.

## Ethereal theme

Ethereal is the only implemented MVP theme. Its layers render back-to-front:

1. restrained ground shadow;
2. radial aura;
3. sparse state-relevant particles;
4. attached spirit tail;
5. organic translucent body and edge;
6. luminous core;
7. minimal face;
8. small semantic state overlay when needed.

The default palette is cool white and ice blue. Moon Violet, Mist Mint, Warm
Amber, Soft Rose, and Monochrome are color variants of Ethereal, not separate
themes. Status color supplements expression, shape, motion, text, and
accessibility output; color is never the only signal.

## Motion

Motion values live in `CompanionMotion`; personality profiles scale tempo,
amplitude, particles, and reaction duration. Friendly is the balanced default,
Calm reduces activity, and Energetic increases it within the same safety and
permission policy.

System Reduce Motion always wins. “Always reduce motion” can request less motion
but cannot force motion back on. With effective Reduce Motion, continuous drift,
aura pulsing, orbit, and particles stop; semantic expression and static shape
remain.

## Interface surfaces

Use system fonts, materials, controls, focus behavior, and SF Symbols for
ordinary interface actions. Veya marks are procedural/vector and must not be
replaced by animal paw icons. Keep cards compact, contrast adaptive, status copy
plain, and destructive actions explicit.

## Originality review

Before accepting visual changes, inspect the normal-size silhouette and icon:

- unmistakably wingless and non-animal;
- no borrowed face, catchphrase, symbol arrangement, or franchise motif;
- no copied or unlicensed asset;
- readable on light and dark desktops;
- restrained enough for persistent desktop use.

