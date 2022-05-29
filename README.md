
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

Erika Schumacher, Audrey Ely, T. Michael Keesey, Zimices, Nobu Tamura,
vectorized by Zimices, Sharon Wegner-Larsen, Jagged Fang Designs, Dmitry
Bogdanov, Cyril Matthey-Doret, adapted from Bernard Chaubet, L. Shyamal,
Liftarn, Richard J. Harris, Pete Buchholz, Matt Dempsey, Shyamal, Matt
Celeskey, Steven Traver, Margot Michaud, Birgit Lang, Andy Wilson,
Melissa Broussard, Milton Tan, Cesar Julian, Michele Tobias, Sarah
Werning, Robert Bruce Horsfall, vectorized by Zimices, Jose Carlos
Arenas-Monroy, Ferran Sayol, Gareth Monger, Kamil S. Jaron, Yan Wong,
Ignacio Contreras, Lukasiniho, DFoidl (vectorized by T. Michael Keesey),
Jordan Mallon (vectorized by T. Michael Keesey), Lindberg (vectorized by
T. Michael Keesey), Andrew A. Farke, Rebecca Groom, Chuanixn Yu, Scott
Hartman, Gabriela Palomo-Munoz, Hans Hillewaert (photo) and T. Michael
Keesey (vectorization), Charles R. Knight (vectorized by T. Michael
Keesey), Ville Koistinen (vectorized by T. Michael Keesey), DW Bapst,
modified from Figure 1 of Belanger (2011, PALAIOS)., (unknown), Emily
Willoughby, Maija Karala, Michelle Site, Noah Schlottman, Original
drawing by Nobu Tamura, vectorized by Roberto Díaz Sibaja, Matt Crook,
Elisabeth Östman, Oscar Sanisidro, CNZdenek, Francesco Veronesi
(vectorized by T. Michael Keesey), Markus A. Grohme, John Conway, C.
Camilo Julián-Caballero, Felix Vaux, Terpsichores, Jiekun He, Kanchi
Nanjo, Dexter R. Mardis, Arthur S. Brum, Nobu Tamura (vectorized by T.
Michael Keesey), Chris huh, Espen Horn (model; vectorized by T. Michael
Keesey from a photo by H. Zell), Almandine (vectorized by T. Michael
Keesey), Roberto Díaz Sibaja, Harold N Eyster, Keith Murdock (photo),
John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G.
Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, T.
Michael Keesey (after Colin M. L. Burnett), www.studiospectre.com, Jack
Mayer Wood, Scott Reid, Lukas Panzarin, Paul Baker (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, J Levin W
(illustration) and T. Michael Keesey (vectorization), Sergio A.
Muñoz-Gómez, Tasman Dixon, Marmelad, Ingo Braasch, Noah Schlottman,
photo by Museum of Geology, University of Tartu, Jan A. Venter, Herbert
H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael
Keesey), DW Bapst (modified from Bulman, 1970), Robert Hering, Noah
Schlottman, photo by Carol Cummings, Noah Schlottman, photo from Casey
Dunn, Julio Garza, wsnaccad, Gopal Murali, Frank Förster (based on a
picture by Hans Hillewaert), Dmitry Bogdanov (vectorized by T. Michael
Keesey), I. Geoffroy Saint-Hilaire (vectorized by T. Michael Keesey),
Steven Coombs, NASA, Zsoldos Márton (vectorized by T. Michael Keesey),
Christoph Schomburg, Kailah Thorn & Mark Hutchinson, Julien Louys, Alex
Slavenko, Beth Reinke, Josep Marti Solans, Smokeybjb, vectorized by
Zimices, Neil Kelley, Jonathan Lawley, Eduard Solà (vectorized by T.
Michael Keesey), terngirl, Michael B. H. (vectorized by T. Michael
Keesey), Manabu Sakamoto, Xavier Giroux-Bougard, Chloé Schmidt, Tony
Ayling (vectorized by T. Michael Keesey), Mathilde Cordellier, Zachary
Quigley, Marie-Aimée Allard, Chris Jennings (Risiatto), Marie Russell,
Kai R. Caspar, Ludwik Gąsiorowski, Nobu Tamura, modified by Andrew A.
Farke, Martin R. Smith, Tauana J. Cunha, Smokeybjb (vectorized by T.
Michael Keesey), Alexandre Vong, Jake Warner, Joanna Wolfe, Jonathan
Wells, Estelle Bourdon, Renato de Carvalho Ferreira, Richard Ruggiero,
vectorized by Zimices, Anthony Caravaggi, Christina N. Hodson, Martien
Brand (original photo), Renato Santos (vector silhouette), Alexander
Schmidt-Lebuhn, Nobu Tamura (modified by T. Michael Keesey), Jaime
Headden, Dean Schnabel, Maxime Dahirel, Kristina Gagalova, Steven
Haddock • Jellywatch.org, FunkMonk, Mathew Wedel, Christine Axon, T.
Michael Keesey (after Joseph Wolf), Armin Reindl, Samanta Orellana,
Michael Ströck (vectorized by T. Michael Keesey), Mathieu Pélissié,
Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes
(www.carnivorosaustrales.org), Zimices, based in Mauricio Antón
skeletal, Tony Ayling, André Karwath (vectorized by T. Michael Keesey),
Charles R. Knight, vectorized by Zimices, Geoff Shaw, Blanco et al.,
2014, vectorized by Zimices, JCGiron, Renata F. Martins, Henry Lydecker,
Andreas Trepte (vectorized by T. Michael Keesey), Yan Wong from
illustration by Charles Orbigny, Stanton F. Fink (vectorized by T.
Michael Keesey), Noah Schlottman, photo by Adam G. Clause, Joe Schneid
(vectorized by T. Michael Keesey), Caroline Harding, MAF (vectorized by
T. Michael Keesey), Florian Pfaff, Luc Viatour (source photo) and
Andreas Plank, Hans Hillewaert, Mo Hassan, Esme Ashe-Jepson, Heinrich
Harder (vectorized by William Gearty), Iain Reid, New York Zoological
Society, Katie S. Collins, Yan Wong (vectorization) from 1873
illustration, Richard Lampitt, Jeremy Young / NHM (vectorization by Yan
Wong), H. Filhol (vectorized by T. Michael Keesey), Carlos
Cano-Barbacil, Jon M Laurent, Bruno C. Vellutini, Taenadoman, Smokeybjb,
Meliponicultor Itaymbere, Joseph Wolf, 1863 (vectorization by Dinah
Challen), Mike Hanson, Dori <dori@merr.info> (source photo) and Nevit
Dilmen, Mykle Hoban, Lafage, Matthew E. Clapham, Tod Robbins, nicubunu,
Crystal Maier, Diana Pomeroy, Original drawing by Dmitry Bogdanov,
vectorized by Roberto Díaz Sibaja, Michael P. Taylor, Christopher Watson
(photo) and T. Michael Keesey (vectorization), Ben Moon, Emily Jane
McTavish, from
<http://en.wikipedia.org/wiki/File:Coccolithus_pelagicus.jpg>, Jaime
Headden, modified by T. Michael Keesey, Nicolas Huet le Jeune and
Jean-Gabriel Prêtre (vectorized by T. Michael Keesey), xgirouxb, Tracy
A. Heath, Caleb M. Brown, Yusan Yang, Nick Schooler, Matt Martyniuk, A.
H. Baldwin (vectorized by T. Michael Keesey), Frank Förster (based on a
picture by Jerry Kirkhart; modified by T. Michael Keesey), Darren Naish
(vectorized by T. Michael Keesey), B. Duygu Özpolat, Michael Scroggie,
Fernando Campos De Domenico, LeonardoG (photography) and T. Michael
Keesey (vectorization), Juan Carlos Jerí, John Gould (vectorized by T.
Michael Keesey), Qiang Ou, Lankester Edwin Ray (vectorized by T. Michael
Keesey), Trond R. Oskars, Вальдимар (vectorized by T. Michael Keesey),
Michael Scroggie, from original photograph by John Bettaso, USFWS
(original photograph in public domain)., Ghedoghedo (vectorized by T.
Michael Keesey), M Kolmann, Adam Stuart Smith (vectorized by T. Michael
Keesey), Kevin Sánchez, Thibaut Brunet, Noah Schlottman, photo by Hans
De Blauwe, Hans Hillewaert (vectorized by T. Michael Keesey), Felix Vaux
and Steven A. Trewick, Noah Schlottman, photo from Moorea Biocode,
Collin Gross, Robert Bruce Horsfall (vectorized by William Gearty), Ralf
Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T.
Michael Keesey), Mali’o Kodis, image from the “Proceedings of the
Zoological Society of London”, Oren Peles / vectorized by Yan Wong,
Conty, T. Michael Keesey (vectorization) and Larry Loos (photography),
Frederick William Frohawk (vectorized by T. Michael Keesey), Daniel
Stadtmauer, Nina Skinner, Courtney Rockenbach, Diego Fontaneto,
Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone,
Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael
Keesey), Ghedo (vectorized by T. Michael Keesey), Lily Hughes,
S.Martini, Jan Sevcik (photo), John E. McCormack, Michael G. Harvey,
Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T.
Brumfield & T. Michael Keesey, DW Bapst (modified from Bates et al.,
2005), Hugo Gruson, Yan Wong from photo by Gyik Toma, Matus Valach,
Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts,
Catherine A. Forster, Joshua A. Smith, Alan L. Titus, Martin Kevil,
Apokryltaros (vectorized by T. Michael Keesey), (after Spotila 2004),
Chase Brownstein, M. Garfield & K. Anderson (modified by T. Michael
Keesey), Paul O. Lewis, U.S. National Park Service (vectorized by
William Gearty), Abraão Leite, Kanako Bessho-Uehara, Brockhaus and
Efron, Davidson Sodré, Riccardo Percudani, Manabu Bessho-Uehara, Joshua
Fowler, Maxwell Lefroy (vectorized by T. Michael Keesey), Lauren
Anderson, Fernando Carezzano, Mario Quevedo, Kent Elson Sorgon, Didier
Descouens (vectorized by T. Michael Keesey), T. Michael Keesey (after
Monika Betley), Brad McFeeters (vectorized by T. Michael Keesey), Alexis
Simon, Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J.
Bartley (silhouette)

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    158.015605 |    510.863473 | Erika Schumacher                                                                                                                                                      |
|   2 |    885.731492 |    142.771569 | Audrey Ely                                                                                                                                                            |
|   3 |    721.964485 |    425.512347 | T. Michael Keesey                                                                                                                                                     |
|   4 |    169.011282 |    438.531350 | Zimices                                                                                                                                                               |
|   5 |    388.072082 |     92.474752 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
|   6 |    105.763545 |    374.503201 | Sharon Wegner-Larsen                                                                                                                                                  |
|   7 |    550.857742 |    112.238140 | Jagged Fang Designs                                                                                                                                                   |
|   8 |    325.747354 |    342.556700 | NA                                                                                                                                                                    |
|   9 |    588.302496 |    283.752887 | Dmitry Bogdanov                                                                                                                                                       |
|  10 |    469.570311 |    497.381505 | Cyril Matthey-Doret, adapted from Bernard Chaubet                                                                                                                     |
|  11 |    581.835449 |    455.241803 | L. Shyamal                                                                                                                                                            |
|  12 |    954.520160 |    311.398512 | Liftarn                                                                                                                                                               |
|  13 |    671.759646 |    143.898067 | Jagged Fang Designs                                                                                                                                                   |
|  14 |    950.465321 |    458.251869 | Richard J. Harris                                                                                                                                                     |
|  15 |    279.610670 |    722.449933 | Pete Buchholz                                                                                                                                                         |
|  16 |    314.868751 |    202.890076 | Matt Dempsey                                                                                                                                                          |
|  17 |    170.708630 |    773.344544 | Shyamal                                                                                                                                                               |
|  18 |    223.192905 |    129.706937 | Matt Celeskey                                                                                                                                                         |
|  19 |    783.659272 |     49.525550 | T. Michael Keesey                                                                                                                                                     |
|  20 |    402.987916 |    634.762960 | NA                                                                                                                                                                    |
|  21 |    519.704809 |    707.949541 | Steven Traver                                                                                                                                                         |
|  22 |    846.675901 |    729.915183 | Margot Michaud                                                                                                                                                        |
|  23 |    734.615363 |    708.036737 | Margot Michaud                                                                                                                                                        |
|  24 |    455.797515 |    214.736255 | Birgit Lang                                                                                                                                                           |
|  25 |    784.283665 |    502.738690 | Andy Wilson                                                                                                                                                           |
|  26 |    707.255367 |    210.153439 | Melissa Broussard                                                                                                                                                     |
|  27 |    149.389618 |    674.776833 | Milton Tan                                                                                                                                                            |
|  28 |     86.149190 |     67.811965 | NA                                                                                                                                                                    |
|  29 |    845.723422 |    416.485910 | Cesar Julian                                                                                                                                                          |
|  30 |    143.270178 |    191.715769 | Andy Wilson                                                                                                                                                           |
|  31 |    417.897815 |    740.529415 | Michele Tobias                                                                                                                                                        |
|  32 |    864.977110 |    492.948111 | T. Michael Keesey                                                                                                                                                     |
|  33 |    209.440308 |    564.574034 | Sarah Werning                                                                                                                                                         |
|  34 |    633.184536 |    383.803999 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                          |
|  35 |    655.582744 |    574.553254 | Jose Carlos Arenas-Monroy                                                                                                                                             |
|  36 |    685.854793 |    299.776180 | Ferran Sayol                                                                                                                                                          |
|  37 |    284.459356 |    491.598066 | Gareth Monger                                                                                                                                                         |
|  38 |    625.973463 |     48.668687 | Kamil S. Jaron                                                                                                                                                        |
|  39 |    524.609996 |    630.564740 | Zimices                                                                                                                                                               |
|  40 |    299.304332 |    661.339344 | Margot Michaud                                                                                                                                                        |
|  41 |    560.350238 |    142.404174 | Yan Wong                                                                                                                                                              |
|  42 |    948.656634 |    663.871943 | Zimices                                                                                                                                                               |
|  43 |    463.157278 |     47.338126 | Ignacio Contreras                                                                                                                                                     |
|  44 |    816.074158 |    610.176497 | Lukasiniho                                                                                                                                                            |
|  45 |    306.234416 |    273.003686 | Kamil S. Jaron                                                                                                                                                        |
|  46 |     48.423558 |    600.872331 | DFoidl (vectorized by T. Michael Keesey)                                                                                                                              |
|  47 |    828.943112 |    269.921052 | Ferran Sayol                                                                                                                                                          |
|  48 |    284.921502 |    421.610090 | Jordan Mallon (vectorized by T. Michael Keesey)                                                                                                                       |
|  49 |    791.352432 |    170.969319 | T. Michael Keesey                                                                                                                                                     |
|  50 |    393.163994 |    152.874811 | Gareth Monger                                                                                                                                                         |
|  51 |    956.746196 |    588.319898 | Lindberg (vectorized by T. Michael Keesey)                                                                                                                            |
|  52 |    222.842170 |     38.905387 | Jagged Fang Designs                                                                                                                                                   |
|  53 |    458.757549 |    368.366947 | Andrew A. Farke                                                                                                                                                       |
|  54 |     45.692418 |    196.347367 | Rebecca Groom                                                                                                                                                         |
|  55 |    132.623425 |    277.980032 | Ferran Sayol                                                                                                                                                          |
|  56 |    896.624888 |     70.710679 | Chuanixn Yu                                                                                                                                                           |
|  57 |    636.389297 |    647.446898 | Milton Tan                                                                                                                                                            |
|  58 |    705.269685 |     99.155300 | Scott Hartman                                                                                                                                                         |
|  59 |    429.516232 |    298.774273 | NA                                                                                                                                                                    |
|  60 |    587.798789 |    204.763077 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  61 |     71.337118 |    736.419197 | Cesar Julian                                                                                                                                                          |
|  62 |    962.512108 |    407.864953 | Shyamal                                                                                                                                                               |
|  63 |     64.771769 |    513.617875 | Hans Hillewaert (photo) and T. Michael Keesey (vectorization)                                                                                                         |
|  64 |    944.035824 |    756.139047 | Charles R. Knight (vectorized by T. Michael Keesey)                                                                                                                   |
|  65 |    683.925365 |    781.473718 | Scott Hartman                                                                                                                                                         |
|  66 |    832.523201 |    340.184475 | Margot Michaud                                                                                                                                                        |
|  67 |    929.564571 |    202.800300 | Ville Koistinen (vectorized by T. Michael Keesey)                                                                                                                     |
|  68 |    219.196371 |    244.825382 | DW Bapst, modified from Figure 1 of Belanger (2011, PALAIOS).                                                                                                         |
|  69 |    344.872112 |    375.447879 | (unknown)                                                                                                                                                             |
|  70 |    199.416317 |    619.561884 | Gareth Monger                                                                                                                                                         |
|  71 |    570.386187 |    735.635587 | Gareth Monger                                                                                                                                                         |
|  72 |    887.553385 |     17.586102 | Cesar Julian                                                                                                                                                          |
|  73 |    435.674305 |     28.005035 | Ignacio Contreras                                                                                                                                                     |
|  74 |    477.939992 |    118.055261 | Yan Wong                                                                                                                                                              |
|  75 |    352.439846 |     70.852115 | Scott Hartman                                                                                                                                                         |
|  76 |    666.234937 |    497.592673 | Scott Hartman                                                                                                                                                         |
|  77 |    646.312213 |    439.742605 | Jagged Fang Designs                                                                                                                                                   |
|  78 |    130.163381 |     81.202081 | Emily Willoughby                                                                                                                                                      |
|  79 |    676.562784 |    689.717274 | Jagged Fang Designs                                                                                                                                                   |
|  80 |    404.175401 |    690.684106 | Maija Karala                                                                                                                                                          |
|  81 |    712.005252 |    744.427149 | Michelle Site                                                                                                                                                         |
|  82 |    565.061410 |    762.804933 | Noah Schlottman                                                                                                                                                       |
|  83 |    683.211249 |    522.345135 | Original drawing by Nobu Tamura, vectorized by Roberto Díaz Sibaja                                                                                                    |
|  84 |    598.448649 |    519.294066 | Matt Crook                                                                                                                                                            |
|  85 |     39.644606 |     18.622536 | Gareth Monger                                                                                                                                                         |
|  86 |    751.993491 |    776.634357 | Elisabeth Östman                                                                                                                                                      |
|  87 |    664.388302 |    253.790012 | Oscar Sanisidro                                                                                                                                                       |
|  88 |    985.621891 |     62.925942 | Ferran Sayol                                                                                                                                                          |
|  89 |    492.124815 |    312.248715 | Zimices                                                                                                                                                               |
|  90 |    615.361227 |     73.556793 | Maija Karala                                                                                                                                                          |
|  91 |     96.726718 |    650.540760 | CNZdenek                                                                                                                                                              |
|  92 |    659.461520 |     12.492668 | Andy Wilson                                                                                                                                                           |
|  93 |    170.044693 |    584.287461 | Francesco Veronesi (vectorized by T. Michael Keesey)                                                                                                                  |
|  94 |     90.344789 |    149.433009 | Pete Buchholz                                                                                                                                                         |
|  95 |    527.110699 |    344.996138 | Margot Michaud                                                                                                                                                        |
|  96 |    223.886123 |    790.665793 | Maija Karala                                                                                                                                                          |
|  97 |    999.391817 |    767.551168 | Markus A. Grohme                                                                                                                                                      |
|  98 |    921.770206 |    709.900654 | Margot Michaud                                                                                                                                                        |
|  99 |    326.956292 |    743.015731 | John Conway                                                                                                                                                           |
| 100 |    306.558491 |    125.939149 | Margot Michaud                                                                                                                                                        |
| 101 |    514.969441 |    445.916423 | Andy Wilson                                                                                                                                                           |
| 102 |    965.729787 |    540.893776 | C. Camilo Julián-Caballero                                                                                                                                            |
| 103 |     84.775686 |    333.814122 | Felix Vaux                                                                                                                                                            |
| 104 |    712.901269 |    659.433626 | NA                                                                                                                                                                    |
| 105 |   1004.319243 |     71.912587 | Terpsichores                                                                                                                                                          |
| 106 |    950.218068 |    373.577589 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 107 |    751.601243 |    112.896817 | Matt Crook                                                                                                                                                            |
| 108 |    313.066698 |    766.952719 | Ferran Sayol                                                                                                                                                          |
| 109 |    726.476125 |    553.129984 | Markus A. Grohme                                                                                                                                                      |
| 110 |    246.296043 |     62.366006 | Ignacio Contreras                                                                                                                                                     |
| 111 |     80.703367 |    779.611690 | Jiekun He                                                                                                                                                             |
| 112 |    543.315742 |     75.893436 | Kanchi Nanjo                                                                                                                                                          |
| 113 |     78.551866 |    132.258799 | Dexter R. Mardis                                                                                                                                                      |
| 114 |    256.105139 |    584.366344 | Arthur S. Brum                                                                                                                                                        |
| 115 |    612.340432 |    228.561483 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 116 |    276.798916 |    570.483780 | CNZdenek                                                                                                                                                              |
| 117 |     14.952664 |    487.931143 | Pete Buchholz                                                                                                                                                         |
| 118 |    402.635590 |    573.828780 | Steven Traver                                                                                                                                                         |
| 119 |    860.593675 |    196.502322 | Chris huh                                                                                                                                                             |
| 120 |    531.115318 |    254.544432 | Espen Horn (model; vectorized by T. Michael Keesey from a photo by H. Zell)                                                                                           |
| 121 |    353.306388 |    268.652173 | Gareth Monger                                                                                                                                                         |
| 122 |    453.273115 |     63.290545 | Almandine (vectorized by T. Michael Keesey)                                                                                                                           |
| 123 |    487.764396 |    595.829418 | Ignacio Contreras                                                                                                                                                     |
| 124 |    880.648616 |    396.603776 | Gareth Monger                                                                                                                                                         |
| 125 |    261.976361 |     22.481665 | T. Michael Keesey                                                                                                                                                     |
| 126 |    628.722946 |    715.076730 | Birgit Lang                                                                                                                                                           |
| 127 |    604.178590 |    414.974328 | Roberto Díaz Sibaja                                                                                                                                                   |
| 128 |    356.461921 |    521.195031 | Harold N Eyster                                                                                                                                                       |
| 129 |    810.763780 |    538.447040 | Keith Murdock (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey         |
| 130 |    824.298887 |    147.971039 | T. Michael Keesey (after Colin M. L. Burnett)                                                                                                                         |
| 131 |    109.845631 |    620.670354 | Jagged Fang Designs                                                                                                                                                   |
| 132 |     13.460933 |    188.394195 | www.studiospectre.com                                                                                                                                                 |
| 133 |    651.081306 |     74.192697 | Jack Mayer Wood                                                                                                                                                       |
| 134 |     96.079651 |    307.066718 | Scott Reid                                                                                                                                                            |
| 135 |    993.541053 |    206.426366 | Steven Traver                                                                                                                                                         |
| 136 |    971.855486 |    698.899223 | Andy Wilson                                                                                                                                                           |
| 137 |    960.991983 |    206.254231 | Michelle Site                                                                                                                                                         |
| 138 |    351.194388 |    216.873424 | Lukas Panzarin                                                                                                                                                        |
| 139 |    889.714057 |    248.153379 | Paul Baker (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey            |
| 140 |    770.125027 |    333.383406 | J Levin W (illustration) and T. Michael Keesey (vectorization)                                                                                                        |
| 141 |    508.141057 |    380.812808 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 142 |    969.402838 |    102.255529 | Zimices                                                                                                                                                               |
| 143 |    308.081173 |    533.130110 | Margot Michaud                                                                                                                                                        |
| 144 |    617.564692 |    310.392228 | Oscar Sanisidro                                                                                                                                                       |
| 145 |    149.866380 |    249.753848 | Tasman Dixon                                                                                                                                                          |
| 146 |    504.104698 |    338.935616 | Marmelad                                                                                                                                                              |
| 147 |    520.159661 |    562.415822 | Ingo Braasch                                                                                                                                                          |
| 148 |    919.326918 |    544.378113 | Zimices                                                                                                                                                               |
| 149 |    391.502883 |     10.201923 | Matt Crook                                                                                                                                                            |
| 150 |    426.846157 |    108.206237 | Noah Schlottman, photo by Museum of Geology, University of Tartu                                                                                                      |
| 151 |    740.624523 |    660.004876 | T. Michael Keesey                                                                                                                                                     |
| 152 |    993.849488 |    458.944580 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 153 |    788.984244 |    354.594604 | DW Bapst (modified from Bulman, 1970)                                                                                                                                 |
| 154 |     26.492452 |    786.625908 | Gareth Monger                                                                                                                                                         |
| 155 |    335.738555 |    448.660894 | Chris huh                                                                                                                                                             |
| 156 |    126.705579 |    574.382727 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 157 |    843.941843 |    556.249282 | Zimices                                                                                                                                                               |
| 158 |    789.286123 |    660.593629 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 159 |    545.255699 |    145.459625 | Markus A. Grohme                                                                                                                                                      |
| 160 |    640.596755 |    238.017478 | Gareth Monger                                                                                                                                                         |
| 161 |    833.992491 |    217.720781 | Andrew A. Farke                                                                                                                                                       |
| 162 |    286.170759 |    752.577179 | Ignacio Contreras                                                                                                                                                     |
| 163 |     13.161672 |    786.119602 | Emily Willoughby                                                                                                                                                      |
| 164 |    642.021488 |    476.679515 | Chris huh                                                                                                                                                             |
| 165 |     27.501814 |    456.484321 | Robert Hering                                                                                                                                                         |
| 166 |    355.131508 |    771.075228 | Michelle Site                                                                                                                                                         |
| 167 |    390.270392 |    593.580100 | Noah Schlottman, photo by Carol Cummings                                                                                                                              |
| 168 |    822.825582 |    782.884047 | Noah Schlottman, photo from Casey Dunn                                                                                                                                |
| 169 |    581.816254 |    716.502876 | Julio Garza                                                                                                                                                           |
| 170 |     62.850846 |    288.638557 | wsnaccad                                                                                                                                                              |
| 171 |    530.050382 |    395.343175 | Jack Mayer Wood                                                                                                                                                       |
| 172 |    289.571752 |    455.157975 | Zimices                                                                                                                                                               |
| 173 |    683.600709 |     26.930809 | Gopal Murali                                                                                                                                                          |
| 174 |    132.026798 |    789.542990 | Chris huh                                                                                                                                                             |
| 175 |    453.310439 |    301.411207 | Markus A. Grohme                                                                                                                                                      |
| 176 |    933.213027 |    632.546011 | Jagged Fang Designs                                                                                                                                                   |
| 177 |    794.814664 |    695.331434 | Frank Förster (based on a picture by Hans Hillewaert)                                                                                                                 |
| 178 |    949.380543 |    566.360661 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 179 |    250.332791 |    178.532806 | T. Michael Keesey                                                                                                                                                     |
| 180 |    925.892810 |    464.371363 | NA                                                                                                                                                                    |
| 181 |    524.192031 |     83.544469 | Steven Traver                                                                                                                                                         |
| 182 |    467.452338 |    339.291757 | NA                                                                                                                                                                    |
| 183 |    552.625456 |    527.104282 | Julio Garza                                                                                                                                                           |
| 184 |    303.041136 |    610.815763 | I. Geoffroy Saint-Hilaire (vectorized by T. Michael Keesey)                                                                                                           |
| 185 |    307.199948 |    580.949783 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 186 |    108.454649 |    255.178875 | Scott Hartman                                                                                                                                                         |
| 187 |    799.345805 |    301.579117 | Steven Coombs                                                                                                                                                         |
| 188 |    880.746466 |    143.403252 | NASA                                                                                                                                                                  |
| 189 |    772.809999 |    235.527037 | Zsoldos Márton (vectorized by T. Michael Keesey)                                                                                                                      |
| 190 |    565.403550 |    251.441075 | Jagged Fang Designs                                                                                                                                                   |
| 191 |     42.676979 |     68.559704 | Scott Hartman                                                                                                                                                         |
| 192 |    220.234901 |    353.387244 | Jagged Fang Designs                                                                                                                                                   |
| 193 |    204.970615 |    167.108537 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 194 |    624.379895 |    788.127857 | Zimices                                                                                                                                                               |
| 195 |    878.268636 |    196.669300 | Christoph Schomburg                                                                                                                                                   |
| 196 |   1009.757891 |    368.480591 | Matt Crook                                                                                                                                                            |
| 197 |    166.571623 |    723.676456 | Harold N Eyster                                                                                                                                                       |
| 198 |    564.624464 |    339.247132 | Steven Traver                                                                                                                                                         |
| 199 |    367.322162 |    206.159989 | NA                                                                                                                                                                    |
| 200 |    291.878436 |     26.815427 | Zimices                                                                                                                                                               |
| 201 |    354.458924 |    452.089702 | T. Michael Keesey                                                                                                                                                     |
| 202 |    318.782079 |    554.429652 | Kailah Thorn & Mark Hutchinson                                                                                                                                        |
| 203 |    445.067525 |    119.411249 | Gareth Monger                                                                                                                                                         |
| 204 |    920.920424 |    116.502911 | Julien Louys                                                                                                                                                          |
| 205 |    888.983264 |    764.884237 | C. Camilo Julián-Caballero                                                                                                                                            |
| 206 |    142.484883 |    555.144155 | Alex Slavenko                                                                                                                                                         |
| 207 |    808.307638 |    126.034457 | Gareth Monger                                                                                                                                                         |
| 208 |    952.431958 |    689.515296 | Melissa Broussard                                                                                                                                                     |
| 209 |    937.554998 |    172.386155 | Beth Reinke                                                                                                                                                           |
| 210 |    835.491273 |    460.556780 | Maija Karala                                                                                                                                                          |
| 211 |    743.854195 |    566.640683 | Josep Marti Solans                                                                                                                                                    |
| 212 |    674.583368 |    400.681765 | Steven Traver                                                                                                                                                         |
| 213 |    696.745871 |    466.034743 | Smokeybjb, vectorized by Zimices                                                                                                                                      |
| 214 |    303.025936 |    699.648586 | Neil Kelley                                                                                                                                                           |
| 215 |     29.376070 |    713.350423 | Jonathan Lawley                                                                                                                                                       |
| 216 |    914.432910 |    508.198267 | Zimices                                                                                                                                                               |
| 217 |    284.202708 |    788.189001 | Eduard Solà (vectorized by T. Michael Keesey)                                                                                                                         |
| 218 |    709.556078 |    151.260780 | Zimices                                                                                                                                                               |
| 219 |    771.185503 |    432.152090 | Gareth Monger                                                                                                                                                         |
| 220 |    324.018692 |    570.782225 | Gareth Monger                                                                                                                                                         |
| 221 |    158.912210 |    389.107252 | Ferran Sayol                                                                                                                                                          |
| 222 |    746.202011 |    386.435925 | terngirl                                                                                                                                                              |
| 223 |     44.250633 |    114.355228 | Michael B. H. (vectorized by T. Michael Keesey)                                                                                                                       |
| 224 |    547.317630 |    548.015662 | Harold N Eyster                                                                                                                                                       |
| 225 |     28.769831 |     14.925550 | Manabu Sakamoto                                                                                                                                                       |
| 226 |    195.951215 |    462.403945 | Xavier Giroux-Bougard                                                                                                                                                 |
| 227 |    829.826698 |    442.282743 | Chloé Schmidt                                                                                                                                                         |
| 228 |    593.519858 |    235.890297 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 229 |    140.174022 |    717.041474 | NA                                                                                                                                                                    |
| 230 |    628.471317 |    102.993952 | Felix Vaux                                                                                                                                                            |
| 231 |    520.801011 |    662.871205 | Zimices                                                                                                                                                               |
| 232 |    316.909303 |    596.513128 | Zimices                                                                                                                                                               |
| 233 |    757.028737 |    642.120772 | Mathilde Cordellier                                                                                                                                                   |
| 234 |    208.967027 |    702.064946 | Zimices                                                                                                                                                               |
| 235 |     10.453609 |    433.876934 | Zachary Quigley                                                                                                                                                       |
| 236 |    298.088250 |    553.812778 | Michelle Site                                                                                                                                                         |
| 237 |    414.953991 |    709.749396 | Zimices                                                                                                                                                               |
| 238 |    638.888562 |    282.842567 | terngirl                                                                                                                                                              |
| 239 |    488.371536 |    745.018326 | Milton Tan                                                                                                                                                            |
| 240 |    266.350974 |    757.337210 | Zimices                                                                                                                                                               |
| 241 |    871.010784 |    573.815988 | Marie-Aimée Allard                                                                                                                                                    |
| 242 |    870.068843 |    169.395411 | Zimices                                                                                                                                                               |
| 243 |    312.238252 |    169.560281 | Steven Traver                                                                                                                                                         |
| 244 |    754.022710 |    233.509923 | Matt Crook                                                                                                                                                            |
| 245 |     66.473484 |    761.737257 | Jonathan Lawley                                                                                                                                                       |
| 246 |    661.842285 |    392.594402 | L. Shyamal                                                                                                                                                            |
| 247 |   1016.379546 |    153.320904 | Chris Jennings (Risiatto)                                                                                                                                             |
| 248 |    367.979354 |    382.092084 | Felix Vaux                                                                                                                                                            |
| 249 |    608.335363 |    608.956348 | Marie Russell                                                                                                                                                         |
| 250 |    965.093803 |    226.032898 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                          |
| 251 |    576.646011 |     10.846887 | Matt Crook                                                                                                                                                            |
| 252 |    609.548737 |    240.899210 | Kai R. Caspar                                                                                                                                                         |
| 253 |    593.779311 |    615.077652 | Ferran Sayol                                                                                                                                                          |
| 254 |    324.627697 |    540.229489 | Ludwik Gąsiorowski                                                                                                                                                    |
| 255 |    154.849071 |     12.275391 | Nobu Tamura, modified by Andrew A. Farke                                                                                                                              |
| 256 |    547.617306 |    480.680550 | Ferran Sayol                                                                                                                                                          |
| 257 |    221.756517 |    690.020700 | Zimices                                                                                                                                                               |
| 258 |    322.318774 |    229.839940 | Martin R. Smith                                                                                                                                                       |
| 259 |    706.630172 |    352.912583 | Scott Hartman                                                                                                                                                         |
| 260 |    495.421262 |    585.067755 | Scott Hartman                                                                                                                                                         |
| 261 |    865.327718 |    773.399117 | Lukasiniho                                                                                                                                                            |
| 262 |    851.766106 |    252.961337 | Andy Wilson                                                                                                                                                           |
| 263 |    869.877013 |    741.366605 | Birgit Lang                                                                                                                                                           |
| 264 |    218.005870 |    678.996134 | Erika Schumacher                                                                                                                                                      |
| 265 |    497.860879 |    136.112821 | Matt Crook                                                                                                                                                            |
| 266 |    830.988215 |    121.162717 | Zimices                                                                                                                                                               |
| 267 |    351.165647 |    318.528693 | Zimices                                                                                                                                                               |
| 268 |    442.222604 |     96.020306 | Tauana J. Cunha                                                                                                                                                       |
| 269 |    124.704218 |    323.287717 | Kai R. Caspar                                                                                                                                                         |
| 270 |    211.005196 |     81.976614 | T. Michael Keesey                                                                                                                                                     |
| 271 |    601.439791 |    773.992137 | Steven Traver                                                                                                                                                         |
| 272 |    359.302830 |    782.696445 | Jagged Fang Designs                                                                                                                                                   |
| 273 |    494.420835 |    778.478859 | NA                                                                                                                                                                    |
| 274 |    634.082012 |    158.377372 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                           |
| 275 |    992.319165 |    229.846348 | Alexandre Vong                                                                                                                                                        |
| 276 |    394.886113 |    259.474648 | Scott Hartman                                                                                                                                                         |
| 277 |    654.217746 |    472.025255 | Yan Wong                                                                                                                                                              |
| 278 |    209.433843 |    375.298049 | Jagged Fang Designs                                                                                                                                                   |
| 279 |    891.099575 |    370.269420 | Matt Crook                                                                                                                                                            |
| 280 |    683.146747 |    439.980844 | Maija Karala                                                                                                                                                          |
| 281 |    928.025714 |    724.075290 | Scott Hartman                                                                                                                                                         |
| 282 |    673.031538 |    471.309987 | Beth Reinke                                                                                                                                                           |
| 283 |    909.503920 |    781.776758 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 284 |    996.877199 |    345.432709 | Xavier Giroux-Bougard                                                                                                                                                 |
| 285 |    278.470569 |     67.885679 | Jake Warner                                                                                                                                                           |
| 286 |    398.996135 |    186.621940 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 287 |    343.739702 |    112.726887 | Chris huh                                                                                                                                                             |
| 288 |    361.412950 |    475.947940 | Tauana J. Cunha                                                                                                                                                       |
| 289 |    277.094131 |    601.641439 | Joanna Wolfe                                                                                                                                                          |
| 290 |    980.234528 |    295.833884 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 291 |     19.842869 |    213.886932 | Milton Tan                                                                                                                                                            |
| 292 |    562.521940 |     32.112537 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 293 |    800.353999 |    382.652371 | Chris huh                                                                                                                                                             |
| 294 |    947.305071 |    140.052218 | Jonathan Wells                                                                                                                                                        |
| 295 |     90.802062 |    161.987960 | Margot Michaud                                                                                                                                                        |
| 296 |    657.139598 |    228.516211 | Sharon Wegner-Larsen                                                                                                                                                  |
| 297 |    748.200727 |    308.704948 | Estelle Bourdon                                                                                                                                                       |
| 298 |    798.316633 |    778.662112 | Andrew A. Farke                                                                                                                                                       |
| 299 |    541.858192 |      6.495603 | Ferran Sayol                                                                                                                                                          |
| 300 |    264.381400 |    231.115932 | Renato de Carvalho Ferreira                                                                                                                                           |
| 301 |    827.577307 |    205.855178 | Scott Hartman                                                                                                                                                         |
| 302 |    582.700595 |    678.418734 | Richard Ruggiero, vectorized by Zimices                                                                                                                               |
| 303 |    878.746279 |    669.087631 | Jagged Fang Designs                                                                                                                                                   |
| 304 |    133.531951 |    465.839168 | Anthony Caravaggi                                                                                                                                                     |
| 305 |    141.100889 |    400.757753 | Christina N. Hodson                                                                                                                                                   |
| 306 |     55.056744 |    682.538504 | Martien Brand (original photo), Renato Santos (vector silhouette)                                                                                                     |
| 307 |    235.634127 |     84.137789 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 308 |    465.987013 |    727.161067 | Sharon Wegner-Larsen                                                                                                                                                  |
| 309 |    792.652955 |     85.981861 | Margot Michaud                                                                                                                                                        |
| 310 |    670.857999 |    736.693950 | Dmitry Bogdanov                                                                                                                                                       |
| 311 |    342.885563 |    137.240055 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 312 |    547.618477 |    328.975774 | Andrew A. Farke                                                                                                                                                       |
| 313 |    257.638702 |    781.508659 | Rebecca Groom                                                                                                                                                         |
| 314 |     70.475504 |    686.630166 | Andy Wilson                                                                                                                                                           |
| 315 |    778.053568 |     96.420744 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                           |
| 316 |    319.075290 |    455.989171 | Scott Hartman                                                                                                                                                         |
| 317 |    885.961265 |    592.741160 | Scott Reid                                                                                                                                                            |
| 318 |    712.797668 |     48.877584 | Jaime Headden                                                                                                                                                         |
| 319 |    753.225935 |    602.299602 | Dean Schnabel                                                                                                                                                         |
| 320 |    827.542544 |    685.371445 | Maxime Dahirel                                                                                                                                                        |
| 321 |    248.972417 |    596.104017 | Jagged Fang Designs                                                                                                                                                   |
| 322 |    860.658481 |    678.460682 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 323 |     11.103860 |    754.202600 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 324 |     35.091137 |    531.041207 | NA                                                                                                                                                                    |
| 325 |    598.662395 |     87.466780 | Steven Traver                                                                                                                                                         |
| 326 |      6.740056 |    702.249381 | Kristina Gagalova                                                                                                                                                     |
| 327 |   1000.682412 |    160.459821 | Zimices                                                                                                                                                               |
| 328 |    633.489751 |    752.125842 | T. Michael Keesey                                                                                                                                                     |
| 329 |    381.694698 |    499.236537 | Jagged Fang Designs                                                                                                                                                   |
| 330 |    945.006553 |      4.760965 | Zimices                                                                                                                                                               |
| 331 |    128.137714 |    345.861253 | Ingo Braasch                                                                                                                                                          |
| 332 |    411.681653 |    316.118989 | Steven Haddock • Jellywatch.org                                                                                                                                       |
| 333 |    747.900636 |    543.263446 | Harold N Eyster                                                                                                                                                       |
| 334 |    967.258961 |    193.730511 | FunkMonk                                                                                                                                                              |
| 335 |    414.365105 |    592.868019 | Joanna Wolfe                                                                                                                                                          |
| 336 |    383.973793 |    191.564059 | Margot Michaud                                                                                                                                                        |
| 337 |     16.741101 |    640.151445 | Margot Michaud                                                                                                                                                        |
| 338 |   1008.796600 |     41.118831 | Zimices                                                                                                                                                               |
| 339 |    508.983917 |    548.502184 | Yan Wong                                                                                                                                                              |
| 340 |    613.885853 |    503.393861 | Jagged Fang Designs                                                                                                                                                   |
| 341 |    763.796959 |    755.786405 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 342 |    381.666032 |    716.665758 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 343 |    505.291790 |    287.783771 | Margot Michaud                                                                                                                                                        |
| 344 |    666.827421 |    717.227604 | Mathew Wedel                                                                                                                                                          |
| 345 |    999.771661 |    384.767462 | Noah Schlottman                                                                                                                                                       |
| 346 |    293.898078 |    240.263219 | Christine Axon                                                                                                                                                        |
| 347 |    899.848418 |    217.361838 | Milton Tan                                                                                                                                                            |
| 348 |    891.750078 |    624.627886 | T. Michael Keesey (after Joseph Wolf)                                                                                                                                 |
| 349 |    628.372595 |     15.503516 | Xavier Giroux-Bougard                                                                                                                                                 |
| 350 |    466.624369 |    293.241209 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 351 |    275.144595 |    155.107317 | Armin Reindl                                                                                                                                                          |
| 352 |    573.919842 |    174.782501 | Samanta Orellana                                                                                                                                                      |
| 353 |    545.506917 |    171.283697 | Michael Ströck (vectorized by T. Michael Keesey)                                                                                                                      |
| 354 |    331.889282 |    428.835088 | Steven Traver                                                                                                                                                         |
| 355 |    825.519352 |    482.426569 | Birgit Lang                                                                                                                                                           |
| 356 |    250.918812 |    693.077499 | Mathilde Cordellier                                                                                                                                                   |
| 357 |    333.383444 |    732.164850 | NA                                                                                                                                                                    |
| 358 |    272.507842 |    779.548072 | Zimices                                                                                                                                                               |
| 359 |    746.033336 |    441.793131 | Mathieu Pélissié                                                                                                                                                      |
| 360 |    974.835308 |    500.721490 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 361 |    351.787764 |    592.939704 | NA                                                                                                                                                                    |
| 362 |    769.535837 |    415.156286 | Scott Hartman                                                                                                                                                         |
| 363 |    471.486672 |    392.968299 | Jagged Fang Designs                                                                                                                                                   |
| 364 |    245.445670 |     88.762468 | Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org)                                                                          |
| 365 |    716.315948 |    628.699352 | Markus A. Grohme                                                                                                                                                      |
| 366 |    352.868110 |    552.023285 | Zimices, based in Mauricio Antón skeletal                                                                                                                             |
| 367 |    148.494781 |     33.424359 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 368 |    165.917687 |     88.031243 | Zimices                                                                                                                                                               |
| 369 |    274.255059 |    555.723856 | Tony Ayling                                                                                                                                                           |
| 370 |    705.987883 |     12.884405 | Gareth Monger                                                                                                                                                         |
| 371 |    289.013089 |    625.898672 | André Karwath (vectorized by T. Michael Keesey)                                                                                                                       |
| 372 |    349.278661 |    304.988384 | Birgit Lang                                                                                                                                                           |
| 373 |    456.073345 |    779.817267 | Zimices                                                                                                                                                               |
| 374 |    520.373210 |    723.222081 | Charles R. Knight, vectorized by Zimices                                                                                                                              |
| 375 |    897.357743 |    292.159749 | Chris huh                                                                                                                                                             |
| 376 |    951.787884 |    121.304044 | T. Michael Keesey                                                                                                                                                     |
| 377 |   1001.770805 |    717.790426 | Christoph Schomburg                                                                                                                                                   |
| 378 |    323.215327 |    620.584278 | Matt Crook                                                                                                                                                            |
| 379 |    528.864704 |    407.180880 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 380 |     30.516869 |    763.511752 | Geoff Shaw                                                                                                                                                            |
| 381 |    966.995314 |    381.196459 | Gareth Monger                                                                                                                                                         |
| 382 |    901.146040 |    446.888048 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 383 |    515.345170 |    751.546118 | Zimices                                                                                                                                                               |
| 384 |    417.385920 |     93.700887 | Birgit Lang                                                                                                                                                           |
| 385 |    951.544104 |    215.910785 | Tasman Dixon                                                                                                                                                          |
| 386 |    247.238113 |    278.722067 | Andy Wilson                                                                                                                                                           |
| 387 |    103.254007 |    698.880605 | Blanco et al., 2014, vectorized by Zimices                                                                                                                            |
| 388 |    890.076272 |    381.721813 | Scott Hartman                                                                                                                                                         |
| 389 |    253.359036 |    534.899254 | Zachary Quigley                                                                                                                                                       |
| 390 |    745.828039 |    520.120674 | Ludwik Gąsiorowski                                                                                                                                                    |
| 391 |    611.485531 |    698.322010 | Andrew A. Farke                                                                                                                                                       |
| 392 |    180.095805 |    312.543251 | NA                                                                                                                                                                    |
| 393 |     17.523125 |    456.298293 | NA                                                                                                                                                                    |
| 394 |    764.691714 |    775.058977 | Tauana J. Cunha                                                                                                                                                       |
| 395 |    375.322257 |      5.523951 | Margot Michaud                                                                                                                                                        |
| 396 |    576.390496 |    664.138716 | Margot Michaud                                                                                                                                                        |
| 397 |    535.034560 |    538.246116 | Chris huh                                                                                                                                                             |
| 398 |    613.339752 |     83.906473 | Julio Garza                                                                                                                                                           |
| 399 |    388.882100 |     48.442153 | Birgit Lang                                                                                                                                                           |
| 400 |    742.261793 |    325.209985 | Zimices                                                                                                                                                               |
| 401 |      8.040165 |    205.283772 | Erika Schumacher                                                                                                                                                      |
| 402 |    215.802962 |    511.925225 | Birgit Lang                                                                                                                                                           |
| 403 |    916.048654 |    577.434810 | Rebecca Groom                                                                                                                                                         |
| 404 |    380.804878 |    434.331730 | Gareth Monger                                                                                                                                                         |
| 405 |    753.191734 |    414.865176 | NA                                                                                                                                                                    |
| 406 |    510.724609 |    398.584397 | JCGiron                                                                                                                                                               |
| 407 |    347.361270 |    391.641090 | Milton Tan                                                                                                                                                            |
| 408 |    654.961010 |    285.485595 | T. Michael Keesey                                                                                                                                                     |
| 409 |    725.662238 |    325.430821 | Renata F. Martins                                                                                                                                                     |
| 410 |    492.679247 |    562.722694 | Chris huh                                                                                                                                                             |
| 411 |    706.518791 |     69.482754 | Steven Traver                                                                                                                                                         |
| 412 |    973.890433 |    715.470758 | Margot Michaud                                                                                                                                                        |
| 413 |    195.822317 |    641.979874 | Steven Traver                                                                                                                                                         |
| 414 |     33.416362 |    693.140132 | NA                                                                                                                                                                    |
| 415 |    179.586111 |    487.688899 | T. Michael Keesey                                                                                                                                                     |
| 416 |    240.353418 |    761.106288 | Zimices, based in Mauricio Antón skeletal                                                                                                                             |
| 417 |    899.113872 |    496.634993 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 418 |    146.372254 |    168.328251 | Jagged Fang Designs                                                                                                                                                   |
| 419 |    436.010265 |    678.732070 | Sarah Werning                                                                                                                                                         |
| 420 |    237.961979 |      5.421397 | Henry Lydecker                                                                                                                                                        |
| 421 |    882.577311 |    284.187654 | Matt Crook                                                                                                                                                            |
| 422 |    113.184967 |    598.980376 | Andreas Trepte (vectorized by T. Michael Keesey)                                                                                                                      |
| 423 |     26.006337 |    469.911887 | Yan Wong from illustration by Charles Orbigny                                                                                                                         |
| 424 |    582.677798 |    416.660440 | Alexandre Vong                                                                                                                                                        |
| 425 |    824.865515 |      6.390196 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                     |
| 426 |    775.681355 |    106.248456 | Scott Hartman                                                                                                                                                         |
| 427 |     81.751655 |    629.418237 | Oscar Sanisidro                                                                                                                                                       |
| 428 |   1005.253526 |    301.150931 | Steven Traver                                                                                                                                                         |
| 429 |    344.187722 |    116.517714 | CNZdenek                                                                                                                                                              |
| 430 |    679.795578 |    420.397458 | L. Shyamal                                                                                                                                                            |
| 431 |    370.721802 |     39.304201 | Margot Michaud                                                                                                                                                        |
| 432 |    125.922066 |    641.118840 | Andy Wilson                                                                                                                                                           |
| 433 |    165.813062 |     37.297214 | Noah Schlottman, photo by Adam G. Clause                                                                                                                              |
| 434 |    785.418709 |    643.922494 | Joe Schneid (vectorized by T. Michael Keesey)                                                                                                                         |
| 435 |    617.030295 |    187.753332 | Neil Kelley                                                                                                                                                           |
| 436 |    962.462486 |     19.961458 | Alexandre Vong                                                                                                                                                        |
| 437 |    665.862340 |    112.056754 | Zimices                                                                                                                                                               |
| 438 |    676.404435 |    148.129494 | Caroline Harding, MAF (vectorized by T. Michael Keesey)                                                                                                               |
| 439 |    522.951585 |     34.765722 | NA                                                                                                                                                                    |
| 440 |    977.713131 |    215.154469 | NA                                                                                                                                                                    |
| 441 |     16.382217 |    770.728173 | Steven Traver                                                                                                                                                         |
| 442 |    604.956551 |    328.766131 | Gareth Monger                                                                                                                                                         |
| 443 |   1014.469135 |    128.690785 | Zimices                                                                                                                                                               |
| 444 |    675.825000 |    161.346907 | Florian Pfaff                                                                                                                                                         |
| 445 |    284.586188 |    230.181315 | Matt Crook                                                                                                                                                            |
| 446 |    148.408639 |    705.744284 | Milton Tan                                                                                                                                                            |
| 447 |    631.752201 |    466.089630 | Michelle Site                                                                                                                                                         |
| 448 |    683.002200 |    445.573318 | Luc Viatour (source photo) and Andreas Plank                                                                                                                          |
| 449 |    701.368573 |    376.201485 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 450 |    415.016097 |    770.206626 | Hans Hillewaert                                                                                                                                                       |
| 451 |    611.809068 |     95.251833 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 452 |    346.989196 |    425.601749 | Mathilde Cordellier                                                                                                                                                   |
| 453 |    976.168797 |    507.889813 | Ferran Sayol                                                                                                                                                          |
| 454 |      8.709462 |    306.626204 | Matt Crook                                                                                                                                                            |
| 455 |    102.121925 |    194.472313 | Mo Hassan                                                                                                                                                             |
| 456 |    153.943077 |    604.389445 | Margot Michaud                                                                                                                                                        |
| 457 |   1010.654860 |    636.665923 | Margot Michaud                                                                                                                                                        |
| 458 |    641.532695 |    252.642352 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 459 |     62.086987 |    269.776131 | Steven Traver                                                                                                                                                         |
| 460 |    202.344805 |    327.663903 | Gareth Monger                                                                                                                                                         |
| 461 |     25.244548 |    335.140266 | T. Michael Keesey                                                                                                                                                     |
| 462 |    537.715049 |     22.151250 | Esme Ashe-Jepson                                                                                                                                                      |
| 463 |    392.334587 |    789.102373 | Heinrich Harder (vectorized by William Gearty)                                                                                                                        |
| 464 |    713.388157 |    344.890353 | Iain Reid                                                                                                                                                             |
| 465 |    163.204204 |     49.570848 | NA                                                                                                                                                                    |
| 466 |    846.738699 |    486.963247 | New York Zoological Society                                                                                                                                           |
| 467 |    344.847153 |    577.319672 | Milton Tan                                                                                                                                                            |
| 468 |     74.839023 |    794.303754 | Katie S. Collins                                                                                                                                                      |
| 469 |    185.527275 |    598.785034 | Emily Willoughby                                                                                                                                                      |
| 470 |    981.407484 |    101.923637 | Yan Wong (vectorization) from 1873 illustration                                                                                                                       |
| 471 |     32.726847 |    668.655675 | Zimices                                                                                                                                                               |
| 472 |    726.118295 |    355.438536 | Gareth Monger                                                                                                                                                         |
| 473 |    982.926149 |     35.806512 | Richard Lampitt, Jeremy Young / NHM (vectorization by Yan Wong)                                                                                                       |
| 474 |    545.893397 |    356.676234 | H. Filhol (vectorized by T. Michael Keesey)                                                                                                                           |
| 475 |    448.004190 |     13.391616 | Zimices                                                                                                                                                               |
| 476 |    101.394888 |    179.810773 | Scott Hartman                                                                                                                                                         |
| 477 |    807.111377 |    398.113145 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 478 |    206.186165 |    340.129087 | Carlos Cano-Barbacil                                                                                                                                                  |
| 479 |    210.862402 |    491.546040 | Sarah Werning                                                                                                                                                         |
| 480 |    809.851212 |    280.035356 | Margot Michaud                                                                                                                                                        |
| 481 |    311.617154 |    396.450276 | NA                                                                                                                                                                    |
| 482 |    490.406637 |    126.302678 | T. Michael Keesey                                                                                                                                                     |
| 483 |   1009.399139 |    287.831334 | Matt Crook                                                                                                                                                            |
| 484 |   1006.465439 |    687.757905 | Tasman Dixon                                                                                                                                                          |
| 485 |    722.605801 |    529.265731 | Andrew A. Farke                                                                                                                                                       |
| 486 |    935.705951 |    373.462601 | Chris huh                                                                                                                                                             |
| 487 |    293.404164 |    166.552522 | L. Shyamal                                                                                                                                                            |
| 488 |    428.969588 |    391.962907 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 489 |    457.377725 |    627.586649 | Jagged Fang Designs                                                                                                                                                   |
| 490 |    925.325710 |    144.061269 | Christoph Schomburg                                                                                                                                                   |
| 491 |    113.928318 |    215.663799 | T. Michael Keesey                                                                                                                                                     |
| 492 |    349.436586 |    123.378337 | Chris huh                                                                                                                                                             |
| 493 |     46.624834 |     77.817434 | Chris huh                                                                                                                                                             |
| 494 |   1006.569033 |    316.341795 | Jon M Laurent                                                                                                                                                         |
| 495 |    513.955739 |    667.078366 | T. Michael Keesey                                                                                                                                                     |
| 496 |    464.987132 |    158.334607 | NA                                                                                                                                                                    |
| 497 |    356.993609 |    535.638707 | NA                                                                                                                                                                    |
| 498 |     19.243458 |     83.780319 | Mathew Wedel                                                                                                                                                          |
| 499 |    432.725195 |    774.795582 | Samanta Orellana                                                                                                                                                      |
| 500 |    227.581610 |    435.537691 | Bruno C. Vellutini                                                                                                                                                    |
| 501 |    890.390502 |    199.213031 | Matt Crook                                                                                                                                                            |
| 502 |    326.354737 |    603.049495 | Taenadoman                                                                                                                                                            |
| 503 |    342.248403 |    212.950739 | Matt Crook                                                                                                                                                            |
| 504 |    596.735318 |     77.603638 | Smokeybjb                                                                                                                                                             |
| 505 |    889.483410 |    637.239625 | Melissa Broussard                                                                                                                                                     |
| 506 |    270.547021 |    381.381583 | Meliponicultor Itaymbere                                                                                                                                              |
| 507 |    604.075467 |    342.495626 | Markus A. Grohme                                                                                                                                                      |
| 508 |    193.893349 |     69.536041 | Joseph Wolf, 1863 (vectorization by Dinah Challen)                                                                                                                    |
| 509 |    603.524623 |    473.360388 | Ignacio Contreras                                                                                                                                                     |
| 510 |    200.036564 |    479.439427 | Mike Hanson                                                                                                                                                           |
| 511 |    138.295717 |    301.074795 | NA                                                                                                                                                                    |
| 512 |     41.463753 |    620.595773 | Dori <dori@merr.info> (source photo) and Nevit Dilmen                                                                                                                 |
| 513 |    866.761302 |    259.539025 | Michelle Site                                                                                                                                                         |
| 514 |    146.572482 |    306.303916 | NA                                                                                                                                                                    |
| 515 |    971.472917 |     91.058423 | Nobu Tamura, modified by Andrew A. Farke                                                                                                                              |
| 516 |    914.797944 |    501.062338 | Zimices                                                                                                                                                               |
| 517 |    322.650426 |    690.066857 | Steven Traver                                                                                                                                                         |
| 518 |    825.476428 |    510.371847 | Steven Traver                                                                                                                                                         |
| 519 |    944.473601 |    339.495088 | Mykle Hoban                                                                                                                                                           |
| 520 |    321.597763 |    717.835002 | Lafage                                                                                                                                                                |
| 521 |    503.082307 |    797.322311 | Chris huh                                                                                                                                                             |
| 522 |    237.215876 |    668.290879 | T. Michael Keesey                                                                                                                                                     |
| 523 |    549.744776 |    231.720413 | Gareth Monger                                                                                                                                                         |
| 524 |    978.699813 |    188.577824 | Steven Traver                                                                                                                                                         |
| 525 |    841.432892 |    641.260643 | Emily Willoughby                                                                                                                                                      |
| 526 |    959.414471 |     39.577234 | Matthew E. Clapham                                                                                                                                                    |
| 527 |    222.441355 |    777.589125 | Matt Crook                                                                                                                                                            |
| 528 |    340.375585 |    609.594509 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 529 |    594.522341 |    573.405969 | Gareth Monger                                                                                                                                                         |
| 530 |     21.825148 |    677.481831 | Tod Robbins                                                                                                                                                           |
| 531 |    731.250320 |    251.675412 | Jagged Fang Designs                                                                                                                                                   |
| 532 |    859.224479 |    791.040264 | Mathilde Cordellier                                                                                                                                                   |
| 533 |     92.631067 |    246.029671 | Zimices                                                                                                                                                               |
| 534 |    939.316380 |    522.835050 | nicubunu                                                                                                                                                              |
| 535 |    426.892061 |    122.286677 | Crystal Maier                                                                                                                                                         |
| 536 |   1012.942119 |    387.259265 | Felix Vaux                                                                                                                                                            |
| 537 |     13.197027 |    353.044078 | Diana Pomeroy                                                                                                                                                         |
| 538 |    766.325314 |    623.560319 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 539 |    643.206749 |    760.211106 | Matt Crook                                                                                                                                                            |
| 540 |    345.593090 |    282.248669 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 541 |    398.677595 |    392.713494 | T. Michael Keesey                                                                                                                                                     |
| 542 |    587.256862 |     31.667226 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                                |
| 543 |    942.804936 |    772.210105 | Michael P. Taylor                                                                                                                                                     |
| 544 |    466.972773 |    144.777713 | Pete Buchholz                                                                                                                                                         |
| 545 |    644.077940 |    347.629978 | Margot Michaud                                                                                                                                                        |
| 546 |    455.801590 |     87.171531 | Christopher Watson (photo) and T. Michael Keesey (vectorization)                                                                                                      |
| 547 |      8.989057 |    658.325214 | Matt Crook                                                                                                                                                            |
| 548 |    478.886984 |    431.801899 | Jagged Fang Designs                                                                                                                                                   |
| 549 |     55.262324 |    570.014037 | Matt Crook                                                                                                                                                            |
| 550 |    837.568452 |    533.959796 | Gareth Monger                                                                                                                                                         |
| 551 |    328.301773 |    313.397569 | Ben Moon                                                                                                                                                              |
| 552 |    892.297775 |    229.164222 | Matt Crook                                                                                                                                                            |
| 553 |    123.272230 |    242.302694 | Emily Jane McTavish, from <http://en.wikipedia.org/wiki/File:Coccolithus_pelagicus.jpg>                                                                               |
| 554 |    236.902910 |    691.098609 | Chuanixn Yu                                                                                                                                                           |
| 555 |    457.967511 |    791.568291 | Matt Crook                                                                                                                                                            |
| 556 |   1011.500947 |    526.560716 | Matt Crook                                                                                                                                                            |
| 557 |    451.391989 |    108.567570 | Jaime Headden, modified by T. Michael Keesey                                                                                                                          |
| 558 |     35.852107 |    683.444413 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 559 |    106.333606 |    556.556923 | NA                                                                                                                                                                    |
| 560 |    282.917199 |     50.171615 | Scott Reid                                                                                                                                                            |
| 561 |     11.884662 |    382.800784 | Zimices                                                                                                                                                               |
| 562 |     59.230478 |    264.065066 | Chris huh                                                                                                                                                             |
| 563 |    528.485437 |    270.446786 | Nicolas Huet le Jeune and Jean-Gabriel Prêtre (vectorized by T. Michael Keesey)                                                                                       |
| 564 |    263.589240 |    644.685806 | Scott Hartman                                                                                                                                                         |
| 565 |    650.912386 |    187.261393 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 566 |    261.619906 |    370.771151 | Jack Mayer Wood                                                                                                                                                       |
| 567 |    973.268560 |    124.307574 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 568 |    297.142767 |    391.117250 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                           |
| 569 |    270.209379 |    272.792842 | Margot Michaud                                                                                                                                                        |
| 570 |    583.160326 |    339.842573 | Michelle Site                                                                                                                                                         |
| 571 |    610.198868 |    250.906969 | Zimices                                                                                                                                                               |
| 572 |    526.524220 |    214.700169 | Michelle Site                                                                                                                                                         |
| 573 |    942.195277 |    530.968089 | Ferran Sayol                                                                                                                                                          |
| 574 |    326.823268 |      7.547136 | Noah Schlottman, photo by Adam G. Clause                                                                                                                              |
| 575 |    175.129771 |    658.672851 | Zimices                                                                                                                                                               |
| 576 |    231.655902 |    302.730234 | Chris huh                                                                                                                                                             |
| 577 |   1001.408318 |    448.842399 | Ferran Sayol                                                                                                                                                          |
| 578 |    494.212066 |    343.819955 | T. Michael Keesey                                                                                                                                                     |
| 579 |    406.632854 |    559.653147 | xgirouxb                                                                                                                                                              |
| 580 |     12.990965 |    395.141912 | Tracy A. Heath                                                                                                                                                        |
| 581 |    990.558332 |    150.022213 | Roberto Díaz Sibaja                                                                                                                                                   |
| 582 |    687.030221 |    259.574041 | T. Michael Keesey                                                                                                                                                     |
| 583 |     66.320313 |    709.930220 | Caleb M. Brown                                                                                                                                                        |
| 584 |    514.542852 |    174.510975 | Alex Slavenko                                                                                                                                                         |
| 585 |    209.601983 |    406.862040 | Hans Hillewaert                                                                                                                                                       |
| 586 |    184.554562 |    451.870224 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 587 |    772.878566 |    103.167532 | Scott Hartman                                                                                                                                                         |
| 588 |    541.079225 |     45.008992 | Zimices                                                                                                                                                               |
| 589 |    636.550107 |    701.481749 | Rebecca Groom                                                                                                                                                         |
| 590 |    445.500352 |    607.596199 | Cesar Julian                                                                                                                                                          |
| 591 |    123.637794 |    712.945406 | Yusan Yang                                                                                                                                                            |
| 592 |    986.500802 |    246.788199 | Nick Schooler                                                                                                                                                         |
| 593 |    104.365007 |    711.732726 | Matt Martyniuk                                                                                                                                                        |
| 594 |    620.710478 |    169.799514 | A. H. Baldwin (vectorized by T. Michael Keesey)                                                                                                                       |
| 595 |    990.715219 |    532.512490 | Frank Förster (based on a picture by Jerry Kirkhart; modified by T. Michael Keesey)                                                                                   |
| 596 |    327.678314 |    111.530327 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                        |
| 597 |    920.874736 |    430.212559 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 598 |    605.460500 |    309.079906 | B. Duygu Özpolat                                                                                                                                                      |
| 599 |    761.026868 |    166.384659 | Tracy A. Heath                                                                                                                                                        |
| 600 |    806.878737 |    113.394592 | Tauana J. Cunha                                                                                                                                                       |
| 601 |    995.327677 |    504.663184 | Michael Scroggie                                                                                                                                                      |
| 602 |    654.726568 |    261.220130 | Matt Crook                                                                                                                                                            |
| 603 |    916.306124 |    791.930277 | Christoph Schomburg                                                                                                                                                   |
| 604 |    316.819464 |     24.987063 | Michael Scroggie                                                                                                                                                      |
| 605 |    881.888103 |    685.638899 | Maija Karala                                                                                                                                                          |
| 606 |    729.855474 |    792.710229 | Fernando Campos De Domenico                                                                                                                                           |
| 607 |    587.652072 |    112.211675 | Robert Hering                                                                                                                                                         |
| 608 |    659.705533 |    346.388258 | LeonardoG (photography) and T. Michael Keesey (vectorization)                                                                                                         |
| 609 |     67.581778 |    475.138775 | NA                                                                                                                                                                    |
| 610 |    645.282500 |    297.174950 | Jaime Headden                                                                                                                                                         |
| 611 |    105.336842 |    330.207915 | Michelle Site                                                                                                                                                         |
| 612 |    893.631931 |    793.858857 | Steven Traver                                                                                                                                                         |
| 613 |    346.721831 |     32.638759 | Sarah Werning                                                                                                                                                         |
| 614 |    626.555874 |    184.575943 | Matthew E. Clapham                                                                                                                                                    |
| 615 |    312.616943 |    145.120997 | Margot Michaud                                                                                                                                                        |
| 616 |    318.639468 |    557.552584 | Ignacio Contreras                                                                                                                                                     |
| 617 |    420.542408 |    371.620489 | Erika Schumacher                                                                                                                                                      |
| 618 |    767.079347 |    278.040864 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 619 |    240.365396 |    440.055170 | Juan Carlos Jerí                                                                                                                                                      |
| 620 |    365.255298 |    294.852572 | Birgit Lang                                                                                                                                                           |
| 621 |    242.489343 |     35.320018 | Steven Traver                                                                                                                                                         |
| 622 |    110.980841 |    308.167162 | Gareth Monger                                                                                                                                                         |
| 623 |    478.666111 |    264.028619 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 624 |    266.402191 |    738.310909 | John Gould (vectorized by T. Michael Keesey)                                                                                                                          |
| 625 |    307.697747 |    101.505271 | Matt Crook                                                                                                                                                            |
| 626 |    163.670189 |    378.267644 | Chris huh                                                                                                                                                             |
| 627 |    213.591073 |     18.663025 | Zimices                                                                                                                                                               |
| 628 |    895.738026 |    753.616700 | Matt Crook                                                                                                                                                            |
| 629 |    954.829963 |    543.383880 | Neil Kelley                                                                                                                                                           |
| 630 |     33.873061 |    568.277308 | Kamil S. Jaron                                                                                                                                                        |
| 631 |    578.369891 |    571.485050 | Steven Traver                                                                                                                                                         |
| 632 |    602.382081 |    585.134792 | Gareth Monger                                                                                                                                                         |
| 633 |    979.380844 |    175.556577 | Qiang Ou                                                                                                                                                              |
| 634 |    983.827200 |    391.243899 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 635 |    482.493924 |    469.488270 | Scott Hartman                                                                                                                                                         |
| 636 |    984.232494 |    112.475234 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 637 |    735.763032 |    726.778007 | Matt Martyniuk                                                                                                                                                        |
| 638 |    188.143899 |    744.103660 | Renata F. Martins                                                                                                                                                     |
| 639 |    886.742580 |    752.208460 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                                 |
| 640 |    139.459414 |    728.910461 | Trond R. Oskars                                                                                                                                                       |
| 641 |    325.036053 |    721.543719 | Smokeybjb                                                                                                                                                             |
| 642 |    743.524971 |    170.471632 | Вальдимар (vectorized by T. Michael Keesey)                                                                                                                           |
| 643 |    880.898045 |    269.838176 | Michael Scroggie, from original photograph by John Bettaso, USFWS (original photograph in public domain).                                                             |
| 644 |   1015.374091 |    578.113072 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 645 |    984.018315 |    729.256650 | M Kolmann                                                                                                                                                             |
| 646 |    673.619628 |     53.449176 | Rebecca Groom                                                                                                                                                         |
| 647 |    124.078752 |    487.453841 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 648 |    912.070364 |    235.372302 | Adam Stuart Smith (vectorized by T. Michael Keesey)                                                                                                                   |
| 649 |    451.766233 |     75.369191 | Gareth Monger                                                                                                                                                         |
| 650 |    147.745366 |    156.843124 | Joanna Wolfe                                                                                                                                                          |
| 651 |    809.843327 |    372.402041 | Steven Traver                                                                                                                                                         |
| 652 |    773.424340 |    262.704934 | Tasman Dixon                                                                                                                                                          |
| 653 |    299.963716 |    313.527521 | Kevin Sánchez                                                                                                                                                         |
| 654 |    696.823581 |    398.048336 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 655 |    899.549506 |    632.610311 | Thibaut Brunet                                                                                                                                                        |
| 656 |    512.171250 |     66.623074 | Noah Schlottman, photo by Hans De Blauwe                                                                                                                              |
| 657 |    480.994604 |    575.624191 | Gareth Monger                                                                                                                                                         |
| 658 |    750.618353 |    278.046076 | Zimices                                                                                                                                                               |
| 659 |    176.293299 |    747.109100 | Jaime Headden                                                                                                                                                         |
| 660 |    365.684788 |    403.467189 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 661 |    347.459271 |    330.358656 | Felix Vaux and Steven A. Trewick                                                                                                                                      |
| 662 |     89.961417 |    566.533309 | terngirl                                                                                                                                                              |
| 663 |    606.745580 |    167.223512 | Pete Buchholz                                                                                                                                                         |
| 664 |    445.893543 |    580.410596 | Birgit Lang                                                                                                                                                           |
| 665 |    380.701047 |    676.165521 | Maija Karala                                                                                                                                                          |
| 666 |   1000.328370 |    100.045635 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 667 |    383.048674 |    179.328396 | Carlos Cano-Barbacil                                                                                                                                                  |
| 668 |    727.624686 |    595.579954 | Jack Mayer Wood                                                                                                                                                       |
| 669 |    164.010626 |     80.347623 | Gareth Monger                                                                                                                                                         |
| 670 |    659.174351 |    729.394429 | Markus A. Grohme                                                                                                                                                      |
| 671 |    340.993829 |    720.308036 | Noah Schlottman, photo from Moorea Biocode                                                                                                                            |
| 672 |     63.002760 |    456.154381 | Matt Crook                                                                                                                                                            |
| 673 |     42.639234 |    713.755903 | Alexandre Vong                                                                                                                                                        |
| 674 |    766.608520 |    348.943451 | Alexandre Vong                                                                                                                                                        |
| 675 |    144.828412 |    333.060116 | Matt Crook                                                                                                                                                            |
| 676 |    120.141692 |      6.590264 | Zimices                                                                                                                                                               |
| 677 |    133.660479 |    587.545931 | Collin Gross                                                                                                                                                          |
| 678 |    631.438118 |    519.968834 | NA                                                                                                                                                                    |
| 679 |     44.553379 |     48.811678 | Margot Michaud                                                                                                                                                        |
| 680 |    984.710305 |    477.128377 | Robert Bruce Horsfall (vectorized by William Gearty)                                                                                                                  |
| 681 |    221.218088 |    400.695684 | Gareth Monger                                                                                                                                                         |
| 682 |    182.296672 |    376.501366 | Steven Traver                                                                                                                                                         |
| 683 |    140.103943 |    436.413478 | Matt Crook                                                                                                                                                            |
| 684 |    311.583520 |    324.348881 | Armin Reindl                                                                                                                                                          |
| 685 |   1004.055131 |     30.664606 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 686 |    154.424617 |    588.845243 | Julio Garza                                                                                                                                                           |
| 687 |    718.115963 |     60.035314 | Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael Keesey)                                                                                |
| 688 |    823.639188 |    382.619643 | Julio Garza                                                                                                                                                           |
| 689 |    556.681819 |    565.229367 | Mali’o Kodis, image from the “Proceedings of the Zoological Society of London”                                                                                        |
| 690 |     81.782030 |    234.595277 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                           |
| 691 |    392.076976 |    361.274153 | NA                                                                                                                                                                    |
| 692 |    634.957392 |     88.078835 | Margot Michaud                                                                                                                                                        |
| 693 |    180.752557 |    530.584198 | Margot Michaud                                                                                                                                                        |
| 694 |    995.302795 |    482.858358 | Ingo Braasch                                                                                                                                                          |
| 695 |    457.472402 |    594.764024 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 696 |    894.881598 |    782.031030 | Birgit Lang                                                                                                                                                           |
| 697 |    507.701645 |      1.976357 | Gareth Monger                                                                                                                                                         |
| 698 |    937.258277 |    384.264332 | Mike Hanson                                                                                                                                                           |
| 699 |    304.177071 |    245.228290 | Xavier Giroux-Bougard                                                                                                                                                 |
| 700 |    399.562379 |    107.673383 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 701 |     14.387827 |    594.405269 | Mathilde Cordellier                                                                                                                                                   |
| 702 |    299.293084 |     86.981197 | Matt Crook                                                                                                                                                            |
| 703 |    268.881212 |    259.238898 | Oren Peles / vectorized by Yan Wong                                                                                                                                   |
| 704 |    752.635066 |    678.221336 | Alexandre Vong                                                                                                                                                        |
| 705 |    298.965483 |    564.709055 | Conty                                                                                                                                                                 |
| 706 |    331.042787 |    756.992156 | Chris Jennings (Risiatto)                                                                                                                                             |
| 707 |    877.532633 |    294.645567 | Beth Reinke                                                                                                                                                           |
| 708 |    769.109106 |    673.791608 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 709 |    906.358422 |     37.883508 | Michelle Site                                                                                                                                                         |
| 710 |    724.094864 |    616.201935 | Matt Crook                                                                                                                                                            |
| 711 |     16.898075 |    243.000074 | Chloé Schmidt                                                                                                                                                         |
| 712 |    726.051363 |    640.910938 | Chris huh                                                                                                                                                             |
| 713 |    115.292834 |     33.793242 | Tasman Dixon                                                                                                                                                          |
| 714 |    140.785404 |    482.268221 | T. Michael Keesey (vectorization) and Larry Loos (photography)                                                                                                        |
| 715 |    387.559207 |    223.779472 | Tasman Dixon                                                                                                                                                          |
| 716 |    911.831189 |    388.511757 | Zimices                                                                                                                                                               |
| 717 |     15.789604 |      9.238650 | Frederick William Frohawk (vectorized by T. Michael Keesey)                                                                                                           |
| 718 |    202.296983 |    395.074627 | Chloé Schmidt                                                                                                                                                         |
| 719 |    127.690058 |    338.453865 | Daniel Stadtmauer                                                                                                                                                     |
| 720 |    104.252136 |    173.564624 | Chris huh                                                                                                                                                             |
| 721 |    744.747352 |    249.568161 | Margot Michaud                                                                                                                                                        |
| 722 |    386.840620 |    776.407119 | Zimices                                                                                                                                                               |
| 723 |    776.154255 |    784.046393 | Matt Crook                                                                                                                                                            |
| 724 |    562.896911 |     78.177494 | Beth Reinke                                                                                                                                                           |
| 725 |    334.328553 |    461.093077 | Nina Skinner                                                                                                                                                          |
| 726 |    983.270292 |    352.420845 | Maija Karala                                                                                                                                                          |
| 727 |    361.263944 |    792.765986 | Collin Gross                                                                                                                                                          |
| 728 |    239.485413 |    634.884103 | Dmitry Bogdanov                                                                                                                                                       |
| 729 |    796.075644 |    709.341547 | Courtney Rockenbach                                                                                                                                                   |
| 730 |    606.279010 |    154.103026 | Ferran Sayol                                                                                                                                                          |
| 731 |    410.354772 |    374.176179 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 732 |    655.460200 |    529.026581 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 733 |    401.805173 |    664.157998 | NA                                                                                                                                                                    |
| 734 |    862.980282 |    111.651970 | Jagged Fang Designs                                                                                                                                                   |
| 735 |     15.987319 |     61.780476 | Ignacio Contreras                                                                                                                                                     |
| 736 |    871.572268 |    533.573510 | Ferran Sayol                                                                                                                                                          |
| 737 |    983.117161 |    140.474981 | NA                                                                                                                                                                    |
| 738 |    910.042761 |    250.286262 | Kailah Thorn & Mark Hutchinson                                                                                                                                        |
| 739 |    884.661463 |    164.517226 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 740 |    519.828754 |    234.585090 | Joe Schneid (vectorized by T. Michael Keesey)                                                                                                                         |
| 741 |    315.199230 |    791.961016 | Erika Schumacher                                                                                                                                                      |
| 742 |   1004.076411 |    184.785876 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 743 |    627.121085 |    609.730244 | Andy Wilson                                                                                                                                                           |
| 744 |    398.545827 |    715.077305 | Ghedo (vectorized by T. Michael Keesey)                                                                                                                               |
| 745 |    358.276391 |    108.835991 | Markus A. Grohme                                                                                                                                                      |
| 746 |     64.519862 |    123.760501 | Zimices                                                                                                                                                               |
| 747 |   1007.969850 |    622.707469 | Matt Crook                                                                                                                                                            |
| 748 |     18.074847 |    463.346811 | Chris huh                                                                                                                                                             |
| 749 |     46.344221 |    254.551225 | Lily Hughes                                                                                                                                                           |
| 750 |    838.608086 |    138.040662 | Margot Michaud                                                                                                                                                        |
| 751 |    379.707190 |    519.355413 | NA                                                                                                                                                                    |
| 752 |    292.460446 |    113.696467 | Birgit Lang                                                                                                                                                           |
| 753 |     95.040382 |    265.622729 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 754 |    578.431335 |    627.918005 | Matt Crook                                                                                                                                                            |
| 755 |    281.290622 |     10.397424 | Margot Michaud                                                                                                                                                        |
| 756 |    208.019626 |    145.406270 | Scott Hartman                                                                                                                                                         |
| 757 |    289.534111 |     40.087612 | Andy Wilson                                                                                                                                                           |
| 758 |    999.797814 |    779.353518 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 759 |    300.447645 |      6.361675 | S.Martini                                                                                                                                                             |
| 760 |    488.444900 |    452.637263 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 761 |    678.987173 |    229.669184 | Ingo Braasch                                                                                                                                                          |
| 762 |    979.615219 |    339.200526 | Erika Schumacher                                                                                                                                                      |
| 763 |      8.081875 |    686.908371 | Jan Sevcik (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey            |
| 764 |    332.859676 |     30.231748 | Michelle Site                                                                                                                                                         |
| 765 |    388.305077 |    665.425180 | Margot Michaud                                                                                                                                                        |
| 766 |    901.811076 |    542.575923 | Gareth Monger                                                                                                                                                         |
| 767 |    444.926535 |    790.482208 | Birgit Lang                                                                                                                                                           |
| 768 |     24.436609 |    659.198096 | Matt Crook                                                                                                                                                            |
| 769 |    348.111298 |    762.220801 | NA                                                                                                                                                                    |
| 770 |    258.546050 |    772.325730 | Margot Michaud                                                                                                                                                        |
| 771 |    731.219404 |    573.909938 | DW Bapst (modified from Bates et al., 2005)                                                                                                                           |
| 772 |    706.325702 |    536.275760 | Matt Crook                                                                                                                                                            |
| 773 |     70.420302 |    313.528491 | Tauana J. Cunha                                                                                                                                                       |
| 774 |    812.871857 |    201.933444 | Hugo Gruson                                                                                                                                                           |
| 775 |     36.034667 |    639.858613 | Kamil S. Jaron                                                                                                                                                        |
| 776 |    343.667692 |     22.631447 | Matt Crook                                                                                                                                                            |
| 777 |    576.527780 |    240.036197 | Matt Crook                                                                                                                                                            |
| 778 |     44.978888 |    216.753451 | Yan Wong from photo by Gyik Toma                                                                                                                                      |
| 779 |    824.838950 |    536.287905 | T. Michael Keesey                                                                                                                                                     |
| 780 |    226.651419 |     72.764891 | Gareth Monger                                                                                                                                                         |
| 781 |    854.137737 |     65.131205 | Gareth Monger                                                                                                                                                         |
| 782 |    457.574292 |    582.917047 | NA                                                                                                                                                                    |
| 783 |    912.167378 |    768.120625 | Birgit Lang                                                                                                                                                           |
| 784 |    366.457983 |    261.507922 | Nina Skinner                                                                                                                                                          |
| 785 |    571.495138 |    536.216688 | Matt Crook                                                                                                                                                            |
| 786 |    934.166376 |    509.354919 | Michael Scroggie                                                                                                                                                      |
| 787 |    572.872714 |    686.874036 | T. Michael Keesey                                                                                                                                                     |
| 788 |    921.775511 |    360.186558 | Matus Valach                                                                                                                                                          |
| 789 |    937.659018 |    116.934438 | Michael Ströck (vectorized by T. Michael Keesey)                                                                                                                      |
| 790 |    138.216584 |    610.035977 | Emily Willoughby                                                                                                                                                      |
| 791 |    899.604918 |    522.874153 | Scott Hartman                                                                                                                                                         |
| 792 |    748.554107 |    151.113087 | Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael Keesey)                                                                                |
| 793 |    827.013836 |    108.657969 | Maija Karala                                                                                                                                                          |
| 794 |     11.396823 |    167.868523 | Matthew E. Clapham                                                                                                                                                    |
| 795 |    876.765129 |    795.976592 | Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus                                              |
| 796 |    823.592467 |    192.693281 | Christoph Schomburg                                                                                                                                                   |
| 797 |     18.353252 |     30.024030 | Ferran Sayol                                                                                                                                                          |
| 798 |    555.668921 |    690.018784 | Dean Schnabel                                                                                                                                                         |
| 799 |    296.527399 |    180.603546 | Martin Kevil                                                                                                                                                          |
| 800 |    524.081614 |    685.951658 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                        |
| 801 |    989.191479 |    705.343545 | Margot Michaud                                                                                                                                                        |
| 802 |    590.418574 |    550.802491 | Matt Crook                                                                                                                                                            |
| 803 |     37.087217 |    491.203152 | Ferran Sayol                                                                                                                                                          |
| 804 |    175.161485 |     75.955245 | Tasman Dixon                                                                                                                                                          |
| 805 |    304.165256 |     47.248137 | NA                                                                                                                                                                    |
| 806 |    797.393556 |    221.898727 | (after Spotila 2004)                                                                                                                                                  |
| 807 |    485.535997 |    479.999081 | Chase Brownstein                                                                                                                                                      |
| 808 |    595.525115 |    161.668390 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 809 |     66.403872 |    715.842346 | Oscar Sanisidro                                                                                                                                                       |
| 810 |    746.029436 |    629.711856 | M. Garfield & K. Anderson (modified by T. Michael Keesey)                                                                                                             |
| 811 |     77.070880 |    276.500900 | Paul O. Lewis                                                                                                                                                         |
| 812 |    365.035567 |    414.236188 | U.S. National Park Service (vectorized by William Gearty)                                                                                                             |
| 813 |    170.243399 |    738.093222 | Abraão Leite                                                                                                                                                          |
| 814 |     57.888168 |    659.287067 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 815 |    991.397123 |    328.001546 | Kanako Bessho-Uehara                                                                                                                                                  |
| 816 |    366.565312 |    119.980144 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 817 |    375.596967 |    321.090956 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 818 |    562.041720 |    659.017392 | Gareth Monger                                                                                                                                                         |
| 819 |    458.358732 |    743.744336 | Gareth Monger                                                                                                                                                         |
| 820 |    804.402074 |    701.321010 | Brockhaus and Efron                                                                                                                                                   |
| 821 |    125.237864 |    261.958116 | Matt Martyniuk                                                                                                                                                        |
| 822 |    704.710567 |    636.691202 | FunkMonk                                                                                                                                                              |
| 823 |    832.407126 |    131.253928 | Margot Michaud                                                                                                                                                        |
| 824 |    247.440934 |    591.676799 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 825 |    259.999428 |    608.617893 | Tasman Dixon                                                                                                                                                          |
| 826 |    120.093600 |    462.859832 | Davidson Sodré                                                                                                                                                        |
| 827 |    802.150179 |    390.875160 | Mo Hassan                                                                                                                                                             |
| 828 |    524.964031 |    167.774590 | Margot Michaud                                                                                                                                                        |
| 829 |    424.825996 |    552.137938 | Emily Willoughby                                                                                                                                                      |
| 830 |    381.502845 |    305.777286 | Chris huh                                                                                                                                                             |
| 831 |    584.224848 |     91.218081 | Tasman Dixon                                                                                                                                                          |
| 832 |    867.782093 |     54.793996 | Riccardo Percudani                                                                                                                                                    |
| 833 |   1013.233110 |    352.144242 | Chris huh                                                                                                                                                             |
| 834 |    853.503613 |     48.469044 | Kai R. Caspar                                                                                                                                                         |
| 835 |    332.351899 |    575.418904 | Jagged Fang Designs                                                                                                                                                   |
| 836 |    419.534686 |    779.795993 | Manabu Bessho-Uehara                                                                                                                                                  |
| 837 |   1015.648541 |    508.239556 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 838 |    346.039143 |    733.886844 | Zimices                                                                                                                                                               |
| 839 |     74.651715 |    259.694668 | Anthony Caravaggi                                                                                                                                                     |
| 840 |     50.273027 |    774.695224 | Joshua Fowler                                                                                                                                                         |
| 841 |    754.187789 |    584.233616 | NA                                                                                                                                                                    |
| 842 |    514.050726 |     13.390046 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 843 |    793.715048 |    433.648627 | Zimices                                                                                                                                                               |
| 844 |    352.393354 |    180.708332 | Scott Hartman                                                                                                                                                         |
| 845 |    872.735435 |    756.589678 | Jaime Headden, modified by T. Michael Keesey                                                                                                                          |
| 846 |    149.595859 |    716.015243 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                      |
| 847 |    523.679909 |    783.731552 | Beth Reinke                                                                                                                                                           |
| 848 |    316.211432 |    425.757964 | Gareth Monger                                                                                                                                                         |
| 849 |      5.232979 |    277.536433 | NA                                                                                                                                                                    |
| 850 |    320.792793 |    727.238353 | Mathew Wedel                                                                                                                                                          |
| 851 |    414.459224 |    117.955947 | Michelle Site                                                                                                                                                         |
| 852 |   1015.364805 |    200.947486 | Matt Crook                                                                                                                                                            |
| 853 |    852.875319 |    267.159234 | Jaime Headden                                                                                                                                                         |
| 854 |     50.391108 |    228.352254 | Chase Brownstein                                                                                                                                                      |
| 855 |    867.048411 |    247.152731 | Jagged Fang Designs                                                                                                                                                   |
| 856 |    768.373317 |    393.911779 | Gareth Monger                                                                                                                                                         |
| 857 |     96.527744 |    787.665711 | Tauana J. Cunha                                                                                                                                                       |
| 858 |    393.989143 |    115.597750 | Margot Michaud                                                                                                                                                        |
| 859 |    761.716543 |    370.779552 | Zimices                                                                                                                                                               |
| 860 |    453.368447 |    667.766495 | Margot Michaud                                                                                                                                                        |
| 861 |    738.641678 |    234.470534 | Steven Coombs                                                                                                                                                         |
| 862 |    680.716773 |    481.285716 | NA                                                                                                                                                                    |
| 863 |    172.020590 |    639.106671 | Lauren Anderson                                                                                                                                                       |
| 864 |    568.568878 |     65.336460 | Sarah Werning                                                                                                                                                         |
| 865 |    100.538769 |    224.541918 | NA                                                                                                                                                                    |
| 866 |    376.310020 |    766.102105 | Jagged Fang Designs                                                                                                                                                   |
| 867 |    214.445988 |    312.873231 | Fernando Carezzano                                                                                                                                                    |
| 868 |    694.417206 |     35.977745 | Riccardo Percudani                                                                                                                                                    |
| 869 |    640.572846 |    122.930329 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 870 |     18.595766 |    198.448121 | Kamil S. Jaron                                                                                                                                                        |
| 871 |    768.215727 |    420.636340 | Tracy A. Heath                                                                                                                                                        |
| 872 |    235.505585 |    313.482108 | Mario Quevedo                                                                                                                                                         |
| 873 |     17.436617 |    224.122705 | Kent Elson Sorgon                                                                                                                                                     |
| 874 |     24.796678 |    753.843113 | terngirl                                                                                                                                                              |
| 875 |    595.771567 |    675.386533 | Gareth Monger                                                                                                                                                         |
| 876 |    462.244999 |    114.660016 | NA                                                                                                                                                                    |
| 877 |    865.179609 |    182.960608 | Matt Crook                                                                                                                                                            |
| 878 |    916.952844 |    631.792577 | Matt Crook                                                                                                                                                            |
| 879 |    284.791980 |    612.646185 | Matt Crook                                                                                                                                                            |
| 880 |    674.057627 |    186.961031 | Daniel Stadtmauer                                                                                                                                                     |
| 881 |    494.757903 |    108.362459 | Andy Wilson                                                                                                                                                           |
| 882 |    556.985235 |     92.495206 | Smokeybjb                                                                                                                                                             |
| 883 |    829.666975 |    497.133294 | Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael Keesey)                                                                                |
| 884 |     49.121631 |     94.942442 | Matt Crook                                                                                                                                                            |
| 885 |    540.043117 |    446.230666 | Fernando Carezzano                                                                                                                                                    |
| 886 |    807.370214 |    350.417606 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 887 |    522.184121 |    385.767741 | Matt Crook                                                                                                                                                            |
| 888 |    294.654495 |    368.249773 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 889 |    945.432433 |    514.424432 | Margot Michaud                                                                                                                                                        |
| 890 |    326.658150 |    171.047708 | Matt Crook                                                                                                                                                            |
| 891 |    558.464846 |    270.446262 | Beth Reinke                                                                                                                                                           |
| 892 |     70.759424 |    571.628127 | T. Michael Keesey (after Monika Betley)                                                                                                                               |
| 893 |    231.930217 |    519.938832 | Steven Haddock • Jellywatch.org                                                                                                                                       |
| 894 |     94.716145 |    660.813554 | Zimices                                                                                                                                                               |
| 895 |    445.846277 |    404.498083 | Ingo Braasch                                                                                                                                                          |
| 896 |    302.006252 |    547.009275 | Ingo Braasch                                                                                                                                                          |
| 897 |    266.747841 |     94.832565 | T. Michael Keesey                                                                                                                                                     |
| 898 |    678.812808 |    458.663353 | Gareth Monger                                                                                                                                                         |
| 899 |    840.522937 |    625.625844 | Matt Martyniuk                                                                                                                                                        |
| 900 |    741.187656 |    578.006417 | Roberto Díaz Sibaja                                                                                                                                                   |
| 901 |    888.778249 |    359.004354 | Ferran Sayol                                                                                                                                                          |
| 902 |    128.316307 |    796.730857 | Manabu Bessho-Uehara                                                                                                                                                  |
| 903 |    281.743395 |    245.703177 | Beth Reinke                                                                                                                                                           |
| 904 |    198.170997 |    389.078400 | Heinrich Harder (vectorized by William Gearty)                                                                                                                        |
| 905 |     42.533214 |    547.026826 | NA                                                                                                                                                                    |
| 906 |    558.577552 |    478.930444 | Andy Wilson                                                                                                                                                           |
| 907 |    561.403479 |    175.086467 | Michelle Site                                                                                                                                                         |
| 908 |    963.140228 |     60.311478 | Ludwik Gąsiorowski                                                                                                                                                    |
| 909 |    603.931392 |    624.321646 | Erika Schumacher                                                                                                                                                      |
| 910 |    198.297421 |    485.486202 | Carlos Cano-Barbacil                                                                                                                                                  |
| 911 |    590.737478 |    709.110491 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 912 |    749.827573 |    137.816622 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 913 |    723.162080 |    686.747999 | Caleb M. Brown                                                                                                                                                        |
| 914 |    500.950513 |     33.243957 | Zimices                                                                                                                                                               |
| 915 |    280.823800 |    258.663582 | Alexis Simon                                                                                                                                                          |
| 916 |    819.708934 |    524.794871 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                                     |

    #> Your tweet has been posted!
