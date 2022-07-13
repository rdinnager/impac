
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

Ferran Sayol, Zimices, Nobu Tamura, vectorized by Zimices, Tasman Dixon,
Noah Schlottman, photo from Moorea Biocode, Matthew E. Clapham, L.
Shyamal, Gabriela Palomo-Munoz, , Steven Traver, Didier Descouens
(vectorized by T. Michael Keesey), Andy Wilson, Matt Crook, Nancy Wyman
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Natasha Vitek, kreidefossilien.de, Mason McNair, T. Tischler,
Bennet McComish, photo by Avenue, Melissa Broussard, Nobu Tamura
(vectorized by T. Michael Keesey), Jaime Headden, Margot Michaud,
Auckland Museum, Maija Karala, Zachary Quigley, Birgit Lang, Pete
Buchholz, Mathilde Cordellier, Tyler Greenfield and Dean Schnabel,
Alexander Schmidt-Lebuhn, Courtney Rockenbach, T. Michael Keesey, Mike
Hanson, Scott Hartman, xgirouxb, Nobu Tamura, Jagged Fang Designs,
Ignacio Contreras, Beth Reinke, Smokeybjb, Jessica Rick, Dmitry Bogdanov
(vectorized by T. Michael Keesey), Derek Bakken (photograph) and T.
Michael Keesey (vectorization), Conty (vectorized by T. Michael Keesey),
Ingo Braasch, Caleb M. Brown, Trond R. Oskars, Michelle Site, Tony
Ayling (vectorized by Milton Tan), Becky Barnes, Gareth Monger, Jennifer
Trimble, Tauana J. Cunha, John Gould (vectorized by T. Michael Keesey),
Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley
(silhouette), Jose Carlos Arenas-Monroy, Christoph Schomburg, Emily
Willoughby, Daniel Stadtmauer, Harold N Eyster, Chris huh, Erika
Schumacher, Henry Fairfield Osborn, vectorized by Zimices, Carlos
Cano-Barbacil, Matt Celeskey, Christine Axon, Sidney Frederic Harmer,
Arthur Everett Shipley (vectorized by Maxime Dahirel), Sharon
Wegner-Larsen, David Orr, Joanna Wolfe, Mathieu Basille, Nina Skinner,
Markus A. Grohme, Taenadoman, SecretJellyMan, U.S. Fish and Wildlife
Service (illustration) and Timothy J. Bartley (silhouette), Smokeybjb
(vectorized by T. Michael Keesey), Yan Wong, Mario Quevedo, FunkMonk,
Martin R. Smith, Rebecca Groom (Based on Photo by Andreas Trepte),
Rainer Schoch, Verdilak, Javiera Constanzo, Iain Reid,
Archaeodontosaurus (vectorized by T. Michael Keesey), Michael Scroggie,
Tony Ayling, Kamil S. Jaron, Anthony Caravaggi, Apokryltaros (vectorized
by T. Michael Keesey), Sarah Werning, Liftarn, Wayne Decatur, T. Michael
Keesey (from a mount by Allis Markham), Cristopher Silva, Scott Reid,
Peter Coxhead, Yan Wong from drawing by Joseph Smit, Mareike C. Janiak,
Armin Reindl, Don Armstrong, Frank Förster (based on a picture by Hans
Hillewaert), Christina N. Hodson, Julien Louys, Alexandre Vong, Raven
Amos, Tyler Greenfield, C. Camilo Julián-Caballero, Stanton F. Fink
(vectorized by T. Michael Keesey), Robbie N. Cada (vectorized by T.
Michael Keesey), Mathew Wedel, Andrew Farke and Joseph Sertich, Chuanixn
Yu, Mali’o Kodis, photograph from Jersabek et al, 2003, Katie S.
Collins, Rafael Maia, Original drawing by Dmitry Bogdanov, vectorized by
Roberto Díaz Sibaja, Lafage, Ville-Veikko Sinkkonen, T. Michael Keesey
(after Heinrich Harder), Ghedoghedo (vectorized by T. Michael Keesey),
Ray Simpson (vectorized by T. Michael Keesey), Noah Schlottman, Jack
Mayer Wood, CNZdenek, T. Michael Keesey (from a photograph by Frank
Glaw, Jörn Köhler, Ted M. Townsend & Miguel Vences), T. Michael Keesey
(after Mauricio Antón), Karla Martinez, Christian A. Masnaghetti, Xavier
Giroux-Bougard, Douglas Brown (modified by T. Michael Keesey), Matt
Dempsey, Dmitry Bogdanov, Jan A. Venter, Herbert H. T. Prins, David A.
Balfour & Rob Slotow (vectorized by T. Michael Keesey), David Sim
(photograph) and T. Michael Keesey (vectorization), Andrew A. Farke,
Kailah Thorn & Mark Hutchinson, Yan Wong from illustration by Charles
Orbigny, Daniel Jaron, Dave Souza (vectorized by T. Michael Keesey),
Matthew Hooge (vectorized by T. Michael Keesey), Samanta Orellana,
Steven Coombs, Mihai Dragos (vectorized by T. Michael Keesey), Dianne
Bray / Museum Victoria (vectorized by T. Michael Keesey), Fcb981
(vectorized by T. Michael Keesey), Bruno Maggia, Agnello Picorelli, T.
Michael Keesey (after Walker & al.), Meyers Konversations-Lexikon 1897
(vectorized: Yan Wong), Kimberly Haddrell, Tyler McCraney, Mattia
Menchetti, Felix Vaux, Terpsichores, Rachel Shoop, NASA, Cesar Julian,
Alyssa Bell & Luis Chiappe 2015,
dx.doi.org/10.1371/journal.pone.0141690, Chris A. Hamilton, Kristina
Gagalova, Mali’o Kodis, image from Higgins and Kristensen, 1986, Noah
Schlottman, photo from Casey Dunn, Greg Schechter (original photo),
Renato Santos (vector silhouette), Collin Gross, Manabu Bessho-Uehara,
S.Martini, Original drawing by Nobu Tamura, vectorized by Roberto Díaz
Sibaja, Michele Tobias, Eduard Solà (vectorized by T. Michael Keesey),
Scarlet23 (vectorized by T. Michael Keesey), ДиБгд (vectorized by T.
Michael Keesey), Zimices / Julián Bayona, Obsidian Soul (vectorized by
T. Michael Keesey), Jaime Chirinos (vectorized by T. Michael Keesey),
Oren Peles / vectorized by Yan Wong, Matt Martyniuk (vectorized by T.
Michael Keesey), Duane Raver/USFWS

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                      |
| --: | ------------: | ------------: | :---------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    881.180184 |    495.787611 | Ferran Sayol                                                                                                                                                |
|   2 |    413.919870 |    321.880431 | Zimices                                                                                                                                                     |
|   3 |    341.901046 |    615.656541 | Nobu Tamura, vectorized by Zimices                                                                                                                          |
|   4 |    882.544462 |    644.683321 | NA                                                                                                                                                          |
|   5 |    853.733011 |     39.313638 | Tasman Dixon                                                                                                                                                |
|   6 |    350.748038 |    488.560992 | Noah Schlottman, photo from Moorea Biocode                                                                                                                  |
|   7 |    656.139613 |    457.137611 | Matthew E. Clapham                                                                                                                                          |
|   8 |    239.770226 |    150.188126 | L. Shyamal                                                                                                                                                  |
|   9 |    873.721300 |    404.973833 | Gabriela Palomo-Munoz                                                                                                                                       |
|  10 |    673.566526 |    344.887819 |                                                                                                                                                             |
|  11 |    227.838831 |    399.347515 | Steven Traver                                                                                                                                               |
|  12 |    630.416961 |    682.418211 | Ferran Sayol                                                                                                                                                |
|  13 |    715.379962 |     95.899298 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                          |
|  14 |    480.723783 |    212.380912 | Andy Wilson                                                                                                                                                 |
|  15 |    492.412037 |    448.269448 | Matt Crook                                                                                                                                                  |
|  16 |    953.982565 |    207.069695 | Nancy Wyman (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
|  17 |     97.473934 |    397.845978 | Natasha Vitek                                                                                                                                               |
|  18 |    774.308626 |    263.803934 | kreidefossilien.de                                                                                                                                          |
|  19 |    451.124549 |     69.271240 | Mason McNair                                                                                                                                                |
|  20 |    209.079527 |    295.327720 | Steven Traver                                                                                                                                               |
|  21 |    835.438682 |    167.499190 | T. Tischler                                                                                                                                                 |
|  22 |    484.468821 |    678.689273 | Bennet McComish, photo by Avenue                                                                                                                            |
|  23 |    123.711047 |    119.634578 | Melissa Broussard                                                                                                                                           |
|  24 |    235.105810 |    498.106795 | Matt Crook                                                                                                                                                  |
|  25 |    402.540889 |    178.857853 | Ferran Sayol                                                                                                                                                |
|  26 |    558.991995 |    741.508586 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                               |
|  27 |    434.394907 |    384.259268 | Jaime Headden                                                                                                                                               |
|  28 |    774.963604 |    673.932915 | NA                                                                                                                                                          |
|  29 |    252.076501 |    711.079655 | Margot Michaud                                                                                                                                              |
|  30 |     93.412774 |    658.341151 | Auckland Museum                                                                                                                                             |
|  31 |    625.442909 |    161.435356 | Zimices                                                                                                                                                     |
|  32 |    572.742875 |    291.714218 | Steven Traver                                                                                                                                               |
|  33 |    105.001975 |     76.579497 | Maija Karala                                                                                                                                                |
|  34 |    794.839593 |    569.050838 | Zachary Quigley                                                                                                                                             |
|  35 |    309.938373 |    514.234054 | Birgit Lang                                                                                                                                                 |
|  36 |    137.434814 |    534.634111 | Pete Buchholz                                                                                                                                               |
|  37 |    958.161540 |    726.839409 | Mathilde Cordellier                                                                                                                                         |
|  38 |    766.639910 |    369.496681 | NA                                                                                                                                                          |
|  39 |    391.031469 |    727.751899 | Tyler Greenfield and Dean Schnabel                                                                                                                          |
|  40 |    122.598246 |    238.058788 | Alexander Schmidt-Lebuhn                                                                                                                                    |
|  41 |     64.090283 |    467.645917 | Birgit Lang                                                                                                                                                 |
|  42 |    690.124018 |    215.375130 | Ferran Sayol                                                                                                                                                |
|  43 |    602.751243 |     45.112103 | Courtney Rockenbach                                                                                                                                         |
|  44 |     48.071439 |    525.812573 | T. Michael Keesey                                                                                                                                           |
|  45 |     59.753882 |    273.380521 | Mike Hanson                                                                                                                                                 |
|  46 |    949.526157 |    298.684528 | Matt Crook                                                                                                                                                  |
|  47 |    857.736640 |     77.824599 | Scott Hartman                                                                                                                                               |
|  48 |    783.944414 |    719.151690 | Ferran Sayol                                                                                                                                                |
|  49 |    226.955434 |     42.495191 | Steven Traver                                                                                                                                               |
|  50 |    630.733499 |    581.018917 | T. Michael Keesey                                                                                                                                           |
|  51 |    566.109726 |     93.797165 | xgirouxb                                                                                                                                                    |
|  52 |    503.474933 |    537.538605 | Nobu Tamura                                                                                                                                                 |
|  53 |    185.345040 |    769.956503 | Jagged Fang Designs                                                                                                                                         |
|  54 |    956.344814 |     17.189561 | Ignacio Contreras                                                                                                                                           |
|  55 |     94.250258 |     38.576941 | Beth Reinke                                                                                                                                                 |
|  56 |    864.335347 |    132.781828 | Smokeybjb                                                                                                                                                   |
|  57 |    481.720823 |    777.458931 | Steven Traver                                                                                                                                               |
|  58 |    309.282910 |    778.090898 | Jagged Fang Designs                                                                                                                                         |
|  59 |    825.537170 |    529.361403 | Jagged Fang Designs                                                                                                                                         |
|  60 |    898.598513 |    110.935757 | Jessica Rick                                                                                                                                                |
|  61 |    223.083829 |    239.889157 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                           |
|  62 |    328.854688 |    379.728276 | Steven Traver                                                                                                                                               |
|  63 |    963.191712 |    345.186208 | Ignacio Contreras                                                                                                                                           |
|  64 |    118.293301 |    738.292190 | Smokeybjb                                                                                                                                                   |
|  65 |     26.773116 |    126.362707 | Margot Michaud                                                                                                                                              |
|  66 |    418.359858 |    100.399822 | Derek Bakken (photograph) and T. Michael Keesey (vectorization)                                                                                             |
|  67 |    335.377354 |    292.443599 | Conty (vectorized by T. Michael Keesey)                                                                                                                     |
|  68 |    681.446047 |    756.968250 | Ingo Braasch                                                                                                                                                |
|  69 |    509.593305 |    628.685331 | Caleb M. Brown                                                                                                                                              |
|  70 |    727.708423 |    171.167272 | Margot Michaud                                                                                                                                              |
|  71 |    869.262552 |    301.055479 | Trond R. Oskars                                                                                                                                             |
|  72 |    974.704330 |    599.527312 | Michelle Site                                                                                                                                               |
|  73 |     79.287387 |    344.876808 | Scott Hartman                                                                                                                                               |
|  74 |    721.673816 |     21.070807 | Tony Ayling (vectorized by Milton Tan)                                                                                                                      |
|  75 |    321.725549 |     69.887626 | Nancy Wyman (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
|  76 |     98.255156 |    607.474145 | T. Michael Keesey                                                                                                                                           |
|  77 |    978.101189 |    520.937533 | Becky Barnes                                                                                                                                                |
|  78 |    958.886368 |     61.334810 | Matt Crook                                                                                                                                                  |
|  79 |    566.850161 |    178.803061 | Tasman Dixon                                                                                                                                                |
|  80 |    272.488380 |    553.501841 | Scott Hartman                                                                                                                                               |
|  81 |     12.288171 |    275.386311 | Gareth Monger                                                                                                                                               |
|  82 |    685.151540 |    269.349452 | Zimices                                                                                                                                                     |
|  83 |    975.161767 |    403.652884 | Jennifer Trimble                                                                                                                                            |
|  84 |    726.876401 |    722.580221 | Tauana J. Cunha                                                                                                                                             |
|  85 |    809.599434 |    340.825494 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                               |
|  86 |     38.871311 |    721.913150 | John Gould (vectorized by T. Michael Keesey)                                                                                                                |
|  87 |    532.854706 |    464.313125 | Zimices                                                                                                                                                     |
|  88 |    518.620395 |    379.292335 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                           |
|  89 |    902.840633 |    754.252167 | Jose Carlos Arenas-Monroy                                                                                                                                   |
|  90 |    143.611316 |    490.925814 | Gareth Monger                                                                                                                                               |
|  91 |    557.313890 |    635.321079 | Gareth Monger                                                                                                                                               |
|  92 |    684.730563 |    297.528091 | Margot Michaud                                                                                                                                              |
|  93 |    845.131967 |    208.044843 | Zimices                                                                                                                                                     |
|  94 |    410.138688 |    455.845477 | Christoph Schomburg                                                                                                                                         |
|  95 |    417.548926 |    246.054518 | Gareth Monger                                                                                                                                               |
|  96 |    497.908574 |    365.210162 | Jagged Fang Designs                                                                                                                                         |
|  97 |    490.720323 |    295.180586 | T. Michael Keesey                                                                                                                                           |
|  98 |    765.697270 |    600.507743 | Scott Hartman                                                                                                                                               |
|  99 |    528.653402 |     26.416276 | Emily Willoughby                                                                                                                                            |
| 100 |    736.517140 |    779.505586 | Daniel Stadtmauer                                                                                                                                           |
| 101 |    537.494066 |    235.186195 | Harold N Eyster                                                                                                                                             |
| 102 |    483.233677 |    473.911382 | Chris huh                                                                                                                                                   |
| 103 |     55.621533 |    776.525594 | Erika Schumacher                                                                                                                                            |
| 104 |    788.936335 |    421.538928 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                               |
| 105 |    582.376471 |    353.698308 | Carlos Cano-Barbacil                                                                                                                                        |
| 106 |    576.403611 |    238.774599 | Margot Michaud                                                                                                                                              |
| 107 |    176.661313 |    716.631584 | Steven Traver                                                                                                                                               |
| 108 |    477.618298 |    714.663034 | Chris huh                                                                                                                                                   |
| 109 |    809.632613 |    105.080185 | Steven Traver                                                                                                                                               |
| 110 |    180.392279 |    656.993234 | Steven Traver                                                                                                                                               |
| 111 |    899.852492 |    354.855792 | Matt Celeskey                                                                                                                                               |
| 112 |    133.396142 |    614.111954 | Matt Crook                                                                                                                                                  |
| 113 |    397.677330 |    490.041744 | Gabriela Palomo-Munoz                                                                                                                                       |
| 114 |    855.266667 |    716.912122 | Christoph Schomburg                                                                                                                                         |
| 115 |    470.439240 |    741.364279 | Christine Axon                                                                                                                                              |
| 116 |    523.595810 |     58.374359 | Sidney Frederic Harmer, Arthur Everett Shipley (vectorized by Maxime Dahirel)                                                                               |
| 117 |    392.006060 |     25.607561 | Steven Traver                                                                                                                                               |
| 118 |   1003.985495 |    467.438904 | Sharon Wegner-Larsen                                                                                                                                        |
| 119 |    769.567965 |    128.178686 | Matt Crook                                                                                                                                                  |
| 120 |    520.865289 |    334.784778 | Chris huh                                                                                                                                                   |
| 121 |    914.090100 |    571.672220 | Alexander Schmidt-Lebuhn                                                                                                                                    |
| 122 |    267.744427 |    362.512057 | Gareth Monger                                                                                                                                               |
| 123 |    992.284055 |     85.874365 | Alexander Schmidt-Lebuhn                                                                                                                                    |
| 124 |     59.499751 |    692.518956 | Gareth Monger                                                                                                                                               |
| 125 |    880.467122 |    156.627746 | Steven Traver                                                                                                                                               |
| 126 |    338.072047 |    693.801332 | David Orr                                                                                                                                                   |
| 127 |    949.834887 |    578.636332 | T. Michael Keesey                                                                                                                                           |
| 128 |    978.065030 |    236.402090 | Joanna Wolfe                                                                                                                                                |
| 129 |    561.164796 |    546.407872 | Steven Traver                                                                                                                                               |
| 130 |    323.041030 |    390.621515 | Emily Willoughby                                                                                                                                            |
| 131 |     72.510204 |     26.428488 | Smokeybjb                                                                                                                                                   |
| 132 |    886.963800 |    452.691784 | Mathieu Basille                                                                                                                                             |
| 133 |    673.241267 |    119.634655 | Steven Traver                                                                                                                                               |
| 134 |    994.089709 |    218.411696 | NA                                                                                                                                                          |
| 135 |    561.769627 |     10.606005 | Jagged Fang Designs                                                                                                                                         |
| 136 |    182.240420 |    506.101312 | Nina Skinner                                                                                                                                                |
| 137 |    923.763109 |    150.615951 | Matt Crook                                                                                                                                                  |
| 138 |    899.952934 |     70.389571 | Smokeybjb                                                                                                                                                   |
| 139 |    371.149964 |    540.334211 | NA                                                                                                                                                          |
| 140 |    848.274421 |    749.377443 | Markus A. Grohme                                                                                                                                            |
| 141 |    687.079143 |    250.710912 | Michelle Site                                                                                                                                               |
| 142 |     64.154432 |    325.801454 | Zimices                                                                                                                                                     |
| 143 |     92.616026 |     12.415737 | Margot Michaud                                                                                                                                              |
| 144 |    328.566315 |    199.317985 | Chris huh                                                                                                                                                   |
| 145 |    431.859103 |    365.242935 | NA                                                                                                                                                          |
| 146 |     19.899516 |    636.207645 | Ferran Sayol                                                                                                                                                |
| 147 |    743.301757 |    523.913221 | T. Michael Keesey                                                                                                                                           |
| 148 |    342.700407 |    750.792736 | Ferran Sayol                                                                                                                                                |
| 149 |    439.751199 |    461.445245 | Christoph Schomburg                                                                                                                                         |
| 150 |    447.443855 |    284.953955 | Becky Barnes                                                                                                                                                |
| 151 |    828.023448 |    787.280425 | Taenadoman                                                                                                                                                  |
| 152 |      7.709858 |    741.246553 | SecretJellyMan                                                                                                                                              |
| 153 |    578.547876 |    780.888520 | Gabriela Palomo-Munoz                                                                                                                                       |
| 154 |    852.299083 |    466.689070 | Matt Crook                                                                                                                                                  |
| 155 |    222.825230 |    329.875965 | Margot Michaud                                                                                                                                              |
| 156 |    890.577359 |     56.133336 | U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                           |
| 157 |    575.710967 |    677.488968 | Jagged Fang Designs                                                                                                                                         |
| 158 |    583.128504 |    701.980921 | Gareth Monger                                                                                                                                               |
| 159 |    773.134658 |    445.984087 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                 |
| 160 |    419.406889 |    549.638183 | Chris huh                                                                                                                                                   |
| 161 |    243.714075 |    747.345293 | Matt Crook                                                                                                                                                  |
| 162 |    711.343343 |    649.600180 | Yan Wong                                                                                                                                                    |
| 163 |    940.241034 |    361.438126 | Scott Hartman                                                                                                                                               |
| 164 |    684.788297 |    648.971316 | Mario Quevedo                                                                                                                                               |
| 165 |    548.617016 |    573.319125 | Gabriela Palomo-Munoz                                                                                                                                       |
| 166 |    825.279880 |    604.874519 | Matt Crook                                                                                                                                                  |
| 167 |     24.125318 |    231.846172 | Steven Traver                                                                                                                                               |
| 168 |    564.487112 |    143.753095 | FunkMonk                                                                                                                                                    |
| 169 |    368.938231 |     53.292318 | Martin R. Smith                                                                                                                                             |
| 170 |    324.113393 |    455.084685 | Rebecca Groom (Based on Photo by Andreas Trepte)                                                                                                            |
| 171 |    941.601449 |     38.090939 | NA                                                                                                                                                          |
| 172 |    454.742154 |    409.665629 | Steven Traver                                                                                                                                               |
| 173 |    579.510052 |    527.537551 | Rainer Schoch                                                                                                                                               |
| 174 |    327.378229 |    220.687711 | Chris huh                                                                                                                                                   |
| 175 |    476.906684 |    147.084224 | Matt Crook                                                                                                                                                  |
| 176 |    434.544754 |    511.331428 | kreidefossilien.de                                                                                                                                          |
| 177 |    210.768879 |    347.116979 | Andy Wilson                                                                                                                                                 |
| 178 |    782.034023 |     45.363038 | Martin R. Smith                                                                                                                                             |
| 179 |    232.793809 |    346.293656 | NA                                                                                                                                                          |
| 180 |    158.967431 |    372.723845 | Verdilak                                                                                                                                                    |
| 181 |    741.653898 |    326.455341 | Zimices                                                                                                                                                     |
| 182 |    509.676749 |    144.861671 | Javiera Constanzo                                                                                                                                           |
| 183 |    906.115044 |    777.523713 | Melissa Broussard                                                                                                                                           |
| 184 |    204.338808 |    640.006913 | Becky Barnes                                                                                                                                                |
| 185 |     22.091279 |    370.691376 | NA                                                                                                                                                          |
| 186 |     50.826932 |    669.653810 | Iain Reid                                                                                                                                                   |
| 187 |    521.890753 |    117.001206 | Sharon Wegner-Larsen                                                                                                                                        |
| 188 |    183.989983 |    433.516762 | Ignacio Contreras                                                                                                                                           |
| 189 |    771.752882 |    471.848609 | Chris huh                                                                                                                                                   |
| 190 |    255.617820 |    220.547677 | Steven Traver                                                                                                                                               |
| 191 |    609.887687 |    769.589323 | Archaeodontosaurus (vectorized by T. Michael Keesey)                                                                                                        |
| 192 |   1004.905268 |    742.907391 | Caleb M. Brown                                                                                                                                              |
| 193 |    992.989564 |    649.735052 | Tasman Dixon                                                                                                                                                |
| 194 |    171.425568 |    329.876523 | Ferran Sayol                                                                                                                                                |
| 195 |    426.700657 |    622.003395 | Matt Crook                                                                                                                                                  |
| 196 |    642.143860 |     57.951401 | Michael Scroggie                                                                                                                                            |
| 197 |    312.220673 |    185.702617 | Tony Ayling                                                                                                                                                 |
| 198 |    329.516289 |    412.095224 | Emily Willoughby                                                                                                                                            |
| 199 |    264.449669 |     98.805691 | Kamil S. Jaron                                                                                                                                              |
| 200 |    306.696203 |    540.106870 | Tasman Dixon                                                                                                                                                |
| 201 |    718.565690 |    588.443084 | Anthony Caravaggi                                                                                                                                           |
| 202 |     70.709345 |    159.227018 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                              |
| 203 |    718.018542 |    549.127493 | Sarah Werning                                                                                                                                               |
| 204 |    594.620124 |    392.222607 | Scott Hartman                                                                                                                                               |
| 205 |    102.090066 |    774.227294 | Liftarn                                                                                                                                                     |
| 206 |    893.928723 |    229.674110 | NA                                                                                                                                                          |
| 207 |    786.845429 |    171.139804 | Gareth Monger                                                                                                                                               |
| 208 |     20.002129 |    196.575656 | Gareth Monger                                                                                                                                               |
| 209 |    498.913256 |    407.885221 | Christoph Schomburg                                                                                                                                         |
| 210 |    817.872222 |    530.764415 | Gabriela Palomo-Munoz                                                                                                                                       |
| 211 |     20.986306 |    673.152188 | Gareth Monger                                                                                                                                               |
| 212 |    791.860264 |    685.767327 | Ferran Sayol                                                                                                                                                |
| 213 |    227.578543 |    564.084671 | Zimices                                                                                                                                                     |
| 214 |   1003.054235 |    372.098582 | Wayne Decatur                                                                                                                                               |
| 215 |    904.990892 |    715.922605 | Carlos Cano-Barbacil                                                                                                                                        |
| 216 |    583.181611 |    320.144960 | T. Michael Keesey (from a mount by Allis Markham)                                                                                                           |
| 217 |    830.298306 |    641.641440 | FunkMonk                                                                                                                                                    |
| 218 |    161.229437 |    579.476613 | Chris huh                                                                                                                                                   |
| 219 |    496.777242 |    430.507784 | Chris huh                                                                                                                                                   |
| 220 |    636.061473 |    251.616753 | Jagged Fang Designs                                                                                                                                         |
| 221 |    217.861956 |    434.819631 | Cristopher Silva                                                                                                                                            |
| 222 |    590.655167 |    617.225073 | Matt Crook                                                                                                                                                  |
| 223 |    800.035305 |     11.928520 | Scott Reid                                                                                                                                                  |
| 224 |     19.918190 |     11.327044 | Zimices                                                                                                                                                     |
| 225 |    817.141897 |    449.153427 | Steven Traver                                                                                                                                               |
| 226 |    717.745959 |    529.496276 | Steven Traver                                                                                                                                               |
| 227 |    949.257804 |    428.385992 | Zimices                                                                                                                                                     |
| 228 |    811.119791 |     84.245235 | Jagged Fang Designs                                                                                                                                         |
| 229 |    193.924741 |    745.794504 | Steven Traver                                                                                                                                               |
| 230 |    441.404410 |    199.984982 | L. Shyamal                                                                                                                                                  |
| 231 |     11.860404 |    537.773153 | T. Michael Keesey                                                                                                                                           |
| 232 |    671.931807 |    326.929110 | Steven Traver                                                                                                                                               |
| 233 |     76.444250 |    200.759440 | Matt Crook                                                                                                                                                  |
| 234 |    138.823883 |    787.264650 | Markus A. Grohme                                                                                                                                            |
| 235 |    665.986998 |     10.584597 | Chris huh                                                                                                                                                   |
| 236 |    944.805144 |    273.058599 | Chris huh                                                                                                                                                   |
| 237 |    127.730298 |    707.074008 | L. Shyamal                                                                                                                                                  |
| 238 |     22.886132 |    607.561467 | Peter Coxhead                                                                                                                                               |
| 239 |    314.861418 |    132.180838 | Ferran Sayol                                                                                                                                                |
| 240 |    759.891362 |    197.130166 | Zimices                                                                                                                                                     |
| 241 |    573.660838 |    599.336734 | Scott Hartman                                                                                                                                               |
| 242 |    241.131754 |     61.809409 | Michelle Site                                                                                                                                               |
| 243 |    576.799039 |    212.942880 | Yan Wong from drawing by Joseph Smit                                                                                                                        |
| 244 |    762.991460 |    149.915889 | Mareike C. Janiak                                                                                                                                           |
| 245 |    980.887983 |    473.465005 | Tauana J. Cunha                                                                                                                                             |
| 246 |    806.658226 |    469.954857 | Scott Hartman                                                                                                                                               |
| 247 |    278.980451 |    760.655948 | Gabriela Palomo-Munoz                                                                                                                                       |
| 248 |    483.706221 |     90.154204 | Margot Michaud                                                                                                                                              |
| 249 |    295.344994 |    263.313239 | Gabriela Palomo-Munoz                                                                                                                                       |
| 250 |   1011.550093 |     43.420849 | Armin Reindl                                                                                                                                                |
| 251 |    372.254699 |    654.482335 | Don Armstrong                                                                                                                                               |
| 252 |    376.793807 |    349.688630 | Frank Förster (based on a picture by Hans Hillewaert)                                                                                                       |
| 253 |   1001.071929 |    781.290056 | NA                                                                                                                                                          |
| 254 |    706.687735 |    700.050098 | Christina N. Hodson                                                                                                                                         |
| 255 |    994.564066 |    683.489500 | Julien Louys                                                                                                                                                |
| 256 |    530.713120 |    211.207740 | Alexandre Vong                                                                                                                                              |
| 257 |    468.839570 |    266.218734 | Carlos Cano-Barbacil                                                                                                                                        |
| 258 |    160.602921 |    449.727073 | Carlos Cano-Barbacil                                                                                                                                        |
| 259 |    880.650103 |    565.419623 | Zimices                                                                                                                                                     |
| 260 |    898.818831 |     11.211511 | Raven Amos                                                                                                                                                  |
| 261 |    180.831941 |    442.588748 | Tyler Greenfield                                                                                                                                            |
| 262 |    483.701642 |    420.464655 | C. Camilo Julián-Caballero                                                                                                                                  |
| 263 |    489.400579 |    332.642759 | Jagged Fang Designs                                                                                                                                         |
| 264 |    550.234522 |    770.703382 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                           |
| 265 |     67.772372 |    525.398790 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                            |
| 266 |    223.455149 |    373.183986 | Mathew Wedel                                                                                                                                                |
| 267 |    320.702374 |    650.737703 | Andrew Farke and Joseph Sertich                                                                                                                             |
| 268 |    964.742234 |    316.513395 | Margot Michaud                                                                                                                                              |
| 269 |    301.794609 |    422.340930 | Chuanixn Yu                                                                                                                                                 |
| 270 |    936.124838 |     54.857950 | Birgit Lang                                                                                                                                                 |
| 271 |    529.214564 |    651.990013 | Jagged Fang Designs                                                                                                                                         |
| 272 |    226.537032 |    212.604617 | Beth Reinke                                                                                                                                                 |
| 273 |     63.825106 |    421.271872 | Zachary Quigley                                                                                                                                             |
| 274 |     11.957355 |    702.589785 | Mali’o Kodis, photograph from Jersabek et al, 2003                                                                                                          |
| 275 |    221.175657 |    552.757232 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                           |
| 276 |    881.075889 |     92.188115 | Michael Scroggie                                                                                                                                            |
| 277 |    643.581124 |    121.624152 | Katie S. Collins                                                                                                                                            |
| 278 |    817.441693 |    365.307741 | NA                                                                                                                                                          |
| 279 |     43.385110 |     17.351634 | Zimices                                                                                                                                                     |
| 280 |    554.843857 |    710.122061 | T. Michael Keesey                                                                                                                                           |
| 281 |    537.711034 |    584.300030 | Rafael Maia                                                                                                                                                 |
| 282 |    308.506233 |    684.378925 | Jaime Headden                                                                                                                                               |
| 283 |    832.874186 |    240.714186 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                      |
| 284 |    262.103674 |    430.173610 | Lafage                                                                                                                                                      |
| 285 |    167.389461 |    688.137193 | Margot Michaud                                                                                                                                              |
| 286 |    504.971667 |     65.138928 | Ville-Veikko Sinkkonen                                                                                                                                      |
| 287 |    186.318056 |    368.968742 | Matt Crook                                                                                                                                                  |
| 288 |    494.399149 |    346.954791 | T. Michael Keesey (after Heinrich Harder)                                                                                                                   |
| 289 |    859.130009 |    735.305596 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                |
| 290 |    963.985257 |     99.571512 | Steven Traver                                                                                                                                               |
| 291 |    936.598059 |    788.198182 | Ferran Sayol                                                                                                                                                |
| 292 |    691.435245 |    544.333095 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                           |
| 293 |    284.454757 |     10.582471 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                          |
| 294 |    501.311037 |    739.510554 | Jagged Fang Designs                                                                                                                                         |
| 295 |    261.911127 |    261.850777 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                           |
| 296 |    485.043065 |      9.310154 | Jagged Fang Designs                                                                                                                                         |
| 297 |    342.064585 |    717.259349 | C. Camilo Julián-Caballero                                                                                                                                  |
| 298 |    107.471970 |    790.174841 | Margot Michaud                                                                                                                                              |
| 299 |    420.489216 |     12.665617 | Gareth Monger                                                                                                                                               |
| 300 |     61.246920 |    187.107352 | Yan Wong                                                                                                                                                    |
| 301 |    631.208555 |     11.523655 | Ray Simpson (vectorized by T. Michael Keesey)                                                                                                               |
| 302 |    836.135473 |    684.613361 | NA                                                                                                                                                          |
| 303 |    746.011295 |     11.741671 | Conty (vectorized by T. Michael Keesey)                                                                                                                     |
| 304 |    121.583427 |    567.891994 | Noah Schlottman                                                                                                                                             |
| 305 |    494.617179 |    129.902311 | Jack Mayer Wood                                                                                                                                             |
| 306 |    528.111776 |    401.361285 | CNZdenek                                                                                                                                                    |
| 307 |    448.356104 |    704.498212 | Zimices                                                                                                                                                     |
| 308 |    121.918958 |    446.239952 | T. Michael Keesey (from a photograph by Frank Glaw, Jörn Köhler, Ted M. Townsend & Miguel Vences)                                                           |
| 309 |    581.658673 |    639.891506 | Chris huh                                                                                                                                                   |
| 310 |    627.234504 |    239.454081 | Zimices                                                                                                                                                     |
| 311 |    299.214888 |    750.950295 | Gareth Monger                                                                                                                                               |
| 312 |    203.370301 |    788.669189 | Carlos Cano-Barbacil                                                                                                                                        |
| 313 |    888.174194 |    364.197225 | Ignacio Contreras                                                                                                                                           |
| 314 |      8.259195 |    427.508263 | Mike Hanson                                                                                                                                                 |
| 315 |    304.074272 |    310.166885 | T. Michael Keesey (after Mauricio Antón)                                                                                                                    |
| 316 |    427.616920 |    667.822591 | C. Camilo Julián-Caballero                                                                                                                                  |
| 317 |    893.915715 |    735.113409 | xgirouxb                                                                                                                                                    |
| 318 |     62.764201 |    571.223234 | Steven Traver                                                                                                                                               |
| 319 |    374.338970 |     16.609814 | Gareth Monger                                                                                                                                               |
| 320 |    344.517436 |     77.041838 | Karla Martinez                                                                                                                                              |
| 321 |    493.132573 |    570.166108 | Christian A. Masnaghetti                                                                                                                                    |
| 322 |    817.381522 |    508.634392 | Margot Michaud                                                                                                                                              |
| 323 |    429.966273 |    748.985166 | Xavier Giroux-Bougard                                                                                                                                       |
| 324 |   1006.614693 |    437.729546 | Matt Crook                                                                                                                                                  |
| 325 |    999.703211 |    321.569176 | Gabriela Palomo-Munoz                                                                                                                                       |
| 326 |    318.002695 |    733.933352 | Markus A. Grohme                                                                                                                                            |
| 327 |    334.295638 |    318.008278 | NA                                                                                                                                                          |
| 328 |    145.983224 |      9.857919 | Douglas Brown (modified by T. Michael Keesey)                                                                                                               |
| 329 |    961.462196 |    555.465301 | Margot Michaud                                                                                                                                              |
| 330 |    564.453733 |    335.594288 | Matt Dempsey                                                                                                                                                |
| 331 |    608.181691 |    710.636913 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                           |
| 332 |    585.074387 |    371.669294 | Dmitry Bogdanov                                                                                                                                             |
| 333 |     34.988654 |     51.387298 | Nobu Tamura, vectorized by Zimices                                                                                                                          |
| 334 |    945.152126 |    769.959755 | Zimices                                                                                                                                                     |
| 335 |     81.346796 |    720.730827 | Emily Willoughby                                                                                                                                            |
| 336 |    721.779126 |    263.306190 | Birgit Lang                                                                                                                                                 |
| 337 |    487.319935 |    502.087103 | Gareth Monger                                                                                                                                               |
| 338 |    275.738862 |    347.322100 | Jagged Fang Designs                                                                                                                                         |
| 339 |    279.668476 |    292.385158 | Tasman Dixon                                                                                                                                                |
| 340 |    641.086212 |     96.049773 | Margot Michaud                                                                                                                                              |
| 341 |    591.203025 |    544.920052 | Ferran Sayol                                                                                                                                                |
| 342 |    585.539950 |     78.840629 | Gabriela Palomo-Munoz                                                                                                                                       |
| 343 |    104.595629 |    749.967836 | Tony Ayling                                                                                                                                                 |
| 344 |    210.444967 |     54.342003 | Chris huh                                                                                                                                                   |
| 345 |    644.653383 |    782.879772 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                         |
| 346 |    180.300209 |    113.458509 | Zimices                                                                                                                                                     |
| 347 |    306.253337 |    637.533777 | Zimices                                                                                                                                                     |
| 348 |    646.528721 |    301.689367 | David Sim (photograph) and T. Michael Keesey (vectorization)                                                                                                |
| 349 |    800.983129 |    587.250513 | Zimices                                                                                                                                                     |
| 350 |    862.050147 |    179.023477 | Andrew A. Farke                                                                                                                                             |
| 351 |    398.392474 |    500.754603 | Christoph Schomburg                                                                                                                                         |
| 352 |     45.878586 |    587.864809 | Kailah Thorn & Mark Hutchinson                                                                                                                              |
| 353 |    313.831045 |    697.956686 | Zimices                                                                                                                                                     |
| 354 |    615.826180 |    206.681152 | Yan Wong from illustration by Charles Orbigny                                                                                                               |
| 355 |    460.789304 |    493.234650 | Daniel Jaron                                                                                                                                                |
| 356 |    932.747069 |    405.382605 | Jaime Headden                                                                                                                                               |
| 357 |     17.038825 |    320.217285 | Zimices                                                                                                                                                     |
| 358 |    432.517976 |    484.395272 | Matt Crook                                                                                                                                                  |
| 359 |    392.372248 |    127.074559 | Steven Traver                                                                                                                                               |
| 360 |    472.498327 |    446.400368 | Lafage                                                                                                                                                      |
| 361 |     22.428259 |    410.452003 | NA                                                                                                                                                          |
| 362 |    946.396979 |    385.940984 | Margot Michaud                                                                                                                                              |
| 363 |    960.992244 |     85.517968 | Chris huh                                                                                                                                                   |
| 364 |    864.267003 |    233.463253 | Birgit Lang                                                                                                                                                 |
| 365 |    518.975437 |    573.601462 | Matt Dempsey                                                                                                                                                |
| 366 |    742.561172 |     49.386092 | T. Michael Keesey                                                                                                                                           |
| 367 |    125.337519 |     22.096206 | Dave Souza (vectorized by T. Michael Keesey)                                                                                                                |
| 368 |    966.068075 |    421.888745 | Matthew Hooge (vectorized by T. Michael Keesey)                                                                                                             |
| 369 |    603.446593 |     56.177679 | Samanta Orellana                                                                                                                                            |
| 370 |    501.294418 |    492.324631 | Scott Hartman                                                                                                                                               |
| 371 |    419.191236 |      4.813838 | Steven Coombs                                                                                                                                               |
| 372 |    712.159872 |    612.274951 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                           |
| 373 |    477.180636 |    699.089306 | Steven Coombs                                                                                                                                               |
| 374 |    300.479282 |    675.971628 | Jagged Fang Designs                                                                                                                                         |
| 375 |    978.843523 |    334.966794 | Chris huh                                                                                                                                                   |
| 376 |    417.934040 |    354.479850 | Scott Hartman                                                                                                                                               |
| 377 |    482.485363 |    608.291730 | Markus A. Grohme                                                                                                                                            |
| 378 |     60.128222 |    757.513192 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                           |
| 379 |    877.525207 |    784.887046 | Zimices                                                                                                                                                     |
| 380 |    552.281967 |    608.914161 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                               |
| 381 |    392.814543 |    251.357680 | NA                                                                                                                                                          |
| 382 |    649.506535 |    366.393091 | Chris huh                                                                                                                                                   |
| 383 |    592.134574 |    755.567257 | Gareth Monger                                                                                                                                               |
| 384 |    672.306926 |    196.641736 | NA                                                                                                                                                          |
| 385 |     42.314979 |    333.956907 | Ignacio Contreras                                                                                                                                           |
| 386 |    633.394063 |    138.277663 | Mihai Dragos (vectorized by T. Michael Keesey)                                                                                                              |
| 387 |     29.091406 |    740.831495 | Michael Scroggie                                                                                                                                            |
| 388 |    653.800820 |    315.683828 | T. Michael Keesey                                                                                                                                           |
| 389 |     73.029473 |     59.024251 | Tasman Dixon                                                                                                                                                |
| 390 |    608.392630 |    734.706536 | Chris huh                                                                                                                                                   |
| 391 |    797.468491 |    202.434490 |                                                                                                                                                             |
| 392 |    425.087910 |    414.854267 | Dianne Bray / Museum Victoria (vectorized by T. Michael Keesey)                                                                                             |
| 393 |    211.500169 |    770.201726 | Margot Michaud                                                                                                                                              |
| 394 |    617.433400 |    372.338418 | T. Michael Keesey                                                                                                                                           |
| 395 |    398.975915 |    419.393710 | Courtney Rockenbach                                                                                                                                         |
| 396 |    791.911538 |    476.308651 | Chris huh                                                                                                                                                   |
| 397 |    252.634564 |    659.378622 | Ville-Veikko Sinkkonen                                                                                                                                      |
| 398 |    416.796374 |    532.711880 | Fcb981 (vectorized by T. Michael Keesey)                                                                                                                    |
| 399 |    152.851746 |     44.506021 | Zimices                                                                                                                                                     |
| 400 |    549.617225 |    661.319166 | Erika Schumacher                                                                                                                                            |
| 401 |    156.556901 |    562.684405 | Bruno Maggia                                                                                                                                                |
| 402 |    700.237109 |    372.270821 | Tauana J. Cunha                                                                                                                                             |
| 403 |    356.398939 |    692.897961 | Agnello Picorelli                                                                                                                                           |
| 404 |    409.418138 |    216.573464 | Matt Crook                                                                                                                                                  |
| 405 |     18.640900 |    451.785301 | Margot Michaud                                                                                                                                              |
| 406 |    857.580222 |    532.965381 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                               |
| 407 |    163.970541 |    222.934809 | Birgit Lang                                                                                                                                                 |
| 408 |    535.535319 |    778.261153 | Gareth Monger                                                                                                                                               |
| 409 |     16.731481 |     30.681374 | NA                                                                                                                                                          |
| 410 |    449.907741 |    440.920388 | Zimices                                                                                                                                                     |
| 411 |    233.068423 |    784.171359 | T. Michael Keesey (after Walker & al.)                                                                                                                      |
| 412 |     37.901521 |    631.662361 | Meyers Konversations-Lexikon 1897 (vectorized: Yan Wong)                                                                                                    |
| 413 |    217.344940 |    541.936743 | Kimberly Haddrell                                                                                                                                           |
| 414 |    831.285775 |    278.920235 | T. Michael Keesey                                                                                                                                           |
| 415 |    986.271249 |    247.457828 | Tyler McCraney                                                                                                                                              |
| 416 |    405.949794 |    278.081983 | Ignacio Contreras                                                                                                                                           |
| 417 |    249.414325 |    756.741450 | Michael Scroggie                                                                                                                                            |
| 418 |    444.126912 |    688.210628 | Christine Axon                                                                                                                                              |
| 419 |    344.142912 |    544.509193 | Gabriela Palomo-Munoz                                                                                                                                       |
| 420 |    495.037936 |    646.947931 | NA                                                                                                                                                          |
| 421 |    646.560348 |    325.166755 | Mattia Menchetti                                                                                                                                            |
| 422 |     80.478922 |    105.703072 | Scott Hartman                                                                                                                                               |
| 423 |     33.758502 |    282.030273 | Matt Crook                                                                                                                                                  |
| 424 |   1011.491062 |    401.420222 | Felix Vaux                                                                                                                                                  |
| 425 |    749.223948 |    586.266169 | Andy Wilson                                                                                                                                                 |
| 426 |    525.209015 |    725.070040 | Terpsichores                                                                                                                                                |
| 427 |     73.073807 |    790.189227 | Jagged Fang Designs                                                                                                                                         |
| 428 |    896.317879 |    429.417315 | Mike Hanson                                                                                                                                                 |
| 429 |    255.198361 |    348.621750 | Rachel Shoop                                                                                                                                                |
| 430 |    319.886582 |    237.241170 | Matt Crook                                                                                                                                                  |
| 431 |    850.526649 |    768.361161 | NASA                                                                                                                                                        |
| 432 |   1005.018241 |    296.604579 | Cesar Julian                                                                                                                                                |
| 433 |    925.507742 |     69.087827 | Alyssa Bell & Luis Chiappe 2015, dx.doi.org/10.1371/journal.pone.0141690                                                                                    |
| 434 |    682.893690 |    153.315762 | FunkMonk                                                                                                                                                    |
| 435 |    651.280811 |     84.059066 | Margot Michaud                                                                                                                                              |
| 436 |    457.358979 |    141.277772 | Beth Reinke                                                                                                                                                 |
| 437 |    536.768988 |    148.943534 | Margot Michaud                                                                                                                                              |
| 438 |    530.255117 |    353.374928 | NA                                                                                                                                                          |
| 439 |    438.858040 |    224.258036 | Margot Michaud                                                                                                                                              |
| 440 |   1008.007623 |    233.210129 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                              |
| 441 |    134.698342 |    587.760423 | Beth Reinke                                                                                                                                                 |
| 442 |    200.428070 |    576.696783 | Caleb M. Brown                                                                                                                                              |
| 443 |    389.221991 |    400.478702 | Chris A. Hamilton                                                                                                                                           |
| 444 |    788.217906 |    130.767498 | Karla Martinez                                                                                                                                              |
| 445 |    673.443901 |    142.576469 | Jaime Headden                                                                                                                                               |
| 446 |    173.551812 |    141.092645 | Kristina Gagalova                                                                                                                                           |
| 447 |     24.456408 |    217.112051 | Chris huh                                                                                                                                                   |
| 448 |    824.262514 |     45.508506 | Mali’o Kodis, image from Higgins and Kristensen, 1986                                                                                                       |
| 449 |    431.392809 |    728.599652 | Noah Schlottman, photo from Casey Dunn                                                                                                                      |
| 450 |    532.170707 |    672.462752 | Alexandre Vong                                                                                                                                              |
| 451 |    521.126331 |    485.046010 | Greg Schechter (original photo), Renato Santos (vector silhouette)                                                                                          |
| 452 |    975.089714 |    374.157936 | Scott Hartman                                                                                                                                               |
| 453 |    777.765464 |     25.887532 | Collin Gross                                                                                                                                                |
| 454 |    131.621038 |    423.825075 | Chris huh                                                                                                                                                   |
| 455 |    696.138308 |    670.351030 | Scott Hartman                                                                                                                                               |
| 456 |    786.117411 |    661.763474 | Manabu Bessho-Uehara                                                                                                                                        |
| 457 |    258.128543 |     82.751238 | Erika Schumacher                                                                                                                                            |
| 458 |    595.929661 |     16.251610 | Tyler Greenfield                                                                                                                                            |
| 459 |    214.209522 |    797.057628 | Markus A. Grohme                                                                                                                                            |
| 460 |    336.137971 |    152.907926 | S.Martini                                                                                                                                                   |
| 461 |    494.220318 |    253.315398 | Gabriela Palomo-Munoz                                                                                                                                       |
| 462 |    462.618160 |    750.872528 | Tasman Dixon                                                                                                                                                |
| 463 |   1003.202607 |    666.151525 | Iain Reid                                                                                                                                                   |
| 464 |    169.619372 |    677.808233 | Jagged Fang Designs                                                                                                                                         |
| 465 |    658.950796 |    135.384087 | Scott Hartman                                                                                                                                               |
| 466 |    930.108178 |    669.286170 | CNZdenek                                                                                                                                                    |
| 467 |    302.074349 |    205.507771 | Felix Vaux                                                                                                                                                  |
| 468 |    861.073703 |      9.028877 | Original drawing by Nobu Tamura, vectorized by Roberto Díaz Sibaja                                                                                          |
| 469 |    554.619775 |    496.064834 | Michele Tobias                                                                                                                                              |
| 470 |   1012.036921 |    710.263780 | Tyler Greenfield                                                                                                                                            |
| 471 |    331.705234 |    789.503512 | Andrew A. Farke                                                                                                                                             |
| 472 |    295.401794 |    405.920529 | Steven Traver                                                                                                                                               |
| 473 |     53.479995 |    313.675152 | Eduard Solà (vectorized by T. Michael Keesey)                                                                                                               |
| 474 |    377.788196 |     89.235895 | Gareth Monger                                                                                                                                               |
| 475 |    512.734475 |    272.575081 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                                 |
| 476 |    547.913336 |    430.396002 | ДиБгд (vectorized by T. Michael Keesey)                                                                                                                     |
| 477 |    718.468400 |    289.987882 | Zimices / Julián Bayona                                                                                                                                     |
| 478 |    844.007281 |    450.213091 | Andy Wilson                                                                                                                                                 |
| 479 |    124.497438 |    778.170232 | Yan Wong                                                                                                                                                    |
| 480 |    903.357506 |     48.858255 | Ignacio Contreras                                                                                                                                           |
| 481 |     17.960225 |    332.295809 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                             |
| 482 |    484.282407 |    728.802405 | Michael Scroggie                                                                                                                                            |
| 483 |     63.895945 |    141.794265 | Gabriela Palomo-Munoz                                                                                                                                       |
| 484 |    151.879882 |    345.456574 | Mareike C. Janiak                                                                                                                                           |
| 485 |    598.316605 |    249.827543 | Jack Mayer Wood                                                                                                                                             |
| 486 |    362.433641 |    768.706249 | Jagged Fang Designs                                                                                                                                         |
| 487 |    934.876712 |    592.689129 | Jaime Chirinos (vectorized by T. Michael Keesey)                                                                                                            |
| 488 |   1002.020726 |    286.624350 | Zimices                                                                                                                                                     |
| 489 |    483.384256 |    103.189029 | Chris huh                                                                                                                                                   |
| 490 |    797.618235 |    502.706207 | FunkMonk                                                                                                                                                    |
| 491 |    619.237740 |    224.987380 | Mathew Wedel                                                                                                                                                |
| 492 |    557.903830 |    685.805988 | Markus A. Grohme                                                                                                                                            |
| 493 |    740.447842 |    135.038316 | Margot Michaud                                                                                                                                              |
| 494 |    994.779066 |     36.321072 | Oren Peles / vectorized by Yan Wong                                                                                                                         |
| 495 |    775.013497 |     71.280927 | Ferran Sayol                                                                                                                                                |
| 496 |    881.724262 |    373.368528 | Zachary Quigley                                                                                                                                             |
| 497 |    925.209909 |    433.791771 | Scott Hartman                                                                                                                                               |
| 498 |    899.211977 |    204.743048 | Pete Buchholz                                                                                                                                               |
| 499 |    600.099369 |    596.901984 | Chris huh                                                                                                                                                   |
| 500 |    190.010948 |     89.172242 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                            |
| 501 |    657.008195 |    624.801106 | Chris huh                                                                                                                                                   |
| 502 |    264.413666 |     18.650856 | Gareth Monger                                                                                                                                               |
| 503 |     18.567718 |    383.410989 | NA                                                                                                                                                          |
| 504 |    308.366484 |    486.142098 | CNZdenek                                                                                                                                                    |
| 505 |    820.733203 |    623.332137 | Duane Raver/USFWS                                                                                                                                           |

    #> Your tweet has been posted!
