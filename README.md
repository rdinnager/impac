
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

Matt Crook, Tyler Greenfield, Yan Wong from wikipedia drawing (PD:
Pearson Scott Foresman), Maija Karala, Armin Reindl, Tony Ayling, Robbie
N. Cada (modified by T. Michael Keesey), Scott Hartman, M. Garfield & K.
Anderson (modified by T. Michael Keesey), Kai R. Caspar, Jessica Anne
Miller, Ignacio Contreras, Chris huh, Mercedes Yrayzoz (vectorized by T.
Michael Keesey), T. Michael Keesey, Jagged Fang Designs, U.S. Fish and
Wildlife Service (illustration) and Timothy J. Bartley (silhouette),
Steven Coombs, Markus A. Grohme, C. W. Nash (illustration) and Timothy
J. Bartley (silhouette), L. Shyamal, Andy Wilson, Gabriela Palomo-Munoz,
Dmitry Bogdanov (vectorized by T. Michael Keesey), Steven Traver, Gareth
Monger, Darren Naish (vectorized by T. Michael Keesey), Zimices, Felix
Vaux, Lukasiniho, Ferran Sayol, Tasman Dixon, Didier Descouens
(vectorized by T. Michael Keesey),
\<U+0412\>\<U+0430\>\<U+043B\>\<U+044C\>\<U+0434\>\<U+0438\>\<U+043C\>\<U+0430\>\<U+0440\>
(vectorized by T. Michael Keesey), Nobu Tamura (vectorized by T. Michael
Keesey), Obsidian Soul (vectorized by T. Michael Keesey), Emily
Willoughby, Mette Aumala, Jack Mayer Wood, Birgit Lang, Nancy Wyman
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Lee Harding (photo), John E. McCormack, Michael G. Harvey, Brant
C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield &
T. Michael Keesey, Joris van der Ham (vectorized by T. Michael Keesey),
Smokeybjb, Scott Reid, CNZdenek, Craig Dylke, Yan Wong from photo by
Denes Emoke, Alexander Schmidt-Lebuhn, Shyamal, Joanna Wolfe, Margret
Flinsch, vectorized by Zimices, Maxime Dahirel, Dinah Challen, Margot
Michaud, Chris Jennings (vectorized by A. Verrière), Ekaterina Kopeykina
(vectorized by T. Michael Keesey), Collin Gross, Caleb M. Brown, Chris
Jennings (Risiatto), B. Duygu Özpolat, Jose Carlos Arenas-Monroy, Sean
McCann, Harold N Eyster, Sarah Werning, Alexandre Vong, Sarefo
(vectorized by T. Michael Keesey), Rebecca Groom, Michelle Site, Carlos
Cano-Barbacil, Ludwik Gasiorowski, Mali’o Kodis, photograph from
<http://commons.wikimedia.org/wiki/File:Trichoplax.jpg>, FunkMonk
\[Michael B.H.\] (modified by T. Michael Keesey), Andrew A. Farke, david
maas / dave hone, Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen
(vectorized by T. Michael Keesey), C. Camilo Julián-Caballero, Owen
Jones (derived from a CC-BY 2.0 photograph by Paulo B. Chaves), Martin
R. Smith, from photo by Jürgen Schoner, Christine Axon, Caroline
Harding, MAF (vectorized by T. Michael Keesey), Oscar Sanisidro, Dmitry
Bogdanov, Mali’o Kodis, drawing by Manvir Singh, Ingo Braasch, FunkMonk,
Kamil S. Jaron, Noah Schlottman, Mo Hassan, Tracy A. Heath, Madeleine
Price Ball, Katie S. Collins, Nobu Tamura (modified by T. Michael
Keesey), Nobu Tamura, Ray Simpson (vectorized by T. Michael Keesey),
Danielle Alba, Michael P. Taylor, Frederick William Frohawk (vectorized
by T. Michael Keesey), Robert Gay, Gopal Murali, Tony Ayling (vectorized
by T. Michael Keesey), Jaime Headden, Ben Liebeskind, M Hutchinson, Brad
McFeeters (vectorized by T. Michael Keesey), Christoph Schomburg, Yan
Wong, Nick Schooler, Pete Buchholz, David Orr, Terpsichores, Renato
Santos, Rene Martin, Zachary Quigley, Geoff Shaw, Alex Slavenko,
kreidefossilien.de, Xavier Giroux-Bougard, Mattia Menchetti / Yan Wong,
Meyers Konversations-Lexikon 1897 (vectorized: Yan Wong), Timothy Knepp
of the U.S. Fish and Wildlife Service (illustration) and Timothy J.
Bartley (silhouette), Verdilak, Jakovche, Matt Dempsey, Mason McNair,
S.Martini, Martin Kevil, Julio Garza, Kanchi Nanjo, xgirouxb, Bruno C.
Vellutini, Julie Blommaert based on photo by Sofdrakou, Cristian Osorio
& Paula Carrera, Proyecto Carnivoros Australes
(www.carnivorosaustrales.org), Cristina Guijarro, Ellen Edmonson
(illustration) and Timothy J. Bartley (silhouette), Iain Reid, Steven
Haddock • Jellywatch.org, G. M. Woodward, Emily Jane McTavish, from
Haeckel, E. H. P. A. (1904).Kunstformen der Natur. Bibliographisches,
Chase Brownstein, Mike Hanson, Dave Angelini, Cathy, Eric Moody, Jan A.
Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized
by T. Michael Keesey), Lisa Byrne, M Kolmann, Renato de Carvalho
Ferreira, Manabu Sakamoto, Ghedoghedo (vectorized by T. Michael Keesey),
Michael Scroggie, TaraTaylorDesign, T. Michael Keesey (after Heinrich
Harder), Mark Hofstetter (vectorized by T. Michael Keesey), Sharon
Wegner-Larsen, SauropodomorphMonarch, Scott Hartman, modified by T.
Michael Keesey, Juan Carlos Jerí, Mathilde Cordellier, Scott Hartman
(modified by T. Michael Keesey), Dave Souza (vectorized by T. Michael
Keesey), T. Michael Keesey (from a mount by Allis Markham), Marcos
Pérez-Losada, Jens T. Høeg & Keith A. Crandall, Ieuan Jones, Cesar
Julian, Duane Raver/USFWS, Jaime Headden, modified by T. Michael Keesey,
Mathew Wedel, Jimmy Bernot, A. H. Baldwin (vectorized by T. Michael
Keesey), Dean Schnabel, Tyler McCraney, Hugo Gruson, Emily Jane
McTavish, Nobu Tamura, vectorized by Zimices, Christian A. Masnaghetti,
Mihai Dragos (vectorized by T. Michael Keesey)

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                      |
| --: | ------------: | ------------: | :---------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |     378.86651 |    531.781797 | NA                                                                                                                                                          |
|   2 |     879.07124 |    342.158900 | Matt Crook                                                                                                                                                  |
|   3 |     392.83882 |     86.128886 | Tyler Greenfield                                                                                                                                            |
|   4 |     622.08533 |    672.101727 | Yan Wong from wikipedia drawing (PD: Pearson Scott Foresman)                                                                                                |
|   5 |     258.24546 |    698.021442 | Maija Karala                                                                                                                                                |
|   6 |      76.90443 |    764.386617 | Armin Reindl                                                                                                                                                |
|   7 |     651.25357 |    472.100927 | Tony Ayling                                                                                                                                                 |
|   8 |     881.36810 |    587.017850 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                              |
|   9 |     882.27269 |    443.647409 | Scott Hartman                                                                                                                                               |
|  10 |     810.76195 |    260.913512 | M. Garfield & K. Anderson (modified by T. Michael Keesey)                                                                                                   |
|  11 |      61.73523 |    533.835292 | Kai R. Caspar                                                                                                                                               |
|  12 |      71.71914 |    201.677649 | Jessica Anne Miller                                                                                                                                         |
|  13 |     235.88143 |    235.664801 | Matt Crook                                                                                                                                                  |
|  14 |     287.40774 |    341.574757 | Ignacio Contreras                                                                                                                                           |
|  15 |     417.84726 |    190.932415 | NA                                                                                                                                                          |
|  16 |     161.75141 |    536.501969 | Scott Hartman                                                                                                                                               |
|  17 |     623.07768 |    325.536140 | Chris huh                                                                                                                                                   |
|  18 |     812.08590 |     93.647382 | Mercedes Yrayzoz (vectorized by T. Michael Keesey)                                                                                                          |
|  19 |     262.75019 |     72.856212 | T. Michael Keesey                                                                                                                                           |
|  20 |     103.09432 |    279.115416 | Jagged Fang Designs                                                                                                                                         |
|  21 |     881.36737 |    742.520522 | Matt Crook                                                                                                                                                  |
|  22 |     627.92948 |     92.058343 | Mercedes Yrayzoz (vectorized by T. Michael Keesey)                                                                                                          |
|  23 |     762.82205 |    620.207188 | NA                                                                                                                                                          |
|  24 |     231.75956 |     18.549953 | U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                           |
|  25 |     125.19777 |    658.755040 | Steven Coombs                                                                                                                                               |
|  26 |     809.82383 |     31.998015 | Markus A. Grohme                                                                                                                                            |
|  27 |     111.52646 |    357.305723 | Jagged Fang Designs                                                                                                                                         |
|  28 |     665.81629 |    170.687972 | Chris huh                                                                                                                                                   |
|  29 |     129.81205 |    128.731513 | C. W. Nash (illustration) and Timothy J. Bartley (silhouette)                                                                                               |
|  30 |     639.12489 |    554.478141 | L. Shyamal                                                                                                                                                  |
|  31 |     715.37869 |    724.530636 | Andy Wilson                                                                                                                                                 |
|  32 |     985.61182 |    572.740533 | NA                                                                                                                                                          |
|  33 |     120.70486 |    602.378672 | Gabriela Palomo-Munoz                                                                                                                                       |
|  34 |     931.10694 |     72.151111 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                           |
|  35 |      85.66078 |    450.672404 | Steven Traver                                                                                                                                               |
|  36 |     504.24540 |     97.408550 | Gareth Monger                                                                                                                                               |
|  37 |      72.02919 |     89.950017 | Matt Crook                                                                                                                                                  |
|  38 |     367.12370 |     49.674267 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                              |
|  39 |     895.29267 |    524.595329 | Zimices                                                                                                                                                     |
|  40 |     411.65086 |    767.826094 | Steven Traver                                                                                                                                               |
|  41 |     549.06505 |    246.489503 | Gabriela Palomo-Munoz                                                                                                                                       |
|  42 |     249.65101 |    606.407845 | Felix Vaux                                                                                                                                                  |
|  43 |     522.83801 |    743.251461 | Lukasiniho                                                                                                                                                  |
|  44 |     955.24872 |    211.749146 | NA                                                                                                                                                          |
|  45 |      73.50317 |    731.293585 | Gareth Monger                                                                                                                                               |
|  46 |     658.06188 |    234.231180 | Ferran Sayol                                                                                                                                                |
|  47 |     780.42477 |    495.763282 | Tasman Dixon                                                                                                                                                |
|  48 |     781.04432 |    168.554983 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                          |
|  49 |     975.90340 |    697.369607 | \<U+0412\>\<U+0430\>\<U+043B\>\<U+044C\>\<U+0434\>\<U+0438\>\<U+043C\>\<U+0430\>\<U+0440\> (vectorized by T. Michael Keesey)                                |
|  50 |     945.12375 |    382.690067 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                               |
|  51 |     187.64564 |    174.993490 | Steven Traver                                                                                                                                               |
|  52 |     686.73971 |    400.118103 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                             |
|  53 |     307.59423 |    151.780670 | Gareth Monger                                                                                                                                               |
|  54 |     372.05187 |    291.667944 | Gareth Monger                                                                                                                                               |
|  55 |     504.90498 |    411.256516 | Felix Vaux                                                                                                                                                  |
|  56 |     316.11846 |    733.689586 | Matt Crook                                                                                                                                                  |
|  57 |      75.01742 |    677.121031 | Emily Willoughby                                                                                                                                            |
|  58 |     947.88108 |    463.305255 | Mette Aumala                                                                                                                                                |
|  59 |     149.72885 |    413.245300 | Andy Wilson                                                                                                                                                 |
|  60 |     634.12692 |    421.008608 | Jack Mayer Wood                                                                                                                                             |
|  61 |     655.86621 |    374.512469 | Scott Hartman                                                                                                                                               |
|  62 |     878.97400 |    156.117722 | Birgit Lang                                                                                                                                                 |
|  63 |     550.75471 |    151.567843 | Nancy Wyman (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
|  64 |     479.44527 |    545.120524 | Andy Wilson                                                                                                                                                 |
|  65 |     494.29076 |     51.315301 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                               |
|  66 |     772.97395 |    534.825561 | Lee Harding (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
|  67 |     789.09770 |    664.631442 | Joris van der Ham (vectorized by T. Michael Keesey)                                                                                                         |
|  68 |     677.38590 |    290.099816 | Markus A. Grohme                                                                                                                                            |
|  69 |     168.22533 |    727.194349 | Gareth Monger                                                                                                                                               |
|  70 |     761.93994 |    435.256993 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                               |
|  71 |     429.28084 |    261.562268 | Smokeybjb                                                                                                                                                   |
|  72 |     758.67850 |    376.189931 | T. Michael Keesey                                                                                                                                           |
|  73 |     896.05251 |    629.504633 | Steven Coombs                                                                                                                                               |
|  74 |     929.64818 |     23.940047 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                               |
|  75 |     961.28227 |    114.152153 | Scott Reid                                                                                                                                                  |
|  76 |     691.12995 |     32.784865 | Jagged Fang Designs                                                                                                                                         |
|  77 |     413.46708 |    714.195274 | CNZdenek                                                                                                                                                    |
|  78 |     728.29688 |    774.372177 | Craig Dylke                                                                                                                                                 |
|  79 |     663.67868 |    611.825824 | Yan Wong from photo by Denes Emoke                                                                                                                          |
|  80 |     539.37380 |    652.836060 | Alexander Schmidt-Lebuhn                                                                                                                                    |
|  81 |      17.59405 |    319.836140 | T. Michael Keesey                                                                                                                                           |
|  82 |     502.74474 |    319.965950 | Shyamal                                                                                                                                                     |
|  83 |     186.52740 |    566.476270 | Joanna Wolfe                                                                                                                                                |
|  84 |     592.69488 |    513.392803 | Steven Traver                                                                                                                                               |
|  85 |     539.15356 |     20.269633 | Margret Flinsch, vectorized by Zimices                                                                                                                      |
|  86 |     730.23875 |    100.492351 | Gareth Monger                                                                                                                                               |
|  87 |     626.06331 |    760.826765 | Maxime Dahirel                                                                                                                                              |
|  88 |     566.12914 |    375.189220 | Joanna Wolfe                                                                                                                                                |
|  89 |     428.58884 |    428.479638 | Dinah Challen                                                                                                                                               |
|  90 |     729.23793 |    234.157804 | Matt Crook                                                                                                                                                  |
|  91 |      30.94472 |    613.004726 | Margot Michaud                                                                                                                                              |
|  92 |     579.46323 |    486.752108 | Smokeybjb                                                                                                                                                   |
|  93 |     122.39573 |     27.587088 | Chris Jennings (vectorized by A. Verrière)                                                                                                                  |
|  94 |     169.33728 |     79.671230 | Margot Michaud                                                                                                                                              |
|  95 |     941.43159 |    412.757593 | NA                                                                                                                                                          |
|  96 |     988.57395 |    299.846165 | Ekaterina Kopeykina (vectorized by T. Michael Keesey)                                                                                                       |
|  97 |      41.15524 |    575.207481 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                               |
|  98 |     815.36400 |    701.614924 | CNZdenek                                                                                                                                                    |
|  99 |     516.73197 |    360.735617 | Chris huh                                                                                                                                                   |
| 100 |      57.97800 |    331.592671 | Chris huh                                                                                                                                                   |
| 101 |     185.94373 |    510.283778 | Collin Gross                                                                                                                                                |
| 102 |     150.92453 |      5.490327 | Markus A. Grohme                                                                                                                                            |
| 103 |     353.21425 |    112.444853 | Birgit Lang                                                                                                                                                 |
| 104 |     177.44577 |    155.856961 | Caleb M. Brown                                                                                                                                              |
| 105 |     704.65087 |    438.775032 | Chris Jennings (Risiatto)                                                                                                                                   |
| 106 |     755.31300 |    465.046607 | B. Duygu Özpolat                                                                                                                                            |
| 107 |     601.23252 |    643.762517 | Chris huh                                                                                                                                                   |
| 108 |     144.31052 |    234.002134 | Steven Traver                                                                                                                                               |
| 109 |     587.56991 |    582.822501 | Jose Carlos Arenas-Monroy                                                                                                                                   |
| 110 |     471.04601 |    359.165585 | NA                                                                                                                                                          |
| 111 |     550.40359 |    697.526096 | Sean McCann                                                                                                                                                 |
| 112 |    1001.75634 |    407.001710 | NA                                                                                                                                                          |
| 113 |     371.67052 |     30.679225 | Harold N Eyster                                                                                                                                             |
| 114 |     855.62732 |    473.826098 | Matt Crook                                                                                                                                                  |
| 115 |     552.42494 |    599.254772 | Sarah Werning                                                                                                                                               |
| 116 |     576.66731 |    625.722476 | Alexandre Vong                                                                                                                                              |
| 117 |     166.26517 |    635.132451 | Birgit Lang                                                                                                                                                 |
| 118 |     540.60142 |    777.704656 | Sarefo (vectorized by T. Michael Keesey)                                                                                                                    |
| 119 |     267.94570 |    381.457494 | T. Michael Keesey                                                                                                                                           |
| 120 |     756.51794 |    341.413043 | Gabriela Palomo-Munoz                                                                                                                                       |
| 121 |     798.64653 |    767.417998 | Birgit Lang                                                                                                                                                 |
| 122 |     444.12679 |     20.627220 | Rebecca Groom                                                                                                                                               |
| 123 |     214.12520 |    112.516662 | Armin Reindl                                                                                                                                                |
| 124 |     731.18846 |     58.527422 | Michelle Site                                                                                                                                               |
| 125 |      58.63178 |     45.602010 | Gabriela Palomo-Munoz                                                                                                                                       |
| 126 |     953.29098 |     88.512676 | Zimices                                                                                                                                                     |
| 127 |     818.11182 |    541.237158 | Carlos Cano-Barbacil                                                                                                                                        |
| 128 |     760.96290 |    405.025953 | Zimices                                                                                                                                                     |
| 129 |     248.29482 |    558.494534 | Ludwik Gasiorowski                                                                                                                                          |
| 130 |     391.82630 |    381.905655 | Margot Michaud                                                                                                                                              |
| 131 |     527.36071 |    285.777597 | Alexander Schmidt-Lebuhn                                                                                                                                    |
| 132 |      59.51339 |    139.048006 | NA                                                                                                                                                          |
| 133 |     950.43739 |    772.857352 | Caleb M. Brown                                                                                                                                              |
| 134 |     992.74245 |    342.667410 | Mali’o Kodis, photograph from <http://commons.wikimedia.org/wiki/File:Trichoplax.jpg>                                                                       |
| 135 |     159.08938 |    436.439623 | FunkMonk \[Michael B.H.\] (modified by T. Michael Keesey)                                                                                                   |
| 136 |      98.85953 |    101.253411 | Matt Crook                                                                                                                                                  |
| 137 |     588.59646 |     36.160557 | Ferran Sayol                                                                                                                                                |
| 138 |     303.15577 |    789.360895 | Gabriela Palomo-Munoz                                                                                                                                       |
| 139 |     437.58863 |     63.740808 | Zimices                                                                                                                                                     |
| 140 |     667.04763 |    646.751806 | Chris huh                                                                                                                                                   |
| 141 |      16.44726 |    151.034404 | NA                                                                                                                                                          |
| 142 |     263.40930 |    541.930369 | Tasman Dixon                                                                                                                                                |
| 143 |     781.93680 |    573.350267 | Andrew A. Farke                                                                                                                                             |
| 144 |     497.87881 |    379.886153 | david maas / dave hone                                                                                                                                      |
| 145 |     260.89539 |    120.161852 | Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael Keesey)                                                                      |
| 146 |     631.76240 |    702.538987 | Gareth Monger                                                                                                                                               |
| 147 |     884.67182 |    191.158070 | Matt Crook                                                                                                                                                  |
| 148 |     809.08255 |    338.473475 | C. Camilo Julián-Caballero                                                                                                                                  |
| 149 |     335.66179 |    185.475258 | T. Michael Keesey                                                                                                                                           |
| 150 |     956.46737 |    602.771126 | Owen Jones (derived from a CC-BY 2.0 photograph by Paulo B. Chaves)                                                                                         |
| 151 |     337.78764 |    379.596584 | Tasman Dixon                                                                                                                                                |
| 152 |     991.58441 |    387.057335 | Martin R. Smith, from photo by Jürgen Schoner                                                                                                               |
| 153 |     684.19605 |    216.703657 | Christine Axon                                                                                                                                              |
| 154 |     395.33905 |    239.329495 | Chris huh                                                                                                                                                   |
| 155 |     733.23316 |     23.403446 | Caroline Harding, MAF (vectorized by T. Michael Keesey)                                                                                                     |
| 156 |     432.67543 |    490.833772 | T. Michael Keesey                                                                                                                                           |
| 157 |     236.26887 |    525.289792 | Matt Crook                                                                                                                                                  |
| 158 |    1008.88498 |     48.344872 | Jagged Fang Designs                                                                                                                                         |
| 159 |     948.72032 |    495.752748 | Oscar Sanisidro                                                                                                                                             |
| 160 |    1012.32783 |    605.058113 | Felix Vaux                                                                                                                                                  |
| 161 |     582.33622 |    296.215991 | NA                                                                                                                                                          |
| 162 |      38.16144 |    402.430342 | Dmitry Bogdanov                                                                                                                                             |
| 163 |      98.02690 |    502.477544 | Mali’o Kodis, drawing by Manvir Singh                                                                                                                       |
| 164 |     939.68277 |    290.666838 | NA                                                                                                                                                          |
| 165 |     490.45046 |    463.460061 | Ferran Sayol                                                                                                                                                |
| 166 |     333.59367 |    265.040730 | Ingo Braasch                                                                                                                                                |
| 167 |     341.35042 |     26.601820 | Ferran Sayol                                                                                                                                                |
| 168 |     630.45939 |     46.955015 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                               |
| 169 |     779.90094 |    745.939486 | Matt Crook                                                                                                                                                  |
| 170 |     356.40180 |    252.201977 | L. Shyamal                                                                                                                                                  |
| 171 |     720.37090 |    524.820533 | Matt Crook                                                                                                                                                  |
| 172 |     211.44816 |     74.178373 | FunkMonk                                                                                                                                                    |
| 173 |     104.52454 |    743.525601 | Jagged Fang Designs                                                                                                                                         |
| 174 |     933.15429 |    598.894567 | Scott Hartman                                                                                                                                               |
| 175 |     135.23023 |    392.628709 | Scott Reid                                                                                                                                                  |
| 176 |     601.04061 |    165.846418 | Collin Gross                                                                                                                                                |
| 177 |     134.13829 |    565.985172 | Kamil S. Jaron                                                                                                                                              |
| 178 |     841.17624 |     11.078983 | Markus A. Grohme                                                                                                                                            |
| 179 |     672.47301 |    155.558543 | Ingo Braasch                                                                                                                                                |
| 180 |     239.73326 |    771.710064 | Matt Crook                                                                                                                                                  |
| 181 |     685.61752 |    488.259145 | Jagged Fang Designs                                                                                                                                         |
| 182 |     111.80664 |    704.129187 | Chris huh                                                                                                                                                   |
| 183 |     628.98467 |    634.269567 | Noah Schlottman                                                                                                                                             |
| 184 |     652.33002 |    716.650894 | Margot Michaud                                                                                                                                              |
| 185 |     804.53950 |    434.164191 | Mo Hassan                                                                                                                                                   |
| 186 |     564.59905 |    558.598527 | Michelle Site                                                                                                                                               |
| 187 |      23.17727 |    500.659628 | Tracy A. Heath                                                                                                                                              |
| 188 |     272.19308 |    634.317976 | Felix Vaux                                                                                                                                                  |
| 189 |      37.70048 |    277.460658 | T. Michael Keesey                                                                                                                                           |
| 190 |     172.99819 |     36.689660 | Madeleine Price Ball                                                                                                                                        |
| 191 |     277.83260 |    245.267430 | Chris huh                                                                                                                                                   |
| 192 |     507.78835 |    696.564223 | Markus A. Grohme                                                                                                                                            |
| 193 |     118.86386 |    168.430091 | Margot Michaud                                                                                                                                              |
| 194 |      74.59507 |    305.391540 | NA                                                                                                                                                          |
| 195 |     862.77133 |    489.339106 | Katie S. Collins                                                                                                                                            |
| 196 |     313.30100 |     18.801001 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                 |
| 197 |    1013.42078 |     15.853582 | Gareth Monger                                                                                                                                               |
| 198 |     956.72993 |    323.852768 | Ignacio Contreras                                                                                                                                           |
| 199 |     598.25245 |    713.025621 | Ignacio Contreras                                                                                                                                           |
| 200 |     581.78281 |    781.909858 | Nobu Tamura                                                                                                                                                 |
| 201 |     539.45828 |    436.876661 | Matt Crook                                                                                                                                                  |
| 202 |      49.14265 |    787.802285 | Margot Michaud                                                                                                                                              |
| 203 |     946.30218 |    434.455764 | Matt Crook                                                                                                                                                  |
| 204 |    1006.67530 |     79.326846 | Matt Crook                                                                                                                                                  |
| 205 |     746.53447 |    587.733967 | Rebecca Groom                                                                                                                                               |
| 206 |      15.03602 |    372.326161 | Ray Simpson (vectorized by T. Michael Keesey)                                                                                                               |
| 207 |     394.76668 |    117.308389 | Danielle Alba                                                                                                                                               |
| 208 |      82.23623 |    383.349193 | Scott Hartman                                                                                                                                               |
| 209 |      78.65131 |    617.385379 | Michael P. Taylor                                                                                                                                           |
| 210 |     733.74150 |    569.896588 | Frederick William Frohawk (vectorized by T. Michael Keesey)                                                                                                 |
| 211 |     322.71139 |    220.391103 | NA                                                                                                                                                          |
| 212 |      29.99952 |     67.683671 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                           |
| 213 |     951.30473 |    138.625115 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                           |
| 214 |     218.18257 |    640.303769 | Robert Gay                                                                                                                                                  |
| 215 |     678.17713 |    268.458825 | Zimices                                                                                                                                                     |
| 216 |     329.87837 |    778.954311 | Zimices                                                                                                                                                     |
| 217 |     724.13169 |    356.975671 | Steven Traver                                                                                                                                               |
| 218 |     323.58508 |    133.465956 | Jagged Fang Designs                                                                                                                                         |
| 219 |     601.71967 |    357.358719 | Gareth Monger                                                                                                                                               |
| 220 |      35.87086 |    481.935879 | Gopal Murali                                                                                                                                                |
| 221 |     974.11681 |    782.607056 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                               |
| 222 |     913.67257 |     93.803418 | Ignacio Contreras                                                                                                                                           |
| 223 |     847.68734 |    649.747673 | Jaime Headden                                                                                                                                               |
| 224 |     971.44673 |    267.225816 | Tasman Dixon                                                                                                                                                |
| 225 |     932.70106 |    264.715275 | Ben Liebeskind                                                                                                                                              |
| 226 |     315.62794 |    390.574651 | CNZdenek                                                                                                                                                    |
| 227 |     711.37784 |    203.198380 | M Hutchinson                                                                                                                                                |
| 228 |     196.30977 |    106.206257 | Markus A. Grohme                                                                                                                                            |
| 229 |     296.51496 |    117.069695 | Zimices                                                                                                                                                     |
| 230 |     569.58284 |    177.737034 | Matt Crook                                                                                                                                                  |
| 231 |     142.90163 |    771.735513 | T. Michael Keesey                                                                                                                                           |
| 232 |     144.94816 |    378.910140 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                           |
| 233 |     696.45144 |     10.054568 | Scott Hartman                                                                                                                                               |
| 234 |     822.22260 |    511.850910 | Chris huh                                                                                                                                                   |
| 235 |     249.60414 |    639.958904 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                            |
| 236 |     206.03345 |    665.795343 | Christoph Schomburg                                                                                                                                         |
| 237 |     647.99908 |    497.057076 | Margot Michaud                                                                                                                                              |
| 238 |     710.43693 |    140.477682 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                               |
| 239 |     383.02082 |    358.558109 | Matt Crook                                                                                                                                                  |
| 240 |     870.26845 |     53.643498 | Yan Wong                                                                                                                                                    |
| 241 |     890.13343 |    648.939413 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                           |
| 242 |    1006.32927 |    636.096567 | Maxime Dahirel                                                                                                                                              |
| 243 |     692.53811 |    353.825447 | Markus A. Grohme                                                                                                                                            |
| 244 |     195.89336 |    776.658978 | Rebecca Groom                                                                                                                                               |
| 245 |     357.48856 |     73.761829 | Chris huh                                                                                                                                                   |
| 246 |     204.28831 |    589.727654 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                              |
| 247 |     337.53548 |    755.607024 | Scott Hartman                                                                                                                                               |
| 248 |     825.85643 |    526.115773 | Nick Schooler                                                                                                                                               |
| 249 |     597.44910 |     13.140207 | Zimices                                                                                                                                                     |
| 250 |     878.34031 |    278.626331 | T. Michael Keesey                                                                                                                                           |
| 251 |      15.29664 |     21.649062 | Pete Buchholz                                                                                                                                               |
| 252 |     301.65610 |     36.823288 | Jagged Fang Designs                                                                                                                                         |
| 253 |     456.63528 |    119.945578 | Zimices                                                                                                                                                     |
| 254 |      18.47494 |    429.565029 | Maija Karala                                                                                                                                                |
| 255 |    1018.96439 |    293.078568 | Alexander Schmidt-Lebuhn                                                                                                                                    |
| 256 |     340.29714 |    294.304175 | Chris huh                                                                                                                                                   |
| 257 |     701.51591 |    566.452216 | David Orr                                                                                                                                                   |
| 258 |     802.67235 |    584.433553 | NA                                                                                                                                                          |
| 259 |     111.29176 |    569.298582 | Zimices                                                                                                                                                     |
| 260 |      23.94169 |    640.065701 | Steven Traver                                                                                                                                               |
| 261 |     648.27375 |    149.844630 | Michelle Site                                                                                                                                               |
| 262 |     708.65533 |     62.806080 | Emily Willoughby                                                                                                                                            |
| 263 |     950.38902 |     47.778387 | Tasman Dixon                                                                                                                                                |
| 264 |     502.20585 |    289.446677 | Terpsichores                                                                                                                                                |
| 265 |     511.21852 |    335.502415 | Margot Michaud                                                                                                                                              |
| 266 |     778.62513 |    794.038591 | Gareth Monger                                                                                                                                               |
| 267 |     805.76058 |    731.471380 | Renato Santos                                                                                                                                               |
| 268 |     108.69083 |    258.589241 | Collin Gross                                                                                                                                                |
| 269 |     640.60838 |    686.929472 | Scott Hartman                                                                                                                                               |
| 270 |     949.44764 |    114.509161 | Ignacio Contreras                                                                                                                                           |
| 271 |     451.57125 |    220.812133 | Rene Martin                                                                                                                                                 |
| 272 |     360.20135 |    667.080433 | Zachary Quigley                                                                                                                                             |
| 273 |     804.84549 |    413.699743 | Joanna Wolfe                                                                                                                                                |
| 274 |     546.91642 |    560.127126 | Geoff Shaw                                                                                                                                                  |
| 275 |    1009.68834 |    665.504045 | Ferran Sayol                                                                                                                                                |
| 276 |     169.38445 |    215.924368 | Alex Slavenko                                                                                                                                               |
| 277 |     122.81663 |     84.560103 | Zimices                                                                                                                                                     |
| 278 |     921.02991 |    771.246538 | C. Camilo Julián-Caballero                                                                                                                                  |
| 279 |     691.43245 |    541.329658 | Jaime Headden                                                                                                                                               |
| 280 |     500.57403 |     29.887735 | Ferran Sayol                                                                                                                                                |
| 281 |     283.31570 |    582.771076 | Zimices                                                                                                                                                     |
| 282 |     222.72902 |    504.277915 | Gareth Monger                                                                                                                                               |
| 283 |     564.90985 |    526.530878 | T. Michael Keesey                                                                                                                                           |
| 284 |     912.39997 |    272.018840 | kreidefossilien.de                                                                                                                                          |
| 285 |     164.19062 |    480.305999 | Xavier Giroux-Bougard                                                                                                                                       |
| 286 |      68.07957 |    644.741543 | Jagged Fang Designs                                                                                                                                         |
| 287 |     377.23370 |      8.651070 | Mattia Menchetti / Yan Wong                                                                                                                                 |
| 288 |    1004.86800 |    493.574144 | Markus A. Grohme                                                                                                                                            |
| 289 |     581.46451 |    153.925387 | Gabriela Palomo-Munoz                                                                                                                                       |
| 290 |     259.64625 |    178.886505 | Markus A. Grohme                                                                                                                                            |
| 291 |    1004.42697 |    141.585450 | Steven Traver                                                                                                                                               |
| 292 |     684.76683 |    124.678357 | Meyers Konversations-Lexikon 1897 (vectorized: Yan Wong)                                                                                                    |
| 293 |     218.34395 |    788.610128 | NA                                                                                                                                                          |
| 294 |     791.58570 |    402.760848 | Steven Traver                                                                                                                                               |
| 295 |     982.25543 |     63.946018 | T. Michael Keesey                                                                                                                                           |
| 296 |     621.38347 |    495.277772 | Scott Hartman                                                                                                                                               |
| 297 |      48.48756 |    365.255181 | Jagged Fang Designs                                                                                                                                         |
| 298 |     597.74377 |    738.511488 | Jagged Fang Designs                                                                                                                                         |
| 299 |    1005.71952 |     93.545612 | Pete Buchholz                                                                                                                                               |
| 300 |     521.05179 |    266.902789 | Timothy Knepp of the U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                      |
| 301 |     748.32383 |    196.512912 | Andy Wilson                                                                                                                                                 |
| 302 |     294.13715 |    650.079690 | Verdilak                                                                                                                                                    |
| 303 |     112.10966 |    640.527528 | Zimices                                                                                                                                                     |
| 304 |    1004.45243 |    278.381198 | Jagged Fang Designs                                                                                                                                         |
| 305 |     975.06908 |    157.121930 | Jakovche                                                                                                                                                    |
| 306 |     955.45444 |    392.058844 | Matt Dempsey                                                                                                                                                |
| 307 |     859.37068 |    549.975643 | Scott Hartman                                                                                                                                               |
| 308 |     160.28787 |    454.693689 | Mason McNair                                                                                                                                                |
| 309 |     699.53023 |    124.271272 | S.Martini                                                                                                                                                   |
| 310 |     678.06645 |    694.144924 | Ferran Sayol                                                                                                                                                |
| 311 |      79.06462 |    421.869813 | Armin Reindl                                                                                                                                                |
| 312 |     162.16676 |    590.500497 | Scott Reid                                                                                                                                                  |
| 313 |      18.65526 |    190.021119 | Armin Reindl                                                                                                                                                |
| 314 |      37.02113 |     82.940468 | Martin Kevil                                                                                                                                                |
| 315 |     658.92898 |    747.562185 | Jagged Fang Designs                                                                                                                                         |
| 316 |     147.54844 |     50.832928 | Julio Garza                                                                                                                                                 |
| 317 |     894.89075 |    414.997336 | Kanchi Nanjo                                                                                                                                                |
| 318 |     597.80202 |    453.810560 | xgirouxb                                                                                                                                                    |
| 319 |     712.54444 |    491.479271 | Bruno C. Vellutini                                                                                                                                          |
| 320 |     116.72667 |    673.102367 | Jagged Fang Designs                                                                                                                                         |
| 321 |     207.94101 |    415.603518 | Maxime Dahirel                                                                                                                                              |
| 322 |     605.30688 |    725.424001 | Jagged Fang Designs                                                                                                                                         |
| 323 |     646.60885 |    453.517274 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                 |
| 324 |     689.21291 |    557.226521 | Carlos Cano-Barbacil                                                                                                                                        |
| 325 |     596.48545 |    752.231640 | Julie Blommaert based on photo by Sofdrakou                                                                                                                 |
| 326 |      17.77973 |    781.319677 | Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org)                                                                |
| 327 |      28.67315 |    457.841303 | Mette Aumala                                                                                                                                                |
| 328 |     884.89347 |    225.997983 | Cristina Guijarro                                                                                                                                           |
| 329 |      19.57239 |    392.574114 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                           |
| 330 |     212.47722 |    686.880402 | Iain Reid                                                                                                                                                   |
| 331 |     924.56480 |    606.484652 | Margot Michaud                                                                                                                                              |
| 332 |     653.52785 |    790.602753 | Steven Haddock • Jellywatch.org                                                                                                                             |
| 333 |     101.36352 |      6.009680 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                           |
| 334 |     475.13160 |    233.770789 | G. M. Woodward                                                                                                                                              |
| 335 |     578.66915 |    191.818883 | Emily Jane McTavish, from Haeckel, E. H. P. A. (1904).Kunstformen der Natur. Bibliographisches                                                              |
| 336 |     464.93349 |    445.793246 | NA                                                                                                                                                          |
| 337 |     911.09016 |    171.661876 | T. Michael Keesey                                                                                                                                           |
| 338 |      31.49944 |    253.032309 | Chase Brownstein                                                                                                                                            |
| 339 |     354.70518 |    777.845340 | Andy Wilson                                                                                                                                                 |
| 340 |      58.27108 |     10.684100 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                               |
| 341 |    1000.39756 |    769.936016 | Andy Wilson                                                                                                                                                 |
| 342 |      43.79608 |    347.049957 | Tasman Dixon                                                                                                                                                |
| 343 |     621.95606 |    147.513342 | Scott Hartman                                                                                                                                               |
| 344 |     924.86640 |     80.651806 | Ferran Sayol                                                                                                                                                |
| 345 |      52.75069 |    632.080867 | Gabriela Palomo-Munoz                                                                                                                                       |
| 346 |     286.97214 |    723.326002 | Margot Michaud                                                                                                                                              |
| 347 |     341.94764 |    364.111509 | Margot Michaud                                                                                                                                              |
| 348 |     917.55437 |    660.630028 | Kai R. Caspar                                                                                                                                               |
| 349 |     838.44136 |    416.358048 | Margot Michaud                                                                                                                                              |
| 350 |     182.65570 |    491.590674 | Mike Hanson                                                                                                                                                 |
| 351 |      69.69490 |    122.294798 | Chris huh                                                                                                                                                   |
| 352 |     424.23883 |    380.973435 | Dave Angelini                                                                                                                                               |
| 353 |    1012.11763 |    473.439435 | Cathy                                                                                                                                                       |
| 354 |     153.75078 |    253.734234 | Zimices                                                                                                                                                     |
| 355 |     712.92802 |    708.448079 | Emily Willoughby                                                                                                                                            |
| 356 |     494.54833 |    567.573444 | Felix Vaux                                                                                                                                                  |
| 357 |     488.80691 |    445.273719 | CNZdenek                                                                                                                                                    |
| 358 |     665.99416 |    589.092203 | Zimices                                                                                                                                                     |
| 359 |     753.16600 |      7.352946 | Markus A. Grohme                                                                                                                                            |
| 360 |    1002.42107 |    749.569488 | Shyamal                                                                                                                                                     |
| 361 |     933.66330 |    560.485269 | C. Camilo Julián-Caballero                                                                                                                                  |
| 362 |     935.60713 |    787.684280 | Eric Moody                                                                                                                                                  |
| 363 |     704.34581 |    158.139229 | Chris huh                                                                                                                                                   |
| 364 |     737.56675 |    327.847495 | Alexander Schmidt-Lebuhn                                                                                                                                    |
| 365 |     713.62613 |    306.380594 | NA                                                                                                                                                          |
| 366 |     354.67390 |    211.865203 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                               |
| 367 |     694.26348 |    392.275080 | Chris huh                                                                                                                                                   |
| 368 |      48.76270 |    306.286282 | Tasman Dixon                                                                                                                                                |
| 369 |     322.30656 |    699.229772 | Markus A. Grohme                                                                                                                                            |
| 370 |     833.29381 |    728.868368 | Tasman Dixon                                                                                                                                                |
| 371 |     172.11317 |    169.100637 | Tracy A. Heath                                                                                                                                              |
| 372 |     502.62770 |    791.854478 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                         |
| 373 |     903.69231 |     51.208251 | Margot Michaud                                                                                                                                              |
| 374 |     641.54752 |    640.219295 | Lisa Byrne                                                                                                                                                  |
| 375 |     348.60166 |    289.857019 | M Kolmann                                                                                                                                                   |
| 376 |     272.16765 |     97.632925 | Matt Crook                                                                                                                                                  |
| 377 |     714.80528 |    580.309839 | T. Michael Keesey                                                                                                                                           |
| 378 |      93.57535 |    563.694551 | Margot Michaud                                                                                                                                              |
| 379 |     103.94347 |    419.504485 | Gabriela Palomo-Munoz                                                                                                                                       |
| 380 |     600.32777 |    275.641724 | Gareth Monger                                                                                                                                               |
| 381 |     620.81648 |    622.082213 | Matt Crook                                                                                                                                                  |
| 382 |     888.60824 |    113.225509 | Emily Willoughby                                                                                                                                            |
| 383 |     884.38448 |    687.870015 | Renato de Carvalho Ferreira                                                                                                                                 |
| 384 |      88.46653 |    781.732627 | Manabu Sakamoto                                                                                                                                             |
| 385 |     677.97547 |    635.640813 | Chris huh                                                                                                                                                   |
| 386 |     580.30803 |    695.454315 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                |
| 387 |     150.05300 |    788.888699 | Margot Michaud                                                                                                                                              |
| 388 |     276.18167 |    559.564303 | Ingo Braasch                                                                                                                                                |
| 389 |     235.01063 |    126.270061 | Michael Scroggie                                                                                                                                            |
| 390 |     583.94070 |    558.912510 | Felix Vaux                                                                                                                                                  |
| 391 |     698.38563 |    100.070576 | TaraTaylorDesign                                                                                                                                            |
| 392 |     695.33856 |    791.273012 | Steven Traver                                                                                                                                               |
| 393 |     962.32144 |    515.160880 | Collin Gross                                                                                                                                                |
| 394 |     778.67796 |      4.532396 | Mike Hanson                                                                                                                                                 |
| 395 |     467.53225 |    250.106603 | Rene Martin                                                                                                                                                 |
| 396 |      20.28832 |    743.955303 | NA                                                                                                                                                          |
| 397 |     477.93028 |    472.491432 | T. Michael Keesey (after Heinrich Harder)                                                                                                                   |
| 398 |     705.39878 |    456.799803 | Jagged Fang Designs                                                                                                                                         |
| 399 |     681.32727 |    659.941364 | Ignacio Contreras                                                                                                                                           |
| 400 |     566.39373 |    496.940009 | C. Camilo Julián-Caballero                                                                                                                                  |
| 401 |     967.09086 |    431.226422 | Jaime Headden                                                                                                                                               |
| 402 |     745.09908 |    280.449491 | Mark Hofstetter (vectorized by T. Michael Keesey)                                                                                                           |
| 403 |      89.12525 |    150.830383 | Zimices                                                                                                                                                     |
| 404 |     662.36473 |    432.162469 | Sharon Wegner-Larsen                                                                                                                                        |
| 405 |     383.52629 |    135.927517 | Alexander Schmidt-Lebuhn                                                                                                                                    |
| 406 |      36.84380 |    706.801547 | SauropodomorphMonarch                                                                                                                                       |
| 407 |     552.70416 |     65.879427 | Scott Hartman, modified by T. Michael Keesey                                                                                                                |
| 408 |    1006.49807 |    168.803974 | Juan Carlos Jerí                                                                                                                                            |
| 409 |     800.19344 |    466.593500 | Margot Michaud                                                                                                                                              |
| 410 |     649.60063 |    187.622182 | Jaime Headden                                                                                                                                               |
| 411 |    1006.25813 |     30.552390 | Margot Michaud                                                                                                                                              |
| 412 |     938.60246 |    744.492525 | Chris huh                                                                                                                                                   |
| 413 |     333.98942 |    256.981883 | Chris huh                                                                                                                                                   |
| 414 |     159.15208 |    755.830840 | Iain Reid                                                                                                                                                   |
| 415 |     153.22263 |    504.421259 | Scott Hartman                                                                                                                                               |
| 416 |      30.85568 |    444.876809 | FunkMonk                                                                                                                                                    |
| 417 |     824.86284 |     52.227555 | Jagged Fang Designs                                                                                                                                         |
| 418 |     232.89570 |     87.465760 | Mathilde Cordellier                                                                                                                                         |
| 419 |     671.41872 |    200.178534 | Scott Hartman (modified by T. Michael Keesey)                                                                                                               |
| 420 |     825.41337 |    504.655483 | Nobu Tamura                                                                                                                                                 |
| 421 |     765.89437 |     99.661161 | NA                                                                                                                                                          |
| 422 |     162.05919 |    267.950124 | Chris huh                                                                                                                                                   |
| 423 |     615.19459 |     32.018608 | Dave Souza (vectorized by T. Michael Keesey)                                                                                                                |
| 424 |     276.58902 |    568.972085 | Ignacio Contreras                                                                                                                                           |
| 425 |     489.19071 |    778.147079 | Mike Hanson                                                                                                                                                 |
| 426 |    1018.09066 |    439.922900 | Alexander Schmidt-Lebuhn                                                                                                                                    |
| 427 |     958.33651 |    568.247761 | T. Michael Keesey (from a mount by Allis Markham)                                                                                                           |
| 428 |     770.42317 |    358.236681 | Gabriela Palomo-Munoz                                                                                                                                       |
| 429 |     698.24308 |    597.475324 | M Kolmann                                                                                                                                                   |
| 430 |     685.58471 |    383.288868 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                               |
| 431 |     852.97465 |    186.923033 | Marcos Pérez-Losada, Jens T. Høeg & Keith A. Crandall                                                                                                       |
| 432 |     933.18214 |    401.272222 | Tracy A. Heath                                                                                                                                              |
| 433 |     450.86757 |    104.607708 | Ieuan Jones                                                                                                                                                 |
| 434 |     451.10777 |    535.422771 | NA                                                                                                                                                          |
| 435 |    1007.08846 |    578.326858 | Terpsichores                                                                                                                                                |
| 436 |    1000.55623 |    795.623958 | Chris huh                                                                                                                                                   |
| 437 |     683.55708 |    143.866462 | Steven Traver                                                                                                                                               |
| 438 |      18.63805 |    759.850763 | Scott Hartman                                                                                                                                               |
| 439 |     770.99649 |    714.440398 | Cesar Julian                                                                                                                                                |
| 440 |     514.97426 |     61.746487 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                          |
| 441 |     847.55355 |      4.391834 | Iain Reid                                                                                                                                                   |
| 442 |     344.19091 |     61.129645 | Duane Raver/USFWS                                                                                                                                           |
| 443 |     173.89044 |    543.185835 | Jaime Headden, modified by T. Michael Keesey                                                                                                                |
| 444 |     714.20610 |    164.358955 | Mathew Wedel                                                                                                                                                |
| 445 |     244.40439 |    200.024258 | Steven Traver                                                                                                                                               |
| 446 |     990.23435 |      6.010146 | Jimmy Bernot                                                                                                                                                |
| 447 |     329.77430 |    102.409205 | Jaime Headden, modified by T. Michael Keesey                                                                                                                |
| 448 |     605.97547 |    559.432459 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                           |
| 449 |     944.36463 |    348.685376 | Steven Coombs                                                                                                                                               |
| 450 |     895.09348 |    157.994164 | Zimices                                                                                                                                                     |
| 451 |     210.27405 |    705.592988 | Jagged Fang Designs                                                                                                                                         |
| 452 |     606.12377 |    406.567317 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                           |
| 453 |     536.27151 |    304.871083 | Scott Hartman                                                                                                                                               |
| 454 |     588.78465 |    439.335994 | Tasman Dixon                                                                                                                                                |
| 455 |     593.50612 |    140.106298 | Gabriela Palomo-Munoz                                                                                                                                       |
| 456 |     604.13581 |    396.656066 | A. H. Baldwin (vectorized by T. Michael Keesey)                                                                                                             |
| 457 |     118.22191 |    396.985221 | Tony Ayling                                                                                                                                                 |
| 458 |     200.71897 |    478.476658 | Dean Schnabel                                                                                                                                               |
| 459 |      18.37681 |    596.809913 | NA                                                                                                                                                          |
| 460 |      16.93539 |    559.371015 | Tyler McCraney                                                                                                                                              |
| 461 |     293.30566 |    176.938919 | T. Michael Keesey                                                                                                                                           |
| 462 |     620.22391 |    532.222133 | Smokeybjb                                                                                                                                                   |
| 463 |     306.35426 |    685.016785 | Jose Carlos Arenas-Monroy                                                                                                                                   |
| 464 |     739.08199 |    178.838546 | Yan Wong                                                                                                                                                    |
| 465 |     203.72501 |    131.785615 | Michael Scroggie                                                                                                                                            |
| 466 |     341.78256 |    792.651426 | Chris huh                                                                                                                                                   |
| 467 |     989.01857 |    477.421270 | Christoph Schomburg                                                                                                                                         |
| 468 |     212.45590 |    757.777885 | Gareth Monger                                                                                                                                               |
| 469 |     924.52919 |    444.264664 | Sarah Werning                                                                                                                                               |
| 470 |     539.76949 |    614.026786 | Ferran Sayol                                                                                                                                                |
| 471 |     190.19477 |    284.243012 | FunkMonk                                                                                                                                                    |
| 472 |     189.00894 |    439.965364 | Ignacio Contreras                                                                                                                                           |
| 473 |     635.28932 |    111.729456 | Cesar Julian                                                                                                                                                |
| 474 |     573.37426 |     28.982699 | Hugo Gruson                                                                                                                                                 |
| 475 |     171.56032 |    392.797942 | NA                                                                                                                                                          |
| 476 |     747.04032 |    507.896092 | B. Duygu Özpolat                                                                                                                                            |
| 477 |     761.87292 |    785.572998 | Ieuan Jones                                                                                                                                                 |
| 478 |     492.26487 |    129.710359 | Ignacio Contreras                                                                                                                                           |
| 479 |     167.40795 |    522.303338 | Markus A. Grohme                                                                                                                                            |
| 480 |     694.72636 |    508.375442 | Emily Jane McTavish                                                                                                                                         |
| 481 |     352.78067 |    739.873181 | Nobu Tamura, vectorized by Zimices                                                                                                                          |
| 482 |     162.74382 |    673.511219 | Steven Traver                                                                                                                                               |
| 483 |     542.78170 |    532.620667 | Andy Wilson                                                                                                                                                 |
| 484 |     727.15164 |    542.426186 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                               |
| 485 |     393.06770 |    683.493619 | T. Michael Keesey                                                                                                                                           |
| 486 |     197.57613 |    578.488992 | Markus A. Grohme                                                                                                                                            |
| 487 |     222.77792 |    157.598667 | Cesar Julian                                                                                                                                                |
| 488 |      22.20488 |     33.114014 | Jagged Fang Designs                                                                                                                                         |
| 489 |     895.79868 |    609.089885 | Tyler Greenfield                                                                                                                                            |
| 490 |     655.92999 |    626.795257 | Christian A. Masnaghetti                                                                                                                                    |
| 491 |     952.99843 |    761.352913 | Markus A. Grohme                                                                                                                                            |
| 492 |     308.70280 |    289.715228 | Rebecca Groom                                                                                                                                               |
| 493 |     356.28246 |    132.685237 | Pete Buchholz                                                                                                                                               |
| 494 |     902.68913 |    784.150667 | Scott Hartman                                                                                                                                               |
| 495 |     475.26446 |    325.231879 | Andrew A. Farke                                                                                                                                             |
| 496 |     984.81217 |    503.108911 | L. Shyamal                                                                                                                                                  |
| 497 |     105.13159 |    716.818611 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                           |
| 498 |     183.18047 |    425.961387 | Jagged Fang Designs                                                                                                                                         |
| 499 |     783.72993 |    654.444671 | Chris huh                                                                                                                                                   |
| 500 |      51.51033 |    703.360423 | Zimices                                                                                                                                                     |
| 501 |     601.50809 |    785.415175 | Margot Michaud                                                                                                                                              |
| 502 |     773.75863 |     14.435166 | Jagged Fang Designs                                                                                                                                         |
| 503 |     632.11454 |    127.661006 | NA                                                                                                                                                          |
| 504 |     404.37216 |    272.162069 | C. Camilo Julián-Caballero                                                                                                                                  |
| 505 |     466.68497 |     63.239515 | T. Michael Keesey                                                                                                                                           |
| 506 |     477.10749 |    611.589589 | Maxime Dahirel                                                                                                                                              |
| 507 |     912.23360 |      2.629158 | Mihai Dragos (vectorized by T. Michael Keesey)                                                                                                              |
| 508 |     500.04679 |     71.495491 | Margot Michaud                                                                                                                                              |

    #> Your tweet has been posted!
