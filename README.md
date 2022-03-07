
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

Tod Robbins, Steven Traver, Jan A. Venter, Herbert H. T. Prins, David A.
Balfour & Rob Slotow (vectorized by T. Michael Keesey), Matt Crook,
Geoff Shaw, Collin Gross, Sebastian Stabinger, Matt Martyniuk
(vectorized by T. Michael Keesey), Zimices, Ryan Cupo, CNZdenek, Birgit
Lang, Nobu Tamura, vectorized by Zimices, Manabu Bessho-Uehara, Maija
Karala, Nobu Tamura, Tasman Dixon, Anthony Caravaggi, Rebecca Groom,
Dean Schnabel, Kent Elson Sorgon, Gabriela Palomo-Munoz, Gareth Monger,
Kamil S. Jaron, Jagged Fang Designs, FunkMonk, Giant Blue Anteater
(vectorized by T. Michael Keesey), Berivan Temiz, L. Shyamal, Margot
Michaud, T. Michael Keesey, Alan Manson (photo), John E. McCormack,
Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C.
Glenn, Robb T. Brumfield & T. Michael Keesey, Ferran Sayol, Felix Vaux,
Shyamal, Scott Hartman, Chris huh, Maxime Dahirel, Brian Gratwicke
(photo) and T. Michael Keesey (vectorization), Maxwell Lefroy
(vectorized by T. Michael Keesey), Erika Schumacher, Sarah Werning, Matt
Dempsey, Nobu Tamura (vectorized by T. Michael Keesey), Andy Wilson,
Chris Jennings (Risiatto), NOAA Great Lakes Environmental Research
Laboratory (illustration) and Timothy J. Bartley (silhouette), Zachary
Quigley, Remes K, Ortega F, Fierro I, Joger U, Kosma R, et al., Lily
Hughes, Chuanixn Yu, Markus A. Grohme, Michael Scroggie, Florian Pfaff,
Heinrich Harder (vectorized by T. Michael Keesey), Jaime Chirinos
(vectorized by T. Michael Keesey), Mark Witton, Tracy A. Heath, Jonathan
Wells, Steven Coombs, Matt Martyniuk, Jose Carlos Arenas-Monroy, Scott
Reid, Noah Schlottman, photo by Casey Dunn, Ignacio Contreras, Derek
Bakken (photograph) and T. Michael Keesey (vectorization), Aviceda
(photo) & T. Michael Keesey, David Orr, Dmitry Bogdanov (vectorized by
T. Michael Keesey), Oliver Griffith, Mike Hanson, T. Michael Keesey
(after C. De Muizon), Tauana J. Cunha, Sergio A. Muñoz-Gómez, Nicholas
J. Czaplewski, vectorized by Zimices, James I. Kirkland, Luis Alcalá,
Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma
(vectorized by T. Michael Keesey), Ghedoghedo (vectorized by T. Michael
Keesey), Jakovche, Mattia Menchetti, Diego Fontaneto, Elisabeth A.
Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia
Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey),
Henry Fairfield Osborn, vectorized by Zimices, Mathew Wedel, C. Camilo
Julián-Caballero, Michael P. Taylor, Christopher Laumer (vectorized by
T. Michael Keesey), Dmitry Bogdanov, Christoph Schomburg, Original
drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja, Henry
Lydecker, Michelle Site, Julie Blommaert based on photo by Sofdrakou,
Dmitry Bogdanov, vectorized by Zimices, Christine Axon, Alex Slavenko,
Andrew A. Farke, Caleb M. Brown, Chloé Schmidt, SecretJellyMan - from
Mason McNair, Yan Wong, Donovan Reginald Rosevear (vectorized by T.
Michael Keesey), Elizabeth Parker, Kevin Sánchez, Robert Gay, Roberto
Díaz Sibaja, Carlos Cano-Barbacil, Hans Hillewaert, M Kolmann, Juan
Carlos Jerí, Arthur Weasley (vectorized by T. Michael Keesey), Chase
Brownstein, Eduard Solà (vectorized by T. Michael Keesey), Julio Garza,
Chris A. Hamilton, Scarlet23 (vectorized by T. Michael Keesey), Jaime
Headden, modified by T. Michael Keesey, Birgit Szabo, Sam Fraser-Smith
(vectorized by T. Michael Keesey), Lee Harding (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Kailah Thorn &
Mark Hutchinson, Madeleine Price Ball, david maas / dave hone, Crystal
Maier, Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael
Keesey., Acrocynus (vectorized by T. Michael Keesey), Milton Tan, James
R. Spotila and Ray Chatterji, Ingo Braasch, Josefine Bohr Brask, Jack
Mayer Wood, Griensteidl and T. Michael Keesey, Becky Barnes, Sharon
Wegner-Larsen, Kelly, Konsta Happonen, from a CC-BY-NC image by
sokolkov2002 on iNaturalist, Yan Wong from photo by Denes Emoke, JJ
Harrison (vectorized by T. Michael Keesey), Darren Naish (vectorized by
T. Michael Keesey), Meliponicultor Itaymbere, Alyssa Bell & Luis Chiappe
2015, dx.doi.org/10.1371/journal.pone.0141690, Mali’o Kodis, photograph
by P. Funch and R.M. Kristensen, Roberto Diaz Sibaja, based on Domser,
Daniel Jaron, Stanton F. Fink (vectorized by T. Michael Keesey),
Obsidian Soul (vectorized by T. Michael Keesey), V. Deepak, Mo Hassan,
Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley
(silhouette), Scott Hartman, modified by T. Michael Keesey, Diana
Pomeroy, Steven Haddock • Jellywatch.org, Mariana Ruiz Villarreal
(modified by T. Michael Keesey), Neil Kelley, Noah Schlottman,
Lukasiniho, Matt Celeskey, www.studiospectre.com, Abraão Leite, Harold N
Eyster, E. Lear, 1819 (vectorization by Yan Wong), Kanchi Nanjo, Emily
Willoughby, Craig Dylke, FJDegrange, Tyler Greenfield, Catherine Yasuda,
T. Michael Keesey (after Marek Velechovský), FunkMonk (Michael B.H.;
vectorized by T. Michael Keesey), Lankester Edwin Ray (vectorized by T.
Michael Keesey), Katie S. Collins, Iain Reid, Christian A. Masnaghetti,
Andrew A. Farke, shell lines added by Yan Wong, Kai R. Caspar, Tony
Ayling, Peileppe, Ghedoghedo, Danielle Alba, Steven Coombs (vectorized
by T. Michael Keesey), Dexter R. Mardis, Beth Reinke, Jaime Headden,
Thibaut Brunet, Rene Martin, Caio Bernardes, vectorized by Zimices,
Scott Hartman (modified by T. Michael Keesey), (unknown), LeonardoG
(photography) and T. Michael Keesey (vectorization), Michael Scroggie,
from original photograph by Gary M. Stolz, USFWS (original photograph in
public domain)., Ellen Edmonson and Hugh Chrisp (vectorized by T.
Michael Keesey)

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |     954.84490 |    570.359554 | Tod Robbins                                                                                                                                                           |
|   2 |     287.06448 |    284.643633 | Steven Traver                                                                                                                                                         |
|   3 |     159.52657 |    661.502020 | Steven Traver                                                                                                                                                         |
|   4 |      84.85595 |    373.183375 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
|   5 |     608.63852 |    444.069572 | Matt Crook                                                                                                                                                            |
|   6 |     771.91656 |    196.968489 | Geoff Shaw                                                                                                                                                            |
|   7 |     495.39540 |     85.550672 | Collin Gross                                                                                                                                                          |
|   8 |     933.69127 |    368.753733 | Sebastian Stabinger                                                                                                                                                   |
|   9 |     391.01339 |    203.732416 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                      |
|  10 |     876.19641 |    205.523243 | Zimices                                                                                                                                                               |
|  11 |     104.48409 |    485.201172 | Ryan Cupo                                                                                                                                                             |
|  12 |     520.51208 |    591.078343 | NA                                                                                                                                                                    |
|  13 |     739.12859 |    266.113557 | CNZdenek                                                                                                                                                              |
|  14 |     914.88510 |    431.934728 | Birgit Lang                                                                                                                                                           |
|  15 |     919.18386 |    288.413649 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
|  16 |     511.31031 |    411.180871 | Matt Crook                                                                                                                                                            |
|  17 |     764.71759 |    692.852589 | Manabu Bessho-Uehara                                                                                                                                                  |
|  18 |     746.79182 |    140.751967 | Maija Karala                                                                                                                                                          |
|  19 |     199.13682 |    146.692966 | Zimices                                                                                                                                                               |
|  20 |     534.90740 |    298.605555 | Nobu Tamura                                                                                                                                                           |
|  21 |     265.97867 |    532.342892 | Tasman Dixon                                                                                                                                                          |
|  22 |     608.51018 |    217.930807 | Anthony Caravaggi                                                                                                                                                     |
|  23 |     221.70477 |    349.129707 | Rebecca Groom                                                                                                                                                         |
|  24 |     587.97777 |    128.848314 | Dean Schnabel                                                                                                                                                         |
|  25 |     883.82749 |    706.894867 | Kent Elson Sorgon                                                                                                                                                     |
|  26 |     119.51673 |    234.130821 | Steven Traver                                                                                                                                                         |
|  27 |     271.69960 |    685.346705 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  28 |     372.48812 |    346.950989 | Gareth Monger                                                                                                                                                         |
|  29 |     709.65476 |    552.602300 | Kamil S. Jaron                                                                                                                                                        |
|  30 |     296.95639 |     84.723956 | Jagged Fang Designs                                                                                                                                                   |
|  31 |     806.31918 |    371.082350 | FunkMonk                                                                                                                                                              |
|  32 |     101.18982 |     69.083467 | Matt Crook                                                                                                                                                            |
|  33 |     446.86177 |    713.436604 | NA                                                                                                                                                                    |
|  34 |     912.92674 |    160.401251 | Giant Blue Anteater (vectorized by T. Michael Keesey)                                                                                                                 |
|  35 |     771.03507 |     24.029549 | Steven Traver                                                                                                                                                         |
|  36 |     338.90224 |    483.693234 | Berivan Temiz                                                                                                                                                         |
|  37 |     298.96087 |    607.001904 | L. Shyamal                                                                                                                                                            |
|  38 |     667.26358 |     79.682878 | Margot Michaud                                                                                                                                                        |
|  39 |     954.00664 |    750.855738 | T. Michael Keesey                                                                                                                                                     |
|  40 |     665.75323 |    242.825295 | Alan Manson (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
|  41 |      82.54450 |    713.238656 | Ferran Sayol                                                                                                                                                          |
|  42 |     492.88949 |    184.213983 | Margot Michaud                                                                                                                                                        |
|  43 |     850.69307 |    627.238707 | Felix Vaux                                                                                                                                                            |
|  44 |     362.85052 |    271.327016 | Gareth Monger                                                                                                                                                         |
|  45 |     930.80611 |     73.553024 | Gareth Monger                                                                                                                                                         |
|  46 |     698.09145 |    462.113801 | Gareth Monger                                                                                                                                                         |
|  47 |     946.77196 |    633.281226 | Zimices                                                                                                                                                               |
|  48 |     120.12891 |    567.283002 | Shyamal                                                                                                                                                               |
|  49 |     853.05914 |    117.813856 | Scott Hartman                                                                                                                                                         |
|  50 |     321.41402 |     35.157005 | Chris huh                                                                                                                                                             |
|  51 |     609.21324 |    715.588284 | Steven Traver                                                                                                                                                         |
|  52 |     179.27765 |    746.568250 | Steven Traver                                                                                                                                                         |
|  53 |     387.33415 |     89.373546 | Maxime Dahirel                                                                                                                                                        |
|  54 |     895.74067 |    521.147501 | Steven Traver                                                                                                                                                         |
|  55 |     802.00976 |    475.439108 | Brian Gratwicke (photo) and T. Michael Keesey (vectorization)                                                                                                         |
|  56 |     661.72559 |    340.121494 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                      |
|  57 |     267.63646 |    199.225415 | Erika Schumacher                                                                                                                                                      |
|  58 |     954.86821 |    486.155905 | Sarah Werning                                                                                                                                                         |
|  59 |     332.78531 |    766.439399 | NA                                                                                                                                                                    |
|  60 |     474.19278 |    241.089342 | Jagged Fang Designs                                                                                                                                                   |
|  61 |     395.34186 |    632.384053 | Matt Dempsey                                                                                                                                                          |
|  62 |     273.46567 |    436.623663 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  63 |      70.19209 |    256.300842 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  64 |     604.91417 |    786.291718 | Gareth Monger                                                                                                                                                         |
|  65 |     152.54251 |    351.058346 | T. Michael Keesey                                                                                                                                                     |
|  66 |      74.97472 |    148.367861 | Andy Wilson                                                                                                                                                           |
|  67 |      67.34388 |    633.364423 | Chris Jennings (Risiatto)                                                                                                                                             |
|  68 |     847.85144 |     81.746404 | Jagged Fang Designs                                                                                                                                                   |
|  69 |     589.21065 |     38.064448 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
|  70 |     900.83313 |    335.017571 | Maija Karala                                                                                                                                                          |
|  71 |     928.73312 |     17.247782 | Chris huh                                                                                                                                                             |
|  72 |     343.82458 |    409.961019 | Zachary Quigley                                                                                                                                                       |
|  73 |     493.21337 |     21.555676 | Jagged Fang Designs                                                                                                                                                   |
|  74 |     524.75445 |    762.066670 | Chris huh                                                                                                                                                             |
|  75 |     465.30111 |    476.954558 | Remes K, Ortega F, Fierro I, Joger U, Kosma R, et al.                                                                                                                 |
|  76 |     182.71779 |    603.690366 | Lily Hughes                                                                                                                                                           |
|  77 |     630.06440 |    751.586155 | NA                                                                                                                                                                    |
|  78 |     717.56470 |    308.320331 | Chuanixn Yu                                                                                                                                                           |
|  79 |     870.91395 |    269.996255 | Markus A. Grohme                                                                                                                                                      |
|  80 |     758.22751 |    230.955943 | NA                                                                                                                                                                    |
|  81 |      82.76514 |    184.571760 | Jagged Fang Designs                                                                                                                                                   |
|  82 |     365.05893 |    678.912306 | Collin Gross                                                                                                                                                          |
|  83 |     281.94647 |    164.238288 | Tasman Dixon                                                                                                                                                          |
|  84 |     206.70305 |     75.331089 | Michael Scroggie                                                                                                                                                      |
|  85 |     757.80805 |    501.128637 | Florian Pfaff                                                                                                                                                         |
|  86 |     442.83779 |    343.369912 | Heinrich Harder (vectorized by T. Michael Keesey)                                                                                                                     |
|  87 |     762.14757 |     95.088291 | Collin Gross                                                                                                                                                          |
|  88 |     398.69289 |    592.572418 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  89 |     980.05206 |    227.372219 | Jaime Chirinos (vectorized by T. Michael Keesey)                                                                                                                      |
|  90 |     112.33556 |    611.610326 | Mark Witton                                                                                                                                                           |
|  91 |      41.23882 |     36.792386 | Tracy A. Heath                                                                                                                                                        |
|  92 |     371.70149 |    545.493853 | Jonathan Wells                                                                                                                                                        |
|  93 |     635.81314 |    533.730641 | Steven Coombs                                                                                                                                                         |
|  94 |     508.79600 |    725.933860 | Scott Hartman                                                                                                                                                         |
|  95 |     666.13149 |     14.124686 | Steven Traver                                                                                                                                                         |
|  96 |     107.93258 |    318.420276 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  97 |     294.69307 |    125.358249 | Matt Martyniuk                                                                                                                                                        |
|  98 |      45.99459 |    582.692567 | Jagged Fang Designs                                                                                                                                                   |
|  99 |     662.22793 |    160.391880 | NA                                                                                                                                                                    |
| 100 |     449.92670 |    267.866941 | NA                                                                                                                                                                    |
| 101 |     375.10179 |    440.354264 | Gareth Monger                                                                                                                                                         |
| 102 |     814.77031 |    292.754428 | Chris huh                                                                                                                                                             |
| 103 |     993.08373 |    154.854209 | Steven Traver                                                                                                                                                         |
| 104 |     363.68454 |    716.210003 | Margot Michaud                                                                                                                                                        |
| 105 |     476.05515 |    217.566281 | Steven Traver                                                                                                                                                         |
| 106 |     995.61642 |    305.033238 | Steven Traver                                                                                                                                                         |
| 107 |     183.19670 |    535.233129 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 108 |     446.39357 |    288.821778 | Scott Reid                                                                                                                                                            |
| 109 |     194.50342 |    465.213294 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
| 110 |      71.93878 |    160.093053 | Margot Michaud                                                                                                                                                        |
| 111 |     870.83917 |    556.879884 | Ignacio Contreras                                                                                                                                                     |
| 112 |     237.00975 |    223.723874 | Derek Bakken (photograph) and T. Michael Keesey (vectorization)                                                                                                       |
| 113 |      26.19437 |    703.248211 | T. Michael Keesey                                                                                                                                                     |
| 114 |      26.46514 |    419.436623 | Aviceda (photo) & T. Michael Keesey                                                                                                                                   |
| 115 |     484.10529 |    635.620512 | Gareth Monger                                                                                                                                                         |
| 116 |     924.12164 |    118.880028 | David Orr                                                                                                                                                             |
| 117 |     477.82178 |    657.789729 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 118 |     582.18612 |     75.779599 | Oliver Griffith                                                                                                                                                       |
| 119 |      41.92293 |    463.153585 | Mike Hanson                                                                                                                                                           |
| 120 |     210.69903 |    479.031287 | Zimices                                                                                                                                                               |
| 121 |     801.17658 |    179.554842 | T. Michael Keesey (after C. De Muizon)                                                                                                                                |
| 122 |     586.69048 |    691.760963 | Tauana J. Cunha                                                                                                                                                       |
| 123 |     123.34032 |    718.045372 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 124 |     425.81760 |    515.819167 | Nicholas J. Czaplewski, vectorized by Zimices                                                                                                                         |
| 125 |     309.03748 |     51.512879 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                  |
| 126 |     415.36918 |    368.332808 | Andy Wilson                                                                                                                                                           |
| 127 |     984.24085 |    697.230204 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 128 |      26.17975 |    483.283089 | Scott Hartman                                                                                                                                                         |
| 129 |      58.53500 |    475.421474 | Zimices                                                                                                                                                               |
| 130 |     983.27669 |    596.784410 | Zimices                                                                                                                                                               |
| 131 |     809.68795 |    305.425641 | Mike Hanson                                                                                                                                                           |
| 132 |      32.22529 |    543.775238 | Matt Crook                                                                                                                                                            |
| 133 |     942.54842 |    183.617071 | Jakovche                                                                                                                                                              |
| 134 |     700.57600 |    115.976032 | Markus A. Grohme                                                                                                                                                      |
| 135 |     577.18203 |    359.614779 | Mattia Menchetti                                                                                                                                                      |
| 136 |     408.95339 |    739.380248 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 137 |     205.72121 |    269.107134 | Jagged Fang Designs                                                                                                                                                   |
| 138 |    1008.73549 |    644.057151 | Margot Michaud                                                                                                                                                        |
| 139 |     108.15280 |    750.945699 | L. Shyamal                                                                                                                                                            |
| 140 |     588.58805 |    549.164136 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 141 |     309.30196 |    530.448555 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                                         |
| 142 |     983.10966 |    411.593907 | Mathew Wedel                                                                                                                                                          |
| 143 |     100.00721 |    457.567316 | C. Camilo Julián-Caballero                                                                                                                                            |
| 144 |     424.78070 |    215.128799 | CNZdenek                                                                                                                                                              |
| 145 |     192.37117 |    428.710610 | Steven Traver                                                                                                                                                         |
| 146 |     626.40728 |    505.579974 | Michael P. Taylor                                                                                                                                                     |
| 147 |     266.33710 |    353.176599 | Christopher Laumer (vectorized by T. Michael Keesey)                                                                                                                  |
| 148 |     438.50031 |     44.899598 | NA                                                                                                                                                                    |
| 149 |     705.97133 |    778.385118 | Margot Michaud                                                                                                                                                        |
| 150 |     219.19313 |    267.813932 | Scott Hartman                                                                                                                                                         |
| 151 |     655.78655 |    627.618697 | Rebecca Groom                                                                                                                                                         |
| 152 |     774.50695 |    332.331732 | Dmitry Bogdanov                                                                                                                                                       |
| 153 |     420.85973 |    770.667299 | Jagged Fang Designs                                                                                                                                                   |
| 154 |     146.23257 |    508.172026 | Mattia Menchetti                                                                                                                                                      |
| 155 |     138.56016 |    288.714969 | Christoph Schomburg                                                                                                                                                   |
| 156 |     791.04149 |    636.681157 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                                |
| 157 |     399.03871 |    566.958471 | Henry Lydecker                                                                                                                                                        |
| 158 |     769.10749 |    597.511778 | Scott Hartman                                                                                                                                                         |
| 159 |     849.68107 |    150.129262 | Michelle Site                                                                                                                                                         |
| 160 |      89.29542 |    665.612629 | Margot Michaud                                                                                                                                                        |
| 161 |     201.27497 |    236.142839 | Julie Blommaert based on photo by Sofdrakou                                                                                                                           |
| 162 |     340.72317 |    237.341704 | NA                                                                                                                                                                    |
| 163 |     466.34550 |    159.685004 | Dmitry Bogdanov, vectorized by Zimices                                                                                                                                |
| 164 |     527.26707 |    162.612488 | Christine Axon                                                                                                                                                        |
| 165 |     141.99175 |    183.417436 | NA                                                                                                                                                                    |
| 166 |     425.14413 |    383.085261 | Alex Slavenko                                                                                                                                                         |
| 167 |     627.60741 |    284.498195 | Zimices                                                                                                                                                               |
| 168 |      91.52856 |    241.882737 | Andrew A. Farke                                                                                                                                                       |
| 169 |     990.41008 |    393.441853 | Steven Traver                                                                                                                                                         |
| 170 |     642.41155 |    320.768385 | T. Michael Keesey                                                                                                                                                     |
| 171 |      21.92765 |    326.934904 | Caleb M. Brown                                                                                                                                                        |
| 172 |     464.63937 |    133.640281 | Chloé Schmidt                                                                                                                                                         |
| 173 |     166.43391 |     34.686962 | NA                                                                                                                                                                    |
| 174 |     759.67918 |     57.838117 | Manabu Bessho-Uehara                                                                                                                                                  |
| 175 |     489.43417 |    691.817265 | Erika Schumacher                                                                                                                                                      |
| 176 |     831.18848 |    422.326009 | SecretJellyMan - from Mason McNair                                                                                                                                    |
| 177 |      54.17267 |    291.723192 | Andy Wilson                                                                                                                                                           |
| 178 |     518.74533 |    228.778103 | Chris huh                                                                                                                                                             |
| 179 |     187.05506 |    204.152396 | Gareth Monger                                                                                                                                                         |
| 180 |     318.33878 |    668.644896 | Felix Vaux                                                                                                                                                            |
| 181 |     899.02287 |     48.630668 | Markus A. Grohme                                                                                                                                                      |
| 182 |     985.86641 |    105.368713 | Yan Wong                                                                                                                                                              |
| 183 |     696.17381 |    712.215082 | NA                                                                                                                                                                    |
| 184 |     955.60877 |    687.684013 | Donovan Reginald Rosevear (vectorized by T. Michael Keesey)                                                                                                           |
| 185 |      52.53049 |    151.257716 | Markus A. Grohme                                                                                                                                                      |
| 186 |     624.78318 |    295.669957 | Matt Dempsey                                                                                                                                                          |
| 187 |      10.58817 |     85.598934 | Gareth Monger                                                                                                                                                         |
| 188 |     254.33708 |    401.840309 | Elizabeth Parker                                                                                                                                                      |
| 189 |     672.49032 |    647.770809 | Kevin Sánchez                                                                                                                                                         |
| 190 |     296.33228 |    362.904119 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 191 |     887.48780 |    139.287660 | Ignacio Contreras                                                                                                                                                     |
| 192 |     686.12594 |    604.818998 | NA                                                                                                                                                                    |
| 193 |     813.73516 |    678.480475 | Maxime Dahirel                                                                                                                                                        |
| 194 |     559.63615 |    657.587018 | Dmitry Bogdanov                                                                                                                                                       |
| 195 |     437.01870 |    436.032442 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 196 |     416.86448 |    281.845087 | Ferran Sayol                                                                                                                                                          |
| 197 |     518.65744 |    789.180131 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 198 |     177.79863 |    276.473622 | Matt Crook                                                                                                                                                            |
| 199 |     376.34598 |    267.180832 | Robert Gay                                                                                                                                                            |
| 200 |     361.91856 |    343.568302 | Roberto Díaz Sibaja                                                                                                                                                   |
| 201 |     988.54305 |    190.876646 | NA                                                                                                                                                                    |
| 202 |     340.16519 |    546.660522 | Carlos Cano-Barbacil                                                                                                                                                  |
| 203 |     341.84698 |    646.939082 | Scott Hartman                                                                                                                                                         |
| 204 |     647.97335 |    240.916540 | Steven Traver                                                                                                                                                         |
| 205 |     245.70071 |    482.207129 | Gareth Monger                                                                                                                                                         |
| 206 |     238.43345 |     20.480334 | Zimices                                                                                                                                                               |
| 207 |     982.90876 |    526.334676 | Hans Hillewaert                                                                                                                                                       |
| 208 |     244.79382 |    311.674658 | NA                                                                                                                                                                    |
| 209 |     112.98293 |    134.499282 | L. Shyamal                                                                                                                                                            |
| 210 |     767.18543 |     74.318507 | Zimices                                                                                                                                                               |
| 211 |      62.76390 |    593.443645 | M Kolmann                                                                                                                                                             |
| 212 |     657.95333 |    128.537240 | Zimices                                                                                                                                                               |
| 213 |     842.25482 |    204.940418 | Juan Carlos Jerí                                                                                                                                                      |
| 214 |     886.71701 |    364.774340 | Zimices                                                                                                                                                               |
| 215 |      36.48686 |    671.101296 | Zimices                                                                                                                                                               |
| 216 |     349.77876 |    568.430740 | Arthur Weasley (vectorized by T. Michael Keesey)                                                                                                                      |
| 217 |     997.47425 |    425.305206 | Chase Brownstein                                                                                                                                                      |
| 218 |     532.00221 |    331.194648 | Steven Traver                                                                                                                                                         |
| 219 |      82.47007 |    284.040855 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 220 |     520.26143 |    256.075025 | Steven Traver                                                                                                                                                         |
| 221 |     119.16844 |    780.434726 | Eduard Solà (vectorized by T. Michael Keesey)                                                                                                                         |
| 222 |     922.55624 |    399.538871 | Julio Garza                                                                                                                                                           |
| 223 |     186.29413 |    163.587235 | Ferran Sayol                                                                                                                                                          |
| 224 |     320.62298 |    789.936458 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 225 |     183.55737 |    501.435641 | Gareth Monger                                                                                                                                                         |
| 226 |     659.42675 |    669.347966 | Margot Michaud                                                                                                                                                        |
| 227 |     524.93343 |    701.222143 | Chris A. Hamilton                                                                                                                                                     |
| 228 |      47.61507 |    455.819304 | Markus A. Grohme                                                                                                                                                      |
| 229 |      99.77482 |    166.094255 | Arthur Weasley (vectorized by T. Michael Keesey)                                                                                                                      |
| 230 |     750.18020 |    407.198345 | Steven Traver                                                                                                                                                         |
| 231 |     613.65706 |      5.879431 | NA                                                                                                                                                                    |
| 232 |     876.34572 |    576.198243 | Margot Michaud                                                                                                                                                        |
| 233 |     960.62095 |    658.117362 | Zimices                                                                                                                                                               |
| 234 |      73.74276 |      7.343333 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                                           |
| 235 |     890.13569 |    772.509454 | Tasman Dixon                                                                                                                                                          |
| 236 |      52.79732 |     12.067065 | Andy Wilson                                                                                                                                                           |
| 237 |     420.66547 |      5.556229 | Chris huh                                                                                                                                                             |
| 238 |     105.77615 |    340.094575 | Markus A. Grohme                                                                                                                                                      |
| 239 |     794.21393 |    625.382146 | Jaime Headden, modified by T. Michael Keesey                                                                                                                          |
| 240 |     971.42220 |    334.306469 | NA                                                                                                                                                                    |
| 241 |      21.59150 |    747.333156 | NA                                                                                                                                                                    |
| 242 |     833.36131 |    243.093950 | T. Michael Keesey                                                                                                                                                     |
| 243 |     454.23007 |    389.535878 | NA                                                                                                                                                                    |
| 244 |     512.24052 |    140.112376 | Birgit Szabo                                                                                                                                                          |
| 245 |     731.47528 |    366.628564 | Sam Fraser-Smith (vectorized by T. Michael Keesey)                                                                                                                    |
| 246 |     580.08740 |      7.472918 | Lee Harding (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
| 247 |     587.41120 |     18.401457 | Chris huh                                                                                                                                                             |
| 248 |     290.36137 |    546.539800 | Kailah Thorn & Mark Hutchinson                                                                                                                                        |
| 249 |     443.31250 |    305.328816 | Margot Michaud                                                                                                                                                        |
| 250 |     824.60741 |    654.208282 | Madeleine Price Ball                                                                                                                                                  |
| 251 |     267.94057 |    518.507987 | david maas / dave hone                                                                                                                                                |
| 252 |     894.03347 |    588.113062 | Chris huh                                                                                                                                                             |
| 253 |     830.98890 |     54.017822 | Tasman Dixon                                                                                                                                                          |
| 254 |     188.01227 |      9.076139 | Jagged Fang Designs                                                                                                                                                   |
| 255 |     813.77555 |    513.874510 | Gareth Monger                                                                                                                                                         |
| 256 |     293.54929 |    105.898849 | CNZdenek                                                                                                                                                              |
| 257 |     822.25714 |    562.357572 | Kamil S. Jaron                                                                                                                                                        |
| 258 |     479.32667 |    368.458610 | Scott Hartman                                                                                                                                                         |
| 259 |     854.30180 |     23.463740 | Margot Michaud                                                                                                                                                        |
| 260 |     789.55679 |    790.556744 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 261 |     397.99734 |     20.008376 | Jagged Fang Designs                                                                                                                                                   |
| 262 |     694.24226 |    219.757550 | Tasman Dixon                                                                                                                                                          |
| 263 |     141.06734 |    790.168312 | Matt Crook                                                                                                                                                            |
| 264 |     894.20587 |    659.365409 | Crystal Maier                                                                                                                                                         |
| 265 |     257.47435 |    237.416037 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                              |
| 266 |      62.03822 |    768.613643 | Acrocynus (vectorized by T. Michael Keesey)                                                                                                                           |
| 267 |     184.05962 |    580.160960 | Milton Tan                                                                                                                                                            |
| 268 |     995.18005 |     34.256687 | Margot Michaud                                                                                                                                                        |
| 269 |     367.43363 |    788.040739 | James R. Spotila and Ray Chatterji                                                                                                                                    |
| 270 |     844.24664 |    542.527544 | Ingo Braasch                                                                                                                                                          |
| 271 |     264.17161 |    584.079985 | Scott Hartman                                                                                                                                                         |
| 272 |     433.41333 |     21.008960 | Josefine Bohr Brask                                                                                                                                                   |
| 273 |     389.73425 |    153.860161 | Matt Crook                                                                                                                                                            |
| 274 |     514.04736 |    322.945600 | Jack Mayer Wood                                                                                                                                                       |
| 275 |     863.42982 |    766.349630 | Griensteidl and T. Michael Keesey                                                                                                                                     |
| 276 |     754.24889 |    780.246875 | Becky Barnes                                                                                                                                                          |
| 277 |     996.27794 |    789.216831 | Sharon Wegner-Larsen                                                                                                                                                  |
| 278 |      37.15133 |    118.912808 | Chris huh                                                                                                                                                             |
| 279 |     806.56851 |    428.557642 | Markus A. Grohme                                                                                                                                                      |
| 280 |     346.58399 |    216.139508 | Anthony Caravaggi                                                                                                                                                     |
| 281 |     681.78803 |     41.695384 | Sarah Werning                                                                                                                                                         |
| 282 |     767.11364 |    112.175488 | Ignacio Contreras                                                                                                                                                     |
| 283 |      94.14533 |    441.503260 | Michelle Site                                                                                                                                                         |
| 284 |     432.18920 |    133.200392 | Gareth Monger                                                                                                                                                         |
| 285 |     565.16808 |    246.988416 | Becky Barnes                                                                                                                                                          |
| 286 |     674.92006 |    736.633581 | Markus A. Grohme                                                                                                                                                      |
| 287 |     177.68271 |    382.561523 | Christine Axon                                                                                                                                                        |
| 288 |     453.66376 |    627.442676 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 289 |     810.20314 |    129.154519 | Kelly                                                                                                                                                                 |
| 290 |     557.88714 |    695.950914 | Matt Crook                                                                                                                                                            |
| 291 |     993.72977 |    342.709388 | Anthony Caravaggi                                                                                                                                                     |
| 292 |     381.07207 |    754.840731 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 293 |     259.04618 |    558.617720 | Steven Traver                                                                                                                                                         |
| 294 |     524.02231 |     25.622045 | Tasman Dixon                                                                                                                                                          |
| 295 |     729.33735 |     59.318552 | Konsta Happonen, from a CC-BY-NC image by sokolkov2002 on iNaturalist                                                                                                 |
| 296 |     331.65741 |    108.583125 | Collin Gross                                                                                                                                                          |
| 297 |      15.72750 |    183.889666 | Yan Wong from photo by Denes Emoke                                                                                                                                    |
| 298 |     590.62055 |    310.984526 | JJ Harrison (vectorized by T. Michael Keesey)                                                                                                                         |
| 299 |     804.49872 |    252.582141 | NA                                                                                                                                                                    |
| 300 |     172.34358 |    445.799612 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                        |
| 301 |     701.83360 |    187.070039 | Collin Gross                                                                                                                                                          |
| 302 |     734.65438 |    417.555680 | Margot Michaud                                                                                                                                                        |
| 303 |     335.82882 |    538.636448 | Scott Hartman                                                                                                                                                         |
| 304 |     622.16122 |    673.032266 | Meliponicultor Itaymbere                                                                                                                                              |
| 305 |     139.00965 |    124.562777 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 306 |      81.50814 |    528.270580 | FunkMonk                                                                                                                                                              |
| 307 |     634.09441 |    520.061109 | Jagged Fang Designs                                                                                                                                                   |
| 308 |     439.40255 |    322.213606 | Alyssa Bell & Luis Chiappe 2015, dx.doi.org/10.1371/journal.pone.0141690                                                                                              |
| 309 |     480.68125 |    748.139382 | Oliver Griffith                                                                                                                                                       |
| 310 |     385.23598 |    294.295420 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 311 |    1007.28879 |    222.214700 | Tasman Dixon                                                                                                                                                          |
| 312 |     706.99953 |    496.510943 | Mali’o Kodis, photograph by P. Funch and R.M. Kristensen                                                                                                              |
| 313 |     999.19679 |    706.560944 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 314 |     254.56373 |    502.799166 | T. Michael Keesey                                                                                                                                                     |
| 315 |     214.10268 |    223.210679 | Scott Hartman                                                                                                                                                         |
| 316 |     947.91493 |    115.607858 | T. Michael Keesey                                                                                                                                                     |
| 317 |     246.90438 |     60.618724 | Tasman Dixon                                                                                                                                                          |
| 318 |     586.72960 |    326.537078 | Roberto Diaz Sibaja, based on Domser                                                                                                                                  |
| 319 |     635.88331 |    583.745430 | Jagged Fang Designs                                                                                                                                                   |
| 320 |     278.28465 |     14.836591 | Zimices                                                                                                                                                               |
| 321 |     415.19630 |    402.144246 | NA                                                                                                                                                                    |
| 322 |     331.59346 |    333.947917 | Zimices                                                                                                                                                               |
| 323 |     916.43247 |    784.255472 | T. Michael Keesey                                                                                                                                                     |
| 324 |     253.79197 |    170.138079 | Daniel Jaron                                                                                                                                                          |
| 325 |     606.17674 |    365.727240 | Gareth Monger                                                                                                                                                         |
| 326 |     570.71700 |    339.586621 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                     |
| 327 |     217.58851 |    616.101239 | Ignacio Contreras                                                                                                                                                     |
| 328 |     314.48092 |     61.571970 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 329 |     716.47456 |    247.833360 | Markus A. Grohme                                                                                                                                                      |
| 330 |     420.03979 |    251.705854 | V. Deepak                                                                                                                                                             |
| 331 |      36.77814 |     75.430001 | Mo Hassan                                                                                                                                                             |
| 332 |     258.19535 |     32.077689 | Felix Vaux                                                                                                                                                            |
| 333 |     970.67609 |    712.313628 | Tasman Dixon                                                                                                                                                          |
| 334 |     716.57164 |     32.402565 | Caleb M. Brown                                                                                                                                                        |
| 335 |     890.24636 |    794.199644 | Erika Schumacher                                                                                                                                                      |
| 336 |     719.93556 |    456.392393 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 337 |    1014.69359 |    100.966237 | Christoph Schomburg                                                                                                                                                   |
| 338 |     240.45336 |    187.061720 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
| 339 |     690.30826 |    126.483318 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                                     |
| 340 |     878.17916 |    375.619870 | Scott Hartman, modified by T. Michael Keesey                                                                                                                          |
| 341 |     211.13937 |    704.238515 | Collin Gross                                                                                                                                                          |
| 342 |     168.18553 |    422.979612 | FunkMonk                                                                                                                                                              |
| 343 |     816.22615 |    153.952495 | Diana Pomeroy                                                                                                                                                         |
| 344 |      91.49360 |    403.396261 | Michelle Site                                                                                                                                                         |
| 345 |     725.25795 |    480.178051 | NA                                                                                                                                                                    |
| 346 |     322.08967 |    353.928279 | Gareth Monger                                                                                                                                                         |
| 347 |      29.99726 |    726.290917 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 348 |     167.57390 |     69.498762 | Steven Haddock • Jellywatch.org                                                                                                                                       |
| 349 |     142.62955 |    585.187298 | Scott Hartman                                                                                                                                                         |
| 350 |      18.15642 |    380.989562 | Margot Michaud                                                                                                                                                        |
| 351 |     992.99398 |    555.542013 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 352 |      43.02700 |    789.487941 | Jagged Fang Designs                                                                                                                                                   |
| 353 |     419.76333 |    481.750016 | Matt Martyniuk                                                                                                                                                        |
| 354 |     744.20835 |    609.696864 | Collin Gross                                                                                                                                                          |
| 355 |     223.55193 |    684.664642 | NA                                                                                                                                                                    |
| 356 |     218.40512 |     37.373745 | Margot Michaud                                                                                                                                                        |
| 357 |     198.18525 |    114.244638 | Maija Karala                                                                                                                                                          |
| 358 |     952.36919 |    239.355478 | Margot Michaud                                                                                                                                                        |
| 359 |     260.82117 |    101.378683 | Markus A. Grohme                                                                                                                                                      |
| 360 |     408.87985 |    530.782169 | Mariana Ruiz Villarreal (modified by T. Michael Keesey)                                                                                                               |
| 361 |     407.28224 |    706.865555 | Andy Wilson                                                                                                                                                           |
| 362 |     352.10543 |     59.735879 | Markus A. Grohme                                                                                                                                                      |
| 363 |     324.48426 |    179.283677 | Neil Kelley                                                                                                                                                           |
| 364 |     690.40412 |    173.082846 | Noah Schlottman                                                                                                                                                       |
| 365 |     837.39237 |    325.515938 | Chris huh                                                                                                                                                             |
| 366 |    1005.23648 |    174.889795 | Gareth Monger                                                                                                                                                         |
| 367 |     979.70275 |     46.128740 | Zimices                                                                                                                                                               |
| 368 |    1002.15263 |    689.977649 | Steven Traver                                                                                                                                                         |
| 369 |    1006.20459 |     70.210328 | L. Shyamal                                                                                                                                                            |
| 370 |     772.57195 |    424.265527 | NA                                                                                                                                                                    |
| 371 |     724.61754 |    208.498922 | Matt Crook                                                                                                                                                            |
| 372 |     992.73353 |    457.886535 | Lukasiniho                                                                                                                                                            |
| 373 |     136.16214 |    542.805835 | Andrew A. Farke                                                                                                                                                       |
| 374 |      15.14851 |    288.086721 | T. Michael Keesey                                                                                                                                                     |
| 375 |     968.30996 |     92.364885 | Zimices                                                                                                                                                               |
| 376 |     419.14928 |    419.210674 | Jonathan Wells                                                                                                                                                        |
| 377 |     323.35064 |    120.456588 | Gareth Monger                                                                                                                                                         |
| 378 |     123.55674 |    444.741003 | Scott Hartman                                                                                                                                                         |
| 379 |     336.72623 |    136.290422 | Tasman Dixon                                                                                                                                                          |
| 380 |     138.55037 |    689.614187 | Jagged Fang Designs                                                                                                                                                   |
| 381 |     207.80227 |    288.886998 | Zimices                                                                                                                                                               |
| 382 |     295.17682 |    655.043883 | Sharon Wegner-Larsen                                                                                                                                                  |
| 383 |     638.92033 |    774.071678 | Jagged Fang Designs                                                                                                                                                   |
| 384 |     333.04217 |      8.672850 | Matt Celeskey                                                                                                                                                         |
| 385 |     281.72731 |    392.699269 | Gareth Monger                                                                                                                                                         |
| 386 |     458.52920 |    375.078443 | Scott Hartman                                                                                                                                                         |
| 387 |      31.62717 |    499.783269 | T. Michael Keesey                                                                                                                                                     |
| 388 |     463.60456 |    113.357346 | www.studiospectre.com                                                                                                                                                 |
| 389 |     299.96824 |    346.252199 | Gareth Monger                                                                                                                                                         |
| 390 |     639.09097 |    650.586436 | Birgit Lang                                                                                                                                                           |
| 391 |      66.82327 |     68.235973 | T. Michael Keesey                                                                                                                                                     |
| 392 |     697.14966 |    738.521517 | Abraão Leite                                                                                                                                                          |
| 393 |     946.62748 |     43.907552 | Harold N Eyster                                                                                                                                                       |
| 394 |     253.63062 |    793.433826 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 395 |     348.09865 |     78.021108 | NA                                                                                                                                                                    |
| 396 |     794.18957 |    606.678840 | Birgit Lang                                                                                                                                                           |
| 397 |     819.11660 |    644.503303 | Caleb M. Brown                                                                                                                                                        |
| 398 |     253.76459 |    767.862215 | E. Lear, 1819 (vectorization by Yan Wong)                                                                                                                             |
| 399 |     466.49934 |    203.907245 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 400 |      43.39601 |    223.749488 | Kanchi Nanjo                                                                                                                                                          |
| 401 |      76.76370 |    432.075036 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 402 |     794.35795 |    659.493321 | Emily Willoughby                                                                                                                                                      |
| 403 |     911.78683 |    176.278927 | Craig Dylke                                                                                                                                                           |
| 404 |     807.75737 |    325.071582 | FJDegrange                                                                                                                                                            |
| 405 |    1007.55230 |    768.846311 | NA                                                                                                                                                                    |
| 406 |     549.86819 |    205.394316 | Zimices                                                                                                                                                               |
| 407 |     145.95330 |    622.153522 | Chris huh                                                                                                                                                             |
| 408 |      87.68372 |    786.847942 | Tyler Greenfield                                                                                                                                                      |
| 409 |    1008.78172 |    123.887095 | Zimices                                                                                                                                                               |
| 410 |     562.12054 |    643.971617 | Markus A. Grohme                                                                                                                                                      |
| 411 |     722.40743 |    384.873131 | Felix Vaux                                                                                                                                                            |
| 412 |     209.34873 |    190.370061 | Catherine Yasuda                                                                                                                                                      |
| 413 |     423.22499 |    665.318157 | Ferran Sayol                                                                                                                                                          |
| 414 |     782.03797 |    526.079259 | Margot Michaud                                                                                                                                                        |
| 415 |     763.62187 |    384.023699 | FunkMonk                                                                                                                                                              |
| 416 |     121.02024 |     90.016136 | Michael Scroggie                                                                                                                                                      |
| 417 |     801.64250 |    797.068284 | Markus A. Grohme                                                                                                                                                      |
| 418 |     873.03422 |    662.100580 | Matt Crook                                                                                                                                                            |
| 419 |     637.32025 |    495.143468 | Scott Hartman                                                                                                                                                         |
| 420 |     955.67422 |    251.821634 | Ignacio Contreras                                                                                                                                                     |
| 421 |     216.84701 |    322.994167 | T. Michael Keesey (after Marek Velechovský)                                                                                                                           |
| 422 |     489.38277 |    255.009457 | Gareth Monger                                                                                                                                                         |
| 423 |     541.89099 |      7.099663 | NA                                                                                                                                                                    |
| 424 |     900.80485 |    761.412487 | Andy Wilson                                                                                                                                                           |
| 425 |     796.73614 |    413.965509 | Jagged Fang Designs                                                                                                                                                   |
| 426 |     779.02774 |     49.946237 | Scott Hartman                                                                                                                                                         |
| 427 |     422.47191 |    149.998489 | T. Michael Keesey                                                                                                                                                     |
| 428 |     171.17635 |    202.491457 | NA                                                                                                                                                                    |
| 429 |     325.59209 |    557.507168 | FunkMonk (Michael B.H.; vectorized by T. Michael Keesey)                                                                                                              |
| 430 |     398.34938 |    776.282267 | Margot Michaud                                                                                                                                                        |
| 431 |     733.82361 |    752.166214 | Gareth Monger                                                                                                                                                         |
| 432 |     137.43975 |    670.431704 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                                 |
| 433 |     956.96929 |    332.291542 | Matt Crook                                                                                                                                                            |
| 434 |      31.35869 |     58.496394 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 435 |     545.35492 |    349.630507 | Julio Garza                                                                                                                                                           |
| 436 |     148.28235 |    529.934789 | Birgit Lang                                                                                                                                                           |
| 437 |     870.80448 |     61.411934 | Katie S. Collins                                                                                                                                                      |
| 438 |     594.16678 |    166.994254 | Margot Michaud                                                                                                                                                        |
| 439 |     808.13112 |    188.783986 | Tasman Dixon                                                                                                                                                          |
| 440 |     608.14994 |     84.319843 | Iain Reid                                                                                                                                                             |
| 441 |     650.22229 |    595.365634 | Christian A. Masnaghetti                                                                                                                                              |
| 442 |     785.20859 |    280.171798 | Andrew A. Farke, shell lines added by Yan Wong                                                                                                                        |
| 443 |     926.01204 |    595.113946 | Kai R. Caspar                                                                                                                                                         |
| 444 |     362.91681 |    586.464306 | NA                                                                                                                                                                    |
| 445 |     280.33121 |    218.010934 | Tasman Dixon                                                                                                                                                          |
| 446 |     484.57558 |    154.906065 | Alex Slavenko                                                                                                                                                         |
| 447 |     103.69731 |    178.646330 | Tony Ayling                                                                                                                                                           |
| 448 |     437.30992 |    612.177190 | Steven Traver                                                                                                                                                         |
| 449 |     601.49899 |    341.461212 | Andy Wilson                                                                                                                                                           |
| 450 |      27.63425 |    473.911714 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 451 |     486.47970 |    785.134610 | Markus A. Grohme                                                                                                                                                      |
| 452 |     760.10374 |    634.144397 | Lily Hughes                                                                                                                                                           |
| 453 |     959.73475 |    143.964206 | Jagged Fang Designs                                                                                                                                                   |
| 454 |     668.13870 |     33.987099 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 455 |     643.61475 |    693.262955 | Peileppe                                                                                                                                                              |
| 456 |     109.78215 |    709.842336 | Margot Michaud                                                                                                                                                        |
| 457 |    1013.89329 |    201.987649 | Ferran Sayol                                                                                                                                                          |
| 458 |     890.35024 |    482.048684 | T. Michael Keesey                                                                                                                                                     |
| 459 |     937.44385 |    790.297012 | Scott Reid                                                                                                                                                            |
| 460 |     998.42519 |    361.250858 | Zimices                                                                                                                                                               |
| 461 |     245.65215 |    569.216307 | Matt Celeskey                                                                                                                                                         |
| 462 |     938.24501 |    345.558758 | Markus A. Grohme                                                                                                                                                      |
| 463 |      18.90254 |    772.682528 | Ignacio Contreras                                                                                                                                                     |
| 464 |     460.10090 |    258.793252 | Markus A. Grohme                                                                                                                                                      |
| 465 |     471.06127 |    712.281725 | Zimices                                                                                                                                                               |
| 466 |     554.27011 |    543.019905 | Ghedoghedo                                                                                                                                                            |
| 467 |     733.52913 |    325.049361 | NA                                                                                                                                                                    |
| 468 |      16.77749 |    156.791293 | Danielle Alba                                                                                                                                                         |
| 469 |     420.28038 |     64.556157 | Sarah Werning                                                                                                                                                         |
| 470 |     783.67626 |    167.344989 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 471 |    1007.46756 |    274.373950 | Scott Hartman                                                                                                                                                         |
| 472 |     902.46164 |    247.828012 | Iain Reid                                                                                                                                                             |
| 473 |     978.21282 |    292.901826 | Gareth Monger                                                                                                                                                         |
| 474 |     405.72338 |    605.687289 | Steven Coombs (vectorized by T. Michael Keesey)                                                                                                                       |
| 475 |     481.39167 |    646.444223 | Dexter R. Mardis                                                                                                                                                      |
| 476 |     665.21042 |    117.210910 | Beth Reinke                                                                                                                                                           |
| 477 |    1008.52813 |    754.537189 | Jaime Headden                                                                                                                                                         |
| 478 |     652.98127 |    206.497703 | Margot Michaud                                                                                                                                                        |
| 479 |      85.08506 |    576.746493 | Margot Michaud                                                                                                                                                        |
| 480 |     457.16159 |    192.046806 | Thibaut Brunet                                                                                                                                                        |
| 481 |     727.68554 |    604.210956 | Matt Crook                                                                                                                                                            |
| 482 |     329.00772 |    741.964045 | Rene Martin                                                                                                                                                           |
| 483 |     506.73681 |    535.584356 | Margot Michaud                                                                                                                                                        |
| 484 |     895.15982 |    124.442206 | NA                                                                                                                                                                    |
| 485 |     997.21983 |     11.703518 | Jagged Fang Designs                                                                                                                                                   |
| 486 |     916.16188 |     34.526243 | Caio Bernardes, vectorized by Zimices                                                                                                                                 |
| 487 |     215.74817 |     13.041571 | Gareth Monger                                                                                                                                                         |
| 488 |     960.88922 |     59.718356 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 489 |     459.60516 |    276.995281 | Caleb M. Brown                                                                                                                                                        |
| 490 |     105.79018 |    599.913645 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 491 |     683.08770 |    683.428966 | Katie S. Collins                                                                                                                                                      |
| 492 |     331.43279 |    676.757897 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                                 |
| 493 |      98.45668 |      7.892674 | Chris huh                                                                                                                                                             |
| 494 |     558.73596 |    632.771807 | Markus A. Grohme                                                                                                                                                      |
| 495 |     252.60379 |    630.462162 | Scott Hartman                                                                                                                                                         |
| 496 |     756.92753 |    394.118015 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 497 |     823.05636 |    584.979781 | Mathew Wedel                                                                                                                                                          |
| 498 |     682.31793 |    440.377100 | Tasman Dixon                                                                                                                                                          |
| 499 |     963.25336 |    783.609742 | Scott Hartman (modified by T. Michael Keesey)                                                                                                                         |
| 500 |     452.06428 |    647.763701 | Lukasiniho                                                                                                                                                            |
| 501 |     214.63178 |    585.391931 | Jagged Fang Designs                                                                                                                                                   |
| 502 |     437.48402 |    359.542687 | (unknown)                                                                                                                                                             |
| 503 |     380.57483 |    234.777300 | LeonardoG (photography) and T. Michael Keesey (vectorization)                                                                                                         |
| 504 |      12.69813 |    353.867334 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                      |
| 505 |     435.18793 |    105.737397 | Tasman Dixon                                                                                                                                                          |
| 506 |     566.56874 |     63.663253 | Michael Scroggie, from original photograph by Gary M. Stolz, USFWS (original photograph in public domain).                                                            |
| 507 |     883.03032 |    396.239335 | Birgit Lang                                                                                                                                                           |
| 508 |      56.31494 |    309.370700 | Markus A. Grohme                                                                                                                                                      |
| 509 |     680.51548 |    518.582507 | Gareth Monger                                                                                                                                                         |
| 510 |     128.92606 |    299.970149 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 511 |     951.09539 |    670.318657 | Scott Hartman                                                                                                                                                         |
| 512 |     740.00332 |     80.390524 | Scott Hartman                                                                                                                                                         |
| 513 |     133.65908 |    435.538870 | Rene Martin                                                                                                                                                           |
| 514 |     297.90271 |    439.083862 | Chris huh                                                                                                                                                             |
| 515 |     455.70919 |    788.693853 | Jagged Fang Designs                                                                                                                                                   |
| 516 |     486.18545 |    346.898545 | Milton Tan                                                                                                                                                            |
| 517 |     757.11567 |    792.112301 | Iain Reid                                                                                                                                                             |
| 518 |     930.05721 |    256.149502 | Scott Hartman                                                                                                                                                         |
| 519 |     247.01681 |    160.591289 | Chloé Schmidt                                                                                                                                                         |
| 520 |     362.11736 |    748.689220 | Jack Mayer Wood                                                                                                                                                       |
| 521 |     586.76438 |    378.525350 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                        |
| 522 |     902.80525 |    348.227242 | Scott Hartman                                                                                                                                                         |
| 523 |     872.87957 |    318.663241 | Zimices                                                                                                                                                               |
| 524 |      18.53190 |    209.986403 | NA                                                                                                                                                                    |
| 525 |     319.86275 |    222.941763 | Maija Karala                                                                                                                                                          |
| 526 |     928.52501 |    554.038770 | Felix Vaux                                                                                                                                                            |
| 527 |     309.89567 |    795.704358 | Ignacio Contreras                                                                                                                                                     |
| 528 |     912.55394 |    672.086496 | Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey)                                                                                                      |
| 529 |     545.98015 |    217.976939 | CNZdenek                                                                                                                                                              |
| 530 |      21.51363 |     42.157794 | Jagged Fang Designs                                                                                                                                                   |
| 531 |     693.56126 |    765.760567 | Gareth Monger                                                                                                                                                         |
| 532 |     848.02276 |    222.554234 | Margot Michaud                                                                                                                                                        |

    #> Your tweet has been posted!
