
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

T. Michael Keesey, Steven Haddock • Jellywatch.org, Ferran Sayol,
Zimices, Michelle Site, Lukasiniho, Gabriela Palomo-Munoz, Matt Crook,
Oscar Sanisidro, Margot Michaud, \[unknown\], Gareth Monger, Milton Tan,
John Curtis (vectorized by T. Michael Keesey), Ignacio Contreras, Pranav
Iyer (grey ideas), Kamil S. Jaron, Chris huh, Darren Naish (vectorize by
T. Michael Keesey), Michele M Tobias, Nobu Tamura, vectorized by
Zimices, Dean Schnabel, Sarefo (vectorized by T. Michael Keesey), Robbie
N. Cada (modified by T. Michael Keesey), Obsidian Soul (vectorized by T.
Michael Keesey), www.studiospectre.com, Steven Traver, Markus A. Grohme,
Ghedoghedo (vectorized by T. Michael Keesey), Tasman Dixon, Rafael Maia,
C. Camilo Julián-Caballero, Smokeybjb (vectorized by T. Michael Keesey),
FunkMonk, Michael P. Taylor, Tracy A. Heath, Mark Hofstetter (vectorized
by T. Michael Keesey), Sarah Alewijnse, Martin R. Smith, from photo by
Jürgen Schoner, Scott Hartman, Shyamal, Rene Martin, Mathew Wedel,
Lafage, Stephen O’Connor (vectorized by T. Michael Keesey), Emily
Willoughby, Henry Lydecker, Nobu Tamura (vectorized by T. Michael
Keesey), Dmitry Bogdanov, Smokeybjb, Birgit Lang, Javiera Constanzo,
Michael Scroggie, Andreas Trepte (vectorized by T. Michael Keesey), Beth
Reinke, Mali’o Kodis, photograph from
<http://commons.wikimedia.org/wiki/File:Trichoplax.jpg>, Jaime Headden,
Scott Reid, DW Bapst, modified from Figure 1 of Belanger (2011,
PALAIOS)., Carlos Cano-Barbacil, Alexander Schmidt-Lebuhn, Crystal
Maier, Kanchi Nanjo, Jagged Fang Designs, CNZdenek, Noah Schlottman,
photo by Carol Cummings, Fernando Carezzano, Alexandre Vong, Lani Mohan,
Xavier Giroux-Bougard, Ghedo (vectorized by T. Michael Keesey), Maija
Karala, Renato de Carvalho Ferreira, Roberto Díaz Sibaja, Nobu Tamura
(modified by T. Michael Keesey), Matt Martyniuk, Qiang Ou, C. W. Nash
(illustration) and Timothy J. Bartley (silhouette), Sarah Werning,
Dr. Thomas G. Barnes, USFWS, Peter Coxhead, James R. Spotila and Ray
Chatterji, Manabu Bessho-Uehara, Andy Wilson, Christoph Schomburg, Pete
Buchholz, Javier Luque, Cesar Julian, Dmitry Bogdanov (vectorized by T.
Michael Keesey), M Kolmann, Manabu Sakamoto, Collin Gross, Brad
McFeeters (vectorized by T. Michael Keesey), Chase Brownstein, Karkemish
(vectorized by T. Michael Keesey), Natalie Claunch, Jon Hill (Photo by
DickDaniels:
<http://en.wikipedia.org/wiki/File:Green_Woodhoopoe_RWD7.jpg>), Matthew
E. Clapham, Sherman F. Denton via rawpixel.com (illustration) and
Timothy J. Bartley (silhouette), Original drawing by Dmitry Bogdanov,
vectorized by Roberto Díaz Sibaja, Unknown (photo), John E. McCormack,
Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C.
Glenn, Robb T. Brumfield & T. Michael Keesey, Andrew A. Farke, Richard
Lampitt, Jeremy Young / NHM (vectorization by Yan Wong), Rebecca Groom,
Mr E? (vectorized by T. Michael Keesey), Jack Mayer Wood, Scott Hartman
(vectorized by T. Michael Keesey), Jaime A. Headden (vectorized by T.
Michael Keesey), Julio Garza, Robert Gay, Keith Murdock (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Alex Slavenko,
Nina Skinner, Didier Descouens (vectorized by T. Michael Keesey), Tyler
Greenfield, xgirouxb, Tauana J. Cunha, Chloé Schmidt, Cathy, Francesco
“Architetto” Rollandin, Kai R. Caspar, Falconaumanni and T. Michael
Keesey, David Orr, S.Martini, Sharon Wegner-Larsen, Inessa Voet, Felix
Vaux, Servien (vectorized by T. Michael Keesey), Riccardo Percudani,
Joanna Wolfe, Verdilak, Dinah Challen, Mathieu Pélissié, Darius Nau,
Kailah Thorn & Mark Hutchinson, Jose Carlos Arenas-Monroy, Craig Dylke,
LeonardoG (photography) and T. Michael Keesey (vectorization), Katie S.
Collins, T. Michael Keesey (after Mivart), Scott D. Sampson, Mark A.
Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua
A. Smith, Alan L. Titus, SauropodomorphMonarch, T. Michael Keesey
(vectorization) and Nadiatalent (photography), Jim Bendon (photography)
and T. Michael Keesey (vectorization), Pedro de Siracusa, Matt Dempsey,
John Gould (vectorized by T. Michael Keesey), Leann Biancani, photo by
Kenneth Clifton, Melissa Broussard, Fir0002/Flagstaffotos (photo), John
E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G.
Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Cagri
Cevrim, Liftarn, Ville Koistinen and T. Michael Keesey, Iain Reid, Roule
Jammes (vectorized by T. Michael Keesey), Alan Manson (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Noah Schlottman,
photo by Gustav Paulay for Moorea Biocode, Mali’o Kodis, photograph by
Aqua-Photos (<http://www.flickr.com/people/undervannsfotografen/>),
FunkMonk (Michael B. H.), Chuanixn Yu, Jessica Anne Miller, Xavier A.
Jenkins, Gabriel Ugueto, Francis de Laporte de Castelnau (vectorized by
T. Michael Keesey), Scott Hartman, modified by T. Michael Keesey, Harold
N Eyster, Myriam\_Ramirez, Siobhon Egan, Chris A. Hamilton, Javier Luque
& Sarah Gerken, L. Shyamal, Gabriel Lio, vectorized by Zimices, Yan
Wong, Robert Bruce Horsfall, vectorized by Zimices, Joseph Wolf, 1863
(vectorization by Dinah Challen), Jiekun He, T. Michael Keesey (after
Marek Velechovský), Ernst Haeckel (vectorized by T. Michael Keesey), Tim
H. Heupink, Leon Huynen, and David M. Lambert (vectorized by T. Michael
Keesey), Noah Schlottman, photo by Reinhard Jahn, Acrocynus (vectorized
by T. Michael Keesey), Martin R. Smith, Mattia Menchetti / Yan Wong, Jan
A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow
(vectorized by T. Michael Keesey), Mali’o Kodis, image by Rebecca
Ritger, Dexter R. Mardis, Tony Ayling, Skye McDavid, Tom Tarrant
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Felix Vaux and Steven A. Trewick, Ghedoghedo, vectorized by
Zimices, Jon M Laurent, Isaure Scavezzoni, Emily Jane McTavish, from
<http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>,
Erika Schumacher, Madeleine Price Ball, James I. Kirkland, Luis Alcalá,
Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma
(vectorized by T. Michael Keesey), T. Michael Keesey (from a mount by
Allis Markham), Mathew Stewart, Audrey Ely, Archaeodontosaurus
(vectorized by T. Michael Keesey), Andrew A. Farke, modified from
original by H. Milne Edwards, Juan Carlos Jerí, Enoch Joseph Wetsy
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela
Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough
(vectorized by T. Michael Keesey), Mo Hassan, Catherine Yasuda, Warren H
(photography), T. Michael Keesey (vectorization), David Tana, Trond R.
Oskars, Maxwell Lefroy (vectorized by T. Michael Keesey), George Edward
Lodge (vectorized by T. Michael Keesey), Dennis C. Murphy, after
<https://commons.wikimedia.org/wiki/File:Queensland_State_Archives_2981_Cane_toads_at_the_Meringa_Sugar_Experiment_Station_North_Queensland_c_1935.png>,
Mykle Hoban, T. Michael Keesey (after James & al.), Anthony Caravaggi,
Meyers Konversations-Lexikon 1897 (vectorized: Yan Wong), Rachel Shoop,
Don Armstrong, Jake Warner, Ghedoghedo, T. Michael Keesey (vector) and
Stuart Halliday (photograph), Caleb M. Brown, John Conway, E. R. Waite &
H. M. Hale (vectorized by T. Michael Keesey), Noah Schlottman, Caleb M.
Gordon, Kenneth Lacovara (vectorized by T. Michael Keesey), Aadx, Duane
Raver (vectorized by T. Michael Keesey), Hans Hillewaert (photo) and T.
Michael Keesey (vectorization), Doug Backlund (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Apokryltaros
(vectorized by T. Michael Keesey), Dave Souza (vectorized by T. Michael
Keesey), Stuart Humphries, Todd Marshall, vectorized by Zimices, Sean
McCann, Mali’o Kodis, photograph by Cordell Expeditions at Cal Academy,
Ingo Braasch, Paul Baker (photo), John E. McCormack, Michael G. Harvey,
Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T.
Brumfield & T. Michael Keesey, Original drawing by Nobu Tamura,
vectorized by Roberto Díaz Sibaja, Lauren Anderson, Smokeybjb (modified
by T. Michael Keesey), Margret Flinsch, vectorized by Zimices, Chris
Hay, T. Michael Keesey (vectorization); Thorsten Assmann, Jörn Buse,
Claudia Drees, Ariel-Leib-Leonid Friedman, Tal Levanony, Andrea Matern,
Anika Timm, and David W. Wrase (photography), Yan Wong from drawing by
Joseph Smit, Robert Bruce Horsfall, from W.B. Scott’s 1912 “A History of
Land Mammals in the Western Hemisphere”, Nobu Tamura (vectorized by A.
Verrière), Ludwik Gąsiorowski, Hans Hillewaert (vectorized by T. Michael
Keesey), Matt Wilkins (photo by Patrick Kavanagh), Martin Kevil, Andreas
Hejnol, Zsoldos Márton (vectorized by T. Michael Keesey), Mali’o Kodis,
photograph by Melissa Frey, Lily Hughes, Matt Wilkins, Dave Angelini,
Mattia Menchetti, Mali’o Kodis, image from Brockhaus and Efron
Encyclopedic Dictionary, White Wolf, Maxime Dahirel, Marie-Aimée Allard,
Joris van der Ham (vectorized by T. Michael Keesey), Diana Pomeroy, Jay
Matternes, vectorized by Zimices, NASA, Kailah Thorn & Ben King, Lisa
Byrne, James Neenan, Young and Zhao (1972:figure 4), modified by Michael
P. Taylor, Robert Gay, modifed from Olegivvit, Mali’o Kodis, photograph
by G. Giribet, Benjamint444, Mathilde Cordellier, Pearson Scott Foresman
(vectorized by T. Michael Keesey), Elizabeth Parker, Matus Valach,
Terpsichores

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                               |
| --: | ------------: | ------------: | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    395.509179 |    361.733473 | T. Michael Keesey                                                                                                                                                                    |
|   2 |    550.100001 |    352.030741 | Steven Haddock • Jellywatch.org                                                                                                                                                      |
|   3 |    801.637407 |    470.559803 | Ferran Sayol                                                                                                                                                                         |
|   4 |    457.893247 |    676.518433 | Zimices                                                                                                                                                                              |
|   5 |    458.104593 |    486.279591 | Michelle Site                                                                                                                                                                        |
|   6 |    490.198119 |     72.330776 | Ferran Sayol                                                                                                                                                                         |
|   7 |    789.911536 |    729.464215 | Lukasiniho                                                                                                                                                                           |
|   8 |    172.381081 |    204.718656 | Gabriela Palomo-Munoz                                                                                                                                                                |
|   9 |    319.924370 |    437.844294 | Matt Crook                                                                                                                                                                           |
|  10 |    641.481822 |    769.051682 | Oscar Sanisidro                                                                                                                                                                      |
|  11 |    260.261224 |    582.966211 | Gabriela Palomo-Munoz                                                                                                                                                                |
|  12 |    355.258430 |    241.053398 | Margot Michaud                                                                                                                                                                       |
|  13 |    835.415568 |    598.911998 | \[unknown\]                                                                                                                                                                          |
|  14 |    183.647528 |    456.016798 | Gareth Monger                                                                                                                                                                        |
|  15 |    215.344156 |    335.790226 | Milton Tan                                                                                                                                                                           |
|  16 |    859.536409 |    264.974032 | Gabriela Palomo-Munoz                                                                                                                                                                |
|  17 |     85.077675 |    504.145872 | John Curtis (vectorized by T. Michael Keesey)                                                                                                                                        |
|  18 |    350.267227 |    583.257372 | Matt Crook                                                                                                                                                                           |
|  19 |    727.486368 |    141.929785 | Margot Michaud                                                                                                                                                                       |
|  20 |    431.917334 |    726.319925 | Ignacio Contreras                                                                                                                                                                    |
|  21 |    913.978275 |    703.835568 | Pranav Iyer (grey ideas)                                                                                                                                                             |
|  22 |    529.513956 |    165.520179 | Margot Michaud                                                                                                                                                                       |
|  23 |    515.894775 |    768.756082 | Kamil S. Jaron                                                                                                                                                                       |
|  24 |    572.588197 |    560.404909 | Chris huh                                                                                                                                                                            |
|  25 |    151.444741 |    686.233049 | T. Michael Keesey                                                                                                                                                                    |
|  26 |    481.336263 |    286.553896 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                                        |
|  27 |    996.861530 |    308.818246 | Michele M Tobias                                                                                                                                                                     |
|  28 |    735.459048 |    639.967312 | Margot Michaud                                                                                                                                                                       |
|  29 |    813.070544 |    358.461472 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
|  30 |    759.793195 |    251.362103 | Matt Crook                                                                                                                                                                           |
|  31 |    927.226388 |    142.509028 | Lukasiniho                                                                                                                                                                           |
|  32 |    567.069225 |    222.041235 | Zimices                                                                                                                                                                              |
|  33 |     74.163517 |    282.714857 | Dean Schnabel                                                                                                                                                                        |
|  34 |    954.299651 |    603.244368 | Sarefo (vectorized by T. Michael Keesey)                                                                                                                                             |
|  35 |    318.280417 |    137.252583 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                                                       |
|  36 |    677.097709 |    553.549610 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                                      |
|  37 |    627.714609 |    287.404136 | www.studiospectre.com                                                                                                                                                                |
|  38 |    234.342408 |     65.740887 | Matt Crook                                                                                                                                                                           |
|  39 |    932.623906 |    385.329477 | Steven Traver                                                                                                                                                                        |
|  40 |    559.312444 |    625.809133 | Steven Traver                                                                                                                                                                        |
|  41 |    305.760401 |    769.885827 | Markus A. Grohme                                                                                                                                                                     |
|  42 |    118.884991 |    396.440241 | Ferran Sayol                                                                                                                                                                         |
|  43 |    305.077599 |    718.212735 | Zimices                                                                                                                                                                              |
|  44 |    658.385173 |    440.643695 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                                         |
|  45 |    399.350956 |     84.017639 | Tasman Dixon                                                                                                                                                                         |
|  46 |    895.589932 |    192.910444 | Rafael Maia                                                                                                                                                                          |
|  47 |    636.375795 |    689.084707 | C. Camilo Julián-Caballero                                                                                                                                                           |
|  48 |    725.912862 |    382.745736 | Margot Michaud                                                                                                                                                                       |
|  49 |    661.878508 |     52.497132 | Chris huh                                                                                                                                                                            |
|  50 |     67.194534 |    197.519638 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                                          |
|  51 |    107.283214 |    132.579246 | FunkMonk                                                                                                                                                                             |
|  52 |    550.982165 |    720.553267 | Michael P. Taylor                                                                                                                                                                    |
|  53 |    931.588096 |     50.152218 | Tracy A. Heath                                                                                                                                                                       |
|  54 |    597.608939 |    471.748419 | Mark Hofstetter (vectorized by T. Michael Keesey)                                                                                                                                    |
|  55 |     67.652440 |    767.247950 | Zimices                                                                                                                                                                              |
|  56 |    495.468358 |    143.400542 | Sarah Alewijnse                                                                                                                                                                      |
|  57 |    957.946484 |    510.672145 | Martin R. Smith, from photo by Jürgen Schoner                                                                                                                                        |
|  58 |    203.368819 |    287.949586 | Scott Hartman                                                                                                                                                                        |
|  59 |    208.690493 |    402.867944 | Shyamal                                                                                                                                                                              |
|  60 |     75.193320 |     26.639459 | Rene Martin                                                                                                                                                                          |
|  61 |    917.823918 |    775.736627 | Zimices                                                                                                                                                                              |
|  62 |    799.459626 |     26.445578 | Mathew Wedel                                                                                                                                                                         |
|  63 |    402.996866 |     33.099220 | Chris huh                                                                                                                                                                            |
|  64 |    122.677504 |     63.461514 | Lafage                                                                                                                                                                               |
|  65 |    595.990030 |     89.299270 | Markus A. Grohme                                                                                                                                                                     |
|  66 |    427.301270 |    615.173949 | Matt Crook                                                                                                                                                                           |
|  67 |     69.240809 |    592.265298 | Stephen O’Connor (vectorized by T. Michael Keesey)                                                                                                                                   |
|  68 |    364.049986 |    311.878414 | Emily Willoughby                                                                                                                                                                     |
|  69 |    625.889232 |    324.111220 | Henry Lydecker                                                                                                                                                                       |
|  70 |    265.065851 |    369.164853 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
|  71 |    799.926588 |    771.853237 | Chris huh                                                                                                                                                                            |
|  72 |    277.641427 |    197.160799 | Dmitry Bogdanov                                                                                                                                                                      |
|  73 |    191.012174 |     19.213598 | Smokeybjb                                                                                                                                                                            |
|  74 |    918.283642 |     90.839376 | Birgit Lang                                                                                                                                                                          |
|  75 |    943.582349 |    439.969802 | Javiera Constanzo                                                                                                                                                                    |
|  76 |    842.303563 |    657.795426 | NA                                                                                                                                                                                   |
|  77 |    908.454447 |    332.887938 | Markus A. Grohme                                                                                                                                                                     |
|  78 |    348.639722 |    643.703581 | Michael Scroggie                                                                                                                                                                     |
|  79 |    363.260976 |    512.715531 | Andreas Trepte (vectorized by T. Michael Keesey)                                                                                                                                     |
|  80 |     61.484766 |    671.939490 | Matt Crook                                                                                                                                                                           |
|  81 |    916.061785 |    267.084805 | Beth Reinke                                                                                                                                                                          |
|  82 |    331.504852 |    739.305274 | Mali’o Kodis, photograph from <http://commons.wikimedia.org/wiki/File:Trichoplax.jpg>                                                                                                |
|  83 |    542.238719 |    475.053914 | Jaime Headden                                                                                                                                                                        |
|  84 |    180.092624 |    155.121611 | Chris huh                                                                                                                                                                            |
|  85 |    506.038607 |    352.943167 | Lukasiniho                                                                                                                                                                           |
|  86 |    825.508808 |     73.690067 | Scott Reid                                                                                                                                                                           |
|  87 |    991.872127 |    103.181812 | NA                                                                                                                                                                                   |
|  88 |    211.847266 |    608.998314 | DW Bapst, modified from Figure 1 of Belanger (2011, PALAIOS).                                                                                                                        |
|  89 |    667.702980 |     12.656908 | NA                                                                                                                                                                                   |
|  90 |    670.713736 |    240.604176 | Birgit Lang                                                                                                                                                                          |
|  91 |    860.501863 |    383.734245 | Steven Traver                                                                                                                                                                        |
|  92 |    961.769282 |    217.889027 | Carlos Cano-Barbacil                                                                                                                                                                 |
|  93 |    833.573539 |     50.928143 | Gareth Monger                                                                                                                                                                        |
|  94 |    139.239335 |    333.405677 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
|  95 |    526.604106 |    443.770290 | Rafael Maia                                                                                                                                                                          |
|  96 |    772.339219 |    546.494328 | Crystal Maier                                                                                                                                                                        |
|  97 |    756.432971 |    687.736616 | Steven Traver                                                                                                                                                                        |
|  98 |    330.721682 |     18.684684 | Kanchi Nanjo                                                                                                                                                                         |
|  99 |    607.892249 |    373.738559 | Jagged Fang Designs                                                                                                                                                                  |
| 100 |     51.987807 |    205.997152 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                                          |
| 101 |    722.674347 |    303.644214 | Ferran Sayol                                                                                                                                                                         |
| 102 |    554.137620 |    684.375615 | Zimices                                                                                                                                                                              |
| 103 |    714.803573 |    218.219106 | Birgit Lang                                                                                                                                                                          |
| 104 |    803.534945 |    152.382766 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 105 |    529.661249 |    114.260419 | Margot Michaud                                                                                                                                                                       |
| 106 |     30.777615 |    544.506355 | CNZdenek                                                                                                                                                                             |
| 107 |    273.874696 |     89.046121 | Noah Schlottman, photo by Carol Cummings                                                                                                                                             |
| 108 |    106.867620 |    174.351884 | Margot Michaud                                                                                                                                                                       |
| 109 |    134.702260 |    763.886325 | Fernando Carezzano                                                                                                                                                                   |
| 110 |     40.647244 |    337.301830 | Scott Hartman                                                                                                                                                                        |
| 111 |     12.048251 |    416.251438 | NA                                                                                                                                                                                   |
| 112 |    381.953306 |    687.514088 | Margot Michaud                                                                                                                                                                       |
| 113 |    950.733836 |    720.126757 | Alexandre Vong                                                                                                                                                                       |
| 114 |    786.112841 |    603.933149 | Jagged Fang Designs                                                                                                                                                                  |
| 115 |     42.527642 |    395.067869 | Lani Mohan                                                                                                                                                                           |
| 116 |    653.617462 |    585.058878 | Zimices                                                                                                                                                                              |
| 117 |    292.329498 |    348.458546 | Xavier Giroux-Bougard                                                                                                                                                                |
| 118 |    527.741792 |    679.142316 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 119 |    395.388375 |    184.302822 | Ghedo (vectorized by T. Michael Keesey)                                                                                                                                              |
| 120 |    162.120080 |    354.673662 | Maija Karala                                                                                                                                                                         |
| 121 |    712.673104 |    749.043708 | Ferran Sayol                                                                                                                                                                         |
| 122 |    625.485802 |    544.964949 | Renato de Carvalho Ferreira                                                                                                                                                          |
| 123 |    590.344150 |     30.666481 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 124 |    625.302283 |    351.377250 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                                          |
| 125 |    606.103358 |    163.043144 | Steven Traver                                                                                                                                                                        |
| 126 |    582.183993 |    393.870009 | Matt Martyniuk                                                                                                                                                                       |
| 127 |    676.640181 |    338.106214 | Qiang Ou                                                                                                                                                                             |
| 128 |    228.115015 |    225.214980 | Gareth Monger                                                                                                                                                                        |
| 129 |    975.688217 |    210.232149 | C. W. Nash (illustration) and Timothy J. Bartley (silhouette)                                                                                                                        |
| 130 |    817.349688 |    200.179978 | Steven Traver                                                                                                                                                                        |
| 131 |    815.360215 |    161.979125 | Margot Michaud                                                                                                                                                                       |
| 132 |    913.258492 |    414.828428 | Sarah Werning                                                                                                                                                                        |
| 133 |    297.291789 |     59.718784 | Steven Traver                                                                                                                                                                        |
| 134 |    461.013361 |    347.764104 | NA                                                                                                                                                                                   |
| 135 |    959.834728 |    350.802223 | Dr. Thomas G. Barnes, USFWS                                                                                                                                                          |
| 136 |    240.475285 |    175.343567 | Emily Willoughby                                                                                                                                                                     |
| 137 |    892.238170 |    619.184894 | NA                                                                                                                                                                                   |
| 138 |    448.311880 |    779.305977 | Peter Coxhead                                                                                                                                                                        |
| 139 |     15.018228 |    147.584927 | James R. Spotila and Ray Chatterji                                                                                                                                                   |
| 140 |    990.656060 |     15.047031 | Steven Traver                                                                                                                                                                        |
| 141 |    990.778533 |    499.600160 | Michelle Site                                                                                                                                                                        |
| 142 |    210.515478 |    760.606057 | Manabu Bessho-Uehara                                                                                                                                                                 |
| 143 |    485.152939 |    321.298956 | Andy Wilson                                                                                                                                                                          |
| 144 |    109.967648 |    190.829967 | Ferran Sayol                                                                                                                                                                         |
| 145 |    101.902409 |    338.172753 | Christoph Schomburg                                                                                                                                                                  |
| 146 |    277.203917 |    260.595317 | Pete Buchholz                                                                                                                                                                        |
| 147 |    341.736964 |    523.250188 | Javier Luque                                                                                                                                                                         |
| 148 |    816.507065 |     29.393347 | Cesar Julian                                                                                                                                                                         |
| 149 |    133.825677 |    381.560335 | NA                                                                                                                                                                                   |
| 150 |    719.705468 |    171.064534 | Zimices                                                                                                                                                                              |
| 151 |    367.106394 |    480.899190 | Margot Michaud                                                                                                                                                                       |
| 152 |    208.313636 |    714.734030 | Sarah Werning                                                                                                                                                                        |
| 153 |    381.759896 |    275.645764 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 154 |    471.909729 |    407.251491 | M Kolmann                                                                                                                                                                            |
| 155 |    891.969499 |    561.964613 | NA                                                                                                                                                                                   |
| 156 |    781.769200 |     55.632185 | Manabu Sakamoto                                                                                                                                                                      |
| 157 |     18.775036 |    596.448873 | Collin Gross                                                                                                                                                                         |
| 158 |     20.520321 |    237.457575 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                                     |
| 159 |    375.116010 |    176.898781 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 160 |   1005.203683 |    752.552068 | Andy Wilson                                                                                                                                                                          |
| 161 |     58.557597 |    459.321680 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 162 |    194.552599 |    369.927194 | Chase Brownstein                                                                                                                                                                     |
| 163 |     27.618058 |    469.706272 | Karkemish (vectorized by T. Michael Keesey)                                                                                                                                          |
| 164 |     70.923132 |    570.784749 | Natalie Claunch                                                                                                                                                                      |
| 165 |    582.667531 |    270.898931 | Ferran Sayol                                                                                                                                                                         |
| 166 |    193.671119 |    387.107699 | Zimices                                                                                                                                                                              |
| 167 |    240.146110 |    267.974045 | Margot Michaud                                                                                                                                                                       |
| 168 |    946.374333 |    240.782787 | Zimices                                                                                                                                                                              |
| 169 |    448.520700 |    226.171363 | Jon Hill (Photo by DickDaniels: <http://en.wikipedia.org/wiki/File:Green_Woodhoopoe_RWD7.jpg>)                                                                                       |
| 170 |     32.317103 |    559.960908 | Steven Traver                                                                                                                                                                        |
| 171 |    876.910426 |    413.638417 | Matt Crook                                                                                                                                                                           |
| 172 |    224.546239 |    701.078413 | Michele M Tobias                                                                                                                                                                     |
| 173 |    829.783271 |    139.995575 | Ferran Sayol                                                                                                                                                                         |
| 174 |     12.449243 |    561.474984 | Jagged Fang Designs                                                                                                                                                                  |
| 175 |    683.126988 |    191.793772 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 176 |    287.491990 |    106.114822 | Matthew E. Clapham                                                                                                                                                                   |
| 177 |    866.919891 |     42.896063 | Margot Michaud                                                                                                                                                                       |
| 178 |    721.953618 |    783.135835 | Sherman F. Denton via rawpixel.com (illustration) and Timothy J. Bartley (silhouette)                                                                                                |
| 179 |    977.328977 |    762.904167 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                                               |
| 180 |    350.478403 |    581.791645 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                              |
| 181 |    756.585437 |    572.811449 | Gareth Monger                                                                                                                                                                        |
| 182 |    328.263505 |    357.760183 | Jagged Fang Designs                                                                                                                                                                  |
| 183 |    326.806962 |     44.498284 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 184 |     15.128003 |    686.101038 | Andrew A. Farke                                                                                                                                                                      |
| 185 |     88.910061 |    452.700852 | Collin Gross                                                                                                                                                                         |
| 186 |    423.769024 |    148.024580 | Richard Lampitt, Jeremy Young / NHM (vectorization by Yan Wong)                                                                                                                      |
| 187 |    740.311126 |    748.869827 | Rebecca Groom                                                                                                                                                                        |
| 188 |    177.710192 |    229.812906 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 189 |    127.943428 |    350.298805 | Matt Crook                                                                                                                                                                           |
| 190 |    532.166274 |    508.120395 | Mr E? (vectorized by T. Michael Keesey)                                                                                                                                              |
| 191 |    593.314523 |    128.007823 | Jaime Headden                                                                                                                                                                        |
| 192 |    348.086905 |    614.281159 | Matt Crook                                                                                                                                                                           |
| 193 |    463.603181 |     98.872675 | Birgit Lang                                                                                                                                                                          |
| 194 |    220.758642 |     32.075066 | Jack Mayer Wood                                                                                                                                                                      |
| 195 |    172.018829 |    467.935657 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 196 |    332.230563 |     59.733201 | Scott Hartman (vectorized by T. Michael Keesey)                                                                                                                                      |
| 197 |    713.926698 |    527.461924 | Jaime A. Headden (vectorized by T. Michael Keesey)                                                                                                                                   |
| 198 |    169.471501 |    241.202659 | Lukasiniho                                                                                                                                                                           |
| 199 |    263.671806 |    224.944548 | Ferran Sayol                                                                                                                                                                         |
| 200 |    799.249361 |    703.435797 | NA                                                                                                                                                                                   |
| 201 |    687.745259 |    722.431000 | Julio Garza                                                                                                                                                                          |
| 202 |     92.049476 |    673.106385 | Robert Gay                                                                                                                                                                           |
| 203 |    988.755087 |    337.513705 | Keith Murdock (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                        |
| 204 |    622.359926 |    391.551180 | Jagged Fang Designs                                                                                                                                                                  |
| 205 |    584.473170 |    720.070040 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 206 |    811.482695 |    400.954005 | Scott Hartman                                                                                                                                                                        |
| 207 |    862.491231 |    547.327558 | Margot Michaud                                                                                                                                                                       |
| 208 |     80.823234 |    627.782593 | Alex Slavenko                                                                                                                                                                        |
| 209 |    402.557667 |    252.229636 | Gareth Monger                                                                                                                                                                        |
| 210 |    414.725320 |    109.783573 | Scott Hartman                                                                                                                                                                        |
| 211 |      7.573090 |    124.200163 | Nina Skinner                                                                                                                                                                         |
| 212 |    373.280329 |    148.674417 | Jagged Fang Designs                                                                                                                                                                  |
| 213 |    647.743876 |     97.815116 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                                   |
| 214 |    180.398431 |    358.470606 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 215 |    239.073201 |    191.121694 | Gareth Monger                                                                                                                                                                        |
| 216 |     54.094589 |    720.610827 | Matt Crook                                                                                                                                                                           |
| 217 |    717.050228 |    708.139713 | Rebecca Groom                                                                                                                                                                        |
| 218 |    779.191783 |    687.307948 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 219 |    164.339406 |    448.508967 | Tyler Greenfield                                                                                                                                                                     |
| 220 |    221.136374 |    249.908331 | xgirouxb                                                                                                                                                                             |
| 221 |    806.368689 |    169.510795 | T. Michael Keesey                                                                                                                                                                    |
| 222 |    600.673545 |    258.220032 | Matt Crook                                                                                                                                                                           |
| 223 |    734.777104 |    186.252650 | Chris huh                                                                                                                                                                            |
| 224 |    425.880069 |    236.402231 | Tauana J. Cunha                                                                                                                                                                      |
| 225 |     20.037544 |     19.629713 | Chris huh                                                                                                                                                                            |
| 226 |    252.809794 |    116.800120 | Matt Crook                                                                                                                                                                           |
| 227 |    318.884874 |     76.373639 | NA                                                                                                                                                                                   |
| 228 |    486.743435 |    752.227704 | Markus A. Grohme                                                                                                                                                                     |
| 229 |    170.093227 |    562.747201 | Chloé Schmidt                                                                                                                                                                        |
| 230 |    547.896996 |    131.218338 | Steven Traver                                                                                                                                                                        |
| 231 |   1007.812713 |    711.967931 | Tauana J. Cunha                                                                                                                                                                      |
| 232 |    706.754747 |    485.097197 | T. Michael Keesey                                                                                                                                                                    |
| 233 |    383.059603 |    514.287379 | Cathy                                                                                                                                                                                |
| 234 |    882.730164 |    676.452673 | T. Michael Keesey                                                                                                                                                                    |
| 235 |     40.310886 |    445.707662 | Francesco “Architetto” Rollandin                                                                                                                                                     |
| 236 |    951.663425 |    178.819497 | Kai R. Caspar                                                                                                                                                                        |
| 237 |    789.807538 |    520.419435 | Gareth Monger                                                                                                                                                                        |
| 238 |    339.681536 |    282.056916 | Tasman Dixon                                                                                                                                                                         |
| 239 |    622.508915 |    603.261360 | Matt Crook                                                                                                                                                                           |
| 240 |    156.509345 |     40.711866 | Chloé Schmidt                                                                                                                                                                        |
| 241 |     70.296438 |    430.403858 | Falconaumanni and T. Michael Keesey                                                                                                                                                  |
| 242 |    713.370038 |    694.318057 | David Orr                                                                                                                                                                            |
| 243 |    225.364054 |    783.717610 | Ferran Sayol                                                                                                                                                                         |
| 244 |    641.784466 |    639.577652 | S.Martini                                                                                                                                                                            |
| 245 |    358.478381 |    729.400715 | NA                                                                                                                                                                                   |
| 246 |    882.023060 |    523.164608 | Sharon Wegner-Larsen                                                                                                                                                                 |
| 247 |    160.324508 |    790.924463 | David Orr                                                                                                                                                                            |
| 248 |     98.440724 |    711.343786 | NA                                                                                                                                                                                   |
| 249 |    333.277674 |    493.328908 | Inessa Voet                                                                                                                                                                          |
| 250 |    525.173139 |    311.082833 | Matt Crook                                                                                                                                                                           |
| 251 |    572.143920 |    702.283229 | Scott Hartman                                                                                                                                                                        |
| 252 |     16.681649 |    350.818472 | Matt Crook                                                                                                                                                                           |
| 253 |    704.997394 |    359.910742 | NA                                                                                                                                                                                   |
| 254 |    225.163530 |    130.595609 | NA                                                                                                                                                                                   |
| 255 |    999.869114 |    456.054375 | NA                                                                                                                                                                                   |
| 256 |    124.883839 |    108.969759 | Margot Michaud                                                                                                                                                                       |
| 257 |    156.939814 |    516.276169 | xgirouxb                                                                                                                                                                             |
| 258 |    717.884999 |    582.131615 | Felix Vaux                                                                                                                                                                           |
| 259 |    491.940198 |    628.467875 | FunkMonk                                                                                                                                                                             |
| 260 |    716.363688 |    719.342765 | Markus A. Grohme                                                                                                                                                                     |
| 261 |    565.992422 |    159.522000 | Servien (vectorized by T. Michael Keesey)                                                                                                                                            |
| 262 |    736.088352 |    200.239148 | Gareth Monger                                                                                                                                                                        |
| 263 |    551.302537 |    425.603653 | Markus A. Grohme                                                                                                                                                                     |
| 264 |    850.360386 |    787.732006 | Scott Hartman                                                                                                                                                                        |
| 265 |    266.147384 |    740.239550 | Riccardo Percudani                                                                                                                                                                   |
| 266 |    909.376009 |    639.674900 | Matt Crook                                                                                                                                                                           |
| 267 |    799.469404 |    220.582022 | Matt Crook                                                                                                                                                                           |
| 268 |    252.148439 |    253.212069 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 269 |    224.275899 |    239.100704 | Felix Vaux                                                                                                                                                                           |
| 270 |    689.109658 |    456.317444 | Joanna Wolfe                                                                                                                                                                         |
| 271 |    981.111146 |    746.857668 | Verdilak                                                                                                                                                                             |
| 272 |   1004.040317 |    558.574225 | Dinah Challen                                                                                                                                                                        |
| 273 |    968.914030 |    476.788605 | Mathieu Pélissié                                                                                                                                                                     |
| 274 |    652.435361 |    517.014564 | Steven Traver                                                                                                                                                                        |
| 275 |    399.933126 |    595.997253 | Ferran Sayol                                                                                                                                                                         |
| 276 |    707.753414 |    492.349091 | Darius Nau                                                                                                                                                                           |
| 277 |    811.590385 |    684.114394 | NA                                                                                                                                                                                   |
| 278 |    733.948929 |    556.891982 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                              |
| 279 |    971.658558 |    728.703945 | Ignacio Contreras                                                                                                                                                                    |
| 280 |    117.906106 |    357.397337 | Kailah Thorn & Mark Hutchinson                                                                                                                                                       |
| 281 |    316.538471 |    198.731343 | Steven Traver                                                                                                                                                                        |
| 282 |    765.482439 |    370.545091 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 283 |    366.288472 |    166.134260 | Zimices                                                                                                                                                                              |
| 284 |     39.790148 |     41.726344 | Jose Carlos Arenas-Monroy                                                                                                                                                            |
| 285 |    747.980867 |     66.875862 | Craig Dylke                                                                                                                                                                          |
| 286 |    788.382206 |    288.784460 | LeonardoG (photography) and T. Michael Keesey (vectorization)                                                                                                                        |
| 287 |    902.597839 |    309.261624 | Matt Martyniuk                                                                                                                                                                       |
| 288 |    487.372291 |    392.696607 | Katie S. Collins                                                                                                                                                                     |
| 289 |     24.135020 |    675.675811 | Margot Michaud                                                                                                                                                                       |
| 290 |     41.040272 |    138.777167 | Matt Crook                                                                                                                                                                           |
| 291 |    624.516625 |    415.794187 | Margot Michaud                                                                                                                                                                       |
| 292 |    489.286722 |    588.697450 | Tracy A. Heath                                                                                                                                                                       |
| 293 |     28.629755 |    773.168371 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 294 |    762.829052 |    606.652067 | T. Michael Keesey (after Mivart)                                                                                                                                                     |
| 295 |    644.538528 |    651.930174 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 296 |    449.506076 |    630.927555 | Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus                                                             |
| 297 |    768.182371 |    563.595409 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                                                       |
| 298 |    738.750623 |    315.054885 | Gareth Monger                                                                                                                                                                        |
| 299 |    420.010384 |    792.435433 | Jagged Fang Designs                                                                                                                                                                  |
| 300 |   1008.070623 |     33.390266 | T. Michael Keesey                                                                                                                                                                    |
| 301 |    374.320070 |    750.884550 | Kai R. Caspar                                                                                                                                                                        |
| 302 |    570.879300 |    123.983858 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 303 |    126.121664 |    548.468697 | Chris huh                                                                                                                                                                            |
| 304 |    812.338239 |    520.891110 | NA                                                                                                                                                                                   |
| 305 |    376.858427 |    764.364572 | NA                                                                                                                                                                                   |
| 306 |    780.375284 |    316.910540 | NA                                                                                                                                                                                   |
| 307 |    423.657984 |    582.025941 | Katie S. Collins                                                                                                                                                                     |
| 308 |    692.837627 |    429.269480 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 309 |   1006.538846 |    162.287012 | Matt Crook                                                                                                                                                                           |
| 310 |     95.619106 |    599.121583 | Zimices                                                                                                                                                                              |
| 311 |    258.535426 |    792.648364 | SauropodomorphMonarch                                                                                                                                                                |
| 312 |    635.610325 |    198.031765 | Tasman Dixon                                                                                                                                                                         |
| 313 |    793.564789 |    206.947235 | Markus A. Grohme                                                                                                                                                                     |
| 314 |    946.770768 |    308.252473 | Maija Karala                                                                                                                                                                         |
| 315 |     15.495595 |    455.391959 | Kai R. Caspar                                                                                                                                                                        |
| 316 |    442.090271 |    119.397129 | T. Michael Keesey (vectorization) and Nadiatalent (photography)                                                                                                                      |
| 317 |    176.001054 |    421.356101 | Margot Michaud                                                                                                                                                                       |
| 318 |    904.598878 |    677.347759 | Matt Crook                                                                                                                                                                           |
| 319 |     24.536975 |     93.911604 | Jim Bendon (photography) and T. Michael Keesey (vectorization)                                                                                                                       |
| 320 |    174.308955 |    573.847254 | Matt Crook                                                                                                                                                                           |
| 321 |    856.032037 |    497.902707 | Pedro de Siracusa                                                                                                                                                                    |
| 322 |    993.556519 |    602.092208 | Matt Dempsey                                                                                                                                                                         |
| 323 |     25.706991 |      5.764689 | John Gould (vectorized by T. Michael Keesey)                                                                                                                                         |
| 324 |    570.895772 |    309.833887 | Katie S. Collins                                                                                                                                                                     |
| 325 |    883.086240 |    575.042044 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 326 |     41.658285 |      6.019345 | NA                                                                                                                                                                                   |
| 327 |    642.762049 |    489.681409 | Leann Biancani, photo by Kenneth Clifton                                                                                                                                             |
| 328 |    225.573181 |    294.419746 | Zimices                                                                                                                                                                              |
| 329 |     33.354529 |    511.503295 | Steven Haddock • Jellywatch.org                                                                                                                                                      |
| 330 |    835.780239 |    195.808366 | Melissa Broussard                                                                                                                                                                    |
| 331 |    283.656340 |    328.736329 | Tracy A. Heath                                                                                                                                                                       |
| 332 |    931.643611 |    449.405416 | Scott Hartman                                                                                                                                                                        |
| 333 |    207.333750 |    141.420887 | NA                                                                                                                                                                                   |
| 334 |    939.716059 |    458.820164 | T. Michael Keesey                                                                                                                                                                    |
| 335 |    995.837661 |    657.640121 | Andrew A. Farke                                                                                                                                                                      |
| 336 |    970.968016 |    666.809281 | Fir0002/Flagstaffotos (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                |
| 337 |    584.326726 |    465.271695 | Matt Crook                                                                                                                                                                           |
| 338 |   1016.478528 |     70.990600 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 339 |    565.925042 |    488.338926 | Cagri Cevrim                                                                                                                                                                         |
| 340 |    989.813497 |    587.425196 | Liftarn                                                                                                                                                                              |
| 341 |    593.271718 |    736.018676 | Andy Wilson                                                                                                                                                                          |
| 342 |    468.069938 |    552.065243 | Scott Hartman                                                                                                                                                                        |
| 343 |    310.053284 |    749.506187 | Ville Koistinen and T. Michael Keesey                                                                                                                                                |
| 344 |    571.416579 |     34.914037 | Katie S. Collins                                                                                                                                                                     |
| 345 |    947.502244 |    476.662313 | NA                                                                                                                                                                                   |
| 346 |    453.065793 |     82.259268 | Zimices                                                                                                                                                                              |
| 347 |    340.682249 |    359.951778 | Matt Crook                                                                                                                                                                           |
| 348 |    982.873296 |    666.220119 | Iain Reid                                                                                                                                                                            |
| 349 |     90.465367 |     97.982082 | Roule Jammes (vectorized by T. Michael Keesey)                                                                                                                                       |
| 350 |    225.996990 |    682.649357 | Ignacio Contreras                                                                                                                                                                    |
| 351 |    316.014820 |    788.662424 | Tasman Dixon                                                                                                                                                                         |
| 352 |    613.712985 |    622.448181 | Alan Manson (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                          |
| 353 |     13.879025 |    314.904618 | Tasman Dixon                                                                                                                                                                         |
| 354 |    985.363675 |    713.428692 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 355 |    203.358893 |    725.932399 | Chloé Schmidt                                                                                                                                                                        |
| 356 |    696.114398 |    293.372617 | Margot Michaud                                                                                                                                                                       |
| 357 |    310.526889 |     96.474584 | Michelle Site                                                                                                                                                                        |
| 358 |     83.365262 |    564.846214 | Noah Schlottman, photo by Gustav Paulay for Moorea Biocode                                                                                                                           |
| 359 |    734.614496 |     12.887016 | DW Bapst, modified from Figure 1 of Belanger (2011, PALAIOS).                                                                                                                        |
| 360 |    462.620353 |    778.197804 | Tracy A. Heath                                                                                                                                                                       |
| 361 |    186.620942 |    786.552037 | Andy Wilson                                                                                                                                                                          |
| 362 |    154.540758 |    101.333756 | Chris huh                                                                                                                                                                            |
| 363 |    534.959712 |    539.352975 | Jaime Headden                                                                                                                                                                        |
| 364 |     42.805765 |     70.009265 | Mali’o Kodis, photograph by Aqua-Photos (<http://www.flickr.com/people/undervannsfotografen/>)                                                                                       |
| 365 |    198.799272 |    146.351768 | Mathieu Pélissié                                                                                                                                                                     |
| 366 |    181.747618 |    496.124009 | NA                                                                                                                                                                                   |
| 367 |    631.549136 |    109.884728 | Margot Michaud                                                                                                                                                                       |
| 368 |    860.029148 |    132.901163 | Christoph Schomburg                                                                                                                                                                  |
| 369 |    673.753454 |     83.469349 | FunkMonk (Michael B. H.)                                                                                                                                                             |
| 370 |     38.130385 |    570.074050 | Scott Hartman                                                                                                                                                                        |
| 371 |    840.691926 |    325.047061 | Chuanixn Yu                                                                                                                                                                          |
| 372 |    451.636746 |    209.501051 | Steven Traver                                                                                                                                                                        |
| 373 |    390.528858 |    159.646221 | Birgit Lang                                                                                                                                                                          |
| 374 |    276.133992 |    318.250294 | Zimices                                                                                                                                                                              |
| 375 |    250.527214 |    159.281849 | Andy Wilson                                                                                                                                                                          |
| 376 |    243.780530 |    305.484872 | Scott Hartman                                                                                                                                                                        |
| 377 |    619.091820 |    478.132387 | Scott Hartman                                                                                                                                                                        |
| 378 |    320.037353 |    593.751417 | Scott Hartman                                                                                                                                                                        |
| 379 |    354.182246 |    705.358181 | NA                                                                                                                                                                                   |
| 380 |     55.632775 |     97.012171 | Matt Crook                                                                                                                                                                           |
| 381 |    978.983972 |    461.757014 | Ignacio Contreras                                                                                                                                                                    |
| 382 |    910.445822 |    490.579360 | Steven Traver                                                                                                                                                                        |
| 383 |    385.627746 |    638.382722 | Matt Crook                                                                                                                                                                           |
| 384 |     30.344996 |    130.616405 | Jessica Anne Miller                                                                                                                                                                  |
| 385 |    303.633308 |    187.206491 | Dmitry Bogdanov                                                                                                                                                                      |
| 386 |    771.673740 |     74.420804 | NA                                                                                                                                                                                   |
| 387 |    693.742095 |    587.726243 | Xavier A. Jenkins, Gabriel Ugueto                                                                                                                                                    |
| 388 |    608.820288 |     78.837889 | Jagged Fang Designs                                                                                                                                                                  |
| 389 |    564.360809 |    730.513612 | Francis de Laporte de Castelnau (vectorized by T. Michael Keesey)                                                                                                                    |
| 390 |    444.938837 |    788.876534 | Markus A. Grohme                                                                                                                                                                     |
| 391 |   1003.128073 |    628.555790 | Scott Hartman, modified by T. Michael Keesey                                                                                                                                         |
| 392 |    903.811338 |     97.781268 | Chris huh                                                                                                                                                                            |
| 393 |    123.507454 |    467.315938 | Margot Michaud                                                                                                                                                                       |
| 394 |    675.096109 |    173.629576 | Margot Michaud                                                                                                                                                                       |
| 395 |    419.415583 |    557.209695 | Gareth Monger                                                                                                                                                                        |
| 396 |    975.734365 |    359.915397 | Gareth Monger                                                                                                                                                                        |
| 397 |    965.131845 |    267.182627 | Harold N Eyster                                                                                                                                                                      |
| 398 |    406.334277 |    705.100096 | Andrew A. Farke                                                                                                                                                                      |
| 399 |    475.711482 |    622.306120 | Myriam\_Ramirez                                                                                                                                                                      |
| 400 |    664.114725 |    635.168711 | Zimices                                                                                                                                                                              |
| 401 |    775.637125 |     65.711202 | Steven Traver                                                                                                                                                                        |
| 402 |    167.034221 |    321.566390 | Scott Hartman                                                                                                                                                                        |
| 403 |    636.974352 |    578.380046 | Matt Crook                                                                                                                                                                           |
| 404 |    909.130221 |    573.601648 | Siobhon Egan                                                                                                                                                                         |
| 405 |    995.808149 |    421.616779 | Pete Buchholz                                                                                                                                                                        |
| 406 |    542.519564 |     68.351079 | Chris A. Hamilton                                                                                                                                                                    |
| 407 |    895.712090 |    502.321090 | Javier Luque & Sarah Gerken                                                                                                                                                          |
| 408 |   1003.907143 |    122.205519 | L. Shyamal                                                                                                                                                                           |
| 409 |   1013.669588 |    143.205098 | Margot Michaud                                                                                                                                                                       |
| 410 |    468.359900 |    421.906836 | Gabriel Lio, vectorized by Zimices                                                                                                                                                   |
| 411 |    138.473665 |    300.671636 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 412 |    906.900851 |     21.573227 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 413 |    420.181736 |     65.620869 | Margot Michaud                                                                                                                                                                       |
| 414 |    216.779523 |    736.395416 | Margot Michaud                                                                                                                                                                       |
| 415 |    385.642100 |    113.817543 | Markus A. Grohme                                                                                                                                                                     |
| 416 |    338.665234 |     85.897242 | Markus A. Grohme                                                                                                                                                                     |
| 417 |    913.987505 |    403.619980 | Zimices                                                                                                                                                                              |
| 418 |    202.628069 |     53.237517 | Birgit Lang                                                                                                                                                                          |
| 419 |    416.561491 |    186.066508 | Sarah Werning                                                                                                                                                                        |
| 420 |    701.824947 |    199.793013 | Matt Crook                                                                                                                                                                           |
| 421 |    622.647354 |    177.474591 | Yan Wong                                                                                                                                                                             |
| 422 |    367.534019 |    426.158613 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                                         |
| 423 |    500.856690 |    785.770697 | T. Michael Keesey                                                                                                                                                                    |
| 424 |    856.387369 |     52.647647 | Ferran Sayol                                                                                                                                                                         |
| 425 |    796.403166 |    291.206709 | Matt Crook                                                                                                                                                                           |
| 426 |    476.502470 |    339.144495 | Joseph Wolf, 1863 (vectorization by Dinah Challen)                                                                                                                                   |
| 427 |    880.757296 |    303.209223 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                                     |
| 428 |    586.913142 |     12.269782 | Jiekun He                                                                                                                                                                            |
| 429 |    632.259718 |     98.457421 | T. Michael Keesey (after Marek Velechovský)                                                                                                                                          |
| 430 |    696.124529 |     85.506114 | Michelle Site                                                                                                                                                                        |
| 431 |   1005.604410 |    544.040361 | Michelle Site                                                                                                                                                                        |
| 432 |    716.216329 |    336.583998 | Scott Hartman                                                                                                                                                                        |
| 433 |    455.669916 |    184.632664 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                                      |
| 434 |    301.219164 |    652.537973 | xgirouxb                                                                                                                                                                             |
| 435 |    467.233964 |    793.924949 | Matt Martyniuk                                                                                                                                                                       |
| 436 |     51.445639 |    370.280503 | Tim H. Heupink, Leon Huynen, and David M. Lambert (vectorized by T. Michael Keesey)                                                                                                  |
| 437 |    286.459590 |    243.973397 | Michelle Site                                                                                                                                                                        |
| 438 |    160.475821 |    341.666564 | Zimices                                                                                                                                                                              |
| 439 |    184.334475 |    766.591772 | Noah Schlottman, photo by Reinhard Jahn                                                                                                                                              |
| 440 |    287.713388 |    407.223675 | T. Michael Keesey                                                                                                                                                                    |
| 441 |    384.659751 |    135.072969 | Acrocynus (vectorized by T. Michael Keesey)                                                                                                                                          |
| 442 |    431.192138 |    767.178156 | Scott Hartman                                                                                                                                                                        |
| 443 |    683.370672 |    266.006117 | Iain Reid                                                                                                                                                                            |
| 444 |    371.955749 |    349.968655 | NA                                                                                                                                                                                   |
| 445 |    839.586055 |    750.417628 | Matt Dempsey                                                                                                                                                                         |
| 446 |    193.911826 |    348.459236 | Martin R. Smith                                                                                                                                                                      |
| 447 |     66.368167 |    250.559601 | NA                                                                                                                                                                                   |
| 448 |    834.928884 |    710.806021 | Zimices                                                                                                                                                                              |
| 449 |    948.012920 |    422.046949 | Christoph Schomburg                                                                                                                                                                  |
| 450 |    397.471990 |    132.324356 | Matt Crook                                                                                                                                                                           |
| 451 |   1011.669563 |    683.253453 | Scott Hartman                                                                                                                                                                        |
| 452 |    701.785720 |    495.567260 | Mattia Menchetti / Yan Wong                                                                                                                                                          |
| 453 |    210.880918 |    430.792812 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 454 |    944.981245 |    653.790278 | Ghedo (vectorized by T. Michael Keesey)                                                                                                                                              |
| 455 |    481.111447 |    363.393012 | Rebecca Groom                                                                                                                                                                        |
| 456 |    647.404188 |    609.977672 | Yan Wong                                                                                                                                                                             |
| 457 |    144.457568 |    437.878853 | NA                                                                                                                                                                                   |
| 458 |    676.211707 |    508.933212 | Jessica Anne Miller                                                                                                                                                                  |
| 459 |    381.025240 |    627.774381 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 460 |     28.098348 |    449.654609 | Ferran Sayol                                                                                                                                                                         |
| 461 |    459.184548 |    604.973251 | T. Michael Keesey                                                                                                                                                                    |
| 462 |    572.665477 |    791.103957 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                                  |
| 463 |    977.150494 |    101.263612 | Kamil S. Jaron                                                                                                                                                                       |
| 464 |    527.403547 |    333.228101 | Margot Michaud                                                                                                                                                                       |
| 465 |    697.917749 |    465.100203 | Scott Hartman                                                                                                                                                                        |
| 466 |    572.456483 |    586.489091 | Christoph Schomburg                                                                                                                                                                  |
| 467 |    537.216662 |    783.459951 | NA                                                                                                                                                                                   |
| 468 |    852.254949 |    203.075556 | Margot Michaud                                                                                                                                                                       |
| 469 |    215.395336 |    768.946451 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 470 |    494.848282 |    575.249869 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 471 |     26.925931 |    418.991498 | Smokeybjb                                                                                                                                                                            |
| 472 |    290.687539 |    393.363656 | Beth Reinke                                                                                                                                                                          |
| 473 |    225.816308 |    445.906059 | Matt Crook                                                                                                                                                                           |
| 474 |    805.877226 |    330.905941 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                                  |
| 475 |    963.743793 |    714.219196 | Scott Hartman                                                                                                                                                                        |
| 476 |    873.819342 |     18.390246 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                                     |
| 477 |    840.112310 |    691.510771 | Mali’o Kodis, image by Rebecca Ritger                                                                                                                                                |
| 478 |    580.742705 |    431.320228 | Birgit Lang                                                                                                                                                                          |
| 479 |    393.990537 |    242.198840 | Scott Hartman, modified by T. Michael Keesey                                                                                                                                         |
| 480 |    655.169959 |    727.777782 | Dexter R. Mardis                                                                                                                                                                     |
| 481 |    489.724697 |    610.486526 | NA                                                                                                                                                                                   |
| 482 |    490.063106 |      8.438806 | Manabu Bessho-Uehara                                                                                                                                                                 |
| 483 |    618.381413 |     66.397869 | Tony Ayling                                                                                                                                                                          |
| 484 |    579.082296 |    338.155229 | Scott Hartman                                                                                                                                                                        |
| 485 |    682.799438 |    477.398211 | NA                                                                                                                                                                                   |
| 486 |    469.552637 |    744.156145 | Skye McDavid                                                                                                                                                                         |
| 487 |    217.259442 |    469.424227 | Tom Tarrant (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                          |
| 488 |    493.731882 |    202.784339 | Maija Karala                                                                                                                                                                         |
| 489 |    554.719924 |    265.306753 | FunkMonk                                                                                                                                                                             |
| 490 |    218.683497 |    635.378471 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 491 |    501.136197 |    230.411258 | Alexandre Vong                                                                                                                                                                       |
| 492 |    431.291894 |    755.667114 | Matt Crook                                                                                                                                                                           |
| 493 |    802.242754 |    629.041942 | Jagged Fang Designs                                                                                                                                                                  |
| 494 |    205.283216 |    748.403049 | Felix Vaux and Steven A. Trewick                                                                                                                                                     |
| 495 |      8.370303 |    210.994849 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 496 |    167.795610 |    375.179736 | Ferran Sayol                                                                                                                                                                         |
| 497 |    351.124590 |    748.351576 | Mathieu Pélissié                                                                                                                                                                     |
| 498 |    946.880177 |    673.789847 | Jagged Fang Designs                                                                                                                                                                  |
| 499 |    134.341934 |    214.926822 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 500 |     20.019129 |     60.314432 | Gareth Monger                                                                                                                                                                        |
| 501 |    710.054943 |    272.597447 | Ghedoghedo, vectorized by Zimices                                                                                                                                                    |
| 502 |      5.267571 |    275.679261 | Andrew A. Farke                                                                                                                                                                      |
| 503 |     55.089355 |     57.474477 | Gareth Monger                                                                                                                                                                        |
| 504 |     28.538816 |    718.097081 | Ferran Sayol                                                                                                                                                                         |
| 505 |    357.960179 |    103.548271 | Beth Reinke                                                                                                                                                                          |
| 506 |    460.731644 |     23.719610 | Dmitry Bogdanov                                                                                                                                                                      |
| 507 |    862.841925 |     69.277454 | Zimices                                                                                                                                                                              |
| 508 |   1018.276142 |    220.457761 | T. Michael Keesey                                                                                                                                                                    |
| 509 |    627.558441 |    498.280760 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 510 |    649.788661 |    222.341706 | NA                                                                                                                                                                                   |
| 511 |    122.004432 |    239.623847 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 512 |     62.335588 |    397.332577 | Jon M Laurent                                                                                                                                                                        |
| 513 |     71.093801 |    455.741930 | Isaure Scavezzoni                                                                                                                                                                    |
| 514 |    755.882157 |    339.360646 | Scott Hartman                                                                                                                                                                        |
| 515 |    456.595773 |    795.281533 | Pete Buchholz                                                                                                                                                                        |
| 516 |    750.007202 |     87.757619 | Emily Jane McTavish, from <http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>                                                                          |
| 517 |    290.871125 |    676.198960 | Sarah Werning                                                                                                                                                                        |
| 518 |    888.986618 |    785.971244 | Emily Willoughby                                                                                                                                                                     |
| 519 |    264.203249 |    730.674818 | Scott Hartman                                                                                                                                                                        |
| 520 |    912.804026 |    618.282588 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 521 |    739.417332 |    531.973834 | Yan Wong                                                                                                                                                                             |
| 522 |    604.921543 |    578.949832 | Jagged Fang Designs                                                                                                                                                                  |
| 523 |   1008.429746 |    775.946426 | Matt Crook                                                                                                                                                                           |
| 524 |    567.577388 |    520.688109 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 525 |    559.550765 |    187.680506 | CNZdenek                                                                                                                                                                             |
| 526 |    281.712787 |    736.972870 | Kamil S. Jaron                                                                                                                                                                       |
| 527 |    460.827952 |    614.996910 | Jagged Fang Designs                                                                                                                                                                  |
| 528 |     48.694178 |    469.018096 | Henry Lydecker                                                                                                                                                                       |
| 529 |   1015.805950 |    568.768424 | Falconaumanni and T. Michael Keesey                                                                                                                                                  |
| 530 |    419.518641 |    129.409104 | Zimices                                                                                                                                                                              |
| 531 |    909.124843 |    232.038779 | Christoph Schomburg                                                                                                                                                                  |
| 532 |    816.405126 |    297.304073 | Erika Schumacher                                                                                                                                                                     |
| 533 |    381.862485 |     63.230777 | Matt Crook                                                                                                                                                                           |
| 534 |    426.752500 |    781.085753 | Zimices                                                                                                                                                                              |
| 535 |    888.972534 |    544.284784 | Madeleine Price Ball                                                                                                                                                                 |
| 536 |    722.217924 |    694.059931 | NA                                                                                                                                                                                   |
| 537 |    257.368074 |    306.562003 | Gareth Monger                                                                                                                                                                        |
| 538 |    741.899637 |    343.289185 | Jose Carlos Arenas-Monroy                                                                                                                                                            |
| 539 |    915.122039 |    459.191028 | Joanna Wolfe                                                                                                                                                                         |
| 540 |    890.532833 |     20.732844 | Tasman Dixon                                                                                                                                                                         |
| 541 |    926.136982 |    474.459831 | Sharon Wegner-Larsen                                                                                                                                                                 |
| 542 |    515.919288 |    408.641125 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                                 |
| 543 |    814.993300 |    287.107158 | Jon M Laurent                                                                                                                                                                        |
| 544 |    113.098178 |    339.475477 | T. Michael Keesey (from a mount by Allis Markham)                                                                                                                                    |
| 545 |    929.429748 |    282.686998 | Margot Michaud                                                                                                                                                                       |
| 546 |    637.335550 |    208.005222 | Mathew Stewart                                                                                                                                                                       |
| 547 |   1002.531007 |    606.874690 | Birgit Lang                                                                                                                                                                          |
| 548 |    385.056504 |    442.623224 | Audrey Ely                                                                                                                                                                           |
| 549 |    967.512186 |    319.405809 | Ferran Sayol                                                                                                                                                                         |
| 550 |    901.922070 |      8.330674 | NA                                                                                                                                                                                   |
| 551 |    478.459483 |    199.175802 | Steven Traver                                                                                                                                                                        |
| 552 |    967.441819 |     16.509247 | Acrocynus (vectorized by T. Michael Keesey)                                                                                                                                          |
| 553 |    871.589011 |    785.631009 | Liftarn                                                                                                                                                                              |
| 554 |    567.812658 |    343.294951 | Archaeodontosaurus (vectorized by T. Michael Keesey)                                                                                                                                 |
| 555 |    623.221222 |    129.328137 | Ferran Sayol                                                                                                                                                                         |
| 556 |    844.693410 |    141.979178 | Scott Hartman                                                                                                                                                                        |
| 557 |    368.298410 |    401.580657 | Margot Michaud                                                                                                                                                                       |
| 558 |    703.264827 |    254.302424 | Matt Crook                                                                                                                                                                           |
| 559 |    883.979902 |    741.474001 | Jiekun He                                                                                                                                                                            |
| 560 |    475.735686 |    351.988240 | Scott Hartman                                                                                                                                                                        |
| 561 |     38.073169 |    638.547887 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 562 |    867.371664 |    239.075566 | L. Shyamal                                                                                                                                                                           |
| 563 |    263.369825 |    417.324806 | Tasman Dixon                                                                                                                                                                         |
| 564 |    164.962639 |     76.887946 | Andrew A. Farke, modified from original by H. Milne Edwards                                                                                                                          |
| 565 |    237.215082 |    321.163695 | Steven Traver                                                                                                                                                                        |
| 566 |    625.030655 |    518.364004 | Tracy A. Heath                                                                                                                                                                       |
| 567 |    386.992300 |    226.563255 | John Gould (vectorized by T. Michael Keesey)                                                                                                                                         |
| 568 |    443.216275 |    235.094193 | Jagged Fang Designs                                                                                                                                                                  |
| 569 |    202.924606 |    483.268135 | Lukasiniho                                                                                                                                                                           |
| 570 |    587.995567 |    749.846196 | CNZdenek                                                                                                                                                                             |
| 571 |    585.745626 |    412.600636 | Sarah Werning                                                                                                                                                                        |
| 572 |    674.776297 |    600.709879 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 573 |    826.049224 |     98.368779 | Scott Hartman                                                                                                                                                                        |
| 574 |    242.607796 |    142.228394 | Zimices                                                                                                                                                                              |
| 575 |    590.893934 |    789.262620 | Juan Carlos Jerí                                                                                                                                                                     |
| 576 |    769.960006 |    172.676454 | Kamil S. Jaron                                                                                                                                                                       |
| 577 |    375.494872 |    233.594130 | Rebecca Groom                                                                                                                                                                        |
| 578 |   1010.454999 |    176.164168 | Harold N Eyster                                                                                                                                                                      |
| 579 |    442.114812 |     63.928977 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 580 |    792.971886 |    559.836575 | Enoch Joseph Wetsy (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                   |
| 581 |    362.512061 |    189.563520 | Jaime Headden                                                                                                                                                                        |
| 582 |    681.294779 |    208.112154 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey)                |
| 583 |    383.563575 |    774.595205 | Steven Traver                                                                                                                                                                        |
| 584 |    515.712290 |    578.999624 | Mo Hassan                                                                                                                                                                            |
| 585 |      9.754103 |    495.729877 | Catherine Yasuda                                                                                                                                                                     |
| 586 |    746.388387 |    583.203037 | Warren H (photography), T. Michael Keesey (vectorization)                                                                                                                            |
| 587 |     10.398036 |    507.518659 | David Tana                                                                                                                                                                           |
| 588 |     26.278983 |    360.679732 | T. Michael Keesey                                                                                                                                                                    |
| 589 |    836.433608 |    212.912581 | Trond R. Oskars                                                                                                                                                                      |
| 590 |    626.792164 |    187.365869 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                                     |
| 591 |    412.235734 |    603.325955 | George Edward Lodge (vectorized by T. Michael Keesey)                                                                                                                                |
| 592 |    966.197754 |    745.928999 | Cathy                                                                                                                                                                                |
| 593 |    785.630109 |    791.858948 | Gareth Monger                                                                                                                                                                        |
| 594 |    547.364296 |    243.338977 | Margot Michaud                                                                                                                                                                       |
| 595 |    411.138340 |    233.491353 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 596 |    265.529400 |    273.320967 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 597 |    937.326220 |    208.475035 | Gareth Monger                                                                                                                                                                        |
| 598 |     25.601653 |    204.175946 | Gareth Monger                                                                                                                                                                        |
| 599 |    769.093687 |     44.446916 | Andy Wilson                                                                                                                                                                          |
| 600 |    545.263744 |    523.462161 | Ferran Sayol                                                                                                                                                                         |
| 601 |    256.736740 |    240.091854 | Michael Scroggie                                                                                                                                                                     |
| 602 |    990.603391 |    548.719662 | Dennis C. Murphy, after <https://commons.wikimedia.org/wiki/File:Queensland_State_Archives_2981_Cane_toads_at_the_Meringa_Sugar_Experiment_Station_North_Queensland_c_1935.png>      |
| 603 |    735.417980 |    761.475225 | Mykle Hoban                                                                                                                                                                          |
| 604 |    437.851597 |    215.545941 | Jose Carlos Arenas-Monroy                                                                                                                                                            |
| 605 |    343.599780 |    348.617200 | T. Michael Keesey                                                                                                                                                                    |
| 606 |    242.951152 |    447.240748 | T. Michael Keesey (after James & al.)                                                                                                                                                |
| 607 |    624.047370 |    621.313788 | Anthony Caravaggi                                                                                                                                                                    |
| 608 |    576.038727 |    496.259945 | Zimices                                                                                                                                                                              |
| 609 |    250.889270 |    291.671055 | Ferran Sayol                                                                                                                                                                         |
| 610 |    782.010714 |    594.227226 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 611 |    179.301548 |    752.202901 | Ferran Sayol                                                                                                                                                                         |
| 612 |    103.758702 |    445.969611 | Chris huh                                                                                                                                                                            |
| 613 |     10.247639 |    384.026719 | Mathieu Pélissié                                                                                                                                                                     |
| 614 |    286.606055 |    629.226132 | Matt Martyniuk                                                                                                                                                                       |
| 615 |    283.285399 |     91.756310 | Jiekun He                                                                                                                                                                            |
| 616 |    112.371245 |    464.152139 | Meyers Konversations-Lexikon 1897 (vectorized: Yan Wong)                                                                                                                             |
| 617 |    465.968765 |    596.311103 | Shyamal                                                                                                                                                                              |
| 618 |    847.860369 |    624.734101 | Myriam\_Ramirez                                                                                                                                                                      |
| 619 |    694.214466 |    506.821472 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 620 |    119.101170 |     86.665294 | Ferran Sayol                                                                                                                                                                         |
| 621 |    345.501580 |    169.902114 | Rachel Shoop                                                                                                                                                                         |
| 622 |   1010.834866 |    762.170794 | Cesar Julian                                                                                                                                                                         |
| 623 |    866.405998 |    198.957462 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 624 |     12.839610 |     75.063523 | T. Michael Keesey                                                                                                                                                                    |
| 625 |    564.781704 |    112.689828 | Ferran Sayol                                                                                                                                                                         |
| 626 |    223.612673 |    279.982575 | Pete Buchholz                                                                                                                                                                        |
| 627 |    802.356655 |     50.910264 | Don Armstrong                                                                                                                                                                        |
| 628 |    937.857042 |    263.313234 | Jake Warner                                                                                                                                                                          |
| 629 |    895.892200 |    428.562965 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                                         |
| 630 |    957.466143 |     35.352650 | Mark Hofstetter (vectorized by T. Michael Keesey)                                                                                                                                    |
| 631 |    397.837166 |    794.335929 | Ghedoghedo                                                                                                                                                                           |
| 632 |     72.762351 |    339.793706 | Xavier Giroux-Bougard                                                                                                                                                                |
| 633 |    336.601335 |     97.845098 | Shyamal                                                                                                                                                                              |
| 634 |    822.063765 |    103.785230 | Steven Traver                                                                                                                                                                        |
| 635 |    571.161334 |    780.950133 | T. Michael Keesey (vector) and Stuart Halliday (photograph)                                                                                                                          |
| 636 |    421.686164 |    176.369522 | Andrew A. Farke                                                                                                                                                                      |
| 637 |    124.425198 |    519.663496 | Mathew Wedel                                                                                                                                                                         |
| 638 |    485.944438 |    235.323600 | Caleb M. Brown                                                                                                                                                                       |
| 639 |     80.401018 |    424.243218 | Manabu Sakamoto                                                                                                                                                                      |
| 640 |     61.716527 |    623.290026 | John Conway                                                                                                                                                                          |
| 641 |    522.734370 |    497.282655 | Steven Traver                                                                                                                                                                        |
| 642 |    518.153063 |      3.103521 | E. R. Waite & H. M. Hale (vectorized by T. Michael Keesey)                                                                                                                           |
| 643 |    607.074712 |    319.178370 | NA                                                                                                                                                                                   |
| 644 |    407.574330 |    763.299838 | Noah Schlottman                                                                                                                                                                      |
| 645 |    315.242962 |    612.756427 | Ignacio Contreras                                                                                                                                                                    |
| 646 |    436.500992 |      5.579471 | Smokeybjb                                                                                                                                                                            |
| 647 |    817.313642 |    796.954890 | Gareth Monger                                                                                                                                                                        |
| 648 |    241.968852 |    227.850730 | Gareth Monger                                                                                                                                                                        |
| 649 |   1011.742363 |    422.322771 | Michelle Site                                                                                                                                                                        |
| 650 |    660.316442 |    623.334500 | Andy Wilson                                                                                                                                                                          |
| 651 |     76.266585 |    796.540897 | Smokeybjb                                                                                                                                                                            |
| 652 |    523.842231 |    322.606826 | Chris huh                                                                                                                                                                            |
| 653 |    306.226125 |    660.508388 | Kailah Thorn & Mark Hutchinson                                                                                                                                                       |
| 654 |    783.061082 |    530.746174 | Caleb M. Gordon                                                                                                                                                                      |
| 655 |    979.352669 |     41.118068 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 656 |    368.349148 |    319.583000 | Matt Crook                                                                                                                                                                           |
| 657 |    955.470645 |    283.490820 | T. Michael Keesey                                                                                                                                                                    |
| 658 |    563.773981 |     15.867743 | Natalie Claunch                                                                                                                                                                      |
| 659 |     19.667980 |    652.099177 | Ferran Sayol                                                                                                                                                                         |
| 660 |     13.037101 |    222.272654 | Harold N Eyster                                                                                                                                                                      |
| 661 |   1011.282771 |    334.315047 | Francis de Laporte de Castelnau (vectorized by T. Michael Keesey)                                                                                                                    |
| 662 |    977.817494 |     24.526747 | Kenneth Lacovara (vectorized by T. Michael Keesey)                                                                                                                                   |
| 663 |    338.930205 |    790.133492 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 664 |     40.245533 |    710.623494 | Scott Hartman                                                                                                                                                                        |
| 665 |    526.014859 |    693.843192 | Scott Hartman                                                                                                                                                                        |
| 666 |    447.773077 |    309.642756 | Qiang Ou                                                                                                                                                                             |
| 667 |    112.128301 |    523.180605 | C. W. Nash (illustration) and Timothy J. Bartley (silhouette)                                                                                                                        |
| 668 |    640.853729 |    178.979436 | Tauana J. Cunha                                                                                                                                                                      |
| 669 |     74.999365 |     86.904347 | Melissa Broussard                                                                                                                                                                    |
| 670 |     85.441158 |     42.222895 | Birgit Lang                                                                                                                                                                          |
| 671 |    549.561583 |    703.431743 | NA                                                                                                                                                                                   |
| 672 |     41.117431 |    727.367299 | Crystal Maier                                                                                                                                                                        |
| 673 |    638.941368 |    220.534957 | Ignacio Contreras                                                                                                                                                                    |
| 674 |   1008.911612 |    358.003539 | Matt Crook                                                                                                                                                                           |
| 675 |    913.443011 |    555.430616 | Ferran Sayol                                                                                                                                                                         |
| 676 |   1002.419112 |     62.757398 | Aadx                                                                                                                                                                                 |
| 677 |   1006.308340 |     84.290280 | Scott Hartman                                                                                                                                                                        |
| 678 |    555.497440 |    436.601274 | Margot Michaud                                                                                                                                                                       |
| 679 |    303.657442 |    482.290623 | Chris huh                                                                                                                                                                            |
| 680 |    514.199949 |    543.747646 | Matt Crook                                                                                                                                                                           |
| 681 |    752.841077 |    699.778978 | Duane Raver (vectorized by T. Michael Keesey)                                                                                                                                        |
| 682 |    229.284121 |    725.536361 | Hans Hillewaert (photo) and T. Michael Keesey (vectorization)                                                                                                                        |
| 683 |    524.195584 |    470.243640 | Doug Backlund (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                        |
| 684 |    190.855073 |    477.362419 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                                       |
| 685 |    937.133391 |    407.216400 | Catherine Yasuda                                                                                                                                                                     |
| 686 |    519.600934 |    398.536987 | Gareth Monger                                                                                                                                                                        |
| 687 |    764.650419 |    757.136175 | Matt Crook                                                                                                                                                                           |
| 688 |    960.741119 |    402.831306 | Birgit Lang                                                                                                                                                                          |
| 689 |    903.717004 |    169.460450 | Chris huh                                                                                                                                                                            |
| 690 |    887.958801 |     70.452922 | Dave Souza (vectorized by T. Michael Keesey)                                                                                                                                         |
| 691 |    102.308022 |     10.287301 | NA                                                                                                                                                                                   |
| 692 |    521.182634 |    418.647842 | Birgit Lang                                                                                                                                                                          |
| 693 |    601.522944 |    358.566381 | Jiekun He                                                                                                                                                                            |
| 694 |    238.692531 |    721.871399 | Stuart Humphries                                                                                                                                                                     |
| 695 |    233.319794 |    196.625651 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 696 |    854.598917 |    232.831063 | Markus A. Grohme                                                                                                                                                                     |
| 697 |    978.818711 |     19.090707 | James R. Spotila and Ray Chatterji                                                                                                                                                   |
| 698 |    172.875451 |    224.608690 | NA                                                                                                                                                                                   |
| 699 |    804.781148 |    624.231323 | Todd Marshall, vectorized by Zimices                                                                                                                                                 |
| 700 |    128.147620 |    516.441206 | Chris huh                                                                                                                                                                            |
| 701 |    531.151239 |     82.067107 | Sean McCann                                                                                                                                                                          |
| 702 |    589.151966 |    245.969347 | Falconaumanni and T. Michael Keesey                                                                                                                                                  |
| 703 |    621.160233 |    149.071816 | Jose Carlos Arenas-Monroy                                                                                                                                                            |
| 704 |     69.771077 |    229.974406 | Zimices                                                                                                                                                                              |
| 705 |    113.263483 |    591.255109 | Jagged Fang Designs                                                                                                                                                                  |
| 706 |    369.849799 |    741.751426 | Emily Willoughby                                                                                                                                                                     |
| 707 |    215.696595 |    709.294440 | NA                                                                                                                                                                                   |
| 708 |    156.544256 |    152.590867 | Birgit Lang                                                                                                                                                                          |
| 709 |     33.755109 |    427.404633 | Mali’o Kodis, photograph by Cordell Expeditions at Cal Academy                                                                                                                       |
| 710 |    857.394935 |    704.694059 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                                     |
| 711 |    579.435217 |    738.070564 | NA                                                                                                                                                                                   |
| 712 |     16.585227 |    515.630539 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 713 |    575.157098 |    186.126434 | T. Michael Keesey (vectorization) and Nadiatalent (photography)                                                                                                                      |
| 714 |    460.400073 |    169.168224 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 715 |    314.430288 |    620.399304 | Margot Michaud                                                                                                                                                                       |
| 716 |    474.563344 |    374.333792 | Margot Michaud                                                                                                                                                                       |
| 717 |    383.104535 |    743.525159 | NA                                                                                                                                                                                   |
| 718 |    632.629117 |    446.629931 | Sean McCann                                                                                                                                                                          |
| 719 |      3.659721 |    241.267087 | Mathieu Pélissié                                                                                                                                                                     |
| 720 |    786.191558 |    210.624016 | Ingo Braasch                                                                                                                                                                         |
| 721 |    468.470434 |    286.406458 | Paul Baker (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                           |
| 722 |    724.967906 |    797.504600 | Markus A. Grohme                                                                                                                                                                     |
| 723 |    234.904944 |    478.404168 | Original drawing by Nobu Tamura, vectorized by Roberto Díaz Sibaja                                                                                                                   |
| 724 |    303.469914 |    212.293384 | Lauren Anderson                                                                                                                                                                      |
| 725 |    989.258426 |    687.657749 | Zimices                                                                                                                                                                              |
| 726 |    747.399986 |    543.363887 | Smokeybjb (modified by T. Michael Keesey)                                                                                                                                            |
| 727 |    938.833172 |    707.475183 | Ferran Sayol                                                                                                                                                                         |
| 728 |    528.932643 |    347.674051 | Margot Michaud                                                                                                                                                                       |
| 729 |    928.014287 |    664.049059 | Margret Flinsch, vectorized by Zimices                                                                                                                                               |
| 730 |     85.013360 |    220.758491 | Markus A. Grohme                                                                                                                                                                     |
| 731 |    373.358999 |    713.293639 | Margot Michaud                                                                                                                                                                       |
| 732 |    785.655698 |    549.979082 | Margot Michaud                                                                                                                                                                       |
| 733 |    453.754707 |    753.747746 | Chris Hay                                                                                                                                                                            |
| 734 |   1009.349210 |    577.219390 | Kailah Thorn & Mark Hutchinson                                                                                                                                                       |
| 735 |    347.187930 |     30.406779 | T. Michael Keesey (vectorization); Thorsten Assmann, Jörn Buse, Claudia Drees, Ariel-Leib-Leonid Friedman, Tal Levanony, Andrea Matern, Anika Timm, and David W. Wrase (photography) |
| 736 |    541.692950 |    417.459583 | Andrew A. Farke                                                                                                                                                                      |
| 737 |    876.366574 |    255.824115 | Yan Wong from drawing by Joseph Smit                                                                                                                                                 |
| 738 |    925.515499 |     33.961092 | Matt Dempsey                                                                                                                                                                         |
| 739 |    938.836129 |    274.121121 | Robert Bruce Horsfall, from W.B. Scott’s 1912 “A History of Land Mammals in the Western Hemisphere”                                                                                  |
| 740 |    795.619616 |    272.450106 | Steven Traver                                                                                                                                                                        |
| 741 |    529.135087 |    234.649164 | Margot Michaud                                                                                                                                                                       |
| 742 |    115.532546 |    370.566451 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                                              |
| 743 |    454.950269 |    198.650215 | Sarah Werning                                                                                                                                                                        |
| 744 |    280.179882 |    691.418486 | NA                                                                                                                                                                                   |
| 745 |    861.565997 |    755.267998 | NA                                                                                                                                                                                   |
| 746 |    920.186339 |    428.726549 | Maija Karala                                                                                                                                                                         |
| 747 |     25.174063 |    396.902673 | Ludwik Gąsiorowski                                                                                                                                                                   |
| 748 |     11.334573 |    203.157007 | Scott Hartman                                                                                                                                                                        |
| 749 |    684.189038 |    355.872517 | Steven Traver                                                                                                                                                                        |
| 750 |    713.101365 |     74.176446 | Ignacio Contreras                                                                                                                                                                    |
| 751 |    835.885883 |    718.597126 | Scott Hartman                                                                                                                                                                        |
| 752 |    997.607713 |    725.043017 | David Tana                                                                                                                                                                           |
| 753 |    555.540214 |    509.399358 | Smokeybjb (modified by T. Michael Keesey)                                                                                                                                            |
| 754 |     30.471920 |    525.265513 | Jagged Fang Designs                                                                                                                                                                  |
| 755 |    371.766998 |    548.265558 | Margot Michaud                                                                                                                                                                       |
| 756 |    352.921205 |      8.416944 | Kamil S. Jaron                                                                                                                                                                       |
| 757 |    284.542876 |    220.726280 | Margot Michaud                                                                                                                                                                       |
| 758 |    397.196459 |    614.145376 | Michelle Site                                                                                                                                                                        |
| 759 |    713.801527 |    231.745182 | Birgit Lang                                                                                                                                                                          |
| 760 |      7.731756 |    262.291336 | Steven Traver                                                                                                                                                                        |
| 761 |    577.663794 |    672.235574 | Markus A. Grohme                                                                                                                                                                     |
| 762 |    209.051453 |    442.272454 | Zimices                                                                                                                                                                              |
| 763 |    269.927266 |    425.116045 | Margot Michaud                                                                                                                                                                       |
| 764 |     84.341118 |    550.186722 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                                    |
| 765 |    443.464710 |    190.051865 | Gareth Monger                                                                                                                                                                        |
| 766 |    648.203311 |    365.280389 | Matt Wilkins (photo by Patrick Kavanagh)                                                                                                                                             |
| 767 |     98.126714 |    311.425735 | Martin Kevil                                                                                                                                                                         |
| 768 |      8.410209 |    328.192438 | Ferran Sayol                                                                                                                                                                         |
| 769 |    809.160686 |    502.832954 | Andreas Hejnol                                                                                                                                                                       |
| 770 |    801.620400 |    277.871392 | NA                                                                                                                                                                                   |
| 771 |    111.084166 |    533.441759 | Collin Gross                                                                                                                                                                         |
| 772 |    839.341958 |    375.415385 | Jagged Fang Designs                                                                                                                                                                  |
| 773 |    801.604695 |    640.136578 | Margot Michaud                                                                                                                                                                       |
| 774 |    883.543879 |    384.845392 | Zsoldos Márton (vectorized by T. Michael Keesey)                                                                                                                                     |
| 775 |    485.277425 |     18.133718 | Chris Hay                                                                                                                                                                            |
| 776 |    946.757198 |    168.621248 | Margot Michaud                                                                                                                                                                       |
| 777 |    544.999522 |    232.037435 | Chase Brownstein                                                                                                                                                                     |
| 778 |    274.477863 |    722.426959 | Chris huh                                                                                                                                                                            |
| 779 |    506.592731 |    735.133227 | Mali’o Kodis, photograph by Melissa Frey                                                                                                                                             |
| 780 |    979.434504 |    776.276307 | Lily Hughes                                                                                                                                                                          |
| 781 |    692.067072 |    735.757643 | Jose Carlos Arenas-Monroy                                                                                                                                                            |
| 782 |    719.514184 |    735.062111 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                                          |
| 783 |    167.712277 |    543.366461 | Matt Wilkins                                                                                                                                                                         |
| 784 |    732.741761 |    702.382223 | Margot Michaud                                                                                                                                                                       |
| 785 |    683.053535 |    393.586625 | Dave Angelini                                                                                                                                                                        |
| 786 |    611.731280 |    593.705780 | Erika Schumacher                                                                                                                                                                     |
| 787 |     58.280110 |    241.225281 | M Kolmann                                                                                                                                                                            |
| 788 |    839.107765 |      5.350923 | Mattia Menchetti                                                                                                                                                                     |
| 789 |    396.561742 |    492.520171 | Gareth Monger                                                                                                                                                                        |
| 790 |    519.654992 |    529.182547 | xgirouxb                                                                                                                                                                             |
| 791 |    131.956099 |    532.242661 | Mathieu Pélissié                                                                                                                                                                     |
| 792 |    375.666769 |    673.747130 | Chris huh                                                                                                                                                                            |
| 793 |   1001.471593 |    649.170404 | Markus A. Grohme                                                                                                                                                                     |
| 794 |    975.124340 |    689.742883 | FunkMonk (Michael B. H.)                                                                                                                                                             |
| 795 |    805.462996 |     64.889175 | Matt Crook                                                                                                                                                                           |
| 796 |   1001.166400 |     24.191693 | Mali’o Kodis, image from Brockhaus and Efron Encyclopedic Dictionary                                                                                                                 |
| 797 |    930.697798 |    306.201284 | Matt Dempsey                                                                                                                                                                         |
| 798 |    110.229302 |    106.916700 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 799 |    170.986298 |    125.132799 | Warren H (photography), T. Michael Keesey (vectorization)                                                                                                                            |
| 800 |    946.036442 |    680.565113 | Collin Gross                                                                                                                                                                         |
| 801 |    135.990332 |    313.161080 | Christoph Schomburg                                                                                                                                                                  |
| 802 |    949.652249 |    744.864135 | NA                                                                                                                                                                                   |
| 803 |    156.209911 |    538.834406 | Meyers Konversations-Lexikon 1897 (vectorized: Yan Wong)                                                                                                                             |
| 804 |   1003.905066 |    490.700364 | Zimices                                                                                                                                                                              |
| 805 |     55.034705 |    231.436431 | Matt Crook                                                                                                                                                                           |
| 806 |    733.841548 |     81.942381 | Trond R. Oskars                                                                                                                                                                      |
| 807 |     88.744801 |    716.932002 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 808 |    354.315712 |    253.811490 | White Wolf                                                                                                                                                                           |
| 809 |    397.007616 |    428.447468 | Jose Carlos Arenas-Monroy                                                                                                                                                            |
| 810 |    315.648191 |    603.811500 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 811 |    549.197409 |    663.018951 | Gareth Monger                                                                                                                                                                        |
| 812 |    394.790309 |    754.152109 | Chuanixn Yu                                                                                                                                                                          |
| 813 |    225.518336 |    256.757903 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 814 |    312.250685 |    644.973573 | Smokeybjb                                                                                                                                                                            |
| 815 |    101.915348 |    353.109555 | Maxime Dahirel                                                                                                                                                                       |
| 816 |    926.055436 |    544.084579 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 817 |    775.491353 |    333.382078 | NA                                                                                                                                                                                   |
| 818 |    867.658850 |    516.093968 | Andy Wilson                                                                                                                                                                          |
| 819 |   1008.578201 |    673.972745 | Matt Crook                                                                                                                                                                           |
| 820 |    168.344785 |    769.551271 | Tyler Greenfield                                                                                                                                                                     |
| 821 |     91.860103 |    213.132167 | Marie-Aimée Allard                                                                                                                                                                   |
| 822 |    821.692538 |    305.656904 | Markus A. Grohme                                                                                                                                                                     |
| 823 |    247.417481 |    432.995629 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 824 |    208.564741 |    323.320755 | Matt Crook                                                                                                                                                                           |
| 825 |    621.162574 |    445.313273 | Shyamal                                                                                                                                                                              |
| 826 |    165.160305 |    140.196164 | Ignacio Contreras                                                                                                                                                                    |
| 827 |    141.827882 |    577.063524 | Margot Michaud                                                                                                                                                                       |
| 828 |      7.594927 |    788.782227 | Mathew Wedel                                                                                                                                                                         |
| 829 |    106.601454 |    158.517109 | Gareth Monger                                                                                                                                                                        |
| 830 |    410.709640 |    614.356903 | Sharon Wegner-Larsen                                                                                                                                                                 |
| 831 |    181.650229 |    797.304784 | T. Michael Keesey                                                                                                                                                                    |
| 832 |    825.842330 |    184.721205 | Joris van der Ham (vectorized by T. Michael Keesey)                                                                                                                                  |
| 833 |    951.555138 |    265.365810 | Matt Crook                                                                                                                                                                           |
| 834 |    150.110501 |    169.133942 | Margot Michaud                                                                                                                                                                       |
| 835 |   1014.421503 |    463.760159 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                                   |
| 836 |    612.945643 |    307.765270 | Margot Michaud                                                                                                                                                                       |
| 837 |    437.473915 |    167.002428 | Margot Michaud                                                                                                                                                                       |
| 838 |    837.474460 |    545.687442 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 839 |    650.776856 |    720.478929 | Ignacio Contreras                                                                                                                                                                    |
| 840 |    811.155819 |    378.869236 | Diana Pomeroy                                                                                                                                                                        |
| 841 |     31.061601 |    150.743293 | NA                                                                                                                                                                                   |
| 842 |    992.243275 |    616.890388 | Zimices                                                                                                                                                                              |
| 843 |    558.819884 |    742.359099 | Jay Matternes, vectorized by Zimices                                                                                                                                                 |
| 844 |    314.014410 |     37.862626 | Pete Buchholz                                                                                                                                                                        |
| 845 |     19.477097 |     39.997760 | Collin Gross                                                                                                                                                                         |
| 846 |    891.125604 |    348.612853 | Fernando Carezzano                                                                                                                                                                   |
| 847 |    894.028062 |    231.680370 | Ferran Sayol                                                                                                                                                                         |
| 848 |     18.859400 |    616.944035 | NASA                                                                                                                                                                                 |
| 849 |    549.376808 |     24.632499 | Sherman F. Denton via rawpixel.com (illustration) and Timothy J. Bartley (silhouette)                                                                                                |
| 850 |    853.834400 |    118.360878 | Kailah Thorn & Ben King                                                                                                                                                              |
| 851 |    617.639655 |    459.044589 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                                                       |
| 852 |    793.849632 |    253.261317 | Birgit Lang                                                                                                                                                                          |
| 853 |    831.482197 |     93.499386 | Scott Hartman                                                                                                                                                                        |
| 854 |    385.505245 |     50.928926 | Lisa Byrne                                                                                                                                                                           |
| 855 |     13.836121 |    708.448602 | Gareth Monger                                                                                                                                                                        |
| 856 |    809.228049 |     83.500975 | Alexandre Vong                                                                                                                                                                       |
| 857 |    345.814052 |    428.553245 | Madeleine Price Ball                                                                                                                                                                 |
| 858 |    558.569109 |     73.467072 | James Neenan                                                                                                                                                                         |
| 859 |    385.787232 |    499.341082 | Zimices                                                                                                                                                                              |
| 860 |    841.921643 |    159.941030 | Christoph Schomburg                                                                                                                                                                  |
| 861 |    273.880304 |    755.317330 | Young and Zhao (1972:figure 4), modified by Michael P. Taylor                                                                                                                        |
| 862 |    508.601251 |    659.486225 | Margret Flinsch, vectorized by Zimices                                                                                                                                               |
| 863 |    861.753874 |    739.940321 | David Orr                                                                                                                                                                            |
| 864 |    375.059768 |    248.716007 | Robert Gay, modifed from Olegivvit                                                                                                                                                   |
| 865 |    999.224213 |    194.007093 | Tauana J. Cunha                                                                                                                                                                      |
| 866 |    515.063911 |    374.927797 | Matt Crook                                                                                                                                                                           |
| 867 |    622.859097 |    489.988147 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 868 |    902.428928 |    474.218502 | Zimices                                                                                                                                                                              |
| 869 |     23.588372 |    337.152367 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 870 |    893.059640 |    605.368889 | Mali’o Kodis, photograph by G. Giribet                                                                                                                                               |
| 871 |    145.914156 |     26.081669 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 872 |    941.398353 |    291.909238 | Benjamint444                                                                                                                                                                         |
| 873 |    297.973158 |    690.644806 | Kai R. Caspar                                                                                                                                                                        |
| 874 |    831.139535 |    125.769024 | Chris huh                                                                                                                                                                            |
| 875 |    816.473761 |    533.766759 | Sarah Werning                                                                                                                                                                        |
| 876 |     85.625843 |    699.807252 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 877 |    794.310829 |    413.506063 | Ferran Sayol                                                                                                                                                                         |
| 878 |    520.352040 |    559.292805 | Michelle Site                                                                                                                                                                        |
| 879 |    221.916117 |    264.545121 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 880 |    538.338497 |     42.343314 | Collin Gross                                                                                                                                                                         |
| 881 |    627.847633 |    511.757406 | Mathilde Cordellier                                                                                                                                                                  |
| 882 |    286.159276 |    339.550418 | Margot Michaud                                                                                                                                                                       |
| 883 |    682.531192 |    434.592998 | Andy Wilson                                                                                                                                                                          |
| 884 |    106.795986 |    562.165455 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                                             |
| 885 |    801.693564 |    134.777636 | Chuanixn Yu                                                                                                                                                                          |
| 886 |    754.898056 |    525.112991 | Chris huh                                                                                                                                                                            |
| 887 |   1016.404807 |    784.232096 | NA                                                                                                                                                                                   |
| 888 |     14.485582 |    778.413349 | Beth Reinke                                                                                                                                                                          |
| 889 |    860.167895 |    722.508138 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 890 |    698.413352 |    721.821841 | T. Michael Keesey                                                                                                                                                                    |
| 891 |    607.719152 |     25.329028 | Tasman Dixon                                                                                                                                                                         |
| 892 |    356.489411 |    418.583594 | Elizabeth Parker                                                                                                                                                                     |
| 893 |    279.955330 |     70.913752 | Jaime Headden                                                                                                                                                                        |
| 894 |    573.388528 |    257.394284 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 895 |    651.578205 |    346.321358 | Margot Michaud                                                                                                                                                                       |
| 896 |    980.296089 |    544.242868 | Scott Hartman                                                                                                                                                                        |
| 897 |    455.636219 |     56.896334 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                                  |
| 898 |    916.849333 |    653.371163 | NA                                                                                                                                                                                   |
| 899 |    245.888398 |    128.631162 | Rebecca Groom                                                                                                                                                                        |
| 900 |    392.766283 |    447.994932 | Dmitry Bogdanov                                                                                                                                                                      |
| 901 |    523.117305 |    479.103069 | Emily Willoughby                                                                                                                                                                     |
| 902 |    482.332196 |    549.467486 | Markus A. Grohme                                                                                                                                                                     |
| 903 |    217.067615 |    488.613563 | Milton Tan                                                                                                                                                                           |
| 904 |    522.996650 |    194.039454 | Jaime Headden                                                                                                                                                                        |
| 905 |    900.170372 |    731.917528 | Ferran Sayol                                                                                                                                                                         |
| 906 |    500.913912 |    305.012732 | Ludwik Gąsiorowski                                                                                                                                                                   |
| 907 |    108.826082 |    232.930651 | Matus Valach                                                                                                                                                                         |
| 908 |    241.725947 |      4.922368 | Tracy A. Heath                                                                                                                                                                       |
| 909 |    262.791255 |    184.642424 | Matt Crook                                                                                                                                                                           |
| 910 |     15.738912 |     97.499305 | Terpsichores                                                                                                                                                                         |
| 911 |     19.184486 |    157.802658 | Margot Michaud                                                                                                                                                                       |
| 912 |    176.101967 |    774.460070 | Gareth Monger                                                                                                                                                                        |

    #> Your tweet has been posted!
