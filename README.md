
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

Matt Martyniuk, Scott Hartman, Zimices, T. Michael Keesey (after
Masteraah), Ingo Braasch, Matt Crook, Anthony Caravaggi, Carlos
Cano-Barbacil, FunkMonk, Ferran Sayol, Nobu Tamura (vectorized by T.
Michael Keesey), Jaime Headden, Dean Schnabel, L. Shyamal, Martin R.
Smith, Margot Michaud, Christopher Laumer (vectorized by T. Michael
Keesey), Gareth Monger, Gabriela Palomo-Munoz, Derek Bakken (photograph)
and T. Michael Keesey (vectorization), Caleb M. Gordon, Sarah Werning,
Roberto Díaz Sibaja, Becky Barnes, Brockhaus and Efron, Melissa
Broussard, Mark Witton, Jagged Fang Designs, Lauren Sumner-Rooney,
Fernando Campos De Domenico, Mariana Ruiz Villarreal, Maxime Dahirel,
Ricardo Araújo, Tyler Greenfield, Yan Wong, Beth Reinke, Joanna Wolfe,
Chris huh, Mykle Hoban, Henry Fairfield Osborn, vectorized by Zimices,
Tracy A. Heath, T. Michael Keesey, Michelle Site, Steven Traver,
Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes
(www.carnivorosaustrales.org), Kailah Thorn & Mark Hutchinson, Dmitry
Bogdanov (vectorized by T. Michael Keesey), Noah Schlottman, photo by
Hans De Blauwe, Chloé Schmidt, LeonardoG (photography) and T. Michael
Keesey (vectorization), Matt Hayes, Didier Descouens (vectorized by T.
Michael Keesey), Sherman Foote Denton (illustration, 1897) and Timothy
J. Bartley (silhouette), Rebecca Groom, Ghedoghedo (vectorized by T.
Michael Keesey), Robbie N. Cada (modified by T. Michael Keesey),
Francesco “Architetto” Rollandin, Hanyong Pu, Yoshitsugu Kobayashi,
Junchang Lü, Li Xu, Yanhua Wu, Huali Chang, Jiming Zhang, Songhai Jia &
T. Michael Keesey, Liftarn, G. M. Woodward, Dmitry Bogdanov, Mali’o
Kodis, photograph from
<http://commons.wikimedia.org/wiki/File:Trichoplax.jpg>, Xavier
Giroux-Bougard, Alexandre Vong, Jimmy Bernot, Jonathan Wells, Tim
Bertelink (modified by T. Michael Keesey), Alex Slavenko, Jake Warner,
Caleb M. Brown, Sharon Wegner-Larsen, Mathilde Cordellier, Hans
Hillewaert (vectorized by T. Michael Keesey), Sibi (vectorized by T.
Michael Keesey), Kai R. Caspar, Noah Schlottman, Lukasiniho, xgirouxb,
Scott Reid, Pete Buchholz, Jessica Anne Miller, kreidefossilien.de,
Mali’o Kodis, photograph property of National Museums of Northern
Ireland, Antonov (vectorized by T. Michael Keesey), S.Martini, Inessa
Voet, Douglas Brown (modified by T. Michael Keesey), Stemonitis
(photography) and T. Michael Keesey (vectorization), Oren Peles /
vectorized by Yan Wong, Tasman Dixon, Meyer-Wachsmuth I, Curini Galletti
M, Jondelius U (<doi:10.1371/journal.pone.0107688>). Vectorization by Y.
Wong, Henry Lydecker, Trond R. Oskars, Nobu Tamura, Kimberly Haddrell,
Taro Maeda, Shyamal, Armin Reindl, Kent Elson Sorgon, Mattia Menchetti,
Richard Lampitt, Jeremy Young / NHM (vectorization by Yan Wong), Emily
Willoughby, C. Abraczinskas, Alexander Schmidt-Lebuhn, Mareike C.
Janiak, Dmitry Bogdanov (modified by T. Michael Keesey), Michael
Scroggie, Cesar Julian, Sean McCann, T. Michael Keesey (vectorization);
Thorsten Assmann, Jörn Buse, Claudia Drees, Ariel-Leib-Leonid Friedman,
Tal Levanony, Andrea Matern, Anika Timm, and David W. Wrase
(photography), Jiekun He, David Orr, Alan Manson (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Maija Karala,
Emily Jane McTavish, from
<http://en.wikipedia.org/wiki/File:Coccolithus_pelagicus.jpg>, Zsoldos
Márton (vectorized by T. Michael Keesey), Original drawing by Dmitry
Bogdanov, vectorized by Roberto Díaz Sibaja, Birgit Lang, Arthur Grosset
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Jack Mayer Wood, Tauana J. Cunha, Mali’o Kodis, photograph by
Jim Vargo, Qiang Ou, Lankester Edwin Ray (vectorized by T. Michael
Keesey), Timothy Knepp of the U.S. Fish and Wildlife Service
(illustration) and Timothy J. Bartley (silhouette), Jose Carlos
Arenas-Monroy, Frank Denota, James R. Spotila and Ray Chatterji, Collin
Gross, Noah Schlottman, photo from Casey Dunn, T. Michael Keesey (after
Kukalová), T. Michael Keesey (photo by J. M. Garg), Evan Swigart
(photography) and T. Michael Keesey (vectorization), NASA, Kamil S.
Jaron, CNZdenek, Michael P. Taylor, Joseph Smit (modified by T. Michael
Keesey), C. Camilo Julián-Caballero, Archaeodontosaurus (vectorized by
T. Michael Keesey), Mason McNair, Gopal Murali, Christine Axon, Katie S.
Collins, Matt Dempsey, Andrew A. Farke, Jan A. Venter, Herbert H. T.
Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey),
T. Michael Keesey, from a photograph by Thea Boodhoo, Mali’o Kodis,
image from Brockhaus and Efron Encyclopedic Dictionary, Matt Celeskey,
Julio Garza, Christoph Schomburg, annaleeblysse, Mathew Wedel, Leon P.
A. M. Claessens, Patrick M. O’Connor, David M. Unwin, Scott Hartman,
modified by T. Michael Keesey, Josep Marti Solans, Nobu Tamura,
vectorized by Zimices, Matt Martyniuk (vectorized by T. Michael Keesey),
T. Michael Keesey (vectorization) and Nadiatalent (photography), Mali’o
Kodis, photograph by Cordell Expeditions at Cal Academy, Ekaterina
Kopeykina (vectorized by T. Michael Keesey), Ellen Edmonson and Hugh
Chrisp (vectorized by T. Michael Keesey), Smokeybjb (vectorized by T.
Michael Keesey), SecretJellyMan, Fir0002/Flagstaffotos (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Chris A.
Hamilton, Manabu Bessho-Uehara, Jonathan Lawley, Karl Ragnar Gjertsen
(vectorized by T. Michael Keesey), Bob Goldstein, Vectorization:Jake
Warner, Falconaumanni and T. Michael Keesey, Samanta Orellana, Benchill,
Mark Miller, Darren Naish (vectorize by T. Michael Keesey), Iain Reid,
Daniel Jaron, Andrew A. Farke, modified from original by H. Milne
Edwards, Apokryltaros (vectorized by T. Michael Keesey), Noah
Schlottman, photo by Museum of Geology, University of Tartu, H. F. O.
March (modified by T. Michael Keesey, Michael P. Taylor & Matthew J.
Wedel), Mark Hannaford (photo), John E. McCormack, Michael G. Harvey,
Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T.
Brumfield & T. Michael Keesey, Tyler McCraney, Aadx, Unknown (photo),
John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G.
Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Andrew
Farke and Joseph Sertich, H. F. O. March (vectorized by T. Michael
Keesey), Richard Ruggiero, vectorized by Zimices, Francis de Laporte de
Castelnau (vectorized by T. Michael Keesey), T. Michael Keesey (from a
photo by Maximilian Paradiz), Emily Jane McTavish, Michael Scroggie,
from original photograph by Gary M. Stolz, USFWS (original photograph in
public domain)., Christopher Chávez, Mercedes Yrayzoz (vectorized by T.
Michael Keesey), Smokeybjb, vectorized by Zimices, Fritz Geller-Grimm
(vectorized by T. Michael Keesey), Jakovche, Michael Wolf (photo), Hans
Hillewaert (editing), T. Michael Keesey (vectorization), Patrick
Strutzenberger, Matt Wilkins, Jon Hill (Photo by DickDaniels:
<http://en.wikipedia.org/wiki/File:Green_Woodhoopoe_RWD7.jpg>), Robert
Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.,
Mali’o Kodis, photograph by John Slapcinsky, Jaime A. Headden
(vectorized by T. Michael Keesey), Crystal Maier, T. Michael Keesey
(after James & al.), Robert Bruce Horsfall, vectorized by Zimices, Juan
Carlos Jerí, Dennis C. Murphy, after
<https://commons.wikimedia.org/wiki/File:Queensland_State_Archives_2981_Cane_toads_at_the_Meringa_Sugar_Experiment_Station_North_Queensland_c_1935.png>,
Tony Ayling (vectorized by T. Michael Keesey), Gregor Bucher, Max
Farnworth, Metalhead64 (vectorized by T. Michael Keesey), Steven Coombs,
Tarique Sani (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, NOAA Great Lakes Environmental Research Laboratory
(illustration) and Timothy J. Bartley (silhouette), Caio Bernardes,
vectorized by Zimices, Allison Pease, Gabriel Lio, vectorized by
Zimices, Harold N Eyster, Martin Kevil, Noah Schlottman, photo by
Antonio Guillén, JJ Harrison (vectorized by T. Michael Keesey), Dave
Souza (vectorized by T. Michael Keesey), Young and Zhao (1972:figure 4),
modified by Michael P. Taylor, Ray Simpson (vectorized by T. Michael
Keesey), Nobu Tamura (vectorized by A. Verrière), Sergio A. Muñoz-Gómez,
Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette),
(after Spotila 2004), Chris Jennings (vectorized by A. Verrière),
Terpsichores, Michael B. H. (vectorized by T. Michael Keesey), M
Kolmann, Wynston Cooper (photo) and Albertonykus (silhouette),
Smokeybjb, Neil Kelley, Lindberg (vectorized by T. Michael Keesey), Tony
Ayling, T. Michael Keesey (after Mivart), Prin Pattawaro (photo), John
E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G.
Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey,
Pearson Scott Foresman (vectorized by T. Michael Keesey), Lisa Byrne,
Sam Droege (photo) and T. Michael Keesey (vectorization), Lukas
Panzarin, Conty (vectorized by T. Michael Keesey), Dinah Challen, Bryan
Carstens, Josefine Bohr Brask, Walter Vladimir, Ville-Veikko Sinkkonen,
Greg Schechter (original photo), Renato Santos (vector silhouette),
Ernst Haeckel (vectorized by T. Michael Keesey), Rachel Shoop, Abraão
Leite, Frank Förster (based on a picture by Hans Hillewaert), V. Deepak,
Ghedoghedo, Ludwik Gasiorowski, Javiera Constanzo, Noah Schlottman,
photo by Reinhard Jahn, wsnaccad, Prathyush Thomas, Pedro de Siracusa,
Anilocra (vectorization by Yan Wong), FunkMonk (Michael B. H.), Cathy,
John Curtis (vectorized by T. Michael Keesey)

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                               |
| --: | ------------: | ------------: | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    267.767085 |    288.537797 | Matt Martyniuk                                                                                                                                                                       |
|   2 |    296.643815 |    654.529226 | Scott Hartman                                                                                                                                                                        |
|   3 |    671.607612 |    371.704053 | Zimices                                                                                                                                                                              |
|   4 |    662.868729 |    107.839004 | T. Michael Keesey (after Masteraah)                                                                                                                                                  |
|   5 |    633.868310 |    672.290768 | NA                                                                                                                                                                                   |
|   6 |    234.687517 |    771.023812 | Ingo Braasch                                                                                                                                                                         |
|   7 |    487.576898 |    369.618425 | Matt Crook                                                                                                                                                                           |
|   8 |    680.414779 |    558.601742 | Anthony Caravaggi                                                                                                                                                                    |
|   9 |    673.709686 |    283.805163 | Carlos Cano-Barbacil                                                                                                                                                                 |
|  10 |    852.907843 |    484.966348 | Ingo Braasch                                                                                                                                                                         |
|  11 |    474.797913 |     34.336790 | FunkMonk                                                                                                                                                                             |
|  12 |    397.564298 |    567.670301 | Ferran Sayol                                                                                                                                                                         |
|  13 |    920.881149 |    534.520592 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
|  14 |    538.414802 |    131.747871 | Matt Crook                                                                                                                                                                           |
|  15 |     72.129694 |    275.825436 | Jaime Headden                                                                                                                                                                        |
|  16 |     89.775168 |    214.236527 | Dean Schnabel                                                                                                                                                                        |
|  17 |    191.263155 |    560.238604 | Ferran Sayol                                                                                                                                                                         |
|  18 |    372.310650 |    118.133728 | L. Shyamal                                                                                                                                                                           |
|  19 |    381.199252 |    696.137414 | Martin R. Smith                                                                                                                                                                      |
|  20 |    846.900057 |    245.543719 | Matt Crook                                                                                                                                                                           |
|  21 |    392.451750 |    217.390942 | Margot Michaud                                                                                                                                                                       |
|  22 |    824.106559 |     43.844310 | NA                                                                                                                                                                                   |
|  23 |    846.491928 |    415.832415 | Christopher Laumer (vectorized by T. Michael Keesey)                                                                                                                                 |
|  24 |    944.190335 |    712.349288 | Zimices                                                                                                                                                                              |
|  25 |    132.979152 |    725.357519 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
|  26 |    980.989630 |     96.745531 | Gareth Monger                                                                                                                                                                        |
|  27 |    278.967246 |     90.508584 | Gabriela Palomo-Munoz                                                                                                                                                                |
|  28 |    981.451704 |    247.318883 | Derek Bakken (photograph) and T. Michael Keesey (vectorization)                                                                                                                      |
|  29 |    401.618964 |     77.197488 | NA                                                                                                                                                                                   |
|  30 |    122.188397 |    444.718783 | Caleb M. Gordon                                                                                                                                                                      |
|  31 |    805.136118 |    612.389820 | Sarah Werning                                                                                                                                                                        |
|  32 |    141.215686 |    359.903504 | Roberto Díaz Sibaja                                                                                                                                                                  |
|  33 |    893.616809 |    118.941274 | Becky Barnes                                                                                                                                                                         |
|  34 |    542.653569 |    438.568622 | Brockhaus and Efron                                                                                                                                                                  |
|  35 |    714.174540 |    187.760454 | Melissa Broussard                                                                                                                                                                    |
|  36 |    831.949296 |    741.193043 | Mark Witton                                                                                                                                                                          |
|  37 |    598.572534 |    217.654001 | Ferran Sayol                                                                                                                                                                         |
|  38 |     96.702861 |    651.350748 | Jagged Fang Designs                                                                                                                                                                  |
|  39 |    949.343473 |    371.705677 | Lauren Sumner-Rooney                                                                                                                                                                 |
|  40 |     69.635706 |     20.760890 | NA                                                                                                                                                                                   |
|  41 |    501.130897 |    301.035307 | Fernando Campos De Domenico                                                                                                                                                          |
|  42 |    248.049128 |    703.938612 | Scott Hartman                                                                                                                                                                        |
|  43 |    950.912935 |    610.693517 | Mariana Ruiz Villarreal                                                                                                                                                              |
|  44 |    477.862807 |    561.417583 | Maxime Dahirel                                                                                                                                                                       |
|  45 |     87.750529 |    580.846179 | Gabriela Palomo-Munoz                                                                                                                                                                |
|  46 |     38.373579 |    439.885778 | Ferran Sayol                                                                                                                                                                         |
|  47 |     88.118660 |    169.264948 | Ricardo Araújo                                                                                                                                                                       |
|  48 |    627.335315 |     51.223333 | Scott Hartman                                                                                                                                                                        |
|  49 |    685.516993 |    439.390504 | Gareth Monger                                                                                                                                                                        |
|  50 |    408.793858 |    706.562133 | Tyler Greenfield                                                                                                                                                                     |
|  51 |    597.836070 |    540.128994 | Yan Wong                                                                                                                                                                             |
|  52 |     68.256126 |    756.052246 | Scott Hartman                                                                                                                                                                        |
|  53 |    673.986207 |    779.744697 | Jagged Fang Designs                                                                                                                                                                  |
|  54 |   1000.284728 |    476.965459 | Beth Reinke                                                                                                                                                                          |
|  55 |    257.494204 |    504.971409 | Scott Hartman                                                                                                                                                                        |
|  56 |    108.204098 |     74.662560 | Sarah Werning                                                                                                                                                                        |
|  57 |    506.402587 |    218.676930 | Joanna Wolfe                                                                                                                                                                         |
|  58 |    312.588724 |     10.740633 | Gabriela Palomo-Munoz                                                                                                                                                                |
|  59 |    277.070920 |    199.033152 | Chris huh                                                                                                                                                                            |
|  60 |    815.714081 |    120.389438 | Margot Michaud                                                                                                                                                                       |
|  61 |    330.800569 |    528.303353 | Mykle Hoban                                                                                                                                                                          |
|  62 |    341.161144 |    493.363476 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                                                        |
|  63 |    608.375625 |    382.342942 | Matt Crook                                                                                                                                                                           |
|  64 |    874.473814 |    766.538249 | Tracy A. Heath                                                                                                                                                                       |
|  65 |    935.680364 |      6.195557 | Zimices                                                                                                                                                                              |
|  66 |    133.712004 |    309.405948 | T. Michael Keesey                                                                                                                                                                    |
|  67 |     68.691264 |    365.453998 | Michelle Site                                                                                                                                                                        |
|  68 |    448.361100 |    254.712118 | Steven Traver                                                                                                                                                                        |
|  69 |    347.384792 |    694.002989 | Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org)                                                                                         |
|  70 |     84.567847 |    543.250968 | Kailah Thorn & Mark Hutchinson                                                                                                                                                       |
|  71 |    980.954766 |    321.005572 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
|  72 |    877.738510 |    658.823769 | Gareth Monger                                                                                                                                                                        |
|  73 |    178.134972 |     17.667274 | Noah Schlottman, photo by Hans De Blauwe                                                                                                                                             |
|  74 |    875.947842 |    341.088378 | Chloé Schmidt                                                                                                                                                                        |
|  75 |    415.834836 |    293.325821 | LeonardoG (photography) and T. Michael Keesey (vectorization)                                                                                                                        |
|  76 |    949.540798 |     53.089241 | Steven Traver                                                                                                                                                                        |
|  77 |    588.709851 |    547.178146 | Matt Hayes                                                                                                                                                                           |
|  78 |    210.934247 |     28.376216 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                                   |
|  79 |    228.458455 |    659.689691 | Margot Michaud                                                                                                                                                                       |
|  80 |    742.623704 |     84.856332 | Sherman Foote Denton (illustration, 1897) and Timothy J. Bartley (silhouette)                                                                                                        |
|  81 |    780.811057 |    760.692021 | Rebecca Groom                                                                                                                                                                        |
|  82 |    425.153971 |    656.553613 | Zimices                                                                                                                                                                              |
|  83 |    503.537926 |    261.285448 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                                         |
|  84 |    758.708476 |     29.848247 | T. Michael Keesey                                                                                                                                                                    |
|  85 |    698.187175 |    628.994848 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                                                       |
|  86 |    850.061411 |    171.719740 | Francesco “Architetto” Rollandin                                                                                                                                                     |
|  87 |    794.731618 |    312.868195 | Hanyong Pu, Yoshitsugu Kobayashi, Junchang Lü, Li Xu, Yanhua Wu, Huali Chang, Jiming Zhang, Songhai Jia & T. Michael Keesey                                                          |
|  88 |    478.024732 |     90.164821 | Liftarn                                                                                                                                                                              |
|  89 |    755.384548 |    525.088556 | G. M. Woodward                                                                                                                                                                       |
|  90 |     16.912374 |    703.409224 | Dmitry Bogdanov                                                                                                                                                                      |
|  91 |    411.321162 |    631.722976 | Mali’o Kodis, photograph from <http://commons.wikimedia.org/wiki/File:Trichoplax.jpg>                                                                                                |
|  92 |    141.010863 |    449.704374 | Steven Traver                                                                                                                                                                        |
|  93 |    898.637540 |    273.158337 | Xavier Giroux-Bougard                                                                                                                                                                |
|  94 |     89.522053 |    328.665285 | Zimices                                                                                                                                                                              |
|  95 |    866.572347 |    589.052629 | Gabriela Palomo-Munoz                                                                                                                                                                |
|  96 |    607.868717 |    765.693813 | Dean Schnabel                                                                                                                                                                        |
|  97 |    431.206176 |    622.484246 | Alexandre Vong                                                                                                                                                                       |
|  98 |    766.602784 |    362.217495 | Zimices                                                                                                                                                                              |
|  99 |    759.177006 |    776.525523 | Jimmy Bernot                                                                                                                                                                         |
| 100 |    344.776115 |    429.963027 | Jonathan Wells                                                                                                                                                                       |
| 101 |     33.492457 |    721.490221 | Tim Bertelink (modified by T. Michael Keesey)                                                                                                                                        |
| 102 |    522.536394 |    105.611385 | Gareth Monger                                                                                                                                                                        |
| 103 |    305.296674 |    711.945446 | Chris huh                                                                                                                                                                            |
| 104 |    447.475367 |    781.333158 | Zimices                                                                                                                                                                              |
| 105 |    151.350067 |    683.729801 | Chris huh                                                                                                                                                                            |
| 106 |    705.706305 |    756.476980 | Steven Traver                                                                                                                                                                        |
| 107 |    481.460246 |    269.165907 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                                   |
| 108 |    351.450797 |    472.024423 | Matt Crook                                                                                                                                                                           |
| 109 |    340.693225 |    619.575512 | Ferran Sayol                                                                                                                                                                         |
| 110 |     94.636742 |    483.245692 | Jagged Fang Designs                                                                                                                                                                  |
| 111 |    775.585914 |    717.677436 | Alex Slavenko                                                                                                                                                                        |
| 112 |     83.872003 |    732.974273 | Scott Hartman                                                                                                                                                                        |
| 113 |     48.821219 |    312.446359 | Jake Warner                                                                                                                                                                          |
| 114 |    859.576339 |    700.753660 | Steven Traver                                                                                                                                                                        |
| 115 |     27.868890 |    181.875214 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 116 |    658.470266 |     23.160867 | Gareth Monger                                                                                                                                                                        |
| 117 |    576.678901 |    621.039178 | Caleb M. Brown                                                                                                                                                                       |
| 118 |    733.104588 |    454.637893 | Becky Barnes                                                                                                                                                                         |
| 119 |    456.641440 |    161.964340 | Margot Michaud                                                                                                                                                                       |
| 120 |    319.851909 |     37.133541 | Zimices                                                                                                                                                                              |
| 121 |    694.735898 |    491.746424 | L. Shyamal                                                                                                                                                                           |
| 122 |    635.416373 |    161.389753 | Sharon Wegner-Larsen                                                                                                                                                                 |
| 123 |    538.573622 |    782.019816 | NA                                                                                                                                                                                   |
| 124 |    131.212909 |    393.726368 | Mathilde Cordellier                                                                                                                                                                  |
| 125 |    208.728090 |    427.868724 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                                    |
| 126 |    751.490367 |    556.455332 | Margot Michaud                                                                                                                                                                       |
| 127 |    977.136470 |    556.505145 | Gareth Monger                                                                                                                                                                        |
| 128 |    340.074607 |    683.053640 | Sibi (vectorized by T. Michael Keesey)                                                                                                                                               |
| 129 |    155.575020 |    199.976130 | Matt Crook                                                                                                                                                                           |
| 130 |    872.572737 |    410.991765 | Tracy A. Heath                                                                                                                                                                       |
| 131 |    265.895186 |    529.878558 | Zimices                                                                                                                                                                              |
| 132 |    996.479655 |    172.891654 | Kai R. Caspar                                                                                                                                                                        |
| 133 |    749.404524 |    315.648153 | Noah Schlottman                                                                                                                                                                      |
| 134 |    800.320621 |    162.614601 | Zimices                                                                                                                                                                              |
| 135 |    116.724251 |    324.884708 | Ferran Sayol                                                                                                                                                                         |
| 136 |    578.688289 |    299.784968 | Lukasiniho                                                                                                                                                                           |
| 137 |    759.908401 |     24.784170 | Gareth Monger                                                                                                                                                                        |
| 138 |    207.321804 |    390.216585 | xgirouxb                                                                                                                                                                             |
| 139 |    662.431450 |    183.376231 | Scott Reid                                                                                                                                                                           |
| 140 |    368.879190 |    767.867606 | Steven Traver                                                                                                                                                                        |
| 141 |    578.974601 |    356.242196 | Gareth Monger                                                                                                                                                                        |
| 142 |    495.005901 |    278.872513 | Pete Buchholz                                                                                                                                                                        |
| 143 |    296.722063 |    540.680651 | Jessica Anne Miller                                                                                                                                                                  |
| 144 |    730.400028 |    604.015765 | Chris huh                                                                                                                                                                            |
| 145 |    776.385841 |    145.212388 | NA                                                                                                                                                                                   |
| 146 |    762.457134 |     72.186396 | Margot Michaud                                                                                                                                                                       |
| 147 |    131.640495 |    145.345714 | Rebecca Groom                                                                                                                                                                        |
| 148 |    986.004389 |    757.392224 | Caleb M. Brown                                                                                                                                                                       |
| 149 |    242.307916 |    599.360193 | Sharon Wegner-Larsen                                                                                                                                                                 |
| 150 |    909.451843 |     14.161566 | kreidefossilien.de                                                                                                                                                                   |
| 151 |    626.658523 |    390.037606 | Zimices                                                                                                                                                                              |
| 152 |    568.121647 |    226.434689 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 153 |    446.886107 |    466.310321 | Mali’o Kodis, photograph property of National Museums of Northern Ireland                                                                                                            |
| 154 |    526.097385 |     30.196623 | Jagged Fang Designs                                                                                                                                                                  |
| 155 |     19.705401 |    174.296303 | Margot Michaud                                                                                                                                                                       |
| 156 |     15.339609 |    539.411645 | Antonov (vectorized by T. Michael Keesey)                                                                                                                                            |
| 157 |    648.859055 |    401.413466 | Michelle Site                                                                                                                                                                        |
| 158 |    505.940541 |    425.688745 | S.Martini                                                                                                                                                                            |
| 159 |     14.422063 |    551.425791 | Inessa Voet                                                                                                                                                                          |
| 160 |    243.457021 |    161.403799 | Steven Traver                                                                                                                                                                        |
| 161 |    746.609472 |     98.365901 | Zimices                                                                                                                                                                              |
| 162 |    280.428548 |    731.778805 | Douglas Brown (modified by T. Michael Keesey)                                                                                                                                        |
| 163 |    302.593403 |    504.234020 | Scott Hartman                                                                                                                                                                        |
| 164 |    950.502946 |    240.912447 | Caleb M. Brown                                                                                                                                                                       |
| 165 |    204.613599 |    722.847905 | Margot Michaud                                                                                                                                                                       |
| 166 |    135.380745 |     74.608902 | xgirouxb                                                                                                                                                                             |
| 167 |     79.476285 |    250.488684 | Stemonitis (photography) and T. Michael Keesey (vectorization)                                                                                                                       |
| 168 |    882.763273 |    578.493833 | Margot Michaud                                                                                                                                                                       |
| 169 |    500.225018 |    125.286408 | NA                                                                                                                                                                                   |
| 170 |    347.289625 |    736.954910 | NA                                                                                                                                                                                   |
| 171 |    781.866712 |    127.396934 | NA                                                                                                                                                                                   |
| 172 |    720.905504 |    228.557100 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 173 |    901.110412 |    762.264487 | Oren Peles / vectorized by Yan Wong                                                                                                                                                  |
| 174 |   1005.718769 |    301.518325 | Matt Crook                                                                                                                                                                           |
| 175 |    722.446336 |    484.953705 | Gareth Monger                                                                                                                                                                        |
| 176 |    992.793025 |    225.250065 | NA                                                                                                                                                                                   |
| 177 |    532.889231 |     76.422208 | Tasman Dixon                                                                                                                                                                         |
| 178 |    951.208300 |    424.026628 | Meyer-Wachsmuth I, Curini Galletti M, Jondelius U (<doi:10.1371/journal.pone.0107688>). Vectorization by Y. Wong                                                                     |
| 179 |    591.487818 |    772.911071 | Henry Lydecker                                                                                                                                                                       |
| 180 |    212.500519 |    369.285706 | Zimices                                                                                                                                                                              |
| 181 |    755.608156 |    109.312470 | Sarah Werning                                                                                                                                                                        |
| 182 |    144.817498 |    190.159068 | Trond R. Oskars                                                                                                                                                                      |
| 183 |    468.565965 |    444.876911 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 184 |    963.214599 |    472.277409 | Nobu Tamura                                                                                                                                                                          |
| 185 |    404.760666 |    782.132592 | Matt Crook                                                                                                                                                                           |
| 186 |     49.856515 |    526.965840 | Zimices                                                                                                                                                                              |
| 187 |    836.036686 |    424.121721 | NA                                                                                                                                                                                   |
| 188 |    954.674902 |     23.859410 | Jagged Fang Designs                                                                                                                                                                  |
| 189 |    905.189688 |    727.294695 | Kimberly Haddrell                                                                                                                                                                    |
| 190 |    717.181718 |    584.695025 | Taro Maeda                                                                                                                                                                           |
| 191 |    879.910457 |    713.698039 | Margot Michaud                                                                                                                                                                       |
| 192 |    774.910324 |    489.911834 | Scott Hartman                                                                                                                                                                        |
| 193 |    920.728157 |     35.031313 | Alex Slavenko                                                                                                                                                                        |
| 194 |    517.882729 |    482.415216 | Shyamal                                                                                                                                                                              |
| 195 |    444.817938 |    142.712383 | Margot Michaud                                                                                                                                                                       |
| 196 |    760.817613 |    126.872818 | Ferran Sayol                                                                                                                                                                         |
| 197 |    865.470778 |    375.414419 | Jagged Fang Designs                                                                                                                                                                  |
| 198 |   1019.391341 |    533.754809 | NA                                                                                                                                                                                   |
| 199 |    119.488977 |    668.687574 | Anthony Caravaggi                                                                                                                                                                    |
| 200 |    176.891844 |    451.188749 | NA                                                                                                                                                                                   |
| 201 |     73.049175 |    320.525971 | Armin Reindl                                                                                                                                                                         |
| 202 |    237.409139 |    610.580299 | Kent Elson Sorgon                                                                                                                                                                    |
| 203 |    758.085412 |    583.668579 | FunkMonk                                                                                                                                                                             |
| 204 |    170.125880 |    325.584685 | Lukasiniho                                                                                                                                                                           |
| 205 |    135.844283 |     85.963930 | Mattia Menchetti                                                                                                                                                                     |
| 206 |    883.217315 |    622.518002 | Maxime Dahirel                                                                                                                                                                       |
| 207 |    414.848914 |    331.026913 | FunkMonk                                                                                                                                                                             |
| 208 |    706.039125 |    327.322829 | Richard Lampitt, Jeremy Young / NHM (vectorization by Yan Wong)                                                                                                                      |
| 209 |    290.232131 |    158.535209 | Tracy A. Heath                                                                                                                                                                       |
| 210 |    457.465983 |    112.299523 | Emily Willoughby                                                                                                                                                                     |
| 211 |    524.466198 |    439.684530 | C. Abraczinskas                                                                                                                                                                      |
| 212 |    815.980429 |    722.329258 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 213 |    806.756331 |    142.351350 | Chris huh                                                                                                                                                                            |
| 214 |    253.573498 |    790.776231 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 215 |    181.167435 |    673.759589 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 216 |    757.251488 |    412.151422 | Mareike C. Janiak                                                                                                                                                                    |
| 217 |    224.906458 |     97.419335 | T. Michael Keesey                                                                                                                                                                    |
| 218 |    928.780672 |    203.702427 | Ferran Sayol                                                                                                                                                                         |
| 219 |   1001.972182 |    222.544254 | Dmitry Bogdanov (modified by T. Michael Keesey)                                                                                                                                      |
| 220 |    113.306410 |    469.450324 | Michael Scroggie                                                                                                                                                                     |
| 221 |    374.139753 |    795.411474 | Cesar Julian                                                                                                                                                                         |
| 222 |    123.205458 |     75.036830 | Sean McCann                                                                                                                                                                          |
| 223 |    879.584254 |    191.921686 | T. Michael Keesey (vectorization); Thorsten Assmann, Jörn Buse, Claudia Drees, Ariel-Leib-Leonid Friedman, Tal Levanony, Andrea Matern, Anika Timm, and David W. Wrase (photography) |
| 224 |    580.339964 |    170.824883 | NA                                                                                                                                                                                   |
| 225 |    314.281053 |    742.425274 | Jiekun He                                                                                                                                                                            |
| 226 |    900.011438 |    416.486856 | David Orr                                                                                                                                                                            |
| 227 |     27.157105 |    683.021478 | Tasman Dixon                                                                                                                                                                         |
| 228 |    990.298779 |    766.587461 | Michelle Site                                                                                                                                                                        |
| 229 |    134.199277 |    322.267413 | Steven Traver                                                                                                                                                                        |
| 230 |    207.384182 |     83.394497 | T. Michael Keesey                                                                                                                                                                    |
| 231 |     35.615632 |    665.208309 | Alan Manson (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                          |
| 232 |    178.577089 |    642.756182 | Zimices                                                                                                                                                                              |
| 233 |     97.112370 |    171.638355 | Maija Karala                                                                                                                                                                         |
| 234 |    168.703816 |    779.356456 | Kai R. Caspar                                                                                                                                                                        |
| 235 |    553.480177 |    286.445803 | Trond R. Oskars                                                                                                                                                                      |
| 236 |    597.561632 |    574.170037 | Emily Jane McTavish, from <http://en.wikipedia.org/wiki/File:Coccolithus_pelagicus.jpg>                                                                                              |
| 237 |    310.150226 |    785.446123 | Zsoldos Márton (vectorized by T. Michael Keesey)                                                                                                                                     |
| 238 |    716.471128 |    152.837411 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                                               |
| 239 |    585.224309 |    316.961874 | Steven Traver                                                                                                                                                                        |
| 240 |     30.307446 |    199.475605 | Chris huh                                                                                                                                                                            |
| 241 |    788.856545 |    535.286544 | Margot Michaud                                                                                                                                                                       |
| 242 |    964.971952 |    652.386294 | Melissa Broussard                                                                                                                                                                    |
| 243 |    491.317341 |    463.473859 | Birgit Lang                                                                                                                                                                          |
| 244 |    781.240383 |    322.821600 | Arthur Grosset (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                       |
| 245 |    994.346120 |    783.512671 | Dean Schnabel                                                                                                                                                                        |
| 246 |    821.004840 |    539.827122 | Margot Michaud                                                                                                                                                                       |
| 247 |    173.865381 |    369.659516 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 248 |    145.659839 |    404.528808 | Scott Hartman                                                                                                                                                                        |
| 249 |    262.772922 |    613.976654 | Gareth Monger                                                                                                                                                                        |
| 250 |    854.430491 |    559.928422 | Jack Mayer Wood                                                                                                                                                                      |
| 251 |    277.671457 |     32.843187 | Tauana J. Cunha                                                                                                                                                                      |
| 252 |    701.159474 |     31.131295 | NA                                                                                                                                                                                   |
| 253 |    852.223149 |    781.810345 | Margot Michaud                                                                                                                                                                       |
| 254 |    503.182871 |    331.713071 | Mali’o Kodis, photograph by Jim Vargo                                                                                                                                                |
| 255 |    435.909497 |    431.485717 | NA                                                                                                                                                                                   |
| 256 |    235.642402 |    415.211328 | Qiang Ou                                                                                                                                                                             |
| 257 |     19.532469 |    641.783336 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                                                |
| 258 |    302.258616 |     47.099192 | Tracy A. Heath                                                                                                                                                                       |
| 259 |    140.594639 |    627.169898 | Timothy Knepp of the U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                               |
| 260 |    594.169904 |     74.606296 | Scott Hartman                                                                                                                                                                        |
| 261 |    835.396553 |    526.708112 | Gareth Monger                                                                                                                                                                        |
| 262 |    645.244534 |    228.235198 | Jose Carlos Arenas-Monroy                                                                                                                                                            |
| 263 |    356.313190 |    638.911171 | Frank Denota                                                                                                                                                                         |
| 264 |    812.892248 |    354.162987 | James R. Spotila and Ray Chatterji                                                                                                                                                   |
| 265 |    995.095484 |    647.392836 | Collin Gross                                                                                                                                                                         |
| 266 |    584.142248 |    430.854871 | Mathilde Cordellier                                                                                                                                                                  |
| 267 |   1013.745826 |    259.630457 | Matt Crook                                                                                                                                                                           |
| 268 |    426.748305 |    531.226826 | Tasman Dixon                                                                                                                                                                         |
| 269 |    405.242933 |     73.330839 | Gareth Monger                                                                                                                                                                        |
| 270 |    568.962927 |    569.966994 | Noah Schlottman, photo from Casey Dunn                                                                                                                                               |
| 271 |    168.046568 |     79.579572 | Matt Crook                                                                                                                                                                           |
| 272 |    606.806647 |    471.468461 | T. Michael Keesey (after Kukalová)                                                                                                                                                   |
| 273 |    369.793285 |      8.475726 | Margot Michaud                                                                                                                                                                       |
| 274 |    238.912110 |    117.046337 | Matt Crook                                                                                                                                                                           |
| 275 |    749.267495 |    286.016054 | Zimices                                                                                                                                                                              |
| 276 |    738.742319 |    378.947905 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 277 |    135.089139 |     29.825995 | T. Michael Keesey (photo by J. M. Garg)                                                                                                                                              |
| 278 |    825.113365 |    708.677429 | Birgit Lang                                                                                                                                                                          |
| 279 |    470.629273 |    140.745485 | Rebecca Groom                                                                                                                                                                        |
| 280 |    895.418067 |     67.239628 | Evan Swigart (photography) and T. Michael Keesey (vectorization)                                                                                                                     |
| 281 |     13.828860 |    505.898850 | NA                                                                                                                                                                                   |
| 282 |     28.133398 |    330.285591 | NASA                                                                                                                                                                                 |
| 283 |    647.043648 |    385.338125 | Collin Gross                                                                                                                                                                         |
| 284 |    859.373373 |    793.298290 | Margot Michaud                                                                                                                                                                       |
| 285 |    538.056166 |     83.739589 | Kamil S. Jaron                                                                                                                                                                       |
| 286 |    792.699759 |    499.738136 | Kamil S. Jaron                                                                                                                                                                       |
| 287 |    194.098232 |    486.361772 | Gareth Monger                                                                                                                                                                        |
| 288 |     35.727487 |    494.125239 | Scott Hartman                                                                                                                                                                        |
| 289 |    140.489575 |    377.285255 | Jagged Fang Designs                                                                                                                                                                  |
| 290 |    271.895490 |      7.704906 | Zimices                                                                                                                                                                              |
| 291 |    629.997186 |    624.884418 | Steven Traver                                                                                                                                                                        |
| 292 |    395.892671 |    150.016869 | Margot Michaud                                                                                                                                                                       |
| 293 |    950.005188 |    305.618378 | T. Michael Keesey                                                                                                                                                                    |
| 294 |    514.615701 |    775.873391 | Matt Crook                                                                                                                                                                           |
| 295 |    272.660422 |    793.084288 | CNZdenek                                                                                                                                                                             |
| 296 |    181.489681 |    742.055606 | Yan Wong                                                                                                                                                                             |
| 297 |    532.247720 |    572.520097 | Michael P. Taylor                                                                                                                                                                    |
| 298 |    208.071349 |    470.802992 | T. Michael Keesey                                                                                                                                                                    |
| 299 |    655.824354 |     52.684928 | Joseph Smit (modified by T. Michael Keesey)                                                                                                                                          |
| 300 |    662.624903 |    328.481938 | Zimices                                                                                                                                                                              |
| 301 |    219.899207 |    634.090984 | Matt Crook                                                                                                                                                                           |
| 302 |    700.863111 |    787.986515 | Joanna Wolfe                                                                                                                                                                         |
| 303 |    868.350979 |    575.617621 | NA                                                                                                                                                                                   |
| 304 |    465.283710 |     70.876113 | Matt Crook                                                                                                                                                                           |
| 305 |    372.789336 |    282.716282 | Matt Crook                                                                                                                                                                           |
| 306 |    535.831501 |     18.550998 | Ferran Sayol                                                                                                                                                                         |
| 307 |    350.768244 |    786.243044 | T. Michael Keesey                                                                                                                                                                    |
| 308 |    754.616662 |    347.407640 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 309 |    218.662983 |      8.514253 | NA                                                                                                                                                                                   |
| 310 |    349.274659 |    454.111970 | Ferran Sayol                                                                                                                                                                         |
| 311 |    316.920493 |    130.272994 | NA                                                                                                                                                                                   |
| 312 |    407.496773 |     19.639851 | Archaeodontosaurus (vectorized by T. Michael Keesey)                                                                                                                                 |
| 313 |    101.441051 |     34.037552 | Maija Karala                                                                                                                                                                         |
| 314 |    409.832202 |    101.897560 | Matt Crook                                                                                                                                                                           |
| 315 |    580.303424 |    183.005051 | Gareth Monger                                                                                                                                                                        |
| 316 |    611.809622 |    264.452220 | NA                                                                                                                                                                                   |
| 317 |    583.916087 |     50.742439 | Margot Michaud                                                                                                                                                                       |
| 318 |     40.170285 |    511.657827 | Ferran Sayol                                                                                                                                                                         |
| 319 |    451.795101 |    302.509364 | NA                                                                                                                                                                                   |
| 320 |    331.056568 |    479.928898 | Mason McNair                                                                                                                                                                         |
| 321 |    271.259473 |    746.358241 | Matt Crook                                                                                                                                                                           |
| 322 |    140.669379 |    785.259641 | Michelle Site                                                                                                                                                                        |
| 323 |    701.781676 |    392.695460 | Zimices                                                                                                                                                                              |
| 324 |    332.755925 |    622.032776 | Margot Michaud                                                                                                                                                                       |
| 325 |      5.093537 |    492.274986 | Gopal Murali                                                                                                                                                                         |
| 326 |    779.268849 |    348.084843 | Christine Axon                                                                                                                                                                       |
| 327 |    962.481362 |    399.448484 | Katie S. Collins                                                                                                                                                                     |
| 328 |    724.600282 |    734.607894 | Gareth Monger                                                                                                                                                                        |
| 329 |    210.444645 |    504.624542 | Gareth Monger                                                                                                                                                                        |
| 330 |    241.883290 |     32.859403 | Matt Crook                                                                                                                                                                           |
| 331 |    933.575283 |    442.067955 | Gareth Monger                                                                                                                                                                        |
| 332 |    254.365341 |    572.733260 | NA                                                                                                                                                                                   |
| 333 |    983.831320 |    159.823236 | Michelle Site                                                                                                                                                                        |
| 334 |    950.162165 |    766.376840 | Matt Dempsey                                                                                                                                                                         |
| 335 |    857.177046 |    533.596741 | Andrew A. Farke                                                                                                                                                                      |
| 336 |    123.373862 |    552.393393 | Ingo Braasch                                                                                                                                                                         |
| 337 |    278.497280 |    180.483204 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 338 |    798.627690 |    410.118697 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                                  |
| 339 |    640.103899 |    481.763652 | T. Michael Keesey                                                                                                                                                                    |
| 340 |    164.392019 |    393.350296 | Matt Crook                                                                                                                                                                           |
| 341 |    470.243398 |     10.115925 | Steven Traver                                                                                                                                                                        |
| 342 |     33.247126 |    386.296591 | Ferran Sayol                                                                                                                                                                         |
| 343 |     62.948323 |    712.149060 | Margot Michaud                                                                                                                                                                       |
| 344 |    941.387291 |    223.184235 | T. Michael Keesey, from a photograph by Thea Boodhoo                                                                                                                                 |
| 345 |    390.163382 |    475.648970 | Ferran Sayol                                                                                                                                                                         |
| 346 |     14.419035 |    290.548153 | Joanna Wolfe                                                                                                                                                                         |
| 347 |    561.333125 |    774.218514 | Margot Michaud                                                                                                                                                                       |
| 348 |    151.179424 |      6.949536 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 349 |    921.539399 |    250.464063 | Steven Traver                                                                                                                                                                        |
| 350 |    314.414042 |    732.954668 | Margot Michaud                                                                                                                                                                       |
| 351 |    327.092108 |    513.126775 | Zimices                                                                                                                                                                              |
| 352 |    946.847888 |    768.951063 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 353 |    862.484104 |    720.137431 | NA                                                                                                                                                                                   |
| 354 |    420.072417 |    176.857343 | NA                                                                                                                                                                                   |
| 355 |    884.796856 |    364.278699 | Mali’o Kodis, image from Brockhaus and Efron Encyclopedic Dictionary                                                                                                                 |
| 356 |    928.340762 |    783.783248 | Steven Traver                                                                                                                                                                        |
| 357 |    696.683646 |     39.238453 | Matt Celeskey                                                                                                                                                                        |
| 358 |    766.022034 |     13.295747 | Matt Crook                                                                                                                                                                           |
| 359 |   1001.836245 |    312.327057 | Julio Garza                                                                                                                                                                          |
| 360 |    681.551312 |     32.344639 | Christoph Schomburg                                                                                                                                                                  |
| 361 |     33.609904 |    695.764541 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 362 |    676.830539 |     10.671348 | Anthony Caravaggi                                                                                                                                                                    |
| 363 |    522.780944 |    260.858165 | annaleeblysse                                                                                                                                                                        |
| 364 |     63.073743 |    796.070302 | Mathew Wedel                                                                                                                                                                         |
| 365 |    988.726117 |    401.052508 | James R. Spotila and Ray Chatterji                                                                                                                                                   |
| 366 |    606.760470 |    310.807216 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 367 |    369.786206 |     84.354304 | NA                                                                                                                                                                                   |
| 368 |    320.368693 |     56.970522 | Ferran Sayol                                                                                                                                                                         |
| 369 |    371.455210 |    602.865733 | NA                                                                                                                                                                                   |
| 370 |    550.084652 |    268.355431 | Matt Crook                                                                                                                                                                           |
| 371 |    522.409282 |     63.897218 | Kamil S. Jaron                                                                                                                                                                       |
| 372 |     39.476153 |    354.399086 | FunkMonk                                                                                                                                                                             |
| 373 |   1008.866762 |     11.924522 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                                         |
| 374 |    824.874827 |    108.585731 | Leon P. A. M. Claessens, Patrick M. O’Connor, David M. Unwin                                                                                                                         |
| 375 |     13.606440 |    611.284179 | Maija Karala                                                                                                                                                                         |
| 376 |    399.298029 |    244.449411 | Scott Hartman                                                                                                                                                                        |
| 377 |    179.295006 |    625.068728 | Jagged Fang Designs                                                                                                                                                                  |
| 378 |    148.531326 |    760.337610 | Ferran Sayol                                                                                                                                                                         |
| 379 |    319.654898 |    754.210709 | Ingo Braasch                                                                                                                                                                         |
| 380 |    492.996432 |     57.504031 | Chris huh                                                                                                                                                                            |
| 381 |    799.311791 |    289.845149 | Lukasiniho                                                                                                                                                                           |
| 382 |    114.051229 |    785.512642 | Scott Hartman                                                                                                                                                                        |
| 383 |    861.465099 |    399.319712 | NA                                                                                                                                                                                   |
| 384 |     40.333112 |    624.180262 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                                  |
| 385 |    922.614346 |     23.606141 | Gopal Murali                                                                                                                                                                         |
| 386 |     36.706482 |    245.248017 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 387 |    245.346911 |     22.110313 | Gareth Monger                                                                                                                                                                        |
| 388 |    293.561416 |    518.411087 | Douglas Brown (modified by T. Michael Keesey)                                                                                                                                        |
| 389 |    473.874181 |    191.659245 | L. Shyamal                                                                                                                                                                           |
| 390 |    725.532285 |    648.656847 | NA                                                                                                                                                                                   |
| 391 |    181.200008 |    395.005821 | Scott Hartman, modified by T. Michael Keesey                                                                                                                                         |
| 392 |     13.961923 |    306.110551 | Steven Traver                                                                                                                                                                        |
| 393 |    616.100698 |    452.329090 | Josep Marti Solans                                                                                                                                                                   |
| 394 |    514.840816 |    491.643317 | Mali’o Kodis, image from Brockhaus and Efron Encyclopedic Dictionary                                                                                                                 |
| 395 |    982.037886 |    141.618501 | T. Michael Keesey                                                                                                                                                                    |
| 396 |    439.913297 |    764.156058 | T. Michael Keesey                                                                                                                                                                    |
| 397 |    919.904884 |    444.112208 | Chris huh                                                                                                                                                                            |
| 398 |    814.376637 |    422.586431 | Yan Wong                                                                                                                                                                             |
| 399 |     75.769932 |    344.164132 | Shyamal                                                                                                                                                                              |
| 400 |    422.482916 |    462.783566 | NA                                                                                                                                                                                   |
| 401 |    170.357240 |    460.646211 | Sarah Werning                                                                                                                                                                        |
| 402 |    297.333475 |    215.236834 | NA                                                                                                                                                                                   |
| 403 |     18.378959 |    325.570480 | Chris huh                                                                                                                                                                            |
| 404 |    927.447033 |    272.823257 | Steven Traver                                                                                                                                                                        |
| 405 |    917.772132 |     68.327710 | Ferran Sayol                                                                                                                                                                         |
| 406 |    792.891913 |    189.387944 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 407 |    349.911400 |    667.311811 | Collin Gross                                                                                                                                                                         |
| 408 |    811.062547 |    776.021463 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 409 |    774.039936 |    416.178989 | NA                                                                                                                                                                                   |
| 410 |    406.817003 |     81.036426 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 411 |    711.540251 |    513.950604 | Chris huh                                                                                                                                                                            |
| 412 |    728.799674 |    578.560961 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 413 |    340.948133 |    151.884402 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 414 |    906.032912 |    259.730572 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                                     |
| 415 |    746.751149 |     69.378043 | T. Michael Keesey (vectorization) and Nadiatalent (photography)                                                                                                                      |
| 416 |     26.118834 |    573.345632 | Beth Reinke                                                                                                                                                                          |
| 417 |    426.936119 |    363.853485 | Joanna Wolfe                                                                                                                                                                         |
| 418 |    227.254194 |    737.737547 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 419 |    413.339050 |    382.055866 | Mali’o Kodis, photograph by Cordell Expeditions at Cal Academy                                                                                                                       |
| 420 |    787.002402 |    303.159805 | Margot Michaud                                                                                                                                                                       |
| 421 |    751.949179 |    253.349146 | Ekaterina Kopeykina (vectorized by T. Michael Keesey)                                                                                                                                |
| 422 |    998.938450 |    189.425444 | Mathew Wedel                                                                                                                                                                         |
| 423 |    703.224150 |    483.118075 | Margot Michaud                                                                                                                                                                       |
| 424 |     89.918668 |    627.599245 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 425 |    101.946291 |    381.313611 | Tasman Dixon                                                                                                                                                                         |
| 426 |    856.998659 |    192.095644 | Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey)                                                                                                                     |
| 427 |    335.026945 |    655.777257 | Gareth Monger                                                                                                                                                                        |
| 428 |    388.955966 |      8.423196 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                                          |
| 429 |    790.131706 |    343.497810 | Scott Hartman                                                                                                                                                                        |
| 430 |    759.904389 |    755.282875 | Steven Traver                                                                                                                                                                        |
| 431 |    770.902099 |    386.041441 | Matt Crook                                                                                                                                                                           |
| 432 |    302.264089 |     18.775560 | Chris huh                                                                                                                                                                            |
| 433 |     14.856578 |    660.955302 | Ferran Sayol                                                                                                                                                                         |
| 434 |    474.418177 |    238.203313 | Steven Traver                                                                                                                                                                        |
| 435 |    494.112537 |      8.129474 | Christoph Schomburg                                                                                                                                                                  |
| 436 |    975.952830 |    509.650805 | Tasman Dixon                                                                                                                                                                         |
| 437 |    962.664302 |    427.438102 | Zimices                                                                                                                                                                              |
| 438 |    160.087742 |    704.513032 | Zimices                                                                                                                                                                              |
| 439 |    601.000821 |    431.930013 | SecretJellyMan                                                                                                                                                                       |
| 440 |    811.247389 |    102.517728 | Matt Crook                                                                                                                                                                           |
| 441 |    770.491804 |    543.882846 | Ferran Sayol                                                                                                                                                                         |
| 442 |    729.407724 |    121.694155 | T. Michael Keesey                                                                                                                                                                    |
| 443 |    146.494214 |    472.936226 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 444 |    481.330076 |    769.947198 | Tasman Dixon                                                                                                                                                                         |
| 445 |    561.418629 |     56.193052 | Fir0002/Flagstaffotos (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                |
| 446 |    561.782877 |    609.759843 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 447 |    192.212156 |    473.104652 | Chris A. Hamilton                                                                                                                                                                    |
| 448 |    772.836677 |    189.428569 | Ferran Sayol                                                                                                                                                                         |
| 449 |    650.449644 |    321.261855 | Ingo Braasch                                                                                                                                                                         |
| 450 |    226.575870 |    601.947114 | Sharon Wegner-Larsen                                                                                                                                                                 |
| 451 |    726.682802 |     14.266731 | Beth Reinke                                                                                                                                                                          |
| 452 |    749.998743 |    379.162884 | Gareth Monger                                                                                                                                                                        |
| 453 |    703.260582 |    769.933200 | Manabu Bessho-Uehara                                                                                                                                                                 |
| 454 |    993.841461 |     24.040660 | Ferran Sayol                                                                                                                                                                         |
| 455 |     54.644035 |    677.856529 | Ferran Sayol                                                                                                                                                                         |
| 456 |    900.503746 |    739.808553 | Ferran Sayol                                                                                                                                                                         |
| 457 |    123.394504 |    338.624587 | Dean Schnabel                                                                                                                                                                        |
| 458 |    738.782381 |    406.613857 | Mariana Ruiz Villarreal                                                                                                                                                              |
| 459 |    780.322318 |    449.318754 | Matt Crook                                                                                                                                                                           |
| 460 |    296.127717 |    190.861954 | Margot Michaud                                                                                                                                                                       |
| 461 |     75.370569 |    507.375572 | Anthony Caravaggi                                                                                                                                                                    |
| 462 |    650.304688 |    141.298180 | T. Michael Keesey                                                                                                                                                                    |
| 463 |    319.381835 |    220.355284 | Matt Crook                                                                                                                                                                           |
| 464 |    183.984356 |    348.886249 | Scott Hartman                                                                                                                                                                        |
| 465 |    155.595273 |    378.059234 | T. Michael Keesey (after Masteraah)                                                                                                                                                  |
| 466 |     16.776220 |    157.000787 | Jonathan Lawley                                                                                                                                                                      |
| 467 |    237.833750 |      8.734388 | Mark Witton                                                                                                                                                                          |
| 468 |    983.090907 |     50.900452 | Xavier Giroux-Bougard                                                                                                                                                                |
| 469 |    932.043733 |     14.360839 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                                          |
| 470 |    992.383127 |     78.312004 | Scott Reid                                                                                                                                                                           |
| 471 |    152.024731 |    157.245414 | Matt Crook                                                                                                                                                                           |
| 472 |    142.662850 |    484.507982 | Karl Ragnar Gjertsen (vectorized by T. Michael Keesey)                                                                                                                               |
| 473 |    984.340022 |     87.471618 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                                  |
| 474 |    426.783084 |    328.481808 | Gareth Monger                                                                                                                                                                        |
| 475 |    291.255771 |    587.628402 | Bob Goldstein, Vectorization:Jake Warner                                                                                                                                             |
| 476 |    911.594704 |    291.861272 | Sarah Werning                                                                                                                                                                        |
| 477 |    943.833916 |    433.197430 | Scott Hartman                                                                                                                                                                        |
| 478 |    940.174964 |    207.789897 | NA                                                                                                                                                                                   |
| 479 |     53.725100 |    614.691375 | T. Michael Keesey                                                                                                                                                                    |
| 480 |    262.730306 |     33.429793 | Margot Michaud                                                                                                                                                                       |
| 481 |    844.044685 |    448.382796 | Scott Hartman                                                                                                                                                                        |
| 482 |      7.690525 |    624.521340 | Scott Hartman                                                                                                                                                                        |
| 483 |    739.226369 |    586.864576 | Falconaumanni and T. Michael Keesey                                                                                                                                                  |
| 484 |    370.270418 |    582.741925 | Chris huh                                                                                                                                                                            |
| 485 |    215.832460 |    459.855032 | Samanta Orellana                                                                                                                                                                     |
| 486 |    348.461389 |    503.686398 | Benchill                                                                                                                                                                             |
| 487 |    138.338676 |    770.724226 | Tasman Dixon                                                                                                                                                                         |
| 488 |    196.998585 |    664.903042 | Gareth Monger                                                                                                                                                                        |
| 489 |    821.221573 |    167.338011 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 490 |    897.304147 |     25.529366 | Mark Miller                                                                                                                                                                          |
| 491 |    333.479016 |    782.395238 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                                        |
| 492 |    871.177643 |    519.970666 | NA                                                                                                                                                                                   |
| 493 |    778.343100 |    330.660820 | Jagged Fang Designs                                                                                                                                                                  |
| 494 |    951.779700 |    566.039523 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                                    |
| 495 |    874.321252 |    179.721597 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 496 |    422.425155 |    541.048252 | Jaime Headden                                                                                                                                                                        |
| 497 |    248.479650 |    401.031295 | Iain Reid                                                                                                                                                                            |
| 498 |    191.388355 |     67.372612 | Zimices                                                                                                                                                                              |
| 499 |     94.954874 |    504.886573 | Matt Crook                                                                                                                                                                           |
| 500 |     76.680370 |    487.934056 | Rebecca Groom                                                                                                                                                                        |
| 501 |    548.318650 |     34.382788 | Daniel Jaron                                                                                                                                                                         |
| 502 |    483.354960 |    797.735438 | Tasman Dixon                                                                                                                                                                         |
| 503 |     13.380810 |    250.830167 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 504 |     80.001183 |    700.889613 | Andrew A. Farke, modified from original by H. Milne Edwards                                                                                                                          |
| 505 |    357.138166 |    744.093938 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                                       |
| 506 |    752.861944 |    238.348427 | Ferran Sayol                                                                                                                                                                         |
| 507 |    423.050926 |    346.432430 | Noah Schlottman, photo by Museum of Geology, University of Tartu                                                                                                                     |
| 508 |     12.174394 |     32.214157 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 509 |    543.420826 |    535.002872 | Zimices                                                                                                                                                                              |
| 510 |    761.139803 |    503.486678 | Matt Crook                                                                                                                                                                           |
| 511 |    134.650527 |    437.058409 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 512 |    200.870245 |    651.547449 | Zimices                                                                                                                                                                              |
| 513 |    738.789036 |    722.910776 | Sarah Werning                                                                                                                                                                        |
| 514 |    787.720326 |    114.495581 | H. F. O. March (modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel)                                                                                                 |
| 515 |    144.441563 |    673.898986 | Ferran Sayol                                                                                                                                                                         |
| 516 |    757.643183 |    395.995846 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 517 |    827.283464 |    347.474776 | Margot Michaud                                                                                                                                                                       |
| 518 |     24.891365 |    788.949221 | Collin Gross                                                                                                                                                                         |
| 519 |    750.139908 |    439.835399 | Melissa Broussard                                                                                                                                                                    |
| 520 |    283.232826 |    595.533673 | CNZdenek                                                                                                                                                                             |
| 521 |    842.235990 |    715.329975 | Gareth Monger                                                                                                                                                                        |
| 522 |    174.023679 |    339.827264 | Matt Crook                                                                                                                                                                           |
| 523 |   1006.414866 |    196.823406 | Sarah Werning                                                                                                                                                                        |
| 524 |    756.547386 |    450.684917 | T. Michael Keesey                                                                                                                                                                    |
| 525 |    406.703135 |    607.754092 | Mark Hannaford (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                       |
| 526 |    791.255578 |     98.691459 | Matt Crook                                                                                                                                                                           |
| 527 |    555.997900 |    564.028269 | Dean Schnabel                                                                                                                                                                        |
| 528 |    696.464986 |    157.445408 | NA                                                                                                                                                                                   |
| 529 |    262.039798 |     42.658230 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 530 |    170.390401 |    653.253933 | Steven Traver                                                                                                                                                                        |
| 531 |    532.544877 |    548.069817 | Tyler McCraney                                                                                                                                                                       |
| 532 |    944.217640 |    255.156510 | Matt Crook                                                                                                                                                                           |
| 533 |    923.063889 |    295.553617 | Jaime Headden                                                                                                                                                                        |
| 534 |    871.759394 |    260.674771 | Aadx                                                                                                                                                                                 |
| 535 |    434.958406 |    235.305197 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                              |
| 536 |     79.985888 |    114.115519 | Christoph Schomburg                                                                                                                                                                  |
| 537 |    971.384442 |    406.909675 | Ferran Sayol                                                                                                                                                                         |
| 538 |    878.782214 |    790.136632 | Jagged Fang Designs                                                                                                                                                                  |
| 539 |    224.998136 |    619.004992 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 540 |    573.469513 |      7.129424 | Jiekun He                                                                                                                                                                            |
| 541 |    591.595824 |    457.180470 | Andrew Farke and Joseph Sertich                                                                                                                                                      |
| 542 |    938.619607 |    482.651159 | Scott Hartman                                                                                                                                                                        |
| 543 |    276.402062 |    688.709157 | Caleb M. Brown                                                                                                                                                                       |
| 544 |    542.887776 |     68.117819 | Beth Reinke                                                                                                                                                                          |
| 545 |    642.575397 |    176.422715 | Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey)                                                                                                                     |
| 546 |    896.181234 |    171.434983 | Fir0002/Flagstaffotos (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                |
| 547 |    951.161368 |     34.203380 | H. F. O. March (vectorized by T. Michael Keesey)                                                                                                                                     |
| 548 |     53.140819 |    544.303709 | Dmitry Bogdanov                                                                                                                                                                      |
| 549 |     32.044246 |     53.521618 | Richard Ruggiero, vectorized by Zimices                                                                                                                                              |
| 550 |    108.218390 |     42.380720 | Kimberly Haddrell                                                                                                                                                                    |
| 551 |     27.169681 |    522.684275 | T. Michael Keesey                                                                                                                                                                    |
| 552 |    102.848730 |    682.950125 | Francis de Laporte de Castelnau (vectorized by T. Michael Keesey)                                                                                                                    |
| 553 |    187.334953 |    680.598735 | Scott Hartman                                                                                                                                                                        |
| 554 |    640.274512 |    494.940751 | Margot Michaud                                                                                                                                                                       |
| 555 |     18.799563 |    780.448596 | T. Michael Keesey (from a photo by Maximilian Paradiz)                                                                                                                               |
| 556 |    125.659439 |     42.503566 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 557 |     80.790016 |    687.964546 | Sarah Werning                                                                                                                                                                        |
| 558 |     40.926419 |    497.779437 | Jagged Fang Designs                                                                                                                                                                  |
| 559 |     29.151194 |    556.139586 | Ferran Sayol                                                                                                                                                                         |
| 560 |    686.398895 |     59.065902 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 561 |    644.508072 |    207.714043 | Caleb M. Gordon                                                                                                                                                                      |
| 562 |     84.387987 |    520.861252 | Emily Jane McTavish                                                                                                                                                                  |
| 563 |    725.929794 |    322.331802 | Steven Traver                                                                                                                                                                        |
| 564 |    958.891539 |    554.816213 | Christoph Schomburg                                                                                                                                                                  |
| 565 |    770.408070 |    337.269228 | NA                                                                                                                                                                                   |
| 566 |    171.492668 |    305.077808 | Michael Scroggie, from original photograph by Gary M. Stolz, USFWS (original photograph in public domain).                                                                           |
| 567 |    828.651233 |    390.534274 | Yan Wong                                                                                                                                                                             |
| 568 |    515.119540 |    125.671291 | Margot Michaud                                                                                                                                                                       |
| 569 |    983.839767 |    430.863960 | T. Michael Keesey                                                                                                                                                                    |
| 570 |   1015.123905 |    137.381373 | Rebecca Groom                                                                                                                                                                        |
| 571 |   1001.318707 |    392.545458 | Zimices                                                                                                                                                                              |
| 572 |    177.651043 |    605.285253 | Matt Crook                                                                                                                                                                           |
| 573 |    736.600992 |    245.579129 | Rebecca Groom                                                                                                                                                                        |
| 574 |    427.166339 |    753.284879 | Christopher Chávez                                                                                                                                                                   |
| 575 |    163.317648 |    289.284387 | FunkMonk                                                                                                                                                                             |
| 576 |    639.954158 |    185.407203 | Mercedes Yrayzoz (vectorized by T. Michael Keesey)                                                                                                                                   |
| 577 |   1014.564301 |    163.005091 | Smokeybjb, vectorized by Zimices                                                                                                                                                     |
| 578 |    597.801311 |     65.572575 | NA                                                                                                                                                                                   |
| 579 |    486.241996 |    329.703712 | Jonathan Wells                                                                                                                                                                       |
| 580 |    563.999747 |    551.550373 | Michael Scroggie                                                                                                                                                                     |
| 581 |     75.675175 |    620.077508 | Matt Crook                                                                                                                                                                           |
| 582 |    459.637634 |    279.207092 | Sarah Werning                                                                                                                                                                        |
| 583 |    114.186139 |    280.969379 | NA                                                                                                                                                                                   |
| 584 |    915.104164 |    782.537736 | Alexandre Vong                                                                                                                                                                       |
| 585 |    515.776695 |     52.745031 | Jagged Fang Designs                                                                                                                                                                  |
| 586 |    969.221974 |     79.282939 | Ferran Sayol                                                                                                                                                                         |
| 587 |    253.138675 |    590.644575 | Tyler Greenfield                                                                                                                                                                     |
| 588 |   1013.947411 |    678.778803 | Margot Michaud                                                                                                                                                                       |
| 589 |    257.538841 |    188.829325 | Birgit Lang                                                                                                                                                                          |
| 590 |    838.730764 |    362.280153 | Margot Michaud                                                                                                                                                                       |
| 591 |    927.210310 |    451.015490 | Fritz Geller-Grimm (vectorized by T. Michael Keesey)                                                                                                                                 |
| 592 |    617.345903 |      3.949393 | Jakovche                                                                                                                                                                             |
| 593 |    632.540351 |     77.916649 | Jagged Fang Designs                                                                                                                                                                  |
| 594 |    537.017046 |     96.708083 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 595 |    161.381178 |    480.703673 | Michael Wolf (photo), Hans Hillewaert (editing), T. Michael Keesey (vectorization)                                                                                                   |
| 596 |    168.486631 |    502.981572 | Henry Lydecker                                                                                                                                                                       |
| 597 |    736.652405 |      9.679947 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 598 |   1007.815591 |    273.824564 | Patrick Strutzenberger                                                                                                                                                               |
| 599 |    918.612644 |    742.586761 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                                     |
| 600 |    747.130442 |    488.688712 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                                        |
| 601 |    969.813365 |    448.777659 | Trond R. Oskars                                                                                                                                                                      |
| 602 |    138.510525 |    602.157834 | T. Michael Keesey                                                                                                                                                                    |
| 603 |    203.642152 |    448.419369 | Matt Wilkins                                                                                                                                                                         |
| 604 |    736.516692 |    106.507572 | Jon Hill (Photo by DickDaniels: <http://en.wikipedia.org/wiki/File:Green_Woodhoopoe_RWD7.jpg>)                                                                                       |
| 605 |    682.695330 |    412.981636 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                                             |
| 606 |    375.679921 |    494.806739 | Mali’o Kodis, photograph by John Slapcinsky                                                                                                                                          |
| 607 |    358.501262 |    135.565648 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                                   |
| 608 |    290.313609 |    619.292265 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 609 |    147.881607 |    283.633174 | Matt Crook                                                                                                                                                                           |
| 610 |    990.994045 |    414.632920 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                                               |
| 611 |     37.150468 |    229.649811 | Matt Crook                                                                                                                                                                           |
| 612 |    739.795037 |    122.196219 | Zimices                                                                                                                                                                              |
| 613 |    169.455872 |    772.287070 | Lukasiniho                                                                                                                                                                           |
| 614 |    477.542955 |    249.718051 | Becky Barnes                                                                                                                                                                         |
| 615 |    463.784778 |    759.513916 | Matt Crook                                                                                                                                                                           |
| 616 |    589.447790 |    472.815048 | Jaime A. Headden (vectorized by T. Michael Keesey)                                                                                                                                   |
| 617 |    164.128220 |    756.716685 | Zimices                                                                                                                                                                              |
| 618 |    196.541397 |    352.171276 | NA                                                                                                                                                                                   |
| 619 |    268.375554 |    112.148877 | NA                                                                                                                                                                                   |
| 620 |    625.572491 |    484.050075 | L. Shyamal                                                                                                                                                                           |
| 621 |    821.011392 |    361.292199 | Kai R. Caspar                                                                                                                                                                        |
| 622 |    113.134885 |    402.691651 | Margot Michaud                                                                                                                                                                       |
| 623 |    765.242296 |    699.728587 | Crystal Maier                                                                                                                                                                        |
| 624 |    708.744650 |    651.043637 | Margot Michaud                                                                                                                                                                       |
| 625 |     13.680784 |    592.023912 | Steven Traver                                                                                                                                                                        |
| 626 |    747.005833 |    220.440124 | Scott Hartman                                                                                                                                                                        |
| 627 |    427.657701 |    165.135590 | NA                                                                                                                                                                                   |
| 628 |    206.372816 |     60.849419 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 629 |    891.067702 |    502.882217 | Ferran Sayol                                                                                                                                                                         |
| 630 |     12.285153 |    194.176581 | Ferran Sayol                                                                                                                                                                         |
| 631 |    278.990571 |    717.856282 | Margot Michaud                                                                                                                                                                       |
| 632 |    569.279424 |    233.116319 | T. Michael Keesey (after James & al.)                                                                                                                                                |
| 633 |    138.961324 |     20.062683 | Emily Willoughby                                                                                                                                                                     |
| 634 |    904.582169 |      2.876272 | Chris huh                                                                                                                                                                            |
| 635 |    680.086531 |    317.682391 | Iain Reid                                                                                                                                                                            |
| 636 |    507.335425 |    471.496781 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                                         |
| 637 |    142.375444 |    274.586025 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 638 |     61.011841 |    250.183806 | Juan Carlos Jerí                                                                                                                                                                     |
| 639 |    700.089134 |    169.372683 | Dennis C. Murphy, after <https://commons.wikimedia.org/wiki/File:Queensland_State_Archives_2981_Cane_toads_at_the_Meringa_Sugar_Experiment_Station_North_Queensland_c_1935.png>      |
| 640 |    399.544384 |    255.931839 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                                        |
| 641 |    742.956506 |    574.437190 | Jose Carlos Arenas-Monroy                                                                                                                                                            |
| 642 |    153.694141 |    789.852872 | Gregor Bucher, Max Farnworth                                                                                                                                                         |
| 643 |    161.010494 |    674.910151 | Matt Crook                                                                                                                                                                           |
| 644 |    706.501415 |    448.268125 | T. Michael Keesey                                                                                                                                                                    |
| 645 |    425.127595 |    479.841877 | Zimices                                                                                                                                                                              |
| 646 |    283.352778 |    551.112763 | Jagged Fang Designs                                                                                                                                                                  |
| 647 |    423.439344 |    550.139439 | Tracy A. Heath                                                                                                                                                                       |
| 648 |    941.849708 |    451.444144 | Matt Crook                                                                                                                                                                           |
| 649 |    772.036636 |     87.026074 | Metalhead64 (vectorized by T. Michael Keesey)                                                                                                                                        |
| 650 |     84.247389 |    384.515194 | T. Michael Keesey                                                                                                                                                                    |
| 651 |    858.052650 |    514.773828 | Ferran Sayol                                                                                                                                                                         |
| 652 |     10.861293 |    523.227774 | Zimices                                                                                                                                                                              |
| 653 |   1009.477524 |    123.069845 | NA                                                                                                                                                                                   |
| 654 |    464.198346 |    470.064444 | Steven Coombs                                                                                                                                                                        |
| 655 |     20.579763 |      9.653149 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 656 |    112.693094 |    445.104905 | Mali’o Kodis, photograph by John Slapcinsky                                                                                                                                          |
| 657 |   1017.135055 |    187.389281 | NA                                                                                                                                                                                   |
| 658 |    671.757029 |    152.702602 | Scott Hartman                                                                                                                                                                        |
| 659 |    134.844347 |    232.858564 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                                                        |
| 660 |    308.584388 |    517.970402 | Tarique Sani (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                         |
| 661 |     15.557324 |    458.981697 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                                |
| 662 |    611.020471 |    279.846586 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 663 |    434.354541 |    575.044894 | Henry Lydecker                                                                                                                                                                       |
| 664 |    989.089302 |    662.725204 | Zimices                                                                                                                                                                              |
| 665 |    795.783899 |    760.216555 | Margot Michaud                                                                                                                                                                       |
| 666 |    962.530344 |    784.668205 | Caio Bernardes, vectorized by Zimices                                                                                                                                                |
| 667 |    742.361876 |    356.087979 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 668 |    930.652041 |    286.913552 | NA                                                                                                                                                                                   |
| 669 |    135.046508 |    611.703479 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 670 |    413.713141 |    769.944814 | Zimices                                                                                                                                                                              |
| 671 |    891.590760 |    651.338476 | Ferran Sayol                                                                                                                                                                         |
| 672 |    979.654204 |    196.972021 | NA                                                                                                                                                                                   |
| 673 |    769.036112 |    305.809832 | NA                                                                                                                                                                                   |
| 674 |    664.328251 |    239.077765 | Margot Michaud                                                                                                                                                                       |
| 675 |    660.015093 |      5.489233 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 676 |    792.587998 |    437.025265 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 677 |    286.998855 |    782.790341 | Chris huh                                                                                                                                                                            |
| 678 |    954.186422 |    167.620909 | Tauana J. Cunha                                                                                                                                                                      |
| 679 |     67.755132 |    228.364394 | Allison Pease                                                                                                                                                                        |
| 680 |    426.306196 |    246.724882 | Alex Slavenko                                                                                                                                                                        |
| 681 |     19.255916 |    473.803397 | Tracy A. Heath                                                                                                                                                                       |
| 682 |    310.870923 |     45.012765 | Yan Wong                                                                                                                                                                             |
| 683 |    105.476880 |    748.184155 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 684 |    608.328119 |     85.888542 | Zimices                                                                                                                                                                              |
| 685 |    954.472843 |     73.908285 | Benchill                                                                                                                                                                             |
| 686 |    851.111714 |    548.926246 | Gabriel Lio, vectorized by Zimices                                                                                                                                                   |
| 687 |   1018.232022 |    744.401499 | Tyler Greenfield                                                                                                                                                                     |
| 688 |    973.777118 |     15.327474 | Matt Crook                                                                                                                                                                           |
| 689 |    729.203799 |     28.443568 | Steven Traver                                                                                                                                                                        |
| 690 |    861.009461 |    730.491049 | Tasman Dixon                                                                                                                                                                         |
| 691 |    142.438925 |    754.028060 | Emily Willoughby                                                                                                                                                                     |
| 692 |    992.912894 |    375.956793 | Joanna Wolfe                                                                                                                                                                         |
| 693 |    891.224794 |    288.520642 | T. Michael Keesey                                                                                                                                                                    |
| 694 |    838.397389 |    509.967391 | Ferran Sayol                                                                                                                                                                         |
| 695 |    625.362328 |    459.226089 | Mark Miller                                                                                                                                                                          |
| 696 |    525.601060 |    559.682388 | Harold N Eyster                                                                                                                                                                      |
| 697 |    203.397056 |    637.109423 | Katie S. Collins                                                                                                                                                                     |
| 698 |    931.350184 |     84.059143 | T. Michael Keesey (vectorization); Thorsten Assmann, Jörn Buse, Claudia Drees, Ariel-Leib-Leonid Friedman, Tal Levanony, Andrea Matern, Anika Timm, and David W. Wrase (photography) |
| 699 |    475.720024 |    175.512216 | Martin Kevil                                                                                                                                                                         |
| 700 |    778.824622 |    503.254277 | Steven Traver                                                                                                                                                                        |
| 701 |    731.722216 |    520.277139 | Gareth Monger                                                                                                                                                                        |
| 702 |    402.077942 |    360.141222 | Sarah Werning                                                                                                                                                                        |
| 703 |     14.497906 |    215.500488 | Tauana J. Cunha                                                                                                                                                                      |
| 704 |    467.248875 |    781.937134 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 705 |    608.275607 |    145.509286 | Gareth Monger                                                                                                                                                                        |
| 706 |     72.898886 |    334.364387 | Scott Hartman                                                                                                                                                                        |
| 707 |    742.354720 |    266.819780 | NA                                                                                                                                                                                   |
| 708 |    501.949951 |    494.759112 | H. F. O. March (vectorized by T. Michael Keesey)                                                                                                                                     |
| 709 |    976.076116 |    751.345733 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 710 |    129.337190 |    292.878100 | Noah Schlottman, photo by Antonio Guillén                                                                                                                                            |
| 711 |    563.362500 |    199.558238 | JJ Harrison (vectorized by T. Michael Keesey)                                                                                                                                        |
| 712 |    500.041953 |    116.576432 | Margot Michaud                                                                                                                                                                       |
| 713 |    284.216032 |    772.504440 | Sean McCann                                                                                                                                                                          |
| 714 |    512.644244 |    605.514967 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 715 |    803.997690 |    553.388148 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 716 |    172.867915 |    374.040266 | Dave Souza (vectorized by T. Michael Keesey)                                                                                                                                         |
| 717 |    742.286618 |      5.887999 | Young and Zhao (1972:figure 4), modified by Michael P. Taylor                                                                                                                        |
| 718 |    735.464769 |    503.097326 | Ray Simpson (vectorized by T. Michael Keesey)                                                                                                                                        |
| 719 |    706.799648 |    607.183940 | NA                                                                                                                                                                                   |
| 720 |    557.684598 |    333.524615 | Margot Michaud                                                                                                                                                                       |
| 721 |    328.965447 |    448.496780 | Zimices                                                                                                                                                                              |
| 722 |    712.230062 |    495.320777 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                                              |
| 723 |    608.936560 |    610.280148 | Sarah Werning                                                                                                                                                                        |
| 724 |    418.509754 |    148.350156 | Sergio A. Muñoz-Gómez                                                                                                                                                                |
| 725 |    443.263321 |    218.881221 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                                         |
| 726 |     10.664681 |    743.684458 | Jagged Fang Designs                                                                                                                                                                  |
| 727 |    509.219905 |     79.058815 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                                                    |
| 728 |    982.792969 |    387.151638 | Chris huh                                                                                                                                                                            |
| 729 |    302.827790 |    134.217052 | Scott Hartman                                                                                                                                                                        |
| 730 |    938.095979 |    157.800371 | Emily Willoughby                                                                                                                                                                     |
| 731 |    742.558345 |    467.143343 | (after Spotila 2004)                                                                                                                                                                 |
| 732 |    336.628866 |     93.231538 | Chris Jennings (vectorized by A. Verrière)                                                                                                                                           |
| 733 |    570.174275 |    203.604790 | Margot Michaud                                                                                                                                                                       |
| 734 |    335.058960 |     65.454011 | Matt Crook                                                                                                                                                                           |
| 735 |    232.981567 |    426.165932 | Tasman Dixon                                                                                                                                                                         |
| 736 |    238.879407 |    745.881703 | Terpsichores                                                                                                                                                                         |
| 737 |    850.336575 |    368.577202 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 738 |    677.996067 |     50.520780 | Tasman Dixon                                                                                                                                                                         |
| 739 |    166.496218 |    177.206874 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 740 |    186.501096 |    440.881897 | Margot Michaud                                                                                                                                                                       |
| 741 |    338.294805 |    642.546468 | T. Michael Keesey                                                                                                                                                                    |
| 742 |    733.073822 |    256.975100 | Michael B. H. (vectorized by T. Michael Keesey)                                                                                                                                      |
| 743 |    588.730556 |      5.706570 | Scott Hartman                                                                                                                                                                        |
| 744 |    315.134969 |    181.691939 | NA                                                                                                                                                                                   |
| 745 |    709.769270 |    257.791102 | Dean Schnabel                                                                                                                                                                        |
| 746 |    362.383090 |    487.645179 | Zimices                                                                                                                                                                              |
| 747 |    303.579237 |    558.932927 | Gareth Monger                                                                                                                                                                        |
| 748 |    255.782790 |    415.060106 | Chris huh                                                                                                                                                                            |
| 749 |    180.949364 |     36.320286 | Scott Hartman                                                                                                                                                                        |
| 750 |    187.443718 |    418.799161 | Matt Crook                                                                                                                                                                           |
| 751 |    134.251442 |    193.587163 | M Kolmann                                                                                                                                                                            |
| 752 |    401.274022 |    654.493494 | Wynston Cooper (photo) and Albertonykus (silhouette)                                                                                                                                 |
| 753 |   1005.325871 |    135.679135 | T. Michael Keesey                                                                                                                                                                    |
| 754 |     32.232414 |    779.943567 | Matt Martyniuk                                                                                                                                                                       |
| 755 |    398.008205 |    180.646650 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 756 |    178.549980 |    786.661597 | Matt Martyniuk                                                                                                                                                                       |
| 757 |    403.155673 |    333.129755 | NA                                                                                                                                                                                   |
| 758 |     20.840279 |    627.387202 | Ferran Sayol                                                                                                                                                                         |
| 759 |    214.720699 |    410.069386 | Smokeybjb                                                                                                                                                                            |
| 760 |    848.784488 |    680.819703 | Melissa Broussard                                                                                                                                                                    |
| 761 |    121.234719 |    651.326914 | Steven Traver                                                                                                                                                                        |
| 762 |     43.201902 |    576.059282 | Neil Kelley                                                                                                                                                                          |
| 763 |    469.163590 |    428.941898 | Lindberg (vectorized by T. Michael Keesey)                                                                                                                                           |
| 764 |    786.856571 |    184.111685 | Christine Axon                                                                                                                                                                       |
| 765 |    893.057196 |    378.134717 | L. Shyamal                                                                                                                                                                           |
| 766 |    119.864104 |    624.725234 | Gareth Monger                                                                                                                                                                        |
| 767 |    968.172392 |    795.375518 | Tony Ayling                                                                                                                                                                          |
| 768 |    422.664774 |    723.323758 | Collin Gross                                                                                                                                                                         |
| 769 |    428.478300 |    523.495560 | Pete Buchholz                                                                                                                                                                        |
| 770 |    689.572755 |    129.352932 | Alexandre Vong                                                                                                                                                                       |
| 771 |    911.901174 |    656.309770 | Matt Crook                                                                                                                                                                           |
| 772 |     27.153458 |    362.882238 | T. Michael Keesey (after Mivart)                                                                                                                                                     |
| 773 |    281.422450 |    644.629484 | Prin Pattawaro (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                       |
| 774 |    601.768574 |    785.083220 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 775 |    713.916031 |     56.264288 | Matt Crook                                                                                                                                                                           |
| 776 |    211.407770 |    364.893990 | Gareth Monger                                                                                                                                                                        |
| 777 |    600.038732 |    622.522130 | Jagged Fang Designs                                                                                                                                                                  |
| 778 |   1000.127603 |    795.766962 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                                             |
| 779 |    564.573205 |    276.784618 | Jaime Headden                                                                                                                                                                        |
| 780 |    414.832959 |    165.282692 | T. Michael Keesey                                                                                                                                                                    |
| 781 |    354.321728 |    589.572307 | Joanna Wolfe                                                                                                                                                                         |
| 782 |    598.565258 |    337.412642 | Zimices                                                                                                                                                                              |
| 783 |    333.656195 |    769.852555 | Margot Michaud                                                                                                                                                                       |
| 784 |    501.591089 |    792.025524 | Jagged Fang Designs                                                                                                                                                                  |
| 785 |    238.143536 |    177.583945 | Scott Hartman                                                                                                                                                                        |
| 786 |    492.042742 |    433.240743 | Tracy A. Heath                                                                                                                                                                       |
| 787 |    501.660519 |    135.013494 | NA                                                                                                                                                                                   |
| 788 |    114.868482 |    366.890933 | Lisa Byrne                                                                                                                                                                           |
| 789 |   1005.928475 |    556.524272 | Alexandre Vong                                                                                                                                                                       |
| 790 |    273.638681 |    583.682145 | Sam Droege (photo) and T. Michael Keesey (vectorization)                                                                                                                             |
| 791 |    472.620946 |    622.362326 | Lukas Panzarin                                                                                                                                                                       |
| 792 |    618.675281 |     81.692780 | Lukas Panzarin                                                                                                                                                                       |
| 793 |    779.452279 |    708.724871 | Scott Hartman                                                                                                                                                                        |
| 794 |    121.638017 |    694.460924 | L. Shyamal                                                                                                                                                                           |
| 795 |    645.792326 |    465.836234 | Jagged Fang Designs                                                                                                                                                                  |
| 796 |    834.214393 |    157.270723 | Maija Karala                                                                                                                                                                         |
| 797 |    409.534224 |    468.880080 | S.Martini                                                                                                                                                                            |
| 798 |    660.406868 |     64.512376 | Conty (vectorized by T. Michael Keesey)                                                                                                                                              |
| 799 |    747.833812 |     52.730350 | Dinah Challen                                                                                                                                                                        |
| 800 |    588.967436 |    586.498331 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 801 |    327.104754 |    642.722186 | L. Shyamal                                                                                                                                                                           |
| 802 |    800.023259 |    426.572686 | L. Shyamal                                                                                                                                                                           |
| 803 |    920.941918 |     46.997529 | Sarah Werning                                                                                                                                                                        |
| 804 |    694.735310 |    407.809863 | Sarah Werning                                                                                                                                                                        |
| 805 |    666.140116 |    485.661596 | Bryan Carstens                                                                                                                                                                       |
| 806 |     37.592726 |    331.969130 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 807 |     28.195332 |     41.448592 | Zimices                                                                                                                                                                              |
| 808 |    866.776848 |    656.426508 | NA                                                                                                                                                                                   |
| 809 |    435.717068 |    599.448959 | Emily Jane McTavish                                                                                                                                                                  |
| 810 |    606.623131 |     58.787479 | Gareth Monger                                                                                                                                                                        |
| 811 |    122.142764 |    371.073952 | Mathew Wedel                                                                                                                                                                         |
| 812 |    966.721026 |    639.769694 | Birgit Lang                                                                                                                                                                          |
| 813 |    261.351616 |    205.049939 | Zimices                                                                                                                                                                              |
| 814 |     64.513840 |    737.370137 | Zimices                                                                                                                                                                              |
| 815 |    319.386688 |    769.065621 | Zimices                                                                                                                                                                              |
| 816 |    393.168074 |    164.825110 | Steven Traver                                                                                                                                                                        |
| 817 |    620.639426 |    397.965483 | Ferran Sayol                                                                                                                                                                         |
| 818 |    853.138612 |    156.796922 | Juan Carlos Jerí                                                                                                                                                                     |
| 819 |    384.259272 |    233.889961 | Zimices                                                                                                                                                                              |
| 820 |    359.265628 |    626.564810 | Ferran Sayol                                                                                                                                                                         |
| 821 |    910.143783 |    169.075153 | Josefine Bohr Brask                                                                                                                                                                  |
| 822 |   1008.759209 |    490.057885 | Matt Crook                                                                                                                                                                           |
| 823 |     54.016474 |    734.106285 | Zimices                                                                                                                                                                              |
| 824 |    935.635546 |    308.813343 | T. Michael Keesey                                                                                                                                                                    |
| 825 |     90.013183 |    255.587672 | Christine Axon                                                                                                                                                                       |
| 826 |    364.001999 |    272.401587 | Scott Hartman                                                                                                                                                                        |
| 827 |    423.200376 |    786.434563 | Matt Crook                                                                                                                                                                           |
| 828 |    155.491556 |     24.627641 | T. Michael Keesey                                                                                                                                                                    |
| 829 |     20.687365 |    272.382997 | Kailah Thorn & Mark Hutchinson                                                                                                                                                       |
| 830 |    731.525276 |    746.207799 | L. Shyamal                                                                                                                                                                           |
| 831 |    195.014925 |    624.057605 | Zimices                                                                                                                                                                              |
| 832 |    386.236767 |    604.268968 | Michelle Site                                                                                                                                                                        |
| 833 |    872.252013 |    322.874854 | Scott Hartman                                                                                                                                                                        |
| 834 |     15.111922 |    676.625296 | Zimices                                                                                                                                                                              |
| 835 |    633.167051 |    216.138014 | Rebecca Groom                                                                                                                                                                        |
| 836 |    701.969133 |     20.161903 | Maxime Dahirel                                                                                                                                                                       |
| 837 |    218.947244 |    668.027793 | Zimices                                                                                                                                                                              |
| 838 |     29.528172 |    219.825635 | Steven Traver                                                                                                                                                                        |
| 839 |    681.575477 |     20.017694 | Walter Vladimir                                                                                                                                                                      |
| 840 |    885.434414 |    440.223364 | Ville-Veikko Sinkkonen                                                                                                                                                               |
| 841 |    418.898861 |    688.166570 | Greg Schechter (original photo), Renato Santos (vector silhouette)                                                                                                                   |
| 842 |    960.615820 |    575.411528 | Cesar Julian                                                                                                                                                                         |
| 843 |    107.791017 |    490.850812 | Matt Martyniuk                                                                                                                                                                       |
| 844 |    230.889027 |    149.369117 | NA                                                                                                                                                                                   |
| 845 |    835.406693 |    373.489145 | Alex Slavenko                                                                                                                                                                        |
| 846 |     20.739587 |    734.410799 | Noah Schlottman, photo from Casey Dunn                                                                                                                                               |
| 847 |     11.409906 |      7.723715 | Jaime Headden                                                                                                                                                                        |
| 848 |    759.775890 |     93.922147 | Christopher Chávez                                                                                                                                                                   |
| 849 |    879.051592 |    307.330944 | M Kolmann                                                                                                                                                                            |
| 850 |    232.190440 |    376.876673 | Collin Gross                                                                                                                                                                         |
| 851 |    716.306377 |    262.099120 | T. Michael Keesey                                                                                                                                                                    |
| 852 |    276.645644 |     20.516543 | Zimices                                                                                                                                                                              |
| 853 |    591.195042 |    625.689073 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 854 |    157.873926 |    238.378604 | NA                                                                                                                                                                                   |
| 855 |    888.214435 |    403.804843 | Margot Michaud                                                                                                                                                                       |
| 856 |    241.491146 |     98.887990 | Margot Michaud                                                                                                                                                                       |
| 857 |    777.123292 |    694.864160 | Lauren Sumner-Rooney                                                                                                                                                                 |
| 858 |    353.526671 |    607.979604 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                                      |
| 859 |     71.638915 |    787.893483 | NA                                                                                                                                                                                   |
| 860 |    845.913962 |    768.978108 | T. Michael Keesey (vectorization); Thorsten Assmann, Jörn Buse, Claudia Drees, Ariel-Leib-Leonid Friedman, Tal Levanony, Andrea Matern, Anika Timm, and David W. Wrase (photography) |
| 861 |    230.036633 |    400.657632 | Rachel Shoop                                                                                                                                                                         |
| 862 |    562.075221 |    786.659291 | Abraão Leite                                                                                                                                                                         |
| 863 |     21.695065 |    133.028096 | Dean Schnabel                                                                                                                                                                        |
| 864 |    614.910573 |    604.721309 | Chris huh                                                                                                                                                                            |
| 865 |    849.273828 |     89.779602 | Gareth Monger                                                                                                                                                                        |
| 866 |    688.543990 |    461.258130 | Zimices                                                                                                                                                                              |
| 867 |    554.093526 |    762.355806 | Margot Michaud                                                                                                                                                                       |
| 868 |    272.592045 |    569.555617 | Kai R. Caspar                                                                                                                                                                        |
| 869 |    835.366504 |    684.727062 | Collin Gross                                                                                                                                                                         |
| 870 |    115.377518 |    754.684782 | Shyamal                                                                                                                                                                              |
| 871 |     71.438199 |    446.119510 | CNZdenek                                                                                                                                                                             |
| 872 |    176.424067 |    708.773131 | Frank Förster (based on a picture by Hans Hillewaert)                                                                                                                                |
| 873 |    721.280375 |    416.320754 | Steven Traver                                                                                                                                                                        |
| 874 |    134.540973 |    665.038439 | Matt Crook                                                                                                                                                                           |
| 875 |    728.514551 |    789.899117 | V. Deepak                                                                                                                                                                            |
| 876 |    790.986544 |    786.423772 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                                |
| 877 |     48.649430 |     38.281807 | Ghedoghedo                                                                                                                                                                           |
| 878 |    155.014031 |    332.970345 | T. Michael Keesey                                                                                                                                                                    |
| 879 |    856.190695 |    713.580260 | Noah Schlottman, photo from Casey Dunn                                                                                                                                               |
| 880 |    580.427691 |    379.151717 | NA                                                                                                                                                                                   |
| 881 |    642.140711 |     68.754418 | Mathew Wedel                                                                                                                                                                         |
| 882 |    139.732500 |    693.425576 | Gareth Monger                                                                                                                                                                        |
| 883 |    148.827245 |    605.613052 | Ferran Sayol                                                                                                                                                                         |
| 884 |    455.456015 |    631.415650 | Steven Traver                                                                                                                                                                        |
| 885 |    163.533299 |    491.773011 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 886 |   1012.523884 |    315.046704 | Chris huh                                                                                                                                                                            |
| 887 |   1013.025040 |    692.606928 | Ferran Sayol                                                                                                                                                                         |
| 888 |    383.691140 |    246.329808 | Andrew A. Farke                                                                                                                                                                      |
| 889 |    539.705778 |    263.190930 | Nobu Tamura                                                                                                                                                                          |
| 890 |    566.539587 |    219.067625 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 891 |    302.115540 |    759.571940 | Becky Barnes                                                                                                                                                                         |
| 892 |    131.336903 |    752.712138 | Wynston Cooper (photo) and Albertonykus (silhouette)                                                                                                                                 |
| 893 |    299.299572 |    723.300964 | Xavier Giroux-Bougard                                                                                                                                                                |
| 894 |    532.259365 |    457.811313 | Ludwik Gasiorowski                                                                                                                                                                   |
| 895 |    792.552003 |    517.364771 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 896 |    583.109139 |    203.404937 | Birgit Lang                                                                                                                                                                          |
| 897 |    551.971918 |    544.028259 | Sharon Wegner-Larsen                                                                                                                                                                 |
| 898 |    426.144079 |    736.318630 | Ferran Sayol                                                                                                                                                                         |
| 899 |    241.658466 |    674.246525 | Gareth Monger                                                                                                                                                                        |
| 900 |    160.911767 |    765.719270 | Matt Crook                                                                                                                                                                           |
| 901 |    923.670064 |    237.728549 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                                  |
| 902 |    647.742949 |    247.799715 | Matt Crook                                                                                                                                                                           |
| 903 |    519.112271 |    429.992201 | T. Michael Keesey                                                                                                                                                                    |
| 904 |    748.187394 |    734.563378 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                                   |
| 905 |    393.958716 |    322.919531 | Scott Hartman                                                                                                                                                                        |
| 906 |    156.293070 |    631.831765 | Javiera Constanzo                                                                                                                                                                    |
| 907 |   1015.076515 |    773.275775 | Noah Schlottman, photo by Reinhard Jahn                                                                                                                                              |
| 908 |    428.202903 |    471.790392 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 909 |    867.649622 |    599.936526 | Alex Slavenko                                                                                                                                                                        |
| 910 |     61.579253 |    632.003334 | Ferran Sayol                                                                                                                                                                         |
| 911 |    964.703765 |    773.705916 | Scott Hartman                                                                                                                                                                        |
| 912 |    898.367892 |    662.954951 | Andrew A. Farke                                                                                                                                                                      |
| 913 |    944.651882 |    145.391885 | Kai R. Caspar                                                                                                                                                                        |
| 914 |    620.499091 |    590.113013 | Matt Crook                                                                                                                                                                           |
| 915 |    336.757169 |     17.072401 | Ferran Sayol                                                                                                                                                                         |
| 916 |   1014.085382 |    228.734124 | wsnaccad                                                                                                                                                                             |
| 917 |    594.489565 |    141.696591 | Prathyush Thomas                                                                                                                                                                     |
| 918 |    478.072962 |    469.716906 | Armin Reindl                                                                                                                                                                         |
| 919 |    407.901065 |     90.581206 | Steven Traver                                                                                                                                                                        |
| 920 |    835.673347 |    700.627972 | Pedro de Siracusa                                                                                                                                                                    |
| 921 |    998.279018 |    362.193154 | Anilocra (vectorization by Yan Wong)                                                                                                                                                 |
| 922 |    951.194438 |    490.811560 | Scott Hartman                                                                                                                                                                        |
| 923 |    680.504961 |    788.508890 | Michelle Site                                                                                                                                                                        |
| 924 |    845.371344 |    348.658421 | Zimices                                                                                                                                                                              |
| 925 |     10.754809 |    203.252532 | FunkMonk (Michael B. H.)                                                                                                                                                             |
| 926 |    474.275046 |    764.615287 | Michelle Site                                                                                                                                                                        |
| 927 |    714.479989 |    309.555586 | Cathy                                                                                                                                                                                |
| 928 |    967.661796 |    415.428719 | John Curtis (vectorized by T. Michael Keesey)                                                                                                                                        |
| 929 |    714.645669 |    421.613857 | Kai R. Caspar                                                                                                                                                                        |
| 930 |    440.430262 |    307.884502 | Michelle Site                                                                                                                                                                        |
| 931 |    955.322479 |    263.005199 | Maija Karala                                                                                                                                                                         |
| 932 |    429.324548 |    312.788489 | Ferran Sayol                                                                                                                                                                         |
| 933 |    629.866158 |    194.543997 | Birgit Lang                                                                                                                                                                          |
| 934 |     90.178316 |    547.388103 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 935 |      8.154767 |     98.095504 | Matt Crook                                                                                                                                                                           |
| 936 |    130.206560 |    414.398550 | Margot Michaud                                                                                                                                                                       |

    #> Your tweet has been posted!
