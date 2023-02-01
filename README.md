
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

Steven Traver, Tasman Dixon, Jack Mayer Wood, Andrew R. Gehrke, Yan
Wong, Ignacio Contreras, Markus A. Grohme, T. Michael Keesey, Mette
Aumala, Enoch Joseph Wetsy (photo), John E. McCormack, Michael G.
Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb
T. Brumfield & T. Michael Keesey, E. J. Van Nieukerken, A. Laštůvka, and
Z. Laštůvka (vectorized by T. Michael Keesey), Scott Hartman, Javier
Luque, Alexander Schmidt-Lebuhn, Roberto Díaz Sibaja, Zimices, Christoph
Schomburg, Chris huh, Jagged Fang Designs, Mathew Wedel, Gareth Monger,
Michelle Site, Matt Crook, Kelly, NASA, Chuanixn Yu, Jan A. Venter,
Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T.
Michael Keesey), Trond R. Oskars, Frank Förster (based on a picture by
Hans Hillewaert), Sarah Werning, Hugo Gruson, Cristian Osorio & Paula
Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org),
FJDegrange, Elisabeth Östman, Andy Wilson, Gabriela Palomo-Munoz, Armin
Reindl, Robert Gay, modifed from Olegivvit, Diego Fontaneto, Elisabeth
A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia
Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey),
Mathilde Cordellier, Dmitry Bogdanov, Ferran Sayol, Robert Gay, Nobu
Tamura, modified by Andrew A. Farke, Cesar Julian, Beth Reinke, Agnello
Picorelli, Birgit Lang, Andreas Hejnol, John Gould (vectorized by T.
Michael Keesey), Jose Carlos Arenas-Monroy, Melissa Broussard, Karl
Ragnar Gjertsen (vectorized by T. Michael Keesey), Maha Ghazal, Tyler
Greenfield, Dmitry Bogdanov (vectorized by T. Michael Keesey), Javiera
Constanzo, Mark Miller, Emily Willoughby, Mo Hassan, Tony Ayling
(vectorized by T. Michael Keesey), Sam Droege (photo) and T. Michael
Keesey (vectorization), Margot Michaud, Maxime Dahirel, terngirl,
Mathieu Basille, Nicholas J. Czaplewski, vectorized by Zimices, Joanna
Wolfe, T. Michael Keesey (vectorization); Yves Bousquet (photography),
Ghedoghedo (vectorized by T. Michael Keesey), Scarlet23 (vectorized by
T. Michael Keesey), Obsidian Soul (vectorized by T. Michael Keesey),
Rafael Maia, Sidney Frederic Harmer, Arthur Everett Shipley (vectorized
by Maxime Dahirel), Joschua Knüppe, C. Camilo Julián-Caballero, Martin
R. Smith, after Skovsted et al 2015, Jaime Headden, Milton Tan, Tracy A.
Heath, Leann Biancani, photo by Kenneth Clifton, Jimmy Bernot, Marie
Russell, Smokeybjb (vectorized by T. Michael Keesey), Pete Buchholz,
Mason McNair, Caleb M. Brown, Harold N Eyster, Kenneth Lacovara
(vectorized by T. Michael Keesey), Michael P. Taylor, Juan Carlos Jerí,
Alexandre Vong, T. Michael Keesey (from a mount by Allis Markham),
Melissa Ingala, Steven Coombs, Yan Wong from photo by Denes Emoke,
SecretJellyMan, Kamil S. Jaron, Julio Garza, Terpsichores, Kanako
Bessho-Uehara, Erika Schumacher, Maija Karala, Rebecca Groom, Skye
McDavid, Joedison Rocha, Estelle Bourdon, Warren H (photography), T.
Michael Keesey (vectorization), Joseph Smit (modified by T. Michael
Keesey), Kimberly Haddrell, T. Michael Keesey (vectorization) and Tony
Hisgett (photography), Matt Martyniuk, Lani Mohan, Katie S. Collins,
nicubunu, xgirouxb, Nobu Tamura (vectorized by T. Michael Keesey), T.
Michael Keesey (after Tillyard), Smokeybjb (modified by T. Michael
Keesey), Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Todd Marshall, vectorized by Zimices, John Curtis
(vectorized by T. Michael Keesey), Doug Backlund (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Meliponicultor
Itaymbere, Remes K, Ortega F, Fierro I, Joger U, Kosma R, et al., Dean
Schnabel, Scott Hartman (vectorized by William Gearty), Thibaut Brunet,
Jake Warner, Giant Blue Anteater (vectorized by T. Michael Keesey), Emil
Schmidt (vectorized by Maxime Dahirel), Philippe Janvier (vectorized by
T. Michael Keesey), Francisco Manuel Blanco (vectorized by T. Michael
Keesey), Dennis C. Murphy, after
<https://commons.wikimedia.org/wiki/File:Queensland_State_Archives_2981_Cane_toads_at_the_Meringa_Sugar_Experiment_Station_North_Queensland_c_1935.png>,
Brad McFeeters (vectorized by T. Michael Keesey), Andrew A. Farke, David
Orr, Walter Vladimir, Becky Barnes, Abraão Leite, Matthew E. Clapham,
Renata F. Martins, Scott D. Sampson, Mark A. Loewen, Andrew A. Farke,
Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus, M
Kolmann, Michael “FunkMonk” B. H. (vectorized by T. Michael Keesey),
Kanchi Nanjo, Mercedes Yrayzoz (vectorized by T. Michael Keesey), Kai R.
Caspar, Lisa M. “Pixxl” (photo), John E. McCormack, Michael G. Harvey,
Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T.
Brumfield & T. Michael Keesey, Noah Schlottman, photo by Carlos
Sánchez-Ortiz, Lukasiniho, Mathieu Pélissié, Yan Wong from photo by
Gyik Toma, S.Martini, Benjamin Monod-Broca, Mateus Zica (modified by T.
Michael Keesey), Aline M. Ghilardi, Hans Hillewaert, Benchill,
Archaeodontosaurus (vectorized by T. Michael Keesey), Mykle Hoban,
Renato de Carvalho Ferreira, Nobu Tamura, vectorized by Zimices, M. A.
Broussard, Mali’o Kodis, photograph from
<http://commons.wikimedia.org/wiki/File:Trichoplax.jpg>, Noah
Schlottman, Nobu Tamura (modified by T. Michael Keesey), Matthias
Buschmann (vectorized by T. Michael Keesey), Charles R. Knight,
vectorized by Zimices, T. Michael Keesey, from a photograph by Thea
Boodhoo, Felix Vaux, Mariana Ruiz (vectorized by T. Michael Keesey), C.
Abraczinskas, Ingo Braasch, Kevin Sánchez, T. Michael Keesey
(vectorization) and Nadiatalent (photography), Frederick William Frohawk
(vectorized by T. Michael Keesey), Apokryltaros (vectorized by T.
Michael Keesey), Verdilak, Collin Gross, DW Bapst, modified from Figure
1 of Belanger (2011, PALAIOS)., CNZdenek, Michele M Tobias, Armelle
Ansart (photograph), Maxime Dahirel (digitisation), Karla Martinez, T.
Michael Keesey (vectorization); Thorsten Assmann, Jörn Buse, Claudia
Drees, Ariel-Leib-Leonid Friedman, Tal Levanony, Andrea Matern, Anika
Timm, and David W. Wrase (photography), Sharon Wegner-Larsen, Xavier A.
Jenkins, Gabriel Ugueto, Crystal Maier, Tom Tarrant (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Josep Marti
Solans, Sebastian Stabinger, Jessica Anne Miller, Chloé Schmidt,
SecretJellyMan - from Mason McNair, Stanton F. Fink, vectorized by
Zimices, kotik, Derek Bakken (photograph) and T. Michael Keesey
(vectorization), Robbie N. Cada (vectorized by T. Michael Keesey),
Gregor Bucher, Max Farnworth, Joshua Fowler, FunkMonk, Anna Willoughby,
Darren Naish (vectorized by T. Michael Keesey), Robert Bruce Horsfall,
vectorized by Zimices, Matt Dempsey, Neil Kelley, Aviceda (vectorized by
T. Michael Keesey), Richard J. Harris, Johan Lindgren, Michael W.
Caldwell, Takuya Konishi, Luis M. Chiappe, Stemonitis (photography) and
T. Michael Keesey (vectorization), (after Spotila 2004), Matt Martyniuk
(vectorized by T. Michael Keesey), Arthur S. Brum, Andrew A. Farke,
modified from original by H. Milne Edwards, Myriam\_Ramirez, Mattia
Menchetti, Mario Quevedo, Robert Hering, Chase Brownstein, Fernando
Carezzano, Matt Wilkins, T. Michael Keesey (after A. Y. Ivantsov), Iain
Reid, Ville-Veikko Sinkkonen, Timothy Knepp of the U.S. Fish and
Wildlife Service (illustration) and Timothy J. Bartley (silhouette),
Mathew Callaghan, Martin R. Smith, Lily Hughes, John Conway, Roderic
Page and Lois Page, Lukas Panzarin (vectorized by T. Michael Keesey),
Hans Hillewaert (vectorized by T. Michael Keesey), Nobu Tamura, Tambja
(vectorized by T. Michael Keesey), Scott Reid, Dave Angelini, Lafage,
Francesco “Architetto” Rollandin, Robert Bruce Horsfall (vectorized by
T. Michael Keesey), JCGiron, Noah Schlottman, photo by Adam G. Clause,
Charles R. Knight (vectorized by T. Michael Keesey), Gordon E.
Robertson, J. J. Harrison (photo) & T. Michael Keesey, Carlos
Cano-Barbacil, Mali’o Kodis, image from the “Proceedings of the
Zoological Society of London”, Lip Kee Yap (vectorized by T. Michael
Keesey), Fritz Geller-Grimm (vectorized by T. Michael Keesey), M.
Garfield & K. Anderson (modified by T. Michael Keesey), T. Michael
Keesey (photo by Sean Mack), Tauana J. Cunha, Ieuan Jones, Yusan Yang,
Taenadoman, FunkMonk (Michael B.H.; vectorized by T. Michael Keesey), T.
Michael Keesey (after Mivart), James R. Spotila and Ray Chatterji, Ellen
Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley
(silhouette), Tony Ayling, Manabu Bessho-Uehara, T. Michael Keesey (from
a photo by Maximilian Paradiz), Nicolas Huet le Jeune and Jean-Gabriel
Prêtre (vectorized by T. Michael Keesey), Sean McCann, Notafly
(vectorized by T. Michael Keesey), I. Geoffroy Saint-Hilaire (vectorized
by T. Michael Keesey), Aadx, Mali’o Kodis, photograph by Bruno
Vellutini, Pollyanna von Knorring and T. Michael Keesey, Fcb981
(vectorized by T. Michael Keesey), Sergio A. Muñoz-Gómez, Rene Martin,
Caleb M. Gordon, Noah Schlottman, photo by Casey Dunn, Josefine Bohr
Brask, Darren Naish (vectorize by T. Michael Keesey), wsnaccad

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                               |
| --: | ------------: | ------------: | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    381.686809 |    498.504975 | Steven Traver                                                                                                                                                                        |
|   2 |    555.087992 |    123.353384 | Tasman Dixon                                                                                                                                                                         |
|   3 |    407.647555 |    299.938667 | NA                                                                                                                                                                                   |
|   4 |    784.240962 |     34.643145 | Jack Mayer Wood                                                                                                                                                                      |
|   5 |    657.869946 |    179.913764 | Andrew R. Gehrke                                                                                                                                                                     |
|   6 |     86.412634 |    347.193618 | Yan Wong                                                                                                                                                                             |
|   7 |    176.546875 |    146.565101 | Ignacio Contreras                                                                                                                                                                    |
|   8 |    389.707288 |    678.536119 | Markus A. Grohme                                                                                                                                                                     |
|   9 |    753.175781 |    392.031390 | Steven Traver                                                                                                                                                                        |
|  10 |    176.702527 |    229.318448 | T. Michael Keesey                                                                                                                                                                    |
|  11 |    682.985075 |    618.278336 | Mette Aumala                                                                                                                                                                         |
|  12 |    769.788338 |    188.427834 | Enoch Joseph Wetsy (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                   |
|  13 |    649.334742 |    505.433078 | E. J. Van Nieukerken, A. Laštůvka, and Z. Laštůvka (vectorized by T. Michael Keesey)                                                                                                 |
|  14 |    228.795733 |    433.668560 | Scott Hartman                                                                                                                                                                        |
|  15 |    758.673625 |    288.821930 | Javier Luque                                                                                                                                                                         |
|  16 |    381.846922 |    608.184138 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
|  17 |    906.945390 |    364.393018 | Roberto Díaz Sibaja                                                                                                                                                                  |
|  18 |    807.112699 |    696.426708 | Zimices                                                                                                                                                                              |
|  19 |    345.895705 |    364.489895 | Christoph Schomburg                                                                                                                                                                  |
|  20 |    923.729960 |     41.492462 | Yan Wong                                                                                                                                                                             |
|  21 |     81.244551 |    457.388860 | Chris huh                                                                                                                                                                            |
|  22 |     19.294083 |    606.374835 | T. Michael Keesey                                                                                                                                                                    |
|  23 |    520.519756 |    190.410056 | Jagged Fang Designs                                                                                                                                                                  |
|  24 |    258.608906 |    592.640190 | Zimices                                                                                                                                                                              |
|  25 |    199.721739 |    744.706017 | Mathew Wedel                                                                                                                                                                         |
|  26 |    170.585740 |    355.320090 | Gareth Monger                                                                                                                                                                        |
|  27 |    911.605649 |    622.109973 | Michelle Site                                                                                                                                                                        |
|  28 |     80.787181 |    409.314629 | Matt Crook                                                                                                                                                                           |
|  29 |    187.231285 |    656.206520 | Gareth Monger                                                                                                                                                                        |
|  30 |    487.135163 |    618.214661 | Kelly                                                                                                                                                                                |
|  31 |    154.250695 |    531.427641 | NA                                                                                                                                                                                   |
|  32 |    362.174191 |    201.973447 | Zimices                                                                                                                                                                              |
|  33 |    573.617047 |    689.019829 | NASA                                                                                                                                                                                 |
|  34 |    757.140978 |    103.785669 | Chuanixn Yu                                                                                                                                                                          |
|  35 |    887.801019 |    221.522895 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                                  |
|  36 |    608.066298 |    265.507582 | Trond R. Oskars                                                                                                                                                                      |
|  37 |    350.084170 |     95.052262 | Frank Förster (based on a picture by Hans Hillewaert)                                                                                                                                |
|  38 |    142.627235 |    623.734116 | Sarah Werning                                                                                                                                                                        |
|  39 |    580.659820 |    405.473333 | Matt Crook                                                                                                                                                                           |
|  40 |     94.077216 |    699.739157 | Hugo Gruson                                                                                                                                                                          |
|  41 |    967.823998 |    684.159802 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
|  42 |    408.222574 |    731.170647 | Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org)                                                                                         |
|  43 |    958.619985 |    168.958168 | FJDegrange                                                                                                                                                                           |
|  44 |    527.513063 |    503.603816 | Elisabeth Östman                                                                                                                                                                     |
|  45 |    614.327146 |     65.151282 | Jagged Fang Designs                                                                                                                                                                  |
|  46 |    471.068133 |    401.731046 | Andy Wilson                                                                                                                                                                          |
|  47 |    691.109474 |    691.135427 | Sarah Werning                                                                                                                                                                        |
|  48 |    251.850989 |    382.879627 | Gabriela Palomo-Munoz                                                                                                                                                                |
|  49 |    875.906898 |    483.629849 | Michelle Site                                                                                                                                                                        |
|  50 |    793.503613 |    474.583990 | Armin Reindl                                                                                                                                                                         |
|  51 |    325.376911 |     26.928778 | Markus A. Grohme                                                                                                                                                                     |
|  52 |    500.245337 |    253.369843 | NA                                                                                                                                                                                   |
|  53 |    114.635341 |    262.908436 | Zimices                                                                                                                                                                              |
|  54 |    433.503905 |     74.301891 | Robert Gay, modifed from Olegivvit                                                                                                                                                   |
|  55 |    770.230933 |    775.561828 | Markus A. Grohme                                                                                                                                                                     |
|  56 |     31.062886 |     74.099040 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey)                |
|  57 |    980.954382 |    562.839864 | Mathilde Cordellier                                                                                                                                                                  |
|  58 |    128.853145 |     36.863460 | Dmitry Bogdanov                                                                                                                                                                      |
|  59 |    260.063211 |    229.112615 | NA                                                                                                                                                                                   |
|  60 |    260.538554 |    698.374634 | Ferran Sayol                                                                                                                                                                         |
|  61 |    858.923675 |    151.454569 | Andy Wilson                                                                                                                                                                          |
|  62 |    238.569331 |     92.442033 | Sarah Werning                                                                                                                                                                        |
|  63 |    927.294902 |    302.303883 | Robert Gay                                                                                                                                                                           |
|  64 |     66.131888 |    308.855923 | Nobu Tamura, modified by Andrew A. Farke                                                                                                                                             |
|  65 |    255.405123 |    528.608843 | Christoph Schomburg                                                                                                                                                                  |
|  66 |    757.426591 |    518.022578 | Zimices                                                                                                                                                                              |
|  67 |    527.132554 |    764.647450 | Cesar Julian                                                                                                                                                                         |
|  68 |    840.095479 |     81.813920 | Beth Reinke                                                                                                                                                                          |
|  69 |    448.516053 |    611.058223 | NA                                                                                                                                                                                   |
|  70 |     65.498399 |    124.215488 | Agnello Picorelli                                                                                                                                                                    |
|  71 |    247.854410 |    303.944960 | Yan Wong                                                                                                                                                                             |
|  72 |     86.470563 |    781.602804 | Markus A. Grohme                                                                                                                                                                     |
|  73 |    534.464548 |    345.982606 | Birgit Lang                                                                                                                                                                          |
|  74 |    376.748991 |    401.717587 | Scott Hartman                                                                                                                                                                        |
|  75 |    849.106413 |    597.675244 | Andreas Hejnol                                                                                                                                                                       |
|  76 |    119.005655 |    570.178713 | Jagged Fang Designs                                                                                                                                                                  |
|  77 |    440.297861 |    211.507228 | NA                                                                                                                                                                                   |
|  78 |    586.045808 |     25.371643 | Ignacio Contreras                                                                                                                                                                    |
|  79 |    625.129391 |    562.546117 | NA                                                                                                                                                                                   |
|  80 |    816.632039 |    258.180522 | John Gould (vectorized by T. Michael Keesey)                                                                                                                                         |
|  81 |    955.188246 |     79.859954 | Jose Carlos Arenas-Monroy                                                                                                                                                            |
|  82 |    790.820790 |    612.892785 | Markus A. Grohme                                                                                                                                                                     |
|  83 |    509.840774 |    713.179125 | NA                                                                                                                                                                                   |
|  84 |    774.655014 |    742.262720 | Melissa Broussard                                                                                                                                                                    |
|  85 |    974.904488 |    771.755823 | Karl Ragnar Gjertsen (vectorized by T. Michael Keesey)                                                                                                                               |
|  86 |    115.268187 |    416.236937 | Maha Ghazal                                                                                                                                                                          |
|  87 |    690.131312 |    210.498694 | Chris huh                                                                                                                                                                            |
|  88 |    685.360925 |     22.244276 | Tyler Greenfield                                                                                                                                                                     |
|  89 |    522.641339 |    415.160544 | NA                                                                                                                                                                                   |
|  90 |    506.003442 |     41.517996 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
|  91 |    333.045117 |    781.684359 | Javiera Constanzo                                                                                                                                                                    |
|  92 |    707.221882 |     89.436895 | Steven Traver                                                                                                                                                                        |
|  93 |    714.777804 |    235.574854 | NA                                                                                                                                                                                   |
|  94 |    630.685214 |    166.916357 | Mark Miller                                                                                                                                                                          |
|  95 |    714.630985 |    627.134889 | Yan Wong                                                                                                                                                                             |
|  96 |    509.709892 |     13.045516 | Mette Aumala                                                                                                                                                                         |
|  97 |    312.451716 |    687.700444 | Emily Willoughby                                                                                                                                                                     |
|  98 |    838.460131 |    670.511084 | Mo Hassan                                                                                                                                                                            |
|  99 |    278.008214 |    422.299648 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                                        |
| 100 |    972.700966 |    440.930401 | Sam Droege (photo) and T. Michael Keesey (vectorization)                                                                                                                             |
| 101 |    475.433647 |    747.066005 | Margot Michaud                                                                                                                                                                       |
| 102 |    682.601461 |    545.433007 | NA                                                                                                                                                                                   |
| 103 |   1001.522973 |    739.064907 | Scott Hartman                                                                                                                                                                        |
| 104 |    572.038311 |    219.872208 | Chris huh                                                                                                                                                                            |
| 105 |     16.954140 |    409.698930 | Maxime Dahirel                                                                                                                                                                       |
| 106 |    766.877541 |    380.066717 | Gareth Monger                                                                                                                                                                        |
| 107 |     28.908458 |    762.838984 | terngirl                                                                                                                                                                             |
| 108 |    371.819576 |    624.888203 | Zimices                                                                                                                                                                              |
| 109 |    434.121492 |    439.833425 | Margot Michaud                                                                                                                                                                       |
| 110 |    502.514203 |    108.359285 | Markus A. Grohme                                                                                                                                                                     |
| 111 |    739.291551 |    486.343539 | Mathieu Basille                                                                                                                                                                      |
| 112 |    864.780544 |    401.350885 | Nicholas J. Czaplewski, vectorized by Zimices                                                                                                                                        |
| 113 |    413.388768 |    264.190816 | Joanna Wolfe                                                                                                                                                                         |
| 114 |    194.939197 |    716.617899 | T. Michael Keesey (vectorization); Yves Bousquet (photography)                                                                                                                       |
| 115 |    563.628714 |    492.449949 | Birgit Lang                                                                                                                                                                          |
| 116 |    540.815181 |    306.356301 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                                         |
| 117 |    230.204609 |    234.701345 | Scott Hartman                                                                                                                                                                        |
| 118 |     75.723837 |    640.248311 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                                                          |
| 119 |    216.298179 |    625.715739 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                                      |
| 120 |    365.676527 |     90.372504 | Rafael Maia                                                                                                                                                                          |
| 121 |    303.605380 |    434.189294 | Michelle Site                                                                                                                                                                        |
| 122 |    733.527686 |    158.302329 | T. Michael Keesey                                                                                                                                                                    |
| 123 |    323.966740 |    624.893553 | Sidney Frederic Harmer, Arthur Everett Shipley (vectorized by Maxime Dahirel)                                                                                                        |
| 124 |    633.792489 |    659.747555 | Joschua Knüppe                                                                                                                                                                       |
| 125 |    950.333398 |    384.546040 | Gareth Monger                                                                                                                                                                        |
| 126 |     24.579245 |    517.592863 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 127 |    385.831776 |    760.602123 | Martin R. Smith, after Skovsted et al 2015                                                                                                                                           |
| 128 |    999.347431 |    235.730790 | Armin Reindl                                                                                                                                                                         |
| 129 |    997.094796 |    443.561077 | Jaime Headden                                                                                                                                                                        |
| 130 |    472.177021 |    791.204415 | Yan Wong                                                                                                                                                                             |
| 131 |    556.267739 |    574.658375 | Chris huh                                                                                                                                                                            |
| 132 |    752.282836 |    193.060755 | Melissa Broussard                                                                                                                                                                    |
| 133 |    306.339365 |    335.613886 | Milton Tan                                                                                                                                                                           |
| 134 |    399.754268 |    251.012549 | Tracy A. Heath                                                                                                                                                                       |
| 135 |     68.517700 |    268.856310 | Jagged Fang Designs                                                                                                                                                                  |
| 136 |    380.579572 |    561.960069 | Matt Crook                                                                                                                                                                           |
| 137 |    770.989246 |    342.910219 | NA                                                                                                                                                                                   |
| 138 |    101.539815 |    208.877906 | Leann Biancani, photo by Kenneth Clifton                                                                                                                                             |
| 139 |    168.770568 |    459.028855 | Matt Crook                                                                                                                                                                           |
| 140 |     69.538873 |     22.796758 | Markus A. Grohme                                                                                                                                                                     |
| 141 |    590.083416 |    461.356839 | Steven Traver                                                                                                                                                                        |
| 142 |    230.470840 |    548.517426 | Jimmy Bernot                                                                                                                                                                         |
| 143 |    724.242643 |    151.233407 | Marie Russell                                                                                                                                                                        |
| 144 |     74.816009 |    111.435272 | T. Michael Keesey                                                                                                                                                                    |
| 145 |    971.194593 |    337.912051 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                                          |
| 146 |    314.608391 |    404.508980 | Pete Buchholz                                                                                                                                                                        |
| 147 |     11.228648 |    274.084211 | Mason McNair                                                                                                                                                                         |
| 148 |     73.711190 |    221.862683 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 149 |    223.111248 |    473.833753 | NA                                                                                                                                                                                   |
| 150 |    764.652300 |    457.760615 | NA                                                                                                                                                                                   |
| 151 |    398.734266 |    630.686614 | Ferran Sayol                                                                                                                                                                         |
| 152 |   1007.352367 |    173.977269 | Margot Michaud                                                                                                                                                                       |
| 153 |    906.421246 |    503.292320 | Ferran Sayol                                                                                                                                                                         |
| 154 |    255.443997 |     43.073671 | Caleb M. Brown                                                                                                                                                                       |
| 155 |    903.997326 |    178.252478 | Scott Hartman                                                                                                                                                                        |
| 156 |     96.326296 |    763.201951 | Scott Hartman                                                                                                                                                                        |
| 157 |    664.073025 |    762.903462 | Harold N Eyster                                                                                                                                                                      |
| 158 |    605.569987 |    635.010517 | Kenneth Lacovara (vectorized by T. Michael Keesey)                                                                                                                                   |
| 159 |    182.857787 |    212.110893 | Zimices                                                                                                                                                                              |
| 160 |    182.276891 |    256.384531 | Ferran Sayol                                                                                                                                                                         |
| 161 |    466.033423 |    229.219894 | Michael P. Taylor                                                                                                                                                                    |
| 162 |    891.735519 |    658.508604 | Juan Carlos Jerí                                                                                                                                                                     |
| 163 |    644.062922 |    450.539075 | Alexandre Vong                                                                                                                                                                       |
| 164 |    696.658922 |    161.898577 | Milton Tan                                                                                                                                                                           |
| 165 |    391.353473 |    328.973435 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 166 |    649.186875 |    400.086344 | T. Michael Keesey (from a mount by Allis Markham)                                                                                                                                    |
| 167 |    406.867459 |    781.596148 | Melissa Ingala                                                                                                                                                                       |
| 168 |    464.411993 |     76.543712 | NA                                                                                                                                                                                   |
| 169 |    180.952569 |    440.861700 | Jimmy Bernot                                                                                                                                                                         |
| 170 |    242.833528 |    103.053092 | Jack Mayer Wood                                                                                                                                                                      |
| 171 |     25.434747 |    172.261297 | Markus A. Grohme                                                                                                                                                                     |
| 172 |    919.989394 |    468.090401 | Matt Crook                                                                                                                                                                           |
| 173 |    315.807136 |    249.683803 | Harold N Eyster                                                                                                                                                                      |
| 174 |    368.247415 |    425.935410 | NA                                                                                                                                                                                   |
| 175 |     42.567922 |    617.326351 | Sidney Frederic Harmer, Arthur Everett Shipley (vectorized by Maxime Dahirel)                                                                                                        |
| 176 |    242.891399 |    448.227810 | Tracy A. Heath                                                                                                                                                                       |
| 177 |    248.787669 |    121.881494 | Margot Michaud                                                                                                                                                                       |
| 178 |    395.294805 |    647.773143 | Steven Coombs                                                                                                                                                                        |
| 179 |     61.009430 |     43.314362 | NA                                                                                                                                                                                   |
| 180 |     61.583737 |    617.466818 | Ignacio Contreras                                                                                                                                                                    |
| 181 |    799.058621 |      8.295679 | Yan Wong from photo by Denes Emoke                                                                                                                                                   |
| 182 |    206.944513 |    106.033287 | T. Michael Keesey                                                                                                                                                                    |
| 183 |    920.830323 |    390.865464 | NA                                                                                                                                                                                   |
| 184 |    288.213908 |     40.620557 | Matt Crook                                                                                                                                                                           |
| 185 |     18.006506 |    107.938881 | Andy Wilson                                                                                                                                                                          |
| 186 |    282.095617 |    173.812132 | SecretJellyMan                                                                                                                                                                       |
| 187 |    269.675257 |    760.561947 | Kamil S. Jaron                                                                                                                                                                       |
| 188 |    151.624842 |    419.553575 | Margot Michaud                                                                                                                                                                       |
| 189 |     25.045012 |    708.686280 | Markus A. Grohme                                                                                                                                                                     |
| 190 |    337.190346 |    267.999218 | NA                                                                                                                                                                                   |
| 191 |    152.874648 |    773.482944 | Zimices                                                                                                                                                                              |
| 192 |    567.164711 |    282.778257 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 193 |     58.303884 |    556.890238 | Matt Crook                                                                                                                                                                           |
| 194 |   1006.337130 |    641.920313 | Jagged Fang Designs                                                                                                                                                                  |
| 195 |    568.527257 |    155.238673 | Matt Crook                                                                                                                                                                           |
| 196 |   1008.002573 |    114.973392 | Scott Hartman                                                                                                                                                                        |
| 197 |    494.968780 |    157.178660 | Ferran Sayol                                                                                                                                                                         |
| 198 |    182.324283 |    475.714196 | NA                                                                                                                                                                                   |
| 199 |     39.962326 |    408.046847 | Zimices                                                                                                                                                                              |
| 200 |    991.956852 |    471.155874 | Ferran Sayol                                                                                                                                                                         |
| 201 |   1008.508620 |    150.793519 | Scott Hartman                                                                                                                                                                        |
| 202 |    396.815583 |    153.754639 | Julio Garza                                                                                                                                                                          |
| 203 |    317.077096 |    509.757270 | Gareth Monger                                                                                                                                                                        |
| 204 |    928.727565 |    764.924165 | Terpsichores                                                                                                                                                                         |
| 205 |    719.096573 |    136.648595 | Margot Michaud                                                                                                                                                                       |
| 206 |    136.964649 |    303.540001 | Scott Hartman                                                                                                                                                                        |
| 207 |    774.797097 |     63.821490 | Matt Crook                                                                                                                                                                           |
| 208 |    694.490030 |    134.974561 | Kanako Bessho-Uehara                                                                                                                                                                 |
| 209 |    408.841083 |    431.890653 | Beth Reinke                                                                                                                                                                          |
| 210 |    394.201137 |    706.508215 | Matt Crook                                                                                                                                                                           |
| 211 |     29.625329 |    692.479546 | Margot Michaud                                                                                                                                                                       |
| 212 |    553.432991 |    569.858933 | Chris huh                                                                                                                                                                            |
| 213 |     51.280185 |    379.176345 | NA                                                                                                                                                                                   |
| 214 |    522.666598 |    568.554772 | Margot Michaud                                                                                                                                                                       |
| 215 |    991.821409 |    290.494319 | Erika Schumacher                                                                                                                                                                     |
| 216 |    439.702539 |    771.566068 | Birgit Lang                                                                                                                                                                          |
| 217 |    995.076299 |    275.684723 | Emily Willoughby                                                                                                                                                                     |
| 218 |    100.098720 |    524.077017 | Margot Michaud                                                                                                                                                                       |
| 219 |    624.185025 |    421.309458 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 220 |    751.643304 |    565.102919 | Matt Crook                                                                                                                                                                           |
| 221 |    140.091354 |    600.680531 | Maija Karala                                                                                                                                                                         |
| 222 |    648.593339 |    739.464074 | Rebecca Groom                                                                                                                                                                        |
| 223 |    513.947857 |     61.335859 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 224 |     33.393446 |    291.638171 | Margot Michaud                                                                                                                                                                       |
| 225 |    782.021655 |    229.282593 | Skye McDavid                                                                                                                                                                         |
| 226 |    141.321103 |    740.697484 | Ferran Sayol                                                                                                                                                                         |
| 227 |    585.737516 |    531.907515 | Margot Michaud                                                                                                                                                                       |
| 228 |    325.325553 |     97.231714 | Matt Crook                                                                                                                                                                           |
| 229 |    512.025160 |    555.504819 | Jaime Headden                                                                                                                                                                        |
| 230 |    411.968571 |     75.049621 | Joedison Rocha                                                                                                                                                                       |
| 231 |    223.376823 |     38.540477 | Estelle Bourdon                                                                                                                                                                      |
| 232 |    883.488875 |    674.749917 | Warren H (photography), T. Michael Keesey (vectorization)                                                                                                                            |
| 233 |    928.237056 |    778.589882 | NA                                                                                                                                                                                   |
| 234 |    255.655917 |    439.709833 | Steven Coombs                                                                                                                                                                        |
| 235 |    602.638368 |    735.240713 | T. Michael Keesey                                                                                                                                                                    |
| 236 |    259.431894 |    494.130471 | NA                                                                                                                                                                                   |
| 237 |     18.441754 |    382.075729 | Joseph Smit (modified by T. Michael Keesey)                                                                                                                                          |
| 238 |    520.254866 |    381.294063 | Kimberly Haddrell                                                                                                                                                                    |
| 239 |    918.405363 |    704.296629 | Matt Crook                                                                                                                                                                           |
| 240 |    686.659773 |    467.437475 | NA                                                                                                                                                                                   |
| 241 |    548.547787 |    371.251035 | Zimices                                                                                                                                                                              |
| 242 |    406.141967 |    532.795603 | Matt Crook                                                                                                                                                                           |
| 243 |    674.076249 |    285.270014 | T. Michael Keesey (vectorization) and Tony Hisgett (photography)                                                                                                                     |
| 244 |    672.911179 |    295.306762 | Steven Traver                                                                                                                                                                        |
| 245 |    223.302711 |    742.044823 | Gareth Monger                                                                                                                                                                        |
| 246 |    942.471590 |    195.943048 | T. Michael Keesey                                                                                                                                                                    |
| 247 |    761.654646 |    220.312148 | Steven Traver                                                                                                                                                                        |
| 248 |    838.839923 |     40.348728 | Matt Martyniuk                                                                                                                                                                       |
| 249 |    221.778124 |    642.268967 | Lani Mohan                                                                                                                                                                           |
| 250 |    724.571403 |    345.303206 | Chris huh                                                                                                                                                                            |
| 251 |    972.178052 |    273.226953 | Harold N Eyster                                                                                                                                                                      |
| 252 |    752.936165 |    624.104449 | Margot Michaud                                                                                                                                                                       |
| 253 |    363.677325 |    141.701547 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 254 |    732.481220 |    467.785490 | Jagged Fang Designs                                                                                                                                                                  |
| 255 |    512.902923 |    395.841610 | Scott Hartman                                                                                                                                                                        |
| 256 |    694.179176 |    753.376436 | Margot Michaud                                                                                                                                                                       |
| 257 |    986.632034 |     27.142044 | T. Michael Keesey                                                                                                                                                                    |
| 258 |    630.177730 |    679.416029 | Katie S. Collins                                                                                                                                                                     |
| 259 |    382.803083 |    779.590238 | Pete Buchholz                                                                                                                                                                        |
| 260 |    176.646096 |    526.780067 | Ignacio Contreras                                                                                                                                                                    |
| 261 |    581.667170 |    183.296123 | Chris huh                                                                                                                                                                            |
| 262 |    299.530110 |    766.192623 | Andy Wilson                                                                                                                                                                          |
| 263 |    352.630906 |    110.283157 | nicubunu                                                                                                                                                                             |
| 264 |    307.645806 |    582.324002 | Kimberly Haddrell                                                                                                                                                                    |
| 265 |     24.340651 |    183.716596 | xgirouxb                                                                                                                                                                             |
| 266 |    306.921950 |    543.910848 | Matt Crook                                                                                                                                                                           |
| 267 |    464.175059 |    569.692448 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 268 |     45.536552 |    339.483513 | NA                                                                                                                                                                                   |
| 269 |    613.993165 |    443.750327 | Matt Crook                                                                                                                                                                           |
| 270 |   1009.245862 |    128.272235 | T. Michael Keesey (after Tillyard)                                                                                                                                                   |
| 271 |    127.933320 |    484.905554 | Lani Mohan                                                                                                                                                                           |
| 272 |    278.938776 |    547.715535 | xgirouxb                                                                                                                                                                             |
| 273 |    598.825597 |    177.082349 | Smokeybjb (modified by T. Michael Keesey)                                                                                                                                            |
| 274 |     51.267280 |    115.959681 | Ferran Sayol                                                                                                                                                                         |
| 275 |    375.899894 |    148.236711 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                              |
| 276 |    580.014563 |    346.104704 | Margot Michaud                                                                                                                                                                       |
| 277 |    564.315397 |    234.306957 | Zimices                                                                                                                                                                              |
| 278 |    821.755909 |    331.781559 | Tasman Dixon                                                                                                                                                                         |
| 279 |    306.262063 |    134.907427 | NA                                                                                                                                                                                   |
| 280 |    706.995302 |    189.508981 | Gareth Monger                                                                                                                                                                        |
| 281 |    875.631272 |    184.772403 | Todd Marshall, vectorized by Zimices                                                                                                                                                 |
| 282 |    202.279800 |     92.539072 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 283 |    165.601112 |    703.352020 | Birgit Lang                                                                                                                                                                          |
| 284 |    317.555757 |    394.666246 | John Curtis (vectorized by T. Michael Keesey)                                                                                                                                        |
| 285 |    152.147765 |     60.645700 | Markus A. Grohme                                                                                                                                                                     |
| 286 |   1011.421666 |     55.405753 | Doug Backlund (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                        |
| 287 |    425.861678 |    230.233508 | Meliponicultor Itaymbere                                                                                                                                                             |
| 288 |    913.665045 |    496.307039 | Margot Michaud                                                                                                                                                                       |
| 289 |    294.452695 |    589.473343 | Steven Traver                                                                                                                                                                        |
| 290 |    325.322880 |     58.027480 | Margot Michaud                                                                                                                                                                       |
| 291 |     19.774800 |    684.034701 | Scott Hartman                                                                                                                                                                        |
| 292 |    916.837087 |    133.723410 | Remes K, Ortega F, Fierro I, Joger U, Kosma R, et al.                                                                                                                                |
| 293 |    695.510960 |    786.089554 | Dean Schnabel                                                                                                                                                                        |
| 294 |    735.800404 |    332.082315 | Margot Michaud                                                                                                                                                                       |
| 295 |    404.699796 |     12.601345 | Gareth Monger                                                                                                                                                                        |
| 296 |    388.302403 |      7.962531 | Scott Hartman (vectorized by William Gearty)                                                                                                                                         |
| 297 |    357.890045 |    231.795030 | Margot Michaud                                                                                                                                                                       |
| 298 |    746.725703 |    744.135252 | Matt Crook                                                                                                                                                                           |
| 299 |    781.754268 |    362.567543 | Scott Hartman                                                                                                                                                                        |
| 300 |    315.729876 |    710.692853 | Gareth Monger                                                                                                                                                                        |
| 301 |    686.550177 |    273.983015 | NA                                                                                                                                                                                   |
| 302 |    464.678670 |     93.633613 | Zimices                                                                                                                                                                              |
| 303 |     91.074543 |      4.045008 | Gareth Monger                                                                                                                                                                        |
| 304 |    375.135777 |    244.454022 | Birgit Lang                                                                                                                                                                          |
| 305 |     48.762001 |    348.938745 | Jack Mayer Wood                                                                                                                                                                      |
| 306 |     35.047643 |    325.829496 | Thibaut Brunet                                                                                                                                                                       |
| 307 |    661.199381 |    696.833091 | Andy Wilson                                                                                                                                                                          |
| 308 |    883.699970 |    321.868074 | Jake Warner                                                                                                                                                                          |
| 309 |    945.318096 |    496.539230 | Zimices                                                                                                                                                                              |
| 310 |    976.594695 |    300.991849 | Ignacio Contreras                                                                                                                                                                    |
| 311 |    495.831272 |    727.663674 | Scott Hartman                                                                                                                                                                        |
| 312 |    317.104910 |    719.910767 | Giant Blue Anteater (vectorized by T. Michael Keesey)                                                                                                                                |
| 313 |    298.585883 |    161.505552 | Emil Schmidt (vectorized by Maxime Dahirel)                                                                                                                                          |
| 314 |    627.199332 |    192.939488 | Matt Crook                                                                                                                                                                           |
| 315 |    263.070589 |    673.515143 | Philippe Janvier (vectorized by T. Michael Keesey)                                                                                                                                   |
| 316 |   1011.385540 |    713.637714 | Jagged Fang Designs                                                                                                                                                                  |
| 317 |    566.036441 |    331.905288 | Matt Crook                                                                                                                                                                           |
| 318 |    420.383397 |    380.206538 | NA                                                                                                                                                                                   |
| 319 |    884.289286 |    755.476262 | Francisco Manuel Blanco (vectorized by T. Michael Keesey)                                                                                                                            |
| 320 |    156.470146 |    631.906242 | Dennis C. Murphy, after <https://commons.wikimedia.org/wiki/File:Queensland_State_Archives_2981_Cane_toads_at_the_Meringa_Sugar_Experiment_Station_North_Queensland_c_1935.png>      |
| 321 |    759.745533 |    362.482702 | Andy Wilson                                                                                                                                                                          |
| 322 |    139.055530 |    404.789444 | Michelle Site                                                                                                                                                                        |
| 323 |    518.978356 |    473.957033 | Steven Traver                                                                                                                                                                        |
| 324 |    726.639391 |     11.885021 | Jagged Fang Designs                                                                                                                                                                  |
| 325 |    855.059819 |    105.088858 | NA                                                                                                                                                                                   |
| 326 |     84.480048 |    205.119736 | Tasman Dixon                                                                                                                                                                         |
| 327 |     39.786696 |    238.326634 | T. Michael Keesey                                                                                                                                                                    |
| 328 |    544.876344 |    148.261995 | Robert Gay                                                                                                                                                                           |
| 329 |     46.106263 |    226.361244 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                                     |
| 330 |     28.370203 |    282.936418 | Christoph Schomburg                                                                                                                                                                  |
| 331 |    210.061594 |    123.665078 | Scott Hartman                                                                                                                                                                        |
| 332 |     72.235981 |    499.672446 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 333 |    707.930888 |     46.937004 | Sarah Werning                                                                                                                                                                        |
| 334 |    984.251644 |    225.306865 | Gareth Monger                                                                                                                                                                        |
| 335 |    518.825156 |    608.038962 | Emily Willoughby                                                                                                                                                                     |
| 336 |    138.562487 |    319.246208 | Andrew A. Farke                                                                                                                                                                      |
| 337 |    713.778004 |     76.842641 | David Orr                                                                                                                                                                            |
| 338 |    510.075879 |    677.816018 | Zimices                                                                                                                                                                              |
| 339 |    157.200561 |    437.807886 | Steven Traver                                                                                                                                                                        |
| 340 |    466.710738 |    655.102246 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 341 |    490.098741 |    320.780411 | Walter Vladimir                                                                                                                                                                      |
| 342 |   1004.842270 |    693.932582 | Becky Barnes                                                                                                                                                                         |
| 343 |    185.389135 |    348.580790 | Matt Crook                                                                                                                                                                           |
| 344 |    561.953350 |    604.940364 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 345 |    636.341119 |    767.879575 | Robert Gay                                                                                                                                                                           |
| 346 |    114.066383 |    320.482072 | Tasman Dixon                                                                                                                                                                         |
| 347 |    617.040873 |    167.322719 | Abraão Leite                                                                                                                                                                         |
| 348 |    176.030563 |     50.086049 | Jagged Fang Designs                                                                                                                                                                  |
| 349 |    144.184448 |    340.839912 | Birgit Lang                                                                                                                                                                          |
| 350 |    529.446825 |    740.110465 | Matthew E. Clapham                                                                                                                                                                   |
| 351 |    608.315741 |    533.565459 | Renata F. Martins                                                                                                                                                                    |
| 352 |    234.259015 |    346.143501 | NA                                                                                                                                                                                   |
| 353 |    940.043670 |     84.547840 | Beth Reinke                                                                                                                                                                          |
| 354 |    987.809606 |    394.273672 | NA                                                                                                                                                                                   |
| 355 |    633.874272 |    412.174828 | Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus                                                             |
| 356 |    348.528700 |    226.569194 | T. Michael Keesey                                                                                                                                                                    |
| 357 |   1009.921526 |    344.710015 | Andy Wilson                                                                                                                                                                          |
| 358 |    905.804443 |    735.570992 | Trond R. Oskars                                                                                                                                                                      |
| 359 |    294.243469 |    751.992910 | Jagged Fang Designs                                                                                                                                                                  |
| 360 |    678.976065 |    251.040939 | Zimices                                                                                                                                                                              |
| 361 |    258.495869 |    649.911283 | Caleb M. Brown                                                                                                                                                                       |
| 362 |    941.211617 |    742.594170 | Dmitry Bogdanov                                                                                                                                                                      |
| 363 |    644.365253 |    355.872256 | Steven Traver                                                                                                                                                                        |
| 364 |    897.966618 |    413.179300 | Margot Michaud                                                                                                                                                                       |
| 365 |    217.633866 |    507.587682 | M Kolmann                                                                                                                                                                            |
| 366 |    408.744021 |    243.750915 | Jaime Headden                                                                                                                                                                        |
| 367 |    493.413305 |     18.526160 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 368 |    887.173448 |    448.613802 | Michael “FunkMonk” B. H. (vectorized by T. Michael Keesey)                                                                                                                           |
| 369 |     46.561469 |    135.269848 | Kanchi Nanjo                                                                                                                                                                         |
| 370 |    401.411380 |     60.466513 | Mercedes Yrayzoz (vectorized by T. Michael Keesey)                                                                                                                                   |
| 371 |    253.154675 |    415.403353 | Margot Michaud                                                                                                                                                                       |
| 372 |    352.230798 |    217.250035 | Matt Crook                                                                                                                                                                           |
| 373 |     85.924925 |    587.191859 | Christoph Schomburg                                                                                                                                                                  |
| 374 |    570.220841 |    476.256473 | Margot Michaud                                                                                                                                                                       |
| 375 |    686.457573 |    307.049937 | Zimices                                                                                                                                                                              |
| 376 |    186.984294 |    679.592711 | Kai R. Caspar                                                                                                                                                                        |
| 377 |    336.947229 |    239.746303 | NA                                                                                                                                                                                   |
| 378 |    325.768576 |    790.833261 | Margot Michaud                                                                                                                                                                       |
| 379 |    696.932440 |     29.098178 | Chris huh                                                                                                                                                                            |
| 380 |    588.009967 |    304.287942 | Lisa M. “Pixxl” (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                      |
| 381 |    230.127218 |    563.333390 | Noah Schlottman, photo by Carlos Sánchez-Ortiz                                                                                                                                       |
| 382 |    358.600228 |    343.451201 | Robert Gay                                                                                                                                                                           |
| 383 |    450.229466 |    118.625295 | Lukasiniho                                                                                                                                                                           |
| 384 |     20.382561 |    156.407975 | Mathieu Pélissié                                                                                                                                                                     |
| 385 |    785.375724 |    487.816348 | Scott Hartman                                                                                                                                                                        |
| 386 |    862.896057 |    279.638279 | NA                                                                                                                                                                                   |
| 387 |    875.878236 |    454.171108 | Lukasiniho                                                                                                                                                                           |
| 388 |    301.313277 |    367.435070 | Scott Hartman                                                                                                                                                                        |
| 389 |    535.330353 |    383.584548 | Yan Wong from photo by Gyik Toma                                                                                                                                                     |
| 390 |    967.475036 |    281.650385 | S.Martini                                                                                                                                                                            |
| 391 |    938.252320 |    453.945164 | Benjamin Monod-Broca                                                                                                                                                                 |
| 392 |    232.735917 |    728.778945 | Tasman Dixon                                                                                                                                                                         |
| 393 |     94.309564 |    102.238132 | Yan Wong                                                                                                                                                                             |
| 394 |    194.886746 |    328.570694 | NA                                                                                                                                                                                   |
| 395 |     87.167768 |    627.506017 | Margot Michaud                                                                                                                                                                       |
| 396 |     45.432818 |    730.868544 | Mateus Zica (modified by T. Michael Keesey)                                                                                                                                          |
| 397 |    859.262826 |    415.449207 | Aline M. Ghilardi                                                                                                                                                                    |
| 398 |    464.012754 |     13.671156 | Hans Hillewaert                                                                                                                                                                      |
| 399 |    580.561649 |    730.855787 | Benchill                                                                                                                                                                             |
| 400 |   1019.969667 |    268.163009 | Archaeodontosaurus (vectorized by T. Michael Keesey)                                                                                                                                 |
| 401 |    862.998722 |    129.936714 | NA                                                                                                                                                                                   |
| 402 |    361.464132 |    591.936456 | Mykle Hoban                                                                                                                                                                          |
| 403 |    843.868182 |    239.651684 | Renato de Carvalho Ferreira                                                                                                                                                          |
| 404 |    339.496593 |    319.238663 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 405 |    902.850756 |    431.709166 | Matt Crook                                                                                                                                                                           |
| 406 |    201.809931 |     58.633154 | M. A. Broussard                                                                                                                                                                      |
| 407 |     17.261456 |     92.681138 | Mali’o Kodis, photograph from <http://commons.wikimedia.org/wiki/File:Trichoplax.jpg>                                                                                                |
| 408 |   1013.927120 |    257.203873 | Jaime Headden                                                                                                                                                                        |
| 409 |    268.373245 |     47.818648 | Katie S. Collins                                                                                                                                                                     |
| 410 |    996.521065 |    717.855676 | Gareth Monger                                                                                                                                                                        |
| 411 |    819.701158 |    337.463635 | Gareth Monger                                                                                                                                                                        |
| 412 |      8.033037 |    489.082042 | Noah Schlottman                                                                                                                                                                      |
| 413 |   1002.656340 |    682.493529 | Margot Michaud                                                                                                                                                                       |
| 414 |    661.493119 |    786.275082 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                                          |
| 415 |     64.909175 |    477.997638 | Mathieu Pélissié                                                                                                                                                                     |
| 416 |    641.321113 |    782.952258 | Margot Michaud                                                                                                                                                                       |
| 417 |    533.151417 |    174.134344 | Zimices                                                                                                                                                                              |
| 418 |    957.970447 |    252.296562 | Tasman Dixon                                                                                                                                                                         |
| 419 |    276.639867 |    633.722419 | Lukasiniho                                                                                                                                                                           |
| 420 |    875.470746 |    699.033472 | Zimices                                                                                                                                                                              |
| 421 |     44.179462 |    592.197541 | Zimices                                                                                                                                                                              |
| 422 |    950.339557 |    210.596575 | Matthias Buschmann (vectorized by T. Michael Keesey)                                                                                                                                 |
| 423 |    618.012817 |    660.182084 | Andy Wilson                                                                                                                                                                          |
| 424 |    564.629686 |    264.368976 | Charles R. Knight, vectorized by Zimices                                                                                                                                             |
| 425 |   1018.188971 |    751.811442 | T. Michael Keesey, from a photograph by Thea Boodhoo                                                                                                                                 |
| 426 |    248.949433 |    550.570373 | Andy Wilson                                                                                                                                                                          |
| 427 |    658.247125 |     49.781867 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 428 |    188.278003 |      8.014944 | Caleb M. Brown                                                                                                                                                                       |
| 429 |    202.775428 |    243.849738 | Felix Vaux                                                                                                                                                                           |
| 430 |    994.543749 |    121.501617 | Emily Willoughby                                                                                                                                                                     |
| 431 |    289.635778 |    782.873428 | Mariana Ruiz (vectorized by T. Michael Keesey)                                                                                                                                       |
| 432 |    215.805607 |    671.349045 | Andy Wilson                                                                                                                                                                          |
| 433 |    547.613832 |    480.979701 | NA                                                                                                                                                                                   |
| 434 |    715.223591 |    768.535518 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 435 |    302.876189 |    666.472173 | Yan Wong                                                                                                                                                                             |
| 436 |    395.795171 |     24.035190 | Scott Hartman                                                                                                                                                                        |
| 437 |    925.489415 |    739.158095 | Matt Crook                                                                                                                                                                           |
| 438 |     73.568606 |    568.328080 | Jack Mayer Wood                                                                                                                                                                      |
| 439 |    746.100880 |    550.105763 | C. Abraczinskas                                                                                                                                                                      |
| 440 |   1010.222054 |    305.703729 | Ingo Braasch                                                                                                                                                                         |
| 441 |    521.078788 |    213.183965 | Matt Crook                                                                                                                                                                           |
| 442 |    589.062792 |    432.344546 | Kevin Sánchez                                                                                                                                                                        |
| 443 |     11.125999 |    124.466126 | T. Michael Keesey (vectorization) and Nadiatalent (photography)                                                                                                                      |
| 444 |    566.688046 |    252.888079 | Gareth Monger                                                                                                                                                                        |
| 445 |    466.898329 |    447.653700 | NA                                                                                                                                                                                   |
| 446 |    147.621544 |    699.350216 | NA                                                                                                                                                                                   |
| 447 |    174.158166 |    281.707468 | Jagged Fang Designs                                                                                                                                                                  |
| 448 |    720.670527 |    500.311111 | Chris huh                                                                                                                                                                            |
| 449 |    377.919136 |    404.546760 | Frederick William Frohawk (vectorized by T. Michael Keesey)                                                                                                                          |
| 450 |    213.760148 |    456.085815 | Sarah Werning                                                                                                                                                                        |
| 451 |    651.423675 |    417.756508 | Steven Traver                                                                                                                                                                        |
| 452 |    771.801757 |    195.324566 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 453 |     17.972671 |    147.379808 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                                       |
| 454 |    617.097061 |      8.985744 | Jaime Headden                                                                                                                                                                        |
| 455 |    798.522030 |    760.698525 | Kamil S. Jaron                                                                                                                                                                       |
| 456 |    801.775961 |    364.056658 | Yan Wong from photo by Denes Emoke                                                                                                                                                   |
| 457 |     48.353876 |    529.219157 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 458 |    538.005954 |    237.613711 | NA                                                                                                                                                                                   |
| 459 |    552.767597 |    587.091783 | Verdilak                                                                                                                                                                             |
| 460 |    850.694399 |    754.036774 | Collin Gross                                                                                                                                                                         |
| 461 |    141.829605 |    569.169885 | Jagged Fang Designs                                                                                                                                                                  |
| 462 |    406.033726 |    518.230788 | DW Bapst, modified from Figure 1 of Belanger (2011, PALAIOS).                                                                                                                        |
| 463 |    742.398774 |    228.576609 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 464 |    822.230655 |     39.340343 | Sam Droege (photo) and T. Michael Keesey (vectorization)                                                                                                                             |
| 465 |    875.615163 |    431.382612 | Matt Crook                                                                                                                                                                           |
| 466 |    369.219502 |    102.995146 | Scott Hartman                                                                                                                                                                        |
| 467 |    586.513639 |      5.013454 | Chris huh                                                                                                                                                                            |
| 468 |    605.570336 |    619.737005 | T. Michael Keesey                                                                                                                                                                    |
| 469 |    936.605436 |    520.314957 | Chris huh                                                                                                                                                                            |
| 470 |    978.990174 |    318.998231 | Matt Crook                                                                                                                                                                           |
| 471 |    320.031143 |    553.442533 | Christoph Schomburg                                                                                                                                                                  |
| 472 |    897.192122 |    760.689379 | Melissa Broussard                                                                                                                                                                    |
| 473 |    761.485256 |    577.135341 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey)                |
| 474 |   1009.449496 |    286.749036 | NA                                                                                                                                                                                   |
| 475 |    298.922708 |    656.596286 | Lukasiniho                                                                                                                                                                           |
| 476 |    750.350197 |    354.108332 | CNZdenek                                                                                                                                                                             |
| 477 |    215.600857 |    600.418332 | Christoph Schomburg                                                                                                                                                                  |
| 478 |    214.363513 |    203.714821 | Michele M Tobias                                                                                                                                                                     |
| 479 |    635.998760 |    326.624450 | Agnello Picorelli                                                                                                                                                                    |
| 480 |    167.553391 |     36.402648 | Ferran Sayol                                                                                                                                                                         |
| 481 |    543.392331 |    210.250887 | Gareth Monger                                                                                                                                                                        |
| 482 |    450.181655 |    148.318111 | Armelle Ansart (photograph), Maxime Dahirel (digitisation)                                                                                                                           |
| 483 |    697.032282 |    566.748564 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 484 |    984.254402 |    625.189714 | Zimices                                                                                                                                                                              |
| 485 |    324.735301 |    432.918511 | Harold N Eyster                                                                                                                                                                      |
| 486 |    626.581256 |    137.423783 | Karla Martinez                                                                                                                                                                       |
| 487 |     10.146028 |    182.600825 | Dmitry Bogdanov                                                                                                                                                                      |
| 488 |    216.115741 |    691.651796 | T. Michael Keesey (vectorization); Thorsten Assmann, Jörn Buse, Claudia Drees, Ariel-Leib-Leonid Friedman, Tal Levanony, Andrea Matern, Anika Timm, and David W. Wrase (photography) |
| 489 |    354.584120 |    765.872894 | Sharon Wegner-Larsen                                                                                                                                                                 |
| 490 |    267.116432 |    777.726133 | Birgit Lang                                                                                                                                                                          |
| 491 |    805.744616 |    193.638652 | Dean Schnabel                                                                                                                                                                        |
| 492 |     93.601221 |     21.930157 | Meliponicultor Itaymbere                                                                                                                                                             |
| 493 |    976.540450 |    347.331445 | Armin Reindl                                                                                                                                                                         |
| 494 |    476.283635 |    690.108781 | Ignacio Contreras                                                                                                                                                                    |
| 495 |    282.942491 |    284.332429 | Xavier A. Jenkins, Gabriel Ugueto                                                                                                                                                    |
| 496 |    748.400511 |    710.149400 | Crystal Maier                                                                                                                                                                        |
| 497 |    814.984829 |    456.944480 | Matt Crook                                                                                                                                                                           |
| 498 |    431.669080 |    182.330223 | Matt Crook                                                                                                                                                                           |
| 499 |    793.052273 |    601.006729 | NA                                                                                                                                                                                   |
| 500 |    107.195946 |    768.398564 | Tom Tarrant (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                          |
| 501 |    469.978150 |    731.135208 | NA                                                                                                                                                                                   |
| 502 |    358.459024 |    162.226308 | T. Michael Keesey                                                                                                                                                                    |
| 503 |    668.568730 |     33.040911 | Steven Traver                                                                                                                                                                        |
| 504 |    842.504054 |     51.385058 | Margot Michaud                                                                                                                                                                       |
| 505 |    901.605752 |    318.665471 | Matt Crook                                                                                                                                                                           |
| 506 |    881.013825 |    627.301759 | Margot Michaud                                                                                                                                                                       |
| 507 |    901.610688 |    780.226654 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 508 |    685.485666 |     98.060737 | Josep Marti Solans                                                                                                                                                                   |
| 509 |    871.694941 |    662.269133 | Robert Gay, modifed from Olegivvit                                                                                                                                                   |
| 510 |    572.346725 |    721.998942 | Felix Vaux                                                                                                                                                                           |
| 511 |    561.487350 |    316.245421 | NA                                                                                                                                                                                   |
| 512 |    479.065248 |    105.704026 | Emily Willoughby                                                                                                                                                                     |
| 513 |    324.055891 |    156.834946 | Kelly                                                                                                                                                                                |
| 514 |    883.512515 |    517.426348 | Sebastian Stabinger                                                                                                                                                                  |
| 515 |    802.211894 |    644.459217 | Jessica Anne Miller                                                                                                                                                                  |
| 516 |     64.693390 |    600.150884 | Chloé Schmidt                                                                                                                                                                        |
| 517 |    300.240063 |    513.457497 | Julio Garza                                                                                                                                                                          |
| 518 |    487.198608 |    736.902663 | Armin Reindl                                                                                                                                                                         |
| 519 |    347.409856 |     67.544930 | Steven Traver                                                                                                                                                                        |
| 520 |    620.494423 |    552.230982 | Markus A. Grohme                                                                                                                                                                     |
| 521 |     12.320352 |    675.141055 | SecretJellyMan - from Mason McNair                                                                                                                                                   |
| 522 |    451.877844 |    528.470374 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 523 |    671.114184 |    110.156027 | NA                                                                                                                                                                                   |
| 524 |    635.362611 |    402.375909 | Stanton F. Fink, vectorized by Zimices                                                                                                                                               |
| 525 |     64.501989 |    659.355102 | kotik                                                                                                                                                                                |
| 526 |    939.231513 |    646.603737 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 527 |   1011.440623 |    497.625888 | Derek Bakken (photograph) and T. Michael Keesey (vectorization)                                                                                                                      |
| 528 |    755.027761 |    131.412634 | Matt Crook                                                                                                                                                                           |
| 529 |    190.934657 |     37.571416 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                                     |
| 530 |    330.569357 |    705.316060 | Michelle Site                                                                                                                                                                        |
| 531 |    536.545524 |      9.854320 | Gareth Monger                                                                                                                                                                        |
| 532 |    502.688150 |    657.052894 | Gregor Bucher, Max Farnworth                                                                                                                                                         |
| 533 |    414.103516 |    773.746801 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                                      |
| 534 |    988.654476 |    257.323098 | Gareth Monger                                                                                                                                                                        |
| 535 |    911.619800 |    752.053309 | Margot Michaud                                                                                                                                                                       |
| 536 |    778.088159 |    795.033461 | NA                                                                                                                                                                                   |
| 537 |    256.188907 |      9.445289 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 538 |    777.567832 |    134.920180 | Tasman Dixon                                                                                                                                                                         |
| 539 |   1008.439758 |    416.198579 | Tracy A. Heath                                                                                                                                                                       |
| 540 |    344.292776 |    705.379350 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 541 |    381.949611 |    258.615677 | Joshua Fowler                                                                                                                                                                        |
| 542 |    946.111681 |    273.672542 | Zimices                                                                                                                                                                              |
| 543 |    258.187659 |     84.392986 | Maxime Dahirel                                                                                                                                                                       |
| 544 |    315.011922 |    640.345390 | Matt Crook                                                                                                                                                                           |
| 545 |    718.870518 |    269.045682 | Margot Michaud                                                                                                                                                                       |
| 546 |    300.342493 |    741.583749 | FunkMonk                                                                                                                                                                             |
| 547 |    767.041281 |    624.631138 | Scott Hartman                                                                                                                                                                        |
| 548 |    604.883396 |    189.407651 | Steven Coombs                                                                                                                                                                        |
| 549 |   1014.719896 |    768.597259 | Birgit Lang                                                                                                                                                                          |
| 550 |    261.080371 |    665.268601 | Margot Michaud                                                                                                                                                                       |
| 551 |    358.835548 |    319.006172 | Anna Willoughby                                                                                                                                                                      |
| 552 |    327.645631 |    404.889204 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                                       |
| 553 |    737.871899 |    748.107358 | NA                                                                                                                                                                                   |
| 554 |    855.782708 |    318.922116 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                                         |
| 555 |    113.668713 |    636.982143 | Zimices                                                                                                                                                                              |
| 556 |    735.703098 |    368.333306 | Harold N Eyster                                                                                                                                                                      |
| 557 |    828.177963 |    736.741169 | Zimices                                                                                                                                                                              |
| 558 |    742.946407 |    134.792160 | Ferran Sayol                                                                                                                                                                         |
| 559 |    943.822810 |    228.481277 | Zimices                                                                                                                                                                              |
| 560 |    811.174957 |    400.379554 | Tasman Dixon                                                                                                                                                                         |
| 561 |    420.684196 |    781.576456 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 562 |    998.769401 |    762.134881 | Jagged Fang Designs                                                                                                                                                                  |
| 563 |    334.656069 |    772.622135 | Gareth Monger                                                                                                                                                                        |
| 564 |    615.905534 |    144.983160 | Andy Wilson                                                                                                                                                                          |
| 565 |    171.546848 |    694.737231 | Scott Hartman                                                                                                                                                                        |
| 566 |    144.438159 |    456.811787 | Chris huh                                                                                                                                                                            |
| 567 |    108.071652 |    493.623312 | Matt Dempsey                                                                                                                                                                         |
| 568 |    164.155614 |     90.214524 | Scott Hartman                                                                                                                                                                        |
| 569 |     43.442186 |    570.395406 | Jagged Fang Designs                                                                                                                                                                  |
| 570 |    839.622479 |      6.051102 | Michelle Site                                                                                                                                                                        |
| 571 |    340.382224 |    339.075023 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 572 |     13.309256 |    342.002067 | Chris huh                                                                                                                                                                            |
| 573 |     88.098928 |    285.573159 | Matt Crook                                                                                                                                                                           |
| 574 |     10.384480 |    191.007597 | Steven Traver                                                                                                                                                                        |
| 575 |    215.881589 |    578.473156 | Collin Gross                                                                                                                                                                         |
| 576 |    422.936818 |    408.553784 | Neil Kelley                                                                                                                                                                          |
| 577 |    740.111726 |    246.260177 | Aviceda (vectorized by T. Michael Keesey)                                                                                                                                            |
| 578 |     41.058348 |    154.793784 | Richard J. Harris                                                                                                                                                                    |
| 579 |    213.801679 |    119.463376 | Johan Lindgren, Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe                                                                                                                 |
| 580 |    601.802205 |    466.294632 | Matt Crook                                                                                                                                                                           |
| 581 |    786.851589 |    376.383686 | T. Michael Keesey                                                                                                                                                                    |
| 582 |     67.464690 |    334.496057 | Benjamin Monod-Broca                                                                                                                                                                 |
| 583 |    543.229611 |    616.041600 | Margot Michaud                                                                                                                                                                       |
| 584 |    220.279785 |    166.427424 | Birgit Lang                                                                                                                                                                          |
| 585 |    357.592710 |    792.551549 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 586 |    413.107868 |    283.084562 | Stemonitis (photography) and T. Michael Keesey (vectorization)                                                                                                                       |
| 587 |    145.230844 |    387.498794 | Tasman Dixon                                                                                                                                                                         |
| 588 |    617.342896 |    754.782231 | Sarah Werning                                                                                                                                                                        |
| 589 |    766.435524 |    711.879843 | (after Spotila 2004)                                                                                                                                                                 |
| 590 |    301.586393 |    793.099978 | Margot Michaud                                                                                                                                                                       |
| 591 |    781.719938 |    161.122249 | Ferran Sayol                                                                                                                                                                         |
| 592 |    577.504408 |    323.112726 | terngirl                                                                                                                                                                             |
| 593 |    130.836558 |    714.558516 | Gareth Monger                                                                                                                                                                        |
| 594 |    487.895784 |    200.253132 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                                     |
| 595 |    240.006725 |    260.365551 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                                     |
| 596 |    440.849590 |    323.723700 | Arthur S. Brum                                                                                                                                                                       |
| 597 |    650.137429 |    432.988627 | Steven Traver                                                                                                                                                                        |
| 598 |    912.724583 |      6.822534 | Cesar Julian                                                                                                                                                                         |
| 599 |    208.962243 |    414.395198 | Joshua Fowler                                                                                                                                                                        |
| 600 |    733.388062 |    762.121404 | Andy Wilson                                                                                                                                                                          |
| 601 |    517.621595 |    650.791832 | Andrew A. Farke, modified from original by H. Milne Edwards                                                                                                                          |
| 602 |    708.313214 |    259.758905 | Scott Hartman                                                                                                                                                                        |
| 603 |    526.424310 |    374.242875 | Joanna Wolfe                                                                                                                                                                         |
| 604 |    817.753905 |    196.713678 | Pete Buchholz                                                                                                                                                                        |
| 605 |    568.915517 |    423.516515 | Myriam\_Ramirez                                                                                                                                                                      |
| 606 |    684.769003 |     37.124442 | Steven Coombs                                                                                                                                                                        |
| 607 |    228.383932 |    511.946538 | Tasman Dixon                                                                                                                                                                         |
| 608 |    283.739774 |    186.219124 | Steven Traver                                                                                                                                                                        |
| 609 |    883.062604 |    640.630361 | Steven Traver                                                                                                                                                                        |
| 610 |     11.902523 |    739.336916 | NA                                                                                                                                                                                   |
| 611 |     97.878555 |    283.396192 | Gareth Monger                                                                                                                                                                        |
| 612 |    973.682738 |     16.114186 | Kanako Bessho-Uehara                                                                                                                                                                 |
| 613 |    311.411942 |    563.327717 | NA                                                                                                                                                                                   |
| 614 |    547.579179 |    183.223665 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 615 |    500.521106 |    117.125017 | Ignacio Contreras                                                                                                                                                                    |
| 616 |    930.316844 |    510.659210 | Mattia Menchetti                                                                                                                                                                     |
| 617 |    277.457485 |    350.329938 | Mario Quevedo                                                                                                                                                                        |
| 618 |    469.810439 |    289.600489 | Zimices                                                                                                                                                                              |
| 619 |    381.568799 |    543.367510 | NA                                                                                                                                                                                   |
| 620 |    480.498886 |     26.087742 | Jagged Fang Designs                                                                                                                                                                  |
| 621 |    920.108462 |    484.950676 | Margot Michaud                                                                                                                                                                       |
| 622 |      6.831279 |     39.294977 | Robert Hering                                                                                                                                                                        |
| 623 |    182.325022 |    362.421593 | Jagged Fang Designs                                                                                                                                                                  |
| 624 |    611.771715 |    197.255136 | Zimices                                                                                                                                                                              |
| 625 |    676.516755 |    712.354695 | Chase Brownstein                                                                                                                                                                     |
| 626 |    672.911232 |    625.190270 | Zimices                                                                                                                                                                              |
| 627 |     84.985175 |    664.147370 | Margot Michaud                                                                                                                                                                       |
| 628 |    705.702987 |    335.354628 | Matt Crook                                                                                                                                                                           |
| 629 |    136.773880 |    270.201016 | Zimices                                                                                                                                                                              |
| 630 |    421.530537 |    159.589720 | Zimices                                                                                                                                                                              |
| 631 |    998.984748 |    657.660767 | Mercedes Yrayzoz (vectorized by T. Michael Keesey)                                                                                                                                   |
| 632 |    454.485501 |    425.884749 | Steven Traver                                                                                                                                                                        |
| 633 |    157.217817 |    302.271811 | Fernando Carezzano                                                                                                                                                                   |
| 634 |    685.061317 |    116.579601 | Kimberly Haddrell                                                                                                                                                                    |
| 635 |    894.442878 |    575.547532 | Matt Crook                                                                                                                                                                           |
| 636 |    192.486860 |    460.040300 | Ferran Sayol                                                                                                                                                                         |
| 637 |     68.388762 |      9.341835 | Margot Michaud                                                                                                                                                                       |
| 638 |    429.574732 |    341.886277 | Ferran Sayol                                                                                                                                                                         |
| 639 |    512.068061 |    637.900153 | Zimices                                                                                                                                                                              |
| 640 |    690.538069 |    589.211338 | Philippe Janvier (vectorized by T. Michael Keesey)                                                                                                                                   |
| 641 |     35.875158 |    255.930246 | nicubunu                                                                                                                                                                             |
| 642 |    103.539095 |     15.475469 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 643 |    572.523536 |    518.247162 | Matt Crook                                                                                                                                                                           |
| 644 |    386.578927 |    109.136988 | Gareth Monger                                                                                                                                                                        |
| 645 |    147.614027 |     82.491072 | Matt Wilkins                                                                                                                                                                         |
| 646 |    870.633678 |    391.726956 | NA                                                                                                                                                                                   |
| 647 |     46.000277 |    195.555201 | T. Michael Keesey (after A. Y. Ivantsov)                                                                                                                                             |
| 648 |    464.861246 |    335.057376 | Steven Traver                                                                                                                                                                        |
| 649 |    339.939672 |    161.880412 | Kai R. Caspar                                                                                                                                                                        |
| 650 |    608.181340 |    346.439797 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                                      |
| 651 |    680.542467 |    156.615610 | Iain Reid                                                                                                                                                                            |
| 652 |    838.348512 |    555.400251 | Steven Traver                                                                                                                                                                        |
| 653 |    902.050611 |     16.096288 | Steven Traver                                                                                                                                                                        |
| 654 |    594.584452 |    413.655642 | Ferran Sayol                                                                                                                                                                         |
| 655 |    651.122224 |    474.315284 | Scott Hartman                                                                                                                                                                        |
| 656 |    805.034281 |    667.068519 | T. Michael Keesey                                                                                                                                                                    |
| 657 |    996.775307 |    408.244347 | Ville-Veikko Sinkkonen                                                                                                                                                               |
| 658 |    180.523425 |    221.004755 | Timothy Knepp of the U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                               |
| 659 |     25.505535 |    484.155269 | Mathew Callaghan                                                                                                                                                                     |
| 660 |    451.944134 |    196.269557 | Steven Traver                                                                                                                                                                        |
| 661 |    273.164611 |    456.730725 | Martin R. Smith                                                                                                                                                                      |
| 662 |    138.444482 |    284.748036 | Lily Hughes                                                                                                                                                                          |
| 663 |    390.009899 |    418.766946 | John Conway                                                                                                                                                                          |
| 664 |    281.379284 |    136.081795 | Sarah Werning                                                                                                                                                                        |
| 665 |    109.987982 |     70.308166 | Roderic Page and Lois Page                                                                                                                                                           |
| 666 |     80.179122 |    195.396793 | Margot Michaud                                                                                                                                                                       |
| 667 |    790.543406 |    493.254861 | Lukas Panzarin (vectorized by T. Michael Keesey)                                                                                                                                     |
| 668 |    117.591582 |    437.598285 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                                    |
| 669 |    582.508400 |    575.002844 | Dean Schnabel                                                                                                                                                                        |
| 670 |    277.662594 |     68.119459 | Juan Carlos Jerí                                                                                                                                                                     |
| 671 |     50.491957 |    551.872361 | Zimices                                                                                                                                                                              |
| 672 |    291.704460 |    406.285961 | Markus A. Grohme                                                                                                                                                                     |
| 673 |    838.586595 |    763.133264 | Scott Hartman                                                                                                                                                                        |
| 674 |    801.318592 |    382.378142 | Birgit Lang                                                                                                                                                                          |
| 675 |    675.848852 |    226.507837 | Matt Crook                                                                                                                                                                           |
| 676 |    756.012396 |    752.999089 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 677 |    273.066476 |    124.344332 | Nobu Tamura                                                                                                                                                                          |
| 678 |    395.944599 |    518.801069 | Caleb M. Brown                                                                                                                                                                       |
| 679 |    432.080162 |    253.043756 | Jaime Headden                                                                                                                                                                        |
| 680 |    837.290264 |    468.623992 | Yan Wong                                                                                                                                                                             |
| 681 |    958.707730 |     11.703889 | Margot Michaud                                                                                                                                                                       |
| 682 |    237.605503 |    503.967239 | Tambja (vectorized by T. Michael Keesey)                                                                                                                                             |
| 683 |     26.715241 |    501.456218 | Margot Michaud                                                                                                                                                                       |
| 684 |    230.919204 |    536.556787 | Tasman Dixon                                                                                                                                                                         |
| 685 |    918.814851 |    730.527787 | Margot Michaud                                                                                                                                                                       |
| 686 |    429.930080 |    702.729824 | Gareth Monger                                                                                                                                                                        |
| 687 |    116.883968 |    653.246267 | Scott Reid                                                                                                                                                                           |
| 688 |    530.758122 |    707.926540 | Matt Crook                                                                                                                                                                           |
| 689 |    201.918890 |    556.692688 | Christoph Schomburg                                                                                                                                                                  |
| 690 |    916.814401 |    276.346538 | Sarah Werning                                                                                                                                                                        |
| 691 |    260.846807 |    551.417124 | NA                                                                                                                                                                                   |
| 692 |    136.159348 |    424.812618 | Matt Crook                                                                                                                                                                           |
| 693 |    438.099190 |    235.622454 | Dave Angelini                                                                                                                                                                        |
| 694 |    281.011837 |    120.243863 | Jagged Fang Designs                                                                                                                                                                  |
| 695 |    650.943661 |    117.948211 | Lafage                                                                                                                                                                               |
| 696 |    657.156523 |    677.428107 | Matt Crook                                                                                                                                                                           |
| 697 |    650.266746 |    702.245028 | Francesco “Architetto” Rollandin                                                                                                                                                     |
| 698 |    411.362076 |    575.574543 | Maija Karala                                                                                                                                                                         |
| 699 |    231.914453 |    496.737936 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 700 |    213.137840 |    328.201849 | Gareth Monger                                                                                                                                                                        |
| 701 |     27.151128 |    276.325873 | Matt Crook                                                                                                                                                                           |
| 702 |    498.911691 |     97.431862 | Sharon Wegner-Larsen                                                                                                                                                                 |
| 703 |    216.732262 |    785.462624 | Kimberly Haddrell                                                                                                                                                                    |
| 704 |    229.199833 |    258.346790 | NA                                                                                                                                                                                   |
| 705 |    896.378073 |    189.927276 | Ferran Sayol                                                                                                                                                                         |
| 706 |    513.441311 |    786.045518 | Jagged Fang Designs                                                                                                                                                                  |
| 707 |   1003.517112 |     31.479869 | Steven Traver                                                                                                                                                                        |
| 708 |    982.308908 |    211.846473 | Robert Bruce Horsfall (vectorized by T. Michael Keesey)                                                                                                                              |
| 709 |     20.062506 |    532.666221 | Scott Hartman                                                                                                                                                                        |
| 710 |    963.355775 |    377.737592 | Rebecca Groom                                                                                                                                                                        |
| 711 |    274.047997 |    667.456268 | JCGiron                                                                                                                                                                              |
| 712 |    108.155283 |    559.394448 | Noah Schlottman, photo by Adam G. Clause                                                                                                                                             |
| 713 |    408.190562 |    386.040796 | Andrew A. Farke                                                                                                                                                                      |
| 714 |     37.824601 |    541.765391 | Steven Traver                                                                                                                                                                        |
| 715 |    847.100740 |    544.681821 | Jagged Fang Designs                                                                                                                                                                  |
| 716 |    352.200286 |    252.805815 | T. Michael Keesey                                                                                                                                                                    |
| 717 |    394.650387 |    577.191559 | Scott Hartman                                                                                                                                                                        |
| 718 |    274.504908 |    485.997461 | Charles R. Knight (vectorized by T. Michael Keesey)                                                                                                                                  |
| 719 |    327.111597 |    740.732961 | Jaime Headden                                                                                                                                                                        |
| 720 |    795.954598 |    126.880563 | NA                                                                                                                                                                                   |
| 721 |    302.812660 |    393.985523 | NA                                                                                                                                                                                   |
| 722 |    739.653175 |     75.557388 | Kamil S. Jaron                                                                                                                                                                       |
| 723 |    963.493321 |    339.705549 | Steven Traver                                                                                                                                                                        |
| 724 |     10.559616 |    721.469920 | Melissa Broussard                                                                                                                                                                    |
| 725 |    657.795714 |    263.609340 | Andy Wilson                                                                                                                                                                          |
| 726 |    283.010978 |    718.278840 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 727 |    962.652995 |    293.466948 | Gordon E. Robertson                                                                                                                                                                  |
| 728 |    588.653732 |    286.438534 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                                          |
| 729 |    163.075990 |     81.058052 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 730 |    699.955846 |    749.167780 | Zimices                                                                                                                                                                              |
| 731 |    109.427149 |     84.782739 | Gareth Monger                                                                                                                                                                        |
| 732 |    546.661168 |    415.424323 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 733 |     39.455125 |    138.313798 | J. J. Harrison (photo) & T. Michael Keesey                                                                                                                                           |
| 734 |    492.582155 |     29.095649 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 735 |      9.392146 |     68.180855 | Mali’o Kodis, image from the “Proceedings of the Zoological Society of London”                                                                                                       |
| 736 |    374.123925 |    161.483769 | Chris huh                                                                                                                                                                            |
| 737 |    713.681163 |    126.472627 | Anna Willoughby                                                                                                                                                                      |
| 738 |    913.035605 |    202.514799 | Birgit Lang                                                                                                                                                                          |
| 739 |    924.293466 |    165.217015 | Matt Crook                                                                                                                                                                           |
| 740 |    205.485228 |    683.760593 | Matt Crook                                                                                                                                                                           |
| 741 |   1009.083967 |     14.264860 | Matt Crook                                                                                                                                                                           |
| 742 |    130.858089 |    276.123020 | Lip Kee Yap (vectorized by T. Michael Keesey)                                                                                                                                        |
| 743 |    162.042030 |    587.132585 | Fritz Geller-Grimm (vectorized by T. Michael Keesey)                                                                                                                                 |
| 744 |    152.141031 |    673.601762 | M. Garfield & K. Anderson (modified by T. Michael Keesey)                                                                                                                            |
| 745 |    873.052408 |    309.730434 | T. Michael Keesey (photo by Sean Mack)                                                                                                                                               |
| 746 |    926.438382 |    413.017988 | Tauana J. Cunha                                                                                                                                                                      |
| 747 |     56.117386 |    647.970282 | Ieuan Jones                                                                                                                                                                          |
| 748 |    122.737867 |    569.409973 | Sarah Werning                                                                                                                                                                        |
| 749 |    683.585033 |    237.575654 | Jack Mayer Wood                                                                                                                                                                      |
| 750 |    176.224320 |    782.611441 | NA                                                                                                                                                                                   |
| 751 |    975.352899 |    460.452478 | Steven Traver                                                                                                                                                                        |
| 752 |     10.483193 |    453.278932 | Jose Carlos Arenas-Monroy                                                                                                                                                            |
| 753 |     29.451337 |    202.545589 | Yusan Yang                                                                                                                                                                           |
| 754 |    909.155142 |    406.758518 | Birgit Lang                                                                                                                                                                          |
| 755 |    964.375274 |    222.790455 | Steven Traver                                                                                                                                                                        |
| 756 |    496.555607 |    336.236151 | Markus A. Grohme                                                                                                                                                                     |
| 757 |    371.521921 |    698.027139 | Margot Michaud                                                                                                                                                                       |
| 758 |    879.239724 |    776.123049 | Zimices                                                                                                                                                                              |
| 759 |     74.439602 |    621.541290 | Zimices                                                                                                                                                                              |
| 760 |    183.306513 |    270.116148 | Gareth Monger                                                                                                                                                                        |
| 761 |    315.823525 |    597.460484 | Matt Crook                                                                                                                                                                           |
| 762 |    352.380519 |    426.593414 | Matt Crook                                                                                                                                                                           |
| 763 |    553.564735 |    547.429675 | Steven Traver                                                                                                                                                                        |
| 764 |     21.819363 |    249.408990 | Fernando Carezzano                                                                                                                                                                   |
| 765 |    721.660374 |    550.039929 | Margot Michaud                                                                                                                                                                       |
| 766 |    357.183407 |    129.470417 | Taenadoman                                                                                                                                                                           |
| 767 |    331.039209 |    330.646374 | Abraão Leite                                                                                                                                                                         |
| 768 |     86.553526 |     78.148963 | FunkMonk (Michael B.H.; vectorized by T. Michael Keesey)                                                                                                                             |
| 769 |    833.866626 |    186.179453 | Margot Michaud                                                                                                                                                                       |
| 770 |     41.960651 |    172.879236 | Steven Traver                                                                                                                                                                        |
| 771 |    225.607105 |    328.430960 | Zimices                                                                                                                                                                              |
| 772 |    330.426668 |    415.274590 | Steven Traver                                                                                                                                                                        |
| 773 |    417.918668 |    631.017322 | Zimices                                                                                                                                                                              |
| 774 |    794.958565 |    660.728281 | Scott Hartman                                                                                                                                                                        |
| 775 |    425.759745 |    281.607886 | Jagged Fang Designs                                                                                                                                                                  |
| 776 |    332.225015 |    666.882647 | Steven Traver                                                                                                                                                                        |
| 777 |    735.957873 |    344.483656 | Matt Crook                                                                                                                                                                           |
| 778 |    612.347862 |    788.139740 | Jaime Headden                                                                                                                                                                        |
| 779 |    162.685420 |    400.264492 | T. Michael Keesey (after Mivart)                                                                                                                                                     |
| 780 |    518.494113 |    307.061592 | Zimices                                                                                                                                                                              |
| 781 |    855.665549 |    466.924682 | James R. Spotila and Ray Chatterji                                                                                                                                                   |
| 782 |    719.520756 |     59.639876 | Kanchi Nanjo                                                                                                                                                                         |
| 783 |    296.047200 |    728.669627 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                                                    |
| 784 |    989.962377 |    741.294323 | Felix Vaux                                                                                                                                                                           |
| 785 |    450.964476 |    782.278458 | Matt Crook                                                                                                                                                                           |
| 786 |     38.223684 |    708.612481 | Matt Crook                                                                                                                                                                           |
| 787 |    931.362675 |    172.785883 | Chris huh                                                                                                                                                                            |
| 788 |    620.237967 |    705.820670 | Zimices                                                                                                                                                                              |
| 789 |    731.923435 |    121.058393 | T. Michael Keesey                                                                                                                                                                    |
| 790 |    386.265738 |    443.265891 | Margot Michaud                                                                                                                                                                       |
| 791 |    261.007079 |    468.260275 | Jaime Headden                                                                                                                                                                        |
| 792 |    659.864286 |    727.886843 | Jose Carlos Arenas-Monroy                                                                                                                                                            |
| 793 |    279.572057 |    736.475996 | Nobu Tamura                                                                                                                                                                          |
| 794 |    919.373704 |    104.708653 | Tony Ayling                                                                                                                                                                          |
| 795 |    951.618909 |    566.303134 | Margot Michaud                                                                                                                                                                       |
| 796 |   1012.092095 |    426.009994 | Tasman Dixon                                                                                                                                                                         |
| 797 |    154.462126 |    226.281056 | Manabu Bessho-Uehara                                                                                                                                                                 |
| 798 |    511.330233 |    366.161308 | NA                                                                                                                                                                                   |
| 799 |     40.351431 |    388.487337 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 800 |    787.948860 |    332.546380 | Matt Crook                                                                                                                                                                           |
| 801 |    416.049800 |    351.789106 | Dean Schnabel                                                                                                                                                                        |
| 802 |    817.030711 |    763.541120 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                                          |
| 803 |    843.436393 |     45.709200 | Sarah Werning                                                                                                                                                                        |
| 804 |    944.381411 |    526.863220 | T. Michael Keesey (from a photo by Maximilian Paradiz)                                                                                                                               |
| 805 |    907.828510 |    139.172755 | Nicolas Huet le Jeune and Jean-Gabriel Prêtre (vectorized by T. Michael Keesey)                                                                                                      |
| 806 |    353.551190 |    273.469080 | Jose Carlos Arenas-Monroy                                                                                                                                                            |
| 807 |    439.574808 |    582.580101 | NASA                                                                                                                                                                                 |
| 808 |    501.629030 |     34.372790 | Mathew Wedel                                                                                                                                                                         |
| 809 |    194.394643 |    415.213335 | Becky Barnes                                                                                                                                                                         |
| 810 |    886.775658 |    595.079531 | Hugo Gruson                                                                                                                                                                          |
| 811 |    599.517651 |     95.087060 | T. Michael Keesey                                                                                                                                                                    |
| 812 |     63.174611 |    792.429238 | Steven Traver                                                                                                                                                                        |
| 813 |    750.653153 |    608.729118 | T. Michael Keesey (after Mivart)                                                                                                                                                     |
| 814 |    164.594493 |    758.417958 | Ferran Sayol                                                                                                                                                                         |
| 815 |    640.871687 |    724.479745 | Erika Schumacher                                                                                                                                                                     |
| 816 |    549.797408 |    255.256634 | Steven Traver                                                                                                                                                                        |
| 817 |    869.537862 |    383.911941 | Katie S. Collins                                                                                                                                                                     |
| 818 |     23.050675 |    222.215669 | NA                                                                                                                                                                                   |
| 819 |    557.962582 |    206.251352 | Sean McCann                                                                                                                                                                          |
| 820 |    236.198187 |    777.606280 | Zimices                                                                                                                                                                              |
| 821 |    814.119727 |    567.037385 | NA                                                                                                                                                                                   |
| 822 |    564.859262 |    366.234113 | Matt Dempsey                                                                                                                                                                         |
| 823 |    841.383685 |    792.595207 | Kamil S. Jaron                                                                                                                                                                       |
| 824 |    993.905662 |    385.759280 | NA                                                                                                                                                                                   |
| 825 |    561.625729 |    451.428279 | Kamil S. Jaron                                                                                                                                                                       |
| 826 |    332.316905 |    749.377805 | Tasman Dixon                                                                                                                                                                         |
| 827 |    328.056686 |      9.866572 | Ferran Sayol                                                                                                                                                                         |
| 828 |    153.809034 |    474.541860 | Notafly (vectorized by T. Michael Keesey)                                                                                                                                            |
| 829 |    724.549924 |    366.036444 | Scott Hartman                                                                                                                                                                        |
| 830 |    514.507328 |    791.534585 | Markus A. Grohme                                                                                                                                                                     |
| 831 |    559.669031 |    790.587553 | Margot Michaud                                                                                                                                                                       |
| 832 |    846.352958 |    298.487765 | NA                                                                                                                                                                                   |
| 833 |    980.197463 |    108.406910 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 834 |     48.546658 |    757.468614 | Zimices                                                                                                                                                                              |
| 835 |    640.874055 |    113.181669 | Chloé Schmidt                                                                                                                                                                        |
| 836 |    373.975453 |     83.390120 | I. Geoffroy Saint-Hilaire (vectorized by T. Michael Keesey)                                                                                                                          |
| 837 |    208.596649 |    224.719273 | Jaime Headden                                                                                                                                                                        |
| 838 |    341.119197 |     14.225520 | Jagged Fang Designs                                                                                                                                                                  |
| 839 |   1004.145971 |    439.674420 | Tasman Dixon                                                                                                                                                                         |
| 840 |    468.756182 |    193.274399 | Sarah Werning                                                                                                                                                                        |
| 841 |     78.666546 |     90.502498 | Jake Warner                                                                                                                                                                          |
| 842 |    190.203296 |    693.641793 | Dean Schnabel                                                                                                                                                                        |
| 843 |    407.249739 |    336.177554 | Scott Hartman                                                                                                                                                                        |
| 844 |    328.917463 |    504.491563 | Ferran Sayol                                                                                                                                                                         |
| 845 |    805.854026 |    257.728188 | Andy Wilson                                                                                                                                                                          |
| 846 |    145.971717 |    762.519116 | Emily Willoughby                                                                                                                                                                     |
| 847 |     57.289518 |    581.763933 | Joanna Wolfe                                                                                                                                                                         |
| 848 |    178.674177 |    334.244146 | Collin Gross                                                                                                                                                                         |
| 849 |    178.787588 |     86.786937 | Michelle Site                                                                                                                                                                        |
| 850 |    293.298187 |    700.095503 | Zimices                                                                                                                                                                              |
| 851 |    930.128798 |    387.385605 | T. Michael Keesey                                                                                                                                                                    |
| 852 |    699.485151 |    579.302615 | Chris huh                                                                                                                                                                            |
| 853 |    774.361674 |    553.957673 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                                          |
| 854 |    990.404027 |     55.345999 | Matt Martyniuk                                                                                                                                                                       |
| 855 |    319.975040 |    676.390570 | Aadx                                                                                                                                                                                 |
| 856 |   1017.151302 |    317.648706 | Andy Wilson                                                                                                                                                                          |
| 857 |    643.926665 |    761.909313 | Christoph Schomburg                                                                                                                                                                  |
| 858 |    195.692732 |    104.981034 | Mali’o Kodis, photograph by Bruno Vellutini                                                                                                                                          |
| 859 |     42.703682 |    103.403671 | Noah Schlottman                                                                                                                                                                      |
| 860 |    621.404467 |    581.326645 | Pollyanna von Knorring and T. Michael Keesey                                                                                                                                         |
| 861 |    637.610524 |    341.325758 | Margot Michaud                                                                                                                                                                       |
| 862 |    442.029394 |    142.115317 | Matt Crook                                                                                                                                                                           |
| 863 |    702.017062 |    174.828876 | Gareth Monger                                                                                                                                                                        |
| 864 |    644.363255 |    585.104967 | Fcb981 (vectorized by T. Michael Keesey)                                                                                                                                             |
| 865 |    932.993101 |    684.740082 | Tracy A. Heath                                                                                                                                                                       |
| 866 |    438.087938 |    789.328866 | NA                                                                                                                                                                                   |
| 867 |    237.197122 |    463.303132 | Sergio A. Muñoz-Gómez                                                                                                                                                                |
| 868 |     67.834119 |    202.769602 | Margot Michaud                                                                                                                                                                       |
| 869 |    605.644738 |    580.589205 | Rene Martin                                                                                                                                                                          |
| 870 |   1003.529971 |    262.293031 | Matt Crook                                                                                                                                                                           |
| 871 |    221.727651 |    174.795922 | Markus A. Grohme                                                                                                                                                                     |
| 872 |    179.638250 |    201.073053 | Ieuan Jones                                                                                                                                                                          |
| 873 |     39.631989 |    740.832798 | Jagged Fang Designs                                                                                                                                                                  |
| 874 |    835.869281 |    107.445966 | Markus A. Grohme                                                                                                                                                                     |
| 875 |     39.097662 |    372.631775 | Caleb M. Gordon                                                                                                                                                                      |
| 876 |    758.874167 |    483.252752 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 877 |    929.879015 |    485.136779 | Mette Aumala                                                                                                                                                                         |
| 878 |    894.057929 |    140.714376 | Noah Schlottman, photo by Casey Dunn                                                                                                                                                 |
| 879 |    700.152787 |    539.520594 | Dean Schnabel                                                                                                                                                                        |
| 880 |    601.080016 |    756.453422 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 881 |    894.999781 |    128.430444 | NA                                                                                                                                                                                   |
| 882 |    129.056554 |    448.365497 | Rafael Maia                                                                                                                                                                          |
| 883 |    818.852333 |    390.335223 | Zimices                                                                                                                                                                              |
| 884 |    201.330261 |    195.203965 | Maija Karala                                                                                                                                                                         |
| 885 |    482.712820 |     40.235359 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 886 |    356.595990 |    779.263005 | Zimices                                                                                                                                                                              |
| 887 |    830.546324 |     31.747332 | Josefine Bohr Brask                                                                                                                                                                  |
| 888 |    759.045948 |    725.409984 | Steven Traver                                                                                                                                                                        |
| 889 |    356.148583 |    541.190568 | Gareth Monger                                                                                                                                                                        |
| 890 |    965.792023 |     90.356782 | David Orr                                                                                                                                                                            |
| 891 |    275.237160 |     55.271569 | Chris huh                                                                                                                                                                            |
| 892 |     86.295396 |    535.503234 | Margot Michaud                                                                                                                                                                       |
| 893 |    487.812429 |     88.996932 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 894 |    954.395030 |    471.272273 | Chris huh                                                                                                                                                                            |
| 895 |    728.619555 |    558.623524 | Zimices                                                                                                                                                                              |
| 896 |    276.143583 |    784.794020 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 897 |    718.316585 |    742.312435 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                                        |
| 898 |    329.401770 |    730.339956 | Markus A. Grohme                                                                                                                                                                     |
| 899 |    358.115939 |    657.186375 | Jake Warner                                                                                                                                                                          |
| 900 |    616.163411 |    408.048298 | Matt Crook                                                                                                                                                                           |
| 901 |    675.296657 |    470.634305 | NA                                                                                                                                                                                   |
| 902 |    392.024101 |    389.999745 | NA                                                                                                                                                                                   |
| 903 |    484.460798 |     52.939483 | Gareth Monger                                                                                                                                                                        |
| 904 |     98.961553 |    541.856096 | Sarah Werning                                                                                                                                                                        |
| 905 |    201.910654 |    504.573926 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 906 |    419.509673 |    418.945045 | NA                                                                                                                                                                                   |
| 907 |    502.196636 |    136.527132 | Rene Martin                                                                                                                                                                          |
| 908 |    939.291211 |    153.925679 | NA                                                                                                                                                                                   |
| 909 |    882.698465 |    372.360071 | I. Geoffroy Saint-Hilaire (vectorized by T. Michael Keesey)                                                                                                                          |
| 910 |    865.654005 |     16.448757 | Margot Michaud                                                                                                                                                                       |
| 911 |    449.772546 |    765.887821 | Zimices                                                                                                                                                                              |
| 912 |    742.415752 |    378.797498 | wsnaccad                                                                                                                                                                             |
| 913 |    558.485657 |    390.510696 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey)                |
| 914 |    995.507203 |    326.860159 | Matt Crook                                                                                                                                                                           |

    #> Your tweet has been posted!
