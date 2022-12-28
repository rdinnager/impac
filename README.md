
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

Chris huh, Zachary Quigley, Gabriela Palomo-Munoz, Margot Michaud,
Robert Gay, modifed from Olegivvit, Tyler Greenfield, Maxime Dahirel,
Xavier Giroux-Bougard, C. Camilo Julián-Caballero, Mason McNair, Jose
Carlos Arenas-Monroy, FunkMonk, Matt Crook, Andy Wilson, Karl Ragnar
Gjertsen (vectorized by T. Michael Keesey), Jaime Headden, Roberto Díaz
Sibaja, Richard Ruggiero, vectorized by Zimices, Dean Schnabel, B. Duygu
Özpolat, Ignacio Contreras, Lauren Anderson, Paul O. Lewis, Luc Viatour
(source photo) and Andreas Plank, Darren Naish (vectorize by T. Michael
Keesey), Zimices, Lukasiniho, Jagged Fang Designs, Matthew Hooge
(vectorized by T. Michael Keesey), Sarah Werning, Emily Jane McTavish,
Steven Traver, Nobu Tamura (vectorized by T. Michael Keesey), Sean
McCann, Timothy Knepp of the U.S. Fish and Wildlife Service
(illustration) and Timothy J. Bartley (silhouette), T. Michael Keesey,
Abraão Leite, Michelle Site, Scott Hartman, Mattia Menchetti, Iain Reid,
Christian A. Masnaghetti, Diego Fontaneto, Elisabeth A. Herniou, Chiara
Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy
G. Barraclough (vectorized by T. Michael Keesey), Martin R. Smith,
S.Martini, Markus A. Grohme, Obsidian Soul (vectorized by T. Michael
Keesey), Gareth Monger, Jimmy Bernot, Michael Ströck (vectorized by T.
Michael Keesey), Cristian Osorio & Paula Carrera, Proyecto Carnivoros
Australes (www.carnivorosaustrales.org), Joanna Wolfe, Ferran Sayol,
Tasman Dixon, Dmitry Bogdanov (vectorized by T. Michael Keesey),
Smokeybjb, Ville Koistinen (vectorized by T. Michael Keesey), Joe
Schneid (vectorized by T. Michael Keesey), Enoch Joseph Wetsy (photo),
John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G.
Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey,
Melissa Broussard, Manabu Bessho-Uehara, Inessa Voet, Kanchi Nanjo, Nobu
Tamura (modified by T. Michael Keesey), Tony Ayling (vectorized by T.
Michael Keesey), Kai R. Caspar, Michael Scroggie, Remes K, Ortega F,
Fierro I, Joger U, Kosma R, et al., Anthony Caravaggi, Tracy A. Heath,
Terpsichores, Frank Denota, Pranav Iyer (grey ideas), Fernando
Carezzano, Dmitry Bogdanov, terngirl, Kamil S. Jaron, Owen Jones
(derived from a CC-BY 2.0 photograph by Paulo B. Chaves), Eduard Solà
Vázquez, vectorised by Yan Wong, Christine Axon, Didier Descouens
(vectorized by T. Michael Keesey), Andrew A. Farke, shell lines added by
Yan Wong, Stanton F. Fink, vectorized by Zimices, Matt Martyniuk
(vectorized by T. Michael Keesey), Ghedoghedo, vectorized by Zimices,
Emma Hughes, Christoph Schomburg, Sherman Foote Denton (illustration,
1897) and Timothy J. Bartley (silhouette), Birgit Lang, Elisabeth
Östman, NOAA Great Lakes Environmental Research Laboratory
(illustration) and Timothy J. Bartley (silhouette), Nobu Tamura,
vectorized by Zimices, Collin Gross, Ville Koistinen and T. Michael
Keesey, Stanton F. Fink (vectorized by T. Michael Keesey), Original
drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja, Andrew A.
Farke, Michael B. H. (vectorized by T. Michael Keesey), FunkMonk
(Michael B.H.; vectorized by T. Michael Keesey), Scott Reid, Nobu
Tamura, Andreas Hejnol, Dennis C. Murphy, after
<https://commons.wikimedia.org/wiki/File:Queensland_State_Archives_2981_Cane_toads_at_the_Meringa_Sugar_Experiment_Station_North_Queensland_c_1935.png>,
Tauana J. Cunha, Margret Flinsch, vectorized by Zimices, Josefine Bohr
Brask, Emily Willoughby, Christopher Chávez, SauropodomorphMonarch,
Steven Coombs, Dinah Challen, Shyamal, Robert Gay, M. Garfield & K.
Anderson (modified by T. Michael Keesey), Karina Garcia, Roderic Page
and Lois Page, Ghedoghedo (vectorized by T. Michael Keesey), Rebecca
Groom, Kimberly Haddrell, Manabu Sakamoto, M Kolmann, DW Bapst, modified
from Ishitani et al. 2016, Sidney Frederic Harmer, Arthur Everett
Shipley (vectorized by Maxime Dahirel), Yan Wong, SecretJellyMan - from
Mason McNair, Matt Dempsey, Todd Marshall, vectorized by Zimices,
Allison Pease, Joris van der Ham (vectorized by T. Michael Keesey), Noah
Schlottman, Beth Reinke, Robert Bruce Horsfall, vectorized by Zimices,
Lukas Panzarin, Mo Hassan, Hans Hillewaert (vectorized by T. Michael
Keesey), Jack Mayer Wood, Chris Hay, Diana Pomeroy, A. R. McCulloch
(vectorized by T. Michael Keesey), Kailah Thorn & Ben King, Maija
Karala, Bruno C. Vellutini, John Gould (vectorized by T. Michael
Keesey), xgirouxb, Javier Luque, Charles R. Knight, vectorized by
Zimices, Felix Vaux, Alyssa Bell & Luis Chiappe 2015,
dx.doi.org/10.1371/journal.pone.0141690, Alexandre Vong, Oscar
Sanisidro, Tod Robbins, Harold N Eyster, wsnaccad, Walter Vladimir,
Conty (vectorized by T. Michael Keesey), Duane Raver (vectorized by T.
Michael Keesey), Lisa M. “Pixxl” (photo), John E. McCormack, Michael G.
Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb
T. Brumfield & T. Michael Keesey, Chris A. Hamilton, T. Michael Keesey
(after James & al.), Tyler Greenfield and Scott Hartman, Robbie N. Cada
(vectorized by T. Michael Keesey), Tony Ayling, Henry Lydecker, John
Curtis (vectorized by T. Michael Keesey), Nobu Tamura (vectorized by A.
Verrière), Konsta Happonen, Mathieu Basille, Pete Buchholz, Gustav
Mützel, Noah Schlottman, photo by Casey Dunn, Yan Wong from wikipedia
drawing (PD: Pearson Scott Foresman), James R. Spotila and Ray
Chatterji, Benchill, david maas / dave hone, James I. Kirkland, Luis
Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P.
Wiersma (vectorized by T. Michael Keesey), Cesar Julian, Michael P.
Taylor, Cagri Cevrim, G. M. Woodward, David Orr, Mark Miller, Heinrich
Harder (vectorized by T. Michael Keesey), Carlos Cano-Barbacil,
FJDegrange, Kent Elson Sorgon

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                          |
| --: | ------------: | ------------: | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
|   1 |    835.784115 |    287.664222 | Chris huh                                                                                                                                                                       |
|   2 |    111.927805 |    202.831545 | Chris huh                                                                                                                                                                       |
|   3 |    423.792863 |    274.549547 | Zachary Quigley                                                                                                                                                                 |
|   4 |    436.737778 |    706.828761 | Gabriela Palomo-Munoz                                                                                                                                                           |
|   5 |    502.125488 |    525.269221 | Margot Michaud                                                                                                                                                                  |
|   6 |    634.798781 |    128.673934 | Robert Gay, modifed from Olegivvit                                                                                                                                              |
|   7 |    546.071521 |     79.805641 | Tyler Greenfield                                                                                                                                                                |
|   8 |    290.240702 |    137.378645 | Maxime Dahirel                                                                                                                                                                  |
|   9 |    289.640980 |    457.567695 | Xavier Giroux-Bougard                                                                                                                                                           |
|  10 |    849.239015 |    583.377551 | C. Camilo Julián-Caballero                                                                                                                                                      |
|  11 |    629.676920 |    455.003768 | Mason McNair                                                                                                                                                                    |
|  12 |    153.743985 |    620.501257 | Margot Michaud                                                                                                                                                                  |
|  13 |    783.081813 |    709.417225 | Jose Carlos Arenas-Monroy                                                                                                                                                       |
|  14 |    835.832754 |    443.904778 | FunkMonk                                                                                                                                                                        |
|  15 |    653.313942 |    580.840206 | Matt Crook                                                                                                                                                                      |
|  16 |    206.356051 |    329.773276 | Andy Wilson                                                                                                                                                                     |
|  17 |     60.203596 |    484.292031 | Margot Michaud                                                                                                                                                                  |
|  18 |    903.459845 |    145.690290 | Karl Ragnar Gjertsen (vectorized by T. Michael Keesey)                                                                                                                          |
|  19 |    489.302857 |    320.857920 | Jaime Headden                                                                                                                                                                   |
|  20 |    581.142860 |    235.736424 | Roberto Díaz Sibaja                                                                                                                                                             |
|  21 |    518.764749 |    604.454519 | Richard Ruggiero, vectorized by Zimices                                                                                                                                         |
|  22 |    474.782946 |    170.830194 | Dean Schnabel                                                                                                                                                                   |
|  23 |    300.505746 |    652.075450 | Maxime Dahirel                                                                                                                                                                  |
|  24 |    937.331222 |    449.044277 | NA                                                                                                                                                                              |
|  25 |    768.634697 |    214.312779 | B. Duygu Özpolat                                                                                                                                                                |
|  26 |    493.220336 |    352.271517 | NA                                                                                                                                                                              |
|  27 |    535.996602 |    748.670906 | Ignacio Contreras                                                                                                                                                               |
|  28 |    878.651904 |    723.947163 | Lauren Anderson                                                                                                                                                                 |
|  29 |    672.558727 |     25.829569 | Gabriela Palomo-Munoz                                                                                                                                                           |
|  30 |    134.917340 |     72.451714 | Paul O. Lewis                                                                                                                                                                   |
|  31 |    733.155404 |    498.304203 | Luc Viatour (source photo) and Andreas Plank                                                                                                                                    |
|  32 |    680.249489 |    650.795521 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                                   |
|  33 |    194.630062 |    731.800514 | Andy Wilson                                                                                                                                                                     |
|  34 |    766.639872 |    109.452495 | Zimices                                                                                                                                                                         |
|  35 |    968.700992 |     76.638523 | Lukasiniho                                                                                                                                                                      |
|  36 |    624.016507 |    313.399815 | Margot Michaud                                                                                                                                                                  |
|  37 |    363.025462 |    321.470329 | Jagged Fang Designs                                                                                                                                                             |
|  38 |    876.915761 |    327.227670 | NA                                                                                                                                                                              |
|  39 |    958.720045 |    199.921399 | Margot Michaud                                                                                                                                                                  |
|  40 |    407.403546 |    110.575156 | Matthew Hooge (vectorized by T. Michael Keesey)                                                                                                                                 |
|  41 |    556.996911 |    696.404043 | Jose Carlos Arenas-Monroy                                                                                                                                                       |
|  42 |    667.464509 |    378.641054 | C. Camilo Julián-Caballero                                                                                                                                                      |
|  43 |    313.176550 |    788.342248 | Ignacio Contreras                                                                                                                                                               |
|  44 |     87.604224 |    733.093142 | Zimices                                                                                                                                                                         |
|  45 |     75.736831 |    378.522528 | Margot Michaud                                                                                                                                                                  |
|  46 |    200.093497 |    240.203043 | Zimices                                                                                                                                                                         |
|  47 |     57.727698 |    269.859068 | Sarah Werning                                                                                                                                                                   |
|  48 |    931.735337 |    714.176605 | Emily Jane McTavish                                                                                                                                                             |
|  49 |    404.565720 |    561.840415 | Steven Traver                                                                                                                                                                   |
|  50 |    412.589460 |     34.555662 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
|  51 |    792.790994 |    370.838831 | Zimices                                                                                                                                                                         |
|  52 |    692.856617 |    186.235457 | Sean McCann                                                                                                                                                                     |
|  53 |     78.090165 |    153.707378 | Timothy Knepp of the U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                          |
|  54 |    721.849391 |    415.946974 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
|  55 |     72.894765 |    593.019794 | Matt Crook                                                                                                                                                                      |
|  56 |    720.596007 |    301.325814 | Jagged Fang Designs                                                                                                                                                             |
|  57 |    899.339434 |     46.096767 | T. Michael Keesey                                                                                                                                                               |
|  58 |    608.013006 |    553.335695 | Jaime Headden                                                                                                                                                                   |
|  59 |    250.080646 |    543.181571 | Margot Michaud                                                                                                                                                                  |
|  60 |    225.187667 |    632.137533 | Abraão Leite                                                                                                                                                                    |
|  61 |    326.711838 |    749.393972 | Michelle Site                                                                                                                                                                   |
|  62 |    815.508434 |    632.704701 | Scott Hartman                                                                                                                                                                   |
|  63 |    957.191053 |    638.952490 | Scott Hartman                                                                                                                                                                   |
|  64 |    522.559995 |    775.485067 | Mattia Menchetti                                                                                                                                                                |
|  65 |    495.014270 |    405.498040 | Margot Michaud                                                                                                                                                                  |
|  66 |    597.713330 |    194.672437 | Iain Reid                                                                                                                                                                       |
|  67 |    277.163267 |    294.006827 | Christian A. Masnaghetti                                                                                                                                                        |
|  68 |    229.933644 |     92.149183 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey)           |
|  69 |    827.866426 |    514.148063 | Martin R. Smith                                                                                                                                                                 |
|  70 |    350.357860 |    382.436384 | Matt Crook                                                                                                                                                                      |
|  71 |    785.780706 |    773.902495 | Matt Crook                                                                                                                                                                      |
|  72 |     34.868576 |     65.815637 | T. Michael Keesey                                                                                                                                                               |
|  73 |    515.407135 |    662.397950 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
|  74 |     77.673961 |    661.891841 | Zimices                                                                                                                                                                         |
|  75 |    368.111823 |    213.220105 | S.Martini                                                                                                                                                                       |
|  76 |    858.197409 |    197.679763 | Chris huh                                                                                                                                                                       |
|  77 |    575.891419 |    111.284673 | Markus A. Grohme                                                                                                                                                                |
|  78 |    376.780539 |    132.563288 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                                 |
|  79 |    756.483019 |    447.305515 | Gareth Monger                                                                                                                                                                   |
|  80 |    699.505129 |    761.707518 | Jimmy Bernot                                                                                                                                                                    |
|  81 |    934.167260 |    761.126836 | Chris huh                                                                                                                                                                       |
|  82 |    555.689090 |    453.865361 | NA                                                                                                                                                                              |
|  83 |    355.824178 |    105.325810 | Michael Ströck (vectorized by T. Michael Keesey)                                                                                                                                |
|  84 |    575.379806 |    372.463829 | Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org)                                                                                    |
|  85 |    147.071685 |    538.406375 | NA                                                                                                                                                                              |
|  86 |    550.691994 |    288.383609 | Joanna Wolfe                                                                                                                                                                    |
|  87 |   1002.749798 |    462.324698 | Ferran Sayol                                                                                                                                                                    |
|  88 |    992.514143 |    780.366551 | Tasman Dixon                                                                                                                                                                    |
|  89 |    164.692692 |    394.656260 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
|  90 |    930.950893 |    273.652440 | Ignacio Contreras                                                                                                                                                               |
|  91 |    455.667651 |     66.148945 | NA                                                                                                                                                                              |
|  92 |    688.854825 |     54.054580 | Smokeybjb                                                                                                                                                                       |
|  93 |    289.253338 |    578.195044 | NA                                                                                                                                                                              |
|  94 |    556.343213 |     39.217500 | Ville Koistinen (vectorized by T. Michael Keesey)                                                                                                                               |
|  95 |    203.013337 |    688.332143 | Scott Hartman                                                                                                                                                                   |
|  96 |    462.140769 |    236.523385 | Gabriela Palomo-Munoz                                                                                                                                                           |
|  97 |    970.664069 |    319.323227 | Joe Schneid (vectorized by T. Michael Keesey)                                                                                                                                   |
|  98 |    115.519399 |    602.211227 | Steven Traver                                                                                                                                                                   |
|  99 |    893.197713 |    128.283891 | T. Michael Keesey                                                                                                                                                               |
| 100 |    221.224019 |     35.565737 | Enoch Joseph Wetsy (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey              |
| 101 |    976.100889 |    577.755414 | Melissa Broussard                                                                                                                                                               |
| 102 |    872.652100 |    650.765058 | Manabu Bessho-Uehara                                                                                                                                                            |
| 103 |    906.336482 |    261.354053 | Inessa Voet                                                                                                                                                                     |
| 104 |    401.922885 |    406.960964 | Kanchi Nanjo                                                                                                                                                                    |
| 105 |    308.865453 |    255.433202 | Chris huh                                                                                                                                                                       |
| 106 |    630.896447 |    768.992219 | Gareth Monger                                                                                                                                                                   |
| 107 |     33.305618 |    759.568983 | Scott Hartman                                                                                                                                                                   |
| 108 |    643.549568 |    710.816561 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                                     |
| 109 |    231.196574 |      8.227882 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                                   |
| 110 |    132.760800 |    270.036042 | Scott Hartman                                                                                                                                                                   |
| 111 |    171.122104 |    140.209827 | Dean Schnabel                                                                                                                                                                   |
| 112 |    499.981763 |     15.934881 | Scott Hartman                                                                                                                                                                   |
| 113 |    487.225865 |    119.035205 | Kai R. Caspar                                                                                                                                                                   |
| 114 |    997.372605 |    729.024291 | Michael Scroggie                                                                                                                                                                |
| 115 |    562.303709 |    486.984945 | Remes K, Ortega F, Fierro I, Joger U, Kosma R, et al.                                                                                                                           |
| 116 |    999.430612 |    555.417952 | Gareth Monger                                                                                                                                                                   |
| 117 |    543.703286 |     51.892663 | Anthony Caravaggi                                                                                                                                                               |
| 118 |    365.329181 |    716.154933 | Jagged Fang Designs                                                                                                                                                             |
| 119 |    933.930367 |    712.294603 | Matt Crook                                                                                                                                                                      |
| 120 |    791.876481 |    322.337961 | Smokeybjb                                                                                                                                                                       |
| 121 |    941.954429 |    678.674874 | Steven Traver                                                                                                                                                                   |
| 122 |    192.102350 |     94.350111 | Andy Wilson                                                                                                                                                                     |
| 123 |    999.338728 |    509.575556 | Matt Crook                                                                                                                                                                      |
| 124 |     30.515681 |    680.035547 | Tracy A. Heath                                                                                                                                                                  |
| 125 |     24.802031 |    128.821537 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                                     |
| 126 |    836.051891 |    256.754613 | Steven Traver                                                                                                                                                                   |
| 127 |    348.415301 |    571.380024 | Terpsichores                                                                                                                                                                    |
| 128 |    834.272057 |    222.651038 | Scott Hartman                                                                                                                                                                   |
| 129 |    736.007523 |    278.704608 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 130 |    915.398568 |    109.333112 | NA                                                                                                                                                                              |
| 131 |    770.412709 |    554.968823 | Gareth Monger                                                                                                                                                                   |
| 132 |    449.366497 |    597.463936 | NA                                                                                                                                                                              |
| 133 |    308.736546 |    220.118857 | Chris huh                                                                                                                                                                       |
| 134 |    927.513649 |    293.700668 | Frank Denota                                                                                                                                                                    |
| 135 |    869.975933 |    368.359521 | Matt Crook                                                                                                                                                                      |
| 136 |    843.916053 |    172.685823 | Pranav Iyer (grey ideas)                                                                                                                                                        |
| 137 |    287.066090 |    319.221508 | Ferran Sayol                                                                                                                                                                    |
| 138 |    677.074666 |    108.148028 | Fernando Carezzano                                                                                                                                                              |
| 139 |    245.395770 |    393.913183 | Dmitry Bogdanov                                                                                                                                                                 |
| 140 |    998.727560 |    755.286988 | Tasman Dixon                                                                                                                                                                    |
| 141 |    433.898757 |    788.139246 | NA                                                                                                                                                                              |
| 142 |    839.975607 |     72.246566 | Matt Crook                                                                                                                                                                      |
| 143 |    692.413076 |    256.281048 | terngirl                                                                                                                                                                        |
| 144 |    849.018989 |    773.175257 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 145 |   1010.487827 |    393.734503 | NA                                                                                                                                                                              |
| 146 |    379.305071 |    169.762210 | Kamil S. Jaron                                                                                                                                                                  |
| 147 |   1008.361749 |    607.567286 | Matt Crook                                                                                                                                                                      |
| 148 |    568.907382 |    139.206014 | Scott Hartman                                                                                                                                                                   |
| 149 |    400.855409 |    629.833401 | Abraão Leite                                                                                                                                                                    |
| 150 |    864.405710 |    232.328153 | Zimices                                                                                                                                                                         |
| 151 |    637.823480 |    525.404894 | Andy Wilson                                                                                                                                                                     |
| 152 |    511.539175 |     49.939456 | Owen Jones (derived from a CC-BY 2.0 photograph by Paulo B. Chaves)                                                                                                             |
| 153 |    826.734781 |    188.940339 | Eduard Solà Vázquez, vectorised by Yan Wong                                                                                                                                     |
| 154 |    596.589145 |    293.284669 | NA                                                                                                                                                                              |
| 155 |    286.755327 |    226.590478 | Christine Axon                                                                                                                                                                  |
| 156 |    800.631944 |     21.242555 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                              |
| 157 |     85.906533 |    122.814567 | Andrew A. Farke, shell lines added by Yan Wong                                                                                                                                  |
| 158 |    708.450683 |    291.373761 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 159 |    865.678993 |     91.490040 | Stanton F. Fink, vectorized by Zimices                                                                                                                                          |
| 160 |    391.921861 |    366.771106 | Steven Traver                                                                                                                                                                   |
| 161 |     69.502052 |    412.500006 | Matt Crook                                                                                                                                                                      |
| 162 |    927.285440 |    560.131188 | Dean Schnabel                                                                                                                                                                   |
| 163 |    163.956684 |    663.505981 | Ferran Sayol                                                                                                                                                                    |
| 164 |    646.066563 |    414.212632 | Steven Traver                                                                                                                                                                   |
| 165 |    820.327068 |    144.459686 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                                |
| 166 |    365.387389 |    602.172816 | T. Michael Keesey                                                                                                                                                               |
| 167 |    149.853920 |    574.833561 | Margot Michaud                                                                                                                                                                  |
| 168 |     39.803962 |    565.827690 | Ferran Sayol                                                                                                                                                                    |
| 169 |    472.061745 |    370.145168 | Kai R. Caspar                                                                                                                                                                   |
| 170 |    136.874120 |    502.383871 | Ghedoghedo, vectorized by Zimices                                                                                                                                               |
| 171 |    713.128788 |    470.160418 | Emma Hughes                                                                                                                                                                     |
| 172 |    602.793268 |    634.943624 | Christoph Schomburg                                                                                                                                                             |
| 173 |   1002.563517 |    695.774827 | Maxime Dahirel                                                                                                                                                                  |
| 174 |    934.230884 |    774.621686 | Sherman Foote Denton (illustration, 1897) and Timothy J. Bartley (silhouette)                                                                                                   |
| 175 |    576.457159 |    518.928123 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 176 |    996.052255 |    338.838477 | Fernando Carezzano                                                                                                                                                              |
| 177 |    596.897044 |    598.755818 | Gareth Monger                                                                                                                                                                   |
| 178 |     75.258344 |    440.278335 | Matt Crook                                                                                                                                                                      |
| 179 |    274.298864 |     15.053230 | NA                                                                                                                                                                              |
| 180 |    670.949101 |    250.208049 | Chris huh                                                                                                                                                                       |
| 181 |    506.128313 |    720.582149 | FunkMonk                                                                                                                                                                        |
| 182 |      9.452825 |     58.280572 | Birgit Lang                                                                                                                                                                     |
| 183 |    874.396832 |    559.598673 | Gareth Monger                                                                                                                                                                   |
| 184 |     70.202373 |     59.806560 | Elisabeth Östman                                                                                                                                                                |
| 185 |    670.393026 |    779.991250 | Andy Wilson                                                                                                                                                                     |
| 186 |    225.782559 |    773.512989 | Matt Crook                                                                                                                                                                      |
| 187 |    115.931514 |     17.978105 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                           |
| 188 |    616.253076 |     35.725065 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 189 |    835.258680 |    413.159891 | Nobu Tamura, vectorized by Zimices                                                                                                                                              |
| 190 |    753.450838 |    569.685247 | Zimices                                                                                                                                                                         |
| 191 |    407.637289 |    198.059335 | Collin Gross                                                                                                                                                                    |
| 192 |     20.161317 |    397.666439 | Ville Koistinen and T. Michael Keesey                                                                                                                                           |
| 193 |    176.020185 |    260.810486 | Gareth Monger                                                                                                                                                                   |
| 194 |     73.896503 |    618.309118 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                               |
| 195 |    509.525687 |    104.998369 | T. Michael Keesey                                                                                                                                                               |
| 196 |    229.568044 |     23.070645 | Iain Reid                                                                                                                                                                       |
| 197 |    723.880137 |     42.987547 | NA                                                                                                                                                                              |
| 198 |    102.857477 |    295.946559 | Ferran Sayol                                                                                                                                                                    |
| 199 |     17.748974 |    727.106231 | NA                                                                                                                                                                              |
| 200 |    741.903284 |    586.780235 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                                          |
| 201 |     24.612792 |    303.813679 | Margot Michaud                                                                                                                                                                  |
| 202 |    109.748785 |    229.912373 | Andrew A. Farke                                                                                                                                                                 |
| 203 |    826.732914 |    157.881735 | Zimices                                                                                                                                                                         |
| 204 |    235.877783 |    309.945700 | Matt Crook                                                                                                                                                                      |
| 205 |    617.810683 |    733.569072 | Michael B. H. (vectorized by T. Michael Keesey)                                                                                                                                 |
| 206 |    857.641428 |    406.591050 | Margot Michaud                                                                                                                                                                  |
| 207 |    232.703914 |    100.867435 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 208 |    968.578147 |    230.156390 | Melissa Broussard                                                                                                                                                               |
| 209 |    908.068429 |    789.784645 | FunkMonk (Michael B.H.; vectorized by T. Michael Keesey)                                                                                                                        |
| 210 |    812.806181 |    215.027566 | Scott Reid                                                                                                                                                                      |
| 211 |    101.791035 |    769.886027 | T. Michael Keesey                                                                                                                                                               |
| 212 |    964.271455 |    795.792853 | Scott Hartman                                                                                                                                                                   |
| 213 |    607.764681 |    786.329166 | Nobu Tamura                                                                                                                                                                     |
| 214 |    584.660707 |    633.639631 | Andreas Hejnol                                                                                                                                                                  |
| 215 |    215.607728 |    658.583988 | Christine Axon                                                                                                                                                                  |
| 216 |    987.989536 |    699.456954 | Zimices                                                                                                                                                                         |
| 217 |    514.890413 |    327.512507 | Dennis C. Murphy, after <https://commons.wikimedia.org/wiki/File:Queensland_State_Archives_2981_Cane_toads_at_the_Meringa_Sugar_Experiment_Station_North_Queensland_c_1935.png> |
| 218 |     18.035677 |     18.934925 | Tauana J. Cunha                                                                                                                                                                 |
| 219 |    408.054969 |    771.737443 | Sarah Werning                                                                                                                                                                   |
| 220 |    886.163724 |    542.338866 | Margret Flinsch, vectorized by Zimices                                                                                                                                          |
| 221 |    404.426745 |    751.172171 | Zimices                                                                                                                                                                         |
| 222 |    610.838910 |     62.088508 | T. Michael Keesey                                                                                                                                                               |
| 223 |    577.189623 |    350.471858 | Chris huh                                                                                                                                                                       |
| 224 |     32.015518 |    108.593647 | Margot Michaud                                                                                                                                                                  |
| 225 |    394.222951 |    518.143577 | Matt Crook                                                                                                                                                                      |
| 226 |     56.451544 |     21.288786 | Gareth Monger                                                                                                                                                                   |
| 227 |    169.309894 |    506.435790 | Andrew A. Farke                                                                                                                                                                 |
| 228 |    402.727280 |     11.586100 | Steven Traver                                                                                                                                                                   |
| 229 |    743.821183 |    608.362918 | Lukasiniho                                                                                                                                                                      |
| 230 |    342.150790 |    720.182766 | Josefine Bohr Brask                                                                                                                                                             |
| 231 |    758.145994 |    277.909529 | Scott Hartman                                                                                                                                                                   |
| 232 |    260.951893 |    513.752748 | Markus A. Grohme                                                                                                                                                                |
| 233 |    472.238093 |    789.398858 | Emily Willoughby                                                                                                                                                                |
| 234 |    166.476220 |    167.095128 | Andrew A. Farke                                                                                                                                                                 |
| 235 |     77.436196 |    456.862572 | Zimices                                                                                                                                                                         |
| 236 |    933.380475 |     36.739226 | Matt Crook                                                                                                                                                                      |
| 237 |     93.295623 |    342.797202 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 238 |    826.573063 |    123.250039 | Joe Schneid (vectorized by T. Michael Keesey)                                                                                                                                   |
| 239 |    201.256959 |    308.436620 | Zimices                                                                                                                                                                         |
| 240 |    511.962973 |    737.248380 | Christopher Chávez                                                                                                                                                              |
| 241 |     52.590289 |     37.112246 | SauropodomorphMonarch                                                                                                                                                           |
| 242 |    304.056609 |    210.569163 | Tasman Dixon                                                                                                                                                                    |
| 243 |    723.629323 |    564.107221 | Matt Crook                                                                                                                                                                      |
| 244 |   1008.462165 |    137.533078 | T. Michael Keesey                                                                                                                                                               |
| 245 |    103.975735 |    489.003874 | Margot Michaud                                                                                                                                                                  |
| 246 |    588.581871 |      9.356755 | Ignacio Contreras                                                                                                                                                               |
| 247 |    335.051016 |     73.583775 | Steven Coombs                                                                                                                                                                   |
| 248 |     87.968067 |     96.100286 | Ferran Sayol                                                                                                                                                                    |
| 249 |    321.272475 |      6.671214 | Jagged Fang Designs                                                                                                                                                             |
| 250 |    121.764370 |    695.087002 | Chris huh                                                                                                                                                                       |
| 251 |   1010.452681 |    673.752808 | Dinah Challen                                                                                                                                                                   |
| 252 |    676.317485 |    561.328925 | Scott Hartman                                                                                                                                                                   |
| 253 |   1008.535699 |     90.085624 | Ferran Sayol                                                                                                                                                                    |
| 254 |    797.619198 |     59.729669 | Shyamal                                                                                                                                                                         |
| 255 |    347.239064 |     49.360648 | Christoph Schomburg                                                                                                                                                             |
| 256 |     16.827053 |    189.675143 | Emma Hughes                                                                                                                                                                     |
| 257 |    242.246451 |    141.197175 | Robert Gay                                                                                                                                                                      |
| 258 |    704.271339 |    718.998868 | Ignacio Contreras                                                                                                                                                               |
| 259 |    315.670467 |    243.196520 | Jagged Fang Designs                                                                                                                                                             |
| 260 |    649.599160 |    742.635143 | Fernando Carezzano                                                                                                                                                              |
| 261 |    512.172024 |    456.568698 | M. Garfield & K. Anderson (modified by T. Michael Keesey)                                                                                                                       |
| 262 |    914.522705 |    658.413518 | Jagged Fang Designs                                                                                                                                                             |
| 263 |   1013.227635 |    287.652993 | Karina Garcia                                                                                                                                                                   |
| 264 |    367.824121 |     54.913051 | Gareth Monger                                                                                                                                                                   |
| 265 |    168.915084 |     12.348602 | Matt Crook                                                                                                                                                                      |
| 266 |    681.172357 |    324.404114 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 267 |    758.832213 |     50.444660 | Andy Wilson                                                                                                                                                                     |
| 268 |    679.877054 |     66.239836 | Scott Hartman                                                                                                                                                                   |
| 269 |    973.297296 |    613.814050 | Chris huh                                                                                                                                                                       |
| 270 |    651.271521 |    662.174042 | Roderic Page and Lois Page                                                                                                                                                      |
| 271 |    663.727409 |    165.562386 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                                    |
| 272 |    486.379268 |     61.811137 | Rebecca Groom                                                                                                                                                                   |
| 273 |    337.382985 |    537.192776 | Tasman Dixon                                                                                                                                                                    |
| 274 |     63.622544 |    550.709510 | Andrew A. Farke                                                                                                                                                                 |
| 275 |    996.984740 |    256.247348 | Kimberly Haddrell                                                                                                                                                               |
| 276 |    860.094816 |    678.101187 | Manabu Sakamoto                                                                                                                                                                 |
| 277 |     18.190137 |    553.348851 | M Kolmann                                                                                                                                                                       |
| 278 |    646.519134 |    676.405290 | Scott Hartman                                                                                                                                                                   |
| 279 |     23.814460 |    786.452480 | DW Bapst, modified from Ishitani et al. 2016                                                                                                                                    |
| 280 |    886.743807 |    409.274969 | Zimices                                                                                                                                                                         |
| 281 |     12.156106 |    263.682547 | NA                                                                                                                                                                              |
| 282 |    549.087975 |    173.009476 | NA                                                                                                                                                                              |
| 283 |    170.792746 |    110.120619 | Sidney Frederic Harmer, Arthur Everett Shipley (vectorized by Maxime Dahirel)                                                                                                   |
| 284 |    751.910371 |    304.404920 | Steven Traver                                                                                                                                                                   |
| 285 |    605.266703 |    531.319061 | Yan Wong                                                                                                                                                                        |
| 286 |    622.884296 |    422.384255 | Scott Hartman                                                                                                                                                                   |
| 287 |     10.848004 |    514.781249 | SecretJellyMan - from Mason McNair                                                                                                                                              |
| 288 |    221.777080 |    603.141313 | Matt Dempsey                                                                                                                                                                    |
| 289 |    735.959330 |    770.913067 | Steven Traver                                                                                                                                                                   |
| 290 |    819.398075 |     48.905462 | Todd Marshall, vectorized by Zimices                                                                                                                                            |
| 291 |     15.355743 |    605.554023 | Allison Pease                                                                                                                                                                   |
| 292 |    102.582037 |    312.720265 | Gareth Monger                                                                                                                                                                   |
| 293 |    735.803412 |     31.244762 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 294 |    309.490394 |    272.117394 | Markus A. Grohme                                                                                                                                                                |
| 295 |    409.909266 |     62.006250 | Zimices                                                                                                                                                                         |
| 296 |    438.326128 |    635.003837 | Joris van der Ham (vectorized by T. Michael Keesey)                                                                                                                             |
| 297 |    962.074339 |    167.301837 | Noah Schlottman                                                                                                                                                                 |
| 298 |    366.950355 |    646.760288 | Beth Reinke                                                                                                                                                                     |
| 299 |    579.872998 |    174.770902 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                                    |
| 300 |    467.041652 |    300.261430 | C. Camilo Julián-Caballero                                                                                                                                                      |
| 301 |   1007.326428 |    419.396442 | Margot Michaud                                                                                                                                                                  |
| 302 |    294.332566 |     41.894834 | Lukas Panzarin                                                                                                                                                                  |
| 303 |    323.612425 |    774.528272 | Mo Hassan                                                                                                                                                                       |
| 304 |   1002.034326 |     23.371253 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                               |
| 305 |    582.578717 |    767.747480 | Matt Crook                                                                                                                                                                      |
| 306 |    835.216166 |    395.719355 | Jack Mayer Wood                                                                                                                                                                 |
| 307 |    788.674855 |    346.977824 | Chris huh                                                                                                                                                                       |
| 308 |    362.575791 |    681.780334 | Chris Hay                                                                                                                                                                       |
| 309 |    802.809305 |    271.755634 | Roberto Díaz Sibaja                                                                                                                                                             |
| 310 |    683.847096 |    704.501090 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 311 |    101.553342 |    480.544770 | Diana Pomeroy                                                                                                                                                                   |
| 312 |    146.683898 |    545.435815 | Gareth Monger                                                                                                                                                                   |
| 313 |    855.694939 |    542.796781 | A. R. McCulloch (vectorized by T. Michael Keesey)                                                                                                                               |
| 314 |    922.695499 |     95.469544 | Nobu Tamura, vectorized by Zimices                                                                                                                                              |
| 315 |    705.714616 |    264.292903 | Matt Crook                                                                                                                                                                      |
| 316 |    908.086120 |    139.461603 | Dean Schnabel                                                                                                                                                                   |
| 317 |    708.137377 |     83.862309 | Kailah Thorn & Ben King                                                                                                                                                         |
| 318 |    468.893369 |    102.008322 | Gareth Monger                                                                                                                                                                   |
| 319 |    175.917201 |     80.400097 | Margot Michaud                                                                                                                                                                  |
| 320 |    144.291183 |    773.038784 | Margot Michaud                                                                                                                                                                  |
| 321 |    622.019111 |    655.409448 | T. Michael Keesey                                                                                                                                                               |
| 322 |    463.291754 |    773.709077 | Maija Karala                                                                                                                                                                    |
| 323 |    485.033490 |     38.094688 | Bruno C. Vellutini                                                                                                                                                              |
| 324 |     32.691457 |    591.280433 | Dean Schnabel                                                                                                                                                                   |
| 325 |    536.433823 |    503.608354 | John Gould (vectorized by T. Michael Keesey)                                                                                                                                    |
| 326 |    826.822994 |    776.545531 | Dean Schnabel                                                                                                                                                                   |
| 327 |    775.048027 |    650.692464 | xgirouxb                                                                                                                                                                        |
| 328 |    321.862891 |     25.609845 | Javier Luque                                                                                                                                                                    |
| 329 |   1014.006807 |    567.455935 | Joanna Wolfe                                                                                                                                                                    |
| 330 |    566.061333 |    406.744777 | Steven Traver                                                                                                                                                                   |
| 331 |    233.553661 |    112.663746 | Sarah Werning                                                                                                                                                                   |
| 332 |    601.356096 |    123.519935 | Gareth Monger                                                                                                                                                                   |
| 333 |    830.607647 |    657.682310 | Charles R. Knight, vectorized by Zimices                                                                                                                                        |
| 334 |    614.777544 |    286.452412 | Felix Vaux                                                                                                                                                                      |
| 335 |     91.300170 |    633.087596 | Zimices                                                                                                                                                                         |
| 336 |     62.135107 |    111.262253 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey)           |
| 337 |    764.810634 |    531.953967 | Tracy A. Heath                                                                                                                                                                  |
| 338 |    432.221985 |     59.505162 | Matt Crook                                                                                                                                                                      |
| 339 |    349.788872 |    294.753181 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                           |
| 340 |    191.915549 |     52.328636 | Alyssa Bell & Luis Chiappe 2015, dx.doi.org/10.1371/journal.pone.0141690                                                                                                        |
| 341 |    916.775030 |     64.112366 | Alexandre Vong                                                                                                                                                                  |
| 342 |    937.741622 |     16.406655 | Scott Hartman                                                                                                                                                                   |
| 343 |    847.849914 |    790.001031 | Zimices                                                                                                                                                                         |
| 344 |    715.235565 |    358.117598 | Javier Luque                                                                                                                                                                    |
| 345 |    705.520860 |    545.138141 | Anthony Caravaggi                                                                                                                                                               |
| 346 |    536.377116 |    379.732792 | Ferran Sayol                                                                                                                                                                    |
| 347 |    562.170102 |    655.762931 | Jose Carlos Arenas-Monroy                                                                                                                                                       |
| 348 |    290.743872 |    234.722243 | Tasman Dixon                                                                                                                                                                    |
| 349 |    477.459683 |    643.738288 | Zimices                                                                                                                                                                         |
| 350 |     86.453503 |    271.463313 | Margot Michaud                                                                                                                                                                  |
| 351 |    246.027457 |    665.613853 | Scott Hartman                                                                                                                                                                   |
| 352 |    654.062331 |    490.743936 | Margot Michaud                                                                                                                                                                  |
| 353 |    599.446079 |    501.376904 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey)           |
| 354 |    452.723357 |    260.206862 | Xavier Giroux-Bougard                                                                                                                                                           |
| 355 |   1004.566443 |    369.028329 | Oscar Sanisidro                                                                                                                                                                 |
| 356 |    191.809509 |    787.701619 | Steven Traver                                                                                                                                                                   |
| 357 |    582.715645 |     47.983508 | NA                                                                                                                                                                              |
| 358 |    733.504960 |    467.475908 | Steven Traver                                                                                                                                                                   |
| 359 |    959.903739 |    255.977566 | Margot Michaud                                                                                                                                                                  |
| 360 |    317.568373 |    361.900032 | NA                                                                                                                                                                              |
| 361 |     33.544676 |    411.485289 | Andrew A. Farke                                                                                                                                                                 |
| 362 |    767.870927 |    165.632266 | Ignacio Contreras                                                                                                                                                               |
| 363 |    968.120253 |      9.941256 | Smokeybjb                                                                                                                                                                       |
| 364 |    351.622256 |    630.444200 | T. Michael Keesey                                                                                                                                                               |
| 365 |     28.974240 |    646.756015 | Ghedoghedo, vectorized by Zimices                                                                                                                                               |
| 366 |    791.754548 |    513.334572 | Tod Robbins                                                                                                                                                                     |
| 367 |    659.319149 |    146.120497 | Harold N Eyster                                                                                                                                                                 |
| 368 |    958.758250 |    743.919502 | Scott Hartman                                                                                                                                                                   |
| 369 |    256.807430 |    589.216156 | Andy Wilson                                                                                                                                                                     |
| 370 |    325.854516 |    559.739964 | wsnaccad                                                                                                                                                                        |
| 371 |    576.960331 |    397.269529 | Maija Karala                                                                                                                                                                    |
| 372 |    944.750695 |    308.680408 | T. Michael Keesey                                                                                                                                                               |
| 373 |    120.275843 |    719.927302 | FunkMonk                                                                                                                                                                        |
| 374 |    540.405065 |    135.166897 | Steven Traver                                                                                                                                                                   |
| 375 |    110.285399 |    790.700675 | Walter Vladimir                                                                                                                                                                 |
| 376 |    506.823943 |      7.134816 | Tasman Dixon                                                                                                                                                                    |
| 377 |    798.993473 |    488.137676 | S.Martini                                                                                                                                                                       |
| 378 |    236.396256 |     87.247441 | Zimices                                                                                                                                                                         |
| 379 |    527.314031 |    731.695392 | Andy Wilson                                                                                                                                                                     |
| 380 |     62.380777 |     76.261402 | Conty (vectorized by T. Michael Keesey)                                                                                                                                         |
| 381 |    787.026601 |    541.410982 | Duane Raver (vectorized by T. Michael Keesey)                                                                                                                                   |
| 382 |    820.186337 |     38.872262 | Roberto Díaz Sibaja                                                                                                                                                             |
| 383 |    892.704051 |    280.449912 | Jagged Fang Designs                                                                                                                                                             |
| 384 |   1000.878450 |    313.227386 | Lisa M. “Pixxl” (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                 |
| 385 |    471.543301 |    740.116961 | Matt Dempsey                                                                                                                                                                    |
| 386 |    655.939382 |    597.950232 | Christine Axon                                                                                                                                                                  |
| 387 |    410.326592 |    127.906983 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                                    |
| 388 |     17.611068 |    585.689516 | Felix Vaux                                                                                                                                                                      |
| 389 |    228.144092 |    395.112167 | Jagged Fang Designs                                                                                                                                                             |
| 390 |    711.679102 |    448.796170 | Emily Willoughby                                                                                                                                                                |
| 391 |    201.461603 |    284.468700 | Chris A. Hamilton                                                                                                                                                               |
| 392 |     95.737400 |    215.659496 | Markus A. Grohme                                                                                                                                                                |
| 393 |    647.572310 |    561.419911 | T. Michael Keesey (after James & al.)                                                                                                                                           |
| 394 |     46.979322 |    334.438063 | Tyler Greenfield and Scott Hartman                                                                                                                                              |
| 395 |    375.471703 |    697.403968 | Michelle Site                                                                                                                                                                   |
| 396 |    666.526545 |    792.250561 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                                |
| 397 |    593.626751 |     39.615803 | Gareth Monger                                                                                                                                                                   |
| 398 |    869.271794 |    272.261918 | Walter Vladimir                                                                                                                                                                 |
| 399 |    670.280535 |    306.080274 | C. Camilo Julián-Caballero                                                                                                                                                      |
| 400 |    215.376267 |    172.431443 | Ferran Sayol                                                                                                                                                                    |
| 401 |    342.711830 |    411.628967 | Andy Wilson                                                                                                                                                                     |
| 402 |    106.634949 |    416.281685 | Markus A. Grohme                                                                                                                                                                |
| 403 |    617.472584 |    145.747599 | T. Michael Keesey                                                                                                                                                               |
| 404 |    807.239860 |    681.265084 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 405 |    935.292403 |    618.205385 | NA                                                                                                                                                                              |
| 406 |    672.928805 |    125.368026 | Ignacio Contreras                                                                                                                                                               |
| 407 |    232.243905 |     71.310264 | Tony Ayling                                                                                                                                                                     |
| 408 |    451.608685 |     21.681030 | Henry Lydecker                                                                                                                                                                  |
| 409 |    397.922768 |    727.373588 | NA                                                                                                                                                                              |
| 410 |     21.394802 |    281.317618 | Matt Crook                                                                                                                                                                      |
| 411 |    882.353357 |    220.655295 | John Curtis (vectorized by T. Michael Keesey)                                                                                                                                   |
| 412 |    346.603607 |    350.128515 | T. Michael Keesey                                                                                                                                                               |
| 413 |    193.840433 |    407.377542 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                                         |
| 414 |     76.278887 |    561.126139 | Scott Hartman                                                                                                                                                                   |
| 415 |    578.069748 |    466.386666 | Matt Crook                                                                                                                                                                      |
| 416 |    549.846259 |    510.965976 | Konsta Happonen                                                                                                                                                                 |
| 417 |    773.676559 |    294.899124 | Conty (vectorized by T. Michael Keesey)                                                                                                                                         |
| 418 |    811.792642 |    549.294490 | Mathieu Basille                                                                                                                                                                 |
| 419 |    416.603111 |    310.003298 | Zimices                                                                                                                                                                         |
| 420 |    256.431434 |     29.416344 | T. Michael Keesey                                                                                                                                                               |
| 421 |    156.901758 |    411.396187 | Smokeybjb                                                                                                                                                                       |
| 422 |    321.137333 |    714.877599 | Steven Coombs                                                                                                                                                                   |
| 423 |    273.873016 |    277.937171 | NA                                                                                                                                                                              |
| 424 |    545.457206 |    339.939429 | Nobu Tamura                                                                                                                                                                     |
| 425 |     90.894297 |    471.085692 | Chris huh                                                                                                                                                                       |
| 426 |    595.215725 |    741.979225 | Gareth Monger                                                                                                                                                                   |
| 427 |     15.395993 |    744.281007 | Pete Buchholz                                                                                                                                                                   |
| 428 |    345.572933 |    592.804503 | Emily Willoughby                                                                                                                                                                |
| 429 |    227.407357 |    592.158110 | Kamil S. Jaron                                                                                                                                                                  |
| 430 |    509.965123 |    123.368180 | Diana Pomeroy                                                                                                                                                                   |
| 431 |    573.643993 |     64.909786 | Nobu Tamura, vectorized by Zimices                                                                                                                                              |
| 432 |    904.924704 |    350.283068 | Matt Crook                                                                                                                                                                      |
| 433 |    333.039841 |    525.498365 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                                   |
| 434 |    834.745071 |    357.685217 | Dean Schnabel                                                                                                                                                                   |
| 435 |    606.295649 |    720.007861 | Gustav Mützel                                                                                                                                                                   |
| 436 |    916.383104 |    728.071939 | Tyler Greenfield                                                                                                                                                                |
| 437 |     78.170133 |    494.788995 | Ferran Sayol                                                                                                                                                                    |
| 438 |    807.961890 |    118.037232 | Felix Vaux                                                                                                                                                                      |
| 439 |    817.084331 |    260.476204 | Gareth Monger                                                                                                                                                                   |
| 440 |    429.322322 |    400.071158 | Matt Crook                                                                                                                                                                      |
| 441 |    977.508432 |    281.326302 | Ferran Sayol                                                                                                                                                                    |
| 442 |    741.498595 |    662.732167 | Noah Schlottman, photo by Casey Dunn                                                                                                                                            |
| 443 |    189.579954 |    704.113319 | Henry Lydecker                                                                                                                                                                  |
| 444 |   1008.213042 |    628.997372 | Matt Crook                                                                                                                                                                      |
| 445 |    150.439691 |    385.014955 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                                |
| 446 |    755.256462 |    632.189322 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                                   |
| 447 |    839.566945 |     54.851330 | Chris huh                                                                                                                                                                       |
| 448 |    754.869590 |    284.947258 | Yan Wong from wikipedia drawing (PD: Pearson Scott Foresman)                                                                                                                    |
| 449 |     13.365225 |    331.386672 | Alexandre Vong                                                                                                                                                                  |
| 450 |     63.222962 |    787.896977 | James R. Spotila and Ray Chatterji                                                                                                                                              |
| 451 |     35.631371 |    173.607860 | Benchill                                                                                                                                                                        |
| 452 |    262.335623 |    758.066594 | david maas / dave hone                                                                                                                                                          |
| 453 |    808.844637 |    469.990914 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                                 |
| 454 |     80.499887 |    701.354134 | NA                                                                                                                                                                              |
| 455 |    512.769980 |    260.808020 | Chris huh                                                                                                                                                                       |
| 456 |    546.187785 |      7.476140 | Ignacio Contreras                                                                                                                                                               |
| 457 |    873.438213 |    623.470978 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 458 |    718.023137 |    794.295336 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                            |
| 459 |    234.155425 |    196.392790 | Tracy A. Heath                                                                                                                                                                  |
| 460 |    834.599455 |    303.992862 | Scott Hartman                                                                                                                                                                   |
| 461 |    958.855329 |    785.102910 | Jagged Fang Designs                                                                                                                                                             |
| 462 |     51.817083 |    134.892907 | Cesar Julian                                                                                                                                                                    |
| 463 |    724.382786 |     66.003968 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 464 |    579.314138 |    160.606995 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 465 |    121.290508 |    328.509336 | Jagged Fang Designs                                                                                                                                                             |
| 466 |    801.866034 |    311.419868 | Conty (vectorized by T. Michael Keesey)                                                                                                                                         |
| 467 |      8.088829 |    147.689061 | Ferran Sayol                                                                                                                                                                    |
| 468 |    747.935448 |    742.831282 | Gareth Monger                                                                                                                                                                   |
| 469 |    352.297778 |      7.587684 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 470 |    536.423939 |    106.225347 | Michael P. Taylor                                                                                                                                                               |
| 471 |    632.025587 |     58.023172 | Chris huh                                                                                                                                                                       |
| 472 |    121.681101 |    586.911298 | Scott Hartman                                                                                                                                                                   |
| 473 |    746.977148 |    729.588311 | Scott Hartman                                                                                                                                                                   |
| 474 |    267.621799 |    731.487027 | Cagri Cevrim                                                                                                                                                                    |
| 475 |    426.189765 |      4.995066 | Jaime Headden                                                                                                                                                                   |
| 476 |    687.992368 |     80.510378 | Scott Hartman                                                                                                                                                                   |
| 477 |    509.166312 |    377.910575 | G. M. Woodward                                                                                                                                                                  |
| 478 |    443.968149 |    624.593406 | David Orr                                                                                                                                                                       |
| 479 |     84.975536 |    694.356267 | Smokeybjb                                                                                                                                                                       |
| 480 |    521.240352 |    210.220152 | NA                                                                                                                                                                              |
| 481 |    973.684963 |    446.943903 | Mark Miller                                                                                                                                                                     |
| 482 |    390.734139 |    245.338870 | Scott Reid                                                                                                                                                                      |
| 483 |    379.910289 |    160.939120 | Ignacio Contreras                                                                                                                                                               |
| 484 |     87.764260 |    545.359058 | Heinrich Harder (vectorized by T. Michael Keesey)                                                                                                                               |
| 485 |    291.373625 |    209.310958 | Jagged Fang Designs                                                                                                                                                             |
| 486 |    215.039103 |    672.989313 | Scott Hartman                                                                                                                                                                   |
| 487 |    374.607086 |    663.661267 | Melissa Broussard                                                                                                                                                               |
| 488 |    515.395844 |     29.373204 | Markus A. Grohme                                                                                                                                                                |
| 489 |     19.331691 |      4.274461 | Chris huh                                                                                                                                                                       |
| 490 |    222.377896 |    791.913714 | Dean Schnabel                                                                                                                                                                   |
| 491 |    790.393154 |    663.552337 | Carlos Cano-Barbacil                                                                                                                                                            |
| 492 |    983.698748 |    760.235834 | FunkMonk                                                                                                                                                                        |
| 493 |   1014.784973 |    663.193314 | FJDegrange                                                                                                                                                                      |
| 494 |    986.621418 |    745.169418 | Kent Elson Sorgon                                                                                                                                                               |
| 495 |    697.292204 |    131.388908 | Margot Michaud                                                                                                                                                                  |
| 496 |     15.519288 |    376.573705 | Ignacio Contreras                                                                                                                                                               |
| 497 |    107.079837 |    423.996371 | Scott Hartman                                                                                                                                                                   |
| 498 |    704.100828 |    485.870638 | Fernando Carezzano                                                                                                                                                              |
| 499 |    877.329892 |    791.260459 | Gareth Monger                                                                                                                                                                   |
| 500 |    278.695275 |    246.728205 | Zimices                                                                                                                                                                         |
| 501 |    378.936139 |    416.589572 | Zimices                                                                                                                                                                         |
| 502 |    672.843253 |    399.361878 | Joris van der Ham (vectorized by T. Michael Keesey)                                                                                                                             |
| 503 |    122.465714 |    133.957354 | Shyamal                                                                                                                                                                         |

    #> Your tweet has been posted!
