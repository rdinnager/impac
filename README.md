
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

Mathilde Cordellier, Mali’o Kodis, image from Higgins and Kristensen,
1986, Scott Hartman, Jessica Anne Miller, Matt Crook, Didier Descouens
(vectorized by T. Michael Keesey), Milton Tan, Giant Blue Anteater
(vectorized by T. Michael Keesey), Martin R. Smith, from photo by Jürgen
Schoner, Zimices, Emily Willoughby, Terpsichores, Sarah Werning, T.
Tischler, Smokeybjb (vectorized by T. Michael Keesey), Collin Gross,
S.Martini, Noah Schlottman, photo by Martin V. Sørensen, Birgit Szabo,
Roberto Díaz Sibaja, Armin Reindl, Noah Schlottman, Christoph Schomburg,
Jon Hill (Photo by Benjamint444:
<http://en.wikipedia.org/wiki/File:Blue-footed-booby.jpg>), T. Michael
Keesey, Gareth Monger, (after Spotila 2004), Steven Traver, Jagged Fang
Designs, Gabriela Palomo-Munoz, Erika Schumacher, Michelle Site, Tasman
Dixon, Jose Carlos Arenas-Monroy, Felix Vaux, Mali’o Kodis, drawing by
Manvir Singh, Emma Hughes, Mali’o Kodis, photograph by P. Funch and R.M.
Kristensen, I. Geoffroy Saint-Hilaire (vectorized by T. Michael Keesey),
Agnello Picorelli, Noah Schlottman, photo by Hans De Blauwe, Andrew A.
Farke, shell lines added by Yan Wong, Rebecca Groom, Jake Warner, Yan
Wong, Ferran Sayol, Christopher Watson (photo) and T. Michael Keesey
(vectorization), Chris huh, Markus A. Grohme, Mette Aumala, Smokeybjb,
Haplochromis (vectorized by T. Michael Keesey), Dmitry Bogdanov
(vectorized by T. Michael Keesey), Trond R. Oskars, Tauana J. Cunha,
Andreas Hejnol, Alexandra van der Geer, Birgit Lang; original image by
virmisco.org, Fernando Carezzano, Margot Michaud, T. Michael Keesey
(from a photograph by Frank Glaw, Jörn Köhler, Ted M. Townsend & Miguel
Vences), Scott Hartman (modified by T. Michael Keesey), Original drawing
by Antonov, vectorized by Roberto Díaz Sibaja, Kamil S. Jaron, Mathieu
Pélissié, Alexander Schmidt-Lebuhn, C. Camilo Julián-Caballero, T.
Michael Keesey and Tanetahi, Joanna Wolfe, Ralf Janssen, Nikola-Michael
Prpic & Wim G. M. Damen (vectorized by T. Michael Keesey), Darren Naish
(vectorized by T. Michael Keesey), Amanda Katzer, Stanton F. Fink
(vectorized by T. Michael Keesey), Davidson Sodré, Oliver Voigt, Siobhon
Egan, Meliponicultor Itaymbere, Birgit Lang, CNZdenek, Marcos
Pérez-Losada, Jens T. Høeg & Keith A. Crandall, Jonathan Wells, Kanchi
Nanjo, Myriam\_Ramirez, Mattia Menchetti, Maija Karala, Alexandre Vong,
Noah Schlottman, photo from Casey Dunn, Tracy A. Heath, Jaime Headden,
Ignacio Contreras, Keith Murdock (photo), John E. McCormack, Michael G.
Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb
T. Brumfield & T. Michael Keesey, Luc Viatour (source photo) and Andreas
Plank, L. Shyamal, Jaime Headden, modified by T. Michael Keesey,
FJDegrange, Maky (vectorization), Gabriella Skollar (photography),
Rebecca Lewis (editing), Neil Kelley, Iain Reid, Ray Simpson (vectorized
by T. Michael Keesey), Mathew Wedel, Jimmy Bernot, Birgit Lang, based on
a photo by D. Sikes, Nobu Tamura, modified by Andrew A. Farke, Andrew A.
Farke, Saguaro Pictures (source photo) and T. Michael Keesey, Unknown
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Joschua Knüppe, Sharon Wegner-Larsen, Ghedoghedo (vectorized by
T. Michael Keesey), V. Deepak, Dmitry Bogdanov, Robbie N. Cada
(vectorized by T. Michael Keesey), Anthony Caravaggi, Dean Schnabel, Sam
Fraser-Smith (vectorized by T. Michael Keesey), mystica, Nobu Tamura
(vectorized by T. Michael Keesey), Eyal Bartov, Becky Barnes, ArtFavor &
annaleeblysse, Lukasiniho, Melissa Broussard, Sean McCann, Jan A.
Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized
by T. Michael Keesey), Jack Mayer Wood, Carlos Cano-Barbacil, T. Michael
Keesey (after Mivart), Konsta Happonen, Skye McDavid, Caleb M. Brown,
xgirouxb, Andy Wilson, kreidefossilien.de, Taro Maeda, Henry Fairfield
Osborn, vectorized by Zimices, David Tana, Lily Hughes, T. Michael
Keesey (after Ponomarenko), Julio Garza, Crystal Maier, Mali’o Kodis,
photograph by Ching (<http://www.flickr.com/photos/36302473@N03/>),
terngirl, Tyler Greenfield, Bryan Carstens, Francis de Laporte de
Castelnau (vectorized by T. Michael Keesey), Dianne Bray / Museum
Victoria (vectorized by T. Michael Keesey), Adrian Reich, Julien Louys,
Tim Bertelink (modified by T. Michael Keesey), Meyers
Konversations-Lexikon 1897 (vectorized: Yan Wong), Andrew A. Farke,
modified from original by Robert Bruce Horsfall, from Scott 1912, T.
Michael Keesey (after Marek Velechovský), Owen Jones (derived from a
CC-BY 2.0 photograph by Paulo B. Chaves), Thibaut Brunet, FunkMonk,
Timothy Knepp (vectorized by T. Michael Keesey), Michael Scroggie, M
Kolmann, Aviceda (vectorized by T. Michael Keesey), Mathieu Basille,
Jiekun He, Alyssa Bell & Luis Chiappe 2015,
dx.doi.org/10.1371/journal.pone.0141690, Martin R. Smith, Tony Ayling
(vectorized by T. Michael Keesey), zoosnow, Noah Schlottman, photo by
David J Patterson, Tarique Sani (photo), John E. McCormack, Michael G.
Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb
T. Brumfield & T. Michael Keesey, Katie S. Collins, T. Michael Keesey
(after A. Y. Ivantsov), Matt Martyniuk, david maas / dave hone, FunkMonk
\[Michael B.H.\] (modified by T. Michael Keesey), Harold N Eyster, Hans
Hillewaert (photo) and T. Michael Keesey (vectorization), Sibi
(vectorized by T. Michael Keesey), Sergio A. Muñoz-Gómez, Louis Ranjard,
T. Michael Keesey (after C. De Muizon), Kanako Bessho-Uehara, Evan
Swigart (photography) and T. Michael Keesey (vectorization), C.
Abraczinskas, Danielle Alba, Dein Freund der Baum (vectorized by T.
Michael Keesey), Scarlet23 (vectorized by T. Michael Keesey), Chuanixn
Yu, Benjamin Monod-Broca, Scott D. Sampson, Mark A. Loewen, Andrew A.
Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L.
Titus, Stacy Spensley (Modified), Matt Dempsey, David Orr, Oren Peles /
vectorized by Yan Wong, Nobu Tamura, vectorized by Zimices, Ville
Koistinen and T. Michael Keesey, Ben Liebeskind, Sidney Frederic Harmer,
Arthur Everett Shipley (vectorized by Maxime Dahirel), Shyamal, Henry
Lydecker, T. Michael Keesey (after Monika Betley), Griensteidl and T.
Michael Keesey, Christina N. Hodson, Steven Haddock • Jellywatch.org,
U.S. National Park Service (vectorized by William Gearty), Diego
Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli,
Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by
T. Michael Keesey), Emily Jane McTavish, from
<http://en.wikipedia.org/wiki/File:Coccolithus_pelagicus.jpg>, G. M.
Woodward, Conty (vectorized by T. Michael Keesey), Ingo Braasch, Lafage,
Nina Skinner, Moussa Direct Ltd. (photography) and T. Michael Keesey
(vectorization), Alex Slavenko, T. Michael Keesey (vectorization) and
Tony Hisgett (photography), Scott Reid, Matthew E. Clapham, Nobu Tamura,
Maxime Dahirel, Yan Wong from drawing in The Century Dictionary (1911),
Yan Wong from drawing by T. F. Zimmermann, Meyer-Wachsmuth I, Curini
Galletti M, Jondelius U (<doi:10.1371/journal.pone.0107688>).
Vectorization by Y. Wong, Yan Wong from illustration by Charles Orbigny,
Francesco “Architetto” Rollandin, Ieuan Jones, Apokryltaros (vectorized
by T. Michael Keesey), Dmitry Bogdanov (modified by T. Michael Keesey),
Francesca Belem Lopes Palmeira, Matthew Hooge (vectorized by T. Michael
Keesey), Chase Brownstein, Abraão B. Leite, A. R. McCulloch (vectorized
by T. Michael Keesey), Sarah Alewijnse, Ben Moon, Ricardo N. Martinez &
Oscar A. Alcober, Darius Nau, annaleeblysse, Daniel Jaron, T. Michael
Keesey (vectorization) and Larry Loos (photography), Brockhaus and
Efron, nicubunu, André Karwath (vectorized by T. Michael Keesey),
Dr. Thomas G. Barnes, USFWS, Chris A. Hamilton, Gopal Murali, Mali’o
Kodis, image from Brockhaus and Efron Encyclopedic Dictionary, John
Curtis (vectorized by T. Michael Keesey), Kailah Thorn & Mark
Hutchinson, Timothy Knepp of the U.S. Fish and Wildlife Service
(illustration) and Timothy J. Bartley (silhouette), Noah Schlottman,
photo by Reinhard Jahn, Matus Valach, Espen Horn (model; vectorized by
T. Michael Keesey from a photo by H. Zell), Qiang Ou, Lankester Edwin
Ray (vectorized by T. Michael Keesey)

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    800.167740 |    123.425349 | Mathilde Cordellier                                                                                                                                                   |
|   2 |    893.858567 |    322.740713 | Mali’o Kodis, image from Higgins and Kristensen, 1986                                                                                                                 |
|   3 |    483.571549 |    201.920726 | Scott Hartman                                                                                                                                                         |
|   4 |    536.553457 |    351.128444 | Jessica Anne Miller                                                                                                                                                   |
|   5 |    812.414003 |    739.776109 | Matt Crook                                                                                                                                                            |
|   6 |    674.599335 |    193.134269 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
|   7 |    768.385230 |    514.292075 | Milton Tan                                                                                                                                                            |
|   8 |    427.353047 |    275.261689 | Giant Blue Anteater (vectorized by T. Michael Keesey)                                                                                                                 |
|   9 |    199.088244 |    687.213932 | Martin R. Smith, from photo by Jürgen Schoner                                                                                                                         |
|  10 |    467.150735 |    661.090523 | Zimices                                                                                                                                                               |
|  11 |    260.435230 |     74.137644 | Emily Willoughby                                                                                                                                                      |
|  12 |    780.124052 |    257.023564 | Matt Crook                                                                                                                                                            |
|  13 |    313.647199 |    326.849035 | Terpsichores                                                                                                                                                          |
|  14 |    152.402913 |    633.212066 | Sarah Werning                                                                                                                                                         |
|  15 |    588.048637 |    435.342104 | T. Tischler                                                                                                                                                           |
|  16 |    135.058360 |    425.858777 | Matt Crook                                                                                                                                                            |
|  17 |    904.207555 |    642.252801 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                           |
|  18 |    376.887544 |    757.312178 | Collin Gross                                                                                                                                                          |
|  19 |    641.528408 |    529.907237 | S.Martini                                                                                                                                                             |
|  20 |    285.224918 |    201.580775 | Noah Schlottman, photo by Martin V. Sørensen                                                                                                                          |
|  21 |    522.107505 |    119.275306 | Birgit Szabo                                                                                                                                                          |
|  22 |    298.858706 |    117.556003 | Roberto Díaz Sibaja                                                                                                                                                   |
|  23 |    103.529631 |    518.449388 | Armin Reindl                                                                                                                                                          |
|  24 |    703.421369 |    315.747029 | Noah Schlottman                                                                                                                                                       |
|  25 |    951.134061 |     62.870966 | Christoph Schomburg                                                                                                                                                   |
|  26 |    100.726405 |    327.754100 | Jon Hill (Photo by Benjamint444: <http://en.wikipedia.org/wiki/File:Blue-footed-booby.jpg>)                                                                           |
|  27 |    483.798216 |    571.406081 | T. Michael Keesey                                                                                                                                                     |
|  28 |    424.358858 |    468.236310 | Gareth Monger                                                                                                                                                         |
|  29 |    327.493908 |    538.072646 | (after Spotila 2004)                                                                                                                                                  |
|  30 |    352.076429 |     53.860337 | Zimices                                                                                                                                                               |
|  31 |    694.133008 |    116.462907 | NA                                                                                                                                                                    |
|  32 |    689.289326 |    611.004995 | Steven Traver                                                                                                                                                         |
|  33 |    654.277614 |    664.072018 | Jagged Fang Designs                                                                                                                                                   |
|  34 |    864.695017 |    433.654655 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  35 |    322.992261 |    431.873044 | Erika Schumacher                                                                                                                                                      |
|  36 |     82.944309 |    735.852165 | Michelle Site                                                                                                                                                         |
|  37 |    167.573251 |    172.472916 | Sarah Werning                                                                                                                                                         |
|  38 |    710.024782 |     44.930556 | Tasman Dixon                                                                                                                                                          |
|  39 |    573.886815 |    258.262028 | Jose Carlos Arenas-Monroy                                                                                                                                             |
|  40 |    679.995492 |    463.910428 | Felix Vaux                                                                                                                                                            |
|  41 |    961.233670 |    751.569013 | Zimices                                                                                                                                                               |
|  42 |    528.475934 |    495.427696 | Mali’o Kodis, drawing by Manvir Singh                                                                                                                                 |
|  43 |     66.852306 |    164.953519 | Gareth Monger                                                                                                                                                         |
|  44 |    915.597061 |    542.353348 | Emma Hughes                                                                                                                                                           |
|  45 |    755.310851 |    422.816826 | Mali’o Kodis, photograph by P. Funch and R.M. Kristensen                                                                                                              |
|  46 |    330.088553 |    696.907805 | I. Geoffroy Saint-Hilaire (vectorized by T. Michael Keesey)                                                                                                           |
|  47 |    578.702479 |     45.747390 | Agnello Picorelli                                                                                                                                                     |
|  48 |    415.498723 |    361.805579 | Noah Schlottman, photo by Hans De Blauwe                                                                                                                              |
|  49 |    243.993101 |    748.506645 | Andrew A. Farke, shell lines added by Yan Wong                                                                                                                        |
|  50 |    139.638637 |    463.834050 | Rebecca Groom                                                                                                                                                         |
|  51 |     92.480542 |     98.749009 | Jake Warner                                                                                                                                                           |
|  52 |    422.416127 |    110.296110 | NA                                                                                                                                                                    |
|  53 |     77.893471 |    543.330372 | Yan Wong                                                                                                                                                              |
|  54 |    306.759432 |    171.269675 | Jagged Fang Designs                                                                                                                                                   |
|  55 |    571.836181 |    487.234487 | Jagged Fang Designs                                                                                                                                                   |
|  56 |    809.860416 |     28.603547 | Sarah Werning                                                                                                                                                         |
|  57 |    648.846862 |    395.282929 | Milton Tan                                                                                                                                                            |
|  58 |    216.492144 |    318.258093 | Ferran Sayol                                                                                                                                                          |
|  59 |    730.602580 |    556.935344 | Scott Hartman                                                                                                                                                         |
|  60 |    503.170290 |    727.614876 | Ferran Sayol                                                                                                                                                          |
|  61 |    119.842952 |     25.923358 | NA                                                                                                                                                                    |
|  62 |    169.460642 |    231.115031 | Scott Hartman                                                                                                                                                         |
|  63 |    962.579927 |    180.639603 | Christopher Watson (photo) and T. Michael Keesey (vectorization)                                                                                                      |
|  64 |    358.834901 |    231.737013 | Chris huh                                                                                                                                                             |
|  65 |    940.753552 |    694.215822 | Markus A. Grohme                                                                                                                                                      |
|  66 |    888.555816 |    126.881038 | Gareth Monger                                                                                                                                                         |
|  67 |    597.518716 |    765.104513 | Chris huh                                                                                                                                                             |
|  68 |    122.353598 |    579.215184 | Mette Aumala                                                                                                                                                          |
|  69 |    855.302835 |     99.900311 | Gareth Monger                                                                                                                                                         |
|  70 |    662.008585 |    273.442260 | Chris huh                                                                                                                                                             |
|  71 |    462.961569 |    155.252915 | Chris huh                                                                                                                                                             |
|  72 |    102.733900 |    504.767677 | Smokeybjb                                                                                                                                                             |
|  73 |    913.689656 |    604.310737 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  74 |    431.618948 |     23.803355 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                        |
|  75 |    726.430370 |    747.674277 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  76 |    256.373579 |    603.670240 | Steven Traver                                                                                                                                                         |
|  77 |     77.178730 |    433.188548 | Trond R. Oskars                                                                                                                                                       |
|  78 |    977.157037 |    163.373332 | Tauana J. Cunha                                                                                                                                                       |
|  79 |    759.402787 |    220.696129 | Andreas Hejnol                                                                                                                                                        |
|  80 |     36.767101 |    434.876280 | Alexandra van der Geer                                                                                                                                                |
|  81 |    452.491141 |     42.284339 | Gareth Monger                                                                                                                                                         |
|  82 |    268.043983 |     20.617473 | Birgit Lang; original image by virmisco.org                                                                                                                           |
|  83 |    989.486897 |    566.745315 | Gareth Monger                                                                                                                                                         |
|  84 |    579.112952 |    582.694580 | Matt Crook                                                                                                                                                            |
|  85 |     45.966868 |    138.659634 | Fernando Carezzano                                                                                                                                                    |
|  86 |    125.855746 |     47.512382 | Margot Michaud                                                                                                                                                        |
|  87 |    538.265464 |    445.677992 | T. Michael Keesey (from a photograph by Frank Glaw, Jörn Köhler, Ted M. Townsend & Miguel Vences)                                                                     |
|  88 |    351.586828 |    606.976702 | Scott Hartman (modified by T. Michael Keesey)                                                                                                                         |
|  89 |     32.415129 |    609.606576 | Original drawing by Antonov, vectorized by Roberto Díaz Sibaja                                                                                                        |
|  90 |    178.684276 |    776.378677 | Kamil S. Jaron                                                                                                                                                        |
|  91 |    709.035854 |    432.941775 | Mathieu Pélissié                                                                                                                                                      |
|  92 |    783.458740 |    172.974615 | Alexander Schmidt-Lebuhn                                                                                                                                              |
|  93 |    635.348267 |    137.899945 | C. Camilo Julián-Caballero                                                                                                                                            |
|  94 |     81.924045 |    209.196537 | Markus A. Grohme                                                                                                                                                      |
|  95 |    754.175984 |    196.592354 | Zimices                                                                                                                                                               |
|  96 |    314.481069 |    631.222843 | T. Michael Keesey and Tanetahi                                                                                                                                        |
|  97 |     90.543980 |    684.937479 | Joanna Wolfe                                                                                                                                                          |
|  98 |    566.240248 |    300.894695 | Chris huh                                                                                                                                                             |
|  99 |    815.186552 |    291.309324 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 100 |    995.873582 |    119.110650 | Margot Michaud                                                                                                                                                        |
| 101 |    625.926588 |     96.478500 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 102 |    344.063092 |    752.448129 | Tasman Dixon                                                                                                                                                          |
| 103 |    843.730361 |    543.430587 | NA                                                                                                                                                                    |
| 104 |    608.968216 |    698.940161 | T. Michael Keesey                                                                                                                                                     |
| 105 |    337.806796 |    183.687344 | Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael Keesey)                                                                                |
| 106 |     39.048253 |    290.295253 | Steven Traver                                                                                                                                                         |
| 107 |    809.335302 |    479.355785 | Margot Michaud                                                                                                                                                        |
| 108 |     26.444259 |    748.396687 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                        |
| 109 |    975.996152 |    400.513576 | Margot Michaud                                                                                                                                                        |
| 110 |     32.062282 |    469.276162 | Amanda Katzer                                                                                                                                                         |
| 111 |    699.910295 |    520.641782 | NA                                                                                                                                                                    |
| 112 |    217.866493 |    506.180255 | Matt Crook                                                                                                                                                            |
| 113 |    597.808158 |    489.567364 | Jagged Fang Designs                                                                                                                                                   |
| 114 |    953.838396 |    141.389958 | Margot Michaud                                                                                                                                                        |
| 115 |    608.978915 |    727.182344 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                     |
| 116 |    881.023521 |    783.126126 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 117 |    469.454784 |    519.939266 | Davidson Sodré                                                                                                                                                        |
| 118 |     25.366599 |    228.956740 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 119 |    858.696326 |    217.736501 | Oliver Voigt                                                                                                                                                          |
| 120 |    567.088057 |      7.699975 | Siobhon Egan                                                                                                                                                          |
| 121 |    807.646077 |    325.546117 | Meliponicultor Itaymbere                                                                                                                                              |
| 122 |   1002.790554 |    318.575652 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 123 |    895.010126 |     41.890220 | Birgit Lang                                                                                                                                                           |
| 124 |     12.839685 |    117.631217 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 125 |    183.276522 |    592.070188 | Matt Crook                                                                                                                                                            |
| 126 |    113.309856 |    139.778720 | CNZdenek                                                                                                                                                              |
| 127 |     22.757509 |    306.297048 | Sarah Werning                                                                                                                                                         |
| 128 |     39.727819 |    207.051155 | Marcos Pérez-Losada, Jens T. Høeg & Keith A. Crandall                                                                                                                 |
| 129 |    415.611584 |    145.728018 | Ferran Sayol                                                                                                                                                          |
| 130 |    672.247041 |     74.565949 | Matt Crook                                                                                                                                                            |
| 131 |    217.128846 |    260.650403 | Jonathan Wells                                                                                                                                                        |
| 132 |    204.075977 |    529.766469 | Kanchi Nanjo                                                                                                                                                          |
| 133 |    326.091761 |    612.125683 | Zimices                                                                                                                                                               |
| 134 |    262.149788 |    692.028075 | Myriam\_Ramirez                                                                                                                                                       |
| 135 |    609.720671 |    366.950636 | Christoph Schomburg                                                                                                                                                   |
| 136 |    246.827072 |    554.779017 | T. Michael Keesey                                                                                                                                                     |
| 137 |     27.580013 |    492.524285 | Scott Hartman                                                                                                                                                         |
| 138 |    186.918477 |     85.066651 | Rebecca Groom                                                                                                                                                         |
| 139 |    597.614122 |    337.929033 | Birgit Lang                                                                                                                                                           |
| 140 |    543.497477 |    792.026101 | Mattia Menchetti                                                                                                                                                      |
| 141 |    611.727003 |    534.473998 | Zimices                                                                                                                                                               |
| 142 |    625.081772 |    520.466077 | Zimices                                                                                                                                                               |
| 143 |    216.730639 |    783.081916 | Maija Karala                                                                                                                                                          |
| 144 |    439.900105 |     93.515586 | NA                                                                                                                                                                    |
| 145 |    949.045528 |    454.702822 | Zimices                                                                                                                                                               |
| 146 |    744.957906 |    172.071482 | Alexandre Vong                                                                                                                                                        |
| 147 |     14.317195 |    675.442250 | Collin Gross                                                                                                                                                          |
| 148 |    536.625963 |     13.828126 | Noah Schlottman, photo from Casey Dunn                                                                                                                                |
| 149 |    243.396537 |    422.039654 | Steven Traver                                                                                                                                                         |
| 150 |    999.697474 |    765.273417 | Zimices                                                                                                                                                               |
| 151 |     77.359704 |    790.376256 | Margot Michaud                                                                                                                                                        |
| 152 |    173.099225 |    424.291621 | Smokeybjb                                                                                                                                                             |
| 153 |     35.211751 |    345.566723 | Ferran Sayol                                                                                                                                                          |
| 154 |    190.010377 |    489.184084 | Tracy A. Heath                                                                                                                                                        |
| 155 |    143.687638 |    512.140474 | CNZdenek                                                                                                                                                              |
| 156 |    560.411793 |    559.141113 | Joanna Wolfe                                                                                                                                                          |
| 157 |    932.887457 |    478.160530 | Jaime Headden                                                                                                                                                         |
| 158 |    923.570988 |    779.698598 | Ignacio Contreras                                                                                                                                                     |
| 159 |    601.986228 |    574.610808 | Keith Murdock (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey         |
| 160 |    828.372372 |    576.986526 | Tracy A. Heath                                                                                                                                                        |
| 161 |    837.755470 |     70.002318 | Luc Viatour (source photo) and Andreas Plank                                                                                                                          |
| 162 |    997.530192 |    470.169588 | L. Shyamal                                                                                                                                                            |
| 163 |    925.930306 |    437.689591 | Roberto Díaz Sibaja                                                                                                                                                   |
| 164 |    896.801428 |    486.037096 | Gareth Monger                                                                                                                                                         |
| 165 |    595.093045 |    120.986984 | Jaime Headden, modified by T. Michael Keesey                                                                                                                          |
| 166 |     31.337691 |    412.406272 | Tasman Dixon                                                                                                                                                          |
| 167 |    266.497197 |    229.805105 | Jagged Fang Designs                                                                                                                                                   |
| 168 |    475.592203 |    781.836196 | FJDegrange                                                                                                                                                            |
| 169 |    671.964452 |    433.170483 | Maky (vectorization), Gabriella Skollar (photography), Rebecca Lewis (editing)                                                                                        |
| 170 |    240.641622 |    455.696069 | Neil Kelley                                                                                                                                                           |
| 171 |    748.818524 |     80.068601 | Iain Reid                                                                                                                                                             |
| 172 |    672.700827 |    731.654527 | Gareth Monger                                                                                                                                                         |
| 173 |    152.132642 |    332.503815 | Michelle Site                                                                                                                                                         |
| 174 |    762.391725 |    341.407394 | Zimices                                                                                                                                                               |
| 175 |    182.219262 |    354.606455 | Jagged Fang Designs                                                                                                                                                   |
| 176 |    885.783557 |    217.858623 | Zimices                                                                                                                                                               |
| 177 |    733.336639 |    761.795293 | Margot Michaud                                                                                                                                                        |
| 178 |    784.298665 |    584.346954 | Matt Crook                                                                                                                                                            |
| 179 |    798.869321 |    488.039362 | Ray Simpson (vectorized by T. Michael Keesey)                                                                                                                         |
| 180 |    999.851591 |    182.195575 | Gareth Monger                                                                                                                                                         |
| 181 |    869.872483 |    527.491965 | Marcos Pérez-Losada, Jens T. Høeg & Keith A. Crandall                                                                                                                 |
| 182 |     50.001212 |    650.144166 | Zimices                                                                                                                                                               |
| 183 |    486.341786 |    767.741630 | Mathew Wedel                                                                                                                                                          |
| 184 |    573.963212 |    574.659534 | Jimmy Bernot                                                                                                                                                          |
| 185 |    502.141893 |    257.109216 | Gareth Monger                                                                                                                                                         |
| 186 |    965.403248 |    446.261318 | Birgit Lang, based on a photo by D. Sikes                                                                                                                             |
| 187 |    987.839349 |    503.477563 | Nobu Tamura, modified by Andrew A. Farke                                                                                                                              |
| 188 |    502.888542 |      8.170773 | NA                                                                                                                                                                    |
| 189 |    458.092930 |    508.141751 | Matt Crook                                                                                                                                                            |
| 190 |    742.167352 |    678.257372 | Armin Reindl                                                                                                                                                          |
| 191 |    586.727161 |    378.547517 | Chris huh                                                                                                                                                             |
| 192 |     76.783375 |    674.227584 | Chris huh                                                                                                                                                             |
| 193 |    477.370386 |    129.540141 | Andrew A. Farke                                                                                                                                                       |
| 194 |    650.777747 |     81.930162 | Steven Traver                                                                                                                                                         |
| 195 |    579.194859 |    313.664420 | Saguaro Pictures (source photo) and T. Michael Keesey                                                                                                                 |
| 196 |    827.823400 |    590.231778 | Jagged Fang Designs                                                                                                                                                   |
| 197 |    448.155553 |    297.695363 | Matt Crook                                                                                                                                                            |
| 198 |    755.577346 |    366.562120 | Zimices                                                                                                                                                               |
| 199 |    178.134321 |    124.900245 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
| 200 |   1007.219489 |    592.632584 | Joschua Knüppe                                                                                                                                                        |
| 201 |    869.299322 |    128.220787 | T. Michael Keesey                                                                                                                                                     |
| 202 |    344.419795 |    666.176864 | Collin Gross                                                                                                                                                          |
| 203 |    665.362422 |    523.705078 | Margot Michaud                                                                                                                                                        |
| 204 |    492.276625 |    330.835592 | Andrew A. Farke                                                                                                                                                       |
| 205 |    209.435865 |    324.219771 | Gareth Monger                                                                                                                                                         |
| 206 |    627.347182 |    324.802106 | Chris huh                                                                                                                                                             |
| 207 |    816.325788 |      4.798491 | Gareth Monger                                                                                                                                                         |
| 208 |    104.640399 |    244.882389 | Chris huh                                                                                                                                                             |
| 209 |    630.806465 |    366.380078 | Gareth Monger                                                                                                                                                         |
| 210 |    784.739530 |    208.454842 | Sharon Wegner-Larsen                                                                                                                                                  |
| 211 |    851.763625 |    756.934595 | T. Michael Keesey                                                                                                                                                     |
| 212 |     35.888856 |    775.374853 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 213 |    873.834320 |    764.368527 | Matt Crook                                                                                                                                                            |
| 214 |    388.180064 |    127.833768 | Gareth Monger                                                                                                                                                         |
| 215 |    133.846947 |    486.059451 | V. Deepak                                                                                                                                                             |
| 216 |    353.714243 |    731.341030 | Dmitry Bogdanov                                                                                                                                                       |
| 217 |    262.625735 |    711.652264 | Zimices                                                                                                                                                               |
| 218 |    719.141100 |    697.457911 | Steven Traver                                                                                                                                                         |
| 219 |     69.621748 |    396.632222 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
| 220 |    637.758493 |    291.666190 | Kamil S. Jaron                                                                                                                                                        |
| 221 |    324.009543 |    394.750527 | Ferran Sayol                                                                                                                                                          |
| 222 |   1000.135336 |     96.155488 | NA                                                                                                                                                                    |
| 223 |    633.104673 |    597.235684 | Anthony Caravaggi                                                                                                                                                     |
| 224 |    783.945490 |    311.062643 | Kamil S. Jaron                                                                                                                                                        |
| 225 |    393.239272 |    606.453294 | Zimices                                                                                                                                                               |
| 226 |    670.165332 |    507.336701 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 227 |    340.339925 |    334.584183 | Matt Crook                                                                                                                                                            |
| 228 |    729.520882 |     87.618174 | L. Shyamal                                                                                                                                                            |
| 229 |    586.396549 |    194.533405 | Terpsichores                                                                                                                                                          |
| 230 |    187.850451 |    747.508984 | Gareth Monger                                                                                                                                                         |
| 231 |    687.222656 |     79.162067 | Dean Schnabel                                                                                                                                                         |
| 232 |    608.842173 |    175.426873 | Margot Michaud                                                                                                                                                        |
| 233 |    592.350991 |    673.279861 | Zimices                                                                                                                                                               |
| 234 |    327.985719 |    665.514506 | Matt Crook                                                                                                                                                            |
| 235 |    674.596363 |      8.651478 | Sam Fraser-Smith (vectorized by T. Michael Keesey)                                                                                                                    |
| 236 |    377.617780 |    475.182364 | Gareth Monger                                                                                                                                                         |
| 237 |    132.752664 |    691.199695 | mystica                                                                                                                                                               |
| 238 |    665.660927 |    542.258377 | Gareth Monger                                                                                                                                                         |
| 239 |    476.657043 |    312.810859 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 240 |     69.336910 |    620.752814 | Neil Kelley                                                                                                                                                           |
| 241 |    249.003366 |    388.762648 | Eyal Bartov                                                                                                                                                           |
| 242 |    745.971518 |    568.433090 | T. Michael Keesey                                                                                                                                                     |
| 243 |    693.948270 |    155.086892 | Steven Traver                                                                                                                                                         |
| 244 |    117.846676 |    737.853116 | NA                                                                                                                                                                    |
| 245 |    791.897854 |    627.911094 | Becky Barnes                                                                                                                                                          |
| 246 |    520.700529 |    370.124374 | Chris huh                                                                                                                                                             |
| 247 |    276.418048 |    140.629458 | Dmitry Bogdanov                                                                                                                                                       |
| 248 |    824.294713 |    645.655674 | ArtFavor & annaleeblysse                                                                                                                                              |
| 249 |    211.847303 |    402.440570 | Markus A. Grohme                                                                                                                                                      |
| 250 |    203.245442 |     30.283711 | Steven Traver                                                                                                                                                         |
| 251 |    430.693516 |    399.428429 | Alexandre Vong                                                                                                                                                        |
| 252 |    541.641667 |    433.928473 | Emily Willoughby                                                                                                                                                      |
| 253 |    805.078416 |    381.107959 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 254 |   1002.110933 |    406.960042 | Birgit Lang                                                                                                                                                           |
| 255 |    987.212056 |    708.871655 | C. Camilo Julián-Caballero                                                                                                                                            |
| 256 |    350.486142 |    466.799824 | Scott Hartman                                                                                                                                                         |
| 257 |    707.211209 |    499.728238 | Collin Gross                                                                                                                                                          |
| 258 |    101.496312 |    199.254176 | Matt Crook                                                                                                                                                            |
| 259 |    460.488541 |    722.635129 | NA                                                                                                                                                                    |
| 260 |    322.682953 |    769.820122 | Lukasiniho                                                                                                                                                            |
| 261 |    595.344029 |    302.568474 | Armin Reindl                                                                                                                                                          |
| 262 |    487.232212 |     26.001748 | Melissa Broussard                                                                                                                                                     |
| 263 |     67.273897 |     51.753932 | Matt Crook                                                                                                                                                            |
| 264 |    301.223833 |    231.126749 | Zimices                                                                                                                                                               |
| 265 |    798.929067 |    417.038521 | Agnello Picorelli                                                                                                                                                     |
| 266 |    955.305641 |    572.925246 | Matt Crook                                                                                                                                                            |
| 267 |    253.788342 |    398.284341 | Sean McCann                                                                                                                                                           |
| 268 |    989.031808 |    260.762715 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 269 |     44.925334 |    398.766800 | Jagged Fang Designs                                                                                                                                                   |
| 270 |    129.514905 |    681.951164 | Jack Mayer Wood                                                                                                                                                       |
| 271 |    670.865048 |    148.026416 | Sharon Wegner-Larsen                                                                                                                                                  |
| 272 |    997.738225 |    426.482351 | Chris huh                                                                                                                                                             |
| 273 |    212.984662 |     12.660127 | Carlos Cano-Barbacil                                                                                                                                                  |
| 274 |     85.279231 |    246.526312 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 275 |    797.310107 |    569.911378 | Matt Crook                                                                                                                                                            |
| 276 |     40.768096 |    378.490101 | Margot Michaud                                                                                                                                                        |
| 277 |    487.603160 |    757.696254 | T. Michael Keesey (after Mivart)                                                                                                                                      |
| 278 |    608.040197 |    197.123876 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 279 |    141.003569 |     58.556017 | Dean Schnabel                                                                                                                                                         |
| 280 |    509.364468 |    325.828921 | Jake Warner                                                                                                                                                           |
| 281 |   1001.859203 |    783.953138 | Konsta Happonen                                                                                                                                                       |
| 282 |    378.675839 |    419.687613 | Gareth Monger                                                                                                                                                         |
| 283 |    980.895265 |    321.748017 | Skye McDavid                                                                                                                                                          |
| 284 |    930.386984 |    446.112271 | Matt Crook                                                                                                                                                            |
| 285 |    382.057970 |    145.954031 | Tracy A. Heath                                                                                                                                                        |
| 286 |    726.500969 |    494.046510 | Gareth Monger                                                                                                                                                         |
| 287 |    627.083265 |    718.108733 | Steven Traver                                                                                                                                                         |
| 288 |    733.417730 |    425.644731 | Birgit Lang                                                                                                                                                           |
| 289 |    375.969421 |    134.768864 | Caleb M. Brown                                                                                                                                                        |
| 290 |    926.485914 |    674.559911 | Chris huh                                                                                                                                                             |
| 291 |     91.499010 |     56.049951 | Christoph Schomburg                                                                                                                                                   |
| 292 |    998.940410 |    155.115109 | Markus A. Grohme                                                                                                                                                      |
| 293 |    845.805541 |    177.645091 | xgirouxb                                                                                                                                                              |
| 294 |    591.263918 |    664.037769 | NA                                                                                                                                                                    |
| 295 |    145.173502 |    553.802415 | Andy Wilson                                                                                                                                                           |
| 296 |    150.031539 |    660.221694 | kreidefossilien.de                                                                                                                                                    |
| 297 |     10.475532 |    598.714224 | Taro Maeda                                                                                                                                                            |
| 298 |     85.954135 |     69.131535 | Matt Crook                                                                                                                                                            |
| 299 |    616.760694 |    593.040728 | Gareth Monger                                                                                                                                                         |
| 300 |    215.955524 |    591.362028 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 301 |    758.976762 |    586.570230 | T. Michael Keesey                                                                                                                                                     |
| 302 |    219.258444 |    525.116364 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                                         |
| 303 |    107.872586 |    686.794125 | Mathilde Cordellier                                                                                                                                                   |
| 304 |     64.621969 |    582.808043 | Gareth Monger                                                                                                                                                         |
| 305 |    991.945621 |    513.116139 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 306 |    291.864672 |    709.906862 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 307 |    344.993838 |    782.035799 | Anthony Caravaggi                                                                                                                                                     |
| 308 |    574.080589 |    635.614433 | Ferran Sayol                                                                                                                                                          |
| 309 |    203.265429 |    569.689295 | David Tana                                                                                                                                                            |
| 310 |    448.422993 |     65.368504 | Markus A. Grohme                                                                                                                                                      |
| 311 |    275.105115 |    419.484285 | Lily Hughes                                                                                                                                                           |
| 312 |     21.493720 |    276.267009 | T. Michael Keesey (after Ponomarenko)                                                                                                                                 |
| 313 |   1007.305506 |    237.377425 | Terpsichores                                                                                                                                                          |
| 314 |    627.914153 |    318.075460 | Mattia Menchetti                                                                                                                                                      |
| 315 |     47.771717 |    600.660168 | Tasman Dixon                                                                                                                                                          |
| 316 |   1006.552374 |    345.534153 | Yan Wong                                                                                                                                                              |
| 317 |    583.688788 |    219.492452 | Julio Garza                                                                                                                                                           |
| 318 |    577.116957 |    358.130129 | Crystal Maier                                                                                                                                                         |
| 319 |    465.910663 |    397.575954 | Matt Crook                                                                                                                                                            |
| 320 |    611.538232 |    313.287001 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 321 |    520.049224 |    456.829395 | Steven Traver                                                                                                                                                         |
| 322 |    724.899926 |    324.566984 | Zimices                                                                                                                                                               |
| 323 |     30.608632 |    592.891413 | Margot Michaud                                                                                                                                                        |
| 324 |    107.599900 |    613.312712 | Mali’o Kodis, photograph by Ching (<http://www.flickr.com/photos/36302473@N03/>)                                                                                      |
| 325 |    865.066349 |    753.568539 | terngirl                                                                                                                                                              |
| 326 |    763.011761 |    621.504584 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 327 |    652.417098 |    791.054682 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 328 |    462.010122 |    538.679065 | Tyler Greenfield                                                                                                                                                      |
| 329 |    299.631726 |    141.699937 | Andy Wilson                                                                                                                                                           |
| 330 |    891.728232 |     23.145743 | Iain Reid                                                                                                                                                             |
| 331 |    756.264535 |    142.308787 | Margot Michaud                                                                                                                                                        |
| 332 |    241.051160 |    650.082889 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 333 |    381.125530 |    503.458136 | Tauana J. Cunha                                                                                                                                                       |
| 334 |    172.891083 |    745.658127 | Bryan Carstens                                                                                                                                                        |
| 335 |    665.061547 |    245.489331 | NA                                                                                                                                                                    |
| 336 |    735.247405 |    658.247284 | Tracy A. Heath                                                                                                                                                        |
| 337 |     65.137518 |    592.129769 | Zimices                                                                                                                                                               |
| 338 |    536.398223 |    415.231593 | Francis de Laporte de Castelnau (vectorized by T. Michael Keesey)                                                                                                     |
| 339 |    541.805571 |    160.010902 | Markus A. Grohme                                                                                                                                                      |
| 340 |    641.676121 |     16.022205 | Dianne Bray / Museum Victoria (vectorized by T. Michael Keesey)                                                                                                       |
| 341 |    521.370546 |    491.851686 | Margot Michaud                                                                                                                                                        |
| 342 |    230.756891 |    659.501405 | Matt Crook                                                                                                                                                            |
| 343 |    741.741441 |      8.725235 | Dean Schnabel                                                                                                                                                         |
| 344 |    583.821313 |    148.938863 | Zimices                                                                                                                                                               |
| 345 |    337.063698 |    475.665211 | Adrian Reich                                                                                                                                                          |
| 346 |    413.477953 |     76.228240 | Crystal Maier                                                                                                                                                         |
| 347 |    314.356171 |    740.127417 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 348 |    361.909088 |    142.807102 | Matt Crook                                                                                                                                                            |
| 349 |    739.475117 |    147.600526 | Julien Louys                                                                                                                                                          |
| 350 |    589.195488 |    699.248609 | Sean McCann                                                                                                                                                           |
| 351 |    135.774998 |    408.112823 | Carlos Cano-Barbacil                                                                                                                                                  |
| 352 |     82.705453 |    647.810490 | Tim Bertelink (modified by T. Michael Keesey)                                                                                                                         |
| 353 |     47.651097 |    313.704685 | Meyers Konversations-Lexikon 1897 (vectorized: Yan Wong)                                                                                                              |
| 354 |    315.344139 |     10.561375 | T. Michael Keesey                                                                                                                                                     |
| 355 |    873.603277 |    167.493888 | Mathieu Pélissié                                                                                                                                                      |
| 356 |     89.991887 |    410.699154 | Margot Michaud                                                                                                                                                        |
| 357 |    664.947367 |    630.758361 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 358 |    182.354254 |    408.614374 | Ferran Sayol                                                                                                                                                          |
| 359 |   1015.193669 |    776.278949 | Margot Michaud                                                                                                                                                        |
| 360 |   1014.991015 |    119.296316 | Steven Traver                                                                                                                                                         |
| 361 |   1010.661547 |    294.385375 | Yan Wong                                                                                                                                                              |
| 362 |    825.125415 |    318.853690 | Zimices                                                                                                                                                               |
| 363 |    904.648709 |     68.399306 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 364 |    505.658707 |    314.054406 | Zimices                                                                                                                                                               |
| 365 |    876.111730 |    748.895903 | Birgit Lang                                                                                                                                                           |
| 366 |    717.741403 |    782.279881 | Andrew A. Farke, modified from original by Robert Bruce Horsfall, from Scott 1912                                                                                     |
| 367 |    781.542612 |    678.921525 | NA                                                                                                                                                                    |
| 368 |    571.721154 |    526.980048 | Tasman Dixon                                                                                                                                                          |
| 369 |    747.904342 |    330.296209 | Jessica Anne Miller                                                                                                                                                   |
| 370 |    122.094220 |    754.618670 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 371 |    224.041393 |    490.903781 | Chris huh                                                                                                                                                             |
| 372 |    908.165491 |    475.787053 | Andy Wilson                                                                                                                                                           |
| 373 |    154.424888 |    133.122513 | T. Michael Keesey (after Marek Velechovský)                                                                                                                           |
| 374 |    438.011640 |    714.238625 | Jaime Headden, modified by T. Michael Keesey                                                                                                                          |
| 375 |    628.259333 |     20.892760 | Margot Michaud                                                                                                                                                        |
| 376 |    723.424480 |     15.592180 | Ferran Sayol                                                                                                                                                          |
| 377 |    216.902597 |    356.460966 | Gareth Monger                                                                                                                                                         |
| 378 |    212.230061 |     25.427090 | Gareth Monger                                                                                                                                                         |
| 379 |    810.412091 |    200.133926 | Margot Michaud                                                                                                                                                        |
| 380 |    988.843809 |    375.928374 | Zimices                                                                                                                                                               |
| 381 |    473.701785 |    488.314909 | Armin Reindl                                                                                                                                                          |
| 382 |    857.667768 |    774.048206 | Owen Jones (derived from a CC-BY 2.0 photograph by Paulo B. Chaves)                                                                                                   |
| 383 |      3.518857 |    789.479010 | NA                                                                                                                                                                    |
| 384 |    103.722644 |    394.368214 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 385 |    348.943153 |    624.489533 | Thibaut Brunet                                                                                                                                                        |
| 386 |    830.178802 |    271.709548 | T. Michael Keesey                                                                                                                                                     |
| 387 |   1015.528529 |    304.984364 | Noah Schlottman                                                                                                                                                       |
| 388 |    477.883734 |    137.675476 | Caleb M. Brown                                                                                                                                                        |
| 389 |    269.071580 |    208.996367 | Matt Crook                                                                                                                                                            |
| 390 |   1007.005480 |    716.076694 | Matt Crook                                                                                                                                                            |
| 391 |    809.276573 |    460.778965 | Tasman Dixon                                                                                                                                                          |
| 392 |    378.682743 |    597.302262 | FunkMonk                                                                                                                                                              |
| 393 |    428.761577 |      5.264467 | Timothy Knepp (vectorized by T. Michael Keesey)                                                                                                                       |
| 394 |    591.303022 |    103.487379 | Michael Scroggie                                                                                                                                                      |
| 395 |    204.532119 |    245.702956 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 396 |    418.817608 |    792.932974 | M Kolmann                                                                                                                                                             |
| 397 |     29.889214 |     49.169492 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                           |
| 398 |    213.784039 |    376.104730 | Margot Michaud                                                                                                                                                        |
| 399 |    343.982055 |     15.205218 | Aviceda (vectorized by T. Michael Keesey)                                                                                                                             |
| 400 |    855.689210 |    499.726371 | Markus A. Grohme                                                                                                                                                      |
| 401 |     47.071243 |     29.131357 | Dmitry Bogdanov                                                                                                                                                       |
| 402 |     17.305451 |    574.100434 | Mathieu Basille                                                                                                                                                       |
| 403 |    121.119065 |    390.459230 | Scott Hartman                                                                                                                                                         |
| 404 |    227.365969 |    501.137451 | Milton Tan                                                                                                                                                            |
| 405 |    934.299224 |    130.379750 | Yan Wong                                                                                                                                                              |
| 406 |     51.968587 |    350.563577 | Crystal Maier                                                                                                                                                         |
| 407 |    209.896173 |    220.875949 | Markus A. Grohme                                                                                                                                                      |
| 408 |    904.589752 |    789.834170 | Matt Crook                                                                                                                                                            |
| 409 |    297.623744 |     16.928145 | NA                                                                                                                                                                    |
| 410 |     27.140577 |    323.751067 | Yan Wong                                                                                                                                                              |
| 411 |    540.326591 |    614.404438 | Jiekun He                                                                                                                                                             |
| 412 |    231.796814 |     37.028028 | Ferran Sayol                                                                                                                                                          |
| 413 |    725.716741 |    244.454723 | kreidefossilien.de                                                                                                                                                    |
| 414 |    185.981763 |    107.018301 | Yan Wong                                                                                                                                                              |
| 415 |    462.280200 |    742.377328 | Matt Crook                                                                                                                                                            |
| 416 |     28.078675 |    128.027866 | L. Shyamal                                                                                                                                                            |
| 417 |    214.312827 |    437.212115 | Matt Crook                                                                                                                                                            |
| 418 |   1014.328659 |    422.590951 | Alyssa Bell & Luis Chiappe 2015, dx.doi.org/10.1371/journal.pone.0141690                                                                                              |
| 419 |    473.120183 |    463.191487 | NA                                                                                                                                                                    |
| 420 |    907.886618 |     56.376957 | Yan Wong                                                                                                                                                              |
| 421 |    712.093972 |    673.377540 | Steven Traver                                                                                                                                                         |
| 422 |    441.113843 |    497.562269 | NA                                                                                                                                                                    |
| 423 |    571.393862 |    512.309816 | Becky Barnes                                                                                                                                                          |
| 424 |    790.577505 |    376.085868 | Martin R. Smith                                                                                                                                                       |
| 425 |    761.364321 |     73.867092 | Martin R. Smith                                                                                                                                                       |
| 426 |    973.583003 |    459.802743 | Zimices                                                                                                                                                               |
| 427 |    255.893925 |    777.043075 | Tyler Greenfield                                                                                                                                                      |
| 428 |    433.196814 |    299.795407 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 429 |    985.109634 |    410.103834 | zoosnow                                                                                                                                                               |
| 430 |    474.359121 |    413.363750 | Zimices                                                                                                                                                               |
| 431 |    813.269751 |    539.218387 | Scott Hartman                                                                                                                                                         |
| 432 |    314.988475 |    136.714381 | Noah Schlottman, photo by David J Patterson                                                                                                                           |
| 433 |      7.830263 |    269.427437 | Tarique Sani (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey          |
| 434 |     19.291805 |    713.845610 | Matt Crook                                                                                                                                                            |
| 435 |    130.399237 |    257.732276 | Zimices                                                                                                                                                               |
| 436 |    764.879061 |    683.496081 | Katie S. Collins                                                                                                                                                      |
| 437 |    152.027870 |    497.018906 | T. Michael Keesey (after A. Y. Ivantsov)                                                                                                                              |
| 438 |    488.708688 |    423.450888 | Ignacio Contreras                                                                                                                                                     |
| 439 |     81.965930 |    257.432654 | Matt Martyniuk                                                                                                                                                        |
| 440 |    705.858227 |    794.352479 | Michael Scroggie                                                                                                                                                      |
| 441 |    797.955001 |     50.573941 | Markus A. Grohme                                                                                                                                                      |
| 442 |    924.308067 |    720.860828 | Margot Michaud                                                                                                                                                        |
| 443 |   1004.582539 |    610.414488 | Lukasiniho                                                                                                                                                            |
| 444 |    377.965215 |    724.592602 | david maas / dave hone                                                                                                                                                |
| 445 |    180.707682 |    332.841144 | Gareth Monger                                                                                                                                                         |
| 446 |    305.589367 |     64.023710 | Felix Vaux                                                                                                                                                            |
| 447 |    527.833020 |    174.611249 | Andy Wilson                                                                                                                                                           |
| 448 |    685.824181 |    569.252955 | Zimices                                                                                                                                                               |
| 449 |    738.729725 |    469.771402 | Steven Traver                                                                                                                                                         |
| 450 |    182.044855 |    245.670838 | FunkMonk \[Michael B.H.\] (modified by T. Michael Keesey)                                                                                                             |
| 451 |    983.027175 |     30.863574 | Harold N Eyster                                                                                                                                                       |
| 452 |    742.199699 |    555.580046 | NA                                                                                                                                                                    |
| 453 |    960.290675 |    468.435544 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 454 |    132.039482 |    121.037776 | Hans Hillewaert (photo) and T. Michael Keesey (vectorization)                                                                                                         |
| 455 |    149.482445 |    209.042489 | Sibi (vectorized by T. Michael Keesey)                                                                                                                                |
| 456 |    340.104176 |    742.584574 | Gareth Monger                                                                                                                                                         |
| 457 |    863.886702 |    737.456337 | Ferran Sayol                                                                                                                                                          |
| 458 |    967.749001 |    372.973365 | Collin Gross                                                                                                                                                          |
| 459 |    165.235229 |    271.790951 | Steven Traver                                                                                                                                                         |
| 460 |    993.878315 |    542.594652 | Gareth Monger                                                                                                                                                         |
| 461 |     25.154350 |    199.375555 | Zimices                                                                                                                                                               |
| 462 |    333.882527 |    382.718179 | Gareth Monger                                                                                                                                                         |
| 463 |     45.434869 |    248.453230 | Gareth Monger                                                                                                                                                         |
| 464 |    770.162675 |    403.223943 | T. Michael Keesey                                                                                                                                                     |
| 465 |    371.690732 |    654.582276 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 466 |     68.756217 |    232.952018 | Louis Ranjard                                                                                                                                                         |
| 467 |    642.983176 |     21.469006 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
| 468 |    389.019903 |    474.213920 | T. Michael Keesey (after C. De Muizon)                                                                                                                                |
| 469 |    541.104637 |    459.980471 | Andy Wilson                                                                                                                                                           |
| 470 |    596.031315 |    541.192991 | Kanako Bessho-Uehara                                                                                                                                                  |
| 471 |    605.045701 |    738.271734 | Dmitry Bogdanov                                                                                                                                                       |
| 472 |     87.831329 |     43.220690 | CNZdenek                                                                                                                                                              |
| 473 |      8.820068 |    620.890767 | NA                                                                                                                                                                    |
| 474 |    684.997038 |    280.484450 | Chris huh                                                                                                                                                             |
| 475 |    163.677088 |    784.160705 | Joanna Wolfe                                                                                                                                                          |
| 476 |    321.148504 |    147.627877 | NA                                                                                                                                                                    |
| 477 |    455.101248 |    429.675945 | Evan Swigart (photography) and T. Michael Keesey (vectorization)                                                                                                      |
| 478 |   1011.897183 |    142.780210 | Crystal Maier                                                                                                                                                         |
| 479 |    334.767051 |    630.527327 | T. Michael Keesey                                                                                                                                                     |
| 480 |    979.681531 |    230.193856 | C. Abraczinskas                                                                                                                                                       |
| 481 |    994.466345 |     66.022421 | Danielle Alba                                                                                                                                                         |
| 482 |     48.517256 |    271.458525 | Steven Traver                                                                                                                                                         |
| 483 |    953.142105 |    404.678189 | Meliponicultor Itaymbere                                                                                                                                              |
| 484 |     63.431879 |    406.405520 | Zimices                                                                                                                                                               |
| 485 |    268.004910 |    700.015258 | Dein Freund der Baum (vectorized by T. Michael Keesey)                                                                                                                |
| 486 |    337.329129 |    413.164996 | NA                                                                                                                                                                    |
| 487 |    244.978718 |    440.863528 | T. Tischler                                                                                                                                                           |
| 488 |     11.027352 |    391.726077 | Matt Crook                                                                                                                                                            |
| 489 |    648.539505 |    368.863872 | T. Tischler                                                                                                                                                           |
| 490 |    965.495490 |    446.041437 | Ferran Sayol                                                                                                                                                          |
| 491 |    190.326585 |    560.981465 | Jagged Fang Designs                                                                                                                                                   |
| 492 |    219.311404 |    560.521141 | NA                                                                                                                                                                    |
| 493 |     55.191693 |    675.221991 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                                           |
| 494 |    759.863763 |    648.931436 | Chuanixn Yu                                                                                                                                                           |
| 495 |     13.226280 |    446.419248 | Gareth Monger                                                                                                                                                         |
| 496 |    218.681820 |    466.377618 | Steven Traver                                                                                                                                                         |
| 497 |    112.627727 |    209.625148 | Benjamin Monod-Broca                                                                                                                                                  |
| 498 |    803.298098 |    351.104577 | Tasman Dixon                                                                                                                                                          |
| 499 |     65.703458 |    650.248134 | Birgit Lang                                                                                                                                                           |
| 500 |    371.990343 |    312.718375 | Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus                                              |
| 501 |    361.100704 |    719.609621 | T. Michael Keesey                                                                                                                                                     |
| 502 |    293.906032 |     96.959133 | Steven Traver                                                                                                                                                         |
| 503 |   1008.394917 |    370.022388 | Stacy Spensley (Modified)                                                                                                                                             |
| 504 |    856.276901 |    235.782695 | Erika Schumacher                                                                                                                                                      |
| 505 |    187.817137 |    759.806766 | Matt Dempsey                                                                                                                                                          |
| 506 |    758.551847 |     61.279081 | Scott Hartman                                                                                                                                                         |
| 507 |    936.492308 |    715.502357 | Zimices                                                                                                                                                               |
| 508 |    264.108691 |      7.861390 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 509 |    748.259982 |     46.417762 | Dmitry Bogdanov                                                                                                                                                       |
| 510 |    619.748495 |    559.257559 | Ignacio Contreras                                                                                                                                                     |
| 511 |    715.160047 |    482.025464 | David Orr                                                                                                                                                             |
| 512 |    481.866462 |    547.412284 | Oren Peles / vectorized by Yan Wong                                                                                                                                   |
| 513 |    151.561455 |    717.683253 | NA                                                                                                                                                                    |
| 514 |     32.426464 |     35.786611 | Anthony Caravaggi                                                                                                                                                     |
| 515 |   1013.555844 |    676.710535 | NA                                                                                                                                                                    |
| 516 |     91.875203 |    606.111494 | Matt Crook                                                                                                                                                            |
| 517 |    583.314279 |    178.112034 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 518 |    174.192637 |     77.294243 | NA                                                                                                                                                                    |
| 519 |    721.917420 |    539.050026 | Mattia Menchetti                                                                                                                                                      |
| 520 |    662.307592 |    135.161598 | Ville Koistinen and T. Michael Keesey                                                                                                                                 |
| 521 |    207.940204 |      8.761550 | Noah Schlottman                                                                                                                                                       |
| 522 |    402.676913 |    490.875979 | Zimices                                                                                                                                                               |
| 523 |    618.512776 |    503.847883 | Ben Liebeskind                                                                                                                                                        |
| 524 |    709.047804 |    276.419496 | Michael Scroggie                                                                                                                                                      |
| 525 |    796.004284 |    393.927388 | Jagged Fang Designs                                                                                                                                                   |
| 526 |    625.264300 |    104.040427 | Timothy Knepp (vectorized by T. Michael Keesey)                                                                                                                       |
| 527 |    331.677526 |    253.637826 | Kanchi Nanjo                                                                                                                                                          |
| 528 |     89.788613 |    786.309662 | Ferran Sayol                                                                                                                                                          |
| 529 |    373.821261 |    632.071166 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 530 |    588.963158 |    204.116015 | M Kolmann                                                                                                                                                             |
| 531 |    708.540680 |    585.718508 | Sidney Frederic Harmer, Arthur Everett Shipley (vectorized by Maxime Dahirel)                                                                                         |
| 532 |    852.875888 |    409.744016 | NA                                                                                                                                                                    |
| 533 |    487.423844 |    243.477896 | Markus A. Grohme                                                                                                                                                      |
| 534 |    284.242817 |     49.494050 | Emily Willoughby                                                                                                                                                      |
| 535 |    733.817917 |     74.860979 | Harold N Eyster                                                                                                                                                       |
| 536 |    769.999061 |     47.255694 | xgirouxb                                                                                                                                                              |
| 537 |    252.030841 |     36.781468 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 538 |     27.267451 |     64.285435 | Shyamal                                                                                                                                                               |
| 539 |    761.805240 |     55.079314 | Ferran Sayol                                                                                                                                                          |
| 540 |    709.768299 |    640.710691 | Henry Lydecker                                                                                                                                                        |
| 541 |    514.263952 |    762.719488 | T. Michael Keesey (after Monika Betley)                                                                                                                               |
| 542 |    990.284308 |    336.580164 | Griensteidl and T. Michael Keesey                                                                                                                                     |
| 543 |     71.496549 |    604.703372 | Andy Wilson                                                                                                                                                           |
| 544 |    219.644820 |    628.300022 | Jessica Anne Miller                                                                                                                                                   |
| 545 |    515.099170 |    784.681180 | Sarah Werning                                                                                                                                                         |
| 546 |    191.197112 |    422.907346 | Mali’o Kodis, photograph by P. Funch and R.M. Kristensen                                                                                                              |
| 547 |    842.488882 |    519.612030 | Sarah Werning                                                                                                                                                         |
| 548 |    418.704625 |     90.514837 | ArtFavor & annaleeblysse                                                                                                                                              |
| 549 |    783.665525 |    303.054375 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 550 |    157.196308 |    360.809365 | Steven Traver                                                                                                                                                         |
| 551 |    152.381040 |    283.739292 | T. Michael Keesey                                                                                                                                                     |
| 552 |     57.498385 |    257.467352 | NA                                                                                                                                                                    |
| 553 |    665.641401 |    494.529667 | Ferran Sayol                                                                                                                                                          |
| 554 |    456.224807 |    483.974255 | Matt Crook                                                                                                                                                            |
| 555 |    195.096015 |    377.103094 | FunkMonk                                                                                                                                                              |
| 556 |    510.900675 |    384.306664 | Rebecca Groom                                                                                                                                                         |
| 557 |    473.329893 |    538.940802 | Margot Michaud                                                                                                                                                        |
| 558 |    815.232644 |    576.844617 | Gareth Monger                                                                                                                                                         |
| 559 |    595.207977 |    552.424166 | Steven Traver                                                                                                                                                         |
| 560 |    390.693034 |    386.090955 | Chris huh                                                                                                                                                             |
| 561 |    308.332742 |    722.706709 | S.Martini                                                                                                                                                             |
| 562 |    220.571864 |    515.592126 | Steven Traver                                                                                                                                                         |
| 563 |    625.453563 |    542.395781 | Andrew A. Farke                                                                                                                                                       |
| 564 |    987.223436 |    610.004057 | NA                                                                                                                                                                    |
| 565 |    219.689320 |    448.878447 | Christina N. Hodson                                                                                                                                                   |
| 566 |    419.582113 |    408.102741 | Steven Traver                                                                                                                                                         |
| 567 |    648.768390 |    639.473198 | Gareth Monger                                                                                                                                                         |
| 568 |    541.185318 |    165.399360 | Armin Reindl                                                                                                                                                          |
| 569 |     40.412489 |    116.523701 | FJDegrange                                                                                                                                                            |
| 570 |    450.757417 |    230.036042 | Matt Crook                                                                                                                                                            |
| 571 |   1007.585399 |    190.548330 | Jaime Headden                                                                                                                                                         |
| 572 |    171.808716 |    486.531835 | FJDegrange                                                                                                                                                            |
| 573 |    730.499564 |    343.645167 | Zimices                                                                                                                                                               |
| 574 |    641.551312 |    458.414195 | Zimices                                                                                                                                                               |
| 575 |    803.518455 |    650.426847 | Steven Haddock • Jellywatch.org                                                                                                                                       |
| 576 |    895.786557 |    212.656126 | Markus A. Grohme                                                                                                                                                      |
| 577 |    647.105111 |    750.735093 | Steven Traver                                                                                                                                                         |
| 578 |    701.668480 |    684.388133 | U.S. National Park Service (vectorized by William Gearty)                                                                                                             |
| 579 |    172.961782 |    325.353343 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 580 |    777.107833 |    666.139421 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 581 |     24.225080 |    657.870941 | Ferran Sayol                                                                                                                                                          |
| 582 |    740.803645 |    215.031234 | Gareth Monger                                                                                                                                                         |
| 583 |    296.942928 |    127.735748 | Jagged Fang Designs                                                                                                                                                   |
| 584 |    195.931114 |    107.612719 | Emily Jane McTavish, from <http://en.wikipedia.org/wiki/File:Coccolithus_pelagicus.jpg>                                                                               |
| 585 |    156.944496 |    381.773396 | G. M. Woodward                                                                                                                                                        |
| 586 |    358.091715 |     73.695766 | Andy Wilson                                                                                                                                                           |
| 587 |    302.979891 |    257.423947 | Matt Crook                                                                                                                                                            |
| 588 |    481.185625 |     36.748704 | Steven Traver                                                                                                                                                         |
| 589 |    885.326373 |    578.693486 | Erika Schumacher                                                                                                                                                      |
| 590 |    903.750990 |    237.763634 | Matt Crook                                                                                                                                                            |
| 591 |    229.992658 |      9.583290 | Margot Michaud                                                                                                                                                        |
| 592 |    719.288630 |    424.970341 | Margot Michaud                                                                                                                                                        |
| 593 |    206.844896 |    132.357602 | Kamil S. Jaron                                                                                                                                                        |
| 594 |    128.030247 |    131.261044 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 595 |    293.451831 |    652.800621 | Steven Traver                                                                                                                                                         |
| 596 |    981.210127 |    213.767675 | Scott Hartman                                                                                                                                                         |
| 597 |    774.764214 |    354.206977 | Jagged Fang Designs                                                                                                                                                   |
| 598 |     20.166477 |    725.022201 | V. Deepak                                                                                                                                                             |
| 599 |     52.897481 |    301.501754 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 600 |    373.816224 |    621.543004 | Shyamal                                                                                                                                                               |
| 601 |    891.739440 |    200.413523 | NA                                                                                                                                                                    |
| 602 |    562.994832 |    458.606942 | NA                                                                                                                                                                    |
| 603 |    240.209348 |    236.878010 | Trond R. Oskars                                                                                                                                                       |
| 604 |    993.466855 |    718.159073 | Ingo Braasch                                                                                                                                                          |
| 605 |    560.817780 |    591.348790 | Matt Crook                                                                                                                                                            |
| 606 |    901.912390 |    511.092423 | Matt Crook                                                                                                                                                            |
| 607 |    763.060286 |    164.141156 | Maija Karala                                                                                                                                                          |
| 608 |    602.969976 |    517.316902 | Margot Michaud                                                                                                                                                        |
| 609 |    578.173882 |    559.700182 | Michelle Site                                                                                                                                                         |
| 610 |     40.104275 |     80.947934 | Gareth Monger                                                                                                                                                         |
| 611 |    827.372653 |    785.283659 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 612 |     17.889694 |    703.787895 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 613 |    951.763320 |    387.836606 | NA                                                                                                                                                                    |
| 614 |     60.297644 |    460.357422 | Lafage                                                                                                                                                                |
| 615 |    992.459269 |     14.248019 | Nina Skinner                                                                                                                                                          |
| 616 |    567.612552 |     80.644711 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 617 |    124.643353 |     79.838649 | Moussa Direct Ltd. (photography) and T. Michael Keesey (vectorization)                                                                                                |
| 618 |    446.529861 |    532.479403 | Zimices                                                                                                                                                               |
| 619 |    131.476077 |    464.363838 | Gareth Monger                                                                                                                                                         |
| 620 |    792.628925 |    543.316510 | Alex Slavenko                                                                                                                                                         |
| 621 |    649.995689 |    426.007064 | Andy Wilson                                                                                                                                                           |
| 622 |    185.207861 |    382.891619 | Scott Hartman                                                                                                                                                         |
| 623 |    205.161907 |    473.172449 | Ferran Sayol                                                                                                                                                          |
| 624 |    962.812637 |    558.977236 | Gareth Monger                                                                                                                                                         |
| 625 |    101.726867 |    484.270355 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 626 |    105.441399 |    456.524499 | T. Michael Keesey (vectorization) and Tony Hisgett (photography)                                                                                                      |
| 627 |    390.474021 |    171.006140 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 628 |    835.171917 |    470.248719 | Matt Crook                                                                                                                                                            |
| 629 |    512.647699 |      5.157168 | Tasman Dixon                                                                                                                                                          |
| 630 |    468.623219 |    336.385939 | Andrew A. Farke                                                                                                                                                       |
| 631 |    511.677903 |     35.445118 | Scott Reid                                                                                                                                                            |
| 632 |    158.907699 |    592.531056 | T. Michael Keesey                                                                                                                                                     |
| 633 |    724.863389 |    414.837385 | NA                                                                                                                                                                    |
| 634 |    126.465926 |    557.941281 | T. Michael Keesey                                                                                                                                                     |
| 635 |    638.583949 |    565.431885 | Michelle Site                                                                                                                                                         |
| 636 |    619.340241 |    613.631085 | Maija Karala                                                                                                                                                          |
| 637 |    687.182726 |    420.440543 | Ingo Braasch                                                                                                                                                          |
| 638 |    477.731026 |    455.420293 | Jagged Fang Designs                                                                                                                                                   |
| 639 |    679.182114 |    346.636839 | Zimices                                                                                                                                                               |
| 640 |    573.515363 |    103.182414 | Matthew E. Clapham                                                                                                                                                    |
| 641 |    597.699261 |    593.549823 | Neil Kelley                                                                                                                                                           |
| 642 |    583.381834 |    566.970911 | Scott Hartman                                                                                                                                                         |
| 643 |    772.426386 |    630.151401 | Nobu Tamura                                                                                                                                                           |
| 644 |    778.444823 |    415.217309 | Maxime Dahirel                                                                                                                                                        |
| 645 |    160.694850 |     67.263769 | Andy Wilson                                                                                                                                                           |
| 646 |    783.022327 |    323.127658 | Katie S. Collins                                                                                                                                                      |
| 647 |      8.767260 |     31.480498 | NA                                                                                                                                                                    |
| 648 |    236.763547 |    279.753016 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 649 |    173.985033 |    301.110051 | Andy Wilson                                                                                                                                                           |
| 650 |    814.210126 |    637.315890 | Scott Hartman                                                                                                                                                         |
| 651 |    603.332066 |     92.709182 | Oliver Voigt                                                                                                                                                          |
| 652 |    372.488137 |    201.706885 | Emily Willoughby                                                                                                                                                      |
| 653 |    983.524002 |    284.950608 | Matt Martyniuk                                                                                                                                                        |
| 654 |    599.159125 |    790.141543 | Yan Wong from drawing in The Century Dictionary (1911)                                                                                                                |
| 655 |   1004.618773 |    442.136007 | Matt Crook                                                                                                                                                            |
| 656 |    496.336154 |    361.878175 | Ingo Braasch                                                                                                                                                          |
| 657 |    228.197519 |    393.803232 | Tasman Dixon                                                                                                                                                          |
| 658 |   1017.568153 |    169.553802 | Gareth Monger                                                                                                                                                         |
| 659 |    503.923912 |     18.439939 | Yan Wong from drawing by T. F. Zimmermann                                                                                                                             |
| 660 |    450.781623 |    768.292705 | Zimices                                                                                                                                                               |
| 661 |     13.308733 |    519.240260 | Saguaro Pictures (source photo) and T. Michael Keesey                                                                                                                 |
| 662 |    625.567949 |    123.025159 | Mattia Menchetti                                                                                                                                                      |
| 663 |    638.672311 |    620.639439 | Lafage                                                                                                                                                                |
| 664 |    653.243676 |    731.704011 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 665 |     94.098205 |    230.517133 | Kamil S. Jaron                                                                                                                                                        |
| 666 |    356.483916 |    255.286870 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 667 |    838.066603 |    187.183175 | Zimices                                                                                                                                                               |
| 668 |    215.063773 |     36.332127 | Meyer-Wachsmuth I, Curini Galletti M, Jondelius U (<doi:10.1371/journal.pone.0107688>). Vectorization by Y. Wong                                                      |
| 669 |    236.657100 |    444.815126 | Sharon Wegner-Larsen                                                                                                                                                  |
| 670 |    723.782877 |    687.821335 | Ingo Braasch                                                                                                                                                          |
| 671 |    340.264199 |    398.940297 | T. Michael Keesey (after Mivart)                                                                                                                                      |
| 672 |      9.854691 |    337.190426 | FunkMonk                                                                                                                                                              |
| 673 |    699.082993 |    359.278348 | Kanchi Nanjo                                                                                                                                                          |
| 674 |    411.013293 |    593.999793 | NA                                                                                                                                                                    |
| 675 |    371.478691 |    448.509978 | NA                                                                                                                                                                    |
| 676 |    124.778432 |    596.879326 | Yan Wong from illustration by Charles Orbigny                                                                                                                         |
| 677 |    319.124038 |    755.347427 | Steven Traver                                                                                                                                                         |
| 678 |    724.962160 |    718.322099 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                                         |
| 679 |    352.347283 |    630.499825 | FunkMonk                                                                                                                                                              |
| 680 |    895.526611 |    712.245796 | Matt Crook                                                                                                                                                            |
| 681 |    845.793407 |    138.317112 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 682 |    649.927489 |    248.049248 | Margot Michaud                                                                                                                                                        |
| 683 |    480.869666 |    404.450552 | Francesco “Architetto” Rollandin                                                                                                                                      |
| 684 |    440.252497 |    578.062179 | Andy Wilson                                                                                                                                                           |
| 685 |    477.598884 |    440.053580 | Ferran Sayol                                                                                                                                                          |
| 686 |   1013.747741 |     97.711407 | Andy Wilson                                                                                                                                                           |
| 687 |     87.562389 |    120.572225 | Ferran Sayol                                                                                                                                                          |
| 688 |    443.538288 |    781.127573 | Margot Michaud                                                                                                                                                        |
| 689 |    420.240755 |     52.708796 | Zimices                                                                                                                                                               |
| 690 |     58.028974 |    115.960477 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 691 |    492.690674 |    543.113213 | Dean Schnabel                                                                                                                                                         |
| 692 |    141.394361 |    584.931231 | NA                                                                                                                                                                    |
| 693 |    168.713474 |    503.647228 | Ieuan Jones                                                                                                                                                           |
| 694 |     39.624945 |    634.637021 | Mathew Wedel                                                                                                                                                          |
| 695 |    806.009017 |    451.615665 | Shyamal                                                                                                                                                               |
| 696 |      8.372286 |    360.114617 | Markus A. Grohme                                                                                                                                                      |
| 697 |    479.023596 |    748.837721 | Matt Crook                                                                                                                                                            |
| 698 |    465.241561 |    731.752710 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                        |
| 699 |    895.128087 |    502.941485 | Anthony Caravaggi                                                                                                                                                     |
| 700 |    634.047056 |    429.589583 | Dmitry Bogdanov (modified by T. Michael Keesey)                                                                                                                       |
| 701 |     63.584130 |     74.878164 | Margot Michaud                                                                                                                                                        |
| 702 |    747.264322 |    694.210509 | Chris huh                                                                                                                                                             |
| 703 |     11.072766 |    283.142718 | Sean McCann                                                                                                                                                           |
| 704 |    887.556339 |    725.599531 | Sarah Werning                                                                                                                                                         |
| 705 |    310.081259 |    376.689710 | Matt Crook                                                                                                                                                            |
| 706 |    198.072631 |    577.721888 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 707 |    482.483725 |    774.429865 | Matt Crook                                                                                                                                                            |
| 708 |    598.294947 |    172.965606 | Anthony Caravaggi                                                                                                                                                     |
| 709 |     82.347335 |    553.396668 | Margot Michaud                                                                                                                                                        |
| 710 |    245.687071 |    296.071209 | Ignacio Contreras                                                                                                                                                     |
| 711 |    223.136230 |    600.418745 | Zimices                                                                                                                                                               |
| 712 |    822.696204 |    159.504626 | Scott Hartman                                                                                                                                                         |
| 713 |    377.455656 |    459.651304 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 714 |    620.680094 |    229.018177 | Francesca Belem Lopes Palmeira                                                                                                                                        |
| 715 |   1008.209110 |    247.813023 | Matthew Hooge (vectorized by T. Michael Keesey)                                                                                                                       |
| 716 |   1012.580212 |    552.733695 | Terpsichores                                                                                                                                                          |
| 717 |     21.530077 |    105.935901 | Andrew A. Farke                                                                                                                                                       |
| 718 |    368.104328 |    785.909897 | T. Michael Keesey                                                                                                                                                     |
| 719 |     64.245491 |    489.648689 | T. Michael Keesey                                                                                                                                                     |
| 720 |    611.560705 |     17.522039 | Zimices                                                                                                                                                               |
| 721 |    784.140774 |    647.762798 | FunkMonk                                                                                                                                                              |
| 722 |    621.729139 |    630.088699 | Zimices                                                                                                                                                               |
| 723 |    630.552869 |    489.292794 | Matt Crook                                                                                                                                                            |
| 724 |    336.977910 |    167.870485 | Jagged Fang Designs                                                                                                                                                   |
| 725 |    206.823499 |    361.516914 | Matt Crook                                                                                                                                                            |
| 726 |   1009.459885 |    271.569867 | Andy Wilson                                                                                                                                                           |
| 727 |    952.569795 |    673.949968 | Chase Brownstein                                                                                                                                                      |
| 728 |    578.165628 |    504.578327 | Yan Wong                                                                                                                                                              |
| 729 |    719.850369 |    134.351837 | Zimices                                                                                                                                                               |
| 730 |    336.469679 |    139.486572 | Abraão B. Leite                                                                                                                                                       |
| 731 |    315.312885 |    663.446510 | A. R. McCulloch (vectorized by T. Michael Keesey)                                                                                                                     |
| 732 |    103.733453 |    129.361474 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 733 |    458.700019 |     97.685449 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 734 |     65.335404 |     28.572759 | Luc Viatour (source photo) and Andreas Plank                                                                                                                          |
| 735 |    930.482509 |    461.562195 | Maija Karala                                                                                                                                                          |
| 736 |    153.498384 |    534.435215 | Ignacio Contreras                                                                                                                                                     |
| 737 |     44.461910 |     60.052706 | Zimices                                                                                                                                                               |
| 738 |    581.621763 |    715.661197 | Lafage                                                                                                                                                                |
| 739 |    740.178423 |    788.706155 | Chris huh                                                                                                                                                             |
| 740 |    209.457512 |    408.891708 | Jagged Fang Designs                                                                                                                                                   |
| 741 |    777.282376 |    372.509410 | Abraão B. Leite                                                                                                                                                       |
| 742 |    390.478703 |    155.453659 | Andy Wilson                                                                                                                                                           |
| 743 |    517.193293 |     12.951868 | Yan Wong                                                                                                                                                              |
| 744 |    970.997928 |    253.206576 | Scott Reid                                                                                                                                                            |
| 745 |    742.910421 |    233.691662 | Ferran Sayol                                                                                                                                                          |
| 746 |    439.495914 |    689.198528 | Collin Gross                                                                                                                                                          |
| 747 |    482.033457 |    229.563572 | Ferran Sayol                                                                                                                                                          |
| 748 |    397.892446 |     89.558746 | Margot Michaud                                                                                                                                                        |
| 749 |    565.850976 |    321.310988 | Gareth Monger                                                                                                                                                         |
| 750 |    202.746616 |    338.118872 | Zimices                                                                                                                                                               |
| 751 |    297.006355 |    352.599775 | S.Martini                                                                                                                                                             |
| 752 |    200.409131 |    609.302093 | Sarah Alewijnse                                                                                                                                                       |
| 753 |      5.975046 |    498.532501 | Christoph Schomburg                                                                                                                                                   |
| 754 |    481.706787 |    351.003461 | Rebecca Groom                                                                                                                                                         |
| 755 |    843.073452 |    149.956303 | Sam Fraser-Smith (vectorized by T. Michael Keesey)                                                                                                                    |
| 756 |    706.188435 |      7.434413 | Matt Crook                                                                                                                                                            |
| 757 |     16.676363 |    369.249669 | Kanako Bessho-Uehara                                                                                                                                                  |
| 758 |    941.561873 |    484.410770 | Birgit Lang                                                                                                                                                           |
| 759 |     38.645643 |    448.104671 | Ben Moon                                                                                                                                                              |
| 760 |    523.057979 |     86.619671 | Andy Wilson                                                                                                                                                           |
| 761 |    113.692451 |    493.338080 | NA                                                                                                                                                                    |
| 762 |    983.232711 |    147.681394 | Ricardo N. Martinez & Oscar A. Alcober                                                                                                                                |
| 763 |    744.342063 |    128.617724 | NA                                                                                                                                                                    |
| 764 |    489.932519 |     66.458588 | NA                                                                                                                                                                    |
| 765 |    573.136628 |    691.340875 | Gareth Monger                                                                                                                                                         |
| 766 |    636.898881 |    727.072905 | Darius Nau                                                                                                                                                            |
| 767 |    716.600034 |    145.620177 | Matt Dempsey                                                                                                                                                          |
| 768 |    755.814868 |    634.969980 | Margot Michaud                                                                                                                                                        |
| 769 |    960.537109 |    617.903920 | Zimices                                                                                                                                                               |
| 770 |    736.953863 |    538.098412 | Tyler Greenfield                                                                                                                                                      |
| 771 |    594.864985 |    462.998672 | Margot Michaud                                                                                                                                                        |
| 772 |    495.117852 |     39.165175 | annaleeblysse                                                                                                                                                         |
| 773 |     10.187666 |     99.966794 | Birgit Lang                                                                                                                                                           |
| 774 |    146.157313 |     28.807430 | Scott Hartman                                                                                                                                                         |
| 775 |    170.253188 |    293.821701 | Markus A. Grohme                                                                                                                                                      |
| 776 |     51.283647 |    573.311234 | Nobu Tamura                                                                                                                                                           |
| 777 |    700.122783 |    655.512464 | Margot Michaud                                                                                                                                                        |
| 778 |    575.718766 |    642.197290 | Scott Hartman                                                                                                                                                         |
| 779 |    293.425225 |    201.610380 | T. Michael Keesey                                                                                                                                                     |
| 780 |    307.482964 |    468.469665 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 781 |    626.115014 |    688.284912 | A. R. McCulloch (vectorized by T. Michael Keesey)                                                                                                                     |
| 782 |    674.332486 |    748.371357 | Matt Crook                                                                                                                                                            |
| 783 |    307.334782 |    269.540362 | Zimices                                                                                                                                                               |
| 784 |    277.905747 |    777.432753 | Skye McDavid                                                                                                                                                          |
| 785 |    162.959761 |    337.507299 | FJDegrange                                                                                                                                                            |
| 786 |    842.233861 |    201.221905 | Ignacio Contreras                                                                                                                                                     |
| 787 |    671.727638 |     94.216959 | Ferran Sayol                                                                                                                                                          |
| 788 |    970.228448 |    384.997294 | Birgit Lang                                                                                                                                                           |
| 789 |    138.427595 |     79.579762 | Matt Crook                                                                                                                                                            |
| 790 |    565.456420 |    732.090898 | Daniel Jaron                                                                                                                                                          |
| 791 |     75.568395 |    630.981978 | Steven Traver                                                                                                                                                         |
| 792 |    850.672836 |    578.756113 | Zimices                                                                                                                                                               |
| 793 |    360.236138 |    499.089727 | T. Michael Keesey (vectorization) and Larry Loos (photography)                                                                                                        |
| 794 |    962.483323 |    490.372101 | Maxime Dahirel                                                                                                                                                        |
| 795 |    260.889242 |     60.120485 | xgirouxb                                                                                                                                                              |
| 796 |    679.571863 |     22.477511 | Tasman Dixon                                                                                                                                                          |
| 797 |    563.724604 |    310.514451 | Zimices                                                                                                                                                               |
| 798 |    337.253074 |    593.169747 | Jagged Fang Designs                                                                                                                                                   |
| 799 |    624.252088 |    451.843983 | Margot Michaud                                                                                                                                                        |
| 800 |    326.683538 |    319.722437 | Felix Vaux                                                                                                                                                            |
| 801 |   1004.204611 |     11.112031 | NA                                                                                                                                                                    |
| 802 |    569.602223 |     89.876551 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 803 |    669.253958 |    582.347100 | Brockhaus and Efron                                                                                                                                                   |
| 804 |    403.699544 |    518.219895 | T. Michael Keesey                                                                                                                                                     |
| 805 |    627.237290 |    529.477409 | Jagged Fang Designs                                                                                                                                                   |
| 806 |    203.209892 |    724.367833 | Matt Martyniuk                                                                                                                                                        |
| 807 |    387.258663 |    451.495727 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 808 |    846.683525 |     46.469910 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 809 |    917.492319 |    513.727844 | T. Michael Keesey                                                                                                                                                     |
| 810 |    513.543166 |    149.143583 | Scott Hartman                                                                                                                                                         |
| 811 |    847.563411 |    122.098636 | Steven Traver                                                                                                                                                         |
| 812 |    374.072979 |    167.619822 | L. Shyamal                                                                                                                                                            |
| 813 |    617.633518 |     25.820029 | nicubunu                                                                                                                                                              |
| 814 |     71.459626 |    124.331008 | Lukasiniho                                                                                                                                                            |
| 815 |    559.551114 |    749.007859 | Zimices                                                                                                                                                               |
| 816 |    838.277497 |    609.120913 | André Karwath (vectorized by T. Michael Keesey)                                                                                                                       |
| 817 |    595.910730 |    369.609628 | NA                                                                                                                                                                    |
| 818 |    607.342573 |    108.183170 | NA                                                                                                                                                                    |
| 819 |    110.160971 |    746.081486 | Ferran Sayol                                                                                                                                                          |
| 820 |    343.337935 |    211.871688 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 821 |    227.516268 |     19.603627 | Collin Gross                                                                                                                                                          |
| 822 |    983.160470 |    492.819496 | Chris huh                                                                                                                                                             |
| 823 |    943.682182 |    225.319702 | Jagged Fang Designs                                                                                                                                                   |
| 824 |     11.046249 |    691.247011 | Matt Crook                                                                                                                                                            |
| 825 |     39.451842 |    337.349178 | Dr. Thomas G. Barnes, USFWS                                                                                                                                           |
| 826 |    491.437666 |    382.624070 | Roberto Díaz Sibaja                                                                                                                                                   |
| 827 |    387.679591 |    702.171518 | Zimices                                                                                                                                                               |
| 828 |    873.786878 |    674.330703 | Dmitry Bogdanov                                                                                                                                                       |
| 829 |    604.069619 |    612.069280 | Matt Crook                                                                                                                                                            |
| 830 |    490.397848 |    709.333431 | Harold N Eyster                                                                                                                                                       |
| 831 |    994.500131 |    300.614800 | Alex Slavenko                                                                                                                                                         |
| 832 |    746.688037 |    482.821740 | Matt Martyniuk                                                                                                                                                        |
| 833 |    291.678333 |    792.634551 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 834 |    649.071126 |    652.827183 | Matt Crook                                                                                                                                                            |
| 835 |    320.857328 |    452.402100 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 836 |    445.786996 |    468.275493 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                                         |
| 837 |    994.232937 |    488.507785 | Kamil S. Jaron                                                                                                                                                        |
| 838 |     88.510658 |    662.732915 | Jimmy Bernot                                                                                                                                                          |
| 839 |     33.735497 |    580.803448 | Jaime Headden                                                                                                                                                         |
| 840 |    510.375320 |    609.285441 | Chris A. Hamilton                                                                                                                                                     |
| 841 |    604.612201 |    677.870172 | Matt Crook                                                                                                                                                            |
| 842 |    396.939921 |    214.729784 | Carlos Cano-Barbacil                                                                                                                                                  |
| 843 |    893.785371 |    763.791242 | Margot Michaud                                                                                                                                                        |
| 844 |     54.739955 |    447.461717 | C. Camilo Julián-Caballero                                                                                                                                            |
| 845 |     32.548638 |    272.387767 | NA                                                                                                                                                                    |
| 846 |    317.214248 |    781.321430 | Gopal Murali                                                                                                                                                          |
| 847 |    847.495722 |    682.608552 | Zimices                                                                                                                                                               |
| 848 |     10.878092 |    491.109920 | Gareth Monger                                                                                                                                                         |
| 849 |    810.029088 |    536.124560 | Jagged Fang Designs                                                                                                                                                   |
| 850 |    193.347433 |    554.006743 | Caleb M. Brown                                                                                                                                                        |
| 851 |    137.922211 |    720.778085 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 852 |    977.877725 |    772.303640 | Christoph Schomburg                                                                                                                                                   |
| 853 |    671.666931 |    131.298377 | Kanchi Nanjo                                                                                                                                                          |
| 854 |    685.936097 |    245.910999 | Mali’o Kodis, image from Brockhaus and Efron Encyclopedic Dictionary                                                                                                  |
| 855 |   1004.261296 |     42.263193 | Gareth Monger                                                                                                                                                         |
| 856 |    528.537396 |     76.695502 | Steven Traver                                                                                                                                                         |
| 857 |    330.022388 |    198.791507 | John Curtis (vectorized by T. Michael Keesey)                                                                                                                         |
| 858 |    986.818292 |    356.198454 | Noah Schlottman, photo from Casey Dunn                                                                                                                                |
| 859 |     47.760357 |     73.332652 | Steven Traver                                                                                                                                                         |
| 860 |    800.907539 |    583.916638 | Matt Crook                                                                                                                                                            |
| 861 |    700.453506 |     87.227804 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 862 |   1014.056111 |    391.081350 | Margot Michaud                                                                                                                                                        |
| 863 |    400.448201 |    161.057417 | Jaime Headden                                                                                                                                                         |
| 864 |    589.432325 |    656.228903 | CNZdenek                                                                                                                                                              |
| 865 |    456.609772 |    682.168522 | Scott Hartman                                                                                                                                                         |
| 866 |    441.541851 |    731.932970 | NA                                                                                                                                                                    |
| 867 |     33.422731 |     11.720006 | Alex Slavenko                                                                                                                                                         |
| 868 |    972.102907 |    313.601040 | Kailah Thorn & Mark Hutchinson                                                                                                                                        |
| 869 |    350.982121 |    687.706353 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 870 |    286.403537 |    470.862413 | Margot Michaud                                                                                                                                                        |
| 871 |    817.294829 |    306.731672 | Jagged Fang Designs                                                                                                                                                   |
| 872 |    470.503703 |    477.749836 | Timothy Knepp of the U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                |
| 873 |    806.118017 |     57.207989 | Christopher Watson (photo) and T. Michael Keesey (vectorization)                                                                                                      |
| 874 |    800.040383 |    186.575317 | Zimices                                                                                                                                                               |
| 875 |    209.077507 |    455.813589 | Noah Schlottman, photo by Reinhard Jahn                                                                                                                               |
| 876 |    587.803325 |    509.273564 | Matt Crook                                                                                                                                                            |
| 877 |      8.428314 |    553.805867 | Michael Scroggie                                                                                                                                                      |
| 878 |     14.355306 |    351.355771 | Taro Maeda                                                                                                                                                            |
| 879 |    859.235630 |    616.629978 | Gareth Monger                                                                                                                                                         |
| 880 |    933.730900 |    788.704574 | Gareth Monger                                                                                                                                                         |
| 881 |     56.447301 |      9.844198 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 882 |    130.739078 |    152.592763 | Matus Valach                                                                                                                                                          |
| 883 |    861.975961 |    194.907376 | Zimices                                                                                                                                                               |
| 884 |    550.250424 |    622.184958 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 885 |    799.182550 |    297.879387 | Crystal Maier                                                                                                                                                         |
| 886 |    385.293421 |    612.135615 | Mette Aumala                                                                                                                                                          |
| 887 |    170.755912 |    432.910954 | Maija Karala                                                                                                                                                          |
| 888 |    191.634003 |    257.449598 | Espen Horn (model; vectorized by T. Michael Keesey from a photo by H. Zell)                                                                                           |
| 889 |    356.811935 |    659.545348 | T. Michael Keesey and Tanetahi                                                                                                                                        |
| 890 |   1003.050511 |    257.276828 | T. Michael Keesey                                                                                                                                                     |
| 891 |    929.786664 |     11.634475 | Sarah Werning                                                                                                                                                         |
| 892 |    620.769273 |     80.892184 | L. Shyamal                                                                                                                                                            |
| 893 |    235.153943 |    163.371685 | Michelle Site                                                                                                                                                         |
| 894 |    782.701740 |    336.975090 | Margot Michaud                                                                                                                                                        |
| 895 |    905.925324 |    122.698289 | Ben Liebeskind                                                                                                                                                        |
| 896 |    143.807929 |    762.155128 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 897 |    286.664715 |    632.376106 | Jagged Fang Designs                                                                                                                                                   |
| 898 |    640.230796 |    337.413373 | Christoph Schomburg                                                                                                                                                   |
| 899 |    572.199207 |    622.949147 | NA                                                                                                                                                                    |
| 900 |    636.072080 |     82.081401 | Jagged Fang Designs                                                                                                                                                   |
| 901 |    144.717765 |     39.897795 | Tauana J. Cunha                                                                                                                                                       |
| 902 |    493.475017 |    125.245440 | Markus A. Grohme                                                                                                                                                      |
| 903 |     98.557025 |    706.156875 | Gareth Monger                                                                                                                                                         |
| 904 |    561.845259 |    379.095382 | Qiang Ou                                                                                                                                                              |
| 905 |    310.732413 |    772.643434 | Ferran Sayol                                                                                                                                                          |
| 906 |     20.420465 |     54.955011 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                                 |
| 907 |    626.691717 |    704.373806 | Matt Crook                                                                                                                                                            |
| 908 |    850.604079 |     55.569345 | Steven Traver                                                                                                                                                         |
| 909 |      7.675426 |    566.049642 | Steven Traver                                                                                                                                                         |
| 910 |    661.551156 |    655.504175 | Andy Wilson                                                                                                                                                           |
| 911 |     43.126424 |    267.678066 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 912 |    466.488341 |    299.939289 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 913 |    180.189294 |    317.958304 | NA                                                                                                                                                                    |
| 914 |    919.654253 |    709.086348 | Ieuan Jones                                                                                                                                                           |
| 915 |    170.689686 |     92.227116 | Steven Traver                                                                                                                                                         |

    #> Your tweet has been posted!
