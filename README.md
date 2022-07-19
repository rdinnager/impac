
<!-- README.md is generated from README.Rmd. Please edit that file -->

# impac

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/rdinnager/impac/workflows/R-CMD-check/badge.svg)](https://github.com/rdinnager/impac/actions)
<!-- badges: end -->

The goal of `{impac}` is to create packed image mosaics. The main
function `impac`, takes a set of images, or a function that generates
images and packs them into a larger image as tightly as possible,
scaling as necessary, using a greedy algorithm (so don’t expect it to be
fast\!). It is inspired by [this python
script](https://github.com/qnzhou/Mosaic%5D). The main upgrade in this
package is the ability to feed the algorithm a generator function, which
generates an images, as opposed to just a list of pre-existing images
(though it can do this too).

## Installation

You can install the development version from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("rdinnager/impac")
```

## Example

This document and hence the images below are regenerated once a day
automatically. No two will ever be alike.

First we load the packages we need for these examples:

``` r
library(impac)
library(Rvcg)
library(rgl)
library(rphylopic)
```

Next we create an R function to generate an image. In this case, we use
the package `rgl` to plot a simple 3d shape, chosen randomly from a set
of possibilities:

``` r

generate_platonic <- function(i, swidth = 200, sheight = 200, cols = rainbow(100)) {
  
  shape <- sample(c("sphere",
                    "spherical_cap",
                    "tetrahedron",
                    "dodecahedron",
                    "octahedron",
                    "icosahedron",
                    "hexahedron",
                    "cube",
                    "cone"),
                  1)
  
  mesh <- switch (shape,
    sphere = Rvcg::vcgSphere(),
    spherical_cap = Rvcg::vcgSphericalCap(),
    tetrahedron = Rvcg::vcgTetrahedron(),
    dodecahedron = Rvcg::vcgDodecahedron(),
    octahedron = Rvcg::vcgOctahedron(),
    icosahedron = Rvcg::vcgIcosahedron(),
    hexahedron = Rvcg::vcgHexahedron(),
    cube = Rvcg::vcgBox(),
    cone = Rvcg::vcgCone(2, 0, 6)
  )
  
  scales <- c(1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 3, 4)
  mesh <- rgl::scale3d(mesh, 
                       sample(scales, 1),
                       sample(scales, 1),
                       sample(scales, 1))
  
  mesh <- rgl::rotate3d(mesh, runif(1, 0, 2 * pi), 0, 0, 1)
  mesh <- rgl::rotate3d(mesh, runif(1, 0, 2 * pi), 0, 1, 0)
  mesh <- rgl::rotate3d(mesh, runif(1, 0, 2 * pi), 1, 0, 0)
  
  rgl::shade3d(mesh, col = sample(cols, 1),
               specular = "grey")
  
  png_file <- tempfile(fileext = ".png")
  rgl::snapshot3d(filename = png_file, width = swidth, height = sheight,
                  webshot = FALSE)
  rgl::close3d()
  
  im2 <- imager::load.image(png_file)
  im <- imager::imfill(swidth, sheight, val = c(0, 0, 0, 1))
  im[ , , , 1:3] <- im2 
  im[imager::R(im) == 1 & imager::G(im) == 1 & imager::B(im) == 1] <- 0
  
  im  
 
}
```

Now we feed our function to the `impac()` function, which packs the
generated images onto a canvas:

``` r
shapes <- impac(generate_platonic, progress = FALSE, show_every = 0, bg = "white")
imager::save.image(shapes$image, "man/figures/R_gems.png")
```

![Pretty R gems - Packed images of 3d shapes drawn with
{rgl}](man/figures/R_gems.png)

Now let’s pack some Phylopic images\! These are silhouettes of organisms
from the [Phylopic](http://phylopic.org/) project. We will use the
`rphylopic` package to grab a random Phylopic image for packing:

``` r
all_images <- rphylopic::image_list(1, 10000)
all_images <- unlist(all_images)
get_phylopic <- function(i, max_size = 400, isize = 1024) {
  fail <- TRUE
  while(fail) {
    uuid <- sample(all_images, 1)
    pp <- try(rphylopic::image_data(uuid, isize), silent = TRUE)
    if(!inherits(pp, "try-error")) {
      fail <- FALSE
    }
  }
  rot <- aperm(pp$uid, c(2, 1, 3))
  dims <- dim(rot)
  im <- imager::as.cimg(as.vector(rot), dim = c(dims[1], dims[2], 1, dims[3]))
  max_dim <- which.max(dims[1:2])
  other_dim <- (max_size / dims[max_dim]) * dims[1:2][-max_dim]
  new_size <- c(0, 0)
  new_size[max_dim] <- max_size
  new_size[-max_dim] <- other_dim
  im <- imager::resize(im, new_size[1], new_size[2], interpolation_type = 6)
  im <- imager::imchange(im, ~ . < 0, ~ 0)
  im <- imager::imchange(im, ~ . > 1, ~ 1)
  ## this adds custom metadata
  list(im, uuid = uuid)
}
```

Now we run `impac` on our phylopic generating function:

``` r
phylopics <- impac(get_phylopic, progress = FALSE, show_every = 0, bg = "white", min_scale = 0.01)
imager::save.image(phylopics$image, "man/figures/phylopic_a_pack.png")
```

![Packed images of organism silhouettes from
Phylopic](man/figures/phylopic_a_pack.png)

Now we extract the artists who made the above images using the uid of
image.

``` r
image_dat <- lapply(phylopics$meta$uuid, 
                    function(x) {Sys.sleep(2); rphylopic::image_get(x, options = c("credit"))$credit})
```

## Artists whose work is showcased:

Matt Crook, Chris huh, Andy Wilson, Zimices, Caleb M. Brown, Mali’o
Kodis, drawing by Manvir Singh, Michelle Site, Matt Martyniuk
(vectorized by T. Michael Keesey), Margot Michaud, Ferran Sayol,
JCGiron, C. Camilo Julián-Caballero, T. Michael Keesey, ДиБгд
(vectorized by T. Michael Keesey), Ludwik Gąsiorowski, Scott Hartman,
Jack Mayer Wood, Yan Wong, Dean Schnabel, Nobu Tamura (vectorized by T.
Michael Keesey), Katie S. Collins, Steven Traver, Gareth Monger, Tasman
Dixon, FunkMonk (Michael B. H.), Felix Vaux, Marmelad, Obsidian Soul
(vectorized by T. Michael Keesey), Alexander Schmidt-Lebuhn, Ignacio
Contreras, Carlos Cano-Barbacil, Nobu Tamura (modified by T. Michael
Keesey), (after Spotila 2004), Duane Raver/USFWS, Andrew A. Farke,
FunkMonk \[Michael B.H.\] (modified by T. Michael Keesey), Darren Naish
(vectorized by T. Michael Keesey), Markus A. Grohme, Jagged Fang
Designs, Dmitry Bogdanov (vectorized by T. Michael Keesey), Noah
Schlottman, photo by Antonio Guillén, Original drawing by Antonov,
vectorized by Roberto Díaz Sibaja, Matt Dempsey, Darius Nau, Beth
Reinke, Michael P. Taylor, Joanna Wolfe, Martin R. Smith, after Skovsted
et al 2015, Audrey Ely, Sharon Wegner-Larsen, Francisco Gascó (modified
by Michael P. Taylor), CNZdenek, Harold N Eyster, Roberto Díaz Sibaja,
Zimices, based in Mauricio Antón skeletal, John Curtis (vectorized by T.
Michael Keesey), Jan A. Venter, Herbert H. T. Prins, David A. Balfour &
Rob Slotow (vectorized by T. Michael Keesey), Erika Schumacher, Gabriela
Palomo-Munoz, nicubunu, Fir0002/Flagstaffotos (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Noah Schlottman,
photo by Carol Cummings, Xvazquez (vectorized by William Gearty), T.
Michael Keesey (from a photo by Maximilian Paradiz), Kamil S. Jaron,
TaraTaylorDesign, Kelly, Mo Hassan, Melissa Broussard, Sarah Werning,
Kent Sorgon, Tauana J. Cunha, Birgit Lang, David Sim (photograph) and T.
Michael Keesey (vectorization), Collin Gross, Bob Goldstein,
Vectorization:Jake Warner, Mathieu Pélissié, Steven Coombs, Xavier
Giroux-Bougard, Dianne Bray / Museum Victoria (vectorized by T. Michael
Keesey), Maha Ghazal, L. Shyamal, Rene Martin, Evan-Amos (vectorized by
T. Michael Keesey), Kai R. Caspar, Christoph Schomburg, Pete Buchholz,
Jaime Headden, Richard Ruggiero, vectorized by Zimices, Fritz
Geller-Grimm (vectorized by T. Michael Keesey), Matt Celeskey, Mathilde
Cordellier, Arthur Grosset (photo), John E. McCormack, Michael G.
Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb
T. Brumfield & T. Michael Keesey, Jose Carlos Arenas-Monroy, Pearson
Scott Foresman (vectorized by T. Michael Keesey), Robert Gay, modifed
from Olegivvit, Rebecca Groom, David Orr, Warren H (photography), T.
Michael Keesey (vectorization), Mathieu Basille, Mali’o Kodis,
photograph by John Slapcinsky, Timothy Knepp of the U.S. Fish and
Wildlife Service (illustration) and Timothy J. Bartley (silhouette),
Abraão Leite, U.S. Fish and Wildlife Service (illustration) and Timothy
J. Bartley (silhouette), Lily Hughes, New York Zoological Society,
Mariana Ruiz Villarreal (modified by T. Michael Keesey), Arthur Weasley
(vectorized by T. Michael Keesey), Juan Carlos Jerí, Aline M. Ghilardi,
Matt Wilkins, Tyler Greenfield and Scott Hartman, FunkMonk, Charles R.
Knight, vectorized by Zimices, Todd Marshall, vectorized by Zimices,
Chris Jennings (Risiatto), Inessa Voet, Tony Ayling (vectorized by T.
Michael Keesey), Lukasiniho, Javiera Constanzo, Jon Hill, Mali’o Kodis,
traced image from the National Science Foundation’s Turbellarian
Taxonomic Database, Rachel Shoop, Yan Wong (vectorization) from 1873
illustration, Jon Hill (Photo by DickDaniels:
<http://en.wikipedia.org/wiki/File:Green_Woodhoopoe_RWD7.jpg>), Chloé
Schmidt, Catherine Yasuda, Ellen Edmonson and Hugh Chrisp (illustration)
and Timothy J. Bartley (silhouette), Haplochromis (vectorized by T.
Michael Keesey), Milton Tan, Smokeybjb, Maija Karala, Mathew Wedel, Iain
Reid, Scott Hartman (modified by T. Michael Keesey), Scott Reid, Emily
Willoughby, Noah Schlottman, photo by Reinhard Jahn, Chuanixn Yu, Gustav
Mützel, Pranav Iyer (grey ideas), Sean McCann, Lankester Edwin Ray
(vectorized by T. Michael Keesey), Manabu Bessho-Uehara, Crystal Maier,
Stuart Humphries, Francesco Veronesi (vectorized by T. Michael Keesey),
Armin Reindl, Mike Hanson, Lauren Anderson, Bruno C. Vellutini, James
Neenan, T. Tischler, (unknown), Scott Hartman (vectorized by William
Gearty), Matt Martyniuk, Martien Brand (original photo), Renato Santos
(vector silhouette), Sarah Alewijnse, Ghedo (vectorized by T. Michael
Keesey), Tracy A. Heath, Walter Vladimir, Theodore W. Pietsch
(photography) and T. Michael Keesey (vectorization), Kailah Thorn & Mark
Hutchinson, M Kolmann, T. Michael Keesey (photo by Darren Swim), Matthew
Hooge (vectorized by T. Michael Keesey), Robert Gay, G. M. Woodward,
Gopal Murali, NOAA Great Lakes Environmental Research Laboratory
(illustration) and Timothy J. Bartley (silhouette), Conty (vectorized by
T. Michael Keesey), Konsta Happonen, from a CC-BY-NC image by pelhonen
on iNaturalist, Nobu Tamura, vectorized by Zimices, Henry Lydecker,
James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis
Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey), Sherman
Foote Denton (illustration, 1897) and Timothy J. Bartley (silhouette)

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    795.580527 |    483.035243 | Matt Crook                                                                                                                                                            |
|   2 |    535.065812 |    518.158677 | Chris huh                                                                                                                                                             |
|   3 |    558.318903 |    143.105692 | Andy Wilson                                                                                                                                                           |
|   4 |    800.900841 |    275.371655 | Zimices                                                                                                                                                               |
|   5 |    372.417520 |    432.227729 | Caleb M. Brown                                                                                                                                                        |
|   6 |    226.622224 |    223.984553 | Mali’o Kodis, drawing by Manvir Singh                                                                                                                                 |
|   7 |    970.929609 |    487.736185 | Michelle Site                                                                                                                                                         |
|   8 |    897.454518 |    172.897564 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                      |
|   9 |     74.959769 |     92.648409 | Margot Michaud                                                                                                                                                        |
|  10 |    947.407044 |     93.449020 | Ferran Sayol                                                                                                                                                          |
|  11 |    158.216534 |    442.914628 | JCGiron                                                                                                                                                               |
|  12 |    489.426301 |    254.145864 | C. Camilo Julián-Caballero                                                                                                                                            |
|  13 |    667.385340 |    346.661160 | T. Michael Keesey                                                                                                                                                     |
|  14 |    886.782011 |    713.471188 | ДиБгд (vectorized by T. Michael Keesey)                                                                                                                               |
|  15 |    517.210672 |    379.235066 | Ludwik Gąsiorowski                                                                                                                                                    |
|  16 |    439.758667 |    484.642942 | Scott Hartman                                                                                                                                                         |
|  17 |    161.058746 |    543.728183 | NA                                                                                                                                                                    |
|  18 |    195.938816 |    653.827686 | Jack Mayer Wood                                                                                                                                                       |
|  19 |    162.645058 |    272.376522 | Yan Wong                                                                                                                                                              |
|  20 |    962.213138 |    278.012815 | Zimices                                                                                                                                                               |
|  21 |    656.955702 |    467.145759 | Scott Hartman                                                                                                                                                         |
|  22 |    565.567019 |    653.678043 | Dean Schnabel                                                                                                                                                         |
|  23 |    672.480825 |    713.503270 | Ferran Sayol                                                                                                                                                          |
|  24 |    447.893530 |    597.894516 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  25 |    302.955701 |     83.473406 | Margot Michaud                                                                                                                                                        |
|  26 |    159.687758 |    759.305489 | Chris huh                                                                                                                                                             |
|  27 |    390.357287 |    349.837861 | Katie S. Collins                                                                                                                                                      |
|  28 |    738.801714 |    102.605792 | Steven Traver                                                                                                                                                         |
|  29 |    808.455704 |    371.269336 | Zimices                                                                                                                                                               |
|  30 |     76.555244 |    246.346863 | Gareth Monger                                                                                                                                                         |
|  31 |    370.449391 |    764.497801 | Tasman Dixon                                                                                                                                                          |
|  32 |    346.527578 |    251.173518 | FunkMonk (Michael B. H.)                                                                                                                                              |
|  33 |    385.468569 |    553.244311 | Felix Vaux                                                                                                                                                            |
|  34 |    303.009440 |    510.349150 | Marmelad                                                                                                                                                              |
|  35 |    228.425178 |    361.998355 | Jack Mayer Wood                                                                                                                                                       |
|  36 |    756.485865 |    580.605791 | Matt Crook                                                                                                                                                            |
|  37 |    258.501250 |    318.393278 | T. Michael Keesey                                                                                                                                                     |
|  38 |    530.520405 |     24.817039 | Chris huh                                                                                                                                                             |
|  39 |    758.855976 |    200.900070 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
|  40 |     72.244948 |    525.060757 | Alexander Schmidt-Lebuhn                                                                                                                                              |
|  41 |     62.634741 |    435.727118 | Andy Wilson                                                                                                                                                           |
|  42 |    941.894641 |    605.932282 | Ignacio Contreras                                                                                                                                                     |
|  43 |    630.595200 |    553.078135 | Carlos Cano-Barbacil                                                                                                                                                  |
|  44 |    948.718089 |    407.671520 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                           |
|  45 |    385.934014 |    654.554904 | (after Spotila 2004)                                                                                                                                                  |
|  46 |    302.744489 |    596.457082 | Tasman Dixon                                                                                                                                                          |
|  47 |    249.898275 |    697.157796 | Duane Raver/USFWS                                                                                                                                                     |
|  48 |    780.204799 |     31.370672 | Zimices                                                                                                                                                               |
|  49 |    575.717706 |     76.448205 | Gareth Monger                                                                                                                                                         |
|  50 |    595.301268 |    324.469059 | C. Camilo Julián-Caballero                                                                                                                                            |
|  51 |    412.306764 |     29.699779 | Zimices                                                                                                                                                               |
|  52 |    418.480875 |    738.517138 | Chris huh                                                                                                                                                             |
|  53 |     99.988649 |    703.706006 | Andrew A. Farke                                                                                                                                                       |
|  54 |    139.000963 |    162.899489 | Carlos Cano-Barbacil                                                                                                                                                  |
|  55 |    180.035728 |     43.609491 | Dean Schnabel                                                                                                                                                         |
|  56 |    632.766424 |    170.787678 | FunkMonk \[Michael B.H.\] (modified by T. Michael Keesey)                                                                                                             |
|  57 |    745.955340 |    641.092773 | NA                                                                                                                                                                    |
|  58 |    413.938673 |    125.252775 | Matt Crook                                                                                                                                                            |
|  59 |    957.035444 |    325.090194 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                        |
|  60 |     50.020471 |    612.554278 | NA                                                                                                                                                                    |
|  61 |    281.702756 |    678.116490 | NA                                                                                                                                                                    |
|  62 |    651.951479 |    605.802800 | Markus A. Grohme                                                                                                                                                      |
|  63 |     63.555825 |    395.789460 | Jagged Fang Designs                                                                                                                                                   |
|  64 |    689.238517 |    414.521802 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  65 |    777.336892 |    760.294730 | Noah Schlottman, photo by Antonio Guillén                                                                                                                             |
|  66 |    555.082265 |    726.074947 | Original drawing by Antonov, vectorized by Roberto Díaz Sibaja                                                                                                        |
|  67 |    844.613263 |    638.880032 | Matt Dempsey                                                                                                                                                          |
|  68 |    170.590866 |    599.631516 | T. Michael Keesey                                                                                                                                                     |
|  69 |    650.923695 |    270.211368 | Darius Nau                                                                                                                                                            |
|  70 |    548.575749 |    472.773007 | Beth Reinke                                                                                                                                                           |
|  71 |    890.793778 |    550.735096 | Markus A. Grohme                                                                                                                                                      |
|  72 |    672.212836 |    505.021593 | Michael P. Taylor                                                                                                                                                     |
|  73 |    250.743742 |    526.278356 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  74 |    222.226644 |    467.591324 | Ferran Sayol                                                                                                                                                          |
|  75 |    659.558989 |    208.344760 | Michelle Site                                                                                                                                                         |
|  76 |    226.191100 |    720.676503 | T. Michael Keesey                                                                                                                                                     |
|  77 |    660.568903 |     37.214452 | Scott Hartman                                                                                                                                                         |
|  78 |    961.335223 |    746.151348 | Joanna Wolfe                                                                                                                                                          |
|  79 |     24.073808 |    724.652092 | Martin R. Smith, after Skovsted et al 2015                                                                                                                            |
|  80 |     37.467066 |    171.197734 | T. Michael Keesey                                                                                                                                                     |
|  81 |    875.448740 |     71.092774 | Ferran Sayol                                                                                                                                                          |
|  82 |    722.304834 |    351.522905 | Audrey Ely                                                                                                                                                            |
|  83 |    772.424136 |    788.836216 | Markus A. Grohme                                                                                                                                                      |
|  84 |    296.035707 |    760.186323 | Jagged Fang Designs                                                                                                                                                   |
|  85 |    980.286733 |     66.399004 | Sharon Wegner-Larsen                                                                                                                                                  |
|  86 |    982.756391 |    567.778390 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  87 |    761.413742 |    152.376422 | T. Michael Keesey                                                                                                                                                     |
|  88 |    540.796120 |    565.585337 | Francisco Gascó (modified by Michael P. Taylor)                                                                                                                       |
|  89 |    266.308237 |     11.745864 | CNZdenek                                                                                                                                                              |
|  90 |    278.034412 |    198.425817 | Harold N Eyster                                                                                                                                                       |
|  91 |    965.106321 |    206.973060 | Roberto Díaz Sibaja                                                                                                                                                   |
|  92 |    872.897520 |    222.651805 | Zimices, based in Mauricio Antón skeletal                                                                                                                             |
|  93 |     94.261205 |    348.431111 | John Curtis (vectorized by T. Michael Keesey)                                                                                                                         |
|  94 |    424.610391 |    441.881066 | Tasman Dixon                                                                                                                                                          |
|  95 |    708.387231 |    531.362694 | Carlos Cano-Barbacil                                                                                                                                                  |
|  96 |     48.429746 |    151.721057 | Markus A. Grohme                                                                                                                                                      |
|  97 |     91.096764 |    401.316171 | Jagged Fang Designs                                                                                                                                                   |
|  98 |    455.079101 |    787.300077 | Gareth Monger                                                                                                                                                         |
|  99 |    961.786747 |    770.537675 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 100 |    864.414861 |    426.029805 | Erika Schumacher                                                                                                                                                      |
| 101 |    443.653794 |    508.808962 | Zimices                                                                                                                                                               |
| 102 |    604.731251 |    774.762971 | Gareth Monger                                                                                                                                                         |
| 103 |    586.971130 |    718.746504 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 104 |    867.740196 |     15.786693 | Jagged Fang Designs                                                                                                                                                   |
| 105 |    651.416069 |    145.310473 | Margot Michaud                                                                                                                                                        |
| 106 |    279.331421 |    156.056056 | Carlos Cano-Barbacil                                                                                                                                                  |
| 107 |    496.094717 |    602.732512 | Zimices                                                                                                                                                               |
| 108 |    632.887870 |    191.840101 | nicubunu                                                                                                                                                              |
| 109 |    586.438583 |    434.141078 | Jagged Fang Designs                                                                                                                                                   |
| 110 |    117.650777 |    276.988742 | Gareth Monger                                                                                                                                                         |
| 111 |    142.333214 |     91.535164 | Matt Crook                                                                                                                                                            |
| 112 |    965.302702 |    656.574426 | Matt Crook                                                                                                                                                            |
| 113 |    887.151080 |    323.386539 | Fir0002/Flagstaffotos (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
| 114 |    900.711922 |    511.391672 | Steven Traver                                                                                                                                                         |
| 115 |    468.130404 |    704.123319 | Andy Wilson                                                                                                                                                           |
| 116 |    936.310808 |     23.839294 | Noah Schlottman, photo by Carol Cummings                                                                                                                              |
| 117 |     27.378414 |    285.174242 | Gareth Monger                                                                                                                                                         |
| 118 |    947.747304 |    371.713813 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 119 |    583.877366 |    580.865483 | NA                                                                                                                                                                    |
| 120 |    172.662257 |     14.168232 | Erika Schumacher                                                                                                                                                      |
| 121 |    370.660196 |    516.346220 | Steven Traver                                                                                                                                                         |
| 122 |    404.951460 |    703.710734 | Tasman Dixon                                                                                                                                                          |
| 123 |    763.050081 |    393.101106 | Gareth Monger                                                                                                                                                         |
| 124 |    202.020164 |     73.231194 | Noah Schlottman, photo by Carol Cummings                                                                                                                              |
| 125 |    388.019016 |     82.068747 | Xvazquez (vectorized by William Gearty)                                                                                                                               |
| 126 |    867.707483 |    577.430803 | T. Michael Keesey (from a photo by Maximilian Paradiz)                                                                                                                |
| 127 |    912.784671 |     12.483227 | Kamil S. Jaron                                                                                                                                                        |
| 128 |    848.429253 |    755.691511 | Jagged Fang Designs                                                                                                                                                   |
| 129 |     49.190032 |    248.076890 | Gareth Monger                                                                                                                                                         |
| 130 |    610.968350 |    368.840023 | TaraTaylorDesign                                                                                                                                                      |
| 131 |    736.982753 |    665.013321 | Margot Michaud                                                                                                                                                        |
| 132 |    227.938951 |     72.861482 | Kelly                                                                                                                                                                 |
| 133 |    991.199546 |      6.938798 | Mo Hassan                                                                                                                                                             |
| 134 |    857.902510 |    317.972059 | Melissa Broussard                                                                                                                                                     |
| 135 |    654.696171 |     72.406085 | Chris huh                                                                                                                                                             |
| 136 |     19.963018 |     39.379623 | Sarah Werning                                                                                                                                                         |
| 137 |     64.311912 |     58.451819 | Steven Traver                                                                                                                                                         |
| 138 |    815.869695 |    577.703605 | Zimices                                                                                                                                                               |
| 139 |    765.868785 |    325.754969 | Kent Sorgon                                                                                                                                                           |
| 140 |    523.338232 |    764.183713 | Scott Hartman                                                                                                                                                         |
| 141 |    241.350123 |    202.728744 | Tauana J. Cunha                                                                                                                                                       |
| 142 |    290.644485 |    785.741970 | NA                                                                                                                                                                    |
| 143 |    181.042174 |    126.796560 | Zimices                                                                                                                                                               |
| 144 |    397.591253 |    108.807994 | Chris huh                                                                                                                                                             |
| 145 |    245.818332 |    390.815648 | Scott Hartman                                                                                                                                                         |
| 146 |    839.791910 |    614.294049 | Scott Hartman                                                                                                                                                         |
| 147 |    266.348981 |    457.035040 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 148 |    516.087240 |    197.396797 | Matt Crook                                                                                                                                                            |
| 149 |     16.828212 |    361.206354 | Chris huh                                                                                                                                                             |
| 150 |    264.356608 |    183.287465 | Birgit Lang                                                                                                                                                           |
| 151 |    814.033125 |    669.466226 | David Sim (photograph) and T. Michael Keesey (vectorization)                                                                                                          |
| 152 |     19.962270 |    312.878388 | Steven Traver                                                                                                                                                         |
| 153 |    889.261563 |    473.352501 | Andy Wilson                                                                                                                                                           |
| 154 |    357.366022 |    293.576694 | T. Michael Keesey                                                                                                                                                     |
| 155 |    571.486533 |    783.049107 | Collin Gross                                                                                                                                                          |
| 156 |    874.729326 |    780.095066 | Bob Goldstein, Vectorization:Jake Warner                                                                                                                              |
| 157 |    559.165799 |    195.687365 | Ferran Sayol                                                                                                                                                          |
| 158 |    723.183044 |    439.896358 | Mathieu Pélissié                                                                                                                                                      |
| 159 |    738.151722 |    709.339401 | Matt Crook                                                                                                                                                            |
| 160 |    341.775624 |    688.090144 | Steven Coombs                                                                                                                                                         |
| 161 |    289.275890 |    376.081001 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 162 |    726.905982 |    511.130753 | Xavier Giroux-Bougard                                                                                                                                                 |
| 163 |    103.669110 |    347.426264 | Dianne Bray / Museum Victoria (vectorized by T. Michael Keesey)                                                                                                       |
| 164 |     38.099943 |    306.260202 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 165 |    137.276887 |    720.875419 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 166 |    702.317732 |    229.093706 | Scott Hartman                                                                                                                                                         |
| 167 |    724.584257 |    303.343694 | Gareth Monger                                                                                                                                                         |
| 168 |     90.246202 |     32.150151 | Maha Ghazal                                                                                                                                                           |
| 169 |    265.538265 |    545.070350 | Katie S. Collins                                                                                                                                                      |
| 170 |    135.622178 |    196.707510 | L. Shyamal                                                                                                                                                            |
| 171 |    482.904343 |    454.660627 | Gareth Monger                                                                                                                                                         |
| 172 |    966.734923 |    354.982579 | Carlos Cano-Barbacil                                                                                                                                                  |
| 173 |    213.488564 |    105.244054 | Rene Martin                                                                                                                                                           |
| 174 |    893.497320 |    359.107190 | Matt Crook                                                                                                                                                            |
| 175 |    475.392232 |    155.724508 | Evan-Amos (vectorized by T. Michael Keesey)                                                                                                                           |
| 176 |    190.235836 |     98.516131 | Matt Crook                                                                                                                                                            |
| 177 |    288.749223 |    326.485613 | NA                                                                                                                                                                    |
| 178 |    626.915222 |    637.517561 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 179 |     21.746429 |    227.880962 | Gareth Monger                                                                                                                                                         |
| 180 |    858.850584 |    465.027315 | T. Michael Keesey                                                                                                                                                     |
| 181 |    475.040914 |    330.789840 | NA                                                                                                                                                                    |
| 182 |    485.751320 |    196.303006 | Kai R. Caspar                                                                                                                                                         |
| 183 |    613.228796 |    116.747609 | Christoph Schomburg                                                                                                                                                   |
| 184 |     23.105468 |    193.186686 | Matt Crook                                                                                                                                                            |
| 185 |     57.429298 |    355.297099 | Xavier Giroux-Bougard                                                                                                                                                 |
| 186 |    228.275485 |    167.931680 | Ferran Sayol                                                                                                                                                          |
| 187 |    472.055874 |    399.074364 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 188 |    464.506349 |    657.948098 | Margot Michaud                                                                                                                                                        |
| 189 |    838.246458 |    187.876851 | Zimices                                                                                                                                                               |
| 190 |    587.627606 |     93.534387 | Pete Buchholz                                                                                                                                                         |
| 191 |    475.831722 |    627.192582 | Jaime Headden                                                                                                                                                         |
| 192 |    139.051368 |    667.841376 | Andy Wilson                                                                                                                                                           |
| 193 |    463.892083 |    547.900887 | Margot Michaud                                                                                                                                                        |
| 194 |    350.347715 |    707.190980 | Richard Ruggiero, vectorized by Zimices                                                                                                                               |
| 195 |    163.342325 |    195.355915 | Steven Traver                                                                                                                                                         |
| 196 |    326.170508 |    780.544655 | Steven Traver                                                                                                                                                         |
| 197 |    685.840053 |    252.887776 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 198 |    789.514150 |    560.872135 | Margot Michaud                                                                                                                                                        |
| 199 |    734.068854 |    611.441840 | Birgit Lang                                                                                                                                                           |
| 200 |    876.561829 |    454.982702 | Fritz Geller-Grimm (vectorized by T. Michael Keesey)                                                                                                                  |
| 201 |    291.634383 |    180.416069 | L. Shyamal                                                                                                                                                            |
| 202 |    815.340073 |    792.742832 | Steven Traver                                                                                                                                                         |
| 203 |    880.658913 |    294.747223 | Matt Celeskey                                                                                                                                                         |
| 204 |    798.075589 |    100.314677 | Ferran Sayol                                                                                                                                                          |
| 205 |    855.999201 |    121.005235 | Ferran Sayol                                                                                                                                                          |
| 206 |    107.640636 |    320.248861 | Mathilde Cordellier                                                                                                                                                   |
| 207 |     50.778244 |     14.824450 | Arthur Grosset (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey        |
| 208 |    428.292084 |    179.847846 | Jagged Fang Designs                                                                                                                                                   |
| 209 |    798.217107 |    235.867779 | Harold N Eyster                                                                                                                                                       |
| 210 |    157.132886 |    789.187409 | Markus A. Grohme                                                                                                                                                      |
| 211 |    459.299229 |    444.650324 | Michelle Site                                                                                                                                                         |
| 212 |    442.531306 |    637.835059 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 213 |   1005.615606 |    171.199044 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                              |
| 214 |    774.107658 |    685.832484 | Robert Gay, modifed from Olegivvit                                                                                                                                    |
| 215 |     46.127449 |    275.153327 | Margot Michaud                                                                                                                                                        |
| 216 |    562.883412 |    407.971054 | Rebecca Groom                                                                                                                                                         |
| 217 |    520.457805 |    111.274144 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 218 |    596.209841 |    409.982199 | Margot Michaud                                                                                                                                                        |
| 219 |    465.283374 |    338.960802 | Jagged Fang Designs                                                                                                                                                   |
| 220 |    218.180891 |    506.310197 | Chris huh                                                                                                                                                             |
| 221 |    915.471722 |    364.292647 | Matt Crook                                                                                                                                                            |
| 222 |     89.565649 |    324.948172 | Collin Gross                                                                                                                                                          |
| 223 |    342.018058 |    300.911290 | T. Michael Keesey                                                                                                                                                     |
| 224 |    507.002708 |    446.944939 | Zimices                                                                                                                                                               |
| 225 |    260.847481 |    222.213542 | Margot Michaud                                                                                                                                                        |
| 226 |    911.131018 |    473.982098 | David Orr                                                                                                                                                             |
| 227 |    830.754914 |     59.444015 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 228 |    315.519671 |    721.313984 | Warren H (photography), T. Michael Keesey (vectorization)                                                                                                             |
| 229 |    901.080995 |    667.431544 | Steven Traver                                                                                                                                                         |
| 230 |    262.294299 |    429.331102 | Mathieu Basille                                                                                                                                                       |
| 231 |     32.383863 |    462.852255 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 232 |    772.925187 |    604.163168 | Jaime Headden                                                                                                                                                         |
| 233 |    650.348242 |      6.769934 | Tasman Dixon                                                                                                                                                          |
| 234 |    532.098752 |    595.971715 | Dean Schnabel                                                                                                                                                         |
| 235 |    544.933188 |    792.925070 | Jagged Fang Designs                                                                                                                                                   |
| 236 |    604.071712 |    146.113265 | Mali’o Kodis, photograph by John Slapcinsky                                                                                                                           |
| 237 |    105.170456 |    788.486412 | Steven Traver                                                                                                                                                         |
| 238 |    847.545667 |    332.478089 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 239 |    467.500435 |    305.895189 | Birgit Lang                                                                                                                                                           |
| 240 |    614.402589 |    523.817483 | Margot Michaud                                                                                                                                                        |
| 241 |     53.665436 |    755.537042 | Chris huh                                                                                                                                                             |
| 242 |   1005.808065 |    374.827232 | Steven Traver                                                                                                                                                         |
| 243 |    825.691046 |    410.371999 | T. Michael Keesey                                                                                                                                                     |
| 244 |    445.464701 |    461.949614 | Margot Michaud                                                                                                                                                        |
| 245 |    111.311136 |    416.055234 | Steven Traver                                                                                                                                                         |
| 246 |    988.749431 |    622.019797 | Timothy Knepp of the U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                |
| 247 |    705.466770 |     54.209267 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 248 |    169.141250 |    699.763462 | Abraão Leite                                                                                                                                                          |
| 249 |    651.994403 |    236.874086 | U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                                     |
| 250 |    212.084063 |    670.990493 | Andy Wilson                                                                                                                                                           |
| 251 |    677.430116 |    577.990227 | Margot Michaud                                                                                                                                                        |
| 252 |    666.272935 |    631.811079 | Scott Hartman                                                                                                                                                         |
| 253 |    752.764134 |    684.049908 | Steven Traver                                                                                                                                                         |
| 254 |    590.491839 |    344.375647 | Lily Hughes                                                                                                                                                           |
| 255 |     16.077866 |    136.672262 | New York Zoological Society                                                                                                                                           |
| 256 |    138.487501 |    366.655925 | Sarah Werning                                                                                                                                                         |
| 257 |    869.074558 |    262.781587 | Mariana Ruiz Villarreal (modified by T. Michael Keesey)                                                                                                               |
| 258 |    413.608690 |    300.090618 | Birgit Lang                                                                                                                                                           |
| 259 |    424.601896 |     62.124902 | Yan Wong                                                                                                                                                              |
| 260 |    883.553550 |    395.706077 | Christoph Schomburg                                                                                                                                                   |
| 261 |    394.276613 |    205.990014 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                              |
| 262 |    693.387201 |    781.725833 | Zimices                                                                                                                                                               |
| 263 |    820.263776 |    212.082056 | Arthur Weasley (vectorized by T. Michael Keesey)                                                                                                                      |
| 264 |     88.875768 |      5.178283 | Juan Carlos Jerí                                                                                                                                                      |
| 265 |    623.874469 |     12.914132 | Aline M. Ghilardi                                                                                                                                                     |
| 266 |    267.790026 |    296.154825 | NA                                                                                                                                                                    |
| 267 |    310.842090 |    555.433175 | Markus A. Grohme                                                                                                                                                      |
| 268 |    805.591945 |    137.302459 | Matt Wilkins                                                                                                                                                          |
| 269 |    206.215085 |     17.685830 | Tyler Greenfield and Scott Hartman                                                                                                                                    |
| 270 |    101.760474 |    613.234630 | Kamil S. Jaron                                                                                                                                                        |
| 271 |    408.187272 |    461.462175 | Scott Hartman                                                                                                                                                         |
| 272 |    660.265895 |    124.451982 | Scott Hartman                                                                                                                                                         |
| 273 |    513.048855 |    138.370620 | Margot Michaud                                                                                                                                                        |
| 274 |    948.130710 |    708.643814 | Matt Crook                                                                                                                                                            |
| 275 |    223.428501 |    409.702881 | Michelle Site                                                                                                                                                         |
| 276 |    597.158570 |    296.263220 | FunkMonk                                                                                                                                                              |
| 277 |    314.220893 |    456.601057 | Duane Raver/USFWS                                                                                                                                                     |
| 278 |     55.039336 |    332.339038 | Steven Traver                                                                                                                                                         |
| 279 |    444.327791 |    772.854482 | Charles R. Knight, vectorized by Zimices                                                                                                                              |
| 280 |    572.014654 |    387.601188 | Todd Marshall, vectorized by Zimices                                                                                                                                  |
| 281 |    243.245707 |    658.651071 | Zimices                                                                                                                                                               |
| 282 |    269.766727 |    242.251284 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 283 |    729.832482 |    562.658213 | Chris Jennings (Risiatto)                                                                                                                                             |
| 284 |    231.404252 |    590.618658 | Michelle Site                                                                                                                                                         |
| 285 |    466.974598 |    769.966494 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 286 |    550.673675 |    602.981120 | Matt Crook                                                                                                                                                            |
| 287 |     33.881978 |    341.760203 | NA                                                                                                                                                                    |
| 288 |    831.987929 |    233.621187 | Inessa Voet                                                                                                                                                           |
| 289 |    218.682765 |    298.416809 | Matt Crook                                                                                                                                                            |
| 290 |    320.200625 |     20.083808 | Zimices                                                                                                                                                               |
| 291 |    757.306980 |    730.595207 | Margot Michaud                                                                                                                                                        |
| 292 |    568.455733 |    544.184665 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 293 |    774.991146 |    712.815541 | Lukasiniho                                                                                                                                                            |
| 294 |    725.820107 |    367.093230 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 295 |    756.085091 |    239.982097 | Javiera Constanzo                                                                                                                                                     |
| 296 |    499.208626 |    786.889262 | Margot Michaud                                                                                                                                                        |
| 297 |    338.659634 |    211.127676 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                      |
| 298 |    630.801550 |    391.462715 | Jagged Fang Designs                                                                                                                                                   |
| 299 |    261.133538 |    741.888805 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 300 |    134.326810 |    319.857119 | Jon Hill                                                                                                                                                              |
| 301 |    880.491444 |    248.276903 | Mali’o Kodis, traced image from the National Science Foundation’s Turbellarian Taxonomic Database                                                                     |
| 302 |    657.618307 |    529.948252 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 303 |    582.010287 |    611.577762 | Markus A. Grohme                                                                                                                                                      |
| 304 |    642.718702 |    583.090812 | C. Camilo Julián-Caballero                                                                                                                                            |
| 305 |     26.888916 |    257.647076 | T. Michael Keesey                                                                                                                                                     |
| 306 |    742.135117 |    555.449408 | Rebecca Groom                                                                                                                                                         |
| 307 |    323.057728 |    378.408669 | Gareth Monger                                                                                                                                                         |
| 308 |    485.528204 |    568.154202 | Markus A. Grohme                                                                                                                                                      |
| 309 |   1005.599948 |    558.571108 | Rachel Shoop                                                                                                                                                          |
| 310 |    783.512099 |     65.036929 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 311 |    912.425736 |    443.526760 | Margot Michaud                                                                                                                                                        |
| 312 |    294.954975 |    637.419896 | Zimices                                                                                                                                                               |
| 313 |    985.245566 |    679.485371 | NA                                                                                                                                                                    |
| 314 |    436.449141 |     83.762549 | Matt Crook                                                                                                                                                            |
| 315 |    999.474402 |    355.467855 | Dean Schnabel                                                                                                                                                         |
| 316 |    606.777226 |     38.168390 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 317 |    760.327522 |    374.254977 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 318 |    950.208048 |    660.581421 | Jagged Fang Designs                                                                                                                                                   |
| 319 |    524.335830 |    296.662999 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 320 |   1005.245242 |    713.824000 | Zimices                                                                                                                                                               |
| 321 |    198.887268 |    408.636136 | Yan Wong (vectorization) from 1873 illustration                                                                                                                       |
| 322 |    621.613890 |    415.232708 | Markus A. Grohme                                                                                                                                                      |
| 323 |    553.857529 |     50.115475 | Steven Traver                                                                                                                                                         |
| 324 |   1004.797665 |    696.098601 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 325 |    973.892231 |    377.999997 | Andy Wilson                                                                                                                                                           |
| 326 |     20.349088 |    244.583134 | Scott Hartman                                                                                                                                                         |
| 327 |    116.043942 |     16.404822 | Jon Hill (Photo by DickDaniels: <http://en.wikipedia.org/wiki/File:Green_Woodhoopoe_RWD7.jpg>)                                                                        |
| 328 |    701.422233 |    485.257798 | Scott Hartman                                                                                                                                                         |
| 329 |    954.143308 |     40.070988 | Matt Crook                                                                                                                                                            |
| 330 |    311.406632 |    209.243062 | Zimices                                                                                                                                                               |
| 331 |    312.924037 |    660.121919 | Chloé Schmidt                                                                                                                                                         |
| 332 |    475.588129 |    754.839584 | Jack Mayer Wood                                                                                                                                                       |
| 333 |    505.809691 |    504.132195 | Zimices                                                                                                                                                               |
| 334 |     16.832392 |     64.999072 | Matt Crook                                                                                                                                                            |
| 335 |    984.812814 |    534.367469 | Lukasiniho                                                                                                                                                            |
| 336 |    887.585863 |    116.451289 | Gareth Monger                                                                                                                                                         |
| 337 |    734.025654 |    289.179662 | Catherine Yasuda                                                                                                                                                      |
| 338 |    640.041574 |    485.350642 | Margot Michaud                                                                                                                                                        |
| 339 |    950.241088 |    235.125795 | Chris huh                                                                                                                                                             |
| 340 |    158.314483 |    772.818689 | C. Camilo Julián-Caballero                                                                                                                                            |
| 341 |     17.037479 |    410.698818 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                                     |
| 342 |     99.418779 |    648.977650 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                        |
| 343 |    853.984421 |    602.206762 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 344 |    391.358647 |    693.927976 | Scott Hartman                                                                                                                                                         |
| 345 |    532.588417 |    316.119656 | David Orr                                                                                                                                                             |
| 346 |    237.646061 |    573.367221 | Christoph Schomburg                                                                                                                                                   |
| 347 |    990.509755 |     23.208987 | Margot Michaud                                                                                                                                                        |
| 348 |    468.610424 |    184.776725 | Jagged Fang Designs                                                                                                                                                   |
| 349 |     68.617253 |    786.470926 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 350 |    487.790308 |    732.253485 | Yan Wong                                                                                                                                                              |
| 351 |    128.389108 |    212.949349 | Markus A. Grohme                                                                                                                                                      |
| 352 |    706.560495 |    162.770037 | CNZdenek                                                                                                                                                              |
| 353 |    616.842929 |     58.979363 | Matt Celeskey                                                                                                                                                         |
| 354 |    180.270064 |    682.351106 | Mathieu Pélissié                                                                                                                                                      |
| 355 |    234.653797 |    372.776706 | Markus A. Grohme                                                                                                                                                      |
| 356 |    370.987769 |    535.262024 | Andrew A. Farke                                                                                                                                                       |
| 357 |    254.306278 |    608.793533 | Milton Tan                                                                                                                                                            |
| 358 |    880.978399 |    443.845710 | Smokeybjb                                                                                                                                                             |
| 359 |    805.557317 |    655.161007 | Chris huh                                                                                                                                                             |
| 360 |    494.453527 |    313.516465 | Maija Karala                                                                                                                                                          |
| 361 |    870.621686 |     99.971294 | Mathew Wedel                                                                                                                                                          |
| 362 |    918.238003 |    718.459915 | Tasman Dixon                                                                                                                                                          |
| 363 |    665.496905 |    414.229639 | Jagged Fang Designs                                                                                                                                                   |
| 364 |    487.583654 |    674.836236 | NA                                                                                                                                                                    |
| 365 |    152.405025 |     21.591036 | Iain Reid                                                                                                                                                             |
| 366 |    629.075320 |    689.607797 | Andy Wilson                                                                                                                                                           |
| 367 |    708.036226 |     41.654893 | Scott Hartman (modified by T. Michael Keesey)                                                                                                                         |
| 368 |    999.771060 |    237.267136 | Lukasiniho                                                                                                                                                            |
| 369 |     33.705499 |    214.924312 | Markus A. Grohme                                                                                                                                                      |
| 370 |    110.709317 |    660.361550 | Dean Schnabel                                                                                                                                                         |
| 371 |    793.423655 |    168.058210 | Scott Reid                                                                                                                                                            |
| 372 |    144.433706 |    508.089851 | Emily Willoughby                                                                                                                                                      |
| 373 |    221.179097 |    205.631123 | Noah Schlottman, photo by Reinhard Jahn                                                                                                                               |
| 374 |    791.294862 |    549.407978 | Christoph Schomburg                                                                                                                                                   |
| 375 |    380.561109 |    599.453775 | Ferran Sayol                                                                                                                                                          |
| 376 |    231.461919 |    489.421235 | Chuanixn Yu                                                                                                                                                           |
| 377 |    321.666514 |    617.836400 | Markus A. Grohme                                                                                                                                                      |
| 378 |    863.012517 |    516.302444 | Gustav Mützel                                                                                                                                                         |
| 379 |    860.953646 |     38.598320 | Zimices                                                                                                                                                               |
| 380 |    642.920651 |    668.963105 | T. Michael Keesey                                                                                                                                                     |
| 381 |    260.647708 |     34.993822 | Matt Crook                                                                                                                                                            |
| 382 |    519.685380 |     43.097006 | Pranav Iyer (grey ideas)                                                                                                                                              |
| 383 |    115.835087 |    230.697283 | NA                                                                                                                                                                    |
| 384 |    801.048051 |    186.414949 | NA                                                                                                                                                                    |
| 385 |    897.719431 |     93.079046 | Sean McCann                                                                                                                                                           |
| 386 |    633.209989 |    300.158471 | Carlos Cano-Barbacil                                                                                                                                                  |
| 387 |    188.838697 |     44.612802 | Chris huh                                                                                                                                                             |
| 388 |    135.471377 |    680.730963 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 389 |    707.834447 |    321.273894 | Christoph Schomburg                                                                                                                                                   |
| 390 |    671.573402 |    193.067984 | Iain Reid                                                                                                                                                             |
| 391 |     94.812344 |    587.059324 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                                 |
| 392 |     54.765431 |    740.248552 | Andy Wilson                                                                                                                                                           |
| 393 |    115.765134 |    462.451804 | Katie S. Collins                                                                                                                                                      |
| 394 |    759.969667 |    164.482384 | Manabu Bessho-Uehara                                                                                                                                                  |
| 395 |    996.605056 |    422.561320 | Margot Michaud                                                                                                                                                        |
| 396 |    643.704196 |    100.470672 | Crystal Maier                                                                                                                                                         |
| 397 |    322.210434 |    326.097097 | Chris huh                                                                                                                                                             |
| 398 |    659.333209 |    593.994197 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                        |
| 399 |    794.532548 |    328.450628 | Carlos Cano-Barbacil                                                                                                                                                  |
| 400 |    494.092619 |    551.649022 | Margot Michaud                                                                                                                                                        |
| 401 |    276.537979 |    655.437963 | Stuart Humphries                                                                                                                                                      |
| 402 |   1011.478133 |    636.147035 | Francesco Veronesi (vectorized by T. Michael Keesey)                                                                                                                  |
| 403 |    230.486255 |    118.661694 | Armin Reindl                                                                                                                                                          |
| 404 |    707.509992 |    149.363878 | Ignacio Contreras                                                                                                                                                     |
| 405 |    277.792185 |    500.316103 | Markus A. Grohme                                                                                                                                                      |
| 406 |    712.353891 |    176.436469 | Rebecca Groom                                                                                                                                                         |
| 407 |    545.643849 |    780.629281 | Carlos Cano-Barbacil                                                                                                                                                  |
| 408 |    276.412812 |    773.983527 | Mike Hanson                                                                                                                                                           |
| 409 |   1010.034954 |    511.069932 | Sarah Werning                                                                                                                                                         |
| 410 |    656.408385 |    651.650611 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 411 |    435.786106 |    312.405989 | Zimices                                                                                                                                                               |
| 412 |    630.609875 |    348.584240 | Lauren Anderson                                                                                                                                                       |
| 413 |    178.052164 |     77.799725 | Gareth Monger                                                                                                                                                         |
| 414 |   1004.283616 |    121.717803 | Zimices                                                                                                                                                               |
| 415 |    886.403209 |    759.021644 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                           |
| 416 |     67.364958 |    534.600234 | Bruno C. Vellutini                                                                                                                                                    |
| 417 |    682.025749 |     14.360638 | Sarah Werning                                                                                                                                                         |
| 418 |     66.185320 |    314.991198 | James Neenan                                                                                                                                                          |
| 419 |    279.609739 |    604.270187 | T. Tischler                                                                                                                                                           |
| 420 |    363.949690 |    122.751750 | (unknown)                                                                                                                                                             |
| 421 |     49.428377 |    198.564391 | Matt Crook                                                                                                                                                            |
| 422 |    262.520382 |    486.323436 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 423 |    596.841951 |    703.663445 | Scott Hartman (vectorized by William Gearty)                                                                                                                          |
| 424 |    463.053794 |    677.871232 | Zimices                                                                                                                                                               |
| 425 |    968.622027 |    179.960550 | Gareth Monger                                                                                                                                                         |
| 426 |    399.320498 |    519.620314 | Matt Martyniuk                                                                                                                                                        |
| 427 |    550.658865 |    183.242044 | NA                                                                                                                                                                    |
| 428 |    217.742819 |      8.562264 | Matt Dempsey                                                                                                                                                          |
| 429 |    258.139846 |    445.211084 | Jagged Fang Designs                                                                                                                                                   |
| 430 |     90.637500 |     14.315126 | Michael P. Taylor                                                                                                                                                     |
| 431 |    720.230506 |    735.683961 | Martien Brand (original photo), Renato Santos (vector silhouette)                                                                                                     |
| 432 |    908.367348 |    678.764422 | Markus A. Grohme                                                                                                                                                      |
| 433 |    744.541309 |    436.216871 | Zimices                                                                                                                                                               |
| 434 |     53.115166 |     34.905323 | Jagged Fang Designs                                                                                                                                                   |
| 435 |    216.979933 |    131.043509 | Gareth Monger                                                                                                                                                         |
| 436 |    463.823716 |    526.979354 | Jagged Fang Designs                                                                                                                                                   |
| 437 |    607.399466 |    237.235688 | Steven Traver                                                                                                                                                         |
| 438 |    550.074649 |    441.159854 | Sarah Alewijnse                                                                                                                                                       |
| 439 |    585.152320 |    201.741599 | Ghedo (vectorized by T. Michael Keesey)                                                                                                                               |
| 440 |    247.342254 |    785.939241 | Steven Traver                                                                                                                                                         |
| 441 |    620.947509 |    724.632181 | Jagged Fang Designs                                                                                                                                                   |
| 442 |     87.554278 |    673.128784 | Tracy A. Heath                                                                                                                                                        |
| 443 |    642.912992 |    786.181368 | Zimices                                                                                                                                                               |
| 444 |    671.418690 |     85.843609 | Walter Vladimir                                                                                                                                                       |
| 445 |    704.818586 |     20.962887 | Theodore W. Pietsch (photography) and T. Michael Keesey (vectorization)                                                                                               |
| 446 |    442.882826 |    716.068939 | T. Michael Keesey                                                                                                                                                     |
| 447 |    257.329380 |    143.289311 | Rebecca Groom                                                                                                                                                         |
| 448 |     18.343667 |     15.112292 | Gareth Monger                                                                                                                                                         |
| 449 |    789.335071 |    729.107141 | Scott Hartman                                                                                                                                                         |
| 450 |    696.965615 |    342.328352 | NA                                                                                                                                                                    |
| 451 |      3.558650 |    669.684030 | NA                                                                                                                                                                    |
| 452 |    551.089645 |    304.539012 | Chris huh                                                                                                                                                             |
| 453 |    221.154932 |    228.800704 | Theodore W. Pietsch (photography) and T. Michael Keesey (vectorization)                                                                                               |
| 454 |    140.913974 |     62.249956 | T. Michael Keesey                                                                                                                                                     |
| 455 |    572.757263 |    766.172436 | NA                                                                                                                                                                    |
| 456 |    358.478200 |    572.631680 | Tasman Dixon                                                                                                                                                          |
| 457 |    398.572641 |    430.924497 | Kailah Thorn & Mark Hutchinson                                                                                                                                        |
| 458 |    442.367888 |    398.357166 | M Kolmann                                                                                                                                                             |
| 459 |    980.260918 |    702.329524 | Matt Celeskey                                                                                                                                                         |
| 460 |    905.398937 |    785.826257 | T. Michael Keesey (photo by Darren Swim)                                                                                                                              |
| 461 |    232.169227 |     54.166006 | Matthew Hooge (vectorized by T. Michael Keesey)                                                                                                                       |
| 462 |     56.375662 |    265.229557 | Carlos Cano-Barbacil                                                                                                                                                  |
| 463 |    207.746398 |    436.237752 | Dean Schnabel                                                                                                                                                         |
| 464 |    338.892943 |    472.237203 | Jaime Headden                                                                                                                                                         |
| 465 |    166.999686 |    104.473190 | Matt Crook                                                                                                                                                            |
| 466 |    720.766312 |    794.026127 | Caleb M. Brown                                                                                                                                                        |
| 467 |    572.194480 |     35.392066 | Tasman Dixon                                                                                                                                                          |
| 468 |    476.485688 |    320.947227 | Chris huh                                                                                                                                                             |
| 469 |   1008.841081 |    340.247582 | Robert Gay                                                                                                                                                            |
| 470 |    319.159789 |    566.247810 | Jagged Fang Designs                                                                                                                                                   |
| 471 |    414.197131 |    246.817256 | Gareth Monger                                                                                                                                                         |
| 472 |    620.940594 |    712.711300 | NA                                                                                                                                                                    |
| 473 |    844.272124 |    669.066612 | G. M. Woodward                                                                                                                                                        |
| 474 |    695.534937 |    304.856226 | Gopal Murali                                                                                                                                                          |
| 475 |    133.013555 |    137.851514 | NA                                                                                                                                                                    |
| 476 |    704.271276 |    513.373702 | Jack Mayer Wood                                                                                                                                                       |
| 477 |    332.258735 |    319.194598 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
| 478 |    881.523431 |    528.273576 | Sarah Werning                                                                                                                                                         |
| 479 |    672.895107 |     58.688073 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 480 |    837.027105 |    598.468472 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 481 |    682.202256 |    187.979484 | Margot Michaud                                                                                                                                                        |
| 482 |    610.128309 |     97.145804 | Mathew Wedel                                                                                                                                                          |
| 483 |    808.048537 |     76.673805 | Konsta Happonen, from a CC-BY-NC image by pelhonen on iNaturalist                                                                                                     |
| 484 |     82.437144 |    743.820653 | L. Shyamal                                                                                                                                                            |
| 485 |    386.691562 |    619.479691 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 486 |    591.220160 |    500.901314 | Beth Reinke                                                                                                                                                           |
| 487 |    928.212265 |    312.118269 | Jagged Fang Designs                                                                                                                                                   |
| 488 |    935.146864 |    360.050859 | Melissa Broussard                                                                                                                                                     |
| 489 |    255.906848 |    171.954798 | Jagged Fang Designs                                                                                                                                                   |
| 490 |     30.978106 |    324.625817 | Markus A. Grohme                                                                                                                                                      |
| 491 |    820.550887 |     42.567194 | Joanna Wolfe                                                                                                                                                          |
| 492 |    215.409330 |    789.738216 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 493 |    544.733247 |    485.313048 | Markus A. Grohme                                                                                                                                                      |
| 494 |    865.381512 |    302.725162 | Henry Lydecker                                                                                                                                                        |
| 495 |   1016.091872 |    391.039427 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 496 |    796.036424 |    314.099189 | Robert Gay                                                                                                                                                            |
| 497 |    770.700419 |    411.277429 | Matt Crook                                                                                                                                                            |
| 498 |    933.534080 |    779.134641 | Gareth Monger                                                                                                                                                         |
| 499 |    232.718404 |    547.496646 | Gareth Monger                                                                                                                                                         |
| 500 |    409.693738 |    795.022237 | Chris huh                                                                                                                                                             |
| 501 |    470.884888 |    601.867752 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                  |
| 502 |      7.867347 |    175.345063 | Gareth Monger                                                                                                                                                         |
| 503 |    163.547195 |    369.807732 | NA                                                                                                                                                                    |
| 504 |   1002.322696 |    298.779659 | Matt Crook                                                                                                                                                            |
| 505 |    781.853574 |    617.759755 | Scott Hartman                                                                                                                                                         |
| 506 |    322.571237 |    633.821140 | Sherman Foote Denton (illustration, 1897) and Timothy J. Bartley (silhouette)                                                                                         |
| 507 |    262.651257 |    401.883825 | T. Michael Keesey                                                                                                                                                     |
| 508 |    257.322743 |    361.447587 | Tasman Dixon                                                                                                                                                          |
| 509 |    931.790779 |    119.611893 | T. Michael Keesey                                                                                                                                                     |
| 510 |    872.231582 |    490.510992 | Gareth Monger                                                                                                                                                         |
| 511 |     18.710275 |    791.791921 | Scott Hartman                                                                                                                                                         |
| 512 |     16.551592 |    480.313326 | Margot Michaud                                                                                                                                                        |

    #> Your tweet has been posted!
