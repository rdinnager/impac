
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

Geoff Shaw, Rebecca Groom, Milton Tan, Matt Crook, Steven Traver, Chris
huh, Kai R. Caspar, Tasman Dixon, Sergio A. Muñoz-Gómez, Terpsichores,
S.Martini, Margot Michaud, Matt Martyniuk, T. Michael Keesey, Jagged
Fang Designs, Gareth Monger, Christoph Schomburg, Joanna Wolfe, Birgit
Lang; original image by virmisco.org, CNZdenek, Pete Buchholz, Emily
Willoughby, Kent Elson Sorgon, Nobu Tamura (vectorized by T. Michael
Keesey), Lankester Edwin Ray (vectorized by T. Michael Keesey), Noah
Schlottman, photo from Casey Dunn, Marie Russell, Tony Ayling, Zimices,
Maija Karala, Birgit Lang, Ghedoghedo (vectorized by T. Michael Keesey),
Conty (vectorized by T. Michael Keesey), Armin Reindl, Scott Hartman,
Stephen O’Connor (vectorized by T. Michael Keesey), Ellen Edmonson and
Hugh Chrisp (vectorized by T. Michael Keesey), FunkMonk, Matt Dempsey,
Xavier Giroux-Bougard, Caleb M. Brown, Martin R. Smith, after Skovsted
et al 2015, Michael Scroggie, Gabriela Palomo-Munoz, Melissa Broussard,
Dmitry Bogdanov (vectorized by T. Michael Keesey), Daniel Stadtmauer, C.
Camilo Julián-Caballero, Markus A. Grohme, Scott Hartman, modified by T.
Michael Keesey, Mathew Wedel, Aleksey Nagovitsyn (vectorized by T.
Michael Keesey), James Neenan, xgirouxb, Crystal Maier, Ignacio
Contreras, Hans Hillewaert, Nobu Tamura, vectorized by Zimices, Tyler
Greenfield, Raven Amos, Sam Droege (photo) and T. Michael Keesey
(vectorization), Alexander Schmidt-Lebuhn, Yan Wong from illustration by
Charles Orbigny, David Tana, Scarlet23 (vectorized by T. Michael
Keesey), Ferran Sayol, Mattia Menchetti, Sharon Wegner-Larsen, Jimmy
Bernot, Audrey Ely, Frank Denota, Collin Gross, Liftarn, Obsidian Soul
(vectorized by T. Michael Keesey), Michelle Site, Jan A. Venter, Herbert
H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael
Keesey), Felix Vaux, Pollyanna von Knorring and T. Michael Keesey,
Andrew A. Farke, Cesar Julian, Joe Schneid (vectorized by T. Michael
Keesey), Lukasiniho, Stuart Humphries, Beth Reinke, Griensteidl and T.
Michael Keesey, Neil Kelley, T. Michael Keesey (photo by Sean Mack), B.
Duygu Özpolat, Mason McNair, Sarah Werning, T. Michael Keesey (after
Heinrich Harder), Jaime Headden (vectorized by T. Michael Keesey),
Mattia Menchetti / Yan Wong, Matthias Buschmann (vectorized by T.
Michael Keesey), Tracy A. Heath, Mercedes Yrayzoz (vectorized by T.
Michael Keesey), Karla Martinez, Maxime Dahirel (digitisation), Kees van
Achterberg et al (doi: 10.3897/BDJ.8.e49017)(original publication),
Darius Nau, ArtFavor & annaleeblysse, NASA, Elizabeth Parker, Smokeybjb,
Steven Coombs, Jose Carlos Arenas-Monroy, Didier Descouens (vectorized
by T. Michael Keesey), Harold N Eyster, Doug Backlund (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Martin R. Smith,
DW Bapst (modified from Bulman, 1970), James R. Spotila and Ray
Chatterji, Cristina Guijarro, Dean Schnabel, Original photo by Andrew
Murray, vectorized by Roberto Díaz Sibaja, Matthew Hooge (vectorized by
T. Michael Keesey), Qiang Ou, T. Michael Keesey (after Mivart),
Ville-Veikko Sinkkonen, Jaime Headden, modified by T. Michael Keesey,
Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela
Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough
(vectorized by T. Michael Keesey), Nicholas J. Czaplewski, vectorized by
Zimices, Robbie N. Cada (vectorized by T. Michael Keesey), Kimberly
Haddrell, Courtney Rockenbach, Andrés Sánchez, H. F. O. March (modified
by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel), Verdilak,
Adrian Reich, L. Shyamal, Lafage, Sidney Frederic Harmer, Arthur Everett
Shipley (vectorized by Maxime Dahirel), T. Michael Keesey (after C. De
Muizon), Javiera Constanzo, Mali’o Kodis, traced image from the National
Science Foundation’s Turbellarian Taxonomic Database, Mareike C. Janiak,
Jon M Laurent, Tauana J. Cunha, U.S. Fish and Wildlife Service
(illustration) and Timothy J. Bartley (silhouette), Chuanixn Yu, Andreas
Trepte (vectorized by T. Michael Keesey), Julio Garza, Henry Lydecker,
Trond R. Oskars, Katie S. Collins, Agnello Picorelli, Jan Sevcik
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Mathew Stewart, A. R. McCulloch (vectorized by T. Michael
Keesey), Ludwik Gasiorowski, Philip Chalmers (vectorized by T. Michael
Keesey), Matt Celeskey, Berivan Temiz, Don Armstrong, Karl Ragnar
Gjertsen (vectorized by T. Michael Keesey), FunkMonk \[Michael B.H.\]
(modified by T. Michael Keesey), Amanda Katzer, Henry Fairfield Osborn,
vectorized by Zimices, Curtis Clark and T. Michael Keesey, A. H. Baldwin
(vectorized by T. Michael Keesey), Darren Naish (vectorized by T.
Michael Keesey), Rafael Maia, Sean McCann, Kamil S. Jaron, C.
Abraczinskas, Noah Schlottman, Mathieu Basille, Ernst Haeckel
(vectorized by T. Michael Keesey), Oscar Sanisidro, Jaime Headden, H. F.
O. March (vectorized by T. Michael Keesey), Ray Simpson (vectorized by
T. Michael Keesey), John Gould (vectorized by T. Michael Keesey), Ingo
Braasch, Javier Luque, Darren Naish (vectorize by T. Michael Keesey),
John Conway, Ekaterina Kopeykina (vectorized by T. Michael Keesey),
Duane Raver/USFWS, Scott Reid, Chloé Schmidt, Carlos Cano-Barbacil,
Dmitry Bogdanov, Andrew A. Farke, shell lines added by Yan Wong, Nobu
Tamura, Jack Mayer Wood, George Edward Lodge (modified by T. Michael
Keesey), Roberto Díaz Sibaja, Michael Day, NOAA Great Lakes
Environmental Research Laboratory (illustration) and Timothy J. Bartley
(silhouette), Abraão Leite, Eyal Bartov, Alexandra van der Geer,
Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja,
Danny Cicchetti (vectorized by T. Michael Keesey), Ben Liebeskind,
Maxime Dahirel, Hans Hillewaert (vectorized by T. Michael Keesey), Mykle
Hoban, Manabu Bessho-Uehara, Joseph Wolf, 1863 (vectorization by Dinah
Challen), Matt Hayes, Walter Vladimir, Michele M Tobias from an image By
Dcrjsr - Own work, CC BY 3.0,
<https://commons.wikimedia.org/w/index.php?curid=18059686>, Jake Warner,
Matthew E. Clapham, Kanchi Nanjo, JCGiron, Mo Hassan, Arthur Grosset
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Craig Dylke, David Liao, Mike Hanson, Mali’o Kodis, image by
Rebecca Ritger, Renata F. Martins, T. Michael Keesey (after Marek
Velechovský), T. Michael Keesey (from a photo by Maximilian Paradiz),
Dein Freund der Baum (vectorized by T. Michael Keesey), T. Michael
Keesey and Tanetahi, Thibaut Brunet, Mathilde Cordellier,
SauropodomorphMonarch, George Edward Lodge (vectorized by T. Michael
Keesey), Benjamint444, David Orr, Hanyong Pu, Yoshitsugu Kobayashi,
Junchang Lü, Li Xu, Yanhua Wu, Huali Chang, Jiming Zhang, Songhai Jia &
T. Michael Keesey, Tommaso Cancellario, Birgit Szabo, Nobu Tamura
(vectorized by A. Verrière), Armelle Ansart (photograph), Maxime Dahirel
(digitisation), Michele Tobias, Josep Marti Solans, Vanessa Guerra,
Alexandre Vong, New York Zoological Society, Pranav Iyer (grey ideas),
Michael Scroggie, from original photograph by John Bettaso, USFWS
(original photograph in public domain)., Brad McFeeters (vectorized by
T. Michael Keesey), Cathy, Alex Slavenko, SecretJellyMan, Bennet
McComish, photo by Hans Hillewaert, Ville Koistinen and T. Michael
Keesey, Siobhon Egan, Plukenet, Yan Wong from drawing by Joseph Smit,
Martin R. Smith, from photo by Jürgen Schoner, Taro Maeda, (after
Spotila 2004), Noah Schlottman, photo by Carol Cummings, Jiekun He,
Becky Barnes, T. Michael Keesey (vectorization) and Nadiatalent
(photography), Smokeybjb (vectorized by T. Michael Keesey), M. Garfield
& K. Anderson (modified by T. Michael Keesey), Julia B McHugh, Kailah
Thorn & Mark Hutchinson, Stacy Spensley (Modified), Ieuan Jones, Óscar
San-Isidro (vectorized by T. Michael Keesey), Scott Hartman (modified by
T. Michael Keesey), Andrew Farke and Joseph Sertich, Robert Gay,
terngirl, Auckland Museum and T. Michael Keesey, Robert Bruce Horsfall,
vectorized by Zimices, Chris Jennings (Risiatto), Ghedo and T. Michael
Keesey, T. Tischler, Robert Gay, modified from FunkMonk (Michael B.H.)
and T. Michael Keesey., Tyler McCraney, Yan Wong

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    364.749088 |    687.852645 | Geoff Shaw                                                                                                                                                            |
|   2 |     84.940591 |    723.782034 | Rebecca Groom                                                                                                                                                         |
|   3 |    316.728709 |    746.500916 | Milton Tan                                                                                                                                                            |
|   4 |    696.189568 |    603.460190 | Matt Crook                                                                                                                                                            |
|   5 |    891.660488 |    572.744805 | Steven Traver                                                                                                                                                         |
|   6 |    121.391107 |    464.135187 | Chris huh                                                                                                                                                             |
|   7 |    278.343467 |     79.785657 | Chris huh                                                                                                                                                             |
|   8 |    341.837232 |    284.352284 | Kai R. Caspar                                                                                                                                                         |
|   9 |    821.293471 |    403.062142 | Steven Traver                                                                                                                                                         |
|  10 |    234.015592 |    492.983112 | Tasman Dixon                                                                                                                                                          |
|  11 |    833.117052 |    220.807407 | NA                                                                                                                                                                    |
|  12 |    741.301719 |    278.197729 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
|  13 |    557.176811 |    524.155913 | Terpsichores                                                                                                                                                          |
|  14 |    175.304367 |    579.053489 | S.Martini                                                                                                                                                             |
|  15 |    832.136604 |    684.855889 | Margot Michaud                                                                                                                                                        |
|  16 |     89.142888 |    122.086907 | Matt Martyniuk                                                                                                                                                        |
|  17 |    393.013781 |    565.353562 | T. Michael Keesey                                                                                                                                                     |
|  18 |    169.780202 |    382.888505 | Jagged Fang Designs                                                                                                                                                   |
|  19 |    947.800785 |    746.876688 | Matt Crook                                                                                                                                                            |
|  20 |    614.427146 |    758.850602 | Gareth Monger                                                                                                                                                         |
|  21 |    394.582068 |    413.294267 | Christoph Schomburg                                                                                                                                                   |
|  22 |    510.880831 |     80.735537 | Gareth Monger                                                                                                                                                         |
|  23 |    617.876566 |    107.658011 | Joanna Wolfe                                                                                                                                                          |
|  24 |    490.499283 |    162.825233 | Birgit Lang; original image by virmisco.org                                                                                                                           |
|  25 |    745.404553 |     17.195287 | Margot Michaud                                                                                                                                                        |
|  26 |    847.456022 |     72.620498 | CNZdenek                                                                                                                                                              |
|  27 |    189.927745 |    184.393095 | Pete Buchholz                                                                                                                                                         |
|  28 |    112.746004 |    312.761345 | Emily Willoughby                                                                                                                                                      |
|  29 |    940.551440 |    264.303166 | Kent Elson Sorgon                                                                                                                                                     |
|  30 |    355.710335 |    500.194602 | Joanna Wolfe                                                                                                                                                          |
|  31 |    646.724040 |    189.726914 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  32 |    380.746957 |     30.283765 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                                 |
|  33 |    961.784486 |    382.475798 | Matt Crook                                                                                                                                                            |
|  34 |    734.404429 |    443.243184 | NA                                                                                                                                                                    |
|  35 |    949.881735 |    173.500418 | Margot Michaud                                                                                                                                                        |
|  36 |    257.912594 |    232.543589 | Noah Schlottman, photo from Casey Dunn                                                                                                                                |
|  37 |    757.505358 |    754.610221 | Marie Russell                                                                                                                                                         |
|  38 |    274.206971 |    407.386305 | Chris huh                                                                                                                                                             |
|  39 |    857.143151 |    337.867662 | Tony Ayling                                                                                                                                                           |
|  40 |    408.703421 |     95.505724 | Zimices                                                                                                                                                               |
|  41 |    665.562015 |    686.745472 | Maija Karala                                                                                                                                                          |
|  42 |     96.738668 |    600.062235 | Birgit Lang                                                                                                                                                           |
|  43 |    621.437031 |    480.479915 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
|  44 |    525.563248 |    349.934124 | Margot Michaud                                                                                                                                                        |
|  45 |    612.049671 |    401.160668 | Margot Michaud                                                                                                                                                        |
|  46 |    908.719778 |    481.112792 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
|  47 |    506.458470 |    275.391229 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  48 |    208.934311 |    725.514127 | Armin Reindl                                                                                                                                                          |
|  49 |    479.108216 |    610.448198 | Birgit Lang                                                                                                                                                           |
|  50 |    247.270617 |    349.774362 | Scott Hartman                                                                                                                                                         |
|  51 |    483.505064 |    418.398095 | Zimices                                                                                                                                                               |
|  52 |    600.037128 |     19.412423 | Stephen O’Connor (vectorized by T. Michael Keesey)                                                                                                                    |
|  53 |    612.178836 |    276.168831 | Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey)                                                                                                      |
|  54 |     84.818579 |    525.786280 | FunkMonk                                                                                                                                                              |
|  55 |    683.053743 |    523.696926 | Zimices                                                                                                                                                               |
|  56 |    258.862919 |    557.613811 | Margot Michaud                                                                                                                                                        |
|  57 |    366.862063 |    625.045364 | Matt Dempsey                                                                                                                                                          |
|  58 |    134.630693 |    243.883961 | NA                                                                                                                                                                    |
|  59 |    154.612350 |     27.576373 | Zimices                                                                                                                                                               |
|  60 |    462.682231 |    217.285588 | Xavier Giroux-Bougard                                                                                                                                                 |
|  61 |     65.864684 |     41.857318 | Caleb M. Brown                                                                                                                                                        |
|  62 |     25.996047 |    281.450874 | Martin R. Smith, after Skovsted et al 2015                                                                                                                            |
|  63 |    117.186209 |    678.643596 | Michael Scroggie                                                                                                                                                      |
|  64 |    372.219623 |    178.383321 | Scott Hartman                                                                                                                                                         |
|  65 |    962.964745 |     59.969502 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  66 |    588.737600 |    596.187139 | Melissa Broussard                                                                                                                                                     |
|  67 |     99.206616 |    423.692933 | Margot Michaud                                                                                                                                                        |
|  68 |     64.323768 |    762.512131 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  69 |    154.464982 |    503.381325 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  70 |    821.116879 |     24.311974 | Daniel Stadtmauer                                                                                                                                                     |
|  71 |    501.200029 |    457.945693 | Chris huh                                                                                                                                                             |
|  72 |    309.397576 |    142.232067 | Scott Hartman                                                                                                                                                         |
|  73 |    857.857519 |    634.005000 | C. Camilo Julián-Caballero                                                                                                                                            |
|  74 |    600.731604 |    232.306272 | Markus A. Grohme                                                                                                                                                      |
|  75 |    395.984975 |    352.225299 | Scott Hartman, modified by T. Michael Keesey                                                                                                                          |
|  76 |    119.724411 |    777.109561 | T. Michael Keesey                                                                                                                                                     |
|  77 |    958.243622 |    111.212658 | Markus A. Grohme                                                                                                                                                      |
|  78 |    826.106130 |    509.433790 | Matt Dempsey                                                                                                                                                          |
|  79 |    951.144724 |    675.746502 | Scott Hartman                                                                                                                                                         |
|  80 |    744.981012 |     61.948741 | Markus A. Grohme                                                                                                                                                      |
|  81 |    247.033629 |    460.091300 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  82 |    627.134357 |    699.112236 | Mathew Wedel                                                                                                                                                          |
|  83 |    762.620385 |    133.057045 | Jagged Fang Designs                                                                                                                                                   |
|  84 |    210.691128 |    309.728220 | Geoff Shaw                                                                                                                                                            |
|  85 |    637.127627 |    332.734060 | Caleb M. Brown                                                                                                                                                        |
|  86 |    233.526248 |     36.037830 | Steven Traver                                                                                                                                                         |
|  87 |    936.879289 |    354.613817 | Aleksey Nagovitsyn (vectorized by T. Michael Keesey)                                                                                                                  |
|  88 |    723.899543 |    369.658884 | Matt Crook                                                                                                                                                            |
|  89 |    346.405444 |    452.289700 | Gareth Monger                                                                                                                                                         |
|  90 |    781.547825 |    370.793685 | Steven Traver                                                                                                                                                         |
|  91 |    850.165917 |    750.141781 | Birgit Lang                                                                                                                                                           |
|  92 |    870.495789 |    719.667840 | James Neenan                                                                                                                                                          |
|  93 |    978.264144 |    486.492992 | Chris huh                                                                                                                                                             |
|  94 |    119.394864 |    142.198622 | Rebecca Groom                                                                                                                                                         |
|  95 |    239.565008 |     19.412014 | xgirouxb                                                                                                                                                              |
|  96 |    201.258817 |    567.241357 | FunkMonk                                                                                                                                                              |
|  97 |    168.192285 |    739.448573 | Crystal Maier                                                                                                                                                         |
|  98 |    316.042345 |    193.730271 | Matt Crook                                                                                                                                                            |
|  99 |    193.534287 |    431.940982 | Ignacio Contreras                                                                                                                                                     |
| 100 |   1008.354026 |    253.150861 | Matt Crook                                                                                                                                                            |
| 101 |    840.762854 |    618.745201 | Hans Hillewaert                                                                                                                                                       |
| 102 |     20.913891 |    599.853758 | Birgit Lang                                                                                                                                                           |
| 103 |    170.924944 |     99.419673 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 104 |    689.284075 |    757.826356 | Jagged Fang Designs                                                                                                                                                   |
| 105 |    736.884775 |     93.611983 | Tasman Dixon                                                                                                                                                          |
| 106 |    695.226176 |    151.955432 | Zimices                                                                                                                                                               |
| 107 |     44.632773 |    206.164334 | NA                                                                                                                                                                    |
| 108 |    934.516062 |    775.334696 | Matt Crook                                                                                                                                                            |
| 109 |    877.546667 |    364.961703 | Tyler Greenfield                                                                                                                                                      |
| 110 |   1001.227453 |    446.267788 | Raven Amos                                                                                                                                                            |
| 111 |    781.105956 |    612.667448 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 112 |    504.981753 |    500.973145 | CNZdenek                                                                                                                                                              |
| 113 |    468.757684 |    320.741069 | Sam Droege (photo) and T. Michael Keesey (vectorization)                                                                                                              |
| 114 |    787.521509 |    105.417289 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 115 |    162.636941 |    120.799059 | Matt Crook                                                                                                                                                            |
| 116 |    872.103056 |    736.856502 | Jagged Fang Designs                                                                                                                                                   |
| 117 |    212.930256 |    644.802571 | Christoph Schomburg                                                                                                                                                   |
| 118 |     11.873383 |    337.246398 | Gareth Monger                                                                                                                                                         |
| 119 |     16.394897 |    185.552976 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 120 |    451.753991 |    493.827472 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 121 |    186.445906 |    680.400435 | Yan Wong from illustration by Charles Orbigny                                                                                                                         |
| 122 |    277.012914 |      9.567198 | David Tana                                                                                                                                                            |
| 123 |    694.384084 |     88.976898 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 124 |    848.481881 |    107.346720 | Markus A. Grohme                                                                                                                                                      |
| 125 |    641.157746 |    313.271882 | Jagged Fang Designs                                                                                                                                                   |
| 126 |    758.162083 |    678.976400 | Chris huh                                                                                                                                                             |
| 127 |    674.833506 |     13.614256 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                                           |
| 128 |    839.123016 |    424.009072 | Ferran Sayol                                                                                                                                                          |
| 129 |    755.666210 |    538.094705 | Mattia Menchetti                                                                                                                                                      |
| 130 |    570.042398 |    457.160567 | Sharon Wegner-Larsen                                                                                                                                                  |
| 131 |    552.825959 |    644.685529 | Jimmy Bernot                                                                                                                                                          |
| 132 |    468.910041 |     98.338418 | Audrey Ely                                                                                                                                                            |
| 133 |    416.953481 |    773.647177 | Tasman Dixon                                                                                                                                                          |
| 134 |    972.036885 |    482.173475 | Frank Denota                                                                                                                                                          |
| 135 |    252.749159 |    701.887465 | Matt Crook                                                                                                                                                            |
| 136 |    900.625642 |    317.101822 | Collin Gross                                                                                                                                                          |
| 137 |    872.915891 |    457.340698 | Liftarn                                                                                                                                                               |
| 138 |     28.483326 |    643.967938 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 139 |    298.973808 |    597.961991 | Michelle Site                                                                                                                                                         |
| 140 |    926.503691 |    214.335474 | Ignacio Contreras                                                                                                                                                     |
| 141 |    157.859834 |    509.833185 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 142 |    592.769049 |    709.716874 | Felix Vaux                                                                                                                                                            |
| 143 |    997.602543 |    634.648068 | NA                                                                                                                                                                    |
| 144 |    779.553312 |    573.019217 | Jagged Fang Designs                                                                                                                                                   |
| 145 |    518.871295 |     27.084869 | Pollyanna von Knorring and T. Michael Keesey                                                                                                                          |
| 146 |    892.792768 |    456.113098 | Chris huh                                                                                                                                                             |
| 147 |    377.753780 |    441.983103 | Markus A. Grohme                                                                                                                                                      |
| 148 |    930.608649 |    293.540668 | Felix Vaux                                                                                                                                                            |
| 149 |     94.883826 |    200.819951 | Gareth Monger                                                                                                                                                         |
| 150 |     53.707223 |    328.209515 | Zimices                                                                                                                                                               |
| 151 |    411.141760 |    247.544605 | Steven Traver                                                                                                                                                         |
| 152 |    271.783395 |    702.247294 | Andrew A. Farke                                                                                                                                                       |
| 153 |    947.780865 |    299.568762 | Cesar Julian                                                                                                                                                          |
| 154 |    470.102387 |    241.165145 | Michael Scroggie                                                                                                                                                      |
| 155 |    872.822536 |    422.802667 | Joe Schneid (vectorized by T. Michael Keesey)                                                                                                                         |
| 156 |     47.701368 |    253.797186 | Margot Michaud                                                                                                                                                        |
| 157 |    814.734443 |    562.183627 | Pete Buchholz                                                                                                                                                         |
| 158 |    941.499451 |     12.531901 | Lukasiniho                                                                                                                                                            |
| 159 |    310.666637 |      9.778921 | Stuart Humphries                                                                                                                                                      |
| 160 |    835.833813 |    372.139054 | Scott Hartman                                                                                                                                                         |
| 161 |    702.391906 |    663.820487 | NA                                                                                                                                                                    |
| 162 |    108.090371 |     49.606358 | Zimices                                                                                                                                                               |
| 163 |    343.225248 |    589.483320 | Beth Reinke                                                                                                                                                           |
| 164 |    932.011429 |    633.411782 | Jagged Fang Designs                                                                                                                                                   |
| 165 |    366.166589 |    655.444634 | Scott Hartman                                                                                                                                                         |
| 166 |    284.995098 |    187.461743 | Chris huh                                                                                                                                                             |
| 167 |    250.074714 |    149.321884 | Jagged Fang Designs                                                                                                                                                   |
| 168 |    796.705089 |    678.192331 | Griensteidl and T. Michael Keesey                                                                                                                                     |
| 169 |    116.785140 |    304.753161 | Maija Karala                                                                                                                                                          |
| 170 |    101.256889 |    531.997531 | Neil Kelley                                                                                                                                                           |
| 171 |    774.538874 |    581.191223 | Margot Michaud                                                                                                                                                        |
| 172 |    780.395377 |    318.841383 | Christoph Schomburg                                                                                                                                                   |
| 173 |    568.799598 |    717.641733 | Armin Reindl                                                                                                                                                          |
| 174 |    508.202060 |    403.136994 | Matt Crook                                                                                                                                                            |
| 175 |    543.585785 |    792.844472 | Matt Crook                                                                                                                                                            |
| 176 |    854.012720 |    737.401350 | T. Michael Keesey (photo by Sean Mack)                                                                                                                                |
| 177 |    672.740132 |    789.950160 | Steven Traver                                                                                                                                                         |
| 178 |    573.409540 |     48.250212 | B. Duygu Özpolat                                                                                                                                                      |
| 179 |   1008.896995 |    397.904927 | Mason McNair                                                                                                                                                          |
| 180 |    478.056360 |    547.483054 | Sarah Werning                                                                                                                                                         |
| 181 |    384.945176 |    148.199126 | Scott Hartman                                                                                                                                                         |
| 182 |    670.049978 |     47.309013 | T. Michael Keesey (after Heinrich Harder)                                                                                                                             |
| 183 |    604.064147 |    519.661250 | Jaime Headden (vectorized by T. Michael Keesey)                                                                                                                       |
| 184 |    587.608050 |    651.061204 | Jagged Fang Designs                                                                                                                                                   |
| 185 |     12.682997 |    143.547548 | Mattia Menchetti / Yan Wong                                                                                                                                           |
| 186 |     47.810770 |     65.110592 | Margot Michaud                                                                                                                                                        |
| 187 |    651.188685 |     19.115926 | NA                                                                                                                                                                    |
| 188 |     45.024858 |      6.311343 | Matt Crook                                                                                                                                                            |
| 189 |    807.763576 |    753.835590 | Armin Reindl                                                                                                                                                          |
| 190 |    404.992650 |    633.884806 | Beth Reinke                                                                                                                                                           |
| 191 |    544.380357 |    194.839492 | Zimices                                                                                                                                                               |
| 192 |    205.396118 |    156.919101 | Matthias Buschmann (vectorized by T. Michael Keesey)                                                                                                                  |
| 193 |    827.758107 |    475.608008 | Zimices                                                                                                                                                               |
| 194 |    512.681427 |    624.518300 | Tracy A. Heath                                                                                                                                                        |
| 195 |    487.188102 |    232.552581 | Chris huh                                                                                                                                                             |
| 196 |    182.636709 |    401.106772 | Mercedes Yrayzoz (vectorized by T. Michael Keesey)                                                                                                                    |
| 197 |    197.415936 |     72.241399 | Christoph Schomburg                                                                                                                                                   |
| 198 |    543.804425 |    475.004660 | Maija Karala                                                                                                                                                          |
| 199 |    863.631427 |    272.037954 | Collin Gross                                                                                                                                                          |
| 200 |     51.305769 |     85.201369 | Karla Martinez                                                                                                                                                        |
| 201 |    924.606590 |    646.258578 | Matt Dempsey                                                                                                                                                          |
| 202 |    268.887764 |    180.372259 | Rebecca Groom                                                                                                                                                         |
| 203 |    109.259223 |    387.285101 | Maxime Dahirel (digitisation), Kees van Achterberg et al (doi: 10.3897/BDJ.8.e49017)(original publication)                                                            |
| 204 |    815.589761 |    660.790278 | Matt Martyniuk                                                                                                                                                        |
| 205 |    871.516988 |    779.250074 | NA                                                                                                                                                                    |
| 206 |    303.839313 |    435.810737 | Darius Nau                                                                                                                                                            |
| 207 |    651.727561 |     36.149538 | FunkMonk                                                                                                                                                              |
| 208 |     17.939996 |    148.211328 | ArtFavor & annaleeblysse                                                                                                                                              |
| 209 |    864.174762 |    481.513853 | NASA                                                                                                                                                                  |
| 210 |    297.116204 |    615.894176 | Elizabeth Parker                                                                                                                                                      |
| 211 |    468.522024 |    531.138114 | Collin Gross                                                                                                                                                          |
| 212 |    736.428610 |    344.322796 | Matt Crook                                                                                                                                                            |
| 213 |    367.771926 |    210.106608 | Smokeybjb                                                                                                                                                             |
| 214 |    246.671382 |    662.474230 | Steven Coombs                                                                                                                                                         |
| 215 |    952.918869 |    520.706594 | T. Michael Keesey                                                                                                                                                     |
| 216 |    977.809712 |    323.266190 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 217 |    547.774470 |    623.819351 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 218 |    104.939045 |    119.455116 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 219 |    334.668074 |    132.014423 | xgirouxb                                                                                                                                                              |
| 220 |    759.368485 |    314.773390 | Harold N Eyster                                                                                                                                                       |
| 221 |    886.638534 |    286.238622 | T. Michael Keesey                                                                                                                                                     |
| 222 |    286.764150 |    175.287710 | Doug Backlund (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey         |
| 223 |    993.626500 |    682.689042 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 224 |    127.028093 |    547.903285 | Steven Traver                                                                                                                                                         |
| 225 |    431.575713 |    785.454928 | Lukasiniho                                                                                                                                                            |
| 226 |    488.515327 |    579.249250 | Martin R. Smith                                                                                                                                                       |
| 227 |    791.214439 |    190.043212 | DW Bapst (modified from Bulman, 1970)                                                                                                                                 |
| 228 |    745.086952 |    567.089628 | James R. Spotila and Ray Chatterji                                                                                                                                    |
| 229 |    664.189794 |    310.564751 | T. Michael Keesey                                                                                                                                                     |
| 230 |    995.745785 |    430.621154 | Scott Hartman                                                                                                                                                         |
| 231 |    650.432373 |    568.006234 | Cristina Guijarro                                                                                                                                                     |
| 232 |    404.235694 |    454.366810 | Michael Scroggie                                                                                                                                                      |
| 233 |    928.556480 |    622.795432 | Smokeybjb                                                                                                                                                             |
| 234 |    121.977499 |    437.472554 | Xavier Giroux-Bougard                                                                                                                                                 |
| 235 |    945.319129 |    317.790331 | Dean Schnabel                                                                                                                                                         |
| 236 |     26.893168 |    495.255616 | Scott Hartman                                                                                                                                                         |
| 237 |     34.970440 |     75.424881 | Ferran Sayol                                                                                                                                                          |
| 238 |    395.052291 |    787.361960 | Birgit Lang                                                                                                                                                           |
| 239 |    766.539288 |    643.381956 | Collin Gross                                                                                                                                                          |
| 240 |    447.886590 |    251.113641 | Matt Crook                                                                                                                                                            |
| 241 |    167.710050 |    542.577704 | Sarah Werning                                                                                                                                                         |
| 242 |    731.079859 |    165.640442 | Tracy A. Heath                                                                                                                                                        |
| 243 |    795.810235 |    473.491315 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 244 |    534.932741 |    114.419039 | Original photo by Andrew Murray, vectorized by Roberto Díaz Sibaja                                                                                                    |
| 245 |    452.714545 |    447.048609 | Jagged Fang Designs                                                                                                                                                   |
| 246 |    599.696253 |    195.237789 | Matthew Hooge (vectorized by T. Michael Keesey)                                                                                                                       |
| 247 |    869.894711 |    247.032781 | Zimices                                                                                                                                                               |
| 248 |    186.318161 |     60.567979 | Matt Crook                                                                                                                                                            |
| 249 |    981.478154 |    469.908214 | Zimices                                                                                                                                                               |
| 250 |    441.007938 |    513.409296 | Ignacio Contreras                                                                                                                                                     |
| 251 |     38.977509 |    375.946535 | Margot Michaud                                                                                                                                                        |
| 252 |      9.039930 |    577.918494 | Zimices                                                                                                                                                               |
| 253 |    198.429973 |    407.682344 | Chris huh                                                                                                                                                             |
| 254 |    735.341821 |    783.855074 | S.Martini                                                                                                                                                             |
| 255 |    497.524001 |     15.722448 | Qiang Ou                                                                                                                                                              |
| 256 |    786.794622 |    282.519921 | T. Michael Keesey (after Mivart)                                                                                                                                      |
| 257 |   1004.270122 |    585.626745 | Sarah Werning                                                                                                                                                         |
| 258 |    410.253206 |    420.688532 | CNZdenek                                                                                                                                                              |
| 259 |    919.057855 |    731.584801 | Margot Michaud                                                                                                                                                        |
| 260 |    814.184187 |    247.538173 | C. Camilo Julián-Caballero                                                                                                                                            |
| 261 |    964.809237 |     13.682842 | Margot Michaud                                                                                                                                                        |
| 262 |     11.038880 |    430.917474 | Ville-Veikko Sinkkonen                                                                                                                                                |
| 263 |    550.159183 |    563.368544 | Ferran Sayol                                                                                                                                                          |
| 264 |    198.670904 |    525.318923 | Jaime Headden, modified by T. Michael Keesey                                                                                                                          |
| 265 |    163.050730 |    576.430921 | Matt Crook                                                                                                                                                            |
| 266 |    523.192618 |    412.047966 | B. Duygu Özpolat                                                                                                                                                      |
| 267 |    152.769727 |    301.531414 | Ignacio Contreras                                                                                                                                                     |
| 268 |    533.006943 |    132.895809 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 269 |    271.039892 |    106.304575 | Nicholas J. Czaplewski, vectorized by Zimices                                                                                                                         |
| 270 |    919.389625 |    755.058600 | Scott Hartman                                                                                                                                                         |
| 271 |    182.044812 |    691.039958 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 272 |    673.023172 |    733.471166 | NA                                                                                                                                                                    |
| 273 |    169.517549 |    152.152462 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 274 |    231.598839 |    326.130311 | Dean Schnabel                                                                                                                                                         |
| 275 |   1010.483844 |    663.469681 | Matt Crook                                                                                                                                                            |
| 276 |    661.406354 |    255.161277 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
| 277 |    731.238203 |    204.593174 | Kimberly Haddrell                                                                                                                                                     |
| 278 |     37.436072 |    579.084375 | Zimices                                                                                                                                                               |
| 279 |    898.104161 |    790.298541 | Courtney Rockenbach                                                                                                                                                   |
| 280 |    163.305297 |    785.000282 | Beth Reinke                                                                                                                                                           |
| 281 |    510.529162 |      9.024269 | Andrés Sánchez                                                                                                                                                        |
| 282 |    714.397645 |    243.184366 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 283 |    342.208681 |    712.520482 | Frank Denota                                                                                                                                                          |
| 284 |     69.855087 |    695.817012 | H. F. O. March (modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel)                                                                                  |
| 285 |     10.560170 |     88.373757 | Verdilak                                                                                                                                                              |
| 286 |   1014.798310 |    593.930613 | Adrian Reich                                                                                                                                                          |
| 287 |     31.811954 |    699.997460 | NA                                                                                                                                                                    |
| 288 |    314.477191 |    451.777399 | L. Shyamal                                                                                                                                                            |
| 289 |    297.640938 |    683.518980 | Zimices                                                                                                                                                               |
| 290 |    731.183099 |     40.021600 | Ferran Sayol                                                                                                                                                          |
| 291 |    864.826000 |    257.972351 | Matt Crook                                                                                                                                                            |
| 292 |    249.862642 |    784.689709 | Steven Traver                                                                                                                                                         |
| 293 |    553.671842 |    150.923784 | T. Michael Keesey                                                                                                                                                     |
| 294 |    143.487277 |    750.025286 | Lafage                                                                                                                                                                |
| 295 |    542.822280 |    214.330025 | Jagged Fang Designs                                                                                                                                                   |
| 296 |    360.268825 |    700.113464 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 297 |    574.975986 |    444.735407 | NA                                                                                                                                                                    |
| 298 |    578.584509 |    509.473453 | Gareth Monger                                                                                                                                                         |
| 299 |    759.112692 |    248.395599 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 300 |    461.551200 |    563.963727 | Tasman Dixon                                                                                                                                                          |
| 301 |      9.550403 |    697.584667 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 302 |    379.737398 |     57.204299 | Margot Michaud                                                                                                                                                        |
| 303 |    374.374914 |    590.778098 | Tasman Dixon                                                                                                                                                          |
| 304 |    864.448742 |    132.808451 | Ferran Sayol                                                                                                                                                          |
| 305 |    974.522406 |    515.542458 | Sidney Frederic Harmer, Arthur Everett Shipley (vectorized by Maxime Dahirel)                                                                                         |
| 306 |    437.049161 |    244.004644 | C. Camilo Julián-Caballero                                                                                                                                            |
| 307 |    699.164703 |    538.266303 | T. Michael Keesey (after C. De Muizon)                                                                                                                                |
| 308 |     11.562324 |    678.783885 | Gareth Monger                                                                                                                                                         |
| 309 |    158.628884 |    700.547117 | NA                                                                                                                                                                    |
| 310 |    243.909991 |    679.955928 | Javiera Constanzo                                                                                                                                                     |
| 311 |      4.250513 |     51.168378 | Mali’o Kodis, traced image from the National Science Foundation’s Turbellarian Taxonomic Database                                                                     |
| 312 |     34.137701 |    486.943068 | Matt Crook                                                                                                                                                            |
| 313 |    619.887440 |     52.419429 | Scott Hartman                                                                                                                                                         |
| 314 |    428.657185 |    145.273668 | Mareike C. Janiak                                                                                                                                                     |
| 315 |    669.357831 |    650.863998 | Jon M Laurent                                                                                                                                                         |
| 316 |    844.813555 |    357.036284 | Felix Vaux                                                                                                                                                            |
| 317 |     70.575203 |    283.714931 | NA                                                                                                                                                                    |
| 318 |    260.978149 |    764.791171 | NA                                                                                                                                                                    |
| 319 |    939.677067 |    332.571159 | Tauana J. Cunha                                                                                                                                                       |
| 320 |    913.304059 |    351.193287 | U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                                     |
| 321 |    935.712073 |    522.591479 | Geoff Shaw                                                                                                                                                            |
| 322 |    992.891213 |    618.823675 | Collin Gross                                                                                                                                                          |
| 323 |    733.699272 |    709.488042 | Chuanixn Yu                                                                                                                                                           |
| 324 |   1013.283055 |    507.395731 | Andreas Trepte (vectorized by T. Michael Keesey)                                                                                                                      |
| 325 |    988.137396 |    290.006439 | Julio Garza                                                                                                                                                           |
| 326 |    388.564907 |     66.214767 | Matt Crook                                                                                                                                                            |
| 327 |    925.562901 |    483.473169 | Henry Lydecker                                                                                                                                                        |
| 328 |     81.118813 |     92.582831 | Beth Reinke                                                                                                                                                           |
| 329 |    144.850933 |    354.116397 | Gareth Monger                                                                                                                                                         |
| 330 |    667.915236 |    572.395343 | Verdilak                                                                                                                                                              |
| 331 |   1007.209814 |    606.092625 | Matt Crook                                                                                                                                                            |
| 332 |    120.451783 |    326.730663 | Trond R. Oskars                                                                                                                                                       |
| 333 |    940.087240 |    642.839963 | Zimices                                                                                                                                                               |
| 334 |    557.031188 |    657.662469 | Matt Martyniuk                                                                                                                                                        |
| 335 |    742.716443 |    634.728315 | Katie S. Collins                                                                                                                                                      |
| 336 |    457.860057 |    791.922817 | Margot Michaud                                                                                                                                                        |
| 337 |    795.542175 |    371.864594 | Agnello Picorelli                                                                                                                                                     |
| 338 |    801.397182 |    307.565388 | Jan Sevcik (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey            |
| 339 |    762.938350 |    349.937897 | Mathew Stewart                                                                                                                                                        |
| 340 |     47.954454 |    668.198230 | Gareth Monger                                                                                                                                                         |
| 341 |    542.380028 |    752.474490 | NA                                                                                                                                                                    |
| 342 |    938.480903 |    497.653597 | Matt Crook                                                                                                                                                            |
| 343 |   1009.948735 |    523.804817 | Armin Reindl                                                                                                                                                          |
| 344 |     26.340545 |    415.170146 | NA                                                                                                                                                                    |
| 345 |    182.421509 |    329.370175 | Chris huh                                                                                                                                                             |
| 346 |    898.667658 |    686.287301 | Sarah Werning                                                                                                                                                         |
| 347 |    850.380732 |    714.782568 | T. Michael Keesey                                                                                                                                                     |
| 348 |   1010.761209 |    315.305650 | Margot Michaud                                                                                                                                                        |
| 349 |    409.968778 |    371.401201 | A. R. McCulloch (vectorized by T. Michael Keesey)                                                                                                                     |
| 350 |   1016.446761 |    430.896729 | Ludwik Gasiorowski                                                                                                                                                    |
| 351 |    209.072276 |    556.908349 | T. Michael Keesey                                                                                                                                                     |
| 352 |    946.286442 |    223.994522 | Philip Chalmers (vectorized by T. Michael Keesey)                                                                                                                     |
| 353 |    707.301457 |    612.696150 | Birgit Lang                                                                                                                                                           |
| 354 |    905.399860 |    675.527098 | Matt Celeskey                                                                                                                                                         |
| 355 |    536.895839 |     55.107859 | B. Duygu Özpolat                                                                                                                                                      |
| 356 |    324.450439 |    541.942471 | Zimices                                                                                                                                                               |
| 357 |    710.417699 |    733.738353 | Berivan Temiz                                                                                                                                                         |
| 358 |    678.880214 |     72.298192 | Steven Traver                                                                                                                                                         |
| 359 |    184.839607 |    497.360265 | Don Armstrong                                                                                                                                                         |
| 360 |    811.926370 |    319.642681 | Zimices                                                                                                                                                               |
| 361 |    125.458134 |    130.166221 | Karl Ragnar Gjertsen (vectorized by T. Michael Keesey)                                                                                                                |
| 362 |    553.085707 |     22.098266 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 363 |    522.756800 |    187.758856 | FunkMonk \[Michael B.H.\] (modified by T. Michael Keesey)                                                                                                             |
| 364 |    836.684676 |    782.258863 | Margot Michaud                                                                                                                                                        |
| 365 |    510.348172 |    766.552130 | Katie S. Collins                                                                                                                                                      |
| 366 |    552.679171 |    632.512023 | Steven Traver                                                                                                                                                         |
| 367 |    655.779902 |    548.076441 | Matt Crook                                                                                                                                                            |
| 368 |    493.484293 |    532.883279 | Amanda Katzer                                                                                                                                                         |
| 369 |    174.416114 |    269.968015 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                                         |
| 370 |     11.643540 |    220.010438 | Audrey Ely                                                                                                                                                            |
| 371 |    594.657779 |    640.700834 | Jagged Fang Designs                                                                                                                                                   |
| 372 |    738.579535 |    680.890944 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 373 |    103.843492 |    770.016101 | Curtis Clark and T. Michael Keesey                                                                                                                                    |
| 374 |    122.323997 |    171.653260 | Emily Willoughby                                                                                                                                                      |
| 375 |     84.821711 |     56.314206 | Ferran Sayol                                                                                                                                                          |
| 376 |    700.185121 |    212.345795 | Scott Hartman                                                                                                                                                         |
| 377 |    130.742021 |    789.339931 | Michael Scroggie                                                                                                                                                      |
| 378 |    676.637565 |    480.507328 | Christoph Schomburg                                                                                                                                                   |
| 379 |    343.556876 |    323.847487 | A. H. Baldwin (vectorized by T. Michael Keesey)                                                                                                                       |
| 380 |    803.377893 |    100.041196 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                        |
| 381 |    244.489559 |    691.601214 | Jagged Fang Designs                                                                                                                                                   |
| 382 |    391.241552 |    468.061110 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 383 |    953.084876 |    580.256270 | Rafael Maia                                                                                                                                                           |
| 384 |     69.637929 |    617.849707 | Tasman Dixon                                                                                                                                                          |
| 385 |    233.511699 |    264.288451 | NA                                                                                                                                                                    |
| 386 |     20.629890 |    529.312959 | xgirouxb                                                                                                                                                              |
| 387 |    733.417251 |    725.223734 | Milton Tan                                                                                                                                                            |
| 388 |    835.277193 |    359.163746 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 389 |    688.835339 |    275.894085 | Gareth Monger                                                                                                                                                         |
| 390 |    180.317871 |    416.260710 | Sean McCann                                                                                                                                                           |
| 391 |    895.928635 |    507.317606 | Joanna Wolfe                                                                                                                                                          |
| 392 |    246.617582 |    108.923568 | Birgit Lang                                                                                                                                                           |
| 393 |    788.350626 |    235.480378 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 394 |    233.586919 |    685.426534 | Margot Michaud                                                                                                                                                        |
| 395 |    695.705157 |    576.052928 | Kamil S. Jaron                                                                                                                                                        |
| 396 |    371.955527 |    669.472025 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 397 |    905.837480 |    711.287292 | C. Abraczinskas                                                                                                                                                       |
| 398 |    457.843968 |    129.979316 | Noah Schlottman                                                                                                                                                       |
| 399 |    506.384295 |    643.501982 | Armin Reindl                                                                                                                                                          |
| 400 |    191.349525 |    127.318251 | Doug Backlund (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey         |
| 401 |   1011.096533 |    494.229887 | Steven Traver                                                                                                                                                         |
| 402 |    151.736273 |    129.484723 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 403 |    781.246651 |    341.420742 | Michael Scroggie                                                                                                                                                      |
| 404 |    284.387429 |    212.190499 | Mathieu Basille                                                                                                                                                       |
| 405 |    628.756816 |     31.508535 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                       |
| 406 |    276.412651 |    676.933901 | Maija Karala                                                                                                                                                          |
| 407 |    672.587368 |    707.997943 | Margot Michaud                                                                                                                                                        |
| 408 |    724.583477 |    219.026853 | Margot Michaud                                                                                                                                                        |
| 409 |    573.243343 |    623.375433 | Mason McNair                                                                                                                                                          |
| 410 |    369.633733 |    198.407888 | Margot Michaud                                                                                                                                                        |
| 411 |    645.513597 |    296.830403 | Christoph Schomburg                                                                                                                                                   |
| 412 |    384.757319 |    539.669241 | T. Michael Keesey                                                                                                                                                     |
| 413 |    875.652354 |    153.748181 | Zimices                                                                                                                                                               |
| 414 |    715.021767 |    494.710530 | NA                                                                                                                                                                    |
| 415 |    147.257762 |    570.978344 | Oscar Sanisidro                                                                                                                                                       |
| 416 |    856.416856 |    768.023119 | Michael Scroggie                                                                                                                                                      |
| 417 |    175.140239 |     88.003018 | Jaime Headden                                                                                                                                                         |
| 418 |    399.567907 |    600.860261 | Steven Traver                                                                                                                                                         |
| 419 |    407.211730 |    533.477915 | H. F. O. March (vectorized by T. Michael Keesey)                                                                                                                      |
| 420 |    482.015528 |    640.169484 | Katie S. Collins                                                                                                                                                      |
| 421 |    552.402814 |    292.878551 | Scott Hartman                                                                                                                                                         |
| 422 |      9.693580 |    365.578631 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 423 |    478.612505 |    490.407186 | Ray Simpson (vectorized by T. Michael Keesey)                                                                                                                         |
| 424 |     77.034067 |    366.638823 | NA                                                                                                                                                                    |
| 425 |    986.248087 |    127.935268 | Ignacio Contreras                                                                                                                                                     |
| 426 |    845.473995 |    726.342539 | John Gould (vectorized by T. Michael Keesey)                                                                                                                          |
| 427 |    806.110254 |    212.025610 | Sharon Wegner-Larsen                                                                                                                                                  |
| 428 |    946.128464 |    700.190740 | Scott Hartman                                                                                                                                                         |
| 429 |    301.214152 |    704.188924 | NA                                                                                                                                                                    |
| 430 |    620.775239 |    162.297937 | Adrian Reich                                                                                                                                                          |
| 431 |   1016.710043 |    210.584317 | Gareth Monger                                                                                                                                                         |
| 432 |    880.677887 |    625.171138 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 433 |    727.281563 |    638.327364 | Birgit Lang                                                                                                                                                           |
| 434 |     38.276010 |    684.229943 | Michael Scroggie                                                                                                                                                      |
| 435 |    459.469087 |    629.908052 | Chris huh                                                                                                                                                             |
| 436 |    925.839236 |    220.827689 | Dean Schnabel                                                                                                                                                         |
| 437 |    458.301032 |    106.463500 | Crystal Maier                                                                                                                                                         |
| 438 |    343.539475 |    441.524564 | Matt Crook                                                                                                                                                            |
| 439 |     55.868547 |    480.883030 | Ingo Braasch                                                                                                                                                          |
| 440 |    978.725947 |    747.017668 | T. Michael Keesey                                                                                                                                                     |
| 441 |    424.820786 |    276.850719 | Kamil S. Jaron                                                                                                                                                        |
| 442 |    956.769506 |    649.558921 | Daniel Stadtmauer                                                                                                                                                     |
| 443 |    883.304765 |    224.646872 | FunkMonk                                                                                                                                                              |
| 444 |    425.726442 |    547.849687 | Jagged Fang Designs                                                                                                                                                   |
| 445 |    736.362060 |    177.939510 | Scott Hartman                                                                                                                                                         |
| 446 |     78.713041 |    271.176030 | Scott Hartman                                                                                                                                                         |
| 447 |    548.100445 |     48.391392 | Collin Gross                                                                                                                                                          |
| 448 |    901.493211 |    702.273253 | Zimices                                                                                                                                                               |
| 449 |    821.522315 |    381.958257 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 450 |    889.026927 |     87.442667 | Javier Luque                                                                                                                                                          |
| 451 |    762.560817 |    688.903501 | Ferran Sayol                                                                                                                                                          |
| 452 |    814.836605 |    776.815540 | Zimices                                                                                                                                                               |
| 453 |    486.945636 |    396.576865 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                         |
| 454 |    909.218842 |    495.463163 | Mason McNair                                                                                                                                                          |
| 455 |    347.153313 |    152.967719 | John Conway                                                                                                                                                           |
| 456 |    922.791214 |    236.262320 | Ekaterina Kopeykina (vectorized by T. Michael Keesey)                                                                                                                 |
| 457 |    330.700607 |    778.169294 | Ferran Sayol                                                                                                                                                          |
| 458 |    517.610651 |    791.665461 | Ekaterina Kopeykina (vectorized by T. Michael Keesey)                                                                                                                 |
| 459 |    980.552335 |    417.626813 | Birgit Lang                                                                                                                                                           |
| 460 |    319.028744 |    433.295916 | Duane Raver/USFWS                                                                                                                                                     |
| 461 |     10.450155 |    619.527615 | Ferran Sayol                                                                                                                                                          |
| 462 |    335.657850 |    227.486841 | Scott Reid                                                                                                                                                            |
| 463 |    323.797974 |    791.473599 | Chloé Schmidt                                                                                                                                                         |
| 464 |    525.453350 |    255.928119 | Carlos Cano-Barbacil                                                                                                                                                  |
| 465 |    205.765592 |    400.730025 | T. Michael Keesey                                                                                                                                                     |
| 466 |    450.412661 |    115.670766 | NA                                                                                                                                                                    |
| 467 |     30.402119 |    724.979909 | Dmitry Bogdanov                                                                                                                                                       |
| 468 |    554.234487 |    302.503104 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 469 |    329.137011 |    339.559577 | Mattia Menchetti                                                                                                                                                      |
| 470 |    639.483766 |     33.868560 | Sean McCann                                                                                                                                                           |
| 471 |     66.754635 |    497.457912 | Andrew A. Farke, shell lines added by Yan Wong                                                                                                                        |
| 472 |     37.182243 |    176.927224 | Matt Crook                                                                                                                                                            |
| 473 |    792.208530 |     38.177563 | Gareth Monger                                                                                                                                                         |
| 474 |     81.680207 |    207.427847 | Armin Reindl                                                                                                                                                          |
| 475 |    818.159513 |     49.245801 | Chris huh                                                                                                                                                             |
| 476 |    811.207310 |    796.296354 | Jagged Fang Designs                                                                                                                                                   |
| 477 |    928.520793 |     51.131897 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 478 |    158.546465 |    309.779664 | Smokeybjb                                                                                                                                                             |
| 479 |    369.491738 |    232.522810 | Nobu Tamura                                                                                                                                                           |
| 480 |    978.256335 |    226.272991 | Markus A. Grohme                                                                                                                                                      |
| 481 |    753.477063 |    262.885889 | Jack Mayer Wood                                                                                                                                                       |
| 482 |    118.256854 |    567.481629 | Ferran Sayol                                                                                                                                                          |
| 483 |    814.416487 |    716.554308 | Andrew A. Farke                                                                                                                                                       |
| 484 |    122.635221 |    387.964722 | NA                                                                                                                                                                    |
| 485 |    505.460292 |    556.663152 | George Edward Lodge (modified by T. Michael Keesey)                                                                                                                   |
| 486 |    169.870600 |    775.946995 | Henry Lydecker                                                                                                                                                        |
| 487 |    900.131097 |    223.889863 | Roberto Díaz Sibaja                                                                                                                                                   |
| 488 |    777.967874 |    158.724098 | T. Michael Keesey                                                                                                                                                     |
| 489 |    425.021839 |    388.008994 | Margot Michaud                                                                                                                                                        |
| 490 |    602.461926 |    214.134796 | T. Michael Keesey                                                                                                                                                     |
| 491 |    972.831823 |    540.423857 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 492 |    954.246584 |    447.720499 | Ludwik Gasiorowski                                                                                                                                                    |
| 493 |     57.943241 |    569.607678 | Michael Day                                                                                                                                                           |
| 494 |   1016.618842 |    162.666008 | Beth Reinke                                                                                                                                                           |
| 495 |     14.956948 |    415.741516 | Maxime Dahirel (digitisation), Kees van Achterberg et al (doi: 10.3897/BDJ.8.e49017)(original publication)                                                            |
| 496 |    891.409126 |    438.161149 | Gareth Monger                                                                                                                                                         |
| 497 |     24.513426 |    557.771114 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
| 498 |    677.909563 |    336.867208 | Matt Crook                                                                                                                                                            |
| 499 |    630.590131 |    439.962174 | Zimices                                                                                                                                                               |
| 500 |    760.087421 |    172.673936 | Matt Crook                                                                                                                                                            |
| 501 |    934.801847 |    204.126334 | Matt Crook                                                                                                                                                            |
| 502 |    842.812349 |    481.546214 | Tracy A. Heath                                                                                                                                                        |
| 503 |    624.377116 |    358.823194 | Gareth Monger                                                                                                                                                         |
| 504 |    554.733792 |    120.594746 | Matt Crook                                                                                                                                                            |
| 505 |    642.164397 |    549.898985 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 506 |    749.233133 |    525.352302 | Zimices                                                                                                                                                               |
| 507 |    149.945957 |    280.461055 | Gareth Monger                                                                                                                                                         |
| 508 |     82.663984 |     20.857265 | Matt Martyniuk                                                                                                                                                        |
| 509 |    707.127595 |    425.676548 | Abraão Leite                                                                                                                                                          |
| 510 |     52.753802 |    656.046840 | Margot Michaud                                                                                                                                                        |
| 511 |    817.337865 |    571.094831 | Eyal Bartov                                                                                                                                                           |
| 512 |    735.206942 |    308.016721 | Zimices                                                                                                                                                               |
| 513 |    855.823832 |    445.775332 | C. Camilo Julián-Caballero                                                                                                                                            |
| 514 |    927.148666 |    790.622390 | Scott Hartman                                                                                                                                                         |
| 515 |    772.872204 |    594.120413 | Alexandra van der Geer                                                                                                                                                |
| 516 |    121.839544 |    338.680249 | Scott Hartman                                                                                                                                                         |
| 517 |    679.216541 |    417.032372 | T. Michael Keesey                                                                                                                                                     |
| 518 |    740.220862 |    658.684600 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                                |
| 519 |    402.392197 |    237.094028 | Matt Crook                                                                                                                                                            |
| 520 |    668.834346 |     60.600789 | Collin Gross                                                                                                                                                          |
| 521 |    594.754261 |    356.360368 | Danny Cicchetti (vectorized by T. Michael Keesey)                                                                                                                     |
| 522 |    223.910781 |    143.768286 | NA                                                                                                                                                                    |
| 523 |    539.780784 |     32.825611 | Zimices                                                                                                                                                               |
| 524 |    173.427409 |    210.935143 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 525 |    739.648397 |    196.943669 | T. Michael Keesey                                                                                                                                                     |
| 526 |    226.206116 |    159.002874 | Armin Reindl                                                                                                                                                          |
| 527 |    554.314269 |    766.038762 | Michelle Site                                                                                                                                                         |
| 528 |    895.210534 |    414.816729 | Ben Liebeskind                                                                                                                                                        |
| 529 |    564.935700 |    443.302220 | Maxime Dahirel                                                                                                                                                        |
| 530 |    543.797777 |    609.164701 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 531 |    865.995618 |    140.422468 | Sharon Wegner-Larsen                                                                                                                                                  |
| 532 |    434.119408 |    527.656370 | Chris huh                                                                                                                                                             |
| 533 |    218.456866 |    129.989893 | Ingo Braasch                                                                                                                                                          |
| 534 |    830.502596 |    765.515201 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 535 |    130.755238 |    298.279668 | Mykle Hoban                                                                                                                                                           |
| 536 |    247.170033 |    383.560263 | Margot Michaud                                                                                                                                                        |
| 537 |    153.471559 |    274.580913 | Tasman Dixon                                                                                                                                                          |
| 538 |    296.942458 |    244.692938 | Chris huh                                                                                                                                                             |
| 539 |    425.689881 |    360.533498 | Manabu Bessho-Uehara                                                                                                                                                  |
| 540 |    862.823415 |    200.642974 | Maija Karala                                                                                                                                                          |
| 541 |    892.743459 |    199.577309 | Joseph Wolf, 1863 (vectorization by Dinah Challen)                                                                                                                    |
| 542 |    610.691238 |    632.538378 | Matt Crook                                                                                                                                                            |
| 543 |     62.669122 |    464.093866 | Tasman Dixon                                                                                                                                                          |
| 544 |     35.396318 |    710.967053 | Matt Crook                                                                                                                                                            |
| 545 |    888.405762 |    600.925866 | NA                                                                                                                                                                    |
| 546 |    863.319838 |    122.978788 | Zimices                                                                                                                                                               |
| 547 |    154.514788 |    416.888284 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 548 |    796.540395 |    613.194048 | John Gould (vectorized by T. Michael Keesey)                                                                                                                          |
| 549 |    693.552112 |    492.297476 | T. Michael Keesey                                                                                                                                                     |
| 550 |    322.356551 |    701.287330 | Sean McCann                                                                                                                                                           |
| 551 |    652.895010 |     50.552553 | Ville-Veikko Sinkkonen                                                                                                                                                |
| 552 |     46.135466 |    783.377031 | Matt Hayes                                                                                                                                                            |
| 553 |    668.094604 |    664.185442 | Walter Vladimir                                                                                                                                                       |
| 554 |    450.204206 |    360.941242 | NA                                                                                                                                                                    |
| 555 |    173.202545 |    440.923140 | Chris huh                                                                                                                                                             |
| 556 |     44.579047 |    288.022237 | Zimices                                                                                                                                                               |
| 557 |    156.618787 |    332.227754 | Zimices                                                                                                                                                               |
| 558 |    143.143508 |    112.766004 | T. Michael Keesey                                                                                                                                                     |
| 559 |   1001.098846 |    796.036489 | Henry Lydecker                                                                                                                                                        |
| 560 |    684.014743 |    124.977161 | Michele M Tobias from an image By Dcrjsr - Own work, CC BY 3.0, <https://commons.wikimedia.org/w/index.php?curid=18059686>                                            |
| 561 |    806.849044 |    614.913294 | Markus A. Grohme                                                                                                                                                      |
| 562 |    809.135111 |    436.674506 | Margot Michaud                                                                                                                                                        |
| 563 |    230.097791 |     60.332925 | Maxime Dahirel                                                                                                                                                        |
| 564 |    879.909873 |    182.734680 | Jake Warner                                                                                                                                                           |
| 565 |    440.759330 |     13.790199 | NA                                                                                                                                                                    |
| 566 |    772.036476 |    556.955343 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 567 |    530.533225 |    731.241519 | Carlos Cano-Barbacil                                                                                                                                                  |
| 568 |     25.616741 |    459.355912 | Matthew E. Clapham                                                                                                                                                    |
| 569 |     64.217842 |    207.354266 | Henry Lydecker                                                                                                                                                        |
| 570 |    978.741182 |    199.763958 | Joanna Wolfe                                                                                                                                                          |
| 571 |    246.654318 |    742.029792 | Kanchi Nanjo                                                                                                                                                          |
| 572 |    414.238136 |    126.201371 | Michelle Site                                                                                                                                                         |
| 573 |     97.704236 |    362.241844 | Melissa Broussard                                                                                                                                                     |
| 574 |    892.726686 |    138.152927 | Melissa Broussard                                                                                                                                                     |
| 575 |   1016.519533 |    638.716352 | JCGiron                                                                                                                                                               |
| 576 |    961.984628 |    766.717879 | Zimices                                                                                                                                                               |
| 577 |    973.253191 |    453.544571 | Gareth Monger                                                                                                                                                         |
| 578 |    675.418311 |    298.258032 | Harold N Eyster                                                                                                                                                       |
| 579 |     29.729883 |     92.140310 | Jagged Fang Designs                                                                                                                                                   |
| 580 |    497.624010 |     58.632885 | Michael Scroggie                                                                                                                                                      |
| 581 |    476.872502 |    563.396096 | Mo Hassan                                                                                                                                                             |
| 582 |    133.835798 |     59.770875 | Arthur Grosset (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey        |
| 583 |    361.822534 |    218.897023 | Markus A. Grohme                                                                                                                                                      |
| 584 |    313.139921 |    471.716654 | Steven Traver                                                                                                                                                         |
| 585 |    876.573134 |    610.184907 | Michelle Site                                                                                                                                                         |
| 586 |      8.661605 |    158.084697 | Margot Michaud                                                                                                                                                        |
| 587 |    205.204297 |    268.018693 | Sarah Werning                                                                                                                                                         |
| 588 |    799.845783 |    580.568030 | Matt Crook                                                                                                                                                            |
| 589 |    960.283953 |    331.461191 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 590 |     42.813663 |    190.679869 | T. Michael Keesey                                                                                                                                                     |
| 591 |    388.195595 |    755.797044 | Felix Vaux                                                                                                                                                            |
| 592 |    229.841168 |    368.370621 | Steven Traver                                                                                                                                                         |
| 593 |   1012.594210 |     17.058621 | Margot Michaud                                                                                                                                                        |
| 594 |    428.774587 |    192.278881 | Margot Michaud                                                                                                                                                        |
| 595 |    227.386796 |    180.235216 | Margot Michaud                                                                                                                                                        |
| 596 |    537.331881 |    124.030812 | Zimices                                                                                                                                                               |
| 597 |    467.429808 |    510.448425 | T. Michael Keesey                                                                                                                                                     |
| 598 |    485.947439 |    249.197069 | Craig Dylke                                                                                                                                                           |
| 599 |    223.950194 |    490.355855 | NA                                                                                                                                                                    |
| 600 |    919.883341 |    330.563069 | Martin R. Smith, after Skovsted et al 2015                                                                                                                            |
| 601 |    498.308314 |    655.998018 | Ignacio Contreras                                                                                                                                                     |
| 602 |    340.730875 |    112.807367 | Neil Kelley                                                                                                                                                           |
| 603 |    858.608442 |    299.214868 | Kai R. Caspar                                                                                                                                                         |
| 604 |    901.676741 |    378.181613 | NA                                                                                                                                                                    |
| 605 |    923.926539 |     98.450767 | Dean Schnabel                                                                                                                                                         |
| 606 |     62.803202 |    681.586547 | David Liao                                                                                                                                                            |
| 607 |   1006.145419 |    538.705034 | NA                                                                                                                                                                    |
| 608 |    422.290973 |    542.725433 | Zimices                                                                                                                                                               |
| 609 |    881.286929 |    376.375127 | Margot Michaud                                                                                                                                                        |
| 610 |    977.319649 |    699.065014 | Gareth Monger                                                                                                                                                         |
| 611 |    223.678600 |    397.142134 | Emily Willoughby                                                                                                                                                      |
| 612 |    641.620948 |    659.815577 | Zimices                                                                                                                                                               |
| 613 |    113.226773 |    375.045193 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 614 |    715.306851 |    278.561458 | Ferran Sayol                                                                                                                                                          |
| 615 |    439.784224 |    138.825796 | Mike Hanson                                                                                                                                                           |
| 616 |    975.548950 |    632.966635 | Mali’o Kodis, image by Rebecca Ritger                                                                                                                                 |
| 617 |    904.943833 |    651.871991 | Tasman Dixon                                                                                                                                                          |
| 618 |    693.014732 |    240.321162 | NA                                                                                                                                                                    |
| 619 |    694.112259 |    712.434424 | Kamil S. Jaron                                                                                                                                                        |
| 620 |    957.625732 |    304.705091 | Chris huh                                                                                                                                                             |
| 621 |    130.851968 |    668.167609 | Renata F. Martins                                                                                                                                                     |
| 622 |    108.162781 |    347.159748 | T. Michael Keesey                                                                                                                                                     |
| 623 |    236.444495 |    703.833380 | Steven Traver                                                                                                                                                         |
| 624 |    875.085970 |    168.435771 | Zimices                                                                                                                                                               |
| 625 |    708.070041 |    556.972109 | Jack Mayer Wood                                                                                                                                                       |
| 626 |     26.019450 |    437.752070 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 627 |    545.310683 |    396.524795 | Markus A. Grohme                                                                                                                                                      |
| 628 |    877.331336 |    190.428236 | Chris huh                                                                                                                                                             |
| 629 |    180.092509 |    533.078368 | Ferran Sayol                                                                                                                                                          |
| 630 |    937.552393 |     37.136090 | Steven Traver                                                                                                                                                         |
| 631 |    161.773549 |    551.153909 | Margot Michaud                                                                                                                                                        |
| 632 |    804.832089 |    366.181588 | Matt Crook                                                                                                                                                            |
| 633 |    894.260455 |    144.515765 | Steven Coombs                                                                                                                                                         |
| 634 |    130.357283 |    100.880094 | NA                                                                                                                                                                    |
| 635 |    887.364614 |    744.118166 | T. Michael Keesey (after Marek Velechovský)                                                                                                                           |
| 636 |   1014.245208 |    142.632830 | Matt Crook                                                                                                                                                            |
| 637 |    557.018515 |    362.582372 | Zimices                                                                                                                                                               |
| 638 |     37.400421 |    136.130159 | CNZdenek                                                                                                                                                              |
| 639 |    530.612443 |    302.777415 | T. Michael Keesey (from a photo by Maximilian Paradiz)                                                                                                                |
| 640 |    358.081665 |    789.749130 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 641 |    158.542026 |    109.924910 | Joanna Wolfe                                                                                                                                                          |
| 642 |   1012.266342 |    756.884842 | Dein Freund der Baum (vectorized by T. Michael Keesey)                                                                                                                |
| 643 |    328.150410 |    376.783419 | Gareth Monger                                                                                                                                                         |
| 644 |   1011.922276 |    284.172472 | Gareth Monger                                                                                                                                                         |
| 645 |    838.028135 |    738.969206 | T. Michael Keesey                                                                                                                                                     |
| 646 |    416.167297 |    475.213920 | T. Michael Keesey and Tanetahi                                                                                                                                        |
| 647 |    484.327472 |    519.857541 | Matt Crook                                                                                                                                                            |
| 648 |    240.253795 |    299.329279 | Gareth Monger                                                                                                                                                         |
| 649 |     43.006731 |    598.172731 | Thibaut Brunet                                                                                                                                                        |
| 650 |     80.049403 |    361.316356 | Margot Michaud                                                                                                                                                        |
| 651 |    299.426448 |    177.080076 | Steven Traver                                                                                                                                                         |
| 652 |     67.902302 |    246.503999 | T. Michael Keesey                                                                                                                                                     |
| 653 |    287.168697 |    696.318402 | Mathilde Cordellier                                                                                                                                                   |
| 654 |    489.385703 |    307.017147 | Steven Traver                                                                                                                                                         |
| 655 |    188.878333 |    472.095469 | Kamil S. Jaron                                                                                                                                                        |
| 656 |    531.379123 |    645.558556 | Mathilde Cordellier                                                                                                                                                   |
| 657 |     42.933470 |    557.198072 | C. Camilo Julián-Caballero                                                                                                                                            |
| 658 |    725.403188 |    662.418649 | Maija Karala                                                                                                                                                          |
| 659 |    787.301954 |    569.057461 | Jagged Fang Designs                                                                                                                                                   |
| 660 |    264.801118 |    465.300966 | Dean Schnabel                                                                                                                                                         |
| 661 |    144.211950 |    412.778361 | SauropodomorphMonarch                                                                                                                                                 |
| 662 |    316.138577 |     44.629350 | Matt Crook                                                                                                                                                            |
| 663 |     94.006999 |    194.976774 | Margot Michaud                                                                                                                                                        |
| 664 |    520.783295 |    756.256979 | Margot Michaud                                                                                                                                                        |
| 665 |    990.578768 |    653.884957 | Matt Crook                                                                                                                                                            |
| 666 |    868.360578 |    214.676732 | NA                                                                                                                                                                    |
| 667 |     27.670183 |    131.188560 | NA                                                                                                                                                                    |
| 668 |    303.259693 |    792.418277 | Collin Gross                                                                                                                                                          |
| 669 |    712.446780 |    789.890832 | Kamil S. Jaron                                                                                                                                                        |
| 670 |    226.016467 |    643.177488 | Sharon Wegner-Larsen                                                                                                                                                  |
| 671 |    954.652836 |    599.290424 | George Edward Lodge (vectorized by T. Michael Keesey)                                                                                                                 |
| 672 |    791.612680 |    527.165804 | Benjamint444                                                                                                                                                          |
| 673 |    236.234019 |    128.748606 | David Orr                                                                                                                                                             |
| 674 |    304.295615 |    235.376816 | Steven Traver                                                                                                                                                         |
| 675 |    995.016665 |    533.697827 | Kai R. Caspar                                                                                                                                                         |
| 676 |    826.405084 |    795.814789 | Christoph Schomburg                                                                                                                                                   |
| 677 |   1000.975869 |    457.741798 | Margot Michaud                                                                                                                                                        |
| 678 |    214.129039 |    795.120018 | Hanyong Pu, Yoshitsugu Kobayashi, Junchang Lü, Li Xu, Yanhua Wu, Huali Chang, Jiming Zhang, Songhai Jia & T. Michael Keesey                                           |
| 679 |    987.956525 |    545.573410 | Chris huh                                                                                                                                                             |
| 680 |    988.274765 |    215.902868 | Tommaso Cancellario                                                                                                                                                   |
| 681 |    717.350963 |    253.568886 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 682 |    998.101385 |    151.116851 | Ferran Sayol                                                                                                                                                          |
| 683 |     76.709319 |    561.378864 | Jaime Headden                                                                                                                                                         |
| 684 |    542.530572 |    281.044729 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 685 |    406.259849 |    411.195714 | Matt Crook                                                                                                                                                            |
| 686 |    224.704181 |    654.501610 | Andrew A. Farke                                                                                                                                                       |
| 687 |    690.096543 |      7.530406 | Zimices                                                                                                                                                               |
| 688 |    831.249104 |    786.325270 | Carlos Cano-Barbacil                                                                                                                                                  |
| 689 |    872.328381 |    585.405351 | Birgit Szabo                                                                                                                                                          |
| 690 |    266.365848 |    200.506715 | T. Michael Keesey                                                                                                                                                     |
| 691 |    836.475316 |    309.378223 | T. Michael Keesey                                                                                                                                                     |
| 692 |    795.489412 |     48.411809 | C. Camilo Julián-Caballero                                                                                                                                            |
| 693 |    754.646462 |     87.675074 | Michelle Site                                                                                                                                                         |
| 694 |    179.064169 |    135.073422 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                         |
| 695 |    241.365134 |    654.857717 | Gareth Monger                                                                                                                                                         |
| 696 |    199.327220 |    550.486512 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                               |
| 697 |    887.750538 |     44.598514 | David Orr                                                                                                                                                             |
| 698 |    482.834663 |    585.919675 | Margot Michaud                                                                                                                                                        |
| 699 |    110.983072 |    294.631849 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 700 |    310.361028 |    377.821427 | Armelle Ansart (photograph), Maxime Dahirel (digitisation)                                                                                                            |
| 701 |    921.916522 |    381.202626 | Steven Traver                                                                                                                                                         |
| 702 |    170.938993 |    604.209635 | Yan Wong from illustration by Charles Orbigny                                                                                                                         |
| 703 |   1008.061199 |    561.664109 | Michelle Site                                                                                                                                                         |
| 704 |    722.236979 |     74.306836 | NA                                                                                                                                                                    |
| 705 |    878.023868 |    204.740246 | Rebecca Groom                                                                                                                                                         |
| 706 |    284.972863 |    374.825785 | Tracy A. Heath                                                                                                                                                        |
| 707 |    908.569391 |    301.952515 | Zimices                                                                                                                                                               |
| 708 |     42.219246 |    333.480399 | Andrew A. Farke                                                                                                                                                       |
| 709 |    478.325152 |     76.814248 | Scott Hartman                                                                                                                                                         |
| 710 |    659.065475 |    582.071635 | Michele Tobias                                                                                                                                                        |
| 711 |    205.203451 |    582.071021 | Sarah Werning                                                                                                                                                         |
| 712 |     28.987581 |     16.658451 | Gareth Monger                                                                                                                                                         |
| 713 |    633.033155 |    348.178758 | Margot Michaud                                                                                                                                                        |
| 714 |    779.829369 |    144.201323 | Josep Marti Solans                                                                                                                                                    |
| 715 |    618.230811 |    560.444605 | Melissa Broussard                                                                                                                                                     |
| 716 |    479.600725 |    339.686433 | Cesar Julian                                                                                                                                                          |
| 717 |    543.189445 |    203.538363 | Milton Tan                                                                                                                                                            |
| 718 |     35.114929 |    393.883043 | Crystal Maier                                                                                                                                                         |
| 719 |    150.530184 |    686.603512 | Zimices                                                                                                                                                               |
| 720 |    378.646601 |    722.423256 | Chris huh                                                                                                                                                             |
| 721 |     90.500257 |      3.532917 | B. Duygu Özpolat                                                                                                                                                      |
| 722 |    811.272953 |    181.008729 | Vanessa Guerra                                                                                                                                                        |
| 723 |   1007.482873 |    188.406026 | Alexandre Vong                                                                                                                                                        |
| 724 |    325.569294 |    552.556991 | New York Zoological Society                                                                                                                                           |
| 725 |    697.646492 |    741.426873 | Pranav Iyer (grey ideas)                                                                                                                                              |
| 726 |    772.427961 |     41.857332 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 727 |    517.580645 |    303.437958 | Margot Michaud                                                                                                                                                        |
| 728 |    551.587101 |    706.138933 | Michael Scroggie, from original photograph by John Bettaso, USFWS (original photograph in public domain).                                                             |
| 729 |     31.179975 |    153.041599 | Margot Michaud                                                                                                                                                        |
| 730 |    228.356853 |    115.213839 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 731 |    897.651205 |    619.950740 | T. Michael Keesey                                                                                                                                                     |
| 732 |    902.542900 |    192.844895 | Gareth Monger                                                                                                                                                         |
| 733 |    284.956861 |    785.658955 | Cathy                                                                                                                                                                 |
| 734 |    994.603053 |    309.361045 | John Gould (vectorized by T. Michael Keesey)                                                                                                                          |
| 735 |    919.178225 |    660.682732 | Alex Slavenko                                                                                                                                                         |
| 736 |    887.679700 |      2.698604 | Zimices                                                                                                                                                               |
| 737 |    983.593687 |     18.423445 | Steven Traver                                                                                                                                                         |
| 738 |    933.093257 |    142.947953 | Christoph Schomburg                                                                                                                                                   |
| 739 |    351.929247 |    655.260640 | SecretJellyMan                                                                                                                                                        |
| 740 |    508.568484 |    589.865449 | Chris huh                                                                                                                                                             |
| 741 |     76.892211 |     74.957579 | Zimices                                                                                                                                                               |
| 742 |    535.689851 |    422.804479 | Sam Droege (photo) and T. Michael Keesey (vectorization)                                                                                                              |
| 743 |    154.494267 |    596.553421 | Matt Crook                                                                                                                                                            |
| 744 |    250.698262 |    250.088731 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 745 |    675.340273 |      8.778212 | Markus A. Grohme                                                                                                                                                      |
| 746 |     81.578005 |    503.387222 | Bennet McComish, photo by Hans Hillewaert                                                                                                                             |
| 747 |    668.212296 |    210.611574 | Steven Traver                                                                                                                                                         |
| 748 |    515.095363 |    241.735455 | Margot Michaud                                                                                                                                                        |
| 749 |    637.184803 |    557.718411 | Michelle Site                                                                                                                                                         |
| 750 |    867.007311 |    233.694812 | Gareth Monger                                                                                                                                                         |
| 751 |    484.956509 |    508.846096 | Sarah Werning                                                                                                                                                         |
| 752 |    794.494101 |    137.989517 | Crystal Maier                                                                                                                                                         |
| 753 |    688.832279 |     41.707869 | Matt Crook                                                                                                                                                            |
| 754 |    423.896673 |    494.364863 | NA                                                                                                                                                                    |
| 755 |    937.234105 |     89.204422 | Jagged Fang Designs                                                                                                                                                   |
| 756 |    908.293294 |    159.893366 | Gareth Monger                                                                                                                                                         |
| 757 |    736.719464 |    795.065851 | Cesar Julian                                                                                                                                                          |
| 758 |    209.631155 |    786.615433 | Steven Traver                                                                                                                                                         |
| 759 |    652.788297 |    340.316279 | Gareth Monger                                                                                                                                                         |
| 760 |    583.075046 |    708.070788 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 761 |    994.983299 |    228.506457 | Ville Koistinen and T. Michael Keesey                                                                                                                                 |
| 762 |    644.743073 |    362.142688 | Mattia Menchetti / Yan Wong                                                                                                                                           |
| 763 |    874.961797 |    193.973026 | Siobhon Egan                                                                                                                                                          |
| 764 |    767.475869 |     84.200473 | Plukenet                                                                                                                                                              |
| 765 |    207.810225 |    500.062631 | Zimices                                                                                                                                                               |
| 766 |    909.390346 |     38.840292 | Yan Wong from drawing by Joseph Smit                                                                                                                                  |
| 767 |    315.196944 |    393.645214 | Margot Michaud                                                                                                                                                        |
| 768 |    414.344233 |    787.905173 | Markus A. Grohme                                                                                                                                                      |
| 769 |     47.381633 |    470.016009 | David Orr                                                                                                                                                             |
| 770 |    247.506256 |    754.886900 | Xavier Giroux-Bougard                                                                                                                                                 |
| 771 |    614.666623 |    503.852171 | Chris huh                                                                                                                                                             |
| 772 |    682.611813 |    744.035702 | Matt Crook                                                                                                                                                            |
| 773 |    207.525297 |     13.282255 | Michele M Tobias from an image By Dcrjsr - Own work, CC BY 3.0, <https://commons.wikimedia.org/w/index.php?curid=18059686>                                            |
| 774 |    519.570607 |    647.702621 | Matt Crook                                                                                                                                                            |
| 775 |    527.849459 |    631.347785 | Martin R. Smith, from photo by Jürgen Schoner                                                                                                                         |
| 776 |    658.831755 |    200.999343 | Zimices                                                                                                                                                               |
| 777 |    688.780800 |    389.671952 | Ferran Sayol                                                                                                                                                          |
| 778 |    223.460176 |    627.276639 | Ferran Sayol                                                                                                                                                          |
| 779 |    558.349322 |    734.779208 | Jagged Fang Designs                                                                                                                                                   |
| 780 |    574.493986 |    188.136234 | Emily Willoughby                                                                                                                                                      |
| 781 |    716.806048 |    565.449970 | Taro Maeda                                                                                                                                                            |
| 782 |    614.666417 |    679.265467 | Markus A. Grohme                                                                                                                                                      |
| 783 |    329.142761 |    641.157092 | Kent Elson Sorgon                                                                                                                                                     |
| 784 |    996.164010 |    717.453437 | (after Spotila 2004)                                                                                                                                                  |
| 785 |    863.196629 |    617.000466 | Tracy A. Heath                                                                                                                                                        |
| 786 |    831.477278 |    720.525054 | Noah Schlottman, photo by Carol Cummings                                                                                                                              |
| 787 |    286.358154 |    111.904714 | Matt Dempsey                                                                                                                                                          |
| 788 |    398.816956 |    394.178656 | NA                                                                                                                                                                    |
| 789 |    805.384977 |    790.245129 | Margot Michaud                                                                                                                                                        |
| 790 |    954.704469 |    502.442655 | Margot Michaud                                                                                                                                                        |
| 791 |    565.769398 |    209.333132 | Gareth Monger                                                                                                                                                         |
| 792 |     51.571657 |    347.821642 | Jiekun He                                                                                                                                                             |
| 793 |    464.415588 |     56.895486 | Zimices                                                                                                                                                               |
| 794 |    251.016005 |    375.214110 | Becky Barnes                                                                                                                                                          |
| 795 |     68.950180 |    338.830569 | Scott Hartman                                                                                                                                                         |
| 796 |    617.342576 |    542.332935 | Matt Crook                                                                                                                                                            |
| 797 |    164.480687 |    624.256088 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 798 |    640.789355 |    531.456804 | Tyler Greenfield                                                                                                                                                      |
| 799 |    263.394925 |    586.232518 | Ferran Sayol                                                                                                                                                          |
| 800 |    857.279612 |    390.686785 | Scott Hartman                                                                                                                                                         |
| 801 |    148.659401 |     87.090521 | T. Michael Keesey (vectorization) and Nadiatalent (photography)                                                                                                       |
| 802 |    696.279706 |    116.883010 | Chris huh                                                                                                                                                             |
| 803 |    166.948504 |    453.172301 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                           |
| 804 |     43.353180 |    478.528018 | Jagged Fang Designs                                                                                                                                                   |
| 805 |    597.749668 |    523.278750 | Chris huh                                                                                                                                                             |
| 806 |    669.911258 |    204.418195 | Jagged Fang Designs                                                                                                                                                   |
| 807 |    881.979214 |    308.144502 | T. Michael Keesey                                                                                                                                                     |
| 808 |    155.571721 |     62.765794 | Jagged Fang Designs                                                                                                                                                   |
| 809 |    762.998117 |    426.946866 | Chris huh                                                                                                                                                             |
| 810 |    206.137522 |     55.532728 | Manabu Bessho-Uehara                                                                                                                                                  |
| 811 |    812.659098 |     42.756488 | Gareth Monger                                                                                                                                                         |
| 812 |    217.989161 |    521.991610 | Caleb M. Brown                                                                                                                                                        |
| 813 |    797.716139 |    456.234606 | Matt Crook                                                                                                                                                            |
| 814 |    766.160886 |    367.865523 | Felix Vaux                                                                                                                                                            |
| 815 |    874.453373 |    497.097130 | Zimices                                                                                                                                                               |
| 816 |     83.101942 |    488.662183 | Michael Day                                                                                                                                                           |
| 817 |    415.406252 |    325.532603 | NA                                                                                                                                                                    |
| 818 |     52.768338 |    643.453676 | M. Garfield & K. Anderson (modified by T. Michael Keesey)                                                                                                             |
| 819 |    523.564750 |     57.111587 | Steven Traver                                                                                                                                                         |
| 820 |    923.924482 |     26.872481 | Tasman Dixon                                                                                                                                                          |
| 821 |    617.672608 |    648.811166 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 822 |    714.303940 |     42.744207 | Julia B McHugh                                                                                                                                                        |
| 823 |     14.253514 |    735.916729 | Kailah Thorn & Mark Hutchinson                                                                                                                                        |
| 824 |    205.453535 |    139.633967 | Ferran Sayol                                                                                                                                                          |
| 825 |    928.699264 |    449.394880 | Ferran Sayol                                                                                                                                                          |
| 826 |    285.368166 |    456.358817 | Ignacio Contreras                                                                                                                                                     |
| 827 |    911.422300 |     17.297759 | Stacy Spensley (Modified)                                                                                                                                             |
| 828 |    212.624100 |    440.545135 | Collin Gross                                                                                                                                                          |
| 829 |    901.782181 |    357.345791 | Ieuan Jones                                                                                                                                                           |
| 830 |     60.487364 |     10.442563 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                                 |
| 831 |    424.882178 |    409.593033 | Cesar Julian                                                                                                                                                          |
| 832 |      8.796686 |    550.531141 | Joanna Wolfe                                                                                                                                                          |
| 833 |    250.626268 |    426.584597 | Ferran Sayol                                                                                                                                                          |
| 834 |    886.573286 |    728.445943 | Smokeybjb                                                                                                                                                             |
| 835 |    757.165677 |    667.379942 | Zimices                                                                                                                                                               |
| 836 |    802.666041 |    708.195070 | Steven Traver                                                                                                                                                         |
| 837 |    503.033751 |    297.529585 | Óscar San-Isidro (vectorized by T. Michael Keesey)                                                                                                                    |
| 838 |    585.849752 |    668.121198 | L. Shyamal                                                                                                                                                            |
| 839 |    889.143118 |     22.276863 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 840 |    287.106696 |    514.188298 | Michael Scroggie                                                                                                                                                      |
| 841 |    334.460553 |    211.439510 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                                 |
| 842 |    656.120972 |    559.272484 | Scott Hartman (modified by T. Michael Keesey)                                                                                                                         |
| 843 |    685.710136 |    784.605751 | T. Michael Keesey                                                                                                                                                     |
| 844 |    435.180740 |    477.984708 | Kamil S. Jaron                                                                                                                                                        |
| 845 |     72.720735 |    194.100725 | Martin R. Smith                                                                                                                                                       |
| 846 |    123.132877 |    113.348528 | Matt Crook                                                                                                                                                            |
| 847 |    887.999682 |    644.043655 | NA                                                                                                                                                                    |
| 848 |     87.821867 |    697.162169 | Rebecca Groom                                                                                                                                                         |
| 849 |    843.518794 |    388.195820 | Andrew Farke and Joseph Sertich                                                                                                                                       |
| 850 |    633.492864 |    515.218037 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                               |
| 851 |    363.955910 |    314.275598 | Robert Gay                                                                                                                                                            |
| 852 |    920.640977 |    741.351419 | Zimices                                                                                                                                                               |
| 853 |    402.675998 |    485.351556 | Zimices                                                                                                                                                               |
| 854 |    592.284046 |    303.584374 | Chris huh                                                                                                                                                             |
| 855 |    631.233440 |    305.649326 | Zimices                                                                                                                                                               |
| 856 |    607.407915 |    306.857892 | Ignacio Contreras                                                                                                                                                     |
| 857 |   1014.196667 |    719.212070 | terngirl                                                                                                                                                              |
| 858 |    509.953423 |    289.558585 | NA                                                                                                                                                                    |
| 859 |    374.002977 |    382.884926 | Zimices                                                                                                                                                               |
| 860 |    661.627251 |    775.300315 | T. Michael Keesey                                                                                                                                                     |
| 861 |    450.351379 |    521.931264 | Sarah Werning                                                                                                                                                         |
| 862 |    861.439893 |    432.807404 | Trond R. Oskars                                                                                                                                                       |
| 863 |    793.755467 |      8.897876 | NA                                                                                                                                                                    |
| 864 |    195.798942 |     13.660949 | Kamil S. Jaron                                                                                                                                                        |
| 865 |    710.535877 |    713.664173 | Alex Slavenko                                                                                                                                                         |
| 866 |    678.658682 |    464.158525 | NA                                                                                                                                                                    |
| 867 |    577.782905 |    692.062948 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 868 |     56.154627 |    631.798150 | Carlos Cano-Barbacil                                                                                                                                                  |
| 869 |     39.810064 |    533.413405 | T. Michael Keesey                                                                                                                                                     |
| 870 |    251.241044 |    363.124730 | T. Michael Keesey                                                                                                                                                     |
| 871 |    149.420288 |    777.765918 | Auckland Museum and T. Michael Keesey                                                                                                                                 |
| 872 |    751.618453 |    364.747200 | Margot Michaud                                                                                                                                                        |
| 873 |     38.526379 |    358.259644 | Matt Crook                                                                                                                                                            |
| 874 |    670.412194 |    550.287968 | Chuanixn Yu                                                                                                                                                           |
| 875 |    780.500098 |    684.946705 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 876 |    169.144943 |    400.885528 | Maxime Dahirel                                                                                                                                                        |
| 877 |    255.481329 |    171.250175 | NA                                                                                                                                                                    |
| 878 |    526.721158 |    782.576576 | Mason McNair                                                                                                                                                          |
| 879 |    534.718366 |     70.297115 | Margot Michaud                                                                                                                                                        |
| 880 |    242.294918 |    723.002152 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                          |
| 881 |     53.924504 |    697.170848 | Chris Jennings (Risiatto)                                                                                                                                             |
| 882 |    276.638638 |    243.472174 | Collin Gross                                                                                                                                                          |
| 883 |    994.228632 |      8.318845 | NA                                                                                                                                                                    |
| 884 |    798.303167 |    276.194455 | Scott Hartman                                                                                                                                                         |
| 885 |    870.030576 |    652.809244 | Chris huh                                                                                                                                                             |
| 886 |    461.145638 |    300.583416 | Alexandre Vong                                                                                                                                                        |
| 887 |    543.076765 |    740.764719 | Margot Michaud                                                                                                                                                        |
| 888 |    978.135024 |    536.946917 | Ghedo and T. Michael Keesey                                                                                                                                           |
| 889 |    179.660433 |    408.253990 | T. Tischler                                                                                                                                                           |
| 890 |    556.190912 |     67.671326 | NA                                                                                                                                                                    |
| 891 |    177.683323 |    257.388018 | Gareth Monger                                                                                                                                                         |
| 892 |    259.711516 |    777.999465 | Joseph Wolf, 1863 (vectorization by Dinah Challen)                                                                                                                    |
| 893 |    189.121878 |    449.936954 | Zimices                                                                                                                                                               |
| 894 |    682.836008 |    722.088346 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                              |
| 895 |    732.935860 |    154.764755 | NA                                                                                                                                                                    |
| 896 |    428.121793 |    200.552758 | Ferran Sayol                                                                                                                                                          |
| 897 |    424.890035 |    257.580483 | NA                                                                                                                                                                    |
| 898 |    816.800159 |    372.215357 | Steven Coombs                                                                                                                                                         |
| 899 |    765.443807 |    520.882397 | Dean Schnabel                                                                                                                                                         |
| 900 |    983.565158 |    497.314251 | Chris huh                                                                                                                                                             |
| 901 |    447.026194 |    275.959769 | Matt Crook                                                                                                                                                            |
| 902 |    916.353704 |    512.103242 | Agnello Picorelli                                                                                                                                                     |
| 903 |    592.759978 |    551.866405 | Tyler McCraney                                                                                                                                                        |
| 904 |    456.332770 |    640.078342 | Gareth Monger                                                                                                                                                         |
| 905 |    397.716826 |      7.646075 | Yan Wong                                                                                                                                                              |

    #> Your tweet has been posted!
