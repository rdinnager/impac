
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

Margot Michaud, Matt Crook, Frederick William Frohawk (vectorized by T.
Michael Keesey), Kai R. Caspar, Emily Willoughby, Michelle Site, Jaime
Headden, Markus A. Grohme, Mason McNair, Gareth Monger, Yan Wong from
illustration by Charles Orbigny, Ignacio Contreras, Chris huh, Yan Wong,
Ewald Rübsamen, Metalhead64 (vectorized by T. Michael Keesey), Pearson
Scott Foresman (vectorized by T. Michael Keesey), Matt Martyniuk, Burton
Robert, USFWS, Jagged Fang Designs, Tyler Greenfield, Josep Marti
Solans, Smokeybjb, Robert Bruce Horsfall, vectorized by Zimices, Mario
Quevedo, Scott Hartman, T. Michael Keesey (vectorization) and
HuttyMcphoo (photography), Dmitry Bogdanov (vectorized by T. Michael
Keesey), Alexander Schmidt-Lebuhn, Mali’o Kodis, photograph property of
National Museums of Northern Ireland, Bennet McComish, photo by Hans
Hillewaert, DW Bapst, modified from Ishitani et al. 2016, Steven Haddock
• Jellywatch.org, David Orr, Steven Traver, Felix Vaux, Zimices, C.
Camilo Julián-Caballero, Tambja (vectorized by T. Michael Keesey), Frank
Förster, CNZdenek, Thibaut Brunet, James I. Kirkland, Luis Alcalá, Mark
A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma
(vectorized by T. Michael Keesey), Francisco Gascó (modified by Michael
P. Taylor), Conty (vectorized by T. Michael Keesey), Milton Tan, Nobu
Tamura, Iain Reid, Tony Ayling (vectorized by T. Michael Keesey), Espen
Horn (model; vectorized by T. Michael Keesey from a photo by H. Zell),
Alan Manson (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, T. Michael Keesey, Agnello Picorelli, Juan Carlos Jerí,
Nobu Tamura (vectorized by T. Michael Keesey), Rebecca Groom, Cathy,
Ingo Braasch, Alexandre Vong, Gabriela Palomo-Munoz, Bryan Carstens,
Joanna Wolfe, Roberto Díaz Sibaja, Lukas Panzarin (vectorized by T.
Michael Keesey), L. Shyamal, Fir0002/Flagstaffotos (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Tasman Dixon,
SecretJellyMan, Mali’o Kodis, image from the Biodiversity Heritage
Library, Robbie N. Cada (vectorized by T. Michael Keesey), Stacy
Spensley (Modified), Matus Valach, Ferran Sayol, Emma Hughes, M Kolmann,
Zsoldos Márton (vectorized by T. Michael Keesey), Andy Wilson, Darius
Nau, Robbie N. Cada (modified by T. Michael Keesey), Noah Schlottman,
photo from Casey Dunn, Sarah Werning, Beth Reinke, Robert Gay, Andrew A.
Farke, John Gould (vectorized by T. Michael Keesey), Maxime Dahirel,
Henry Fairfield Osborn, vectorized by Zimices, Isaure Scavezzoni,
Mathieu Pélissié, Michael Scroggie, from original photograph by Gary M.
Stolz, USFWS (original photograph in public domain)., Ludwik
Gąsiorowski, Jose Carlos Arenas-Monroy, Mali’o Kodis, photograph by
John Slapcinsky, Obsidian Soul (vectorized by T. Michael Keesey),
Smokeybjb (vectorized by T. Michael Keesey), Henry Lydecker, Todd
Marshall, vectorized by Zimices, Matt Dempsey, Paul O. Lewis, Sarefo
(vectorized by T. Michael Keesey), Rachel Shoop, Tyler Greenfield and
Scott Hartman, Dean Schnabel, Tracy A. Heath, Christoph Schomburg,
Shyamal, Eduard Solà (vectorized by T. Michael Keesey), Eyal Bartov,
Crystal Maier, Joe Schneid (vectorized by T. Michael Keesey), Geoff
Shaw, Zachary Quigley, Jimmy Bernot, S.Martini, Kamil S. Jaron, Birgit
Lang, Nobu Tamura, vectorized by Zimices, Philippe Janvier (vectorized
by T. Michael Keesey), Karla Martinez, Manabu Sakamoto, Don Armstrong,
Maija Karala, Martin R. Smith, Anthony Caravaggi, Lukasiniho, Zimices /
Julián Bayona, Noah Schlottman, photo from National Science Foundation -
Turbellarian Taxonomic Database, Robert Gay, modified from FunkMonk
(Michael B.H.) and T. Michael Keesey., Erika Schumacher, Neil Kelley,
Rene Martin, Melissa Broussard, Steven Coombs (vectorized by T. Michael
Keesey), Jiekun He, Hans Hillewaert (photo) and T. Michael Keesey
(vectorization), Lankester Edwin Ray (vectorized by T. Michael Keesey),
Alex Slavenko, Sebastian Stabinger, Yan Wong from wikipedia drawing (PD:
Pearson Scott Foresman), Saguaro Pictures (source photo) and T. Michael
Keesey, Mali’o Kodis, photograph by Hans Hillewaert, Renata F. Martins,
Matt Celeskey, Armin Reindl, SauropodomorphMonarch, Original drawing by
Nobu Tamura, vectorized by Roberto Díaz Sibaja, Carlos Cano-Barbacil,
Michele M Tobias, Jordan Mallon (vectorized by T. Michael Keesey),
Amanda Katzer, Christine Axon, Kimberly Haddrell, Kailah Thorn & Mark
Hutchinson, Timothy Knepp of the U.S. Fish and Wildlife Service
(illustration) and Timothy J. Bartley (silhouette), Original drawing by
Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja, Harold N Eyster, Lee
Harding (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Craig Dylke, Steven Coombs, Giant Blue Anteater
(vectorized by T. Michael Keesey), Francis de Laporte de Castelnau
(vectorized by T. Michael Keesey), Mali’o Kodis, photograph by P. Funch
and R.M. Kristensen, Pete Buchholz, Sergio A. Muñoz-Gómez, Fernando
Campos De Domenico, Jack Mayer Wood, Jan A. Venter, Herbert H. T. Prins,
David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey), Lisa
Byrne, Scott Reid, Hugo Gruson, Dantheman9758 (vectorized by T. Michael
Keesey), Felix Vaux and Steven A. Trewick, Sibi (vectorized by T.
Michael Keesey), , Dmitry Bogdanov, Marie-Aimée Allard, T. Michael
Keesey (vectorization) and Larry Loos (photography), Matthew E. Clapham,
Dexter R. Mardis, Ghedo (vectorized by T. Michael Keesey), Maxwell
Lefroy (vectorized by T. Michael Keesey), T. K. Robinson, ДиБгд
(vectorized by T. Michael Keesey), Moussa Direct Ltd. (photography) and
T. Michael Keesey (vectorization)

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |     84.962599 |    122.371860 | Margot Michaud                                                                                                                                                        |
|   2 |    706.301757 |    444.726178 | Matt Crook                                                                                                                                                            |
|   3 |    273.505686 |    683.165142 | Frederick William Frohawk (vectorized by T. Michael Keesey)                                                                                                           |
|   4 |    431.035683 |    483.504873 | Kai R. Caspar                                                                                                                                                         |
|   5 |    115.888606 |    542.900857 | Emily Willoughby                                                                                                                                                      |
|   6 |    158.584913 |     37.855416 | Michelle Site                                                                                                                                                         |
|   7 |    907.486442 |    352.895302 | Jaime Headden                                                                                                                                                         |
|   8 |    491.705451 |    340.088190 | Markus A. Grohme                                                                                                                                                      |
|   9 |    761.194743 |    669.317069 | Markus A. Grohme                                                                                                                                                      |
|  10 |    575.769477 |    209.034453 | Mason McNair                                                                                                                                                          |
|  11 |    382.288557 |    296.731816 | Gareth Monger                                                                                                                                                         |
|  12 |    469.972991 |     65.119879 | Yan Wong from illustration by Charles Orbigny                                                                                                                         |
|  13 |    179.331326 |    451.085541 | Ignacio Contreras                                                                                                                                                     |
|  14 |    528.155895 |    695.361237 | Chris huh                                                                                                                                                             |
|  15 |    270.044536 |    282.196792 | Yan Wong                                                                                                                                                              |
|  16 |    749.278305 |    203.551081 | Ewald Rübsamen                                                                                                                                                        |
|  17 |    929.567970 |    555.335802 | Metalhead64 (vectorized by T. Michael Keesey)                                                                                                                         |
|  18 |    193.747314 |    320.842625 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                              |
|  19 |    592.929952 |    756.138314 | Matt Martyniuk                                                                                                                                                        |
|  20 |    292.124705 |    182.742959 | Burton Robert, USFWS                                                                                                                                                  |
|  21 |    176.096992 |    774.171618 | Jagged Fang Designs                                                                                                                                                   |
|  22 |     35.581921 |    204.835804 | Tyler Greenfield                                                                                                                                                      |
|  23 |     69.249062 |    316.197559 | Josep Marti Solans                                                                                                                                                    |
|  24 |    661.644770 |    609.481127 | Smokeybjb                                                                                                                                                             |
|  25 |    385.889812 |    580.030773 | Michelle Site                                                                                                                                                         |
|  26 |    540.526434 |    437.898160 | NA                                                                                                                                                                    |
|  27 |    845.624670 |     45.632020 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                          |
|  28 |    389.642575 |    217.769900 | Gareth Monger                                                                                                                                                         |
|  29 |    842.530238 |    262.026382 | Chris huh                                                                                                                                                             |
|  30 |    286.726781 |    469.245161 | Mario Quevedo                                                                                                                                                         |
|  31 |    531.553438 |    732.154709 | Scott Hartman                                                                                                                                                         |
|  32 |    367.652400 |    117.306267 | NA                                                                                                                                                                    |
|  33 |    854.919818 |    154.774649 | Ewald Rübsamen                                                                                                                                                        |
|  34 |    602.854716 |     72.880246 | T. Michael Keesey (vectorization) and HuttyMcphoo (photography)                                                                                                       |
|  35 |    883.980998 |    713.510697 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  36 |    735.662080 |    104.213896 | Alexander Schmidt-Lebuhn                                                                                                                                              |
|  37 |    979.433105 |    219.291669 | Mali’o Kodis, photograph property of National Museums of Northern Ireland                                                                                             |
|  38 |    326.666340 |    377.743333 | Bennet McComish, photo by Hans Hillewaert                                                                                                                             |
|  39 |    169.575315 |    219.749806 | Yan Wong                                                                                                                                                              |
|  40 |     67.185728 |    637.593231 | DW Bapst, modified from Ishitani et al. 2016                                                                                                                          |
|  41 |    393.095175 |    752.575438 | Matt Crook                                                                                                                                                            |
|  42 |    759.994453 |    327.567236 | Steven Haddock • Jellywatch.org                                                                                                                                       |
|  43 |    252.242873 |     65.254975 | Markus A. Grohme                                                                                                                                                      |
|  44 |    482.205801 |    165.292779 | Gareth Monger                                                                                                                                                         |
|  45 |    782.244885 |    729.001295 | David Orr                                                                                                                                                             |
|  46 |    910.561631 |    654.057486 | Steven Traver                                                                                                                                                         |
|  47 |    593.499296 |    297.907783 | Margot Michaud                                                                                                                                                        |
|  48 |    940.352111 |    125.059337 | Felix Vaux                                                                                                                                                            |
|  49 |    512.112137 |    219.105594 | NA                                                                                                                                                                    |
|  50 |    136.642633 |    729.886764 | Margot Michaud                                                                                                                                                        |
|  51 |    948.729293 |    469.789023 | Zimices                                                                                                                                                               |
|  52 |    239.402389 |    637.094407 | Zimices                                                                                                                                                               |
|  53 |     60.645856 |    460.535831 | C. Camilo Julián-Caballero                                                                                                                                            |
|  54 |    732.944566 |    258.424097 | Tambja (vectorized by T. Michael Keesey)                                                                                                                              |
|  55 |    659.226175 |    155.421144 | Felix Vaux                                                                                                                                                            |
|  56 |    655.264517 |    724.752973 | Frank Förster                                                                                                                                                         |
|  57 |    224.524164 |    713.007970 | Scott Hartman                                                                                                                                                         |
|  58 |    111.752691 |    400.867876 | CNZdenek                                                                                                                                                              |
|  59 |    954.705778 |    435.492084 | Chris huh                                                                                                                                                             |
|  60 |    381.017756 |    409.143779 | Zimices                                                                                                                                                               |
|  61 |    688.171274 |     29.976313 | Zimices                                                                                                                                                               |
|  62 |    698.212622 |    587.039104 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  63 |    382.511140 |    692.107159 | Steven Traver                                                                                                                                                         |
|  64 |    348.785500 |     32.951495 | Thibaut Brunet                                                                                                                                                        |
|  65 |    621.085177 |    237.447471 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                  |
|  66 |    456.707279 |    560.479964 | Francisco Gascó (modified by Michael P. Taylor)                                                                                                                       |
|  67 |    508.338451 |    115.964863 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
|  68 |    955.124175 |    740.320097 | Milton Tan                                                                                                                                                            |
|  69 |    664.885573 |    775.717408 | Nobu Tamura                                                                                                                                                           |
|  70 |    868.066925 |    219.848922 | Steven Traver                                                                                                                                                         |
|  71 |    886.213928 |    771.464977 | Iain Reid                                                                                                                                                             |
|  72 |    227.217266 |     96.430598 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
|  73 |    496.195265 |    257.755024 | Espen Horn (model; vectorized by T. Michael Keesey from a photo by H. Zell)                                                                                           |
|  74 |    639.864959 |    403.676223 | Scott Hartman                                                                                                                                                         |
|  75 |    173.380500 |    601.780162 | Jagged Fang Designs                                                                                                                                                   |
|  76 |    836.760639 |    374.407580 | Alan Manson (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
|  77 |    953.820457 |    623.565747 | T. Michael Keesey                                                                                                                                                     |
|  78 |    904.480124 |     85.947787 | Agnello Picorelli                                                                                                                                                     |
|  79 |    426.841473 |    210.448814 | Juan Carlos Jerí                                                                                                                                                      |
|  80 |    215.389030 |    559.435797 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  81 |    585.972142 |    656.362267 | NA                                                                                                                                                                    |
|  82 |    270.165343 |    622.206312 | Smokeybjb                                                                                                                                                             |
|  83 |     93.539385 |    224.276567 | Rebecca Groom                                                                                                                                                         |
|  84 |    248.060327 |    520.779109 | Yan Wong                                                                                                                                                              |
|  85 |    620.626800 |    463.878282 | Michelle Site                                                                                                                                                         |
|  86 |    220.601100 |    137.112155 | Cathy                                                                                                                                                                 |
|  87 |    956.510596 |     15.525114 | Scott Hartman                                                                                                                                                         |
|  88 |    979.620568 |    301.070684 | Gareth Monger                                                                                                                                                         |
|  89 |    981.363147 |    123.688975 | T. Michael Keesey                                                                                                                                                     |
|  90 |    547.370578 |    125.327470 | NA                                                                                                                                                                    |
|  91 |    276.274574 |    782.401982 | Ingo Braasch                                                                                                                                                          |
|  92 |    819.725525 |    589.059742 | Alexandre Vong                                                                                                                                                        |
|  93 |    678.102260 |    638.230097 | Chris huh                                                                                                                                                             |
|  94 |    336.805003 |    237.650336 | Scott Hartman                                                                                                                                                         |
|  95 |    488.603833 |    761.577308 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  96 |    164.921817 |     87.654249 | Bryan Carstens                                                                                                                                                        |
|  97 |    598.971880 |     14.897201 | Joanna Wolfe                                                                                                                                                          |
|  98 |    193.006166 |    428.503221 | Roberto Díaz Sibaja                                                                                                                                                   |
|  99 |    345.838488 |     58.112502 | Lukas Panzarin (vectorized by T. Michael Keesey)                                                                                                                      |
| 100 |    502.078695 |    447.560838 | Zimices                                                                                                                                                               |
| 101 |    987.084895 |    770.816096 | Matt Crook                                                                                                                                                            |
| 102 |     24.573850 |     48.839204 | L. Shyamal                                                                                                                                                            |
| 103 |     44.158164 |    718.596373 | Fir0002/Flagstaffotos (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
| 104 |    313.043486 |    287.522349 | Gareth Monger                                                                                                                                                         |
| 105 |    996.680813 |    352.416474 | T. Michael Keesey                                                                                                                                                     |
| 106 |    626.897237 |    783.663162 | Scott Hartman                                                                                                                                                         |
| 107 |    176.151883 |    515.599276 | Tasman Dixon                                                                                                                                                          |
| 108 |    319.393622 |    343.234905 | Smokeybjb                                                                                                                                                             |
| 109 |    503.246886 |    536.780671 | Tasman Dixon                                                                                                                                                          |
| 110 |    183.500848 |    160.907194 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 111 |    211.649043 |    467.153855 | Gareth Monger                                                                                                                                                         |
| 112 |    802.285253 |    785.324252 | Matt Crook                                                                                                                                                            |
| 113 |    792.692848 |    320.255488 | SecretJellyMan                                                                                                                                                        |
| 114 |    709.647030 |    141.288159 | Mali’o Kodis, image from the Biodiversity Heritage Library                                                                                                            |
| 115 |    148.771373 |    263.626737 | Matt Crook                                                                                                                                                            |
| 116 |    244.212489 |    380.226381 | NA                                                                                                                                                                    |
| 117 |    996.470478 |    663.540949 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
| 118 |    242.162704 |    266.638447 | NA                                                                                                                                                                    |
| 119 |    930.601566 |    285.435251 | Matt Crook                                                                                                                                                            |
| 120 |    979.919954 |    391.781985 | Margot Michaud                                                                                                                                                        |
| 121 |     80.668704 |    256.603859 | Gareth Monger                                                                                                                                                         |
| 122 |    784.928644 |    644.733800 | Matt Crook                                                                                                                                                            |
| 123 |    131.025104 |    665.936183 | Matt Crook                                                                                                                                                            |
| 124 |    476.912248 |     15.974740 | Stacy Spensley (Modified)                                                                                                                                             |
| 125 |    300.277807 |    596.458199 | Matus Valach                                                                                                                                                          |
| 126 |    110.534213 |    176.509440 | Margot Michaud                                                                                                                                                        |
| 127 |    743.351303 |    782.857669 | Matt Crook                                                                                                                                                            |
| 128 |     23.483389 |    542.170719 | Margot Michaud                                                                                                                                                        |
| 129 |    811.401540 |    379.292171 | Felix Vaux                                                                                                                                                            |
| 130 |    769.104889 |     71.286972 | Steven Traver                                                                                                                                                         |
| 131 |    186.709274 |    531.423617 | Ferran Sayol                                                                                                                                                          |
| 132 |    849.312557 |    294.356169 | Zimices                                                                                                                                                               |
| 133 |    134.754591 |    695.790890 | Emma Hughes                                                                                                                                                           |
| 134 |    190.976194 |    646.989736 | Scott Hartman                                                                                                                                                         |
| 135 |    449.634907 |    382.014329 | Scott Hartman                                                                                                                                                         |
| 136 |    113.440539 |    338.451943 | Gareth Monger                                                                                                                                                         |
| 137 |    663.198018 |    455.744569 | M Kolmann                                                                                                                                                             |
| 138 |     19.649930 |    584.410375 | Zsoldos Márton (vectorized by T. Michael Keesey)                                                                                                                      |
| 139 |    149.748880 |    496.291520 | Jagged Fang Designs                                                                                                                                                   |
| 140 |    108.504504 |    693.212100 | Andy Wilson                                                                                                                                                           |
| 141 |    739.355290 |    238.314043 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 142 |    319.854265 |    404.837219 | Jagged Fang Designs                                                                                                                                                   |
| 143 |    177.328545 |    180.038068 | Darius Nau                                                                                                                                                            |
| 144 |    910.267985 |     41.680535 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                                        |
| 145 |   1010.111607 |    639.793528 | Noah Schlottman, photo from Casey Dunn                                                                                                                                |
| 146 |    509.285274 |    308.313737 | Margot Michaud                                                                                                                                                        |
| 147 |    499.726051 |    583.819979 | NA                                                                                                                                                                    |
| 148 |     22.778154 |    129.800103 | Steven Traver                                                                                                                                                         |
| 149 |    412.654066 |    518.707237 | Sarah Werning                                                                                                                                                         |
| 150 |    279.900962 |     27.637151 | Beth Reinke                                                                                                                                                           |
| 151 |    388.157413 |    665.531084 | Robert Gay                                                                                                                                                            |
| 152 |    174.875417 |    489.370137 | Andrew A. Farke                                                                                                                                                       |
| 153 |     20.456804 |    753.277982 | John Gould (vectorized by T. Michael Keesey)                                                                                                                          |
| 154 |    360.408643 |    486.936765 | Scott Hartman                                                                                                                                                         |
| 155 |    588.850047 |    782.536224 | Chris huh                                                                                                                                                             |
| 156 |    830.539314 |    651.052569 | Matt Crook                                                                                                                                                            |
| 157 |    667.827805 |     80.422293 | Maxime Dahirel                                                                                                                                                        |
| 158 |      9.047584 |    500.165126 | Felix Vaux                                                                                                                                                            |
| 159 |    333.596921 |    623.992394 | Jagged Fang Designs                                                                                                                                                   |
| 160 |    692.778507 |    289.110707 | Margot Michaud                                                                                                                                                        |
| 161 |    235.001225 |    173.763175 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                                         |
| 162 |    628.676159 |    689.503850 | NA                                                                                                                                                                    |
| 163 |    862.035414 |    528.585756 | Jagged Fang Designs                                                                                                                                                   |
| 164 |    966.381009 |    695.537967 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 165 |    205.119370 |    517.521603 | Isaure Scavezzoni                                                                                                                                                     |
| 166 |    367.105936 |    339.271650 | Matt Crook                                                                                                                                                            |
| 167 |    992.533169 |     37.984051 | Zimices                                                                                                                                                               |
| 168 |     87.400537 |    188.024444 | Zimices                                                                                                                                                               |
| 169 |    788.638989 |    765.975317 | Steven Traver                                                                                                                                                         |
| 170 |    993.517852 |    584.755982 | Margot Michaud                                                                                                                                                        |
| 171 |    365.543649 |    635.484942 | Jagged Fang Designs                                                                                                                                                   |
| 172 |    136.233469 |    634.555790 | Noah Schlottman, photo from Casey Dunn                                                                                                                                |
| 173 |    613.273697 |    361.983521 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 174 |    851.946319 |    608.701864 | Mathieu Pélissié                                                                                                                                                      |
| 175 |     25.158904 |    418.931993 | Michael Scroggie, from original photograph by Gary M. Stolz, USFWS (original photograph in public domain).                                                            |
| 176 |    451.553343 |    176.575982 | Andrew A. Farke                                                                                                                                                       |
| 177 |    450.539341 |    697.045952 | Francisco Gascó (modified by Michael P. Taylor)                                                                                                                       |
| 178 |    168.437776 |    272.598141 | Mathieu Pélissié                                                                                                                                                      |
| 179 |    245.467112 |    592.880733 | L. Shyamal                                                                                                                                                            |
| 180 |    762.720195 |    144.942296 | Ludwik Gąsiorowski                                                                                                                                                    |
| 181 |    356.242410 |    663.054792 | Roberto Díaz Sibaja                                                                                                                                                   |
| 182 |    986.510269 |    320.192049 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 183 |    339.372120 |    429.573072 | Zimices                                                                                                                                                               |
| 184 |    430.582303 |    133.368887 | NA                                                                                                                                                                    |
| 185 |    822.646226 |    100.756169 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 186 |    503.563294 |    652.157157 | Mali’o Kodis, photograph by John Slapcinsky                                                                                                                           |
| 187 |     84.775327 |    745.907271 | Roberto Díaz Sibaja                                                                                                                                                   |
| 188 |    367.611408 |    204.560944 | Margot Michaud                                                                                                                                                        |
| 189 |    570.001029 |    586.263333 | Steven Traver                                                                                                                                                         |
| 190 |    297.715691 |     17.467379 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 191 |    981.997103 |    283.117358 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 192 |    334.528198 |    445.220762 | Markus A. Grohme                                                                                                                                                      |
| 193 |    843.662026 |    558.465235 | Zimices                                                                                                                                                               |
| 194 |    101.838410 |     11.114841 | Zimices                                                                                                                                                               |
| 195 |    144.667997 |    297.436714 | Zimices                                                                                                                                                               |
| 196 |    486.400435 |    501.697144 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 197 |   1003.652890 |    291.452229 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                           |
| 198 |     97.902774 |    784.444424 | Henry Lydecker                                                                                                                                                        |
| 199 |    951.189021 |    781.062459 | Todd Marshall, vectorized by Zimices                                                                                                                                  |
| 200 |     66.653899 |    695.262706 | Matt Dempsey                                                                                                                                                          |
| 201 |     85.379459 |    501.010693 | Chris huh                                                                                                                                                             |
| 202 |    654.187599 |    668.838108 | Paul O. Lewis                                                                                                                                                         |
| 203 |    995.802528 |    507.070053 | Sarefo (vectorized by T. Michael Keesey)                                                                                                                              |
| 204 |    681.630951 |    234.449734 | Gareth Monger                                                                                                                                                         |
| 205 |     20.228273 |    386.083239 | Rachel Shoop                                                                                                                                                          |
| 206 |    370.148887 |     22.358957 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 207 |    115.403535 |    244.206892 | Scott Hartman                                                                                                                                                         |
| 208 |     55.634556 |    427.203798 | Scott Hartman                                                                                                                                                         |
| 209 |    632.001400 |    347.843320 | NA                                                                                                                                                                    |
| 210 |    861.040057 |    371.012420 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 211 |     58.683203 |    781.217112 | Scott Hartman                                                                                                                                                         |
| 212 |    769.304276 |     42.767399 | Tyler Greenfield and Scott Hartman                                                                                                                                    |
| 213 |    490.127112 |    625.316775 | Dean Schnabel                                                                                                                                                         |
| 214 |    756.067100 |    583.343639 | Ferran Sayol                                                                                                                                                          |
| 215 |    317.444586 |    760.892049 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 216 |    257.149329 |    565.139343 | Margot Michaud                                                                                                                                                        |
| 217 |    515.146065 |      6.464599 | T. Michael Keesey                                                                                                                                                     |
| 218 |    122.421097 |    367.437372 | Tracy A. Heath                                                                                                                                                        |
| 219 |    135.952275 |    751.691816 | Christoph Schomburg                                                                                                                                                   |
| 220 |    705.318871 |    100.437762 | Shyamal                                                                                                                                                               |
| 221 |    228.108902 |    409.416717 | Eduard Solà (vectorized by T. Michael Keesey)                                                                                                                         |
| 222 |     74.870047 |     63.950502 | Margot Michaud                                                                                                                                                        |
| 223 |    753.539386 |    406.548439 | Eyal Bartov                                                                                                                                                           |
| 224 |    281.422937 |    127.009846 | Crystal Maier                                                                                                                                                         |
| 225 |    330.735940 |    721.805134 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 226 |    415.370689 |    273.568079 | Joe Schneid (vectorized by T. Michael Keesey)                                                                                                                         |
| 227 |    855.830423 |    273.741711 | Chris huh                                                                                                                                                             |
| 228 |    140.983090 |     11.978498 | Geoff Shaw                                                                                                                                                            |
| 229 |    243.465796 |     48.135298 | Zachary Quigley                                                                                                                                                       |
| 230 |    193.009557 |    779.622524 | Scott Hartman                                                                                                                                                         |
| 231 |    830.719351 |    542.991009 | Zimices                                                                                                                                                               |
| 232 |    524.461768 |    369.397122 | Scott Hartman                                                                                                                                                         |
| 233 |   1016.843728 |    698.009003 | Jimmy Bernot                                                                                                                                                          |
| 234 |    697.485289 |    310.827533 | Tasman Dixon                                                                                                                                                          |
| 235 |    917.180354 |    206.263749 | Jimmy Bernot                                                                                                                                                          |
| 236 |    733.787149 |    534.499271 | Felix Vaux                                                                                                                                                            |
| 237 |    293.969752 |    246.831407 | Tasman Dixon                                                                                                                                                          |
| 238 |    513.499726 |     19.401668 | S.Martini                                                                                                                                                             |
| 239 |    880.304999 |    417.138127 | Shyamal                                                                                                                                                               |
| 240 |    140.238155 |    353.427572 | Kamil S. Jaron                                                                                                                                                        |
| 241 |    584.047267 |    364.262174 | NA                                                                                                                                                                    |
| 242 |   1006.697213 |    552.622205 | Gareth Monger                                                                                                                                                         |
| 243 |    801.919705 |    291.368820 | Birgit Lang                                                                                                                                                           |
| 244 |   1009.060897 |    412.881748 | T. Michael Keesey                                                                                                                                                     |
| 245 |    870.789755 |    613.178530 | Ferran Sayol                                                                                                                                                          |
| 246 |    263.522131 |    748.049954 | Steven Traver                                                                                                                                                         |
| 247 |    540.440460 |    649.375270 | Jagged Fang Designs                                                                                                                                                   |
| 248 |    898.299667 |    773.517993 | Markus A. Grohme                                                                                                                                                      |
| 249 |    102.668831 |    141.652392 | Joanna Wolfe                                                                                                                                                          |
| 250 |     51.505157 |    334.315626 | Jaime Headden                                                                                                                                                         |
| 251 |    964.062451 |    393.601851 | NA                                                                                                                                                                    |
| 252 |    443.054836 |    411.319513 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 253 |    358.961262 |    172.016215 | NA                                                                                                                                                                    |
| 254 |    451.580272 |    108.591291 | Tasman Dixon                                                                                                                                                          |
| 255 |    792.230326 |    515.797877 | Emily Willoughby                                                                                                                                                      |
| 256 |    873.734358 |     76.646442 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 257 |     40.608628 |     13.379013 | Shyamal                                                                                                                                                               |
| 258 |    419.978303 |    414.127867 | Jagged Fang Designs                                                                                                                                                   |
| 259 |    245.229573 |    191.932291 | Kamil S. Jaron                                                                                                                                                        |
| 260 |    527.546588 |    787.226928 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 261 |    376.326157 |      9.230489 | Chris huh                                                                                                                                                             |
| 262 |    572.852486 |    424.169211 | Philippe Janvier (vectorized by T. Michael Keesey)                                                                                                                    |
| 263 |    311.805240 |    518.393907 | Karla Martinez                                                                                                                                                        |
| 264 |    848.887265 |    576.073004 | Christoph Schomburg                                                                                                                                                   |
| 265 |    765.119541 |    280.079531 | Margot Michaud                                                                                                                                                        |
| 266 |    798.975385 |    689.158788 | Smokeybjb                                                                                                                                                             |
| 267 |    480.247611 |    519.186732 | Matt Crook                                                                                                                                                            |
| 268 |    836.917565 |    313.746037 | Chris huh                                                                                                                                                             |
| 269 |    990.090566 |     52.374719 | CNZdenek                                                                                                                                                              |
| 270 |    898.510255 |    670.841253 | T. Michael Keesey                                                                                                                                                     |
| 271 |     33.454639 |    779.630625 | T. Michael Keesey                                                                                                                                                     |
| 272 |    818.148238 |    327.482068 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 273 |    334.098956 |     17.498483 | T. Michael Keesey                                                                                                                                                     |
| 274 |    297.998784 |    730.233761 | Manabu Sakamoto                                                                                                                                                       |
| 275 |    788.604961 |    443.021574 | Gareth Monger                                                                                                                                                         |
| 276 |    428.208188 |    734.615569 | Don Armstrong                                                                                                                                                         |
| 277 |     98.028120 |    767.193010 | Ignacio Contreras                                                                                                                                                     |
| 278 |    766.617277 |    636.979513 | Scott Hartman                                                                                                                                                         |
| 279 |     78.147319 |    174.203300 | Maija Karala                                                                                                                                                          |
| 280 |    710.441816 |    692.152666 | NA                                                                                                                                                                    |
| 281 |    836.136187 |    511.409279 | Martin R. Smith                                                                                                                                                       |
| 282 |    714.802878 |     70.096345 | Chris huh                                                                                                                                                             |
| 283 |    197.026466 |    390.036683 | Zimices                                                                                                                                                               |
| 284 |    383.247086 |     72.850972 | T. Michael Keesey                                                                                                                                                     |
| 285 |    996.572310 |    788.455338 | Scott Hartman                                                                                                                                                         |
| 286 |    637.998797 |    100.278547 | Philippe Janvier (vectorized by T. Michael Keesey)                                                                                                                    |
| 287 |    776.437823 |     10.608615 | Zimices                                                                                                                                                               |
| 288 |    101.808369 |    496.176919 | Jagged Fang Designs                                                                                                                                                   |
| 289 |    633.280398 |    623.509535 | Anthony Caravaggi                                                                                                                                                     |
| 290 |    700.914539 |    789.756271 | NA                                                                                                                                                                    |
| 291 |    127.903508 |    470.305174 | Lukasiniho                                                                                                                                                            |
| 292 |    645.436558 |    526.569016 | Zimices / Julián Bayona                                                                                                                                               |
| 293 |    484.011427 |    413.619139 | Chris huh                                                                                                                                                             |
| 294 |    278.477816 |    537.858112 | Noah Schlottman, photo from National Science Foundation - Turbellarian Taxonomic Database                                                                             |
| 295 |    222.893928 |    489.453542 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                              |
| 296 |    455.903986 |    682.968735 | Erika Schumacher                                                                                                                                                      |
| 297 |    257.959363 |    405.675118 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 298 |    671.771048 |    441.152582 | Neil Kelley                                                                                                                                                           |
| 299 |    877.816458 |    105.873316 | Rene Martin                                                                                                                                                           |
| 300 |    728.462469 |    111.717539 | Matt Crook                                                                                                                                                            |
| 301 |    520.355268 |    493.482299 | Melissa Broussard                                                                                                                                                     |
| 302 |    175.082609 |    665.354278 | Margot Michaud                                                                                                                                                        |
| 303 |    477.716989 |    674.639462 | Steven Coombs (vectorized by T. Michael Keesey)                                                                                                                       |
| 304 |    503.696009 |    196.459664 | Scott Hartman                                                                                                                                                         |
| 305 |    567.889859 |    671.969753 | Cathy                                                                                                                                                                 |
| 306 |    638.185873 |    378.608240 | Tasman Dixon                                                                                                                                                          |
| 307 |    103.291679 |    156.885725 | Scott Hartman                                                                                                                                                         |
| 308 |    601.652018 |    338.173666 | Birgit Lang                                                                                                                                                           |
| 309 |    842.048185 |    779.663973 | Jagged Fang Designs                                                                                                                                                   |
| 310 |    737.614479 |    390.701632 | Jiekun He                                                                                                                                                             |
| 311 |    573.772225 |    382.178771 | Kamil S. Jaron                                                                                                                                                        |
| 312 |    216.175806 |    693.018949 | David Orr                                                                                                                                                             |
| 313 |   1012.532237 |    323.796389 | Noah Schlottman, photo from National Science Foundation - Turbellarian Taxonomic Database                                                                             |
| 314 |    512.673565 |    420.132610 | Zimices                                                                                                                                                               |
| 315 |    937.016892 |     67.208438 | Margot Michaud                                                                                                                                                        |
| 316 |     53.145782 |    562.059224 | Steven Traver                                                                                                                                                         |
| 317 |    913.274738 |    272.880993 | Melissa Broussard                                                                                                                                                     |
| 318 |    611.976870 |    139.593212 | Hans Hillewaert (photo) and T. Michael Keesey (vectorization)                                                                                                         |
| 319 |    602.721330 |    675.437633 | Margot Michaud                                                                                                                                                        |
| 320 |    637.735917 |    280.369107 | Jimmy Bernot                                                                                                                                                          |
| 321 |    405.970946 |     88.747007 | T. Michael Keesey                                                                                                                                                     |
| 322 |   1015.211534 |    585.622737 | T. Michael Keesey                                                                                                                                                     |
| 323 |    857.146919 |    655.922094 | Juan Carlos Jerí                                                                                                                                                      |
| 324 |    225.184436 |    613.714677 | Jagged Fang Designs                                                                                                                                                   |
| 325 |    487.096111 |    375.766543 | Zimices                                                                                                                                                               |
| 326 |    864.148598 |      9.706987 | C. Camilo Julián-Caballero                                                                                                                                            |
| 327 |     65.352296 |      8.034630 | Scott Hartman                                                                                                                                                         |
| 328 |    363.686413 |    187.385673 | NA                                                                                                                                                                    |
| 329 |    914.978871 |    241.698511 | Zimices                                                                                                                                                               |
| 330 |    455.217923 |    296.594709 | NA                                                                                                                                                                    |
| 331 |    965.152088 |    492.528223 | Zimices                                                                                                                                                               |
| 332 |    198.561578 |    494.654745 | Markus A. Grohme                                                                                                                                                      |
| 333 |    607.284381 |    559.861548 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                                 |
| 334 |    730.519514 |    743.664953 | Zimices                                                                                                                                                               |
| 335 |    933.568564 |    253.157074 | Alex Slavenko                                                                                                                                                         |
| 336 |    354.032942 |    474.764998 | Tasman Dixon                                                                                                                                                          |
| 337 |    697.555879 |    118.604032 | L. Shyamal                                                                                                                                                            |
| 338 |    174.744942 |    113.829326 | Maija Karala                                                                                                                                                          |
| 339 |    651.490541 |    298.295886 | T. Michael Keesey                                                                                                                                                     |
| 340 |    424.636188 |    168.201083 | Matt Crook                                                                                                                                                            |
| 341 |    997.050384 |     84.929350 | Zimices                                                                                                                                                               |
| 342 |    139.229161 |    307.525648 | Sebastian Stabinger                                                                                                                                                   |
| 343 |    465.551876 |     69.429037 | Scott Hartman                                                                                                                                                         |
| 344 |    899.305299 |    609.715437 | Yan Wong from wikipedia drawing (PD: Pearson Scott Foresman)                                                                                                          |
| 345 |    729.237981 |    165.231984 | Scott Hartman                                                                                                                                                         |
| 346 |    853.283235 |     88.783311 | Markus A. Grohme                                                                                                                                                      |
| 347 |    271.241240 |    356.545562 | Chris huh                                                                                                                                                             |
| 348 |    255.807951 |    342.012782 | Saguaro Pictures (source photo) and T. Michael Keesey                                                                                                                 |
| 349 |    957.648210 |    146.543907 | Jagged Fang Designs                                                                                                                                                   |
| 350 |    751.976422 |    368.457365 | Mali’o Kodis, photograph by Hans Hillewaert                                                                                                                           |
| 351 |     68.319510 |    772.663341 | Renata F. Martins                                                                                                                                                     |
| 352 |    306.344546 |    362.614044 | Matt Celeskey                                                                                                                                                         |
| 353 |    665.582988 |     61.548487 | Gareth Monger                                                                                                                                                         |
| 354 |    560.700492 |    598.690735 | Emily Willoughby                                                                                                                                                      |
| 355 |    111.763040 |    776.356904 | Armin Reindl                                                                                                                                                          |
| 356 |    602.620921 |    626.984877 | SauropodomorphMonarch                                                                                                                                                 |
| 357 |    660.272426 |    363.287434 | Margot Michaud                                                                                                                                                        |
| 358 |    271.916610 |    610.703257 | Original drawing by Nobu Tamura, vectorized by Roberto Díaz Sibaja                                                                                                    |
| 359 |    959.454572 |    315.833925 | Carlos Cano-Barbacil                                                                                                                                                  |
| 360 |    485.850368 |    606.488332 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 361 |    375.234738 |    439.064511 | NA                                                                                                                                                                    |
| 362 |    301.881240 |    409.395666 | Michele M Tobias                                                                                                                                                      |
| 363 |     61.745811 |    759.229986 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 364 |    541.873482 |     29.277118 | Jordan Mallon (vectorized by T. Michael Keesey)                                                                                                                       |
| 365 |    397.424612 |    319.843010 | Matt Crook                                                                                                                                                            |
| 366 |    210.888945 |    538.452264 | NA                                                                                                                                                                    |
| 367 |    188.206837 |    474.927439 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 368 |    759.215861 |     59.948972 | Joanna Wolfe                                                                                                                                                          |
| 369 |   1003.164726 |    472.868683 | Steven Traver                                                                                                                                                         |
| 370 |    614.768657 |    121.565399 | Amanda Katzer                                                                                                                                                         |
| 371 |    452.474630 |    405.049120 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 372 |    781.197679 |    376.695222 | Christine Axon                                                                                                                                                        |
| 373 |    931.418756 |    499.719799 | Rebecca Groom                                                                                                                                                         |
| 374 |    738.667793 |    291.510837 | Matt Crook                                                                                                                                                            |
| 375 |    195.250288 |    127.038606 | Yan Wong                                                                                                                                                              |
| 376 |    340.849675 |    208.472376 | Stacy Spensley (Modified)                                                                                                                                             |
| 377 |    821.089499 |    697.641489 | Ingo Braasch                                                                                                                                                          |
| 378 |    968.441759 |    363.326145 | Kimberly Haddrell                                                                                                                                                     |
| 379 |    861.071800 |    401.810714 | Kamil S. Jaron                                                                                                                                                        |
| 380 |    581.205774 |    508.587046 | Margot Michaud                                                                                                                                                        |
| 381 |    321.422520 |    484.492247 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 382 |     64.295728 |     20.124601 | Todd Marshall, vectorized by Zimices                                                                                                                                  |
| 383 |    200.804907 |    795.283454 | Margot Michaud                                                                                                                                                        |
| 384 |    778.744646 |    623.081655 | Kailah Thorn & Mark Hutchinson                                                                                                                                        |
| 385 |    485.498858 |    284.770365 | Erika Schumacher                                                                                                                                                      |
| 386 |    544.852261 |     13.670651 | Chris huh                                                                                                                                                             |
| 387 |    614.721000 |    548.651694 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 388 |    253.729466 |    767.401551 | Timothy Knepp of the U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                |
| 389 |     59.766979 |    572.172321 | Armin Reindl                                                                                                                                                          |
| 390 |    985.469577 |    453.287448 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                                |
| 391 |    944.939898 |    305.271462 | Harold N Eyster                                                                                                                                                       |
| 392 |    371.717151 |    215.745648 | Lee Harding (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
| 393 |    260.205245 |    424.120025 | Christoph Schomburg                                                                                                                                                   |
| 394 |    306.199070 |    251.437729 | Tasman Dixon                                                                                                                                                          |
| 395 |    814.175051 |      6.613254 | Steven Traver                                                                                                                                                         |
| 396 |    297.255676 |     53.908029 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 397 |    579.043571 |    574.398823 | Jagged Fang Designs                                                                                                                                                   |
| 398 |    234.968463 |      3.872920 | Craig Dylke                                                                                                                                                           |
| 399 |    251.297839 |    111.386086 | Steven Coombs                                                                                                                                                         |
| 400 |    663.392464 |    692.822743 | Giant Blue Anteater (vectorized by T. Michael Keesey)                                                                                                                 |
| 401 |    782.409328 |    159.978125 | Chris huh                                                                                                                                                             |
| 402 |    170.683140 |    696.957099 | Sarah Werning                                                                                                                                                         |
| 403 |    531.253368 |    658.956457 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 404 |    304.399350 |    639.772576 | Francis de Laporte de Castelnau (vectorized by T. Michael Keesey)                                                                                                     |
| 405 |     12.254895 |    559.025556 | Mali’o Kodis, photograph by P. Funch and R.M. Kristensen                                                                                                              |
| 406 |    347.488345 |    742.133756 | Pete Buchholz                                                                                                                                                         |
| 407 |    523.200751 |    181.493004 | Shyamal                                                                                                                                                               |
| 408 |    916.138808 |     13.986235 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 409 |    309.946424 |    139.902419 | Amanda Katzer                                                                                                                                                         |
| 410 |     60.753939 |    219.497816 | Gareth Monger                                                                                                                                                         |
| 411 |    484.121255 |     53.164698 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                  |
| 412 |    955.332430 |    121.949308 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 413 |    637.570007 |    328.865227 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 414 |    301.362289 |     97.936558 | Fernando Campos De Domenico                                                                                                                                           |
| 415 |    998.771463 |     71.131962 | NA                                                                                                                                                                    |
| 416 |     62.225888 |    581.442245 | Jagged Fang Designs                                                                                                                                                   |
| 417 |     19.313765 |    266.633607 | Margot Michaud                                                                                                                                                        |
| 418 |     35.106541 |    316.689805 | Gareth Monger                                                                                                                                                         |
| 419 |    451.784829 |     17.638289 | Dean Schnabel                                                                                                                                                         |
| 420 |    104.209654 |    355.698725 | Shyamal                                                                                                                                                               |
| 421 |    543.439521 |     66.574248 | Steven Traver                                                                                                                                                         |
| 422 |    908.687983 |    787.429291 | Jagged Fang Designs                                                                                                                                                   |
| 423 |    480.963951 |    393.375040 | Zimices                                                                                                                                                               |
| 424 |    606.729991 |     33.271874 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 425 |    710.412862 |    493.918966 | Margot Michaud                                                                                                                                                        |
| 426 |    182.498220 |    141.129799 | Margot Michaud                                                                                                                                                        |
| 427 |    425.534856 |    793.860880 | Markus A. Grohme                                                                                                                                                      |
| 428 |    969.058781 |    404.565067 | Andy Wilson                                                                                                                                                           |
| 429 |    176.104575 |     13.451403 | Erika Schumacher                                                                                                                                                      |
| 430 |    416.223836 |     14.629078 | Chris huh                                                                                                                                                             |
| 431 |    543.143920 |    715.512875 | Jagged Fang Designs                                                                                                                                                   |
| 432 |   1003.865696 |    714.612874 | Ferran Sayol                                                                                                                                                          |
| 433 |    228.271527 |    365.003537 | Jack Mayer Wood                                                                                                                                                       |
| 434 |    861.706971 |    750.491226 | Steven Coombs                                                                                                                                                         |
| 435 |    546.720310 |    101.620183 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 436 |    354.021439 |    271.666311 | C. Camilo Julián-Caballero                                                                                                                                            |
| 437 |    842.741204 |    631.620156 | CNZdenek                                                                                                                                                              |
| 438 |    272.672769 |    559.231090 | Iain Reid                                                                                                                                                             |
| 439 |    740.650386 |    680.713132 | Lisa Byrne                                                                                                                                                            |
| 440 |    265.900789 |    588.776231 | Joanna Wolfe                                                                                                                                                          |
| 441 |    376.436542 |    652.898884 | Markus A. Grohme                                                                                                                                                      |
| 442 |    145.752833 |    325.759578 | Scott Reid                                                                                                                                                            |
| 443 |    863.858624 |    421.100732 | Rebecca Groom                                                                                                                                                         |
| 444 |    873.729056 |    594.754538 | Jagged Fang Designs                                                                                                                                                   |
| 445 |    857.743371 |     97.837790 | Ignacio Contreras                                                                                                                                                     |
| 446 |    876.803213 |    509.698866 | Tasman Dixon                                                                                                                                                          |
| 447 |     19.294151 |    672.804424 | Gareth Monger                                                                                                                                                         |
| 448 |     13.170772 |    775.696202 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 449 |    422.367756 |    238.940792 | C. Camilo Julián-Caballero                                                                                                                                            |
| 450 |    376.418163 |    460.252325 | Erika Schumacher                                                                                                                                                      |
| 451 |    573.569829 |    720.671614 | Jagged Fang Designs                                                                                                                                                   |
| 452 |    712.581744 |    623.128216 | Gareth Monger                                                                                                                                                         |
| 453 |    827.896540 |    184.231624 | Beth Reinke                                                                                                                                                           |
| 454 |    227.211097 |    781.266721 | Iain Reid                                                                                                                                                             |
| 455 |    920.463533 |     33.803568 | Chris huh                                                                                                                                                             |
| 456 |     61.365683 |    243.516654 | Kai R. Caspar                                                                                                                                                         |
| 457 |    334.098963 |     75.933325 | Scott Hartman                                                                                                                                                         |
| 458 |    734.304962 |    150.037334 | Zimices                                                                                                                                                               |
| 459 |    758.960490 |     17.618699 | Steven Traver                                                                                                                                                         |
| 460 |    964.527178 |    334.597579 | Iain Reid                                                                                                                                                             |
| 461 |      4.014619 |    656.651444 | T. Michael Keesey                                                                                                                                                     |
| 462 |    525.038414 |    758.140511 | Hugo Gruson                                                                                                                                                           |
| 463 |    585.169952 |    494.969419 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 464 |    993.255625 |    158.183913 | Henry Lydecker                                                                                                                                                        |
| 465 |    305.447568 |     79.949609 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 466 |    162.855136 |    363.397336 | Scott Hartman                                                                                                                                                         |
| 467 |    220.056797 |    388.663053 | Felix Vaux                                                                                                                                                            |
| 468 |    644.352035 |    653.345997 | Ignacio Contreras                                                                                                                                                     |
| 469 |    433.225898 |    712.112328 | NA                                                                                                                                                                    |
| 470 |    830.832406 |    295.989831 | Scott Hartman                                                                                                                                                         |
| 471 |    816.982447 |    442.783100 | Matt Crook                                                                                                                                                            |
| 472 |    800.840420 |    542.302208 | Dantheman9758 (vectorized by T. Michael Keesey)                                                                                                                       |
| 473 |    237.972920 |    332.596091 | Tasman Dixon                                                                                                                                                          |
| 474 |    914.516586 |     55.297145 | NA                                                                                                                                                                    |
| 475 |    318.275110 |    330.907617 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 476 |    504.384939 |    237.574993 | Henry Lydecker                                                                                                                                                        |
| 477 |    832.384193 |    306.977383 | NA                                                                                                                                                                    |
| 478 |    242.088036 |    324.016460 | Jagged Fang Designs                                                                                                                                                   |
| 479 |    812.051112 |     77.354113 | Markus A. Grohme                                                                                                                                                      |
| 480 |    158.699458 |    638.249685 | Chris huh                                                                                                                                                             |
| 481 |     46.586798 |    485.930959 | Scott Hartman                                                                                                                                                         |
| 482 |    969.265128 |    346.148324 | Chris huh                                                                                                                                                             |
| 483 |    784.309636 |    295.056528 | Melissa Broussard                                                                                                                                                     |
| 484 |    826.897774 |    276.652021 | S.Martini                                                                                                                                                             |
| 485 |    981.109359 |    719.278723 | Chris huh                                                                                                                                                             |
| 486 |    369.994546 |    232.668770 | Felix Vaux and Steven A. Trewick                                                                                                                                      |
| 487 |    133.736222 |    793.171765 | Gareth Monger                                                                                                                                                         |
| 488 |    677.852841 |    469.969922 | Jagged Fang Designs                                                                                                                                                   |
| 489 |    231.793698 |    551.073141 | Margot Michaud                                                                                                                                                        |
| 490 |    405.553862 |    144.664500 | Sibi (vectorized by T. Michael Keesey)                                                                                                                                |
| 491 |    145.821580 |    246.680677 |                                                                                                                                                                       |
| 492 |    550.030807 |    319.357193 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 493 |    192.147166 |    195.634105 | Dmitry Bogdanov                                                                                                                                                       |
| 494 |     20.931617 |    602.566633 | Marie-Aimée Allard                                                                                                                                                    |
| 495 |    760.150176 |    341.544549 | T. Michael Keesey (vectorization) and Larry Loos (photography)                                                                                                        |
| 496 |    269.058466 |    370.878272 | Geoff Shaw                                                                                                                                                            |
| 497 |     78.879351 |    270.858395 | Matthew E. Clapham                                                                                                                                                    |
| 498 |    417.513763 |    428.956719 | Jagged Fang Designs                                                                                                                                                   |
| 499 |    847.636877 |    520.500804 | Matt Crook                                                                                                                                                            |
| 500 |   1008.211658 |    527.597069 | Zimices                                                                                                                                                               |
| 501 |    581.355806 |    794.723972 | Dexter R. Mardis                                                                                                                                                      |
| 502 |    589.367869 |    709.724383 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 503 |   1001.245538 |     21.230595 | Geoff Shaw                                                                                                                                                            |
| 504 |    924.459950 |    319.424598 | Markus A. Grohme                                                                                                                                                      |
| 505 |    770.917693 |    694.929862 | Ghedo (vectorized by T. Michael Keesey)                                                                                                                               |
| 506 |    243.481135 |     78.868479 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                      |
| 507 |    318.323263 |     37.831066 | Gareth Monger                                                                                                                                                         |
| 508 |    760.742835 |    686.699602 | Zimices                                                                                                                                                               |
| 509 |    792.511462 |    128.693687 | T. K. Robinson                                                                                                                                                        |
| 510 |     19.562128 |    525.402124 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 511 |    988.629791 |    682.632855 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 512 |     69.160237 |    708.939932 | ДиБгд (vectorized by T. Michael Keesey)                                                                                                                               |
| 513 |    230.644711 |    421.605988 | Zimices                                                                                                                                                               |
| 514 |    953.854606 |    282.597080 | Moussa Direct Ltd. (photography) and T. Michael Keesey (vectorization)                                                                                                |
| 515 |    883.053373 |     69.049515 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 516 |    859.896142 |    282.374748 | Markus A. Grohme                                                                                                                                                      |
| 517 |    847.883300 |    461.391928 | Gareth Monger                                                                                                                                                         |

    #> Your tweet has been posted!
