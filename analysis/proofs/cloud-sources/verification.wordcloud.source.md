# Word cloud — rendering source

These are the exact text items and weights supplied to the renderer.
Selections are extractive; prominence is not a claim of factual correctness.

Source: verification.txt
Source SHA-256: `4687a94a2d79b016569a7e4e495ed4f84388c2314e78529ec4f785a3b79abe3d`

## 1 · weight 24

open

## 2 · weight 24

reservoir

## 3 · weight 24

coupling

## 4 · weight 24

input

## 5 · weight 24

power

## 6 · weight 24

measured

## 7 · weight 24

output

## 8 · weight 24

recorded

## 9 · weight 1

final

## 10 · weight 1

twenty

## 11 · weight 1

five

## 12 · weight 1

ocr

## 13 · weight 1

marker

## Machine-readable rendering input

The JSON below is the complete rendering specification. No image OCR is needed.

```cloud-render-json
{
  "schema": "cloud-render/1",
  "kind": "wordcloud",
  "items": [
    {
      "text": "open",
      "weight": 24
    },
    {
      "text": "reservoir",
      "weight": 24
    },
    {
      "text": "coupling",
      "weight": 24
    },
    {
      "text": "input",
      "weight": 24
    },
    {
      "text": "power",
      "weight": 24
    },
    {
      "text": "measured",
      "weight": 24
    },
    {
      "text": "output",
      "weight": 24
    },
    {
      "text": "recorded",
      "weight": 24
    },
    {
      "text": "final",
      "weight": 1
    },
    {
      "text": "twenty",
      "weight": 1
    },
    {
      "text": "five",
      "weight": 1
    },
    {
      "text": "ocr",
      "weight": 1
    },
    {
      "text": "marker",
      "weight": 1
    }
  ],
  "settings": {
    "width": 1600,
    "height": 900,
    "max_words": 200,
    "background": "black",
    "title": "verification.txt",
    "random_state": 42,
    "relative_scaling": 0.5,
    "collocations": false,
    "prefer_horizontal": 0.85
  },
  "source": {
    "name": "verification.txt",
    "sha256": "4687a94a2d79b016569a7e4e495ed4f84388c2314e78529ec4f785a3b79abe3d"
  },
  "spec_sha256": "44a80132e29e8a8cfdfff57347f47c4b807c05ad04f1ab8c5eb4e11e8164ef63"
}
```
