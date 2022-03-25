
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

Chris huh, E. D. Cope (modified by T. Michael Keesey, Michael P. Taylor
& Matthew J. Wedel), Markus A. Grohme, Scott D. Sampson, Mark A. Loewen,
Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith,
Alan L. Titus, Christina N. Hodson, Emily Jane McTavish, from
<http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>,
Kai R. Caspar, Robert Bruce Horsfall, from W.B. Scott’s 1912 “A History
of Land Mammals in the Western Hemisphere”, Scott Hartman, Tom Tarrant
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Verdilak, Jagged Fang Designs, Katie S. Collins, Gabriela
Palomo-Munoz, Andrew A. Farke, Caleb M. Brown, Xavier Giroux-Bougard,
Steven Traver, Eduard Solà (vectorized by T. Michael Keesey), Matt
Crook, Tasman Dixon, Roberto Díaz Sibaja, Sarah Werning, Aviceda
(vectorized by T. Michael Keesey), Alex Slavenko, Zimices, Mali’o Kodis,
photograph by Hans Hillewaert, Amanda Katzer, Melissa Broussard, Margot
Michaud, C. Camilo Julián-Caballero, L. Shyamal, Marie-Aimée Allard,
Andy Wilson, Sherman F. Denton via rawpixel.com (illustration) and
Timothy J. Bartley (silhouette), Jesús Gómez, vectorized by Zimices,
Tauana J. Cunha, Ferran Sayol, Ignacio Contreras, Skye McDavid, T.
Michael Keesey, Martien Brand (original photo), Renato Santos (vector
silhouette), Nobu Tamura (vectorized by T. Michael Keesey), Matt
Martyniuk, Shyamal, T. Michael Keesey (from a photo by Maximilian
Paradiz), Juan Carlos Jerí, Carlos Cano-Barbacil, Moussa Direct
Ltd. (photography) and T. Michael Keesey (vectorization), Dmitry
Bogdanov (vectorized by T. Michael Keesey), Gareth Monger, Brian Swartz
(vectorized by T. Michael Keesey), Brockhaus and Efron, Matt Dempsey,
Maxime Dahirel, Ricardo N. Martinez & Oscar A. Alcober, Maija Karala,
Obsidian Soul (vectorized by T. Michael Keesey), Jebulon (vectorized by
T. Michael Keesey), Cristian Osorio & Paula Carrera, Proyecto Carnivoros
Australes (www.carnivorosaustrales.org), Renata F. Martins, Sharon
Wegner-Larsen, SauropodomorphMonarch, Jakovche, Nobu Tamura, vectorized
by Zimices, Frank Förster (based on a picture by Jerry Kirkhart;
modified by T. Michael Keesey), FJDegrange, Felix Vaux, Joschua Knüppe,
Jose Carlos Arenas-Monroy, Birgit Lang, Anthony Caravaggi, David Sim
(photograph) and T. Michael Keesey (vectorization), Dmitry Bogdanov,
Michael Scroggie, Michelle Site, Chase Brownstein, B. Duygu Özpolat,
Sergio A. Muñoz-Gómez, Collin Gross, Mario Quevedo, Original drawing by
Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja, Robbie N. Cada
(modified by T. Michael Keesey), Gopal Murali, Erika Schumacher, Yan
Wong, Jean-Raphaël Guillaumin (photography) and T. Michael Keesey
(vectorization), Arthur Weasley (vectorized by T. Michael Keesey),
Lukasiniho, xgirouxb, Smokeybjb (vectorized by T. Michael Keesey),
Robert Bruce Horsfall, vectorized by Zimices, Lankester Edwin Ray
(vectorized by T. Michael Keesey), Henry Lydecker, Nobu Tamura
(vectorized by A. Verrière), Beth Reinke, Cesar Julian, Neil Kelley,
Pete Buchholz, John Conway, Birgit Lang, based on a photo by D. Sikes,
Sean McCann, Keith Murdock (photo), John E. McCormack, Michael G.
Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb
T. Brumfield & T. Michael Keesey, Iain Reid, Noah Schlottman, photo by
Casey Dunn, Jack Mayer Wood, Nobu Tamura (modified by T. Michael
Keesey), Bruno Maggia, H. Filhol (vectorized by T. Michael Keesey),
Andrew A. Farke, modified from original by Robert Bruce Horsfall, from
Scott 1912, Kanchi Nanjo, Javier Luque & Sarah Gerken, Noah Schlottman,
Danielle Alba, Alexander Schmidt-Lebuhn, Terpsichores, Lee Harding
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Martin R. Smith, FunkMonk, Yan Wong from wikipedia drawing (PD:
Pearson Scott Foresman), Kamil S. Jaron, Martin Kevil, Dein Freund der
Baum (vectorized by T. Michael Keesey), David Orr, Charles Doolittle
Walcott (vectorized by T. Michael Keesey), ArtFavor & annaleeblysse, Sam
Droege (photography) and T. Michael Keesey (vectorization), John Curtis
(vectorized by T. Michael Keesey), Rebecca Groom, Mason McNair, Steven
Coombs, Patrick Strutzenberger, Rene Martin, Mo Hassan, Scott Hartman
(modified by T. Michael Keesey), Crystal Maier, Julio Garza, Danny
Cicchetti (vectorized by T. Michael Keesey), NOAA Great Lakes
Environmental Research Laboratory (illustration) and Timothy J. Bartley
(silhouette), White Wolf, M Hutchinson, Hans Hillewaert (vectorized by
T. Michael Keesey), Francesca Belem Lopes Palmeira, Robbie Cada
(vectorized by T. Michael Keesey), Tim Bertelink (modified by T. Michael
Keesey), www.studiospectre.com, Mali’o Kodis, photograph from Jersabek
et al, 2003, Armin Reindl, Joanna Wolfe, Emily Willoughby, Ieuan Jones,
Dmitry Bogdanov and FunkMonk (vectorized by T. Michael Keesey),
Smokeybjb, Dexter R. Mardis, Pollyanna von Knorring and T. Michael
Keesey, U.S. National Park Service (vectorized by William Gearty),
Myriam\_Ramirez, Madeleine Price Ball, Michele M Tobias, Arthur Grosset
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Chris Hay, François Michonneau, T. Michael Keesey (after
Tillyard), Dianne Bray / Museum Victoria (vectorized by T. Michael
Keesey), Darren Naish (vectorize by T. Michael Keesey), Ellen Edmonson
(illustration) and Timothy J. Bartley (silhouette), FunkMonk \[Michael
B.H.\] (modified by T. Michael Keesey), Tracy A. Heath, Jaime Headden,
DW Bapst, modified from Figure 1 of Belanger (2011, PALAIOS)., T.
Michael Keesey (photo by Sean Mack), Robbie N. Cada (vectorized by T.
Michael Keesey), Ghedoghedo (vectorized by T. Michael Keesey), M.
Antonio Todaro, Tobias Kånneby, Matteo Dal Zotto, and Ulf Jondelius
(vectorized by T. Michael Keesey), Oscar Sanisidro, Chuanixn Yu, Roderic
Page and Lois Page, Scott Reid, Mike Hanson, Dean Schnabel, New York
Zoological Society, Mali’o Kodis, image from the Smithsonian
Institution, Raven Amos, Pranav Iyer (grey ideas), Noah Schlottman,
photo from Casey Dunn, Agnello Picorelli, Yan Wong from drawing by
Joseph Smit, Kimberly Haddrell, Ludwik Gasiorowski, Tyler Greenfield,
Mike Keesey (vectorization) and Vaibhavcho (photography), Geoff Shaw,
Siobhon Egan, Michael Scroggie, from original photograph by Gary M.
Stolz, USFWS (original photograph in public domain)., Michael B. H.
(vectorized by T. Michael Keesey), Matt Martyniuk (vectorized by T.
Michael Keesey)

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                         |
| --: | ------------: | ------------: | :------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    806.209631 |    194.439745 | Chris huh                                                                                                                                                      |
|   2 |    267.576193 |    685.289108 | E. D. Cope (modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel)                                                                               |
|   3 |    597.773517 |    351.839106 | Markus A. Grohme                                                                                                                                               |
|   4 |    333.319542 |    525.773566 | Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus                                       |
|   5 |    384.478260 |    204.104011 | Christina N. Hodson                                                                                                                                            |
|   6 |    194.925848 |    352.897469 | Emily Jane McTavish, from <http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>                                                    |
|   7 |    817.198314 |    715.460326 | Kai R. Caspar                                                                                                                                                  |
|   8 |    514.134316 |     55.647127 | Robert Bruce Horsfall, from W.B. Scott’s 1912 “A History of Land Mammals in the Western Hemisphere”                                                            |
|   9 |    924.092571 |    228.601929 | Scott Hartman                                                                                                                                                  |
|  10 |    583.248214 |    589.352748 | Tom Tarrant (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey    |
|  11 |    555.011224 |    243.576436 | Verdilak                                                                                                                                                       |
|  12 |    390.187430 |    291.487481 | Jagged Fang Designs                                                                                                                                            |
|  13 |    558.895863 |    442.717587 | Katie S. Collins                                                                                                                                               |
|  14 |     67.592019 |    282.974486 | Gabriela Palomo-Munoz                                                                                                                                          |
|  15 |    887.478715 |    270.171171 | Chris huh                                                                                                                                                      |
|  16 |    834.874843 |    548.768765 | Andrew A. Farke                                                                                                                                                |
|  17 |    359.661230 |     37.907003 | Scott Hartman                                                                                                                                                  |
|  18 |    273.005110 |    163.931191 | Caleb M. Brown                                                                                                                                                 |
|  19 |    400.790299 |    383.789302 | Xavier Giroux-Bougard                                                                                                                                          |
|  20 |    666.093420 |    141.571686 | Steven Traver                                                                                                                                                  |
|  21 |    411.015426 |    727.756282 | Eduard Solà (vectorized by T. Michael Keesey)                                                                                                                  |
|  22 |    240.239255 |    622.957109 | Markus A. Grohme                                                                                                                                               |
|  23 |    835.199733 |     83.206047 | Matt Crook                                                                                                                                                     |
|  24 |    342.799647 |    766.209499 | Tasman Dixon                                                                                                                                                   |
|  25 |    894.670700 |    780.097764 | Roberto Díaz Sibaja                                                                                                                                            |
|  26 |    821.257727 |    346.012081 | Jagged Fang Designs                                                                                                                                            |
|  27 |    772.908280 |    506.936140 | Sarah Werning                                                                                                                                                  |
|  28 |    435.617317 |    541.143093 | Aviceda (vectorized by T. Michael Keesey)                                                                                                                      |
|  29 |    159.821765 |    757.312701 | Alex Slavenko                                                                                                                                                  |
|  30 |     72.800420 |    144.873629 | Zimices                                                                                                                                                        |
|  31 |    914.579419 |    399.722454 | Mali’o Kodis, photograph by Hans Hillewaert                                                                                                                    |
|  32 |    920.057239 |    641.464896 | Amanda Katzer                                                                                                                                                  |
|  33 |    100.359403 |    580.051897 | Melissa Broussard                                                                                                                                              |
|  34 |    802.424241 |    246.825087 | Margot Michaud                                                                                                                                                 |
|  35 |    947.439204 |    678.621309 | C. Camilo Julián-Caballero                                                                                                                                     |
|  36 |    129.486021 |    103.272526 | L. Shyamal                                                                                                                                                     |
|  37 |    933.226401 |    514.727591 | Marie-Aimée Allard                                                                                                                                             |
|  38 |    678.770978 |    664.831575 | Andy Wilson                                                                                                                                                    |
|  39 |    956.543500 |    139.205149 | Sherman F. Denton via rawpixel.com (illustration) and Timothy J. Bartley (silhouette)                                                                          |
|  40 |    705.204952 |    432.027716 | Jesús Gómez, vectorized by Zimices                                                                                                                             |
|  41 |    589.780602 |    743.108642 | Tauana J. Cunha                                                                                                                                                |
|  42 |    471.001689 |    191.431168 | Ferran Sayol                                                                                                                                                   |
|  43 |    950.214115 |     80.016662 | NA                                                                                                                                                             |
|  44 |    157.203658 |    179.052699 | Chris huh                                                                                                                                                      |
|  45 |    308.904193 |    659.927438 | Ignacio Contreras                                                                                                                                              |
|  46 |     73.226624 |    415.156130 | NA                                                                                                                                                             |
|  47 |    297.274516 |    375.863694 | Skye McDavid                                                                                                                                                   |
|  48 |    257.431882 |     96.282432 | Melissa Broussard                                                                                                                                              |
|  49 |    665.344965 |     36.519797 | NA                                                                                                                                                             |
|  50 |    386.669886 |    105.033134 | T. Michael Keesey                                                                                                                                              |
|  51 |    560.135763 |    535.135318 | Steven Traver                                                                                                                                                  |
|  52 |    669.152143 |    268.431315 | Martien Brand (original photo), Renato Santos (vector silhouette)                                                                                              |
|  53 |    240.037423 |    712.272464 | T. Michael Keesey                                                                                                                                              |
|  54 |    285.420681 |    216.498645 | Roberto Díaz Sibaja                                                                                                                                            |
|  55 |    413.583343 |    643.756389 | Matt Crook                                                                                                                                                     |
|  56 |    936.733632 |    325.062106 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
|  57 |     71.764681 |    775.422413 | Jagged Fang Designs                                                                                                                                            |
|  58 |    747.321586 |    759.959903 | Matt Martyniuk                                                                                                                                                 |
|  59 |    937.880647 |    592.974548 | Shyamal                                                                                                                                                        |
|  60 |    442.930994 |    148.429920 | T. Michael Keesey (from a photo by Maximilian Paradiz)                                                                                                         |
|  61 |    819.316126 |    425.076856 | Juan Carlos Jerí                                                                                                                                               |
|  62 |    176.463344 |    230.641101 | Margot Michaud                                                                                                                                                 |
|  63 |    101.513858 |    477.248150 | Carlos Cano-Barbacil                                                                                                                                           |
|  64 |    107.913522 |    695.472433 | Jagged Fang Designs                                                                                                                                            |
|  65 |    272.129932 |    460.237891 | Carlos Cano-Barbacil                                                                                                                                           |
|  66 |    225.736313 |    667.455397 | Roberto Díaz Sibaja                                                                                                                                            |
|  67 |    755.961729 |     63.268748 | Moussa Direct Ltd. (photography) and T. Michael Keesey (vectorization)                                                                                         |
|  68 |    822.421248 |    665.400333 | Jagged Fang Designs                                                                                                                                            |
|  69 |    943.200187 |    751.371647 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
|  70 |    285.108295 |    262.143281 | Tasman Dixon                                                                                                                                                   |
|  71 |    959.167590 |     33.945479 | Gareth Monger                                                                                                                                                  |
|  72 |     90.742905 |    342.490544 | Brian Swartz (vectorized by T. Michael Keesey)                                                                                                                 |
|  73 |    203.185514 |    557.746644 | Brockhaus and Efron                                                                                                                                            |
|  74 |    268.924219 |     23.483963 | Tasman Dixon                                                                                                                                                   |
|  75 |    394.610004 |    459.392845 | Matt Dempsey                                                                                                                                                   |
|  76 |    728.988963 |    623.933858 | Gareth Monger                                                                                                                                                  |
|  77 |   1002.807764 |    418.142323 | T. Michael Keesey                                                                                                                                              |
|  78 |    733.795028 |    308.585119 | Jagged Fang Designs                                                                                                                                            |
|  79 |    479.334286 |    295.738142 | Maxime Dahirel                                                                                                                                                 |
|  80 |     86.438895 |     47.401529 | Jagged Fang Designs                                                                                                                                            |
|  81 |    776.702760 |    393.265713 | Markus A. Grohme                                                                                                                                               |
|  82 |     95.383158 |      9.383809 | Jagged Fang Designs                                                                                                                                            |
|  83 |    620.556849 |    664.651504 | Margot Michaud                                                                                                                                                 |
|  84 |     61.008040 |    217.959980 | Ricardo N. Martinez & Oscar A. Alcober                                                                                                                         |
|  85 |    739.555696 |    355.358255 | Maija Karala                                                                                                                                                   |
|  86 |    899.539699 |    119.021461 | Zimices                                                                                                                                                        |
|  87 |    898.058070 |    697.407802 | Jagged Fang Designs                                                                                                                                            |
|  88 |    882.916686 |    464.671822 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                |
|  89 |    496.861588 |    390.210486 | Steven Traver                                                                                                                                                  |
|  90 |    462.537860 |    751.184431 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
|  91 |     38.360652 |    514.370599 | Chris huh                                                                                                                                                      |
|  92 |    663.422685 |    475.564451 | Kai R. Caspar                                                                                                                                                  |
|  93 |    973.001310 |     61.577805 | Gabriela Palomo-Munoz                                                                                                                                          |
|  94 |    575.159502 |    115.192006 | Jebulon (vectorized by T. Michael Keesey)                                                                                                                      |
|  95 |     54.732142 |     93.349062 | Ferran Sayol                                                                                                                                                   |
|  96 |    516.266260 |    615.166131 | Shyamal                                                                                                                                                        |
|  97 |    693.862211 |    585.331939 | Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org)                                                                   |
|  98 |    222.087830 |    695.430628 | Gareth Monger                                                                                                                                                  |
|  99 |    951.281921 |    185.857945 | Renata F. Martins                                                                                                                                              |
| 100 |    400.573253 |     77.075937 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 101 |    467.265221 |    578.312944 | NA                                                                                                                                                             |
| 102 |    521.663743 |    123.035993 | Steven Traver                                                                                                                                                  |
| 103 |    143.812545 |    274.243789 | Scott Hartman                                                                                                                                                  |
| 104 |    275.109335 |    588.016102 | Ignacio Contreras                                                                                                                                              |
| 105 |    359.104301 |    488.002396 | Tauana J. Cunha                                                                                                                                                |
| 106 |    767.838172 |    587.235266 | Gabriela Palomo-Munoz                                                                                                                                          |
| 107 |     20.181808 |    607.504404 | Sharon Wegner-Larsen                                                                                                                                           |
| 108 |    237.857567 |    504.049504 | Gabriela Palomo-Munoz                                                                                                                                          |
| 109 |     97.084966 |    223.494366 | Tasman Dixon                                                                                                                                                   |
| 110 |    488.030074 |    717.456417 | Katie S. Collins                                                                                                                                               |
| 111 |    962.312122 |    206.956880 | SauropodomorphMonarch                                                                                                                                          |
| 112 |    545.623838 |    162.389063 | Gareth Monger                                                                                                                                                  |
| 113 |     43.177819 |    635.923572 | Zimices                                                                                                                                                        |
| 114 |    104.335234 |    374.303186 | Jakovche                                                                                                                                                       |
| 115 |    365.953170 |    317.764298 | Nobu Tamura, vectorized by Zimices                                                                                                                             |
| 116 |    109.917474 |    666.099176 | Zimices                                                                                                                                                        |
| 117 |     18.285112 |    735.362984 | Frank Förster (based on a picture by Jerry Kirkhart; modified by T. Michael Keesey)                                                                            |
| 118 |    169.511464 |     57.288863 | Andy Wilson                                                                                                                                                    |
| 119 |    250.314694 |    549.891105 | FJDegrange                                                                                                                                                     |
| 120 |    844.587777 |    789.784956 | Felix Vaux                                                                                                                                                     |
| 121 |    338.790973 |    442.348164 | NA                                                                                                                                                             |
| 122 |    150.378825 |    253.701391 | Joschua Knüppe                                                                                                                                                 |
| 123 |    680.720617 |    368.673521 | Jose Carlos Arenas-Monroy                                                                                                                                      |
| 124 |    224.979342 |    789.997418 | Birgit Lang                                                                                                                                                    |
| 125 |    402.670891 |    754.355135 | Caleb M. Brown                                                                                                                                                 |
| 126 |    805.878766 |    625.114367 | Anthony Caravaggi                                                                                                                                              |
| 127 |    515.598681 |    369.206854 | David Sim (photograph) and T. Michael Keesey (vectorization)                                                                                                   |
| 128 |    988.196657 |    251.321781 | Sarah Werning                                                                                                                                                  |
| 129 |    230.982946 |     69.086023 | Jagged Fang Designs                                                                                                                                            |
| 130 |    469.238309 |    462.113943 | T. Michael Keesey                                                                                                                                              |
| 131 |     82.504468 |    745.213837 | Dmitry Bogdanov                                                                                                                                                |
| 132 |    427.013100 |    493.496460 | Chris huh                                                                                                                                                      |
| 133 |    654.020064 |     90.038751 | Michael Scroggie                                                                                                                                               |
| 134 |     28.920878 |    174.739880 | Felix Vaux                                                                                                                                                     |
| 135 |    691.657048 |     89.560997 | Michelle Site                                                                                                                                                  |
| 136 |    883.137531 |    556.324917 | Felix Vaux                                                                                                                                                     |
| 137 |    353.900654 |    131.204165 | Andrew A. Farke                                                                                                                                                |
| 138 |    772.369741 |    150.894504 | Chase Brownstein                                                                                                                                               |
| 139 |    988.373171 |    704.902632 | Gabriela Palomo-Munoz                                                                                                                                          |
| 140 |    295.749439 |    295.956931 | Zimices                                                                                                                                                        |
| 141 |    999.714941 |    538.761181 | B. Duygu Özpolat                                                                                                                                               |
| 142 |    376.729807 |     57.454466 | Ignacio Contreras                                                                                                                                              |
| 143 |    367.862442 |    332.829359 | Scott Hartman                                                                                                                                                  |
| 144 |    541.538757 |     12.475418 | Zimices                                                                                                                                                        |
| 145 |    842.603547 |    622.591945 | Sergio A. Muñoz-Gómez                                                                                                                                          |
| 146 |    695.410876 |    543.225198 | Collin Gross                                                                                                                                                   |
| 147 |    681.334241 |    558.833036 | Mario Quevedo                                                                                                                                                  |
| 148 |    700.311311 |    382.490989 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                         |
| 149 |    798.424493 |    775.689861 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                                 |
| 150 |    228.211883 |     30.208323 | Gopal Murali                                                                                                                                                   |
| 151 |    542.919091 |    514.165322 | Margot Michaud                                                                                                                                                 |
| 152 |    333.673779 |    721.834370 | Katie S. Collins                                                                                                                                               |
| 153 |    147.748522 |    661.915109 | Steven Traver                                                                                                                                                  |
| 154 |    518.035654 |    498.441265 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 155 |    190.611362 |    459.476769 | Erika Schumacher                                                                                                                                               |
| 156 |    164.975801 |    116.179090 | C. Camilo Julián-Caballero                                                                                                                                     |
| 157 |    432.848357 |    700.747040 | Zimices                                                                                                                                                        |
| 158 |    965.777162 |    445.809569 | Scott Hartman                                                                                                                                                  |
| 159 |    234.918942 |    436.275140 | Yan Wong                                                                                                                                                       |
| 160 |    688.330413 |    494.437739 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 161 |    879.339206 |    447.414873 | Nobu Tamura, vectorized by Zimices                                                                                                                             |
| 162 |    674.629564 |    396.985777 | Markus A. Grohme                                                                                                                                               |
| 163 |    718.962132 |    722.754965 | Margot Michaud                                                                                                                                                 |
| 164 |    857.632549 |    140.521840 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 165 |    457.512533 |    421.028835 | Jean-Raphaël Guillaumin (photography) and T. Michael Keesey (vectorization)                                                                                    |
| 166 |    735.888443 |     16.604676 | Gareth Monger                                                                                                                                                  |
| 167 |    246.278632 |    334.077708 | Sarah Werning                                                                                                                                                  |
| 168 |    950.069780 |    418.092743 | Matt Crook                                                                                                                                                     |
| 169 |    765.328440 |    728.688086 | Arthur Weasley (vectorized by T. Michael Keesey)                                                                                                               |
| 170 |    957.795561 |    706.077782 | Gareth Monger                                                                                                                                                  |
| 171 |    309.797998 |     53.250622 | Lukasiniho                                                                                                                                                     |
| 172 |     17.961255 |    192.716184 | NA                                                                                                                                                             |
| 173 |    945.067776 |    291.197281 | NA                                                                                                                                                             |
| 174 |    404.893179 |     17.285654 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 175 |     99.139317 |    170.090736 | xgirouxb                                                                                                                                                       |
| 176 |    321.046823 |    637.760490 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                    |
| 177 |    514.993663 |    759.858096 | Gareth Monger                                                                                                                                                  |
| 178 |    122.570984 |    295.213026 | Zimices                                                                                                                                                        |
| 179 |    131.270772 |    497.126257 | Margot Michaud                                                                                                                                                 |
| 180 |    151.315919 |     12.015650 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                   |
| 181 |    472.023154 |    668.277453 | Birgit Lang                                                                                                                                                    |
| 182 |    193.324507 |    115.701222 | Chris huh                                                                                                                                                      |
| 183 |    484.886395 |    539.914699 | Markus A. Grohme                                                                                                                                               |
| 184 |    410.732347 |    243.789323 | Margot Michaud                                                                                                                                                 |
| 185 |    190.982515 |    143.542210 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                          |
| 186 |     31.388359 |    324.535241 | Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org)                                                                   |
| 187 |    613.896929 |    495.357231 | Michelle Site                                                                                                                                                  |
| 188 |    579.574810 |     46.066477 | Henry Lydecker                                                                                                                                                 |
| 189 |    111.790557 |    392.674753 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                        |
| 190 |    280.357099 |    312.419303 | Beth Reinke                                                                                                                                                    |
| 191 |    899.507060 |    427.135477 | Gabriela Palomo-Munoz                                                                                                                                          |
| 192 |    141.401645 |    318.165256 | Cesar Julian                                                                                                                                                   |
| 193 |    639.578139 |    205.904927 | Scott Hartman                                                                                                                                                  |
| 194 |    574.776644 |     11.427577 | Neil Kelley                                                                                                                                                    |
| 195 |    970.762056 |    275.280707 | Scott Hartman                                                                                                                                                  |
| 196 |    615.786027 |     63.693954 | Chris huh                                                                                                                                                      |
| 197 |    992.190486 |    613.180083 | Pete Buchholz                                                                                                                                                  |
| 198 |    194.270596 |    478.853993 | John Conway                                                                                                                                                    |
| 199 |    216.032241 |    763.650620 | Markus A. Grohme                                                                                                                                               |
| 200 |    104.486262 |    723.661256 | Maija Karala                                                                                                                                                   |
| 201 |    370.977333 |     14.498320 | Zimices                                                                                                                                                        |
| 202 |    908.969614 |     15.351122 | Tasman Dixon                                                                                                                                                   |
| 203 |    561.283429 |    334.594942 | Tauana J. Cunha                                                                                                                                                |
| 204 |    405.360535 |    274.875229 | Birgit Lang, based on a photo by D. Sikes                                                                                                                      |
| 205 |    329.169977 |    171.875248 | Sean McCann                                                                                                                                                    |
| 206 |     13.030646 |     47.631717 | Keith Murdock (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey  |
| 207 |     17.348501 |    673.723838 | Birgit Lang                                                                                                                                                    |
| 208 |    371.494483 |    547.543543 | Gabriela Palomo-Munoz                                                                                                                                          |
| 209 |    403.314044 |    479.646303 | Iain Reid                                                                                                                                                      |
| 210 |    379.831958 |    134.658231 | Matt Crook                                                                                                                                                     |
| 211 |    864.652213 |    750.219927 | Zimices                                                                                                                                                        |
| 212 |    656.219498 |    383.369555 | Scott Hartman                                                                                                                                                  |
| 213 |    111.726891 |     19.510298 | Margot Michaud                                                                                                                                                 |
| 214 |    331.959302 |     70.381125 | Noah Schlottman, photo by Casey Dunn                                                                                                                           |
| 215 |    709.145410 |     74.275784 | Chris huh                                                                                                                                                      |
| 216 |    471.360795 |    778.533829 | Ferran Sayol                                                                                                                                                   |
| 217 |    582.591142 |    294.840400 | Jack Mayer Wood                                                                                                                                                |
| 218 |    620.058471 |    319.292262 | Matt Crook                                                                                                                                                     |
| 219 |    295.033357 |    130.674135 | Gareth Monger                                                                                                                                                  |
| 220 |    996.908067 |    211.726449 | T. Michael Keesey                                                                                                                                              |
| 221 |    436.556117 |     14.336903 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                    |
| 222 |    186.471191 |    516.897452 | L. Shyamal                                                                                                                                                     |
| 223 |    622.263714 |    220.443158 | Bruno Maggia                                                                                                                                                   |
| 224 |    856.786942 |    294.987671 | Margot Michaud                                                                                                                                                 |
| 225 |    446.533607 |    404.094175 | Matt Crook                                                                                                                                                     |
| 226 |    979.015060 |    103.900806 | Erika Schumacher                                                                                                                                               |
| 227 |    618.664327 |    269.653933 | Tauana J. Cunha                                                                                                                                                |
| 228 |    849.399257 |    245.035693 | H. Filhol (vectorized by T. Michael Keesey)                                                                                                                    |
| 229 |     82.050604 |    441.808358 | Sergio A. Muñoz-Gómez                                                                                                                                          |
| 230 |     20.943306 |    123.076339 | Zimices                                                                                                                                                        |
| 231 |    753.987137 |    634.505896 | Andrew A. Farke, modified from original by Robert Bruce Horsfall, from Scott 1912                                                                              |
| 232 |   1001.027090 |    270.089442 | Kanchi Nanjo                                                                                                                                                   |
| 233 |     43.651412 |    528.300775 | Maija Karala                                                                                                                                                   |
| 234 |    810.101965 |    755.932428 | Javier Luque & Sarah Gerken                                                                                                                                    |
| 235 |    195.339561 |     21.481332 | Noah Schlottman                                                                                                                                                |
| 236 |    847.179168 |    332.365120 | Tasman Dixon                                                                                                                                                   |
| 237 |    450.904041 |     46.748987 | Birgit Lang                                                                                                                                                    |
| 238 |    798.152763 |    378.007742 | C. Camilo Julián-Caballero                                                                                                                                     |
| 239 |    276.574453 |     45.741638 | Cesar Julian                                                                                                                                                   |
| 240 |    361.347739 |    785.942226 | Danielle Alba                                                                                                                                                  |
| 241 |    575.125852 |    572.316245 | Jagged Fang Designs                                                                                                                                            |
| 242 |    538.203504 |    303.936699 | Alexander Schmidt-Lebuhn                                                                                                                                       |
| 243 |    446.410322 |    258.078162 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                          |
| 244 |    598.303497 |     80.147004 | Alexander Schmidt-Lebuhn                                                                                                                                       |
| 245 |    703.871362 |    458.282136 | Terpsichores                                                                                                                                                   |
| 246 |     17.243247 |    470.271396 | Lee Harding (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey    |
| 247 |     94.344688 |     98.006170 | Ignacio Contreras                                                                                                                                              |
| 248 |    711.608522 |    697.725068 | Martin R. Smith                                                                                                                                                |
| 249 |    574.162106 |    315.128953 | Jagged Fang Designs                                                                                                                                            |
| 250 |    537.537833 |    789.619694 | FunkMonk                                                                                                                                                       |
| 251 |    786.707103 |      3.854731 | Chris huh                                                                                                                                                      |
| 252 |    849.889611 |    761.168370 | Zimices                                                                                                                                                        |
| 253 |    743.682969 |    787.569469 | Andy Wilson                                                                                                                                                    |
| 254 |    977.516167 |    571.407421 | Yan Wong from wikipedia drawing (PD: Pearson Scott Foresman)                                                                                                   |
| 255 |    306.609136 |    330.091760 | Kamil S. Jaron                                                                                                                                                 |
| 256 |    939.758248 |    106.277138 | Zimices                                                                                                                                                        |
| 257 |    155.348379 |    216.049061 | Martin Kevil                                                                                                                                                   |
| 258 |    894.708153 |    292.094218 | Dein Freund der Baum (vectorized by T. Michael Keesey)                                                                                                         |
| 259 |    793.625519 |     19.517705 | Maija Karala                                                                                                                                                   |
| 260 |    587.220366 |    152.714894 | Zimices                                                                                                                                                        |
| 261 |    768.876698 |    532.724751 | C. Camilo Julián-Caballero                                                                                                                                     |
| 262 |   1004.298198 |    290.546133 | Chris huh                                                                                                                                                      |
| 263 |    971.409616 |    726.343254 | Ferran Sayol                                                                                                                                                   |
| 264 |    399.996414 |    350.533262 | Matt Crook                                                                                                                                                     |
| 265 |    173.027648 |    154.128093 | Margot Michaud                                                                                                                                                 |
| 266 |    467.219990 |     15.121646 | David Orr                                                                                                                                                      |
| 267 |    146.323148 |    518.921335 | Matt Crook                                                                                                                                                     |
| 268 |    335.344990 |    122.371798 | Scott Hartman                                                                                                                                                  |
| 269 |    646.379710 |    233.645977 | Charles Doolittle Walcott (vectorized by T. Michael Keesey)                                                                                                    |
| 270 |    215.176868 |    156.816754 | Margot Michaud                                                                                                                                                 |
| 271 |    480.076163 |    637.745862 | Andy Wilson                                                                                                                                                    |
| 272 |    956.563187 |    380.183111 | ArtFavor & annaleeblysse                                                                                                                                       |
| 273 |    380.188176 |    614.041880 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 274 |    628.324928 |    421.441641 | Sam Droege (photography) and T. Michael Keesey (vectorization)                                                                                                 |
| 275 |    833.270564 |    375.811680 | John Curtis (vectorized by T. Michael Keesey)                                                                                                                  |
| 276 |     92.743687 |    106.154511 | Markus A. Grohme                                                                                                                                               |
| 277 |    434.406359 |    593.985560 | Amanda Katzer                                                                                                                                                  |
| 278 |    975.545524 |    396.324685 | Chris huh                                                                                                                                                      |
| 279 |    181.849233 |    680.649169 | Melissa Broussard                                                                                                                                              |
| 280 |    719.344452 |    269.659434 | Rebecca Groom                                                                                                                                                  |
| 281 |   1016.468998 |    198.029384 | Kanchi Nanjo                                                                                                                                                   |
| 282 |    951.896655 |    650.327105 | Zimices                                                                                                                                                        |
| 283 |    664.421019 |    772.254527 | NA                                                                                                                                                             |
| 284 |    505.904165 |    276.603221 | Mason McNair                                                                                                                                                   |
| 285 |    284.579232 |    342.795319 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 286 |    797.819734 |     52.833889 | Steven Coombs                                                                                                                                                  |
| 287 |    302.432122 |    276.336087 | Patrick Strutzenberger                                                                                                                                         |
| 288 |     71.710193 |    501.614645 | Anthony Caravaggi                                                                                                                                              |
| 289 |     15.512107 |    787.411245 | Gareth Monger                                                                                                                                                  |
| 290 |    513.897882 |    581.208223 | Margot Michaud                                                                                                                                                 |
| 291 |    417.694829 |    587.019094 | John Conway                                                                                                                                                    |
| 292 |     41.653679 |    708.649254 | Zimices                                                                                                                                                        |
| 293 |    133.495955 |    402.910547 | Zimices                                                                                                                                                        |
| 294 |    440.405205 |     78.842025 | Matt Crook                                                                                                                                                     |
| 295 |    319.033357 |    107.262464 | Shyamal                                                                                                                                                        |
| 296 |    719.732377 |    242.213120 | Zimices                                                                                                                                                        |
| 297 |    656.252424 |    795.101389 | Markus A. Grohme                                                                                                                                               |
| 298 |    333.483665 |    581.094198 | Sarah Werning                                                                                                                                                  |
| 299 |    630.639498 |    250.236931 | Zimices                                                                                                                                                        |
| 300 |    991.784131 |    306.061477 | Rene Martin                                                                                                                                                    |
| 301 |    494.540179 |    433.550526 | T. Michael Keesey (from a photo by Maximilian Paradiz)                                                                                                         |
| 302 |    885.735926 |     24.485988 | Ignacio Contreras                                                                                                                                              |
| 303 |    246.416965 |    768.926245 | Mo Hassan                                                                                                                                                      |
| 304 |    419.469050 |    744.149599 | Scott Hartman (modified by T. Michael Keesey)                                                                                                                  |
| 305 |   1009.980497 |    497.926407 | Crystal Maier                                                                                                                                                  |
| 306 |    495.172919 |    777.495954 | Margot Michaud                                                                                                                                                 |
| 307 |    710.247526 |    194.614960 | Julio Garza                                                                                                                                                    |
| 308 |    138.976175 |    367.686985 | Neil Kelley                                                                                                                                                    |
| 309 |     12.545735 |    493.524788 | T. Michael Keesey                                                                                                                                              |
| 310 |    410.500072 |    697.860021 | Scott Hartman                                                                                                                                                  |
| 311 |    942.244098 |    164.814818 | Danny Cicchetti (vectorized by T. Michael Keesey)                                                                                                              |
| 312 |     86.943759 |    791.628730 | Markus A. Grohme                                                                                                                                               |
| 313 |     11.274088 |    580.975825 | Gareth Monger                                                                                                                                                  |
| 314 |    807.372937 |    149.680455 | Alexander Schmidt-Lebuhn                                                                                                                                       |
| 315 |    432.347956 |    786.262703 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                          |
| 316 |    530.117027 |     91.807126 | White Wolf                                                                                                                                                     |
| 317 |    554.026053 |    388.671895 | Tasman Dixon                                                                                                                                                   |
| 318 |    517.992348 |     73.511109 | Jack Mayer Wood                                                                                                                                                |
| 319 |    130.780906 |    197.635019 | Steven Traver                                                                                                                                                  |
| 320 |    812.461134 |    534.933288 | Sean McCann                                                                                                                                                    |
| 321 |    822.590094 |     30.433837 | Roberto Díaz Sibaja                                                                                                                                            |
| 322 |    764.764872 |    409.629615 | Alex Slavenko                                                                                                                                                  |
| 323 |    320.836527 |    673.308596 | Margot Michaud                                                                                                                                                 |
| 324 |    986.288157 |    344.186358 | M Hutchinson                                                                                                                                                   |
| 325 |   1010.710919 |    672.784307 | Rebecca Groom                                                                                                                                                  |
| 326 |    520.777668 |    402.681895 | Matt Crook                                                                                                                                                     |
| 327 |    662.570588 |    603.460157 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                              |
| 328 |    278.240007 |    431.267639 | Juan Carlos Jerí                                                                                                                                               |
| 329 |    904.393888 |    189.476787 | Francesca Belem Lopes Palmeira                                                                                                                                 |
| 330 |    496.236573 |    767.111077 | Andy Wilson                                                                                                                                                    |
| 331 |    675.430699 |    737.108365 | Birgit Lang                                                                                                                                                    |
| 332 |    580.541388 |    177.307505 | Felix Vaux                                                                                                                                                     |
| 333 |     43.035958 |    664.550782 | Robbie Cada (vectorized by T. Michael Keesey)                                                                                                                  |
| 334 |    437.984161 |    309.950685 | Tim Bertelink (modified by T. Michael Keesey)                                                                                                                  |
| 335 |    627.367408 |    394.485698 | Jagged Fang Designs                                                                                                                                            |
| 336 |    512.416880 |    708.733320 | Zimices                                                                                                                                                        |
| 337 |    847.696329 |    672.272927 | Margot Michaud                                                                                                                                                 |
| 338 |    365.424457 |    582.878457 | Gareth Monger                                                                                                                                                  |
| 339 |    450.646848 |    282.927579 | www.studiospectre.com                                                                                                                                          |
| 340 |    367.053498 |    701.653866 | Tasman Dixon                                                                                                                                                   |
| 341 |    900.733258 |     56.599425 | Margot Michaud                                                                                                                                                 |
| 342 |    815.533440 |    309.369182 | Katie S. Collins                                                                                                                                               |
| 343 |    546.551668 |    321.690142 | Nobu Tamura, vectorized by Zimices                                                                                                                             |
| 344 |    860.691621 |    204.500519 | Mali’o Kodis, photograph from Jersabek et al, 2003                                                                                                             |
| 345 |    999.225574 |    125.737470 | Maija Karala                                                                                                                                                   |
| 346 |   1000.468824 |    633.831354 | Xavier Giroux-Bougard                                                                                                                                          |
| 347 |    414.525899 |    137.267056 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 348 |     43.400038 |    736.513891 | Armin Reindl                                                                                                                                                   |
| 349 |   1006.653485 |    749.022961 | Gareth Monger                                                                                                                                                  |
| 350 |     58.403285 |    609.736095 | xgirouxb                                                                                                                                                       |
| 351 |    220.643127 |    129.903348 | Kamil S. Jaron                                                                                                                                                 |
| 352 |    277.364568 |    515.788477 | Birgit Lang                                                                                                                                                    |
| 353 |    773.763857 |    298.273686 | Markus A. Grohme                                                                                                                                               |
| 354 |    495.016219 |    525.503959 | Zimices                                                                                                                                                        |
| 355 |    764.352550 |    456.938652 | Zimices                                                                                                                                                        |
| 356 |    570.156133 |    162.670622 | Gabriela Palomo-Munoz                                                                                                                                          |
| 357 |    954.141696 |    465.106032 | T. Michael Keesey                                                                                                                                              |
| 358 |    903.085452 |    456.784129 | Steven Traver                                                                                                                                                  |
| 359 |    973.132436 |    658.570839 | Jagged Fang Designs                                                                                                                                            |
| 360 |    170.651912 |    695.131294 | Shyamal                                                                                                                                                        |
| 361 |    443.534372 |    388.862942 | Joanna Wolfe                                                                                                                                                   |
| 362 |    289.915485 |     67.962050 | Gabriela Palomo-Munoz                                                                                                                                          |
| 363 |    499.187900 |    364.177548 | Emily Willoughby                                                                                                                                               |
| 364 |     52.445727 |    180.503577 | Scott Hartman                                                                                                                                                  |
| 365 |    437.772125 |    473.827600 | Emily Willoughby                                                                                                                                               |
| 366 |    741.840503 |    135.193494 | Ieuan Jones                                                                                                                                                    |
| 367 |    688.300360 |    202.827887 | Gareth Monger                                                                                                                                                  |
| 368 |    311.365380 |    702.253297 | Zimices                                                                                                                                                        |
| 369 |    205.387619 |    654.596251 | Jagged Fang Designs                                                                                                                                            |
| 370 |    538.979429 |    572.956822 | Steven Traver                                                                                                                                                  |
| 371 |    748.171647 |    157.869202 | Matt Crook                                                                                                                                                     |
| 372 |    767.465070 |    209.728356 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 373 |    459.632009 |    353.299017 | Matt Martyniuk                                                                                                                                                 |
| 374 |    870.394902 |    613.297420 | Henry Lydecker                                                                                                                                                 |
| 375 |    869.219022 |    480.714928 | Dmitry Bogdanov and FunkMonk (vectorized by T. Michael Keesey)                                                                                                 |
| 376 |    432.083961 |     34.808630 | Scott Hartman                                                                                                                                                  |
| 377 |    445.351219 |    680.471864 | Maija Karala                                                                                                                                                   |
| 378 |    439.075368 |     66.698172 | Beth Reinke                                                                                                                                                    |
| 379 |    767.570641 |    673.909635 | Gabriela Palomo-Munoz                                                                                                                                          |
| 380 |    208.402527 |    743.748483 | Maija Karala                                                                                                                                                   |
| 381 |     24.272704 |    455.204424 | Margot Michaud                                                                                                                                                 |
| 382 |    202.413357 |    201.808413 | Smokeybjb                                                                                                                                                      |
| 383 |    350.211975 |    270.797723 | Zimices                                                                                                                                                        |
| 384 |    168.821660 |    497.955363 | Steven Traver                                                                                                                                                  |
| 385 |    798.908903 |    282.497640 | Gareth Monger                                                                                                                                                  |
| 386 |    266.793898 |    338.307631 | Joanna Wolfe                                                                                                                                                   |
| 387 |     26.834644 |    445.210388 | Dexter R. Mardis                                                                                                                                               |
| 388 |    234.383708 |    185.730287 | Steven Traver                                                                                                                                                  |
| 389 |    883.464355 |    666.326755 | Renata F. Martins                                                                                                                                              |
| 390 |    745.470646 |    226.517126 | Pollyanna von Knorring and T. Michael Keesey                                                                                                                   |
| 391 |    741.217369 |    551.240243 | Steven Traver                                                                                                                                                  |
| 392 |    241.133056 |    571.405392 | U.S. National Park Service (vectorized by William Gearty)                                                                                                      |
| 393 |      7.458948 |    151.430836 | Myriam\_Ramirez                                                                                                                                                |
| 394 |    620.999695 |     10.131315 | Madeleine Price Ball                                                                                                                                           |
| 395 |    886.740720 |    709.924466 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 396 |    367.785494 |    345.809844 | Felix Vaux                                                                                                                                                     |
| 397 |    448.355327 |    372.770875 | NA                                                                                                                                                             |
| 398 |    882.332199 |    411.781521 | Michele M Tobias                                                                                                                                               |
| 399 |    839.782507 |    483.886351 | C. Camilo Julián-Caballero                                                                                                                                     |
| 400 |    288.734793 |    719.003292 | Matt Crook                                                                                                                                                     |
| 401 |    144.870465 |    676.139539 | Margot Michaud                                                                                                                                                 |
| 402 |    675.289208 |    318.336462 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 403 |    493.102797 |    734.381070 | Tasman Dixon                                                                                                                                                   |
| 404 |     86.369730 |    190.951866 | Arthur Grosset (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
| 405 |     31.782850 |    266.425123 | Chris Hay                                                                                                                                                      |
| 406 |    284.791453 |    325.482709 | Jagged Fang Designs                                                                                                                                            |
| 407 |    335.277519 |    317.997128 | Jagged Fang Designs                                                                                                                                            |
| 408 |     37.515369 |     50.351331 | François Michonneau                                                                                                                                            |
| 409 |    299.346982 |    222.003379 | Markus A. Grohme                                                                                                                                               |
| 410 |    534.631393 |    696.831100 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 411 |     54.120107 |    445.360414 | T. Michael Keesey (after Tillyard)                                                                                                                             |
| 412 |    470.100071 |    559.615739 | T. Michael Keesey                                                                                                                                              |
| 413 |    604.014874 |    409.298787 | Jagged Fang Designs                                                                                                                                            |
| 414 |     70.143560 |     89.940548 | C. Camilo Julián-Caballero                                                                                                                                     |
| 415 |    591.311120 |    333.113988 | Gabriela Palomo-Munoz                                                                                                                                          |
| 416 |    776.315070 |    137.118878 | Dianne Bray / Museum Victoria (vectorized by T. Michael Keesey)                                                                                                |
| 417 |    882.311796 |    104.611940 | Chris huh                                                                                                                                                      |
| 418 |    739.371963 |    335.824118 | Joanna Wolfe                                                                                                                                                   |
| 419 |    141.970690 |     29.507965 | Andrew A. Farke                                                                                                                                                |
| 420 |    687.218951 |    770.687740 | Sarah Werning                                                                                                                                                  |
| 421 |    954.007825 |    256.842832 | Maija Karala                                                                                                                                                   |
| 422 |   1005.528126 |    584.812975 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                  |
| 423 |    785.608937 |    794.099399 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                              |
| 424 |    188.611667 |    793.534686 | Kai R. Caspar                                                                                                                                                  |
| 425 |    336.142238 |    433.952744 | Margot Michaud                                                                                                                                                 |
| 426 |    494.172483 |    576.283582 | FunkMonk \[Michael B.H.\] (modified by T. Michael Keesey)                                                                                                      |
| 427 |    939.195614 |    392.657083 | Tracy A. Heath                                                                                                                                                 |
| 428 |     74.398471 |    658.441172 | Sharon Wegner-Larsen                                                                                                                                           |
| 429 |    502.801539 |     10.816585 | Jaime Headden                                                                                                                                                  |
| 430 |    815.394619 |    785.979211 | T. Michael Keesey                                                                                                                                              |
| 431 |    480.497361 |    688.019096 | Ferran Sayol                                                                                                                                                   |
| 432 |    388.115213 |    508.079052 | Margot Michaud                                                                                                                                                 |
| 433 |    495.446279 |    466.436987 | NA                                                                                                                                                             |
| 434 |    168.894691 |    132.219492 | Margot Michaud                                                                                                                                                 |
| 435 |    451.255821 |    120.541107 | Matt Crook                                                                                                                                                     |
| 436 |    943.880155 |    563.994144 | Zimices                                                                                                                                                        |
| 437 |    420.979506 |    207.176828 | Ferran Sayol                                                                                                                                                   |
| 438 |    838.355068 |     12.843749 | Zimices                                                                                                                                                        |
| 439 |    457.205106 |    235.214379 | Zimices                                                                                                                                                        |
| 440 |    166.326623 |    461.372096 | DW Bapst, modified from Figure 1 of Belanger (2011, PALAIOS).                                                                                                  |
| 441 |     16.871757 |    242.521082 | T. Michael Keesey (photo by Sean Mack)                                                                                                                         |
| 442 |     81.722331 |    242.287742 | Steven Traver                                                                                                                                                  |
| 443 |    904.528933 |    156.383924 | Zimices                                                                                                                                                        |
| 444 |    982.246334 |    794.538077 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                               |
| 445 |    947.488840 |      5.251969 | T. Michael Keesey                                                                                                                                              |
| 446 |    238.762251 |    600.701463 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                   |
| 447 |     13.651718 |     93.692933 | Felix Vaux                                                                                                                                                     |
| 448 |    876.771831 |    641.362991 | Sarah Werning                                                                                                                                                  |
| 449 |    630.005979 |    690.807930 | Scott Hartman                                                                                                                                                  |
| 450 |    970.242648 |    787.627838 | Chris huh                                                                                                                                                      |
| 451 |    910.680804 |      6.854512 | Gabriela Palomo-Munoz                                                                                                                                          |
| 452 |    790.258283 |    607.418480 | Zimices                                                                                                                                                        |
| 453 |    395.016760 |    788.744007 | M. Antonio Todaro, Tobias Kånneby, Matteo Dal Zotto, and Ulf Jondelius (vectorized by T. Michael Keesey)                                                       |
| 454 |   1015.917144 |    316.929820 | NA                                                                                                                                                             |
| 455 |    461.437759 |    704.332515 | Tasman Dixon                                                                                                                                                   |
| 456 |    858.252725 |    599.941832 | Oscar Sanisidro                                                                                                                                                |
| 457 |    558.222511 |    678.291985 | Markus A. Grohme                                                                                                                                               |
| 458 |    938.744904 |    794.381609 | NA                                                                                                                                                             |
| 459 |    308.699582 |    571.864451 | Chuanixn Yu                                                                                                                                                    |
| 460 |    714.004169 |    635.554988 | L. Shyamal                                                                                                                                                     |
| 461 |    343.588268 |    499.263819 | Markus A. Grohme                                                                                                                                               |
| 462 |    586.783219 |    506.583737 | Ignacio Contreras                                                                                                                                              |
| 463 |    260.038506 |    726.404059 | Chris huh                                                                                                                                                      |
| 464 |    161.227879 |    715.503922 | Matt Martyniuk                                                                                                                                                 |
| 465 |    215.366107 |    616.604698 | Rebecca Groom                                                                                                                                                  |
| 466 |    460.338959 |     96.416197 | Jaime Headden                                                                                                                                                  |
| 467 |    564.735262 |    137.908651 | Birgit Lang                                                                                                                                                    |
| 468 |    214.039002 |     54.776687 | Roderic Page and Lois Page                                                                                                                                     |
| 469 |    716.081771 |     94.992618 | Scott Hartman                                                                                                                                                  |
| 470 |    695.793297 |    507.059684 | Scott Reid                                                                                                                                                     |
| 471 |    581.935695 |     27.518790 | Steven Traver                                                                                                                                                  |
| 472 |    708.581683 |    481.713997 | Margot Michaud                                                                                                                                                 |
| 473 |    876.896064 |    313.040667 | Yan Wong                                                                                                                                                       |
| 474 |    424.933126 |     93.801687 | Mike Hanson                                                                                                                                                    |
| 475 |    291.078348 |    144.351553 | Markus A. Grohme                                                                                                                                               |
| 476 |    855.733991 |    320.492206 | Chris huh                                                                                                                                                      |
| 477 |     25.958053 |    357.117860 | Margot Michaud                                                                                                                                                 |
| 478 |    338.215472 |    593.542723 | Birgit Lang                                                                                                                                                    |
| 479 |    657.594828 |    740.886029 | Dean Schnabel                                                                                                                                                  |
| 480 |    398.297171 |    321.578009 | Tracy A. Heath                                                                                                                                                 |
| 481 |    702.422010 |    361.514968 | T. Michael Keesey                                                                                                                                              |
| 482 |    350.376850 |    746.435984 | Ieuan Jones                                                                                                                                                    |
| 483 |    388.976412 |    156.453850 | Kamil S. Jaron                                                                                                                                                 |
| 484 |    839.502601 |    331.275428 | New York Zoological Society                                                                                                                                    |
| 485 |    429.814369 |    567.832066 | Mali’o Kodis, image from the Smithsonian Institution                                                                                                           |
| 486 |    584.002822 |    394.612876 | Raven Amos                                                                                                                                                     |
| 487 |    762.933512 |    621.595750 | Tasman Dixon                                                                                                                                                   |
| 488 |    877.895100 |    766.506958 | Tasman Dixon                                                                                                                                                   |
| 489 |    622.967335 |    487.130875 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                   |
| 490 |    143.406041 |    789.550635 | Zimices                                                                                                                                                        |
| 491 |    493.897169 |     19.322029 | Scott Hartman                                                                                                                                                  |
| 492 |    931.448090 |    713.077353 | Chris huh                                                                                                                                                      |
| 493 |    390.744944 |    271.680860 | Pranav Iyer (grey ideas)                                                                                                                                       |
| 494 |    796.277082 |    156.522915 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 495 |    790.329077 |     41.971747 | Zimices                                                                                                                                                        |
| 496 |    868.351291 |    456.655802 | Scott Hartman                                                                                                                                                  |
| 497 |    101.183996 |    458.417412 | Tasman Dixon                                                                                                                                                   |
| 498 |    166.501913 |    538.365403 | Noah Schlottman, photo from Casey Dunn                                                                                                                         |
| 499 |    879.986763 |     10.147394 | Tasman Dixon                                                                                                                                                   |
| 500 |   1016.689185 |    760.458115 | Agnello Picorelli                                                                                                                                              |
| 501 |    657.306419 |    650.941103 | Yan Wong from drawing by Joseph Smit                                                                                                                           |
| 502 |     37.671021 |     14.868958 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                |
| 503 |    331.893973 |     12.015909 | Alex Slavenko                                                                                                                                                  |
| 504 |    441.302440 |    442.646865 | Kimberly Haddrell                                                                                                                                              |
| 505 |    249.795565 |    688.526219 | Jagged Fang Designs                                                                                                                                            |
| 506 |    147.685251 |    449.968613 | Ludwik Gasiorowski                                                                                                                                             |
| 507 |    580.006138 |    494.964862 | Steven Traver                                                                                                                                                  |
| 508 |    340.263124 |    626.089387 | Jose Carlos Arenas-Monroy                                                                                                                                      |
| 509 |    519.759127 |    306.521552 | Scott Hartman                                                                                                                                                  |
| 510 |    965.737755 |    367.148822 | Jagged Fang Designs                                                                                                                                            |
| 511 |    152.780874 |    607.320695 | Tyler Greenfield                                                                                                                                               |
| 512 |    242.871191 |    735.142131 | Joanna Wolfe                                                                                                                                                   |
| 513 |    792.265556 |    525.714230 | Jack Mayer Wood                                                                                                                                                |
| 514 |    514.863496 |    594.972145 | Maija Karala                                                                                                                                                   |
| 515 |    314.718270 |    345.920296 | Mike Keesey (vectorization) and Vaibhavcho (photography)                                                                                                       |
| 516 |    618.438442 |    290.783000 | Geoff Shaw                                                                                                                                                     |
| 517 |   1006.834408 |    356.469174 | Jagged Fang Designs                                                                                                                                            |
| 518 |    804.868154 |    454.399615 | Siobhon Egan                                                                                                                                                   |
| 519 |    969.079913 |     89.592680 | Gabriela Palomo-Munoz                                                                                                                                          |
| 520 |    452.813368 |    774.938029 | L. Shyamal                                                                                                                                                     |
| 521 |    172.680558 |    607.056690 | Kamil S. Jaron                                                                                                                                                 |
| 522 |     27.216929 |    533.517357 | Scott Hartman                                                                                                                                                  |
| 523 |    987.334586 |     94.569285 | E. D. Cope (modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel)                                                                               |
| 524 |    861.309782 |    682.156629 | T. Michael Keesey                                                                                                                                              |
| 525 |    989.864327 |    557.435878 | Steven Traver                                                                                                                                                  |
| 526 |    520.225726 |    167.442599 | Michael Scroggie, from original photograph by Gary M. Stolz, USFWS (original photograph in public domain).                                                     |
| 527 |    757.057496 |    685.361277 | Cesar Julian                                                                                                                                                   |
| 528 |     68.137104 |    729.096871 | NA                                                                                                                                                             |
| 529 |    125.093875 |    701.988403 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 530 |     30.527444 |      4.803989 | Michelle Site                                                                                                                                                  |
| 531 |    680.082301 |    193.183245 | Michael B. H. (vectorized by T. Michael Keesey)                                                                                                                |
| 532 |    262.398095 |    321.131377 | Caleb M. Brown                                                                                                                                                 |
| 533 |    256.668135 |     55.428295 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                               |
| 534 |    910.739683 |    574.499688 | Scott Hartman                                                                                                                                                  |

    #> Your tweet has been posted!
