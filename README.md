
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

Jagged Fang Designs, xgirouxb, Zimices, Maky (vectorization), Gabriella
Skollar (photography), Rebecca Lewis (editing), Mali’o Kodis, image from
Brockhaus and Efron Encyclopedic Dictionary, Falconaumanni and T.
Michael Keesey, Oscar Sanisidro, Andy Wilson, Yan Wong from drawing by
Joseph Smit, Emily Willoughby, Taro Maeda, Kailah Thorn & Mark
Hutchinson, Alex Slavenko, FunkMonk (Michael B.H.; vectorized by T.
Michael Keesey), Lani Mohan, Javiera Constanzo, Armin Reindl, Collin
Gross, Ingo Braasch, Margot Michaud, Christoph Schomburg, Matt Crook, T.
Michael Keesey (vectorization); Thorsten Assmann, Jörn Buse, Claudia
Drees, Ariel-Leib-Leonid Friedman, Tal Levanony, Andrea Matern, Anika
Timm, and David W. Wrase (photography), Mathew Wedel, Gareth Monger,
Nobu Tamura, vectorized by Zimices, Alexandre Vong, Ieuan Jones, Scott
Hartman, Joshua Fowler, David Orr, Tasman Dixon, Ferran Sayol, Kenneth
Lacovara (vectorized by T. Michael Keesey), Manabu Bessho-Uehara,
Gabriela Palomo-Munoz, Becky Barnes, H. F. O. March (modified by T.
Michael Keesey, Michael P. Taylor & Matthew J. Wedel), Steven Traver,
Julia B McHugh, Markus A. Grohme, Tyler McCraney, Felix Vaux, Kamil S.
Jaron, Steven Coombs, Chris huh, T. Michael Keesey, James R. Spotila and
Ray Chatterji, Taenadoman, , Tyler Greenfield, Iain Reid, Caleb M.
Brown, Christopher Watson (photo) and T. Michael Keesey (vectorization),
Dexter R. Mardis, Dave Souza (vectorized by T. Michael Keesey), Pete
Buchholz, Dmitry Bogdanov (vectorized by T. Michael Keesey), Hanyong Pu,
Yoshitsugu Kobayashi, Junchang Lü, Li Xu, Yanhua Wu, Huali Chang, Jiming
Zhang, Songhai Jia & T. Michael Keesey, Ignacio Contreras, Joanna Wolfe,
Rebecca Groom, Melissa Broussard, Nobu Tamura (vectorized by T. Michael
Keesey), V. Deepak, Kai R. Caspar, Mali’o Kodis, photograph from
Jersabek et al, 2003, Jiekun He, Michael Day, Mathilde Cordellier, Hugo
Gruson, Mali’o Kodis, image from the Smithsonian Institution, Hans
Hillewaert (vectorized by T. Michael Keesey), Obsidian Soul (vectorized
by T. Michael Keesey), Harold N Eyster, Lukasiniho, Eyal Bartov,
AnAgnosticGod (vectorized by T. Michael Keesey), (unknown), Lukas
Panzarin (vectorized by T. Michael Keesey), Maija Karala, Robert Gay, T.
Tischler, Andrew Farke and Joseph Sertich, Jaime Headden, Rainer Schoch,
Louis Ranjard, Matthew E. Clapham, Richard Lampitt, Jeremy Young / NHM
(vectorization by Yan Wong), Sarah Werning, Mali’o Kodis, photograph by
“Wildcat Dunny” (<http://www.flickr.com/people/wildcat_dunny/>),
Jonathan Wells, Tony Ayling (vectorized by T. Michael Keesey), Roberto
Díaz Sibaja, Beth Reinke, Maha Ghazal, T. Michael Keesey (from a
photograph by Frank Glaw, Jörn Köhler, Ted M. Townsend & Miguel Vences),
Sean McCann, S.Martini, Birgit Lang, Katie S. Collins, Michelle Site,
Skye M, T. Michael Keesey (from a mount by Allis Markham), Didier
Descouens (vectorized by T. Michael Keesey), Kanchi Nanjo, Conty
(vectorized by T. Michael Keesey), Johan Lindgren, Michael W. Caldwell,
Takuya Konishi, Luis M. Chiappe, Auckland Museum, Tony Ayling, Matt
Martyniuk, Francisco Manuel Blanco (vectorized by T. Michael Keesey),
Maxime Dahirel, M. Antonio Todaro, Tobias Kånneby, Matteo Dal Zotto, and
Ulf Jondelius (vectorized by T. Michael Keesey), Noah Schlottman, photo
by Gustav Paulay for Moorea Biocode, Jan A. Venter, Herbert H. T. Prins,
David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey),
Catherine Yasuda, Tim Bertelink (modified by T. Michael Keesey), Ludwik
Gasiorowski, Jebulon (vectorized by T. Michael Keesey), Evan Swigart
(photography) and T. Michael Keesey (vectorization), Julio Garza,
Benchill, Trond R. Oskars, Marmelad, Notafly (vectorized by T. Michael
Keesey), Michael Scroggie, C. Camilo Julián-Caballero, Ellen Edmonson
(illustration) and Timothy J. Bartley (silhouette), Ghedoghedo
(vectorized by T. Michael Keesey), Robbie N. Cada (vectorized by T.
Michael Keesey), Lankester Edwin Ray (vectorized by T. Michael Keesey),
Amanda Katzer, Javier Luque, MPF (vectorized by T. Michael Keesey),
Jessica Anne Miller, Cesar Julian, Anthony Caravaggi, Auckland Museum
and T. Michael Keesey, Kent Elson Sorgon, Original drawing by Nobu
Tamura, vectorized by Roberto Díaz Sibaja, Dean Schnabel, Andrew A.
Farke, Martin Kevil, T. Michael Keesey (after Heinrich Harder), Nobu
Tamura (vectorized by A. Verrière), Danny Cicchetti (vectorized by T.
Michael Keesey), Tracy A. Heath, Jaime Headden, modified by T. Michael
Keesey, Matt Dempsey, Nobu Tamura and T. Michael Keesey, Andrew A.
Farke, modified from original by H. Milne Edwards, Shyamal, L. Shyamal,
FunkMonk, Javier Luque & Sarah Gerken, Agnello Picorelli, Michael P.
Taylor, Inessa Voet, CNZdenek, SecretJellyMan, Smokeybjb (vectorized by
T. Michael Keesey), Brad McFeeters (vectorized by T. Michael Keesey),
Lisa Byrne, NOAA Great Lakes Environmental Research Laboratory
(illustration) and Timothy J. Bartley (silhouette), Alexander
Schmidt-Lebuhn, Armelle Ansart (photograph), Maxime Dahirel
(digitisation), Kevin Sánchez, Martin R. Smith, Caleb Brown, Christine
Axon, M Hutchinson, Mali’o Kodis, photograph by Hans Hillewaert,
Smokeybjb, Chuanixn Yu, Yan Wong from illustration by Charles Orbigny,
Mark Witton, Eduard Solà (vectorized by T. Michael Keesey), Henry
Fairfield Osborn, vectorized by Zimices, Tony Ayling (vectorized by
Milton Tan), Riccardo Percudani, Mykle Hoban, Tyler Greenfield and Scott
Hartman, Ghedoghedo, vectorized by Zimices, Erika Schumacher, Carlos
Cano-Barbacil, Francisco Gascó (modified by Michael P. Taylor), Arthur
S. Brum, Apokryltaros (vectorized by T. Michael Keesey), Philip Chalmers
(vectorized by T. Michael Keesey), Andreas Hejnol, Sherman Foote Denton
(illustration, 1897) and Timothy J. Bartley (silhouette), Campbell
Fleming, Joseph J. W. Sertich, Mark A. Loewen, Brian Swartz (vectorized
by T. Michael Keesey), Mercedes Yrayzoz (vectorized by T. Michael
Keesey), Milton Tan, M Kolmann, Zachary Quigley, Sharon Wegner-Larsen,
Jaime Headden (vectorized by T. Michael Keesey), Pranav Iyer (grey
ideas), Scott Reid, Jan Sevcik (photo), John E. McCormack, Michael G.
Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb
T. Brumfield & T. Michael Keesey

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                               |
| --: | ------------: | ------------: | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |     232.87019 |    338.997402 | Jagged Fang Designs                                                                                                                                                                  |
|   2 |     428.93711 |    722.315352 | xgirouxb                                                                                                                                                                             |
|   3 |     102.81076 |    613.370537 | Zimices                                                                                                                                                                              |
|   4 |     822.23438 |    388.058858 | Maky (vectorization), Gabriella Skollar (photography), Rebecca Lewis (editing)                                                                                                       |
|   5 |     645.25322 |    509.377973 | Mali’o Kodis, image from Brockhaus and Efron Encyclopedic Dictionary                                                                                                                 |
|   6 |     344.35197 |    166.834596 | Zimices                                                                                                                                                                              |
|   7 |     431.79198 |     61.478518 | Falconaumanni and T. Michael Keesey                                                                                                                                                  |
|   8 |     117.67680 |    511.306702 | Zimices                                                                                                                                                                              |
|   9 |     884.83346 |    473.237257 | Oscar Sanisidro                                                                                                                                                                      |
|  10 |     394.20818 |    456.376447 | Andy Wilson                                                                                                                                                                          |
|  11 |     514.26815 |    491.302080 | Zimices                                                                                                                                                                              |
|  12 |     233.41998 |    491.243702 | Yan Wong from drawing by Joseph Smit                                                                                                                                                 |
|  13 |     334.93908 |     64.236412 | NA                                                                                                                                                                                   |
|  14 |     715.69117 |    663.128336 | Emily Willoughby                                                                                                                                                                     |
|  15 |     144.68537 |     98.744590 | Taro Maeda                                                                                                                                                                           |
|  16 |     883.78671 |    552.848344 | Kailah Thorn & Mark Hutchinson                                                                                                                                                       |
|  17 |     594.27310 |    592.583969 | Alex Slavenko                                                                                                                                                                        |
|  18 |     856.22184 |    610.131735 | FunkMonk (Michael B.H.; vectorized by T. Michael Keesey)                                                                                                                             |
|  19 |     550.50641 |    219.919501 | Lani Mohan                                                                                                                                                                           |
|  20 |     172.32598 |    222.224312 | Javiera Constanzo                                                                                                                                                                    |
|  21 |     718.03033 |    757.947801 | Armin Reindl                                                                                                                                                                         |
|  22 |      85.74851 |    433.800840 | Collin Gross                                                                                                                                                                         |
|  23 |     902.66285 |    102.404044 | Ingo Braasch                                                                                                                                                                         |
|  24 |     700.83788 |    107.707185 | Margot Michaud                                                                                                                                                                       |
|  25 |     401.65488 |    556.952038 | Christoph Schomburg                                                                                                                                                                  |
|  26 |     271.67537 |    636.614664 | Zimices                                                                                                                                                                              |
|  27 |     497.53498 |    140.760677 | Jagged Fang Designs                                                                                                                                                                  |
|  28 |     424.33089 |    262.173694 | Matt Crook                                                                                                                                                                           |
|  29 |     940.55697 |    719.753067 | T. Michael Keesey (vectorization); Thorsten Assmann, Jörn Buse, Claudia Drees, Ariel-Leib-Leonid Friedman, Tal Levanony, Andrea Matern, Anika Timm, and David W. Wrase (photography) |
|  30 |     569.56750 |    299.207475 | Zimices                                                                                                                                                                              |
|  31 |     891.95777 |    250.184808 | Mathew Wedel                                                                                                                                                                         |
|  32 |     250.10228 |    179.499061 | Gareth Monger                                                                                                                                                                        |
|  33 |      81.96926 |    702.621866 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
|  34 |     683.01811 |    226.272881 | Alexandre Vong                                                                                                                                                                       |
|  35 |     768.04612 |    703.234978 | Ieuan Jones                                                                                                                                                                          |
|  36 |     881.38840 |    155.662959 | Scott Hartman                                                                                                                                                                        |
|  37 |     663.83045 |    347.241583 | Joshua Fowler                                                                                                                                                                        |
|  38 |     731.07780 |    500.264506 | David Orr                                                                                                                                                                            |
|  39 |     877.08481 |    189.751109 | Tasman Dixon                                                                                                                                                                         |
|  40 |     729.85249 |     42.634194 | Margot Michaud                                                                                                                                                                       |
|  41 |     847.97446 |    413.729628 | Ferran Sayol                                                                                                                                                                         |
|  42 |     403.13221 |    370.655841 | Kenneth Lacovara (vectorized by T. Michael Keesey)                                                                                                                                   |
|  43 |     430.01115 |    780.910044 | Armin Reindl                                                                                                                                                                         |
|  44 |     961.08527 |     62.938783 | Manabu Bessho-Uehara                                                                                                                                                                 |
|  45 |     509.42764 |    653.686769 | Gabriela Palomo-Munoz                                                                                                                                                                |
|  46 |      60.42702 |    748.380894 | Becky Barnes                                                                                                                                                                         |
|  47 |     514.79310 |    423.979643 | H. F. O. March (modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel)                                                                                                 |
|  48 |     316.22076 |    273.765796 | Margot Michaud                                                                                                                                                                       |
|  49 |     552.12069 |    725.632217 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
|  50 |     513.53835 |     37.360785 | Scott Hartman                                                                                                                                                                        |
|  51 |     956.59754 |    549.134427 | Steven Traver                                                                                                                                                                        |
|  52 |     268.62654 |    765.171848 | Julia B McHugh                                                                                                                                                                       |
|  53 |     281.21890 |    566.218905 | Markus A. Grohme                                                                                                                                                                     |
|  54 |     790.81010 |    598.494252 | Gareth Monger                                                                                                                                                                        |
|  55 |     232.35538 |    733.200812 | Alex Slavenko                                                                                                                                                                        |
|  56 |     110.76910 |    673.701454 | Tyler McCraney                                                                                                                                                                       |
|  57 |     977.72813 |    192.586311 | Felix Vaux                                                                                                                                                                           |
|  58 |     610.32295 |     50.289933 | Kamil S. Jaron                                                                                                                                                                       |
|  59 |     962.03356 |    379.419116 | NA                                                                                                                                                                                   |
|  60 |     105.98923 |    179.814800 | NA                                                                                                                                                                                   |
|  61 |     274.84683 |    421.995059 | Emily Willoughby                                                                                                                                                                     |
|  62 |     230.14047 |    255.784293 | Kenneth Lacovara (vectorized by T. Michael Keesey)                                                                                                                                   |
|  63 |      98.19847 |    257.227455 | Steven Coombs                                                                                                                                                                        |
|  64 |     959.79630 |    634.254464 | Tasman Dixon                                                                                                                                                                         |
|  65 |     129.93827 |    791.436499 | NA                                                                                                                                                                                   |
|  66 |     124.19692 |     15.131904 | Chris huh                                                                                                                                                                            |
|  67 |     473.31474 |    186.136168 | T. Michael Keesey                                                                                                                                                                    |
|  68 |     866.92898 |    720.370374 | NA                                                                                                                                                                                   |
|  69 |     708.19882 |    598.687729 | James R. Spotila and Ray Chatterji                                                                                                                                                   |
|  70 |     565.12352 |    573.718920 | Taenadoman                                                                                                                                                                           |
|  71 |     390.70758 |    656.338544 |                                                                                                                                                                                      |
|  72 |     362.93243 |    534.795130 | Armin Reindl                                                                                                                                                                         |
|  73 |     676.61026 |    418.332116 | Jagged Fang Designs                                                                                                                                                                  |
|  74 |     513.31171 |    355.089993 | Chris huh                                                                                                                                                                            |
|  75 |     241.07288 |     65.947794 | Ferran Sayol                                                                                                                                                                         |
|  76 |      39.73811 |     84.611166 | Tyler Greenfield                                                                                                                                                                     |
|  77 |     614.20385 |    131.052563 | Steven Traver                                                                                                                                                                        |
|  78 |     878.11842 |     18.678048 | Iain Reid                                                                                                                                                                            |
|  79 |     622.70811 |    678.986799 | Caleb M. Brown                                                                                                                                                                       |
|  80 |     413.54785 |    618.713728 | Zimices                                                                                                                                                                              |
|  81 |     203.75545 |    704.188498 | Gareth Monger                                                                                                                                                                        |
|  82 |     350.91836 |    228.841347 | NA                                                                                                                                                                                   |
|  83 |     796.53112 |    131.224714 | Ferran Sayol                                                                                                                                                                         |
|  84 |     605.15439 |    742.576256 | Jagged Fang Designs                                                                                                                                                                  |
|  85 |     805.06764 |     19.670687 | Christopher Watson (photo) and T. Michael Keesey (vectorization)                                                                                                                     |
|  86 |      39.90351 |    272.702022 | Tasman Dixon                                                                                                                                                                         |
|  87 |     959.72686 |    347.571554 | Scott Hartman                                                                                                                                                                        |
|  88 |     783.63543 |    511.166520 | NA                                                                                                                                                                                   |
|  89 |     163.70972 |    728.819332 | Jagged Fang Designs                                                                                                                                                                  |
|  90 |     316.13997 |    696.923593 | Ferran Sayol                                                                                                                                                                         |
|  91 |     650.08157 |    712.058708 | Dexter R. Mardis                                                                                                                                                                     |
|  92 |     933.31892 |    428.559768 | Chris huh                                                                                                                                                                            |
|  93 |     912.98199 |    308.271208 | Jagged Fang Designs                                                                                                                                                                  |
|  94 |     384.48703 |    515.762216 | Scott Hartman                                                                                                                                                                        |
|  95 |     820.53960 |     80.169895 | Gabriela Palomo-Munoz                                                                                                                                                                |
|  96 |     900.02462 |    228.657521 | Dave Souza (vectorized by T. Michael Keesey)                                                                                                                                         |
|  97 |     136.56524 |    478.449320 | Matt Crook                                                                                                                                                                           |
|  98 |     559.72350 |    777.148575 | Pete Buchholz                                                                                                                                                                        |
|  99 |     994.95297 |    713.842095 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 100 |     969.42757 |    299.163023 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 101 |     390.47291 |    320.177448 | Hanyong Pu, Yoshitsugu Kobayashi, Junchang Lü, Li Xu, Yanhua Wu, Huali Chang, Jiming Zhang, Songhai Jia & T. Michael Keesey                                                          |
| 102 |     423.82153 |    143.186228 | Scott Hartman                                                                                                                                                                        |
| 103 |     799.64386 |    735.440093 | Ignacio Contreras                                                                                                                                                                    |
| 104 |     338.08718 |    739.663419 | Margot Michaud                                                                                                                                                                       |
| 105 |      79.80329 |    400.591052 | T. Michael Keesey                                                                                                                                                                    |
| 106 |     522.49229 |     68.029243 | Joanna Wolfe                                                                                                                                                                         |
| 107 |     392.47589 |    577.089344 | Joanna Wolfe                                                                                                                                                                         |
| 108 |     830.54102 |    500.127936 | Zimices                                                                                                                                                                              |
| 109 |      64.54091 |    369.505385 | Rebecca Groom                                                                                                                                                                        |
| 110 |     686.17564 |    786.976341 | Melissa Broussard                                                                                                                                                                    |
| 111 |     102.94817 |    296.572308 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 112 |     304.91786 |    784.231588 | Alex Slavenko                                                                                                                                                                        |
| 113 |     371.48952 |    127.708054 | NA                                                                                                                                                                                   |
| 114 |     327.51305 |    316.690216 | V. Deepak                                                                                                                                                                            |
| 115 |    1011.81768 |    331.636708 | Tyler Greenfield                                                                                                                                                                     |
| 116 |     259.91109 |    153.344739 | Andy Wilson                                                                                                                                                                          |
| 117 |     588.58615 |    634.638238 | Kai R. Caspar                                                                                                                                                                        |
| 118 |     288.88234 |    120.908760 | Steven Traver                                                                                                                                                                        |
| 119 |     192.48907 |    561.022452 | Ferran Sayol                                                                                                                                                                         |
| 120 |     565.25236 |     15.169808 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 121 |     348.76491 |    484.073979 | Matt Crook                                                                                                                                                                           |
| 122 |    1006.74139 |    399.541472 | Mali’o Kodis, photograph from Jersabek et al, 2003                                                                                                                                   |
| 123 |     994.21575 |    430.962111 | Andy Wilson                                                                                                                                                                          |
| 124 |     952.49662 |    505.945114 | Jiekun He                                                                                                                                                                            |
| 125 |     309.73943 |    249.243666 | Emily Willoughby                                                                                                                                                                     |
| 126 |     494.88387 |    378.357010 | Tasman Dixon                                                                                                                                                                         |
| 127 |     227.26207 |    119.420676 | NA                                                                                                                                                                                   |
| 128 |     509.72317 |    689.228392 | Michael Day                                                                                                                                                                          |
| 129 |     277.07698 |    357.039436 | Mathilde Cordellier                                                                                                                                                                  |
| 130 |     940.05816 |    220.490645 | Hugo Gruson                                                                                                                                                                          |
| 131 |     983.33964 |    497.642558 | Mali’o Kodis, image from the Smithsonian Institution                                                                                                                                 |
| 132 |     577.96333 |    377.194973 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                                    |
| 133 |     218.52146 |    195.792657 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 134 |     166.72635 |    417.949126 | Zimices                                                                                                                                                                              |
| 135 |     634.05294 |    651.865346 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 136 |     799.19127 |    244.819810 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                                      |
| 137 |     527.53597 |    116.187735 | Chris huh                                                                                                                                                                            |
| 138 |     195.92309 |    402.767900 | Matt Crook                                                                                                                                                                           |
| 139 |      19.60006 |    241.245603 | Harold N Eyster                                                                                                                                                                      |
| 140 |     403.24440 |    424.941793 | Lukasiniho                                                                                                                                                                           |
| 141 |     410.33303 |    334.612723 | Eyal Bartov                                                                                                                                                                          |
| 142 |     867.99643 |    788.778642 | AnAgnosticGod (vectorized by T. Michael Keesey)                                                                                                                                      |
| 143 |     464.30593 |     58.176820 | NA                                                                                                                                                                                   |
| 144 |     796.57639 |    178.646230 | Alex Slavenko                                                                                                                                                                        |
| 145 |     327.62770 |    135.550587 | (unknown)                                                                                                                                                                            |
| 146 |     762.04245 |    636.664254 | Joanna Wolfe                                                                                                                                                                         |
| 147 |     751.33671 |    269.836765 | Chris huh                                                                                                                                                                            |
| 148 |     923.92263 |    588.185702 | Lukas Panzarin (vectorized by T. Michael Keesey)                                                                                                                                     |
| 149 |     176.75851 |    497.946388 | Melissa Broussard                                                                                                                                                                    |
| 150 |     398.42738 |    229.499041 | Maija Karala                                                                                                                                                                         |
| 151 |     267.17098 |    237.289839 | Robert Gay                                                                                                                                                                           |
| 152 |     286.11691 |    389.042180 | Ferran Sayol                                                                                                                                                                         |
| 153 |     825.09317 |    673.934319 | Zimices                                                                                                                                                                              |
| 154 |     291.24119 |    692.797044 | Zimices                                                                                                                                                                              |
| 155 |     179.57128 |    517.312910 | T. Tischler                                                                                                                                                                          |
| 156 |     813.86220 |    262.595238 | Margot Michaud                                                                                                                                                                       |
| 157 |     676.51349 |    546.730602 | Gareth Monger                                                                                                                                                                        |
| 158 |     655.57791 |    279.825338 | Andrew Farke and Joseph Sertich                                                                                                                                                      |
| 159 |     467.64386 |    329.863519 | Zimices                                                                                                                                                                              |
| 160 |     224.09061 |    520.952859 | Chris huh                                                                                                                                                                            |
| 161 |     535.58155 |    444.555269 | Jaime Headden                                                                                                                                                                        |
| 162 |     750.45692 |    732.949680 | Hugo Gruson                                                                                                                                                                          |
| 163 |     506.30149 |    100.396889 | Rainer Schoch                                                                                                                                                                        |
| 164 |     842.86899 |    118.076930 | Margot Michaud                                                                                                                                                                       |
| 165 |      29.51918 |    788.686577 | Ferran Sayol                                                                                                                                                                         |
| 166 |     297.42861 |     75.937108 | Manabu Bessho-Uehara                                                                                                                                                                 |
| 167 |      76.82845 |    475.948660 | Louis Ranjard                                                                                                                                                                        |
| 168 |      18.68408 |    361.930141 | Matthew E. Clapham                                                                                                                                                                   |
| 169 |      64.64885 |    541.010824 | Richard Lampitt, Jeremy Young / NHM (vectorization by Yan Wong)                                                                                                                      |
| 170 |     592.32280 |    404.408578 | Sarah Werning                                                                                                                                                                        |
| 171 |     794.19819 |    279.889788 | Sarah Werning                                                                                                                                                                        |
| 172 |     855.67689 |    656.610296 | Mali’o Kodis, photograph by “Wildcat Dunny” (<http://www.flickr.com/people/wildcat_dunny/>)                                                                                          |
| 173 |     456.44129 |     95.336956 | Jonathan Wells                                                                                                                                                                       |
| 174 |     470.77580 |     13.809196 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 175 |     442.64894 |    518.934361 | Mathew Wedel                                                                                                                                                                         |
| 176 |     606.99812 |    781.727624 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                                        |
| 177 |     626.19094 |    262.240014 | Gareth Monger                                                                                                                                                                        |
| 178 |     255.50248 |    702.403434 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 179 |     881.05633 |    572.420250 | Steven Traver                                                                                                                                                                        |
| 180 |     613.14040 |    303.677944 | Jagged Fang Designs                                                                                                                                                                  |
| 181 |     979.42548 |    603.078140 | Beth Reinke                                                                                                                                                                          |
| 182 |     160.48538 |    575.922541 | Gareth Monger                                                                                                                                                                        |
| 183 |     204.29675 |     17.554450 | Maha Ghazal                                                                                                                                                                          |
| 184 |     630.19976 |    162.959082 | Jagged Fang Designs                                                                                                                                                                  |
| 185 |     203.03266 |    778.135418 | Markus A. Grohme                                                                                                                                                                     |
| 186 |     468.01763 |    268.278811 | Christoph Schomburg                                                                                                                                                                  |
| 187 |      69.82049 |    297.560465 | T. Michael Keesey (from a photograph by Frank Glaw, Jörn Köhler, Ted M. Townsend & Miguel Vences)                                                                                    |
| 188 |     684.59086 |    620.221524 | Chris huh                                                                                                                                                                            |
| 189 |     919.55069 |    789.208910 | Zimices                                                                                                                                                                              |
| 190 |     590.62391 |    429.012419 | Sean McCann                                                                                                                                                                          |
| 191 |     766.62180 |    245.710271 | Matt Crook                                                                                                                                                                           |
| 192 |     976.46690 |     37.178044 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 193 |      39.89244 |    221.280447 | Tasman Dixon                                                                                                                                                                         |
| 194 |     346.49775 |    512.794840 | S.Martini                                                                                                                                                                            |
| 195 |     228.69605 |    143.837755 | Zimices                                                                                                                                                                              |
| 196 |     695.21275 |    142.650797 | Birgit Lang                                                                                                                                                                          |
| 197 |     579.22863 |    656.196188 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 198 |     305.84711 |    436.740584 | Steven Traver                                                                                                                                                                        |
| 199 |     182.85539 |    268.424081 | Zimices                                                                                                                                                                              |
| 200 |     727.07541 |     15.658771 | Beth Reinke                                                                                                                                                                          |
| 201 |     320.58990 |    486.219115 | Gareth Monger                                                                                                                                                                        |
| 202 |     504.20073 |    166.337033 | Katie S. Collins                                                                                                                                                                     |
| 203 |     339.96335 |     22.647421 | Christoph Schomburg                                                                                                                                                                  |
| 204 |     322.52473 |    588.785090 | Michelle Site                                                                                                                                                                        |
| 205 |     844.55125 |    581.445443 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 206 |     780.94330 |    790.549484 | Skye M                                                                                                                                                                               |
| 207 |     357.88545 |    197.765766 | T. Michael Keesey (from a mount by Allis Markham)                                                                                                                                    |
| 208 |    1006.18971 |    670.343260 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                                   |
| 209 |      25.76332 |    203.697039 | Kanchi Nanjo                                                                                                                                                                         |
| 210 |      98.47983 |    729.951636 | Hugo Gruson                                                                                                                                                                          |
| 211 |     537.33876 |    615.587770 | NA                                                                                                                                                                                   |
| 212 |     668.32577 |    725.062606 | T. Michael Keesey                                                                                                                                                                    |
| 213 |      45.50660 |    634.081024 | Conty (vectorized by T. Michael Keesey)                                                                                                                                              |
| 214 |     176.92786 |    787.552903 | Johan Lindgren, Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe                                                                                                                 |
| 215 |     984.41962 |    462.300178 | T. Michael Keesey                                                                                                                                                                    |
| 216 |     876.97401 |    511.136669 | Auckland Museum                                                                                                                                                                      |
| 217 |     402.32913 |    260.477355 | Jaime Headden                                                                                                                                                                        |
| 218 |     132.18905 |    579.495603 | Tony Ayling                                                                                                                                                                          |
| 219 |     606.41591 |    249.797752 | Matt Martyniuk                                                                                                                                                                       |
| 220 |     882.72519 |    614.171873 | Jaime Headden                                                                                                                                                                        |
| 221 |     398.82038 |    203.341829 | NA                                                                                                                                                                                   |
| 222 |     578.19639 |    258.495371 | Francisco Manuel Blanco (vectorized by T. Michael Keesey)                                                                                                                            |
| 223 |     813.29251 |    640.267760 | Maxime Dahirel                                                                                                                                                                       |
| 224 |     178.07316 |    768.711930 | Matt Crook                                                                                                                                                                           |
| 225 |     932.23542 |    136.092074 | M. Antonio Todaro, Tobias Kånneby, Matteo Dal Zotto, and Ulf Jondelius (vectorized by T. Michael Keesey)                                                                             |
| 226 |     354.05514 |    318.302937 | Andy Wilson                                                                                                                                                                          |
| 227 |     409.63213 |    394.203215 | Markus A. Grohme                                                                                                                                                                     |
| 228 |     460.31434 |     78.625338 | Noah Schlottman, photo by Gustav Paulay for Moorea Biocode                                                                                                                           |
| 229 |     851.09921 |    203.098759 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 230 |     699.31564 |    729.163420 | NA                                                                                                                                                                                   |
| 231 |     316.22028 |    395.600139 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                                  |
| 232 |     224.25315 |     79.550048 | Taro Maeda                                                                                                                                                                           |
| 233 |     203.87684 |    531.284898 | Catherine Yasuda                                                                                                                                                                     |
| 234 |     372.64156 |      6.366250 | Zimices                                                                                                                                                                              |
| 235 |     883.25150 |     67.964809 | NA                                                                                                                                                                                   |
| 236 |     110.35228 |    469.444698 | Margot Michaud                                                                                                                                                                       |
| 237 |     480.01971 |    769.972605 | Tim Bertelink (modified by T. Michael Keesey)                                                                                                                                        |
| 238 |     175.44631 |    189.391306 | Ludwik Gasiorowski                                                                                                                                                                   |
| 239 |     354.94942 |    389.679039 | Jebulon (vectorized by T. Michael Keesey)                                                                                                                                            |
| 240 |     783.72870 |    683.789767 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 241 |     280.35548 |     90.228629 | Evan Swigart (photography) and T. Michael Keesey (vectorization)                                                                                                                     |
| 242 |     995.20694 |    101.619281 | Steven Traver                                                                                                                                                                        |
| 243 |      15.83097 |    387.551249 | Julio Garza                                                                                                                                                                          |
| 244 |     150.75721 |    655.818476 | Kamil S. Jaron                                                                                                                                                                       |
| 245 |      20.66845 |    168.075006 | Benchill                                                                                                                                                                             |
| 246 |    1010.66907 |    185.337635 | Steven Traver                                                                                                                                                                        |
| 247 |     396.62236 |    490.294404 | Jagged Fang Designs                                                                                                                                                                  |
| 248 |     532.12933 |    187.809544 | Zimices                                                                                                                                                                              |
| 249 |     365.30041 |    333.598714 | T. Michael Keesey                                                                                                                                                                    |
| 250 |     892.93201 |    396.963229 | Jagged Fang Designs                                                                                                                                                                  |
| 251 |     608.14650 |    190.675799 | Margot Michaud                                                                                                                                                                       |
| 252 |     458.65095 |    588.340223 | Trond R. Oskars                                                                                                                                                                      |
| 253 |     343.80015 |    298.988529 | Marmelad                                                                                                                                                                             |
| 254 |     588.10490 |    349.079662 | Notafly (vectorized by T. Michael Keesey)                                                                                                                                            |
| 255 |     828.20758 |    756.742148 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 256 |     421.95121 |    229.460304 | Michael Scroggie                                                                                                                                                                     |
| 257 |     491.05172 |    291.765746 | Margot Michaud                                                                                                                                                                       |
| 258 |    1000.97647 |    230.056442 | Zimices                                                                                                                                                                              |
| 259 |     121.27543 |    769.700695 | Gareth Monger                                                                                                                                                                        |
| 260 |      16.38994 |    659.676422 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 261 |     687.38807 |    568.239106 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                                                    |
| 262 |     738.67844 |    149.568367 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 263 |     486.77146 |    567.913759 | NA                                                                                                                                                                                   |
| 264 |     537.16898 |    541.203752 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                                         |
| 265 |     448.29867 |    257.458031 | Collin Gross                                                                                                                                                                         |
| 266 |      97.88291 |    657.303151 | Jagged Fang Designs                                                                                                                                                                  |
| 267 |     812.91479 |    786.223680 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                                     |
| 268 |    1000.03428 |    492.179828 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                                                |
| 269 |     977.53819 |     11.871334 | Sarah Werning                                                                                                                                                                        |
| 270 |     565.46607 |    340.179484 | NA                                                                                                                                                                                   |
| 271 |     879.53298 |    625.445802 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 272 |      15.28141 |    558.018977 | Amanda Katzer                                                                                                                                                                        |
| 273 |     934.67155 |    331.653263 | Mathew Wedel                                                                                                                                                                         |
| 274 |     386.77715 |    296.792032 | Matt Crook                                                                                                                                                                           |
| 275 |     653.69499 |    769.883737 | Javier Luque                                                                                                                                                                         |
| 276 |     602.37493 |    617.152188 | NA                                                                                                                                                                                   |
| 277 |     610.89771 |    324.948682 | MPF (vectorized by T. Michael Keesey)                                                                                                                                                |
| 278 |     404.56162 |     99.158230 | Jessica Anne Miller                                                                                                                                                                  |
| 279 |     612.34992 |    174.719349 | Chris huh                                                                                                                                                                            |
| 280 |     330.93364 |    714.147779 | Matt Crook                                                                                                                                                                           |
| 281 |     150.55010 |    695.805483 | Cesar Julian                                                                                                                                                                         |
| 282 |     954.06730 |    490.702482 | Jagged Fang Designs                                                                                                                                                                  |
| 283 |     479.86318 |    236.006567 | Anthony Caravaggi                                                                                                                                                                    |
| 284 |      25.10251 |    539.480294 | Auckland Museum and T. Michael Keesey                                                                                                                                                |
| 285 |     840.15785 |     51.635286 | Jagged Fang Designs                                                                                                                                                                  |
| 286 |     553.62551 |    324.643448 | Ferran Sayol                                                                                                                                                                         |
| 287 |     668.16730 |    173.353201 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 288 |     349.23152 |    458.780034 | Matt Crook                                                                                                                                                                           |
| 289 |     667.79775 |    453.354694 | Scott Hartman                                                                                                                                                                        |
| 290 |     893.51591 |    213.742258 | Iain Reid                                                                                                                                                                            |
| 291 |     434.47583 |    165.774116 | Gareth Monger                                                                                                                                                                        |
| 292 |      19.76131 |    304.678505 | Michelle Site                                                                                                                                                                        |
| 293 |     771.68818 |    285.408536 | Kent Elson Sorgon                                                                                                                                                                    |
| 294 |     539.46946 |    386.031128 | Original drawing by Nobu Tamura, vectorized by Roberto Díaz Sibaja                                                                                                                   |
| 295 |     507.91486 |    600.050013 | Tasman Dixon                                                                                                                                                                         |
| 296 |     640.39767 |    788.860700 | Melissa Broussard                                                                                                                                                                    |
| 297 |    1002.40112 |    256.660977 | Tasman Dixon                                                                                                                                                                         |
| 298 |    1004.26767 |     26.787003 | S.Martini                                                                                                                                                                            |
| 299 |      42.99512 |    570.614426 | Gareth Monger                                                                                                                                                                        |
| 300 |     391.76231 |    766.816007 | Scott Hartman                                                                                                                                                                        |
| 301 |     292.14229 |    464.747321 | Zimices                                                                                                                                                                              |
| 302 |     596.03023 |     10.581808 | Dean Schnabel                                                                                                                                                                        |
| 303 |     139.03532 |    499.025215 | Andrew A. Farke                                                                                                                                                                      |
| 304 |      34.72194 |    587.825937 | Steven Traver                                                                                                                                                                        |
| 305 |     323.21503 |    633.965177 | Melissa Broussard                                                                                                                                                                    |
| 306 |     886.88599 |    670.821209 | Zimices                                                                                                                                                                              |
| 307 |     249.83309 |    789.166363 | Martin Kevil                                                                                                                                                                         |
| 308 |     230.30296 |    582.899887 | T. Michael Keesey (after Heinrich Harder)                                                                                                                                            |
| 309 |     269.53186 |    169.529543 | Matt Crook                                                                                                                                                                           |
| 310 |     342.16829 |    790.843324 | Tasman Dixon                                                                                                                                                                         |
| 311 |     248.47019 |    671.606104 | Andrew A. Farke                                                                                                                                                                      |
| 312 |     152.08584 |    379.746861 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                                              |
| 313 |     492.42881 |    311.699585 | Emily Willoughby                                                                                                                                                                     |
| 314 |     798.18138 |     94.888013 | Markus A. Grohme                                                                                                                                                                     |
| 315 |     497.44409 |    589.488193 | Tasman Dixon                                                                                                                                                                         |
| 316 |      57.29889 |    203.129331 | Zimices                                                                                                                                                                              |
| 317 |     390.02855 |     17.669499 | Danny Cicchetti (vectorized by T. Michael Keesey)                                                                                                                                    |
| 318 |    1003.03926 |    154.142134 | Zimices                                                                                                                                                                              |
| 319 |     931.97059 |     29.354320 | Beth Reinke                                                                                                                                                                          |
| 320 |      59.35835 |    660.887226 | Markus A. Grohme                                                                                                                                                                     |
| 321 |    1001.83757 |    122.941199 | Tracy A. Heath                                                                                                                                                                       |
| 322 |     625.47397 |    704.900502 | Jaime Headden, modified by T. Michael Keesey                                                                                                                                         |
| 323 |    1007.77646 |    271.411907 | Zimices                                                                                                                                                                              |
| 324 |     341.33086 |    372.280158 | Ferran Sayol                                                                                                                                                                         |
| 325 |    1000.97301 |    291.793071 | Matt Crook                                                                                                                                                                           |
| 326 |     228.86761 |    285.494505 | Matt Dempsey                                                                                                                                                                         |
| 327 |     898.83079 |    710.276042 | Zimices                                                                                                                                                                              |
| 328 |     931.30934 |    618.764924 | Nobu Tamura and T. Michael Keesey                                                                                                                                                    |
| 329 |     650.40111 |    255.595662 | Andrew A. Farke, modified from original by H. Milne Edwards                                                                                                                          |
| 330 |      87.96154 |    211.591815 | xgirouxb                                                                                                                                                                             |
| 331 |     825.41960 |    553.741371 | Shyamal                                                                                                                                                                              |
| 332 |     601.33820 |    464.524528 | Jagged Fang Designs                                                                                                                                                                  |
| 333 |     430.68729 |    409.122239 | Tasman Dixon                                                                                                                                                                         |
| 334 |     303.90582 |    359.680349 | Gareth Monger                                                                                                                                                                        |
| 335 |     821.80660 |    434.051551 | Caleb M. Brown                                                                                                                                                                       |
| 336 |     185.04296 |    595.689213 | Beth Reinke                                                                                                                                                                          |
| 337 |      46.91821 |    520.923672 | Chris huh                                                                                                                                                                            |
| 338 |      25.99451 |    625.473898 | Jagged Fang Designs                                                                                                                                                                  |
| 339 |     492.61443 |    790.444913 | Tasman Dixon                                                                                                                                                                         |
| 340 |     236.68717 |    399.511225 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 341 |     679.85748 |    473.671236 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 342 |     505.25273 |      8.125299 | Gareth Monger                                                                                                                                                                        |
| 343 |     353.59167 |    693.694651 | Matt Martyniuk                                                                                                                                                                       |
| 344 |     828.04264 |    742.870122 | Iain Reid                                                                                                                                                                            |
| 345 |     540.26820 |     23.721138 | Jagged Fang Designs                                                                                                                                                                  |
| 346 |     802.37127 |    161.421855 | Andy Wilson                                                                                                                                                                          |
| 347 |     914.18460 |    532.583383 | L. Shyamal                                                                                                                                                                           |
| 348 |     635.52769 |    634.919292 | FunkMonk                                                                                                                                                                             |
| 349 |     610.16090 |    385.687411 | Chris huh                                                                                                                                                                            |
| 350 |     945.71314 |      9.185591 | Margot Michaud                                                                                                                                                                       |
| 351 |     386.26166 |     37.818901 | Javier Luque & Sarah Gerken                                                                                                                                                          |
| 352 |     973.36182 |    396.735182 | Melissa Broussard                                                                                                                                                                    |
| 353 |     207.20298 |    165.555373 | Kent Elson Sorgon                                                                                                                                                                    |
| 354 |     904.13595 |     81.264366 | Sarah Werning                                                                                                                                                                        |
| 355 |      17.10328 |    432.050910 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 356 |     156.42185 |    404.022046 | Scott Hartman                                                                                                                                                                        |
| 357 |     311.53183 |    655.251481 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 358 |    1010.80587 |    782.588204 | Agnello Picorelli                                                                                                                                                                    |
| 359 |     983.18481 |    774.104122 | Michael P. Taylor                                                                                                                                                                    |
| 360 |     855.42742 |    524.989174 | Inessa Voet                                                                                                                                                                          |
| 361 |     378.48142 |    599.599131 | T. Michael Keesey                                                                                                                                                                    |
| 362 |     951.77346 |    261.485719 | Steven Traver                                                                                                                                                                        |
| 363 |     383.52224 |    495.729876 | Markus A. Grohme                                                                                                                                                                     |
| 364 |     907.82655 |    668.626004 | T. Michael Keesey                                                                                                                                                                    |
| 365 |     586.59034 |    101.000181 | Markus A. Grohme                                                                                                                                                                     |
| 366 |     443.04053 |    538.317908 | Chris huh                                                                                                                                                                            |
| 367 |      91.78583 |    287.166301 | Jagged Fang Designs                                                                                                                                                                  |
| 368 |     809.93740 |     50.292565 | Steven Traver                                                                                                                                                                        |
| 369 |     216.48886 |    686.367630 | CNZdenek                                                                                                                                                                             |
| 370 |     362.52720 |    405.529924 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 371 |     749.69962 |    785.016267 | Zimices                                                                                                                                                                              |
| 372 |     848.95945 |    216.572492 | Maxime Dahirel                                                                                                                                                                       |
| 373 |      33.63164 |    670.686346 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                                      |
| 374 |      32.26229 |    505.558086 | Ingo Braasch                                                                                                                                                                         |
| 375 |     897.08564 |     59.877801 | Iain Reid                                                                                                                                                                            |
| 376 |      85.81186 |     91.390312 | Andy Wilson                                                                                                                                                                          |
| 377 |     993.69026 |    331.090064 | Ludwik Gasiorowski                                                                                                                                                                   |
| 378 |     230.93348 |    670.109587 | SecretJellyMan                                                                                                                                                                       |
| 379 |     402.94432 |     67.303071 | NA                                                                                                                                                                                   |
| 380 |      27.27418 |    413.481842 | Scott Hartman                                                                                                                                                                        |
| 381 |     985.17465 |    750.312507 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                                          |
| 382 |    1008.14588 |    686.998235 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                                     |
| 383 |     884.51657 |     47.008534 | Lisa Byrne                                                                                                                                                                           |
| 384 |     155.71545 |    276.629686 | Matt Crook                                                                                                                                                                           |
| 385 |     800.58281 |    723.974373 | Birgit Lang                                                                                                                                                                          |
| 386 |     512.05886 |     84.745095 | Chris huh                                                                                                                                                                            |
| 387 |     189.92003 |    282.969290 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                                |
| 388 |     965.42470 |    773.223913 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 389 |      11.15504 |    332.629649 | Armelle Ansart (photograph), Maxime Dahirel (digitisation)                                                                                                                           |
| 390 |     499.18720 |    232.108028 | Jagged Fang Designs                                                                                                                                                                  |
| 391 |     155.99113 |    760.769376 | Jessica Anne Miller                                                                                                                                                                  |
| 392 |     803.18060 |    198.517872 | Kevin Sánchez                                                                                                                                                                        |
| 393 |      36.03002 |     17.205204 | Martin R. Smith                                                                                                                                                                      |
| 394 |     687.29607 |     67.626134 | Zimices                                                                                                                                                                              |
| 395 |     830.87671 |     32.577799 | Matt Crook                                                                                                                                                                           |
| 396 |     164.08887 |    438.949090 | Shyamal                                                                                                                                                                              |
| 397 |     119.80700 |    760.667572 | Scott Hartman                                                                                                                                                                        |
| 398 |     607.61197 |    453.039251 | Caleb Brown                                                                                                                                                                          |
| 399 |     941.08536 |    239.821986 | Zimices                                                                                                                                                                              |
| 400 |     493.50864 |    267.432045 | Birgit Lang                                                                                                                                                                          |
| 401 |     451.72210 |    107.829971 | Christine Axon                                                                                                                                                                       |
| 402 |     469.18265 |    493.149773 | T. Michael Keesey                                                                                                                                                                    |
| 403 |     536.54051 |    157.810143 | Jagged Fang Designs                                                                                                                                                                  |
| 404 |     590.12138 |    710.330814 | M Hutchinson                                                                                                                                                                         |
| 405 |     653.29909 |    697.209148 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 406 |     787.14645 |    220.565707 | Pete Buchholz                                                                                                                                                                        |
| 407 |     730.11462 |    541.348849 | Christine Axon                                                                                                                                                                       |
| 408 |     366.95441 |    272.261553 | Gareth Monger                                                                                                                                                                        |
| 409 |     540.50696 |    254.138616 | NA                                                                                                                                                                                   |
| 410 |     618.46059 |     89.188640 | Michael Scroggie                                                                                                                                                                     |
| 411 |    1012.40700 |    462.807247 | Mali’o Kodis, photograph by Hans Hillewaert                                                                                                                                          |
| 412 |      36.55954 |    149.301823 | Smokeybjb                                                                                                                                                                            |
| 413 |     300.55731 |    521.448943 | Tasman Dixon                                                                                                                                                                         |
| 414 |     276.11670 |    251.585517 | Emily Willoughby                                                                                                                                                                     |
| 415 |     688.20605 |    698.175158 | Chuanixn Yu                                                                                                                                                                          |
| 416 |     688.18609 |    495.309113 | Andy Wilson                                                                                                                                                                          |
| 417 |      69.12344 |    232.291854 | T. Michael Keesey                                                                                                                                                                    |
| 418 |     704.78632 |    547.096917 | FunkMonk                                                                                                                                                                             |
| 419 |     840.75595 |    645.557465 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 420 |     232.68200 |    537.661825 | Yan Wong from illustration by Charles Orbigny                                                                                                                                        |
| 421 |      31.36594 |    646.132027 | Tyler Greenfield                                                                                                                                                                     |
| 422 |     400.77810 |    407.407189 | Mark Witton                                                                                                                                                                          |
| 423 |     402.30400 |    603.463826 | NA                                                                                                                                                                                   |
| 424 |     220.31149 |    425.221403 | Eduard Solà (vectorized by T. Michael Keesey)                                                                                                                                        |
| 425 |     708.53078 |    433.196301 | Zimices                                                                                                                                                                              |
| 426 |     737.17904 |    560.199990 | Sarah Werning                                                                                                                                                                        |
| 427 |      16.03075 |    686.191231 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                                                        |
| 428 |     357.55827 |    781.362162 | NA                                                                                                                                                                                   |
| 429 |     904.77170 |    751.394885 | Alex Slavenko                                                                                                                                                                        |
| 430 |     578.30638 |    773.734593 | Jagged Fang Designs                                                                                                                                                                  |
| 431 |     177.73145 |    153.771974 | Tony Ayling (vectorized by Milton Tan)                                                                                                                                               |
| 432 |     627.91874 |    440.084296 | Riccardo Percudani                                                                                                                                                                   |
| 433 |     731.60594 |    677.121701 | Matt Crook                                                                                                                                                                           |
| 434 |     914.13186 |    634.721250 | Mykle Hoban                                                                                                                                                                          |
| 435 |     998.49559 |     83.064261 | Dean Schnabel                                                                                                                                                                        |
| 436 |     504.97911 |    776.946667 | Conty (vectorized by T. Michael Keesey)                                                                                                                                              |
| 437 |     621.46632 |    208.772146 | Chris huh                                                                                                                                                                            |
| 438 |     946.91486 |    205.933672 | M. Antonio Todaro, Tobias Kånneby, Matteo Dal Zotto, and Ulf Jondelius (vectorized by T. Michael Keesey)                                                                             |
| 439 |     763.72846 |     13.562153 | Michelle Site                                                                                                                                                                        |
| 440 |     496.28415 |    619.903323 | Tyler Greenfield and Scott Hartman                                                                                                                                                   |
| 441 |      91.52838 |    363.474038 | Jagged Fang Designs                                                                                                                                                                  |
| 442 |     916.67201 |    244.905082 | Scott Hartman                                                                                                                                                                        |
| 443 |     295.53993 |    191.391000 | Ghedoghedo, vectorized by Zimices                                                                                                                                                    |
| 444 |     394.37881 |    589.270767 | Erika Schumacher                                                                                                                                                                     |
| 445 |     603.28134 |    648.240385 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 446 |      50.22938 |    454.457168 | Francisco Gascó (modified by Michael P. Taylor)                                                                                                                                      |
| 447 |     199.27987 |    191.915515 | Jagged Fang Designs                                                                                                                                                                  |
| 448 |     921.15066 |    405.391162 | Andrew A. Farke                                                                                                                                                                      |
| 449 |      84.47017 |    306.716399 | Michelle Site                                                                                                                                                                        |
| 450 |     850.53093 |     64.803901 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 451 |      85.76157 |    450.150658 | Steven Coombs                                                                                                                                                                        |
| 452 |      90.55845 |    577.137453 | Arthur S. Brum                                                                                                                                                                       |
| 453 |     299.81192 |    227.445070 | Zimices                                                                                                                                                                              |
| 454 |      63.08475 |    620.660442 | Agnello Picorelli                                                                                                                                                                    |
| 455 |     469.85083 |    116.714305 | Chuanixn Yu                                                                                                                                                                          |
| 456 |     689.04699 |    646.823335 | Scott Hartman                                                                                                                                                                        |
| 457 |     848.08750 |    225.237791 | Mathew Wedel                                                                                                                                                                         |
| 458 |     125.57878 |    646.877489 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                                       |
| 459 |     369.37765 |    638.438456 | Zimices                                                                                                                                                                              |
| 460 |     660.18483 |    736.632628 | Smokeybjb                                                                                                                                                                            |
| 461 |     934.84318 |    322.027497 | Sarah Werning                                                                                                                                                                        |
| 462 |     873.08133 |    130.708979 | Tasman Dixon                                                                                                                                                                         |
| 463 |     416.70648 |     74.149676 | Philip Chalmers (vectorized by T. Michael Keesey)                                                                                                                                    |
| 464 |    1013.42106 |    514.315305 | Andreas Hejnol                                                                                                                                                                       |
| 465 |     778.42218 |     78.876636 | FunkMonk                                                                                                                                                                             |
| 466 |      70.78781 |    141.232833 | Sherman Foote Denton (illustration, 1897) and Timothy J. Bartley (silhouette)                                                                                                        |
| 467 |     710.11831 |    720.687277 | David Orr                                                                                                                                                                            |
| 468 |     586.01024 |    793.755042 | Scott Hartman                                                                                                                                                                        |
| 469 |     449.28931 |    792.839500 | T. Michael Keesey                                                                                                                                                                    |
| 470 |     438.80446 |    569.844608 | Tasman Dixon                                                                                                                                                                         |
| 471 |     316.25412 |    305.166693 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                                     |
| 472 |      76.52393 |     51.210976 | Campbell Fleming                                                                                                                                                                     |
| 473 |     770.83493 |    667.786185 | Joseph J. W. Sertich, Mark A. Loewen                                                                                                                                                 |
| 474 |      16.78701 |    478.885069 | Margot Michaud                                                                                                                                                                       |
| 475 |     307.98158 |    470.743624 | Tasman Dixon                                                                                                                                                                         |
| 476 |     807.83429 |    558.612096 | Jagged Fang Designs                                                                                                                                                                  |
| 477 |     178.61375 |    481.707074 | Jagged Fang Designs                                                                                                                                                                  |
| 478 |     373.68719 |    685.925450 | Scott Hartman                                                                                                                                                                        |
| 479 |     904.94433 |     33.627742 | Markus A. Grohme                                                                                                                                                                     |
| 480 |     926.04084 |    354.014101 | Brian Swartz (vectorized by T. Michael Keesey)                                                                                                                                       |
| 481 |     846.79071 |    265.556979 | Mercedes Yrayzoz (vectorized by T. Michael Keesey)                                                                                                                                   |
| 482 |     783.11464 |    261.051914 | Harold N Eyster                                                                                                                                                                      |
| 483 |     845.98535 |    565.219324 | Matt Crook                                                                                                                                                                           |
| 484 |     957.29647 |    461.628703 | Conty (vectorized by T. Michael Keesey)                                                                                                                                              |
| 485 |     890.76566 |    767.487489 | Milton Tan                                                                                                                                                                           |
| 486 |     818.84971 |    484.006326 | Collin Gross                                                                                                                                                                         |
| 487 |     297.25162 |    171.617691 | Julio Garza                                                                                                                                                                          |
| 488 |     210.96489 |    370.784922 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 489 |     338.23515 |    667.696276 | Scott Hartman                                                                                                                                                                        |
| 490 |     192.19352 |     13.439152 | Gareth Monger                                                                                                                                                                        |
| 491 |     126.54103 |    572.112084 | M Kolmann                                                                                                                                                                            |
| 492 |     728.98174 |    387.513791 | T. Michael Keesey                                                                                                                                                                    |
| 493 |     119.58214 |    284.241251 | Margot Michaud                                                                                                                                                                       |
| 494 |     469.04900 |    409.892629 | Zachary Quigley                                                                                                                                                                      |
| 495 |      55.05510 |    778.175114 | Collin Gross                                                                                                                                                                         |
| 496 |     837.86574 |    772.690184 | Scott Hartman                                                                                                                                                                        |
| 497 |     588.69228 |    696.973791 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 498 |     256.61346 |    379.994850 | Michelle Site                                                                                                                                                                        |
| 499 |     945.97793 |    768.991302 | Sharon Wegner-Larsen                                                                                                                                                                 |
| 500 |     654.58456 |    618.793580 | Jaime Headden (vectorized by T. Michael Keesey)                                                                                                                                      |
| 501 |      58.76845 |    343.476296 | Kent Elson Sorgon                                                                                                                                                                    |
| 502 |     783.68489 |    433.436459 | Pranav Iyer (grey ideas)                                                                                                                                                             |
| 503 |     428.57748 |    134.173945 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 504 |     424.94358 |    639.944455 | Scott Reid                                                                                                                                                                           |
| 505 |     894.64216 |    730.484629 | Zimices                                                                                                                                                                              |
| 506 |     739.71999 |    301.773588 | Chris huh                                                                                                                                                                            |
| 507 |     278.93631 |    302.597767 | Ingo Braasch                                                                                                                                                                         |
| 508 |     693.51251 |    526.207074 | Beth Reinke                                                                                                                                                                          |
| 509 |      83.78531 |    125.891766 | Steven Traver                                                                                                                                                                        |
| 510 |     235.83480 |    708.590048 | Zimices                                                                                                                                                                              |
| 511 |     820.84760 |    114.385627 | Jan Sevcik (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                           |
| 512 |     321.13628 |    125.277055 | Margot Michaud                                                                                                                                                                       |
| 513 |     768.28734 |    577.953892 | Margot Michaud                                                                                                                                                                       |
| 514 |     203.49625 |    794.600039 | Jagged Fang Designs                                                                                                                                                                  |
| 515 |     757.53720 |    131.563097 | NA                                                                                                                                                                                   |
| 516 |     248.05867 |    135.442252 | Ignacio Contreras                                                                                                                                                                    |
| 517 |     946.80690 |    289.025019 | Jagged Fang Designs                                                                                                                                                                  |
| 518 |     157.67644 |     32.171051 | Chris huh                                                                                                                                                                            |
| 519 |     556.92916 |    163.658430 | Zimices                                                                                                                                                                              |

    #> Your tweet has been posted!
