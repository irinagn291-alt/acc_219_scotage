# Scotage

Tap the aimed lot so it quits and this month's load falls.

Scotage is for people who already know the month is too heavy. Lots that bill this month sit on a rate face. A Scot pin marks the month the user can bear. The hand aims at the largest overrun lot. That tap files a QuitMark. Any other tap cools the arc and leaves the hand. There is no bank login.

## Architecture

The Face is a Precept ADT fold of Vacant, Bare, Aimed, and Eased over live Lots. That pattern fits this product because the home verb is illegal on every lot except one.

- Aim writes a Hand on the live overrun Lot with the largest period-normalized month amount and folds Bare to Aimed.
- A second Aim while Aimed is refused.
- Quit writes a QuitMark only when the tapped Lot is the aimed Lot, then drops it from the live stack.
- A miss writes a HoldMark and keeps the Hand.
- The last true Quit that brings live load to or under the Scot folds Aimed to Eased.
- Quit on Bare is refused.
- An empty live stack writes Vacant.

monthlyEquivalent is amount times period.occurrencesPerMonth, with weekly as 52/12. Only Lots whose next charge day falls in the current month sit on the Face. Cancel-savings is the sum of QuitMark month amounts.

FaceStore is the only persistence seam. Views never see UserDefaults. The Ledger is one UIKit UICollectionView with a compositional layout and a diffable data source. `NSCollectionLayoutGroup.custom` places Lot cells as rim arcs. Supplementary views draw the needle, the Scot pin, and the year inscription. Insights and Settings are SwiftUI sheets. The rate face never leaves.

## Aim then quit

After seed the Hand already aims at an overrun Lot, so the first tap can file. Tapping that aimed arc writes a QuitMark, drops the Lot, drops the needle, and raises cancel-savings. Tapping any other arc writes a HoldMark and leaves the Hand. Insights lists quits, cooled misses, leftover overrun, and mystery-charge flags. Settings stores currency, the Scot, and a local reminder.

## Art

Style: gouache illustration, abstract, opaque pigment on cold-press paper.

Base prompt, reused for every asset:

```
Flat gouache illustration, abstract, opaque pigment on cold-press paper, visible brush loading and paper tooth, simplified geometric masses, dry-brush edges, a rate instrument reduced to arcs and a pin, no line-drawing illustration, no photorealism, no readable text, no logo, no emoji
```

| Image set | Prompt |
| --- | --- |
| `sct_AppIcon` | Abstract gouache emblem of a rate face reduced to a disc, a pin, and one aimed arc, filling the canvas edge to edge, no text, no transparency, no rounded-corner mask |
| `sct_Splash` | Vertical abstract gouache field of a quiet analog face, calm uncluttered centre band, opaque pigment, paper tooth, no readable text |
| `sct_Onboarding1` | Solid gouache lot-token cluster on a short stand, opaque painted clay forms, isolated subject, what the product is, not glass |
| `sct_Onboarding2` | Solid gouache hand touching one raised arc on a face disc, mid-gesture quit tap, opaque painted mass, isolated subject, not a wire frame |
| `sct_Onboarding3` | Solid gouache face with a lowered needle and stacked quit seals beside it, accumulated meaning, opaque pigment, isolated subject |
| `sct_EmptyHome` | Solid closed ceramic lot bowl waiting to be filled, fully opaque clay, isolated subject, not glass, not a hollow ring |
| `sct_EmptyList` | Solid folded cloth waiting for ink, opaque fabric block, isolated subject, not a glass plate |
| `sct_CardBackdrop` | Abstract gouache wash of rim arcs behind a quiet centre, low contrast so ink stays readable, fills the canvas, no cutout |
| `sct_ControlFace` | Solid painted analog-face disc with a raised pin and a short hand, opaque gouache, isolated subject |
| `sct_TwistHero` | Solid gouache emblem of a hand aimed at one overrun arc, opaque painted mass, isolated subject |
| `sct_SuccessMark` | Solid stamped quit seal, opaque pigment disc, isolated subject, not a hollow outline |
| `sct_HeaderDecor` | Wide abstract gouache band of rim arcs and a pin, ornamental painted mass, isolated subject |

## Why this is not a repeat

Kentledge seats freed credit on a keep or sink after a drag-cut on a load beam. Scotage keeps subscription_load math, but the Ledger is a rate face. The hand aims at the largest overrun lot. Only that tap quits. Insights lists quits and cooled misses, not a rank of uncut bricks. Not Restante payday wait, not Counterfoil hold tickets, not Palmette pinch, not Castellum pours, and not a three-tab subscription list.

## Build

```bash
cd Scotage
xcodegen generate
xcodebuild -scheme Scotage -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
xcodebuild -scheme Scotage -destination 'generic/platform=iOS Simulator' build-for-testing
```
