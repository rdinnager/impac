
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

Ferran Sayol, Javiera Constanzo, T. Michael Keesey, Matt Crook, Melissa
Broussard, Frank Förster (based on a picture by Jerry Kirkhart; modified
by T. Michael Keesey), Michelle Site, Smith609 and T. Michael Keesey,
Dmitry Bogdanov (vectorized by T. Michael Keesey), Mariana Ruiz
Villarreal, Zimices, Kamil S. Jaron, Crystal Maier, T. Michael Keesey
(after A. Y. Ivantsov), Scott Hartman, Collin Gross, Conty (vectorized
by T. Michael Keesey), Steven Traver, Chris huh, Eduard Solà (vectorized
by T. Michael Keesey), Erika Schumacher, Servien (vectorized by T.
Michael Keesey), Mr E? (vectorized by T. Michael Keesey), Andy Wilson,
Juan Carlos Jerí, Lafage, Margot Michaud, Kailah Thorn & Ben King, Jose
Carlos Arenas-Monroy, Gabriela Palomo-Munoz, Gareth Monger, Robert Gay,
Stuart Humphries, Dmitry Bogdanov (modified by T. Michael Keesey), Lukas
Panzarin (vectorized by T. Michael Keesey), , Kailah Thorn & Mark
Hutchinson, Steven Coombs, Xavier Giroux-Bougard, Alexander
Schmidt-Lebuhn, Michael P. Taylor, Jagged Fang Designs, Jaime Headden,
Nobu Tamura (vectorized by T. Michael Keesey), Alexandra van der Geer,
Jonathan Wells, T. Michael Keesey (after Walker & al.), Beth Reinke,
FunkMonk, Raven Amos, Roberto Díaz Sibaja, Markus A. Grohme, Tony
Ayling, Stanton F. Fink (vectorized by T. Michael Keesey), Birgit Lang,
Ian Burt (original) and T. Michael Keesey (vectorization), Skye M, Jack
Mayer Wood, Dmitry Bogdanov, Tasman Dixon, Tyler Greenfield, Alexandre
Vong, Yan Wong, David Orr, Christoph Schomburg, Archaeodontosaurus
(vectorized by T. Michael Keesey), Mathew Wedel, Haplochromis
(vectorized by T. Michael Keesey), Dean Schnabel, Kai R. Caspar, André
Karwath (vectorized by T. Michael Keesey), Karla Martinez, Steven
Blackwood, Terpsichores, TaraTaylorDesign, C. Camilo Julián-Caballero,
Scott Hartman (vectorized by William Gearty), Rachel Shoop, L. Shyamal,
Emily Jane McTavish, from
<http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>,
Brad McFeeters (vectorized by T. Michael Keesey), T. Michael Keesey
(after Mauricio Antón), Henry Lydecker, Josefine Bohr Brask, NOAA
(vectorized by T. Michael Keesey), Abraão B. Leite, JCGiron, Carlos
Cano-Barbacil, kotik, Tracy A. Heath, Felix Vaux, Johan Lindgren,
Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe, Robert Bruce
Horsfall, vectorized by Zimices, Sarah Werning, Nobu Tamura, vectorized
by Zimices, Matt Martyniuk, White Wolf, Ghedo (vectorized by T. Michael
Keesey), Matt Hayes, Ville Koistinen (vectorized by T. Michael Keesey),
Noah Schlottman, photo by Casey Dunn, Matt Wilkins (photo by Patrick
Kavanagh), Giant Blue Anteater (vectorized by T. Michael Keesey),
Chuanixn Yu, Christine Axon, Cesar Julian, Emily Willoughby, Joshua
Fowler, Tony Ayling (vectorized by Milton Tan), Mathieu Pélissié, Martin
R. Smith, S.Martini, Ieuan Jones, Nobu Tamura, modified by Andrew A.
Farke, Manabu Sakamoto, Tod Robbins, Jakovche, SecretJellyMan, Jake
Warner, Tony Ayling (vectorized by T. Michael Keesey), Tauana J. Cunha,
Mathilde Cordellier, Armin Reindl, Kelly, Joanna Wolfe, Henry Fairfield
Osborn, vectorized by Zimices, Jan A. Venter, Herbert H. T. Prins, David
A. Balfour & Rob Slotow (vectorized by T. Michael Keesey), Chloé
Schmidt, Julio Garza, Sergio A. Muñoz-Gómez, Unknown (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, ArtFavor &
annaleeblysse, Trond R. Oskars, Chris A. Hamilton, Sharon Wegner-Larsen,
Smokeybjb, Darren Naish (vectorize by T. Michael Keesey), Ellen Edmonson
(illustration) and Timothy J. Bartley (silhouette), Skye McDavid, Tyler
McCraney, Frank Denota, Caio Bernardes, vectorized by Zimices, Katie S.
Collins, Mykle Hoban, Chris Jennings (vectorized by A. Verrière), Inessa
Voet, Caleb M. Brown, Ben Liebeskind, Pearson Scott Foresman (vectorized
by T. Michael Keesey), Andrew A. Farke, modified from original by Robert
Bruce Horsfall, from Scott 1912, Andrew A. Farke, shell lines added by
Yan Wong, Ewald Rübsamen, Ron Holmes/U. S. Fish and Wildlife Service
(source photo), T. Michael Keesey (vectorization), NASA, Ignacio
Contreras, Donovan Reginald Rosevear (vectorized by T. Michael Keesey),
Michael Scroggie, Harold N Eyster, Michael “FunkMonk” B. H. (vectorized
by T. Michael Keesey), Audrey Ely, Zimices / Julián Bayona, Y. de Hoev.
(vectorized by T. Michael Keesey), Nobu Tamura, Mathew Callaghan, Kent
Sorgon, Mali’o Kodis, image from the “Proceedings of the Zoological
Society of London”, Mathieu Basille, Duane Raver (vectorized by T.
Michael Keesey), Derek Bakken (photograph) and T. Michael Keesey
(vectorization), Ingo Braasch, Gustav Mützel, Chase Brownstein, T.
Michael Keesey (vector) and Stuart Halliday (photograph), Bruno Maggia,
Scarlet23 (vectorized by T. Michael Keesey), (unknown), C. Abraczinskas,
Burton Robert, USFWS, John Gould (vectorized by T. Michael Keesey),
Meyers Konversations-Lexikon 1897 (vectorized: Yan Wong), Tim Bertelink
(modified by T. Michael Keesey), Diana Pomeroy, Duane Raver/USFWS, Nobu
Tamura (vectorized by A. Verrière), Rebecca Groom, Ghedoghedo
(vectorized by T. Michael Keesey), Amanda Katzer, Dexter R. Mardis, Ralf
Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T.
Michael Keesey), Mattia Menchetti / Yan Wong, Fritz Geller-Grimm
(vectorized by T. Michael Keesey), Didier Descouens (vectorized by T.
Michael Keesey), Emma Kissling, Lankester Edwin Ray (vectorized by T.
Michael Keesey), Matus Valach, Thibaut Brunet, Michael B. H. (vectorized
by T. Michael Keesey), Anthony Caravaggi, Neil Kelley, T. Michael Keesey
(after Heinrich Harder), Greg Schechter (original photo), Renato Santos
(vector silhouette)

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                  |
| --: | ------------: | ------------: | :------------------------------------------------------------------------------------------------------------------------------------------------------ |
|   1 |     386.56649 |    144.549245 | Ferran Sayol                                                                                                                                            |
|   2 |     650.52395 |    498.402242 | Javiera Constanzo                                                                                                                                       |
|   3 |     939.56332 |    632.605950 | T. Michael Keesey                                                                                                                                       |
|   4 |      87.76389 |    101.261210 | Matt Crook                                                                                                                                              |
|   5 |     164.31259 |    639.488005 | Melissa Broussard                                                                                                                                       |
|   6 |      67.96541 |    382.916965 | Matt Crook                                                                                                                                              |
|   7 |     443.76451 |    340.272497 | Frank Förster (based on a picture by Jerry Kirkhart; modified by T. Michael Keesey)                                                                     |
|   8 |     525.28749 |    699.917300 | Michelle Site                                                                                                                                           |
|   9 |     726.31679 |    137.642978 | Smith609 and T. Michael Keesey                                                                                                                          |
|  10 |     225.29339 |    422.212471 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                       |
|  11 |     867.63875 |    670.996037 | NA                                                                                                                                                      |
|  12 |     731.51410 |    592.433525 | Mariana Ruiz Villarreal                                                                                                                                 |
|  13 |     283.82124 |    330.647365 | Zimices                                                                                                                                                 |
|  14 |     161.21067 |    757.673470 | Kamil S. Jaron                                                                                                                                          |
|  15 |     537.56515 |    269.899529 | Crystal Maier                                                                                                                                           |
|  16 |     454.13144 |    529.919856 | T. Michael Keesey (after A. Y. Ivantsov)                                                                                                                |
|  17 |     319.84660 |    616.726778 | Scott Hartman                                                                                                                                           |
|  18 |     288.00810 |    208.020462 | Collin Gross                                                                                                                                            |
|  19 |     947.95744 |    104.902877 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                       |
|  20 |     484.45368 |    593.446663 | Conty (vectorized by T. Michael Keesey)                                                                                                                 |
|  21 |     601.86493 |    342.647200 | Steven Traver                                                                                                                                           |
|  22 |     789.17027 |    287.067856 | Chris huh                                                                                                                                               |
|  23 |     144.65070 |    355.066533 | Eduard Solà (vectorized by T. Michael Keesey)                                                                                                           |
|  24 |     628.21703 |    766.010125 | Erika Schumacher                                                                                                                                        |
|  25 |     400.46834 |    459.428785 | Servien (vectorized by T. Michael Keesey)                                                                                                               |
|  26 |     300.60115 |    685.958791 | Zimices                                                                                                                                                 |
|  27 |     537.27251 |    116.879598 | Mr E? (vectorized by T. Michael Keesey)                                                                                                                 |
|  28 |     823.56534 |    390.309922 | Andy Wilson                                                                                                                                             |
|  29 |     628.68435 |    670.738227 | Juan Carlos Jerí                                                                                                                                        |
|  30 |     952.11351 |    399.572530 | Lafage                                                                                                                                                  |
|  31 |     149.51937 |    236.498455 | Margot Michaud                                                                                                                                          |
|  32 |     920.05927 |    197.742206 | Kailah Thorn & Ben King                                                                                                                                 |
|  33 |     102.79592 |    320.131017 | T. Michael Keesey                                                                                                                                       |
|  34 |     812.21652 |    330.337972 | Jose Carlos Arenas-Monroy                                                                                                                               |
|  35 |     220.69667 |    141.270412 | Gabriela Palomo-Munoz                                                                                                                                   |
|  36 |     112.84520 |    533.534190 | Zimices                                                                                                                                                 |
|  37 |     710.30485 |    671.263044 | Gareth Monger                                                                                                                                           |
|  38 |     281.39698 |    554.087676 | Robert Gay                                                                                                                                              |
|  39 |     386.93613 |    724.788920 | Stuart Humphries                                                                                                                                        |
|  40 |     645.93548 |    398.345004 | Dmitry Bogdanov (modified by T. Michael Keesey)                                                                                                         |
|  41 |     825.08590 |    509.925609 | Ferran Sayol                                                                                                                                            |
|  42 |     463.68126 |    105.945891 | T. Michael Keesey                                                                                                                                       |
|  43 |     454.97176 |    637.476497 | Zimices                                                                                                                                                 |
|  44 |     317.91053 |     52.007142 | Lukas Panzarin (vectorized by T. Michael Keesey)                                                                                                        |
|  45 |     109.24458 |    448.041943 |                                                                                                                                                         |
|  46 |     913.47063 |    511.051135 | Steven Traver                                                                                                                                           |
|  47 |     683.57459 |     42.747912 | Zimices                                                                                                                                                 |
|  48 |     934.60115 |    333.226041 | Kailah Thorn & Mark Hutchinson                                                                                                                          |
|  49 |     597.87918 |    443.367910 | Steven Coombs                                                                                                                                           |
|  50 |     960.31784 |    433.943336 | Xavier Giroux-Bougard                                                                                                                                   |
|  51 |     860.04454 |    211.431610 | Scott Hartman                                                                                                                                           |
|  52 |     891.34460 |    758.837669 |                                                                                                                                                         |
|  53 |      49.29385 |    226.966860 | Alexander Schmidt-Lebuhn                                                                                                                                |
|  54 |     766.51432 |    445.204925 | Michael P. Taylor                                                                                                                                       |
|  55 |     516.25821 |    513.652024 | Kailah Thorn & Mark Hutchinson                                                                                                                          |
|  56 |     265.56353 |    258.564522 | Zimices                                                                                                                                                 |
|  57 |     243.56141 |    486.191592 | Jagged Fang Designs                                                                                                                                     |
|  58 |     759.11331 |    712.302660 | Jaime Headden                                                                                                                                           |
|  59 |     407.12484 |    407.067923 | Chris huh                                                                                                                                               |
|  60 |     361.83873 |    260.504096 | Chris huh                                                                                                                                               |
|  61 |     303.13546 |    770.221174 | Scott Hartman                                                                                                                                           |
|  62 |     708.22891 |    546.252298 | Scott Hartman                                                                                                                                           |
|  63 |     815.49159 |    114.902770 | Steven Traver                                                                                                                                           |
|  64 |      72.99713 |    641.261391 | Zimices                                                                                                                                                 |
|  65 |     700.06206 |    347.986663 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                           |
|  66 |     617.59502 |    580.607741 | Alexandra van der Geer                                                                                                                                  |
|  67 |     824.27818 |     28.222740 | Jagged Fang Designs                                                                                                                                     |
|  68 |     831.33406 |    170.352810 | Jonathan Wells                                                                                                                                          |
|  69 |     887.10502 |     52.809801 | Conty (vectorized by T. Michael Keesey)                                                                                                                 |
|  70 |     617.11057 |     81.591651 | T. Michael Keesey (after Walker & al.)                                                                                                                  |
|  71 |     527.34191 |    399.765093 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                       |
|  72 |     430.21940 |    239.231866 | NA                                                                                                                                                      |
|  73 |     998.58216 |    517.911712 | NA                                                                                                                                                      |
|  74 |      87.96498 |    410.153132 | Beth Reinke                                                                                                                                             |
|  75 |     824.65861 |    244.083557 | FunkMonk                                                                                                                                                |
|  76 |      35.74889 |    502.113299 | Beth Reinke                                                                                                                                             |
|  77 |     721.13879 |    754.796957 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                           |
|  78 |     673.72633 |    267.125733 | Raven Amos                                                                                                                                              |
|  79 |     152.50440 |     25.733578 | Roberto Díaz Sibaja                                                                                                                                     |
|  80 |     498.56647 |    779.205493 | Markus A. Grohme                                                                                                                                        |
|  81 |      77.45168 |    700.875196 | Tony Ayling                                                                                                                                             |
|  82 |     147.90943 |    534.299796 | Michelle Site                                                                                                                                           |
|  83 |     408.19320 |     15.317788 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                       |
|  84 |     613.68621 |    185.598192 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                           |
|  85 |     405.62259 |    596.026476 | Chris huh                                                                                                                                               |
|  86 |     548.73157 |     54.769623 | Gareth Monger                                                                                                                                           |
|  87 |      32.77861 |     19.980709 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                       |
|  88 |     688.30837 |    298.440201 | Matt Crook                                                                                                                                              |
|  89 |     882.93261 |    603.924367 | Collin Gross                                                                                                                                            |
|  90 |     606.39312 |    549.325651 | Steven Traver                                                                                                                                           |
|  91 |      76.85074 |    757.334520 | Birgit Lang                                                                                                                                             |
|  92 |     976.91984 |    265.108116 | Matt Crook                                                                                                                                              |
|  93 |     386.76977 |    558.714193 | Steven Traver                                                                                                                                           |
|  94 |    1003.99652 |    741.787872 | Ian Burt (original) and T. Michael Keesey (vectorization)                                                                                               |
|  95 |     107.23630 |    264.545143 | Skye M                                                                                                                                                  |
|  96 |     852.86385 |    375.056773 | Jack Mayer Wood                                                                                                                                         |
|  97 |     320.81828 |    384.314099 | Dmitry Bogdanov                                                                                                                                         |
|  98 |     172.38493 |    290.292708 | Tasman Dixon                                                                                                                                            |
|  99 |      70.64014 |    569.551958 | Tyler Greenfield                                                                                                                                        |
| 100 |     356.58666 |    653.887770 | Scott Hartman                                                                                                                                           |
| 101 |     452.57981 |    257.152401 | Scott Hartman                                                                                                                                           |
| 102 |     865.38091 |    456.215021 | Alexandre Vong                                                                                                                                          |
| 103 |     960.31838 |    726.799245 | Steven Traver                                                                                                                                           |
| 104 |     419.43717 |    693.644592 | Yan Wong                                                                                                                                                |
| 105 |     199.65659 |    781.374918 | David Orr                                                                                                                                               |
| 106 |     907.83994 |    275.820833 | Gareth Monger                                                                                                                                           |
| 107 |     867.57655 |    578.622039 | Tasman Dixon                                                                                                                                            |
| 108 |      82.16807 |     35.948729 | NA                                                                                                                                                      |
| 109 |     261.56039 |    457.164144 | Christoph Schomburg                                                                                                                                     |
| 110 |    1009.68581 |    172.040212 | Archaeodontosaurus (vectorized by T. Michael Keesey)                                                                                                    |
| 111 |     618.26614 |    301.565294 | Chris huh                                                                                                                                               |
| 112 |     739.89813 |    420.100671 | Steven Traver                                                                                                                                           |
| 113 |     868.32776 |    144.065339 | Mathew Wedel                                                                                                                                            |
| 114 |     666.22101 |    642.133046 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                          |
| 115 |    1005.51025 |    198.424295 | Dean Schnabel                                                                                                                                           |
| 116 |      20.41255 |    107.159336 | Andy Wilson                                                                                                                                             |
| 117 |     456.90311 |    751.966622 | Andy Wilson                                                                                                                                             |
| 118 |     125.76501 |    572.468411 | Kai R. Caspar                                                                                                                                           |
| 119 |     204.38138 |    699.851534 | NA                                                                                                                                                      |
| 120 |     938.76393 |     13.502234 | Margot Michaud                                                                                                                                          |
| 121 |     988.09308 |    289.282517 | Matt Crook                                                                                                                                              |
| 122 |     973.55391 |    689.879586 | André Karwath (vectorized by T. Michael Keesey)                                                                                                         |
| 123 |     866.69234 |    636.355778 | Steven Traver                                                                                                                                           |
| 124 |     502.51244 |    376.887795 | NA                                                                                                                                                      |
| 125 |     903.24775 |    581.580537 | Michelle Site                                                                                                                                           |
| 126 |     761.66469 |    167.587442 | Markus A. Grohme                                                                                                                                        |
| 127 |    1012.91569 |    686.459072 | Karla Martinez                                                                                                                                          |
| 128 |     944.36960 |    332.576445 | Steven Blackwood                                                                                                                                        |
| 129 |     455.27826 |    185.024568 | NA                                                                                                                                                      |
| 130 |     798.83305 |    129.740878 | Scott Hartman                                                                                                                                           |
| 131 |     714.06354 |    460.922331 | Steven Traver                                                                                                                                           |
| 132 |     176.24727 |    567.479257 | Andy Wilson                                                                                                                                             |
| 133 |     343.04435 |    241.276198 | Scott Hartman                                                                                                                                           |
| 134 |     263.96893 |     77.975190 | Margot Michaud                                                                                                                                          |
| 135 |     981.61109 |    592.742173 | Terpsichores                                                                                                                                            |
| 136 |     360.95057 |    223.721269 | TaraTaylorDesign                                                                                                                                        |
| 137 |     279.94423 |    726.815019 | T. Michael Keesey                                                                                                                                       |
| 138 |     255.29734 |    291.768682 | C. Camilo Julián-Caballero                                                                                                                              |
| 139 |     473.03650 |     36.413987 | Scott Hartman (vectorized by William Gearty)                                                                                                            |
| 140 |     932.08842 |    282.804781 | Rachel Shoop                                                                                                                                            |
| 141 |     281.64817 |    127.693214 | Zimices                                                                                                                                                 |
| 142 |     964.57590 |     30.183674 | Jagged Fang Designs                                                                                                                                     |
| 143 |     126.71029 |    595.041381 | L. Shyamal                                                                                                                                              |
| 144 |     200.05601 |    212.652061 | Christoph Schomburg                                                                                                                                     |
| 145 |     898.89755 |    227.059594 | Jagged Fang Designs                                                                                                                                     |
| 146 |     274.72529 |    743.973535 | C. Camilo Julián-Caballero                                                                                                                              |
| 147 |     983.91911 |    611.508715 | Emily Jane McTavish, from <http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>                                             |
| 148 |     425.33196 |    729.350873 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                        |
| 149 |     578.85196 |      5.956671 | T. Michael Keesey (after Mauricio Antón)                                                                                                                |
| 150 |     985.14756 |    790.902757 | Margot Michaud                                                                                                                                          |
| 151 |     541.55639 |     16.773125 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                       |
| 152 |     360.42897 |    510.551814 | Henry Lydecker                                                                                                                                          |
| 153 |     340.81089 |    101.741976 | Zimices                                                                                                                                                 |
| 154 |      19.81722 |    174.860120 | Josefine Bohr Brask                                                                                                                                     |
| 155 |     598.90764 |    464.940849 | C. Camilo Julián-Caballero                                                                                                                              |
| 156 |     825.52742 |    564.946506 | NOAA (vectorized by T. Michael Keesey)                                                                                                                  |
| 157 |     975.71872 |     45.274206 | Matt Crook                                                                                                                                              |
| 158 |     158.56658 |    278.520686 | Markus A. Grohme                                                                                                                                        |
| 159 |     964.71195 |    517.004647 | Ferran Sayol                                                                                                                                            |
| 160 |     960.79280 |    562.342827 | Scott Hartman                                                                                                                                           |
| 161 |     396.95828 |    193.200124 | Gareth Monger                                                                                                                                           |
| 162 |     238.30949 |    644.360703 | Matt Crook                                                                                                                                              |
| 163 |     137.13263 |    185.179951 | Matt Crook                                                                                                                                              |
| 164 |     839.52131 |    137.557959 | Abraão B. Leite                                                                                                                                         |
| 165 |     293.96814 |    151.478277 | Alexander Schmidt-Lebuhn                                                                                                                                |
| 166 |     461.35683 |    556.147236 | Markus A. Grohme                                                                                                                                        |
| 167 |     207.60811 |    100.720517 | JCGiron                                                                                                                                                 |
| 168 |     636.26354 |    152.893434 | Scott Hartman                                                                                                                                           |
| 169 |     462.27770 |    281.883278 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                           |
| 170 |     710.16488 |    236.829490 | Carlos Cano-Barbacil                                                                                                                                    |
| 171 |     735.62811 |    407.286773 | Margot Michaud                                                                                                                                          |
| 172 |     246.31968 |    614.951852 | Christoph Schomburg                                                                                                                                     |
| 173 |     774.14098 |    150.950998 | Zimices                                                                                                                                                 |
| 174 |     170.79142 |     75.495394 | Margot Michaud                                                                                                                                          |
| 175 |     281.03131 |    230.224086 | Zimices                                                                                                                                                 |
| 176 |     221.49189 |    719.725544 | kotik                                                                                                                                                   |
| 177 |      31.44190 |    147.436923 | Tracy A. Heath                                                                                                                                          |
| 178 |     251.55357 |    376.976737 | Felix Vaux                                                                                                                                              |
| 179 |      20.46895 |    313.555532 | L. Shyamal                                                                                                                                              |
| 180 |      51.49897 |    449.195286 | Margot Michaud                                                                                                                                          |
| 181 |      28.97930 |    542.248035 | Melissa Broussard                                                                                                                                       |
| 182 |     780.85188 |    642.465243 | Gareth Monger                                                                                                                                           |
| 183 |     390.59460 |    639.621371 | Johan Lindgren, Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe                                                                                    |
| 184 |     986.01053 |    220.734444 | NA                                                                                                                                                      |
| 185 |     791.07316 |    533.111203 | Matt Crook                                                                                                                                              |
| 186 |      25.64780 |    574.659837 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                            |
| 187 |     553.36971 |    467.374427 | Sarah Werning                                                                                                                                           |
| 188 |     905.82669 |    371.080638 | Kamil S. Jaron                                                                                                                                          |
| 189 |     271.47642 |    115.576263 | Carlos Cano-Barbacil                                                                                                                                    |
| 190 |     185.79927 |    269.269139 | Matt Crook                                                                                                                                              |
| 191 |     232.60402 |    506.398105 | Steven Coombs                                                                                                                                           |
| 192 |     736.89384 |    333.983326 | Nobu Tamura, vectorized by Zimices                                                                                                                      |
| 193 |      31.12531 |    363.381866 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                           |
| 194 |     523.30040 |    558.056529 | Matt Martyniuk                                                                                                                                          |
| 195 |     429.34255 |    212.246558 | L. Shyamal                                                                                                                                              |
| 196 |     547.40585 |    615.373342 | NA                                                                                                                                                      |
| 197 |     545.88523 |     99.791780 | T. Michael Keesey                                                                                                                                       |
| 198 |     667.61562 |    460.589496 | NA                                                                                                                                                      |
| 199 |     835.53395 |    185.798882 | White Wolf                                                                                                                                              |
| 200 |     999.37215 |    363.824138 | Ghedo (vectorized by T. Michael Keesey)                                                                                                                 |
| 201 |    1000.60915 |     82.123389 | Gareth Monger                                                                                                                                           |
| 202 |     566.48132 |    715.677660 | Matt Hayes                                                                                                                                              |
| 203 |     768.08612 |    475.337483 | Margot Michaud                                                                                                                                          |
| 204 |     536.14789 |    321.114807 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                       |
| 205 |     810.03071 |     77.802589 | NA                                                                                                                                                      |
| 206 |     586.98076 |    394.147063 | T. Michael Keesey                                                                                                                                       |
| 207 |     739.92188 |    242.886176 | Zimices                                                                                                                                                 |
| 208 |     789.37447 |    674.379180 | Scott Hartman                                                                                                                                           |
| 209 |     615.57971 |    215.638823 | Ville Koistinen (vectorized by T. Michael Keesey)                                                                                                       |
| 210 |     872.27769 |    100.611746 | Birgit Lang                                                                                                                                             |
| 211 |     868.29015 |    620.380742 | Noah Schlottman, photo by Casey Dunn                                                                                                                    |
| 212 |      17.87800 |    775.148481 | Mathew Wedel                                                                                                                                            |
| 213 |     323.13725 |    791.885323 | Steven Traver                                                                                                                                           |
| 214 |     344.59750 |    380.066985 | Beth Reinke                                                                                                                                             |
| 215 |     388.51956 |    102.556991 | Matt Wilkins (photo by Patrick Kavanagh)                                                                                                                |
| 216 |     191.57834 |    455.220479 | Margot Michaud                                                                                                                                          |
| 217 |     568.79562 |    637.817894 | NA                                                                                                                                                      |
| 218 |     304.18379 |     96.006516 | Giant Blue Anteater (vectorized by T. Michael Keesey)                                                                                                   |
| 219 |     224.95782 |    596.361325 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                       |
| 220 |     560.65636 |    412.190613 | Matt Crook                                                                                                                                              |
| 221 |     422.96589 |    781.516983 | Scott Hartman                                                                                                                                           |
| 222 |     987.39364 |    653.049807 | Margot Michaud                                                                                                                                          |
| 223 |     149.17603 |    100.398664 | Margot Michaud                                                                                                                                          |
| 224 |     864.84346 |    502.479150 | Christoph Schomburg                                                                                                                                     |
| 225 |     654.31227 |    107.556644 | Chuanixn Yu                                                                                                                                             |
| 226 |     444.83006 |    735.165216 | Christine Axon                                                                                                                                          |
| 227 |      22.61565 |    678.600869 | Cesar Julian                                                                                                                                            |
| 228 |     637.87665 |    210.776323 | Margot Michaud                                                                                                                                          |
| 229 |    1006.15429 |     19.983361 | Emily Willoughby                                                                                                                                        |
| 230 |     341.37489 |    496.416178 | Joshua Fowler                                                                                                                                           |
| 231 |     618.46728 |    321.751589 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                            |
| 232 |      51.60892 |    600.468329 | Gabriela Palomo-Munoz                                                                                                                                   |
| 233 |     665.98585 |    419.259882 | Lafage                                                                                                                                                  |
| 234 |     419.58541 |     49.846052 | Tony Ayling (vectorized by Milton Tan)                                                                                                                  |
| 235 |     523.01484 |    423.285289 | Birgit Lang                                                                                                                                             |
| 236 |     954.45527 |    464.036330 | NA                                                                                                                                                      |
| 237 |     925.91364 |    679.822026 | Jagged Fang Designs                                                                                                                                     |
| 238 |     579.15307 |    304.730420 | Dean Schnabel                                                                                                                                           |
| 239 |      91.46590 |    596.615575 | Mathieu Pélissié                                                                                                                                        |
| 240 |     310.27803 |    118.320930 | Zimices                                                                                                                                                 |
| 241 |     822.95278 |    591.454615 | Martin R. Smith                                                                                                                                         |
| 242 |      32.93070 |    420.948408 | Zimices                                                                                                                                                 |
| 243 |      31.99345 |    748.333373 | Markus A. Grohme                                                                                                                                        |
| 244 |     444.26423 |    512.405750 | S.Martini                                                                                                                                               |
| 245 |     206.08260 |    377.571774 | Ieuan Jones                                                                                                                                             |
| 246 |     738.42264 |    523.334625 | NA                                                                                                                                                      |
| 247 |     485.86652 |    669.756246 | Carlos Cano-Barbacil                                                                                                                                    |
| 248 |     306.72741 |    428.157134 | Nobu Tamura, modified by Andrew A. Farke                                                                                                                |
| 249 |     477.35107 |    219.665867 | Manabu Sakamoto                                                                                                                                         |
| 250 |     145.32797 |    703.547716 | Tod Robbins                                                                                                                                             |
| 251 |     761.70518 |    783.546686 | Zimices                                                                                                                                                 |
| 252 |      42.62647 |    268.012917 | Jakovche                                                                                                                                                |
| 253 |     589.04805 |    624.193466 | SecretJellyMan                                                                                                                                          |
| 254 |     604.13866 |    278.831552 | Jake Warner                                                                                                                                             |
| 255 |     532.88652 |    488.414697 | Zimices                                                                                                                                                 |
| 256 |     842.72852 |    436.361552 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                           |
| 257 |     643.90590 |    474.680724 | Andy Wilson                                                                                                                                             |
| 258 |      32.61116 |     48.013907 | NA                                                                                                                                                      |
| 259 |     250.21521 |    706.116037 | Tauana J. Cunha                                                                                                                                         |
| 260 |     686.11467 |    432.892935 | Mathilde Cordellier                                                                                                                                     |
| 261 |     986.23778 |    171.225096 | Chris huh                                                                                                                                               |
| 262 |     645.01132 |    741.028425 | Ferran Sayol                                                                                                                                            |
| 263 |      11.21335 |    243.747586 | Michelle Site                                                                                                                                           |
| 264 |     490.01356 |    290.616359 | Henry Lydecker                                                                                                                                          |
| 265 |     777.93620 |    502.964658 | Chris huh                                                                                                                                               |
| 266 |     366.42181 |    339.381253 | Chris huh                                                                                                                                               |
| 267 |     896.44590 |     17.242673 | Margot Michaud                                                                                                                                          |
| 268 |      51.83370 |    669.098921 | Ferran Sayol                                                                                                                                            |
| 269 |     226.24731 |     10.050400 | Armin Reindl                                                                                                                                            |
| 270 |     589.78905 |    725.053912 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                       |
| 271 |     934.67834 |    215.601024 | T. Michael Keesey                                                                                                                                       |
| 272 |     410.32534 |    192.690517 | Kelly                                                                                                                                                   |
| 273 |     156.39294 |    377.181407 | Margot Michaud                                                                                                                                          |
| 274 |     285.76565 |    470.519218 | Joanna Wolfe                                                                                                                                            |
| 275 |     708.46255 |    523.992620 | Jagged Fang Designs                                                                                                                                     |
| 276 |      15.89182 |     71.003313 | Matt Crook                                                                                                                                              |
| 277 |      97.10215 |    205.187305 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                           |
| 278 |     555.99744 |     72.190393 | Margot Michaud                                                                                                                                          |
| 279 |     659.33872 |    629.175331 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                     |
| 280 |     991.90975 |    240.777339 | Jagged Fang Designs                                                                                                                                     |
| 281 |     680.90771 |    785.610401 | Carlos Cano-Barbacil                                                                                                                                    |
| 282 |     744.28262 |    638.776707 | Chloé Schmidt                                                                                                                                           |
| 283 |     805.42220 |    622.798300 | Margot Michaud                                                                                                                                          |
| 284 |      49.00168 |    341.252718 | Gareth Monger                                                                                                                                           |
| 285 |     680.62188 |    700.450733 | Ferran Sayol                                                                                                                                            |
| 286 |     106.27421 |    665.093314 | Tasman Dixon                                                                                                                                            |
| 287 |     660.20778 |    721.066166 | Julio Garza                                                                                                                                             |
| 288 |     379.16962 |    786.940949 | Sergio A. Muñoz-Gómez                                                                                                                                   |
| 289 |     515.12866 |    458.167093 | Jaime Headden                                                                                                                                           |
| 290 |     816.91710 |    781.340463 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
| 291 |     189.89105 |     58.599493 | Mathilde Cordellier                                                                                                                                     |
| 292 |     278.03346 |    632.607621 | ArtFavor & annaleeblysse                                                                                                                                |
| 293 |    1011.36686 |    318.202857 | Trond R. Oskars                                                                                                                                         |
| 294 |     563.47420 |    749.717232 | Tasman Dixon                                                                                                                                            |
| 295 |     772.39393 |    743.718024 | Chris A. Hamilton                                                                                                                                       |
| 296 |     428.91642 |     81.800436 | NA                                                                                                                                                      |
| 297 |     948.54884 |    479.770247 | Zimices                                                                                                                                                 |
| 298 |     461.75770 |    711.534801 | Sharon Wegner-Larsen                                                                                                                                    |
| 299 |     666.13174 |    615.673106 | Smokeybjb                                                                                                                                               |
| 300 |     368.70860 |    356.837865 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                           |
| 301 |     579.56362 |    138.960963 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                       |
| 302 |     655.19636 |    242.351897 | FunkMonk                                                                                                                                                |
| 303 |     889.53096 |    531.529120 | Christine Axon                                                                                                                                          |
| 304 |     442.38011 |    603.619383 | Scott Hartman                                                                                                                                           |
| 305 |     650.37444 |    138.899616 | Skye McDavid                                                                                                                                            |
| 306 |     544.88466 |    723.871219 | Kai R. Caspar                                                                                                                                           |
| 307 |     158.14298 |    431.556685 | Birgit Lang                                                                                                                                             |
| 308 |     150.96959 |    155.849727 | TaraTaylorDesign                                                                                                                                        |
| 309 |     608.40978 |    165.851173 | Markus A. Grohme                                                                                                                                        |
| 310 |     806.15290 |    652.982544 | Birgit Lang                                                                                                                                             |
| 311 |      62.90593 |    476.099459 | T. Michael Keesey                                                                                                                                       |
| 312 |     497.87746 |    592.074415 | Tyler McCraney                                                                                                                                          |
| 313 |      15.97799 |    668.891225 | Chris huh                                                                                                                                               |
| 314 |     746.37901 |    363.547884 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                           |
| 315 |     536.85788 |     35.201819 | Christine Axon                                                                                                                                          |
| 316 |     258.23002 |     98.835182 | Ferran Sayol                                                                                                                                            |
| 317 |     313.57407 |    418.692722 | Carlos Cano-Barbacil                                                                                                                                    |
| 318 |     907.80642 |    418.568942 | Steven Traver                                                                                                                                           |
| 319 |     344.30078 |    724.864035 | NA                                                                                                                                                      |
| 320 |     160.96033 |      6.478219 | Frank Denota                                                                                                                                            |
| 321 |     798.37865 |    354.859585 | Caio Bernardes, vectorized by Zimices                                                                                                                   |
| 322 |     394.97413 |    291.706454 | Katie S. Collins                                                                                                                                        |
| 323 |     535.36047 |    359.199684 | Collin Gross                                                                                                                                            |
| 324 |     437.97078 |    272.593865 | Mykle Hoban                                                                                                                                             |
| 325 |     828.48287 |    706.502287 | Andy Wilson                                                                                                                                             |
| 326 |     242.80138 |    220.598927 | Matt Crook                                                                                                                                              |
| 327 |      36.90694 |    295.461107 | Chris Jennings (vectorized by A. Verrière)                                                                                                              |
| 328 |     142.89690 |    713.452828 | Inessa Voet                                                                                                                                             |
| 329 |     752.48204 |    305.095796 | Caleb M. Brown                                                                                                                                          |
| 330 |     980.83475 |    479.104460 | Margot Michaud                                                                                                                                          |
| 331 |     768.52942 |     47.458464 | Ben Liebeskind                                                                                                                                          |
| 332 |     133.17731 |    290.643165 | Markus A. Grohme                                                                                                                                        |
| 333 |     144.85257 |    778.134998 | Sharon Wegner-Larsen                                                                                                                                    |
| 334 |      97.94356 |    184.430619 | Matt Crook                                                                                                                                              |
| 335 |     247.59017 |    774.344454 | NA                                                                                                                                                      |
| 336 |     741.50515 |     59.168466 | Alexandre Vong                                                                                                                                          |
| 337 |     590.13576 |    481.620843 | Markus A. Grohme                                                                                                                                        |
| 338 |     571.08294 |    189.410017 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                |
| 339 |      25.80938 |    722.914505 | Steven Traver                                                                                                                                           |
| 340 |     907.94981 |    564.453371 | Chris huh                                                                                                                                               |
| 341 |     216.85473 |    667.254392 | Andrew A. Farke, modified from original by Robert Bruce Horsfall, from Scott 1912                                                                       |
| 342 |     516.31200 |    188.393855 | Matt Crook                                                                                                                                              |
| 343 |     153.54421 |    468.874412 | Andy Wilson                                                                                                                                             |
| 344 |      22.57185 |    279.381842 | Andrew A. Farke, shell lines added by Yan Wong                                                                                                          |
| 345 |     240.17485 |    437.390937 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                           |
| 346 |     269.72518 |    398.898454 | Ewald Rübsamen                                                                                                                                          |
| 347 |     284.07847 |    492.388290 | NA                                                                                                                                                      |
| 348 |     597.42481 |    648.251355 | Ron Holmes/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                            |
| 349 |     352.77876 |    787.156514 | Steven Traver                                                                                                                                           |
| 350 |     884.31558 |    379.037733 | Matt Crook                                                                                                                                              |
| 351 |     400.77108 |    575.595611 | Ferran Sayol                                                                                                                                            |
| 352 |     441.40222 |    673.076260 | Tauana J. Cunha                                                                                                                                         |
| 353 |     378.94359 |    492.167084 | Jagged Fang Designs                                                                                                                                     |
| 354 |     765.68839 |    527.958868 | NASA                                                                                                                                                    |
| 355 |     973.78950 |     13.329855 | Felix Vaux                                                                                                                                              |
| 356 |     979.21065 |    192.575059 | Crystal Maier                                                                                                                                           |
| 357 |     386.37036 |    220.156204 | L. Shyamal                                                                                                                                              |
| 358 |     520.56238 |    719.080993 | Matt Crook                                                                                                                                              |
| 359 |      66.28533 |    292.095905 | Scott Hartman                                                                                                                                           |
| 360 |     779.79282 |    795.310545 | Ignacio Contreras                                                                                                                                       |
| 361 |     344.26171 |    589.456826 | Steven Traver                                                                                                                                           |
| 362 |     856.42011 |    278.098774 | Jagged Fang Designs                                                                                                                                     |
| 363 |    1004.04724 |    587.813416 | Donovan Reginald Rosevear (vectorized by T. Michael Keesey)                                                                                             |
| 364 |      16.60774 |    493.118868 | Matt Crook                                                                                                                                              |
| 365 |     935.51167 |    262.374437 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                       |
| 366 |     714.16259 |     70.752694 | Markus A. Grohme                                                                                                                                        |
| 367 |    1006.19026 |    636.881206 | Chris huh                                                                                                                                               |
| 368 |     919.30621 |     55.200842 | Chuanixn Yu                                                                                                                                             |
| 369 |      19.46097 |    611.922541 | Michael Scroggie                                                                                                                                        |
| 370 |     596.74131 |    241.428402 | Markus A. Grohme                                                                                                                                        |
| 371 |     563.38526 |     90.593304 | Harold N Eyster                                                                                                                                         |
| 372 |     494.87133 |    139.366696 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                        |
| 373 |     812.04493 |    427.879244 | Scott Hartman                                                                                                                                           |
| 374 |     705.84181 |    626.458798 | Matt Crook                                                                                                                                              |
| 375 |     441.77053 |     40.581659 | Zimices                                                                                                                                                 |
| 376 |     382.75549 |    373.929968 | Chris huh                                                                                                                                               |
| 377 |     643.22570 |    526.069550 | Margot Michaud                                                                                                                                          |
| 378 |     850.06520 |     81.997601 | Gareth Monger                                                                                                                                           |
| 379 |     372.53484 |    324.637532 | Mathew Wedel                                                                                                                                            |
| 380 |     473.84287 |    263.668452 | Michael “FunkMonk” B. H. (vectorized by T. Michael Keesey)                                                                                              |
| 381 |     684.26299 |    245.185505 | NA                                                                                                                                                      |
| 382 |     162.36987 |     62.641422 | Audrey Ely                                                                                                                                              |
| 383 |     171.49968 |    206.829666 | Margot Michaud                                                                                                                                          |
| 384 |     271.96872 |     10.840152 | Zimices / Julián Bayona                                                                                                                                 |
| 385 |     393.68560 |    385.996032 | Margot Michaud                                                                                                                                          |
| 386 |     303.41012 |    510.775508 | Markus A. Grohme                                                                                                                                        |
| 387 |     528.06240 |    201.436923 | Zimices                                                                                                                                                 |
| 388 |     383.42951 |     34.323754 | Scott Hartman                                                                                                                                           |
| 389 |     959.05567 |    368.276919 | Zimices                                                                                                                                                 |
| 390 |     791.83192 |    191.475540 | Zimices                                                                                                                                                 |
| 391 |      57.68060 |    723.040819 | NA                                                                                                                                                      |
| 392 |     862.70697 |    733.502993 | Markus A. Grohme                                                                                                                                        |
| 393 |     186.43183 |    705.618937 | Scott Hartman                                                                                                                                           |
| 394 |     341.22752 |    430.973521 | Y. de Hoev. (vectorized by T. Michael Keesey)                                                                                                           |
| 395 |     346.85214 |    543.459131 | Gareth Monger                                                                                                                                           |
| 396 |     637.52122 |      8.757665 | Chris huh                                                                                                                                               |
| 397 |     926.75559 |    346.862335 | Markus A. Grohme                                                                                                                                        |
| 398 |     734.19557 |    477.798842 | Steven Coombs                                                                                                                                           |
| 399 |     463.93054 |    389.664370 | Frank Denota                                                                                                                                            |
| 400 |      92.41500 |    678.123483 | Zimices                                                                                                                                                 |
| 401 |     378.64486 |    427.683284 | Zimices                                                                                                                                                 |
| 402 |     188.97478 |    682.305238 | Nobu Tamura                                                                                                                                             |
| 403 |     474.77751 |    686.325949 | Beth Reinke                                                                                                                                             |
| 404 |     885.02213 |    281.126414 | Mathew Callaghan                                                                                                                                        |
| 405 |    1007.27718 |    779.959557 | Kent Sorgon                                                                                                                                             |
| 406 |     318.34560 |    746.413150 | Ferran Sayol                                                                                                                                            |
| 407 |     907.96666 |    662.997281 | Chloé Schmidt                                                                                                                                           |
| 408 |     568.17806 |    572.481690 | Joanna Wolfe                                                                                                                                            |
| 409 |     868.89403 |     10.359968 | Jagged Fang Designs                                                                                                                                     |
| 410 |     740.90496 |     31.087936 | Mali’o Kodis, image from the “Proceedings of the Zoological Society of London”                                                                          |
| 411 |     454.02398 |    212.312892 | T. Michael Keesey                                                                                                                                       |
| 412 |     981.70274 |    375.276202 | Mathieu Basille                                                                                                                                         |
| 413 |     922.55078 |    791.276244 | Duane Raver (vectorized by T. Michael Keesey)                                                                                                           |
| 414 |     886.94249 |    107.114753 | Andy Wilson                                                                                                                                             |
| 415 |     426.13363 |    562.188162 | Tasman Dixon                                                                                                                                            |
| 416 |     525.07172 |     85.856843 | Dean Schnabel                                                                                                                                           |
| 417 |     513.61353 |     46.014060 | Derek Bakken (photograph) and T. Michael Keesey (vectorization)                                                                                         |
| 418 |    1014.98277 |     38.623000 | Matt Crook                                                                                                                                              |
| 419 |    1007.96071 |    670.053285 | Birgit Lang                                                                                                                                             |
| 420 |     958.62605 |    342.116749 | Caleb M. Brown                                                                                                                                          |
| 421 |     430.63487 |    431.996814 | Scott Hartman                                                                                                                                           |
| 422 |     524.56346 |    343.802302 | Steven Traver                                                                                                                                           |
| 423 |     810.14096 |     58.652735 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                           |
| 424 |     888.72885 |    741.383914 | C. Camilo Julián-Caballero                                                                                                                              |
| 425 |     884.95790 |    624.445235 | Matt Crook                                                                                                                                              |
| 426 |     201.40702 |     79.411194 | Ferran Sayol                                                                                                                                            |
| 427 |     992.90445 |     65.618440 | Gabriela Palomo-Munoz                                                                                                                                   |
| 428 |     617.09972 |    361.380435 | Gareth Monger                                                                                                                                           |
| 429 |     571.39915 |     36.495011 | Ingo Braasch                                                                                                                                            |
| 430 |      34.98095 |    351.636248 | Jagged Fang Designs                                                                                                                                     |
| 431 |     193.90583 |     39.139827 | Gustav Mützel                                                                                                                                           |
| 432 |     226.37835 |     30.150314 | Tasman Dixon                                                                                                                                            |
| 433 |    1003.59500 |    260.810312 | Chase Brownstein                                                                                                                                        |
| 434 |     120.51322 |    158.134934 | Scott Hartman                                                                                                                                           |
| 435 |     129.64388 |    682.217622 | NA                                                                                                                                                      |
| 436 |      19.81028 |    121.417378 | Chris huh                                                                                                                                               |
| 437 |     594.58083 |    225.811509 | Birgit Lang                                                                                                                                             |
| 438 |     868.21585 |    361.786874 | T. Michael Keesey (vector) and Stuart Halliday (photograph)                                                                                             |
| 439 |     145.82548 |     42.607768 | Dean Schnabel                                                                                                                                           |
| 440 |      20.64282 |    739.431811 | Bruno Maggia                                                                                                                                            |
| 441 |     498.23645 |    615.117919 | Margot Michaud                                                                                                                                          |
| 442 |     788.86315 |    444.888408 | Jagged Fang Designs                                                                                                                                     |
| 443 |     441.12768 |    192.510678 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                             |
| 444 |     651.59933 |    190.579036 | Felix Vaux                                                                                                                                              |
| 445 |     967.64139 |    540.261686 | Zimices                                                                                                                                                 |
| 446 |      92.48346 |    163.531307 | NA                                                                                                                                                      |
| 447 |     906.65553 |    190.974372 | Michael Scroggie                                                                                                                                        |
| 448 |     426.22134 |     30.796331 | (unknown)                                                                                                                                               |
| 449 |     901.57531 |    243.579796 | Chris huh                                                                                                                                               |
| 450 |     108.17873 |    425.749634 | C. Abraczinskas                                                                                                                                         |
| 451 |     858.51951 |    422.807160 | Bruno Maggia                                                                                                                                            |
| 452 |     890.59701 |    551.319216 | NA                                                                                                                                                      |
| 453 |     732.18381 |    654.989400 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                          |
| 454 |     837.43800 |    196.447760 | Dean Schnabel                                                                                                                                           |
| 455 |     695.23478 |    462.159515 | Burton Robert, USFWS                                                                                                                                    |
| 456 |      60.71624 |    161.867791 | Michael P. Taylor                                                                                                                                       |
| 457 |     312.15423 |    489.511153 | Ferran Sayol                                                                                                                                            |
| 458 |     521.19301 |    635.706691 | Gareth Monger                                                                                                                                           |
| 459 |     766.23656 |    180.960242 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                            |
| 460 |     547.28652 |    403.267690 | Smokeybjb                                                                                                                                               |
| 461 |     341.22891 |    756.728467 | Kent Sorgon                                                                                                                                             |
| 462 |     405.58439 |     96.264072 | Gabriela Palomo-Munoz                                                                                                                                   |
| 463 |      61.12126 |    359.894195 | John Gould (vectorized by T. Michael Keesey)                                                                                                            |
| 464 |    1006.48183 |    619.333679 | Gareth Monger                                                                                                                                           |
| 465 |     395.77749 |    611.246528 | Markus A. Grohme                                                                                                                                        |
| 466 |     661.47109 |    653.348823 | Beth Reinke                                                                                                                                             |
| 467 |      24.32588 |    589.886428 | Gareth Monger                                                                                                                                           |
| 468 |     230.81618 |    458.187857 | Scott Hartman                                                                                                                                           |
| 469 |     780.84323 |     90.642881 | Jonathan Wells                                                                                                                                          |
| 470 |     743.67452 |    168.589486 | Meyers Konversations-Lexikon 1897 (vectorized: Yan Wong)                                                                                                |
| 471 |      63.72569 |     35.551760 | Gabriela Palomo-Munoz                                                                                                                                   |
| 472 |      97.05163 |    732.764200 | Tim Bertelink (modified by T. Michael Keesey)                                                                                                           |
| 473 |      82.96955 |     12.210923 | Margot Michaud                                                                                                                                          |
| 474 |     881.25572 |    646.802024 | Diana Pomeroy                                                                                                                                           |
| 475 |     678.04001 |    278.942177 | Duane Raver/USFWS                                                                                                                                       |
| 476 |     545.69462 |    560.275055 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                 |
| 477 |     317.90629 |    587.956135 | Rebecca Groom                                                                                                                                           |
| 478 |     414.54093 |    769.108314 | Scott Hartman                                                                                                                                           |
| 479 |     504.87471 |    123.863993 | Scott Hartman                                                                                                                                           |
| 480 |     728.05492 |    789.760114 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                            |
| 481 |     723.47872 |    401.204274 | Joanna Wolfe                                                                                                                                            |
| 482 |     221.34250 |     88.688483 | Ferran Sayol                                                                                                                                            |
| 483 |     290.31005 |    434.162795 | Sarah Werning                                                                                                                                           |
| 484 |     570.44058 |    738.419577 | NA                                                                                                                                                      |
| 485 |      11.05440 |    752.999264 | Andy Wilson                                                                                                                                             |
| 486 |      17.50635 |    395.269007 | Amanda Katzer                                                                                                                                           |
| 487 |     788.45962 |    680.369626 | C. Camilo Julián-Caballero                                                                                                                              |
| 488 |     648.36345 |    608.101845 | Dexter R. Mardis                                                                                                                                        |
| 489 |     732.65926 |    316.181959 | Steven Traver                                                                                                                                           |
| 490 |     502.41635 |    651.017349 | Scott Hartman                                                                                                                                           |
| 491 |     483.47389 |    570.413410 | Scott Hartman                                                                                                                                           |
| 492 |     715.80219 |    320.128827 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                            |
| 493 |     946.85603 |    769.212886 | Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael Keesey)                                                                  |
| 494 |     294.89781 |    794.310384 | Mattia Menchetti / Yan Wong                                                                                                                             |
| 495 |      61.47257 |    515.231120 | Scott Hartman                                                                                                                                           |
| 496 |     369.83877 |    185.579037 | Fritz Geller-Grimm (vectorized by T. Michael Keesey)                                                                                                    |
| 497 |     700.19458 |    772.726528 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                      |
| 498 |     595.49181 |    115.825801 | Tracy A. Heath                                                                                                                                          |
| 499 |     828.44104 |    340.776756 | Emma Kissling                                                                                                                                           |
| 500 |     845.80431 |    597.872792 | Kamil S. Jaron                                                                                                                                          |
| 501 |     876.66083 |    351.554715 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                   |
| 502 |     606.24655 |     18.388539 | Ignacio Contreras                                                                                                                                       |
| 503 |     625.93926 |    415.968102 | Margot Michaud                                                                                                                                          |
| 504 |      59.80965 |    784.076965 | Zimices                                                                                                                                                 |
| 505 |     750.61290 |    617.844039 | Matt Crook                                                                                                                                              |
| 506 |     507.39839 |    437.262531 | Christoph Schomburg                                                                                                                                     |
| 507 |     916.68595 |     21.070807 | Jagged Fang Designs                                                                                                                                     |
| 508 |     810.17216 |    406.743584 | Markus A. Grohme                                                                                                                                        |
| 509 |     961.74292 |    245.968573 | Margot Michaud                                                                                                                                          |
| 510 |      33.10702 |    185.764644 | Chris huh                                                                                                                                               |
| 511 |     745.11238 |    532.792381 | Margot Michaud                                                                                                                                          |
| 512 |     122.63058 |      7.356835 | Chris huh                                                                                                                                               |
| 513 |     249.56978 |    793.868770 | Margot Michaud                                                                                                                                          |
| 514 |     484.80877 |    271.539184 | Markus A. Grohme                                                                                                                                        |
| 515 |     303.46945 |    719.569124 | Margot Michaud                                                                                                                                          |
| 516 |     470.62838 |     10.940905 | Matus Valach                                                                                                                                            |
| 517 |     319.80942 |    735.737544 | Chris huh                                                                                                                                               |
| 518 |     572.90735 |    488.216006 | Dmitry Bogdanov                                                                                                                                         |
| 519 |     264.31068 |    591.269832 | Thibaut Brunet                                                                                                                                          |
| 520 |     434.56918 |    488.977673 | Steven Traver                                                                                                                                           |
| 521 |     317.73643 |    167.691231 | Michael B. H. (vectorized by T. Michael Keesey)                                                                                                         |
| 522 |     611.55350 |    516.910721 | Anthony Caravaggi                                                                                                                                       |
| 523 |     864.82976 |    385.193188 | Neil Kelley                                                                                                                                             |
| 524 |     544.65717 |    585.987632 | Scott Hartman                                                                                                                                           |
| 525 |     596.96064 |    260.691306 | Sarah Werning                                                                                                                                           |
| 526 |     748.31822 |    551.551031 | Matt Martyniuk                                                                                                                                          |
| 527 |     164.22398 |    331.999810 | Margot Michaud                                                                                                                                          |
| 528 |     921.36348 |    577.141516 | Andy Wilson                                                                                                                                             |
| 529 |     206.81534 |    574.347280 | Harold N Eyster                                                                                                                                         |
| 530 |     283.38365 |    504.517116 | T. Michael Keesey (after Heinrich Harder)                                                                                                               |
| 531 |     877.44049 |    262.979497 | Markus A. Grohme                                                                                                                                        |
| 532 |     164.53986 |    169.964072 | NA                                                                                                                                                      |
| 533 |     277.54099 |    655.916227 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                       |
| 534 |     758.77155 |    351.309883 | Gareth Monger                                                                                                                                           |
| 535 |    1009.21745 |    230.574964 | Greg Schechter (original photo), Renato Santos (vector silhouette)                                                                                      |
| 536 |    1005.19372 |      9.631090 | Tasman Dixon                                                                                                                                            |
| 537 |     794.40226 |    340.096124 | Collin Gross                                                                                                                                            |
| 538 |     988.67928 |    766.666733 | T. Michael Keesey                                                                                                                                       |
| 539 |     595.69103 |    153.148780 | Scott Hartman                                                                                                                                           |
| 540 |     335.02360 |    361.673467 | Matt Crook                                                                                                                                              |

    #> Your tweet has been posted!
