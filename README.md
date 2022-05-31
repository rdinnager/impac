
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

Andy Wilson, Chris huh, Adam Stuart Smith (vectorized by T. Michael
Keesey), Anthony Caravaggi, Michelle Site, Zimices, based in Mauricio
Antón skeletal, Nina Skinner, Diana Pomeroy, Gabriela Palomo-Munoz,
Ferran Sayol, Margot Michaud, Jaime Headden, Robert Bruce Horsfall
(vectorized by T. Michael Keesey), Matt Crook, Zimices, Christoph
Schomburg, Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob
Slotow (vectorized by T. Michael Keesey), B. Duygu Özpolat, Scott
Hartman, M. Antonio Todaro, Tobias Kånneby, Matteo Dal Zotto, and Ulf
Jondelius (vectorized by T. Michael Keesey), Gareth Monger, T. Michael
Keesey, Agnello Picorelli, Jagged Fang Designs, Tasman Dixon, Alexandre
Vong, Martin Kevil, Carlos Cano-Barbacil, Francesca Belem Lopes
Palmeira, M Kolmann, Nobu Tamura (vectorized by T. Michael Keesey),
Sarah Werning, Steven Traver, Michael Scroggie, Caleb M. Brown, Timothy
Knepp (vectorized by T. Michael Keesey), Steven Coombs (vectorized by T.
Michael Keesey), Smokeybjb, Stanton F. Fink (vectorized by T. Michael
Keesey), Tracy A. Heath, Markus A. Grohme, Maxwell Lefroy (vectorized by
T. Michael Keesey), Mette Aumala, Gabriel Lio, vectorized by Zimices,
Robert Gay, Tauana J. Cunha, Conty (vectorized by T. Michael Keesey),
Collin Gross, Lukasiniho, Armelle Ansart (photograph), Maxime Dahirel
(digitisation), ДиБгд (vectorized by T. Michael Keesey), Mali’o Kodis,
photograph by Bruno Vellutini, Mattia Menchetti, Jakovche, Melissa
Broussard, Darius Nau, Alex Slavenko, CNZdenek, Dean Schnabel, Enoch
Joseph Wetsy (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Matt Dempsey, Derek Bakken (photograph) and T. Michael
Keesey (vectorization), C. Camilo Julián-Caballero, Noah Schlottman,
Steven Coombs, Tambja (vectorized by T. Michael Keesey), Nancy Wyman
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, T. Michael Keesey (from a photo by Maximilian Paradiz), Y. de
Hoev. (vectorized by T. Michael Keesey), Martin R. Smith, Becky Barnes,
Dmitry Bogdanov (vectorized by T. Michael Keesey), Roule Jammes
(vectorized by T. Michael Keesey), George Edward Lodge, Matt Martyniuk,
Falconaumanni and T. Michael Keesey, Andrew A. Farke, David Sim
(photograph) and T. Michael Keesey (vectorization), Birgit Lang, Emily
Willoughby, Sebastian Stabinger, Iain Reid, Xavier Giroux-Bougard, Maija
Karala, Rebecca Groom, John Conway, Mali’o Kodis, photograph by Derek
Keats (<http://www.flickr.com/photos/dkeats/>), AnAgnosticGod
(vectorized by T. Michael Keesey), Kamil S. Jaron, James Neenan, Didier
Descouens (vectorized by T. Michael Keesey), Chris Hay, Erika
Schumacher, Chase Brownstein, Nobu Tamura, vectorized by Zimices, Emma
Kissling, FunkMonk, Nobu Tamura, Campbell Fleming, Jose Carlos
Arenas-Monroy, Brad McFeeters (vectorized by T. Michael Keesey), Mareike
C. Janiak, Chuanixn Yu, Joanna Wolfe, Roderic Page and Lois Page,
Smokeybjb (vectorized by T. Michael Keesey), Juan Carlos Jerí, Ignacio
Contreras, Beth Reinke, Riccardo Percudani, Alan Manson (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Lankester Edwin
Ray (vectorized by T. Michael Keesey), C. W. Nash (illustration) and
Timothy J. Bartley (silhouette), Dmitry Bogdanov, Pranav Iyer (grey
ideas), Tony Ayling (vectorized by T. Michael Keesey), Xvazquez
(vectorized by William Gearty), Tim Bertelink (modified by T. Michael
Keesey), Caleb Brown, Neil Kelley, T. Michael Keesey (after
Ponomarenko), John Curtis (vectorized by T. Michael Keesey), H. F. O.
March (modified by T. Michael Keesey, Michael P. Taylor & Matthew J.
Wedel), Mali’o Kodis, image by Rebecca Ritger, Michael Scroggie, from
original photograph by Gary M. Stolz, USFWS (original photograph in
public domain)., Rene Martin, E. J. Van Nieukerken, A. Laštůvka, and Z.
Laštůvka (vectorized by T. Michael Keesey), Noah Schlottman, photo from
Casey Dunn, Ricardo N. Martinez & Oscar A. Alcober, Haplochromis
(vectorized by T. Michael Keesey), James R. Spotila and Ray Chatterji,
Mo Hassan, T. Michael Keesey (after James & al.), Kai R. Caspar, Ingo
Braasch, Bryan Carstens, Sergio A. Muñoz-Gómez, Darren Naish (vectorized
by T. Michael Keesey), Diego Fontaneto, Elisabeth A. Herniou, Chiara
Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy
G. Barraclough (vectorized by T. Michael Keesey), Catherine Yasuda,
Alexandra van der Geer, Dexter R. Mardis, Ghedoghedo (vectorized by T.
Michael Keesey), I. Geoffroy Saint-Hilaire (vectorized by T. Michael
Keesey), Noah Schlottman, photo by Antonio Guillén, Ghedoghedo,
vectorized by Zimices, Henry Lydecker, Armin Reindl, Jonathan Wells, Yan
Wong, Smith609 and T. Michael Keesey, Sam Droege (photography) and T.
Michael Keesey (vectorization), Tyler McCraney, Noah Schlottman, photo
by Martin V. Sørensen, Pete Buchholz, Jiekun He, Tyler Greenfield,
Smokeybjb (modified by Mike Keesey), Apokryltaros (vectorized by T.
Michael Keesey), , Duane Raver (vectorized by T. Michael Keesey), Matus
Valach, Mattia Menchetti / Yan Wong, Verisimilus, Shyamal, Abraão Leite,
Manabu Bessho-Uehara, L. Shyamal, . Original drawing by M. Antón,
published in Montoya and Morales 1984. Vectorized by O. Sanisidro,
Rebecca Groom (Based on Photo by Andreas Trepte), Robert Gay, modified
from FunkMonk (Michael B.H.) and T. Michael Keesey., Julia B McHugh,
Anna Willoughby, Stephen O’Connor (vectorized by T. Michael Keesey),
Lisa M. “Pixxl” (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, David Orr, T. Michael Keesey (vector) and Stuart
Halliday (photograph), Felix Vaux, Blanco et al., 2014, vectorized by
Zimices, Ville-Veikko Sinkkonen, Zsoldos Márton (vectorized by T.
Michael Keesey), Kanako Bessho-Uehara, Noah Schlottman, photo by Museum
of Geology, University of Tartu, Giant Blue Anteater (vectorized by T.
Michael Keesey), Mathew Wedel, Michele M Tobias, Bennet McComish, photo
by Avenue, Michael P. Taylor, T. Michael Keesey (from a mount by Allis
Markham), Rainer Schoch, Roberto Díaz Sibaja

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |     408.10925 |    273.424585 | Andy Wilson                                                                                                                                                           |
|   2 |     679.02124 |    542.154587 | Chris huh                                                                                                                                                             |
|   3 |     420.49472 |    580.936075 | Adam Stuart Smith (vectorized by T. Michael Keesey)                                                                                                                   |
|   4 |     799.80371 |    419.958826 | Anthony Caravaggi                                                                                                                                                     |
|   5 |     964.51353 |    627.245188 | Michelle Site                                                                                                                                                         |
|   6 |     684.01643 |    177.381473 | Michelle Site                                                                                                                                                         |
|   7 |      91.97995 |    324.367190 | Zimices, based in Mauricio Antón skeletal                                                                                                                             |
|   8 |     698.98309 |    757.098288 | Nina Skinner                                                                                                                                                          |
|   9 |     778.70874 |    298.340716 | Diana Pomeroy                                                                                                                                                         |
|  10 |     254.71838 |    541.024425 | NA                                                                                                                                                                    |
|  11 |     680.00553 |    438.945905 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  12 |     822.74006 |    598.926239 | NA                                                                                                                                                                    |
|  13 |     939.66453 |    422.279960 | Ferran Sayol                                                                                                                                                          |
|  14 |     622.17896 |    644.136855 | Margot Michaud                                                                                                                                                        |
|  15 |     205.21780 |     49.190588 | Jaime Headden                                                                                                                                                         |
|  16 |     126.48009 |    445.830699 | Robert Bruce Horsfall (vectorized by T. Michael Keesey)                                                                                                               |
|  17 |     305.05686 |     65.941861 | Margot Michaud                                                                                                                                                        |
|  18 |     221.11830 |    355.013311 | Matt Crook                                                                                                                                                            |
|  19 |     818.61385 |    111.269614 | NA                                                                                                                                                                    |
|  20 |     559.19911 |    569.303977 | Margot Michaud                                                                                                                                                        |
|  21 |     550.06132 |    363.843143 | Zimices                                                                                                                                                               |
|  22 |     385.50289 |    482.920098 | Christoph Schomburg                                                                                                                                                   |
|  23 |     430.62304 |    759.646553 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
|  24 |     941.45440 |    279.707497 | B. Duygu Özpolat                                                                                                                                                      |
|  25 |     127.95127 |    754.772193 | Scott Hartman                                                                                                                                                         |
|  26 |      94.49785 |    119.024760 | M. Antonio Todaro, Tobias Kånneby, Matteo Dal Zotto, and Ulf Jondelius (vectorized by T. Michael Keesey)                                                              |
|  27 |     926.09725 |    175.155658 | Gareth Monger                                                                                                                                                         |
|  28 |     530.98189 |     38.736878 | T. Michael Keesey                                                                                                                                                     |
|  29 |     517.39451 |    663.538556 | Matt Crook                                                                                                                                                            |
|  30 |     293.06131 |    406.595923 | Scott Hartman                                                                                                                                                         |
|  31 |     178.41714 |    250.849847 | Agnello Picorelli                                                                                                                                                     |
|  32 |      63.69148 |    535.729100 | Andy Wilson                                                                                                                                                           |
|  33 |     507.04536 |    466.373026 | Jagged Fang Designs                                                                                                                                                   |
|  34 |     323.02841 |    674.475513 | Tasman Dixon                                                                                                                                                          |
|  35 |     129.97882 |    633.516381 | Alexandre Vong                                                                                                                                                        |
|  36 |     963.17561 |     75.720829 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  37 |     318.10419 |    741.242612 | Martin Kevil                                                                                                                                                          |
|  38 |     561.75409 |    758.708144 | NA                                                                                                                                                                    |
|  39 |     607.46271 |    224.371013 | Carlos Cano-Barbacil                                                                                                                                                  |
|  40 |     415.78998 |     64.453817 | Francesca Belem Lopes Palmeira                                                                                                                                        |
|  41 |     727.13542 |    698.245266 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
|  42 |     864.29882 |    699.401922 | M Kolmann                                                                                                                                                             |
|  43 |      29.78393 |    696.444726 | T. Michael Keesey                                                                                                                                                     |
|  44 |     633.30387 |    509.245176 | Zimices                                                                                                                                                               |
|  45 |      84.49244 |    184.485403 | Jagged Fang Designs                                                                                                                                                   |
|  46 |     706.60175 |     53.031418 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  47 |     109.52844 |     58.224423 | Sarah Werning                                                                                                                                                         |
|  48 |     639.81945 |    336.107375 | Andy Wilson                                                                                                                                                           |
|  49 |     818.76810 |    760.350778 | Steven Traver                                                                                                                                                         |
|  50 |     180.04855 |    548.662572 | Michael Scroggie                                                                                                                                                      |
|  51 |     816.72926 |    202.542104 | Matt Crook                                                                                                                                                            |
|  52 |     339.46422 |    116.569745 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  53 |     380.76003 |     24.948765 | Caleb M. Brown                                                                                                                                                        |
|  54 |     928.56040 |    340.979169 | Timothy Knepp (vectorized by T. Michael Keesey)                                                                                                                       |
|  55 |     947.98845 |    531.977183 | NA                                                                                                                                                                    |
|  56 |     612.12599 |    105.652002 | Steven Coombs (vectorized by T. Michael Keesey)                                                                                                                       |
|  57 |     901.97620 |    381.799243 | Smokeybjb                                                                                                                                                             |
|  58 |     884.46810 |     30.326600 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                     |
|  59 |     154.60054 |    703.732314 | Zimices                                                                                                                                                               |
|  60 |     944.96989 |    746.835074 | Tracy A. Heath                                                                                                                                                        |
|  61 |     259.41394 |    687.379442 | Tasman Dixon                                                                                                                                                          |
|  62 |     611.06309 |    717.085890 | Markus A. Grohme                                                                                                                                                      |
|  63 |      65.13146 |    240.538120 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                      |
|  64 |     669.98205 |    591.628371 | Mette Aumala                                                                                                                                                          |
|  65 |     796.30437 |    500.537419 | NA                                                                                                                                                                    |
|  66 |     607.03928 |     39.992037 | NA                                                                                                                                                                    |
|  67 |     585.27306 |    791.250003 | Smokeybjb                                                                                                                                                             |
|  68 |     750.79615 |    177.757091 | Gabriel Lio, vectorized by Zimices                                                                                                                                    |
|  69 |     203.90626 |    770.133191 | Robert Gay                                                                                                                                                            |
|  70 |     981.38666 |    490.292407 | Matt Crook                                                                                                                                                            |
|  71 |     560.28301 |    407.093576 | Markus A. Grohme                                                                                                                                                      |
|  72 |     422.59307 |    602.833133 | Tauana J. Cunha                                                                                                                                                       |
|  73 |     724.94603 |    107.076886 | NA                                                                                                                                                                    |
|  74 |     159.23064 |    519.971996 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
|  75 |     983.28096 |    699.918801 | Collin Gross                                                                                                                                                          |
|  76 |      50.51959 |    619.398446 | Lukasiniho                                                                                                                                                            |
|  77 |     102.62424 |    569.033522 | Ferran Sayol                                                                                                                                                          |
|  78 |      21.46368 |    279.390157 | M Kolmann                                                                                                                                                             |
|  79 |     449.11996 |    351.349933 | NA                                                                                                                                                                    |
|  80 |      43.62244 |    376.854653 | Steven Traver                                                                                                                                                         |
|  81 |     693.95127 |    379.792561 | NA                                                                                                                                                                    |
|  82 |    1000.32890 |    425.140925 | Armelle Ansart (photograph), Maxime Dahirel (digitisation)                                                                                                            |
|  83 |     268.59360 |    776.521532 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  84 |     330.47498 |    619.717687 | Zimices                                                                                                                                                               |
|  85 |     610.72898 |    738.037023 | Carlos Cano-Barbacil                                                                                                                                                  |
|  86 |     101.67195 |    204.552435 | Margot Michaud                                                                                                                                                        |
|  87 |     579.83321 |    265.335053 | Margot Michaud                                                                                                                                                        |
|  88 |     353.24771 |    782.232253 | ДиБгд (vectorized by T. Michael Keesey)                                                                                                                               |
|  89 |      35.24790 |     34.095222 | Gareth Monger                                                                                                                                                         |
|  90 |     822.96386 |    178.859377 | Mali’o Kodis, photograph by Bruno Vellutini                                                                                                                           |
|  91 |     314.11402 |    453.967049 | Mette Aumala                                                                                                                                                          |
|  92 |     116.52267 |    384.550414 | Mattia Menchetti                                                                                                                                                      |
|  93 |     546.77759 |    308.819927 | B. Duygu Özpolat                                                                                                                                                      |
|  94 |      35.47707 |     76.630216 | Jakovche                                                                                                                                                              |
|  95 |      33.41370 |    452.842441 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  96 |     325.34692 |    367.100190 | Melissa Broussard                                                                                                                                                     |
|  97 |     289.27886 |     23.745874 | Darius Nau                                                                                                                                                            |
|  98 |     550.76084 |    430.736549 | NA                                                                                                                                                                    |
|  99 |     980.44052 |    180.431689 | Alex Slavenko                                                                                                                                                         |
| 100 |     612.42217 |    778.599315 | Smokeybjb                                                                                                                                                             |
| 101 |     166.33704 |     26.947586 | CNZdenek                                                                                                                                                              |
| 102 |     203.26332 |    437.382452 | Dean Schnabel                                                                                                                                                         |
| 103 |     479.44269 |    605.914343 | Enoch Joseph Wetsy (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey    |
| 104 |     974.24614 |    207.653764 | Jagged Fang Designs                                                                                                                                                   |
| 105 |     419.38780 |    669.515410 | Jagged Fang Designs                                                                                                                                                   |
| 106 |     780.03718 |     16.547313 | Matt Dempsey                                                                                                                                                          |
| 107 |     502.23772 |     87.939970 | Scott Hartman                                                                                                                                                         |
| 108 |     906.32301 |    181.554274 | Derek Bakken (photograph) and T. Michael Keesey (vectorization)                                                                                                       |
| 109 |     545.19836 |    489.066632 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 110 |      66.31567 |    255.274121 | C. Camilo Julián-Caballero                                                                                                                                            |
| 111 |     555.07334 |     77.138333 | Gareth Monger                                                                                                                                                         |
| 112 |      79.40595 |    293.863854 | Noah Schlottman                                                                                                                                                       |
| 113 |     744.14684 |    552.400069 | Steven Coombs                                                                                                                                                         |
| 114 |     418.94896 |    461.216620 | Tambja (vectorized by T. Michael Keesey)                                                                                                                              |
| 115 |     512.62535 |    619.969252 | Matt Crook                                                                                                                                                            |
| 116 |     299.72810 |    480.719572 | Nancy Wyman (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
| 117 |     370.95579 |    706.039275 | Margot Michaud                                                                                                                                                        |
| 118 |     159.35701 |    153.927808 | T. Michael Keesey (from a photo by Maximilian Paradiz)                                                                                                                |
| 119 |     119.39530 |    147.305746 | NA                                                                                                                                                                    |
| 120 |     840.74374 |    392.731179 | Y. de Hoev. (vectorized by T. Michael Keesey)                                                                                                                         |
| 121 |     942.80643 |    239.116970 | Matt Crook                                                                                                                                                            |
| 122 |     383.11244 |    664.422926 | Martin R. Smith                                                                                                                                                       |
| 123 |     457.12613 |    422.047802 | Becky Barnes                                                                                                                                                          |
| 124 |     286.68237 |    335.794272 | Matt Crook                                                                                                                                                            |
| 125 |     428.37918 |      6.704300 | Jagged Fang Designs                                                                                                                                                   |
| 126 |     552.05462 |    607.247776 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 127 |      82.09661 |    788.113541 | NA                                                                                                                                                                    |
| 128 |     870.23194 |    401.509921 | Zimices                                                                                                                                                               |
| 129 |     786.88450 |    190.261449 | Matt Crook                                                                                                                                                            |
| 130 |     868.94703 |    451.624051 | CNZdenek                                                                                                                                                              |
| 131 |     251.98227 |     79.763126 | Roule Jammes (vectorized by T. Michael Keesey)                                                                                                                        |
| 132 |      26.27696 |    201.060136 | Scott Hartman                                                                                                                                                         |
| 133 |     180.07391 |    176.640325 | Matt Crook                                                                                                                                                            |
| 134 |     752.37949 |    567.706095 | C. Camilo Julián-Caballero                                                                                                                                            |
| 135 |     723.33653 |    648.247490 | Margot Michaud                                                                                                                                                        |
| 136 |     427.83965 |    688.400867 | George Edward Lodge                                                                                                                                                   |
| 137 |      19.27718 |    493.915269 | Matt Crook                                                                                                                                                            |
| 138 |     754.49640 |    619.444790 | Gareth Monger                                                                                                                                                         |
| 139 |     261.29574 |    366.082909 | Matt Martyniuk                                                                                                                                                        |
| 140 |     529.35589 |    512.182773 | Falconaumanni and T. Michael Keesey                                                                                                                                   |
| 141 |     984.60272 |    162.084491 | Carlos Cano-Barbacil                                                                                                                                                  |
| 142 |      16.79471 |    164.436139 | Andrew A. Farke                                                                                                                                                       |
| 143 |     554.32346 |    525.574791 | David Sim (photograph) and T. Michael Keesey (vectorization)                                                                                                          |
| 144 |     971.77895 |    299.549141 | Birgit Lang                                                                                                                                                           |
| 145 |     501.90796 |    435.461244 | Emily Willoughby                                                                                                                                                      |
| 146 |      41.00462 |    145.818334 | Sebastian Stabinger                                                                                                                                                   |
| 147 |     634.86803 |    257.826559 | Iain Reid                                                                                                                                                             |
| 148 |     759.38465 |    223.952958 | Jagged Fang Designs                                                                                                                                                   |
| 149 |      19.05176 |    321.708338 | Scott Hartman                                                                                                                                                         |
| 150 |     358.59288 |    392.547761 | Ferran Sayol                                                                                                                                                          |
| 151 |      16.06549 |    518.942425 | Chris huh                                                                                                                                                             |
| 152 |     492.71754 |    316.301019 | Zimices                                                                                                                                                               |
| 153 |     571.48294 |    174.177005 | NA                                                                                                                                                                    |
| 154 |     415.89454 |     94.113113 | NA                                                                                                                                                                    |
| 155 |     163.74456 |    326.292140 | Xavier Giroux-Bougard                                                                                                                                                 |
| 156 |      26.10165 |    341.391702 | Maija Karala                                                                                                                                                          |
| 157 |     633.50466 |    685.538293 | Margot Michaud                                                                                                                                                        |
| 158 |     909.30882 |    260.838909 | Rebecca Groom                                                                                                                                                         |
| 159 |     198.89426 |    150.316930 | Alex Slavenko                                                                                                                                                         |
| 160 |      34.84152 |      8.742975 | Iain Reid                                                                                                                                                             |
| 161 |     338.30342 |    146.937605 | John Conway                                                                                                                                                           |
| 162 |     516.06373 |    734.456092 | Mali’o Kodis, photograph by Derek Keats (<http://www.flickr.com/photos/dkeats/>)                                                                                      |
| 163 |     422.02071 |    442.760618 | Matt Crook                                                                                                                                                            |
| 164 |     997.15960 |    669.459270 | Zimices                                                                                                                                                               |
| 165 |     971.43413 |    314.897716 | Steven Traver                                                                                                                                                         |
| 166 |     113.86900 |    491.841197 | AnAgnosticGod (vectorized by T. Michael Keesey)                                                                                                                       |
| 167 |     522.27245 |    568.807540 | Kamil S. Jaron                                                                                                                                                        |
| 168 |      87.85107 |    716.351383 | James Neenan                                                                                                                                                          |
| 169 |     154.93121 |    788.050709 | Michelle Site                                                                                                                                                         |
| 170 |     604.40573 |    443.789066 | M. Antonio Todaro, Tobias Kånneby, Matteo Dal Zotto, and Ulf Jondelius (vectorized by T. Michael Keesey)                                                              |
| 171 |     214.21819 |    322.681148 | Matt Crook                                                                                                                                                            |
| 172 |     606.25740 |    187.884443 | Xavier Giroux-Bougard                                                                                                                                                 |
| 173 |      71.06196 |    748.537563 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 174 |      99.88080 |    648.275652 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 175 |     675.25655 |     17.394171 | Chris huh                                                                                                                                                             |
| 176 |     338.15907 |    648.053902 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 177 |      34.93373 |    570.178198 | Ferran Sayol                                                                                                                                                          |
| 178 |     473.21408 |    505.243973 | Margot Michaud                                                                                                                                                        |
| 179 |     471.52773 |    621.756869 | T. Michael Keesey                                                                                                                                                     |
| 180 |      14.35892 |    592.812119 | Margot Michaud                                                                                                                                                        |
| 181 |     777.27123 |    786.204441 | Chris Hay                                                                                                                                                             |
| 182 |     833.08362 |    374.274622 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 183 |     116.41304 |     79.926660 | Erika Schumacher                                                                                                                                                      |
| 184 |     204.55930 |    201.955897 | Gareth Monger                                                                                                                                                         |
| 185 |     738.43407 |     93.030495 | Zimices                                                                                                                                                               |
| 186 |     169.04884 |    104.865737 | Chase Brownstein                                                                                                                                                      |
| 187 |     250.08618 |    104.477295 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 188 |     651.76046 |    186.164699 | Margot Michaud                                                                                                                                                        |
| 189 |     691.83158 |    622.351836 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 190 |      45.07018 |    769.589202 | Emma Kissling                                                                                                                                                         |
| 191 |     609.13048 |    409.820226 | CNZdenek                                                                                                                                                              |
| 192 |     224.04789 |    747.731672 | FunkMonk                                                                                                                                                              |
| 193 |     664.03660 |    269.194170 | Gareth Monger                                                                                                                                                         |
| 194 |     732.33491 |    671.314787 | Nobu Tamura                                                                                                                                                           |
| 195 |     320.63358 |    561.035978 | NA                                                                                                                                                                    |
| 196 |     714.19064 |    350.708000 | Zimices                                                                                                                                                               |
| 197 |     708.95896 |    151.153701 | Campbell Fleming                                                                                                                                                      |
| 198 |     733.33898 |    785.771747 | Tasman Dixon                                                                                                                                                          |
| 199 |      75.87627 |     12.186432 | T. Michael Keesey                                                                                                                                                     |
| 200 |      71.10917 |    687.802302 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 201 |     442.58564 |    712.934851 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 202 |     694.74690 |    242.299803 | Michael Scroggie                                                                                                                                                      |
| 203 |     766.86705 |    372.191264 | Mareike C. Janiak                                                                                                                                                     |
| 204 |      67.00711 |    148.010308 | Scott Hartman                                                                                                                                                         |
| 205 |     729.55437 |    409.668353 | Gareth Monger                                                                                                                                                         |
| 206 |     644.25455 |    596.361515 | Chuanixn Yu                                                                                                                                                           |
| 207 |     582.36609 |    522.559539 | Zimices                                                                                                                                                               |
| 208 |    1002.23809 |    311.306533 | Ferran Sayol                                                                                                                                                          |
| 209 |     671.29053 |    227.644109 | Joanna Wolfe                                                                                                                                                          |
| 210 |     179.52677 |    498.498097 | Roderic Page and Lois Page                                                                                                                                            |
| 211 |      87.10971 |    604.460760 | Ferran Sayol                                                                                                                                                          |
| 212 |     964.08046 |    118.398334 | NA                                                                                                                                                                    |
| 213 |      15.56715 |    412.130813 | Christoph Schomburg                                                                                                                                                   |
| 214 |      63.96804 |    486.338831 | T. Michael Keesey                                                                                                                                                     |
| 215 |     229.49532 |    646.346237 | Rebecca Groom                                                                                                                                                         |
| 216 |     735.72870 |    618.684390 | Maija Karala                                                                                                                                                          |
| 217 |     619.99003 |    152.940037 | Birgit Lang                                                                                                                                                           |
| 218 |     896.24799 |    598.988979 | Ferran Sayol                                                                                                                                                          |
| 219 |     969.73904 |     12.525840 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                           |
| 220 |     584.35141 |    471.599567 | NA                                                                                                                                                                    |
| 221 |     711.61485 |    413.519722 | Jagged Fang Designs                                                                                                                                                   |
| 222 |     913.84989 |    679.378174 | Gareth Monger                                                                                                                                                         |
| 223 |     883.00420 |    714.280437 | Juan Carlos Jerí                                                                                                                                                      |
| 224 |     832.78927 |    790.045104 | Chris huh                                                                                                                                                             |
| 225 |     984.69341 |    240.456370 | T. Michael Keesey                                                                                                                                                     |
| 226 |     180.91305 |    659.916776 | Ignacio Contreras                                                                                                                                                     |
| 227 |     685.41252 |    345.281077 | Beth Reinke                                                                                                                                                           |
| 228 |     605.72707 |    341.481998 | Andrew A. Farke                                                                                                                                                       |
| 229 |     520.95267 |    785.384301 | Iain Reid                                                                                                                                                             |
| 230 |     886.30643 |    216.699320 | Sarah Werning                                                                                                                                                         |
| 231 |     887.61321 |    328.069560 | Gareth Monger                                                                                                                                                         |
| 232 |     875.52788 |    679.869680 | Gareth Monger                                                                                                                                                         |
| 233 |     734.77217 |    368.162439 | Riccardo Percudani                                                                                                                                                    |
| 234 |     719.93111 |    485.281943 | Joanna Wolfe                                                                                                                                                          |
| 235 |     587.25255 |    684.031070 | NA                                                                                                                                                                    |
| 236 |     679.31270 |    684.668691 | Matt Crook                                                                                                                                                            |
| 237 |     135.50052 |     91.216619 | Iain Reid                                                                                                                                                             |
| 238 |     914.54764 |    613.899473 | Alan Manson (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
| 239 |     971.56614 |     26.652241 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                                 |
| 240 |     225.43025 |    191.064602 | Steven Traver                                                                                                                                                         |
| 241 |      53.72466 |    796.562775 | Gareth Monger                                                                                                                                                         |
| 242 |    1014.13373 |    203.036635 | Gareth Monger                                                                                                                                                         |
| 243 |     839.14131 |    714.357379 | C. W. Nash (illustration) and Timothy J. Bartley (silhouette)                                                                                                         |
| 244 |     272.44402 |    712.417893 | Dmitry Bogdanov                                                                                                                                                       |
| 245 |     833.51864 |    224.290936 | NA                                                                                                                                                                    |
| 246 |     990.43052 |     27.848001 | Matt Crook                                                                                                                                                            |
| 247 |     602.04551 |    288.511678 | Tasman Dixon                                                                                                                                                          |
| 248 |     259.89503 |    115.501147 | Pranav Iyer (grey ideas)                                                                                                                                              |
| 249 |      20.56453 |    404.909180 | Rebecca Groom                                                                                                                                                         |
| 250 |     870.25946 |    257.042186 | NA                                                                                                                                                                    |
| 251 |     824.90080 |    776.509779 | Scott Hartman                                                                                                                                                         |
| 252 |      19.24679 |    130.807300 | NA                                                                                                                                                                    |
| 253 |     954.42072 |    360.056362 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 254 |     308.65623 |    518.273514 | Xvazquez (vectorized by William Gearty)                                                                                                                               |
| 255 |     398.41734 |    694.794607 | Iain Reid                                                                                                                                                             |
| 256 |     587.74299 |    700.532820 | Tim Bertelink (modified by T. Michael Keesey)                                                                                                                         |
| 257 |     147.07086 |    374.742789 | Gareth Monger                                                                                                                                                         |
| 258 |     754.35671 |    468.683242 | Andy Wilson                                                                                                                                                           |
| 259 |     921.67077 |    321.274031 | Caleb Brown                                                                                                                                                           |
| 260 |      95.07261 |    666.898933 | Neil Kelley                                                                                                                                                           |
| 261 |    1008.46814 |    622.731522 | Zimices                                                                                                                                                               |
| 262 |     613.71274 |    476.885351 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 263 |     386.78675 |    733.186367 | T. Michael Keesey (after Ponomarenko)                                                                                                                                 |
| 264 |     894.90752 |    653.978803 | Zimices                                                                                                                                                               |
| 265 |     843.11669 |     10.051697 | Zimices                                                                                                                                                               |
| 266 |    1006.92483 |    563.612210 | John Curtis (vectorized by T. Michael Keesey)                                                                                                                         |
| 267 |    1009.93484 |    345.146087 | Michelle Site                                                                                                                                                         |
| 268 |     799.73782 |    210.715800 | Ignacio Contreras                                                                                                                                                     |
| 269 |     634.04404 |     79.475385 | Scott Hartman                                                                                                                                                         |
| 270 |     868.85697 |    359.284317 | NA                                                                                                                                                                    |
| 271 |     149.76821 |    766.322410 | Matt Crook                                                                                                                                                            |
| 272 |     750.91848 |    731.821293 | H. F. O. March (modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel)                                                                                  |
| 273 |     917.03205 |     44.592802 | Mali’o Kodis, image by Rebecca Ritger                                                                                                                                 |
| 274 |     742.42255 |    128.904123 | Chuanixn Yu                                                                                                                                                           |
| 275 |     861.03781 |    441.037358 | Jagged Fang Designs                                                                                                                                                   |
| 276 |     208.47838 |     15.206897 | Michael Scroggie, from original photograph by Gary M. Stolz, USFWS (original photograph in public domain).                                                            |
| 277 |     549.25964 |    331.426662 | Rene Martin                                                                                                                                                           |
| 278 |     931.35100 |    568.541013 | Emily Willoughby                                                                                                                                                      |
| 279 |     383.81554 |    140.301104 | Andy Wilson                                                                                                                                                           |
| 280 |      36.89075 |     53.693623 | Tasman Dixon                                                                                                                                                          |
| 281 |     467.35790 |     21.161901 | Jagged Fang Designs                                                                                                                                                   |
| 282 |     314.10024 |    492.417098 | E. J. Van Nieukerken, A. Laštůvka, and Z. Laštůvka (vectorized by T. Michael Keesey)                                                                                  |
| 283 |     239.87130 |    734.342467 | Emily Willoughby                                                                                                                                                      |
| 284 |     796.28114 |    243.036804 | Markus A. Grohme                                                                                                                                                      |
| 285 |     884.10270 |    497.330825 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 286 |     104.05932 |    281.939319 | Ferran Sayol                                                                                                                                                          |
| 287 |     288.76558 |    630.496032 | Noah Schlottman, photo from Casey Dunn                                                                                                                                |
| 288 |     314.08641 |    160.673135 | Tasman Dixon                                                                                                                                                          |
| 289 |     545.33976 |    265.081004 | Andy Wilson                                                                                                                                                           |
| 290 |     730.02695 |    385.751551 | Gareth Monger                                                                                                                                                         |
| 291 |     708.03819 |     19.264104 | Ricardo N. Martinez & Oscar A. Alcober                                                                                                                                |
| 292 |     560.77064 |     94.619074 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                        |
| 293 |     488.43560 |    573.036275 | James R. Spotila and Ray Chatterji                                                                                                                                    |
| 294 |     230.67732 |    449.274338 | Emily Willoughby                                                                                                                                                      |
| 295 |     891.89456 |    106.988883 | Matt Crook                                                                                                                                                            |
| 296 |     876.50053 |    479.610746 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 297 |     858.77477 |    419.390935 | Lukasiniho                                                                                                                                                            |
| 298 |      11.24556 |    636.540574 | Gareth Monger                                                                                                                                                         |
| 299 |     486.04628 |    374.939560 | Matt Crook                                                                                                                                                            |
| 300 |     716.63815 |    617.133619 | Andy Wilson                                                                                                                                                           |
| 301 |     625.70081 |    460.697063 | Zimices                                                                                                                                                               |
| 302 |     173.21551 |    125.981736 | Mo Hassan                                                                                                                                                             |
| 303 |     640.68822 |     31.122378 | Erika Schumacher                                                                                                                                                      |
| 304 |     188.01463 |    640.238590 | Ferran Sayol                                                                                                                                                          |
| 305 |     964.60445 |    452.778332 | Gareth Monger                                                                                                                                                         |
| 306 |     339.45688 |    663.864465 | T. Michael Keesey (after James & al.)                                                                                                                                 |
| 307 |    1008.47203 |     75.191710 | Jaime Headden                                                                                                                                                         |
| 308 |     497.13154 |    495.504271 | Kai R. Caspar                                                                                                                                                         |
| 309 |     759.33924 |    536.941742 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 310 |     170.83283 |    777.345569 | Ingo Braasch                                                                                                                                                          |
| 311 |     113.34981 |    358.533290 | Bryan Carstens                                                                                                                                                        |
| 312 |     998.10516 |    285.095096 | C. Camilo Julián-Caballero                                                                                                                                            |
| 313 |     771.07446 |    143.810912 | Collin Gross                                                                                                                                                          |
| 314 |     102.57892 |    703.713350 | NA                                                                                                                                                                    |
| 315 |     455.44167 |    681.618960 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 316 |     447.82633 |    580.649791 | Matt Martyniuk                                                                                                                                                        |
| 317 |     990.81501 |    195.677864 | Noah Schlottman                                                                                                                                                       |
| 318 |     547.99821 |    286.366582 | Tasman Dixon                                                                                                                                                          |
| 319 |     893.67074 |     62.122020 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                        |
| 320 |     147.59259 |    490.178584 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 321 |     658.82086 |    681.107743 | Catherine Yasuda                                                                                                                                                      |
| 322 |     100.21962 |    264.238197 | Scott Hartman                                                                                                                                                         |
| 323 |     696.68597 |    783.456482 | Beth Reinke                                                                                                                                                           |
| 324 |     924.31453 |    648.386437 | Gareth Monger                                                                                                                                                         |
| 325 |     738.55534 |    659.668821 | Emily Willoughby                                                                                                                                                      |
| 326 |     524.09489 |    468.980257 | Alexandra van der Geer                                                                                                                                                |
| 327 |     108.97796 |    774.770243 | Chris huh                                                                                                                                                             |
| 328 |     230.59593 |    434.512612 | Dexter R. Mardis                                                                                                                                                      |
| 329 |     277.46659 |    132.947240 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 330 |     148.76942 |    186.676517 | Pranav Iyer (grey ideas)                                                                                                                                              |
| 331 |     669.22110 |    399.682447 | Tracy A. Heath                                                                                                                                                        |
| 332 |     494.51581 |    408.626880 | Iain Reid                                                                                                                                                             |
| 333 |    1007.07717 |      9.428969 | Zimices                                                                                                                                                               |
| 334 |     890.42148 |    756.225339 | Markus A. Grohme                                                                                                                                                      |
| 335 |     287.29524 |    348.170163 | Matt Crook                                                                                                                                                            |
| 336 |     463.00274 |    486.581469 | I. Geoffroy Saint-Hilaire (vectorized by T. Michael Keesey)                                                                                                           |
| 337 |    1008.43431 |    263.992990 | Anthony Caravaggi                                                                                                                                                     |
| 338 |     231.08428 |    304.437209 | NA                                                                                                                                                                    |
| 339 |     820.53811 |     31.471936 | Gareth Monger                                                                                                                                                         |
| 340 |      35.96261 |    782.751836 | Zimices                                                                                                                                                               |
| 341 |     757.06324 |    719.479270 | Noah Schlottman, photo by Antonio Guillén                                                                                                                             |
| 342 |      71.47760 |    272.893718 | Jagged Fang Designs                                                                                                                                                   |
| 343 |     209.39380 |    491.196349 | Margot Michaud                                                                                                                                                        |
| 344 |     831.37637 |    352.769124 | Zimices                                                                                                                                                               |
| 345 |     633.23002 |      8.627217 | Emily Willoughby                                                                                                                                                      |
| 346 |     594.89619 |    161.988588 | Matt Crook                                                                                                                                                            |
| 347 |     135.09875 |    575.868907 | Matt Crook                                                                                                                                                            |
| 348 |     386.49230 |    501.757894 | Steven Traver                                                                                                                                                         |
| 349 |     121.10081 |    531.658661 | Ferran Sayol                                                                                                                                                          |
| 350 |     314.57816 |    714.237692 | Scott Hartman                                                                                                                                                         |
| 351 |    1001.21095 |    132.916804 | Steven Traver                                                                                                                                                         |
| 352 |     802.49318 |     54.938049 | Zimices                                                                                                                                                               |
| 353 |     591.62292 |    326.379296 | Zimices                                                                                                                                                               |
| 354 |     109.58167 |    725.072948 | Ghedoghedo, vectorized by Zimices                                                                                                                                     |
| 355 |     322.32003 |    392.384655 | Scott Hartman                                                                                                                                                         |
| 356 |     485.38988 |    444.189322 | Henry Lydecker                                                                                                                                                        |
| 357 |     810.12866 |    714.388034 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                     |
| 358 |     327.83532 |    436.812434 | Jagged Fang Designs                                                                                                                                                   |
| 359 |     296.94927 |    309.838796 | Margot Michaud                                                                                                                                                        |
| 360 |     852.42941 |    157.667772 | T. Michael Keesey                                                                                                                                                     |
| 361 |     527.73983 |    545.080658 | Chris huh                                                                                                                                                             |
| 362 |      70.13258 |    765.859701 | M Kolmann                                                                                                                                                             |
| 363 |     909.16161 |    480.457815 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 364 |     359.82599 |    462.682484 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 365 |    1007.25449 |    387.203900 | Joanna Wolfe                                                                                                                                                          |
| 366 |     373.17217 |    446.280337 | NA                                                                                                                                                                    |
| 367 |     882.18317 |    275.699460 | Ferran Sayol                                                                                                                                                          |
| 368 |     790.26428 |     35.639988 | Armin Reindl                                                                                                                                                          |
| 369 |     701.54606 |    636.109565 | Jonathan Wells                                                                                                                                                        |
| 370 |     529.34637 |    441.788943 | Yan Wong                                                                                                                                                              |
| 371 |     544.06814 |    728.275456 | Birgit Lang                                                                                                                                                           |
| 372 |      19.04304 |    795.420967 | Jagged Fang Designs                                                                                                                                                   |
| 373 |     895.43265 |      7.155551 | FunkMonk                                                                                                                                                              |
| 374 |     336.44243 |    167.716922 | T. Michael Keesey                                                                                                                                                     |
| 375 |     597.21806 |    432.606946 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 376 |     202.55752 |    176.308770 | Gareth Monger                                                                                                                                                         |
| 377 |      86.90953 |    402.377562 | Joanna Wolfe                                                                                                                                                          |
| 378 |      12.80886 |     48.709957 | Smith609 and T. Michael Keesey                                                                                                                                        |
| 379 |     113.23890 |     24.904952 | Sam Droege (photography) and T. Michael Keesey (vectorization)                                                                                                        |
| 380 |     514.04455 |    535.256975 | Scott Hartman                                                                                                                                                         |
| 381 |     967.35797 |    224.089099 | Tyler McCraney                                                                                                                                                        |
| 382 |     893.18367 |     79.612904 | Maija Karala                                                                                                                                                          |
| 383 |     605.75226 |    177.539329 | Noah Schlottman, photo by Martin V. Sørensen                                                                                                                          |
| 384 |     504.65680 |    773.637869 | NA                                                                                                                                                                    |
| 385 |     600.03068 |    611.462177 | Matt Crook                                                                                                                                                            |
| 386 |     894.41023 |    772.344835 | Pete Buchholz                                                                                                                                                         |
| 387 |     406.10605 |     33.895833 | Ferran Sayol                                                                                                                                                          |
| 388 |     386.86541 |    127.633791 | C. Camilo Julián-Caballero                                                                                                                                            |
| 389 |     746.01418 |    354.057812 | Scott Hartman                                                                                                                                                         |
| 390 |     729.84319 |    588.310873 | Jiekun He                                                                                                                                                             |
| 391 |      58.73652 |    584.246325 | Steven Traver                                                                                                                                                         |
| 392 |     498.11710 |    325.979710 | Beth Reinke                                                                                                                                                           |
| 393 |     146.12185 |    158.598619 | Andy Wilson                                                                                                                                                           |
| 394 |     971.48933 |    133.585359 | Maija Karala                                                                                                                                                          |
| 395 |    1005.07009 |    603.817602 | Zimices                                                                                                                                                               |
| 396 |     233.68751 |    715.025264 | Scott Hartman                                                                                                                                                         |
| 397 |     862.84607 |     59.357529 | Tyler Greenfield                                                                                                                                                      |
| 398 |     863.66043 |    248.833721 | Kamil S. Jaron                                                                                                                                                        |
| 399 |     279.35665 |    460.421133 | Alan Manson (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
| 400 |     170.48431 |    349.433363 | Tracy A. Heath                                                                                                                                                        |
| 401 |      68.76484 |    727.333186 | Smokeybjb (modified by Mike Keesey)                                                                                                                                   |
| 402 |     424.85238 |    108.322444 | NA                                                                                                                                                                    |
| 403 |      45.92856 |    213.116884 | Markus A. Grohme                                                                                                                                                      |
| 404 |     407.57988 |    349.060637 | Armin Reindl                                                                                                                                                          |
| 405 |     906.93577 |    509.006253 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                        |
| 406 |     403.52403 |    650.451823 | NA                                                                                                                                                                    |
| 407 |      42.14178 |     17.882170 |                                                                                                                                                                       |
| 408 |     311.22354 |    776.919093 | Ferran Sayol                                                                                                                                                          |
| 409 |     915.28240 |    356.838642 | Emily Willoughby                                                                                                                                                      |
| 410 |    1003.13588 |    222.682093 | Margot Michaud                                                                                                                                                        |
| 411 |     895.00783 |    625.574417 | Tasman Dixon                                                                                                                                                          |
| 412 |     253.84599 |    288.461985 | Duane Raver (vectorized by T. Michael Keesey)                                                                                                                         |
| 413 |     208.82252 |    731.600878 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 414 |     115.01181 |    606.552524 | Matt Crook                                                                                                                                                            |
| 415 |      78.89370 |    135.186410 | Matus Valach                                                                                                                                                          |
| 416 |     493.04482 |    549.642079 | Zimices                                                                                                                                                               |
| 417 |      18.92172 |    389.396521 | NA                                                                                                                                                                    |
| 418 |     100.22494 |    168.173000 | Mattia Menchetti / Yan Wong                                                                                                                                           |
| 419 |     988.17908 |    149.925542 | Gareth Monger                                                                                                                                                         |
| 420 |     231.88313 |    355.695069 | Matt Crook                                                                                                                                                            |
| 421 |     713.70637 |    512.580548 | NA                                                                                                                                                                    |
| 422 |     492.20230 |      7.129326 | Verisimilus                                                                                                                                                           |
| 423 |     757.90784 |    209.497330 | Erika Schumacher                                                                                                                                                      |
| 424 |     559.26219 |    451.597924 | Gareth Monger                                                                                                                                                         |
| 425 |      15.36870 |    180.711302 | Scott Hartman                                                                                                                                                         |
| 426 |     676.39191 |    481.415666 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 427 |     830.40425 |    238.956025 | Shyamal                                                                                                                                                               |
| 428 |     254.01035 |     52.311393 | Abraão Leite                                                                                                                                                          |
| 429 |     593.51737 |    456.803666 | Juan Carlos Jerí                                                                                                                                                      |
| 430 |     324.55603 |    134.038976 | Erika Schumacher                                                                                                                                                      |
| 431 |     591.37262 |    602.285218 | Manabu Bessho-Uehara                                                                                                                                                  |
| 432 |     946.94461 |    184.692762 | L. Shyamal                                                                                                                                                            |
| 433 |     130.04130 |      9.186535 | Ignacio Contreras                                                                                                                                                     |
| 434 |     588.73145 |    196.506622 | Margot Michaud                                                                                                                                                        |
| 435 |     693.68987 |    118.761779 | . Original drawing by M. Antón, published in Montoya and Morales 1984. Vectorized by O. Sanisidro                                                                     |
| 436 |     909.31078 |    237.623569 | NA                                                                                                                                                                    |
| 437 |     525.59358 |    292.395990 | Gareth Monger                                                                                                                                                         |
| 438 |     824.18290 |    252.306318 | Christoph Schomburg                                                                                                                                                   |
| 439 |     448.46287 |    451.201209 | Matt Crook                                                                                                                                                            |
| 440 |     619.70066 |    271.541636 | NA                                                                                                                                                                    |
| 441 |     522.43049 |    704.254674 | Iain Reid                                                                                                                                                             |
| 442 |     879.34375 |    169.729071 | Iain Reid                                                                                                                                                             |
| 443 |     345.98571 |    702.615924 | Andy Wilson                                                                                                                                                           |
| 444 |     982.18818 |    794.490051 | Carlos Cano-Barbacil                                                                                                                                                  |
| 445 |     182.06156 |    310.724157 | Rebecca Groom (Based on Photo by Andreas Trepte)                                                                                                                      |
| 446 |     226.16203 |    782.063264 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                              |
| 447 |    1019.23928 |    725.470781 | Tyler Greenfield                                                                                                                                                      |
| 448 |     812.05549 |    371.851894 | T. Michael Keesey                                                                                                                                                     |
| 449 |     567.69008 |    744.346736 | Julia B McHugh                                                                                                                                                        |
| 450 |     201.92071 |    307.183166 | Steven Coombs                                                                                                                                                         |
| 451 |     238.29760 |    384.948034 | Iain Reid                                                                                                                                                             |
| 452 |      49.29366 |    331.714602 | Gareth Monger                                                                                                                                                         |
| 453 |     139.37553 |    398.858788 | Anna Willoughby                                                                                                                                                       |
| 454 |      60.63292 |    658.788675 | Zimices                                                                                                                                                               |
| 455 |     192.97550 |     10.501096 | Markus A. Grohme                                                                                                                                                      |
| 456 |     603.43831 |    548.982421 | Erika Schumacher                                                                                                                                                      |
| 457 |     290.47438 |    365.172823 | Zimices                                                                                                                                                               |
| 458 |     750.19053 |    635.760899 | Rebecca Groom                                                                                                                                                         |
| 459 |     142.62689 |    755.976677 | Stephen O’Connor (vectorized by T. Michael Keesey)                                                                                                                    |
| 460 |    1003.47937 |    644.836803 | Steven Traver                                                                                                                                                         |
| 461 |     935.66599 |    111.441376 | Andy Wilson                                                                                                                                                           |
| 462 |     839.36672 |    136.505152 | Rebecca Groom                                                                                                                                                         |
| 463 |     980.71820 |    553.014930 | Chris huh                                                                                                                                                             |
| 464 |     792.42186 |    175.719557 | Jagged Fang Designs                                                                                                                                                   |
| 465 |     674.96371 |    772.088673 | Gareth Monger                                                                                                                                                         |
| 466 |     453.15475 |    511.696107 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                              |
| 467 |      10.47331 |    669.349135 | Lisa M. “Pixxl” (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey       |
| 468 |     621.79395 |    692.106970 | Scott Hartman                                                                                                                                                         |
| 469 |     218.23981 |    791.353759 | David Orr                                                                                                                                                             |
| 470 |     176.42593 |    755.780704 | T. Michael Keesey (vector) and Stuart Halliday (photograph)                                                                                                           |
| 471 |     890.67201 |    195.839965 | Felix Vaux                                                                                                                                                            |
| 472 |     558.34690 |    513.371462 | Alexandre Vong                                                                                                                                                        |
| 473 |     552.85455 |    400.094101 | Felix Vaux                                                                                                                                                            |
| 474 |     666.11110 |    206.019667 | Chris huh                                                                                                                                                             |
| 475 |     518.35642 |    396.210180 | Gareth Monger                                                                                                                                                         |
| 476 |     250.71586 |    232.179598 | Emily Willoughby                                                                                                                                                      |
| 477 |     663.67337 |     38.162986 | Blanco et al., 2014, vectorized by Zimices                                                                                                                            |
| 478 |    1001.17835 |    512.374251 | NA                                                                                                                                                                    |
| 479 |     670.07349 |    568.294973 | Ville-Veikko Sinkkonen                                                                                                                                                |
| 480 |     699.43993 |     32.674711 | Jagged Fang Designs                                                                                                                                                   |
| 481 |     407.34265 |    712.145695 | Zimices                                                                                                                                                               |
| 482 |     779.37046 |    713.017962 | Caleb M. Brown                                                                                                                                                        |
| 483 |     366.23013 |    148.183583 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 484 |     598.95586 |    402.977395 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 485 |      61.60066 |    722.239649 | Markus A. Grohme                                                                                                                                                      |
| 486 |     484.87163 |     64.529623 | Chris huh                                                                                                                                                             |
| 487 |     862.24496 |    489.401102 | Becky Barnes                                                                                                                                                          |
| 488 |     340.89073 |     88.179543 | Matus Valach                                                                                                                                                          |
| 489 |      49.39604 |    269.919621 | Zsoldos Márton (vectorized by T. Michael Keesey)                                                                                                                      |
| 490 |     280.78826 |      3.457749 | Scott Hartman                                                                                                                                                         |
| 491 |     183.29397 |    342.466123 | Tasman Dixon                                                                                                                                                          |
| 492 |     982.28328 |    358.809768 | Kanako Bessho-Uehara                                                                                                                                                  |
| 493 |     316.17305 |    336.240168 | NA                                                                                                                                                                    |
| 494 |     954.85485 |    475.657247 | Alexandre Vong                                                                                                                                                        |
| 495 |     500.31865 |    636.484127 | Tauana J. Cunha                                                                                                                                                       |
| 496 |     761.36059 |    443.991525 | Noah Schlottman, photo by Museum of Geology, University of Tartu                                                                                                      |
| 497 |     314.37341 |     89.555351 | Zimices                                                                                                                                                               |
| 498 |      76.57054 |     85.768973 | Giant Blue Anteater (vectorized by T. Michael Keesey)                                                                                                                 |
| 499 |     911.59896 |    791.980313 | Mathew Wedel                                                                                                                                                          |
| 500 |     400.95172 |    435.544759 | Michele M Tobias                                                                                                                                                      |
| 501 |     150.38274 |    173.789303 | Emily Willoughby                                                                                                                                                      |
| 502 |     477.16609 |    433.214533 | Bennet McComish, photo by Avenue                                                                                                                                      |
| 503 |     563.97097 |    314.253985 | Michael P. Taylor                                                                                                                                                     |
| 504 |     869.24440 |    218.520482 | Dean Schnabel                                                                                                                                                         |
| 505 |     218.92497 |     91.135345 | Tyler Greenfield                                                                                                                                                      |
| 506 |     964.97954 |    247.825280 | T. Michael Keesey (from a mount by Allis Markham)                                                                                                                     |
| 507 |     550.12557 |    535.875348 | Jagged Fang Designs                                                                                                                                                   |
| 508 |     292.08941 |     95.656635 | Rainer Schoch                                                                                                                                                         |
| 509 |     116.83706 |    400.617482 | Roberto Díaz Sibaja                                                                                                                                                   |
| 510 |     248.68507 |    725.524953 | C. Camilo Julián-Caballero                                                                                                                                            |
| 511 |     759.89882 |    673.315023 | NA                                                                                                                                                                    |
| 512 |     517.66255 |    598.560714 | Markus A. Grohme                                                                                                                                                      |

    #> Your tweet has been posted!
