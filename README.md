
<!-- README.md is generated from README.Rmd. Please edit that file -->

# immosaic

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/rdinnager/immosaic/workflows/R-CMD-check/badge.svg)](https://github.com/rdinnager/immosaic/actions)
<!-- badges: end -->

The goal of `{immosaic}` is to create packed image mosaics. The main
function `immosaic`, takes a set of images, or a function that generates
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
devtools::install_github("rdinnager/immosaic")
```

## Example

This document and hence the images below are regenerated once a day
automatically. No two will ever be alike.

First we load the packages we need for these examples:

``` r
library(immosaic)
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

Now we feed our function to the `immosaic()` function, which packs the
generated images onto a canvas:

``` r
shapes <- immosaic(generate_platonic, progress = FALSE, show_every = 0, bg = "white")
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

Now we run `immosaic` on our phylopic generating function:

``` r
phylopics <- immosaic(get_phylopic, progress = FALSE, show_every = 0, bg = "white", min_scale = 0.01)
imager::save.image(phylopics$image, "man/figures/phylopic_a_pack.png")
```

![Packed images of organism silhouettes from
Phylopic](man/figures/phylopic_a_pack.png)

Now we extract the artists who made the above images using the uid of
image.

``` r
image_dat <- lapply(phylopics$meta$uuid, 
                    function(x) {Sys.sleep(0.5); rphylopic::image_get(x, options = c("credit"))$credit})
```

## Artists whose work is showcased:

Zimices, Steven Traver, Dmitry Bogdanov (vectorized by T. Michael
Keesey), \[unknown\], Tyler Greenfield, Scott Hartman, Nobu Tamura
(vectorized by T. Michael Keesey), Melissa Broussard, Mattia Menchetti,
Matt Crook, Maxime Dahirel, Gareth Monger, Becky Barnes, Jessica Anne
Miller, Yan Wong, Joanna Wolfe, Noah Schlottman, photo by Antonio
Guillén, Roberto Díaz Sibaja, Kai R. Caspar, Jagged Fang Designs,
Ferran Sayol, Gabriela Palomo-Munoz, Dean Schnabel, T. Michael Keesey,
Kamil S. Jaron, Rafael Maia, Mo Hassan, Scarlet23 (vectorized by T.
Michael Keesey), M Kolmann, Jay Matternes (vectorized by T. Michael
Keesey), Christoph Schomburg, Chris huh, Ingo Braasch, C. Camilo
Julián-Caballero, Sarah Alewijnse, FunkMonk, Tasman Dixon, Diego
Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli,
Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by
T. Michael Keesey), Emily Willoughby, Jimmy Bernot, T. Michael Keesey
(after Walker & al.), Iain Reid, Birgit Lang, Stemonitis (photography)
and T. Michael Keesey (vectorization), Maija Karala, Julio Garza, L.
Shyamal, Margot Michaud, Jose Carlos Arenas-Monroy, terngirl, Dmitry
Bogdanov, Jakovche, B. Duygu Özpolat, Conty (vectorized by T. Michael
Keesey), Tess Linden, Original scheme by ‘Haplochromis’, vectorized by
Roberto Díaz Sibaja, Jennifer Trimble, Scott Hartman (modified by T.
Michael Keesey), Javier Luque,
\<U+0414\>\<U+0438\>\<U+0411\>\<U+0433\>\<U+0434\> (vectorized by T.
Michael Keesey), Xavier Giroux-Bougard, Michael Scroggie, Beth Reinke,
Richard J. Harris, New York Zoological Society, Amanda Katzer, Inessa
Voet, Sam Droege (photo) and T. Michael Keesey (vectorization), Matthias
Buschmann (vectorized by T. Michael Keesey), Chloé Schmidt, Tracy A.
Heath, Brad McFeeters (vectorized by T. Michael Keesey), Sean McCann,
LeonardoG (photography) and T. Michael Keesey (vectorization), Fernando
Campos De Domenico, Jaime Headden (vectorized by T. Michael Keesey),
Michelle Site, Lukas Panzarin, Ludwik Gasiorowski, Jack Mayer Wood, Eric
Moody, Matt Dempsey, Darren Naish (vectorized by T. Michael Keesey),
Brockhaus and Efron, Anthony Caravaggi, Mathilde Cordellier, Ron
Holmes/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey
(vectorization), Ghedo (vectorized by T. Michael Keesey), Andrew A.
Farke, T. Michael Keesey (after MPF), Sarah Werning, Giant Blue Anteater
(vectorized by T. Michael Keesey), Walter Vladimir, SecretJellyMan,
Trond R. Oskars, Pedro de Siracusa, Darren Naish (vectorize by T.
Michael Keesey), Noah Schlottman, T. Michael Keesey, from a photograph
by Thea Boodhoo, Obsidian Soul (vectorized by T. Michael Keesey),
Meyer-Wachsmuth I, Curini Galletti M, Jondelius U
(<doi:10.1371/journal.pone.0107688>). Vectorization by Y. Wong, Matthew
Hooge (vectorized by T. Michael Keesey), Juan Carlos Jerí, Michael P.
Taylor, Moussa Direct Ltd. (photography) and T. Michael Keesey
(vectorization), Collin Gross, Armin Reindl, Robert Gay, modified from
FunkMonk (Michael B.H.) and T. Michael Keesey., Lukasiniho, Roger
Witter, vectorized by Zimices, Wynston Cooper (photo) and Albertonykus
(silhouette), RS, Dr. Thomas G. Barnes, USFWS, Lafage, Shyamal, Chase
Brownstein, Robbie N. Cada (vectorized by T. Michael Keesey), Pranav
Iyer (grey ideas), Matt Martyniuk, Óscar San-Isidro (vectorized by T.
Michael Keesey), Lee Harding (photo), John E. McCormack, Michael G.
Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb
T. Brumfield & T. Michael Keesey, . Original drawing by M. Antón,
published in Montoya and Morales 1984. Vectorized by O. Sanisidro,
Pearson Scott Foresman (vectorized by T. Michael Keesey), Catherine
Yasuda, Sergio A. Muñoz-Gómez, Noah Schlottman, photo by Adam G. Clause,
Mali’o Kodis, photograph by John Slapcinsky, Blanco et al., 2014,
vectorized by Zimices, Michael B. H. (vectorized by T. Michael Keesey),
Matt Wilkins, Caleb M. Brown, Hans Hillewaert (vectorized by T. Michael
Keesey), Nobu Tamura, Alex Slavenko, Milton Tan, Mali’o Kodis,
photograph by “Wildcat Dunny”
(<http://www.flickr.com/people/wildcat_dunny/>), Joseph J. W. Sertich,
Mark A. Loewen, Mathew Wedel, Griensteidl and T. Michael Keesey, Maxwell
Lefroy (vectorized by T. Michael Keesey), Lily Hughes, Andrew Farke and
Joseph Sertich, T. Michael Keesey (vectorization); Yves Bousquet
(photography), Noah Schlottman, photo by David J Patterson, Oscar
Sanisidro, Scott Hartman, modified by T. Michael Keesey, Scott Reid,
Christine Axon, Tauana J. Cunha, Abraão Leite, Cristian Osorio & Paula
Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org),
Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Harold N Eyster, Mark Hannaford (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, DW Bapst,
modified from Ishitani et al. 2016, Philip Chalmers (vectorized by T.
Michael Keesey), Mathieu Basille, Eyal Bartov, Didier Descouens
(vectorized by T. Michael Keesey), Jaime Headden, Renato Santos, Crystal
Maier, Yan Wong from photo by Denes Emoke, Meliponicultor Itaymbere, Jan
A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow
(vectorized by T. Michael Keesey), Felix Vaux, Cristopher Silva,
Smokeybjb (modified by T. Michael Keesey), Richard Lampitt, Jeremy Young
/ NHM (vectorization by Yan Wong), Carlos Cano-Barbacil, Rebecca Groom,
Dmitry Bogdanov (modified by T. Michael Keesey), Jan Sevcik (photo),
John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G.
Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Sharon
Wegner-Larsen, Vijay Cavale (photo), John E. McCormack, Michael G.
Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb
T. Brumfield & T. Michael Keesey, Prathyush Thomas, T. Michael Keesey
(vectorization) and Nadiatalent (photography), David Orr, Ghedoghedo
(vectorized by T. Michael Keesey), Don Armstrong, Archaeodontosaurus
(vectorized by T. Michael Keesey), David Tana, Siobhon Egan, Renata F.
Martins, Adam Stuart Smith (vectorized by T. Michael Keesey), Lindberg
(vectorized by T. Michael Keesey), Michele M Tobias, Francesco Veronesi
(vectorized by T. Michael Keesey), Kent Elson Sorgon, Alexander
Schmidt-Lebuhn, Sherman F. Denton via rawpixel.com (illustration) and
Timothy J. Bartley (silhouette), Mason McNair, SauropodomorphMonarch,
Manabu Bessho-Uehara, Nobu Tamura, vectorized by Zimices, Terpsichores,
Pete Buchholz, T. Michael Keesey (after A. Y. Ivantsov), Keith Murdock
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, FunkMonk (Michael B.H.; vectorized by T. Michael Keesey), T.
Michael Keesey (photo by Darren Swim), Josefine Bohr Brask, Mathew
Callaghan, Francisco Gascó (modified by Michael P. Taylor), Mario
Quevedo, Mareike C. Janiak, Karl Ragnar Gjertsen (vectorized by T.
Michael Keesey), Michele Tobias, Francisco Manuel Blanco (vectorized by
T. Michael Keesey), Stephen O’Connor (vectorized by T. Michael Keesey),
Caleb M. Gordon, Stanton F. Fink (vectorized by T. Michael Keesey), Yan
Wong from SEM by Arnau Sebé-Pedrós (PD agreed by Iñaki Ruiz-Trillo),
Katie S. Collins, Michael Ströck (vectorized by T. Michael Keesey),
Gabriel Lio, vectorized by Zimices, Mali’o Kodis, photograph from
Jersabek et al, 2003, Cesar Julian, T. Michael Keesey (after Tillyard),
Matt Martyniuk (vectorized by T. Michael Keesey), Chris A. Hamilton,
Alexandre Vong, Mykle Hoban, Henry Lydecker, Emily Jane McTavish,
Patrick Fisher (vectorized by T. Michael Keesey), James I. Kirkland,
Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P.
Wiersma (vectorized by T. Michael Keesey), Tim H. Heupink, Leon Huynen,
and David M. Lambert (vectorized by T. Michael Keesey), Saguaro Pictures
(source photo) and T. Michael Keesey, Claus Rebler, Jake Warner, Mali’o
Kodis, photograph by P. Funch and R.M. Kristensen, CNZdenek, Martin R.
Smith, Ghedoghedo, vectorized by Zimices, Alexandra van der Geer,
Jonathan Wells, Arthur S. Brum, Pollyanna von Knorring and T. Michael
Keesey, Roberto Diaz Sibaja, based on Domser, Dave Souza (vectorized by
T. Michael Keesey), xgirouxb, Scott D. Sampson, Mark A. Loewen, Andrew
A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan
L. Titus, Steven Haddock • Jellywatch.org, Steven Coombs, Konsta
Happonen, from a CC-BY-NC image by pelhonen on iNaturalist, Cagri
Cevrim, Mali’o Kodis, photograph by Aqua-Photos
(<http://www.flickr.com/people/undervannsfotografen/>), Ernst Haeckel
(vectorized by T. Michael Keesey), Nicolas Huet le Jeune and
Jean-Gabriel Prêtre (vectorized by T. Michael Keesey), Myriam\_Ramirez,
Henry Fairfield Osborn, vectorized by Zimices, Luc Viatour (source
photo) and Andreas Plank, Nicholas J. Czaplewski, vectorized by Zimices,
Fernando Carezzano, Mark Miller, Martin R. Smith, from photo by Jürgen
Schoner, Lukas Panzarin (vectorized by T. Michael Keesey), T. Michael
Keesey (after Ponomarenko), Tony Ayling (vectorized by T. Michael
Keesey), Nina Skinner, Doug Backlund (photo), John E. McCormack, Michael
G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn,
Robb T. Brumfield & T. Michael Keesey

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    749.168993 |    711.237187 | Zimices                                                                                                                                                               |
|   2 |    322.148287 |    311.745979 | Zimices                                                                                                                                                               |
|   3 |    677.495481 |    299.584756 | Steven Traver                                                                                                                                                         |
|   4 |    138.114571 |    528.841224 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|   5 |    588.624762 |    609.269906 | \[unknown\]                                                                                                                                                           |
|   6 |    105.379814 |    127.972169 | Tyler Greenfield                                                                                                                                                      |
|   7 |    175.758176 |    739.000404 | NA                                                                                                                                                                    |
|   8 |    193.492606 |    207.364991 | Scott Hartman                                                                                                                                                         |
|   9 |    483.636434 |    678.533743 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  10 |    251.808202 |    471.082015 | NA                                                                                                                                                                    |
|  11 |    387.186453 |     77.706721 | Melissa Broussard                                                                                                                                                     |
|  12 |    479.718217 |    104.132216 | Scott Hartman                                                                                                                                                         |
|  13 |    480.869046 |    582.724022 | Mattia Menchetti                                                                                                                                                      |
|  14 |    242.114471 |     75.161219 | Steven Traver                                                                                                                                                         |
|  15 |    850.572023 |    513.921833 | Matt Crook                                                                                                                                                            |
|  16 |    910.150382 |    709.645698 | Maxime Dahirel                                                                                                                                                        |
|  17 |    668.294272 |    772.884231 | NA                                                                                                                                                                    |
|  18 |    961.350822 |    547.004475 | Maxime Dahirel                                                                                                                                                        |
|  19 |    362.331699 |    560.353634 | Gareth Monger                                                                                                                                                         |
|  20 |    591.070143 |     77.867935 | Gareth Monger                                                                                                                                                         |
|  21 |    962.232295 |    274.252659 | Becky Barnes                                                                                                                                                          |
|  22 |    251.597695 |    655.218026 | Jessica Anne Miller                                                                                                                                                   |
|  23 |    673.043788 |     48.871099 | Yan Wong                                                                                                                                                              |
|  24 |    759.302438 |    439.374460 | Matt Crook                                                                                                                                                            |
|  25 |    874.114558 |    106.860893 | Joanna Wolfe                                                                                                                                                          |
|  26 |    515.155749 |    479.595391 | Noah Schlottman, photo by Antonio Guillén                                                                                                                             |
|  27 |    474.167553 |    389.430108 | Roberto Díaz Sibaja                                                                                                                                                   |
|  28 |    696.161656 |    546.213158 | Kai R. Caspar                                                                                                                                                         |
|  29 |    922.683424 |    374.304955 | Jagged Fang Designs                                                                                                                                                   |
|  30 |    386.693060 |    465.787339 | Gareth Monger                                                                                                                                                         |
|  31 |    166.243316 |    310.337542 | NA                                                                                                                                                                    |
|  32 |    123.325311 |    434.239233 | Ferran Sayol                                                                                                                                                          |
|  33 |    897.629800 |    614.507876 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  34 |    867.555743 |    215.253341 | Scott Hartman                                                                                                                                                         |
|  35 |    809.770014 |     52.948381 | Dean Schnabel                                                                                                                                                         |
|  36 |     37.711598 |    304.002594 | T. Michael Keesey                                                                                                                                                     |
|  37 |     78.413099 |    622.201573 | Kamil S. Jaron                                                                                                                                                        |
|  38 |    710.332464 |    619.677591 | Ferran Sayol                                                                                                                                                          |
|  39 |    739.097531 |    168.677046 | Dean Schnabel                                                                                                                                                         |
|  40 |    417.205706 |    233.738149 | NA                                                                                                                                                                    |
|  41 |     73.015450 |    732.725298 | Rafael Maia                                                                                                                                                           |
|  42 |     82.150492 |    218.218765 | Mo Hassan                                                                                                                                                             |
|  43 |    406.119338 |    776.885284 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                                           |
|  44 |    606.838203 |    150.122538 | Melissa Broussard                                                                                                                                                     |
|  45 |    975.862148 |    167.702650 | M Kolmann                                                                                                                                                             |
|  46 |    374.396915 |    173.783842 | Scott Hartman                                                                                                                                                         |
|  47 |    752.866315 |    486.624485 | Jay Matternes (vectorized by T. Michael Keesey)                                                                                                                       |
|  48 |    876.039707 |    174.396934 | Scott Hartman                                                                                                                                                         |
|  49 |    917.750714 |    446.882432 | Gareth Monger                                                                                                                                                         |
|  50 |    269.042854 |    756.543176 | Ferran Sayol                                                                                                                                                          |
|  51 |    467.170072 |    351.686899 | Christoph Schomburg                                                                                                                                                   |
|  52 |    217.528686 |    132.615353 | Gareth Monger                                                                                                                                                         |
|  53 |    484.264907 |    741.916904 | Chris huh                                                                                                                                                             |
|  54 |    348.153923 |    636.744980 | Gareth Monger                                                                                                                                                         |
|  55 |    814.553523 |    674.399808 | Ingo Braasch                                                                                                                                                          |
|  56 |    236.423954 |    320.717874 | T. Michael Keesey                                                                                                                                                     |
|  57 |    613.176742 |    717.489444 | C. Camilo Julián-Caballero                                                                                                                                            |
|  58 |    460.162458 |     54.536587 | Chris huh                                                                                                                                                             |
|  59 |    401.927672 |    726.897369 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  60 |    199.384323 |    154.894127 | Sarah Alewijnse                                                                                                                                                       |
|  61 |    926.889693 |    325.427958 | Gareth Monger                                                                                                                                                         |
|  62 |     61.312728 |    357.722863 | FunkMonk                                                                                                                                                              |
|  63 |    134.765433 |     51.878881 | Tasman Dixon                                                                                                                                                          |
|  64 |    996.343462 |    739.487348 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
|  65 |    664.634728 |    432.753505 | Emily Willoughby                                                                                                                                                      |
|  66 |     58.660423 |    486.963166 | Jimmy Bernot                                                                                                                                                          |
|  67 |    942.250694 |     55.207452 | Scott Hartman                                                                                                                                                         |
|  68 |     40.011709 |    126.744633 | T. Michael Keesey (after Walker & al.)                                                                                                                                |
|  69 |    548.894540 |     23.641902 | FunkMonk                                                                                                                                                              |
|  70 |    837.572820 |    254.753398 | Jagged Fang Designs                                                                                                                                                   |
|  71 |    455.057842 |    281.403010 | Iain Reid                                                                                                                                                             |
|  72 |    420.675034 |    691.877894 | Ferran Sayol                                                                                                                                                          |
|  73 |    167.781557 |    607.426471 | Ferran Sayol                                                                                                                                                          |
|  74 |     24.548314 |    604.337352 | NA                                                                                                                                                                    |
|  75 |    529.144100 |    781.643148 | Birgit Lang                                                                                                                                                           |
|  76 |    105.190683 |     16.240955 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  77 |    881.891978 |    763.285340 | Stemonitis (photography) and T. Michael Keesey (vectorization)                                                                                                        |
|  78 |    789.516760 |    631.719830 | Maija Karala                                                                                                                                                          |
|  79 |    413.404544 |    640.341803 | Julio Garza                                                                                                                                                           |
|  80 |    322.338434 |    484.050704 | L. Shyamal                                                                                                                                                            |
|  81 |    891.441329 |    451.988474 | Emily Willoughby                                                                                                                                                      |
|  82 |   1005.253349 |    610.667221 | Kai R. Caspar                                                                                                                                                         |
|  83 |   1001.494241 |    383.403747 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  84 |    560.485548 |    518.647243 | Matt Crook                                                                                                                                                            |
|  85 |    803.688839 |     89.015055 | Matt Crook                                                                                                                                                            |
|  86 |    576.448012 |    337.684804 | Mo Hassan                                                                                                                                                             |
|  87 |   1006.186075 |    300.164520 | Zimices                                                                                                                                                               |
|  88 |    191.173719 |    181.492962 | Margot Michaud                                                                                                                                                        |
|  89 |    576.367130 |    108.872231 | Jose Carlos Arenas-Monroy                                                                                                                                             |
|  90 |    774.125111 |    756.401291 | terngirl                                                                                                                                                              |
|  91 |    218.347577 |     24.714222 | Dmitry Bogdanov                                                                                                                                                       |
|  92 |    371.568841 |    418.574727 | Jakovche                                                                                                                                                              |
|  93 |     36.771116 |     63.249235 | Margot Michaud                                                                                                                                                        |
|  94 |    998.507800 |    446.841908 | M Kolmann                                                                                                                                                             |
|  95 |    841.462818 |    325.504480 | Matt Crook                                                                                                                                                            |
|  96 |    355.655366 |      8.810754 | NA                                                                                                                                                                    |
|  97 |    672.215311 |    739.546741 | B. Duygu Özpolat                                                                                                                                                      |
|  98 |    322.010591 |    445.535630 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
|  99 |    962.870727 |    721.075039 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 100 |    682.375490 |    585.680055 | Tess Linden                                                                                                                                                           |
| 101 |    323.172672 |    227.439469 | Original scheme by ‘Haplochromis’, vectorized by Roberto Díaz Sibaja                                                                                                  |
| 102 |    302.107143 |    249.373597 | Margot Michaud                                                                                                                                                        |
| 103 |    886.364128 |    349.349251 | Kamil S. Jaron                                                                                                                                                        |
| 104 |    785.388272 |     13.318761 | Jennifer Trimble                                                                                                                                                      |
| 105 |    290.770369 |    383.513560 | Margot Michaud                                                                                                                                                        |
| 106 |    828.748563 |    735.330574 | Scott Hartman (modified by T. Michael Keesey)                                                                                                                         |
| 107 |    366.585577 |    272.119746 | Scott Hartman                                                                                                                                                         |
| 108 |    532.718179 |    317.826158 | Tasman Dixon                                                                                                                                                          |
| 109 |    613.537025 |    114.257671 | Matt Crook                                                                                                                                                            |
| 110 |    676.364074 |    653.268756 | Gareth Monger                                                                                                                                                         |
| 111 |    613.046858 |    192.036070 | Jagged Fang Designs                                                                                                                                                   |
| 112 |    661.055787 |     93.317195 | Javier Luque                                                                                                                                                          |
| 113 |    953.693253 |    401.199682 | \<U+0414\>\<U+0438\>\<U+0411\>\<U+0433\>\<U+0434\> (vectorized by T. Michael Keesey)                                                                                  |
| 114 |    902.330160 |    573.192200 | Ferran Sayol                                                                                                                                                          |
| 115 |    587.967102 |    523.312587 | Gareth Monger                                                                                                                                                         |
| 116 |    801.909037 |    231.314640 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 117 |   1014.003782 |    225.390536 | M Kolmann                                                                                                                                                             |
| 118 |    479.716228 |    170.969580 | NA                                                                                                                                                                    |
| 119 |    927.934404 |    408.098552 | Christoph Schomburg                                                                                                                                                   |
| 120 |    974.082921 |    671.754498 | Xavier Giroux-Bougard                                                                                                                                                 |
| 121 |    293.715550 |    583.991984 | NA                                                                                                                                                                    |
| 122 |     20.096181 |    535.965441 | Michael Scroggie                                                                                                                                                      |
| 123 |    434.703649 |    147.728435 | Tasman Dixon                                                                                                                                                          |
| 124 |    922.092633 |    233.389515 | Beth Reinke                                                                                                                                                           |
| 125 |    575.183503 |    441.215405 | Chris huh                                                                                                                                                             |
| 126 |    865.050290 |    293.774621 | Steven Traver                                                                                                                                                         |
| 127 |    563.200940 |    376.273252 | Richard J. Harris                                                                                                                                                     |
| 128 |    912.521691 |    422.597740 | Birgit Lang                                                                                                                                                           |
| 129 |    780.382878 |    601.001005 | New York Zoological Society                                                                                                                                           |
| 130 |    768.443300 |    535.432963 | Matt Crook                                                                                                                                                            |
| 131 |   1006.260458 |    184.902826 | Amanda Katzer                                                                                                                                                         |
| 132 |    781.070296 |    443.134089 | Inessa Voet                                                                                                                                                           |
| 133 |    974.121007 |    630.808808 | Sam Droege (photo) and T. Michael Keesey (vectorization)                                                                                                              |
| 134 |    311.249584 |    405.761787 | T. Michael Keesey                                                                                                                                                     |
| 135 |    696.125644 |    462.099336 | C. Camilo Julián-Caballero                                                                                                                                            |
| 136 |    704.210495 |    110.497728 | Matthias Buschmann (vectorized by T. Michael Keesey)                                                                                                                  |
| 137 |    140.152839 |     27.061805 | Scott Hartman                                                                                                                                                         |
| 138 |    425.048573 |    319.456186 | Chloé Schmidt                                                                                                                                                         |
| 139 |    540.745727 |    434.773217 | Maija Karala                                                                                                                                                          |
| 140 |    106.651357 |    781.891122 | Gareth Monger                                                                                                                                                         |
| 141 |     81.071561 |    690.056222 | Yan Wong                                                                                                                                                              |
| 142 |    752.004514 |    629.122247 | NA                                                                                                                                                                    |
| 143 |     47.674671 |    580.929793 | NA                                                                                                                                                                    |
| 144 |    787.073897 |    132.547254 | Steven Traver                                                                                                                                                         |
| 145 |    340.570180 |    524.956672 | Tracy A. Heath                                                                                                                                                        |
| 146 |    302.541238 |    710.919095 | Steven Traver                                                                                                                                                         |
| 147 |    717.194313 |     75.149767 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 148 |    393.916086 |    645.367384 | Zimices                                                                                                                                                               |
| 149 |    111.473831 |    746.943290 | Sean McCann                                                                                                                                                           |
| 150 |    975.265864 |    106.224437 | Gareth Monger                                                                                                                                                         |
| 151 |    615.475874 |     57.270104 | LeonardoG (photography) and T. Michael Keesey (vectorization)                                                                                                         |
| 152 |    366.661573 |    627.575434 | Fernando Campos De Domenico                                                                                                                                           |
| 153 |    767.960120 |    403.063433 | Christoph Schomburg                                                                                                                                                   |
| 154 |    806.928357 |    781.269242 | Joanna Wolfe                                                                                                                                                          |
| 155 |    163.602736 |     32.854636 | Jaime Headden (vectorized by T. Michael Keesey)                                                                                                                       |
| 156 |    529.332950 |    757.537894 | Michelle Site                                                                                                                                                         |
| 157 |    777.236602 |    109.880770 | Lukas Panzarin                                                                                                                                                        |
| 158 |    426.764936 |    453.301969 | Gareth Monger                                                                                                                                                         |
| 159 |    663.755986 |    690.049901 | NA                                                                                                                                                                    |
| 160 |   1016.155501 |     73.040005 | Michael Scroggie                                                                                                                                                      |
| 161 |    761.929153 |    555.293575 | Chris huh                                                                                                                                                             |
| 162 |    207.890983 |    572.341829 | Zimices                                                                                                                                                               |
| 163 |    447.091102 |    630.328009 | Steven Traver                                                                                                                                                         |
| 164 |      8.013643 |    257.342866 | Margot Michaud                                                                                                                                                        |
| 165 |    147.680150 |    781.016172 | Ludwik Gasiorowski                                                                                                                                                    |
| 166 |    272.971613 |    251.367462 | Jack Mayer Wood                                                                                                                                                       |
| 167 |    908.440764 |     14.430243 | Eric Moody                                                                                                                                                            |
| 168 |    524.701553 |    649.815451 | Matt Dempsey                                                                                                                                                          |
| 169 |    334.132606 |    131.715603 | Matt Crook                                                                                                                                                            |
| 170 |    190.166038 |    390.381645 | Chris huh                                                                                                                                                             |
| 171 |    696.759657 |    203.286784 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                        |
| 172 |    359.602821 |    121.742800 | Matt Crook                                                                                                                                                            |
| 173 |    463.752158 |    427.519271 | Gareth Monger                                                                                                                                                         |
| 174 |    214.910209 |    710.408765 | Brockhaus and Efron                                                                                                                                                   |
| 175 |    288.218998 |    209.948276 | Anthony Caravaggi                                                                                                                                                     |
| 176 |    719.872951 |    209.487429 | Mathilde Cordellier                                                                                                                                                   |
| 177 |    823.229176 |     14.213785 | Chris huh                                                                                                                                                             |
| 178 |    890.719122 |    156.443766 | Scott Hartman                                                                                                                                                         |
| 179 |     35.885231 |    429.872011 | Scott Hartman                                                                                                                                                         |
| 180 |    752.866015 |     63.891205 | FunkMonk                                                                                                                                                              |
| 181 |    552.948814 |    320.487676 | NA                                                                                                                                                                    |
| 182 |     18.299408 |      6.351490 | T. Michael Keesey                                                                                                                                                     |
| 183 |    537.182242 |    423.664891 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 184 |    598.490269 |    783.863898 | NA                                                                                                                                                                    |
| 185 |   1006.975956 |    765.672480 | Ron Holmes/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                                          |
| 186 |    148.557126 |    232.311098 | Margot Michaud                                                                                                                                                        |
| 187 |    932.035518 |    127.029525 | Ghedo (vectorized by T. Michael Keesey)                                                                                                                               |
| 188 |    228.021531 |    712.949958 | Andrew A. Farke                                                                                                                                                       |
| 189 |    342.540120 |    233.948117 | T. Michael Keesey (after MPF)                                                                                                                                         |
| 190 |    972.331159 |    466.043102 | Sarah Werning                                                                                                                                                         |
| 191 |    587.182787 |    350.346184 | Giant Blue Anteater (vectorized by T. Michael Keesey)                                                                                                                 |
| 192 |    165.172999 |    360.674191 | Gareth Monger                                                                                                                                                         |
| 193 |    393.361372 |    139.201077 | Scott Hartman                                                                                                                                                         |
| 194 |     27.674167 |    419.807972 | Zimices                                                                                                                                                               |
| 195 |    140.548581 |     95.172440 | Zimices                                                                                                                                                               |
| 196 |     90.382957 |    291.232558 | Matt Crook                                                                                                                                                            |
| 197 |    884.217384 |    532.597619 | Walter Vladimir                                                                                                                                                       |
| 198 |    351.474594 |     23.781046 | Matt Crook                                                                                                                                                            |
| 199 |    655.788511 |    589.193760 | Margot Michaud                                                                                                                                                        |
| 200 |    465.651608 |    647.343488 | NA                                                                                                                                                                    |
| 201 |    391.222261 |    515.579023 | SecretJellyMan                                                                                                                                                        |
| 202 |    601.088647 |     34.649834 | Trond R. Oskars                                                                                                                                                       |
| 203 |    131.095371 |    669.943794 | Ferran Sayol                                                                                                                                                          |
| 204 |    257.298375 |    314.777250 | Christoph Schomburg                                                                                                                                                   |
| 205 |    168.476668 |    486.459559 | Matt Crook                                                                                                                                                            |
| 206 |    625.554875 |    542.235183 | Pedro de Siracusa                                                                                                                                                     |
| 207 |    651.153602 |    186.254724 | Maija Karala                                                                                                                                                          |
| 208 |   1002.436519 |    655.560646 | Mathilde Cordellier                                                                                                                                                   |
| 209 |     82.941302 |    273.277434 | Sarah Werning                                                                                                                                                         |
| 210 |    969.874742 |     45.578171 | NA                                                                                                                                                                    |
| 211 |   1009.011380 |     21.807408 | Margot Michaud                                                                                                                                                        |
| 212 |   1002.445312 |     87.755182 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                         |
| 213 |    752.722226 |     93.473027 | NA                                                                                                                                                                    |
| 214 |     81.356671 |    704.630461 | Noah Schlottman                                                                                                                                                       |
| 215 |    261.589519 |    116.063346 | Tasman Dixon                                                                                                                                                          |
| 216 |    122.389999 |    626.905866 | Ferran Sayol                                                                                                                                                          |
| 217 |    837.135895 |    386.678475 | T. Michael Keesey, from a photograph by Thea Boodhoo                                                                                                                  |
| 218 |    135.426364 |    570.842874 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 219 |    950.720274 |     67.597590 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 220 |    281.923253 |    791.254555 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 221 |    125.211243 |    557.919121 | Tracy A. Heath                                                                                                                                                        |
| 222 |    265.446871 |    543.045008 | Christoph Schomburg                                                                                                                                                   |
| 223 |    939.198144 |    477.070817 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 224 |    889.211522 |    281.612073 | Meyer-Wachsmuth I, Curini Galletti M, Jondelius U (<doi:10.1371/journal.pone.0107688>). Vectorization by Y. Wong                                                      |
| 225 |    120.536114 |    391.352291 | Matt Crook                                                                                                                                                            |
| 226 |    810.057993 |     30.200592 | Matthew Hooge (vectorized by T. Michael Keesey)                                                                                                                       |
| 227 |    809.026614 |    280.096089 | Juan Carlos Jerí                                                                                                                                                      |
| 228 |    499.080866 |    242.900934 | Margot Michaud                                                                                                                                                        |
| 229 |    645.943761 |    372.672905 | Matt Crook                                                                                                                                                            |
| 230 |    281.422570 |    199.511469 | Michael P. Taylor                                                                                                                                                     |
| 231 |    335.061224 |     65.683303 | Moussa Direct Ltd. (photography) and T. Michael Keesey (vectorization)                                                                                                |
| 232 |    150.730765 |    512.241293 | Zimices                                                                                                                                                               |
| 233 |    338.131599 |    330.829101 | Collin Gross                                                                                                                                                          |
| 234 |    217.506676 |    586.960864 | Armin Reindl                                                                                                                                                          |
| 235 |    307.716716 |    108.856392 | Matt Crook                                                                                                                                                            |
| 236 |     79.488579 |     71.929783 | Jagged Fang Designs                                                                                                                                                   |
| 237 |    420.078185 |    624.069753 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                              |
| 238 |    604.141485 |    741.267019 | Lukasiniho                                                                                                                                                            |
| 239 |    210.500260 |    354.762017 | Ferran Sayol                                                                                                                                                          |
| 240 |    445.557847 |     78.157998 | Xavier Giroux-Bougard                                                                                                                                                 |
| 241 |    393.815211 |    427.678842 | Chris huh                                                                                                                                                             |
| 242 |    857.838933 |    552.804541 | Roger Witter, vectorized by Zimices                                                                                                                                   |
| 243 |    278.435111 |    177.606965 | Steven Traver                                                                                                                                                         |
| 244 |    829.229422 |    302.469090 | Matt Crook                                                                                                                                                            |
| 245 |    577.662922 |    740.422362 | Gareth Monger                                                                                                                                                         |
| 246 |    112.426694 |    572.005715 | Wynston Cooper (photo) and Albertonykus (silhouette)                                                                                                                  |
| 247 |    377.882568 |    615.972051 | RS                                                                                                                                                                    |
| 248 |    545.722281 |    762.063053 | Birgit Lang                                                                                                                                                           |
| 249 |    918.289309 |    142.640607 | Dr. Thomas G. Barnes, USFWS                                                                                                                                           |
| 250 |    858.540071 |    565.934534 | Ferran Sayol                                                                                                                                                          |
| 251 |    822.519755 |    138.135885 | Scott Hartman                                                                                                                                                         |
| 252 |    399.924532 |    376.646850 | Ferran Sayol                                                                                                                                                          |
| 253 |    346.757770 |    445.533073 | Maija Karala                                                                                                                                                          |
| 254 |    977.183854 |    476.488493 | Zimices                                                                                                                                                               |
| 255 |    976.477559 |    697.683762 | NA                                                                                                                                                                    |
| 256 |    916.825199 |    577.465737 | Lafage                                                                                                                                                                |
| 257 |      7.167259 |     83.081185 | Matt Crook                                                                                                                                                            |
| 258 |    496.746063 |    187.389369 | Noah Schlottman                                                                                                                                                       |
| 259 |    786.257492 |    216.332939 | Gareth Monger                                                                                                                                                         |
| 260 |     20.553554 |    185.988716 | Shyamal                                                                                                                                                               |
| 261 |    794.146989 |    209.146949 | Melissa Broussard                                                                                                                                                     |
| 262 |    738.657847 |    679.338078 | Chase Brownstein                                                                                                                                                      |
| 263 |    826.904519 |    472.426079 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 264 |    788.529169 |    562.941011 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 265 |    578.232288 |    676.957963 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
| 266 |    449.962620 |    444.222770 | Sarah Werning                                                                                                                                                         |
| 267 |    579.380734 |    758.879393 | Matt Crook                                                                                                                                                            |
| 268 |    950.034910 |     36.321163 | NA                                                                                                                                                                    |
| 269 |    687.517883 |    512.383977 | T. Michael Keesey                                                                                                                                                     |
| 270 |    414.841884 |    398.754093 | Pranav Iyer (grey ideas)                                                                                                                                              |
| 271 |    762.480771 |    772.647950 | Matt Martyniuk                                                                                                                                                        |
| 272 |    804.034724 |    710.224981 | Óscar San-Isidro (vectorized by T. Michael Keesey)                                                                                                                    |
| 273 |    305.413647 |     49.129880 | Lee Harding (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
| 274 |    761.801893 |    412.845544 | Steven Traver                                                                                                                                                         |
| 275 |    776.558274 |    585.523507 | Ferran Sayol                                                                                                                                                          |
| 276 |    978.064870 |    445.344820 | T. Michael Keesey                                                                                                                                                     |
| 277 |    952.842689 |    235.967367 | . Original drawing by M. Antón, published in Montoya and Morales 1984. Vectorized by O. Sanisidro                                                                     |
| 278 |    677.665032 |    106.249475 | Anthony Caravaggi                                                                                                                                                     |
| 279 |     11.831865 |    663.992946 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                              |
| 280 |    509.129488 |    693.201378 | Maija Karala                                                                                                                                                          |
| 281 |    835.982546 |    292.306752 | Ingo Braasch                                                                                                                                                          |
| 282 |    617.658369 |    529.124727 | Catherine Yasuda                                                                                                                                                      |
| 283 |    433.394528 |    597.891331 | Gareth Monger                                                                                                                                                         |
| 284 |    591.314461 |    444.180620 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 285 |    893.297435 |    234.264318 | Matt Crook                                                                                                                                                            |
| 286 |    963.782479 |    361.506560 | Noah Schlottman, photo by Adam G. Clause                                                                                                                              |
| 287 |    115.285469 |    249.223311 | Mali’o Kodis, photograph by John Slapcinsky                                                                                                                           |
| 288 |    688.838346 |     91.475484 | T. Michael Keesey                                                                                                                                                     |
| 289 |    446.745710 |    313.888324 | Ferran Sayol                                                                                                                                                          |
| 290 |    897.715302 |    522.703670 | Blanco et al., 2014, vectorized by Zimices                                                                                                                            |
| 291 |    780.557616 |    540.471214 | Iain Reid                                                                                                                                                             |
| 292 |    409.873759 |     94.622199 | Ferran Sayol                                                                                                                                                          |
| 293 |      9.622760 |    718.759655 | NA                                                                                                                                                                    |
| 294 |    782.867437 |    180.320878 | Michael B. H. (vectorized by T. Michael Keesey)                                                                                                                       |
| 295 |    808.133124 |    110.003686 | Matt Wilkins                                                                                                                                                          |
| 296 |    873.680644 |     68.927596 | Xavier Giroux-Bougard                                                                                                                                                 |
| 297 |    659.345915 |    617.900359 | C. Camilo Julián-Caballero                                                                                                                                            |
| 298 |    830.431226 |    599.731651 | Tyler Greenfield                                                                                                                                                      |
| 299 |    984.304843 |    410.163133 | Caleb M. Brown                                                                                                                                                        |
| 300 |    186.391158 |    230.661204 | Roger Witter, vectorized by Zimices                                                                                                                                   |
| 301 |    317.420146 |    620.869611 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 302 |    877.699645 |    706.248703 | Nobu Tamura                                                                                                                                                           |
| 303 |    822.361601 |    421.972794 | Zimices                                                                                                                                                               |
| 304 |    211.338217 |    242.590086 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 305 |    390.284562 |    207.253499 | Óscar San-Isidro (vectorized by T. Michael Keesey)                                                                                                                    |
| 306 |    792.907553 |    423.452062 | NA                                                                                                                                                                    |
| 307 |    980.695454 |    243.584058 | Margot Michaud                                                                                                                                                        |
| 308 |    639.410687 |    558.143814 | L. Shyamal                                                                                                                                                            |
| 309 |    804.514569 |    164.352751 | Alex Slavenko                                                                                                                                                         |
| 310 |    354.348358 |    209.982529 | Margot Michaud                                                                                                                                                        |
| 311 |    903.171800 |    250.129075 | Margot Michaud                                                                                                                                                        |
| 312 |     97.157817 |    269.585684 | Zimices                                                                                                                                                               |
| 313 |    569.416022 |    321.993320 | Yan Wong                                                                                                                                                              |
| 314 |    142.216904 |    182.770114 | Gareth Monger                                                                                                                                                         |
| 315 |    595.777534 |    754.239955 | Milton Tan                                                                                                                                                            |
| 316 |     37.697156 |    686.350371 | Mali’o Kodis, photograph by “Wildcat Dunny” (<http://www.flickr.com/people/wildcat_dunny/>)                                                                           |
| 317 |    519.232770 |    586.798785 | Birgit Lang                                                                                                                                                           |
| 318 |    419.014244 |    738.695444 | Michelle Site                                                                                                                                                         |
| 319 |    220.203634 |    551.133823 | Jagged Fang Designs                                                                                                                                                   |
| 320 |    807.934504 |    593.936392 | Matt Dempsey                                                                                                                                                          |
| 321 |    239.707092 |    240.667640 | Maija Karala                                                                                                                                                          |
| 322 |    772.129669 |    232.727998 | Matt Crook                                                                                                                                                            |
| 323 |    224.269379 |    116.738140 | Jagged Fang Designs                                                                                                                                                   |
| 324 |    491.101252 |    432.574721 | Margot Michaud                                                                                                                                                        |
| 325 |     27.060058 |    748.112997 | Chris huh                                                                                                                                                             |
| 326 |    704.335109 |     13.851069 | Joseph J. W. Sertich, Mark A. Loewen                                                                                                                                  |
| 327 |    597.191768 |    768.121774 | Mathew Wedel                                                                                                                                                          |
| 328 |    644.931124 |    568.583283 | Griensteidl and T. Michael Keesey                                                                                                                                     |
| 329 |    416.883292 |    498.777440 | Maija Karala                                                                                                                                                          |
| 330 |    559.371901 |    731.668523 | Margot Michaud                                                                                                                                                        |
| 331 |    518.539373 |    104.467087 | Ferran Sayol                                                                                                                                                          |
| 332 |    455.312329 |    256.824609 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                      |
| 333 |    202.501864 |    493.451222 | Tracy A. Heath                                                                                                                                                        |
| 334 |    265.035494 |    398.730221 | Lily Hughes                                                                                                                                                           |
| 335 |    815.664972 |    315.354517 | Andrew Farke and Joseph Sertich                                                                                                                                       |
| 336 |    380.842930 |    757.014724 | Shyamal                                                                                                                                                               |
| 337 |      7.415652 |     34.551007 | Maxime Dahirel                                                                                                                                                        |
| 338 |    236.263414 |     10.666089 | Sarah Werning                                                                                                                                                         |
| 339 |      9.664513 |    676.827327 | Gareth Monger                                                                                                                                                         |
| 340 |    388.649862 |    593.897074 | Ferran Sayol                                                                                                                                                          |
| 341 |    786.695057 |    398.667997 | Matt Crook                                                                                                                                                            |
| 342 |    299.759346 |     96.805398 | Michael Scroggie                                                                                                                                                      |
| 343 |    267.572921 |    241.198563 | T. Michael Keesey (vectorization); Yves Bousquet (photography)                                                                                                        |
| 344 |    470.845351 |    793.800903 | NA                                                                                                                                                                    |
| 345 |    105.296938 |    449.093276 | Noah Schlottman, photo by David J Patterson                                                                                                                           |
| 346 |    684.730483 |     18.227149 | Oscar Sanisidro                                                                                                                                                       |
| 347 |    267.010108 |    155.309613 | Zimices                                                                                                                                                               |
| 348 |    533.941526 |    580.039824 | T. Michael Keesey                                                                                                                                                     |
| 349 |    316.345413 |     88.102988 | Chris huh                                                                                                                                                             |
| 350 |    505.508507 |    250.268419 | Scott Hartman, modified by T. Michael Keesey                                                                                                                          |
| 351 |    285.429767 |    605.408251 | Steven Traver                                                                                                                                                         |
| 352 |    563.923119 |    615.342001 | Scott Reid                                                                                                                                                            |
| 353 |    620.805977 |    622.757490 | Christine Axon                                                                                                                                                        |
| 354 |    792.799874 |    607.088866 | Chris huh                                                                                                                                                             |
| 355 |    928.327233 |    192.783103 | Margot Michaud                                                                                                                                                        |
| 356 |   1016.773523 |    701.893113 | Michelle Site                                                                                                                                                         |
| 357 |    354.861995 |    399.963305 | Steven Traver                                                                                                                                                         |
| 358 |    449.667004 |    530.463847 | Margot Michaud                                                                                                                                                        |
| 359 |    351.196229 |    471.645415 | Tauana J. Cunha                                                                                                                                                       |
| 360 |    951.244257 |    307.487576 | Abraão Leite                                                                                                                                                          |
| 361 |    344.782348 |    203.552286 | FunkMonk                                                                                                                                                              |
| 362 |    538.880499 |    126.343864 | Margot Michaud                                                                                                                                                        |
| 363 |    710.287562 |     30.419931 | Sean McCann                                                                                                                                                           |
| 364 |   1016.206851 |    417.816192 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 365 |    748.267033 |    745.543598 | Matt Crook                                                                                                                                                            |
| 366 |    496.306075 |    417.147015 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
| 367 |    336.912365 |    741.468969 | Lily Hughes                                                                                                                                                           |
| 368 |    435.404089 |    584.753409 | Matt Crook                                                                                                                                                            |
| 369 |    440.514195 |     40.499883 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                      |
| 370 |     22.471248 |     97.709502 | NA                                                                                                                                                                    |
| 371 |     54.359479 |    132.282914 | Chris huh                                                                                                                                                             |
| 372 |     45.400021 |     39.881054 | Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org)                                                                          |
| 373 |    596.616644 |    302.076042 | Mathilde Cordellier                                                                                                                                                   |
| 374 |    121.739368 |    368.729086 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
| 375 |    840.819228 |    792.650885 | Harold N Eyster                                                                                                                                                       |
| 376 |    348.713982 |    758.955609 | Noah Schlottman, photo by Antonio Guillén                                                                                                                             |
| 377 |    502.334153 |    707.276760 | Matt Crook                                                                                                                                                            |
| 378 |    960.261283 |     25.641425 | Beth Reinke                                                                                                                                                           |
| 379 |    207.332656 |    101.725094 | Mark Hannaford (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey        |
| 380 |    113.850911 |    315.232530 | Alex Slavenko                                                                                                                                                         |
| 381 |   1009.878528 |    454.028510 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 382 |   1009.206614 |    471.098924 | Margot Michaud                                                                                                                                                        |
| 383 |    820.686198 |    161.640114 | Shyamal                                                                                                                                                               |
| 384 |    216.183148 |    388.356979 | DW Bapst, modified from Ishitani et al. 2016                                                                                                                          |
| 385 |    962.595276 |    208.535681 | Julio Garza                                                                                                                                                           |
| 386 |     77.172025 |    340.278070 | Philip Chalmers (vectorized by T. Michael Keesey)                                                                                                                     |
| 387 |    523.794114 |    606.267533 | Ferran Sayol                                                                                                                                                          |
| 388 |   1003.384028 |      8.558623 | Mathieu Basille                                                                                                                                                       |
| 389 |    309.820660 |    530.925077 | Matt Martyniuk                                                                                                                                                        |
| 390 |    867.838933 |    390.319814 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                              |
| 391 |    503.032180 |    373.516457 | Steven Traver                                                                                                                                                         |
| 392 |    285.017354 |    114.428612 | Matt Crook                                                                                                                                                            |
| 393 |    121.504192 |    657.183412 | Matt Crook                                                                                                                                                            |
| 394 |    558.747926 |    365.029026 | Eyal Bartov                                                                                                                                                           |
| 395 |    118.134402 |    238.830968 | Scott Hartman                                                                                                                                                         |
| 396 |    548.734116 |     47.150646 | Matt Crook                                                                                                                                                            |
| 397 |    970.737135 |    613.047919 | Collin Gross                                                                                                                                                          |
| 398 |    798.526740 |    763.367013 | Steven Traver                                                                                                                                                         |
| 399 |    805.631445 |    124.927867 | Steven Traver                                                                                                                                                         |
| 400 |     75.384311 |    395.887273 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 401 |    711.277440 |    460.738781 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 402 |    777.616535 |    195.684151 | Margot Michaud                                                                                                                                                        |
| 403 |    643.758272 |     93.361253 | NA                                                                                                                                                                    |
| 404 |    192.577740 |    514.995390 | Jaime Headden                                                                                                                                                         |
| 405 |    481.285102 |    510.931993 | Renato Santos                                                                                                                                                         |
| 406 |    903.674177 |    429.126367 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 407 |    543.567920 |    358.862054 | Zimices                                                                                                                                                               |
| 408 |    929.917309 |    113.958900 | Crystal Maier                                                                                                                                                         |
| 409 |    316.398016 |     32.833714 | Yan Wong from photo by Denes Emoke                                                                                                                                    |
| 410 |    957.105341 |    698.846977 | Meliponicultor Itaymbere                                                                                                                                              |
| 411 |    885.504939 |    551.833003 | NA                                                                                                                                                                    |
| 412 |    828.331455 |    715.403376 | Chris huh                                                                                                                                                             |
| 413 |     58.217245 |     95.885890 | Sarah Werning                                                                                                                                                         |
| 414 |    132.368032 |    485.526560 | Gareth Monger                                                                                                                                                         |
| 415 |    354.462622 |     76.588437 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 416 |    893.464176 |     56.519177 | Jagged Fang Designs                                                                                                                                                   |
| 417 |    829.276712 |    762.157963 | NA                                                                                                                                                                    |
| 418 |    561.915529 |     65.896772 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 419 |    425.208263 |    286.110442 | Matt Crook                                                                                                                                                            |
| 420 |    966.586893 |    618.397996 | Felix Vaux                                                                                                                                                            |
| 421 |    156.608531 |    215.950671 | NA                                                                                                                                                                    |
| 422 |    702.908497 |    514.134467 | Ferran Sayol                                                                                                                                                          |
| 423 |    566.240320 |    701.953488 | Cristopher Silva                                                                                                                                                      |
| 424 |   1016.308154 |    507.966287 | Steven Traver                                                                                                                                                         |
| 425 |    796.687851 |    405.383234 | Margot Michaud                                                                                                                                                        |
| 426 |    595.706685 |    456.105405 | Abraão Leite                                                                                                                                                          |
| 427 |    109.821011 |    719.706394 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 428 |    354.144038 |    376.522883 | Smokeybjb (modified by T. Michael Keesey)                                                                                                                             |
| 429 |    158.721137 |    511.034197 | Ferran Sayol                                                                                                                                                          |
| 430 |    365.008352 |     48.912999 | Richard Lampitt, Jeremy Young / NHM (vectorization by Yan Wong)                                                                                                       |
| 431 |     36.984310 |    592.650703 | Matt Crook                                                                                                                                                            |
| 432 |    404.893319 |     39.612487 | Carlos Cano-Barbacil                                                                                                                                                  |
| 433 |    137.300004 |    192.144356 | Rebecca Groom                                                                                                                                                         |
| 434 |     76.808055 |     90.191500 | Joanna Wolfe                                                                                                                                                          |
| 435 |    114.883383 |    699.577758 | Dmitry Bogdanov (modified by T. Michael Keesey)                                                                                                                       |
| 436 |    989.515920 |    308.397266 | Scott Reid                                                                                                                                                            |
| 437 |    704.415115 |    757.865894 | Zimices                                                                                                                                                               |
| 438 |    599.741335 |    359.957317 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 439 |    164.554685 |      9.363066 | Sarah Werning                                                                                                                                                         |
| 440 |    507.889047 |    131.708709 | Maxime Dahirel                                                                                                                                                        |
| 441 |    521.578020 |     78.700234 | Jan Sevcik (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey            |
| 442 |     62.049394 |    412.302285 | Zimices                                                                                                                                                               |
| 443 |    528.336358 |    615.783321 | NA                                                                                                                                                                    |
| 444 |    943.727600 |    177.519541 | Margot Michaud                                                                                                                                                        |
| 445 |    453.758551 |    655.044406 | Gareth Monger                                                                                                                                                         |
| 446 |    398.620853 |    619.947239 | Sarah Werning                                                                                                                                                         |
| 447 |    720.187621 |    183.394761 | Margot Michaud                                                                                                                                                        |
| 448 |    855.362916 |      6.675490 | Scott Hartman, modified by T. Michael Keesey                                                                                                                          |
| 449 |    228.692895 |    183.647422 | Gareth Monger                                                                                                                                                         |
| 450 |    668.758192 |    346.701968 | Matt Martyniuk                                                                                                                                                        |
| 451 |    638.336520 |    583.243389 | Melissa Broussard                                                                                                                                                     |
| 452 |    547.324036 |    640.514088 | NA                                                                                                                                                                    |
| 453 |    738.320665 |     16.616661 | Zimices                                                                                                                                                               |
| 454 |    819.960397 |    274.970478 | Zimices                                                                                                                                                               |
| 455 |   1014.528565 |    108.766789 | Sharon Wegner-Larsen                                                                                                                                                  |
| 456 |    961.988292 |    743.459304 | Zimices                                                                                                                                                               |
| 457 |    431.059770 |     83.189009 | Roberto Díaz Sibaja                                                                                                                                                   |
| 458 |    541.725466 |    397.113973 | Vijay Cavale (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey          |
| 459 |    407.139185 |    532.085217 | Sharon Wegner-Larsen                                                                                                                                                  |
| 460 |    488.706680 |    408.452669 | Zimices                                                                                                                                                               |
| 461 |    414.456083 |    514.179568 | Dean Schnabel                                                                                                                                                         |
| 462 |    863.644695 |    283.571601 | Jaime Headden                                                                                                                                                         |
| 463 |    890.618641 |    310.724102 | Margot Michaud                                                                                                                                                        |
| 464 |     69.805120 |    301.435385 | Matt Crook                                                                                                                                                            |
| 465 |     71.086794 |    782.782924 | Prathyush Thomas                                                                                                                                                      |
| 466 |     10.726361 |    351.958870 | T. Michael Keesey (vectorization) and Nadiatalent (photography)                                                                                                       |
| 467 |    318.869894 |    200.919879 | Margot Michaud                                                                                                                                                        |
| 468 |    612.611914 |     15.391036 | Birgit Lang                                                                                                                                                           |
| 469 |    898.930232 |    352.127273 | David Orr                                                                                                                                                             |
| 470 |    618.467460 |    750.740165 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 471 |    129.003361 |    347.095336 | Don Armstrong                                                                                                                                                         |
| 472 |    201.585673 |    398.550771 | Matt Crook                                                                                                                                                            |
| 473 |     77.709786 |    191.145646 | Roberto Díaz Sibaja                                                                                                                                                   |
| 474 |    987.871325 |    389.051437 | Archaeodontosaurus (vectorized by T. Michael Keesey)                                                                                                                  |
| 475 |    585.435069 |    364.567867 | Steven Traver                                                                                                                                                         |
| 476 |    276.168348 |    316.523192 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 477 |    939.028179 |     15.041274 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 478 |    466.004609 |     15.665300 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 479 |    445.230874 |     22.304479 | David Tana                                                                                                                                                            |
| 480 |    153.196561 |    582.467711 | Alex Slavenko                                                                                                                                                         |
| 481 |    550.909813 |    630.482042 | Inessa Voet                                                                                                                                                           |
| 482 |    970.499352 |    790.802095 | Siobhon Egan                                                                                                                                                          |
| 483 |    113.330422 |    289.184042 | Renata F. Martins                                                                                                                                                     |
| 484 |    363.808968 |    278.417251 | Zimices                                                                                                                                                               |
| 485 |    624.115231 |    700.096267 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 486 |    685.615954 |    499.965915 | Anthony Caravaggi                                                                                                                                                     |
| 487 |     64.060263 |     56.151274 | Adam Stuart Smith (vectorized by T. Michael Keesey)                                                                                                                   |
| 488 |    609.231501 |    433.281079 | Birgit Lang                                                                                                                                                           |
| 489 |    864.710957 |     17.820043 | Chase Brownstein                                                                                                                                                      |
| 490 |   1007.696269 |    316.718423 | FunkMonk                                                                                                                                                              |
| 491 |    850.483444 |    723.061817 | Steven Traver                                                                                                                                                         |
| 492 |    282.973696 |    549.205575 | Zimices                                                                                                                                                               |
| 493 |   1012.023126 |    539.712695 | Birgit Lang                                                                                                                                                           |
| 494 |    786.458456 |    450.223273 | Gareth Monger                                                                                                                                                         |
| 495 |    887.307349 |     66.380679 | Ferran Sayol                                                                                                                                                          |
| 496 |    843.567573 |    554.406056 | L. Shyamal                                                                                                                                                            |
| 497 |    554.750477 |    684.670219 | Lindberg (vectorized by T. Michael Keesey)                                                                                                                            |
| 498 |     94.251021 |    710.153912 | Tauana J. Cunha                                                                                                                                                       |
| 499 |    211.914170 |    687.043694 | Zimices                                                                                                                                                               |
| 500 |    190.414971 |    632.841624 | Chris huh                                                                                                                                                             |
| 501 |    723.012256 |    665.524417 | Chris huh                                                                                                                                                             |
| 502 |     42.945539 |    775.781092 | NA                                                                                                                                                                    |
| 503 |    647.469650 |    670.369304 | Gareth Monger                                                                                                                                                         |
| 504 |    826.473482 |    434.402965 | Michele M Tobias                                                                                                                                                      |
| 505 |    284.715290 |    239.691929 | Gareth Monger                                                                                                                                                         |
| 506 |    993.956971 |    209.947830 | Matt Crook                                                                                                                                                            |
| 507 |    303.679672 |    787.024144 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 508 |    858.148298 |    135.644438 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 509 |    268.970626 |    360.125785 | Birgit Lang                                                                                                                                                           |
| 510 |    956.105809 |    772.333746 | Sharon Wegner-Larsen                                                                                                                                                  |
| 511 |     46.489938 |    663.297312 | Margot Michaud                                                                                                                                                        |
| 512 |    536.583976 |    410.510146 | Matt Crook                                                                                                                                                            |
| 513 |    118.332298 |    271.514149 | Francesco Veronesi (vectorized by T. Michael Keesey)                                                                                                                  |
| 514 |    414.472950 |    592.507093 | Jaime Headden                                                                                                                                                         |
| 515 |    825.107034 |    196.806513 | Kent Elson Sorgon                                                                                                                                                     |
| 516 |    849.246285 |    187.882578 | Ludwik Gasiorowski                                                                                                                                                    |
| 517 |    151.869437 |    383.322964 | Julio Garza                                                                                                                                                           |
| 518 |    906.973512 |    146.218699 | Jakovche                                                                                                                                                              |
| 519 |    960.862691 |    227.593401 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 520 |    793.411608 |    572.438990 | Sherman F. Denton via rawpixel.com (illustration) and Timothy J. Bartley (silhouette)                                                                                 |
| 521 |    625.608850 |    434.043563 | Sharon Wegner-Larsen                                                                                                                                                  |
| 522 |    848.867771 |    461.582057 | Zimices                                                                                                                                                               |
| 523 |    808.807306 |    191.759209 | Chloé Schmidt                                                                                                                                                         |
| 524 |    226.129236 |    145.304779 | Mason McNair                                                                                                                                                          |
| 525 |     27.534513 |    463.863974 | Zimices                                                                                                                                                               |
| 526 |    174.329859 |    205.293496 | Gareth Monger                                                                                                                                                         |
| 527 |    195.467882 |    416.838268 | Gareth Monger                                                                                                                                                         |
| 528 |    411.919334 |    786.267157 | Ingo Braasch                                                                                                                                                          |
| 529 |    689.339279 |    355.474381 | SauropodomorphMonarch                                                                                                                                                 |
| 530 |     24.377709 |    244.863432 | Manabu Bessho-Uehara                                                                                                                                                  |
| 531 |    267.521718 |    204.737513 | Zimices                                                                                                                                                               |
| 532 |     15.040231 |    496.186752 | NA                                                                                                                                                                    |
| 533 |    439.991406 |    139.965898 | Zimices                                                                                                                                                               |
| 534 |    302.885496 |     23.716515 | Margot Michaud                                                                                                                                                        |
| 535 |     41.569213 |    409.290616 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 536 |    878.150820 |    415.843339 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 537 |    529.107178 |    534.949633 | Carlos Cano-Barbacil                                                                                                                                                  |
| 538 |     17.035073 |     36.471120 | T. Michael Keesey                                                                                                                                                     |
| 539 |    174.578344 |    102.866409 | Margot Michaud                                                                                                                                                        |
| 540 |    863.946074 |    158.319113 | Mathew Wedel                                                                                                                                                          |
| 541 |    258.655476 |    784.075034 | Margot Michaud                                                                                                                                                        |
| 542 |    630.781599 |     58.751146 | NA                                                                                                                                                                    |
| 543 |    353.014467 |    193.300617 | Carlos Cano-Barbacil                                                                                                                                                  |
| 544 |    672.065172 |    488.937772 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 545 |    646.900979 |    638.158265 | Lukasiniho                                                                                                                                                            |
| 546 |    823.953431 |      7.572093 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 547 |    350.986473 |     59.959702 | Terpsichores                                                                                                                                                          |
| 548 |    952.278745 |    196.446024 | NA                                                                                                                                                                    |
| 549 |    523.545408 |    546.939162 | Ferran Sayol                                                                                                                                                          |
| 550 |    924.831300 |    489.415656 | Trond R. Oskars                                                                                                                                                       |
| 551 |    645.852280 |    628.296563 | Christoph Schomburg                                                                                                                                                   |
| 552 |    884.772146 |    652.284399 | Tasman Dixon                                                                                                                                                          |
| 553 |    674.960561 |    198.995159 | Matt Crook                                                                                                                                                            |
| 554 |    859.507082 |    662.933516 | Sarah Werning                                                                                                                                                         |
| 555 |     86.782579 |    468.116178 | Zimices                                                                                                                                                               |
| 556 |    677.381372 |    703.256555 | Birgit Lang                                                                                                                                                           |
| 557 |    592.497513 |    741.490255 | Pete Buchholz                                                                                                                                                         |
| 558 |    699.750748 |    374.638460 | T. Michael Keesey (after A. Y. Ivantsov)                                                                                                                              |
| 559 |    330.910816 |     86.306851 | Ferran Sayol                                                                                                                                                          |
| 560 |    987.626705 |    369.721195 | Shyamal                                                                                                                                                               |
| 561 |    722.186416 |    504.814342 | Brockhaus and Efron                                                                                                                                                   |
| 562 |    802.188491 |    149.965755 | Margot Michaud                                                                                                                                                        |
| 563 |    727.210057 |    730.304899 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 564 |     89.294499 |    283.187680 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 565 |    559.339411 |    126.384149 | Ludwik Gasiorowski                                                                                                                                                    |
| 566 |    359.963618 |    665.276056 | Rebecca Groom                                                                                                                                                         |
| 567 |    399.561787 |    287.580199 | Jagged Fang Designs                                                                                                                                                   |
| 568 |    751.064915 |    525.636823 | Keith Murdock (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey         |
| 569 |    170.201916 |     59.855353 | Collin Gross                                                                                                                                                          |
| 570 |    153.401241 |    791.360552 | Chloé Schmidt                                                                                                                                                         |
| 571 |    825.932104 |    703.752682 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 572 |    796.063808 |    511.497158 | Felix Vaux                                                                                                                                                            |
| 573 |     79.999465 |    254.750012 | Pedro de Siracusa                                                                                                                                                     |
| 574 |    319.445502 |    668.726542 | Gareth Monger                                                                                                                                                         |
| 575 |    658.247047 |    507.963628 | Gareth Monger                                                                                                                                                         |
| 576 |    340.527821 |    344.325375 | NA                                                                                                                                                                    |
| 577 |     52.235376 |    792.027380 | FunkMonk (Michael B.H.; vectorized by T. Michael Keesey)                                                                                                              |
| 578 |    188.353258 |    676.832862 | Margot Michaud                                                                                                                                                        |
| 579 |    758.737693 |    752.292291 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 580 |    712.956037 |    445.827000 | T. Michael Keesey (photo by Darren Swim)                                                                                                                              |
| 581 |     99.860551 |    420.072015 | NA                                                                                                                                                                    |
| 582 |    364.644841 |    785.875221 | NA                                                                                                                                                                    |
| 583 |   1006.843146 |    489.483052 | Michael Scroggie                                                                                                                                                      |
| 584 |    971.158881 |    763.240091 | Noah Schlottman, photo by Antonio Guillén                                                                                                                             |
| 585 |    454.054224 |    161.332312 | Kai R. Caspar                                                                                                                                                         |
| 586 |    695.109755 |    452.144024 | Matt Crook                                                                                                                                                            |
| 587 |    394.411966 |    312.759379 | Pete Buchholz                                                                                                                                                         |
| 588 |    207.612100 |    599.690604 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 589 |    334.661764 |    106.232887 | Josefine Bohr Brask                                                                                                                                                   |
| 590 |    188.107525 |     93.444181 | Steven Traver                                                                                                                                                         |
| 591 |    467.071076 |    136.971403 | Mathew Callaghan                                                                                                                                                      |
| 592 |    818.840790 |    574.405735 | Francisco Gascó (modified by Michael P. Taylor)                                                                                                                       |
| 593 |    611.407721 |    100.812000 | Mario Quevedo                                                                                                                                                         |
| 594 |    955.131333 |    351.794463 | Sarah Werning                                                                                                                                                         |
| 595 |    976.156888 |    341.944637 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 596 |    193.468317 |    619.623859 | Maija Karala                                                                                                                                                          |
| 597 |    128.224795 |    291.550650 | NA                                                                                                                                                                    |
| 598 |    793.097717 |    599.456617 | Zimices                                                                                                                                                               |
| 599 |    979.049201 |     14.733462 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 600 |    109.483980 |    492.763157 | Mareike C. Janiak                                                                                                                                                     |
| 601 |    540.729721 |    326.822211 | Karl Ragnar Gjertsen (vectorized by T. Michael Keesey)                                                                                                                |
| 602 |    538.937000 |    710.992003 | Michele Tobias                                                                                                                                                        |
| 603 |    342.785245 |    117.821660 | NA                                                                                                                                                                    |
| 604 |    598.774162 |     51.027642 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
| 605 |     82.880374 |    320.138675 | Carlos Cano-Barbacil                                                                                                                                                  |
| 606 |    670.025728 |    475.590430 | Francisco Manuel Blanco (vectorized by T. Michael Keesey)                                                                                                             |
| 607 |    773.472686 |    184.141987 | Stephen O’Connor (vectorized by T. Michael Keesey)                                                                                                                    |
| 608 |    203.189824 |    530.847489 | Christoph Schomburg                                                                                                                                                   |
| 609 |    505.096972 |    431.038755 | Michelle Site                                                                                                                                                         |
| 610 |     54.636941 |    560.358448 | Matt Crook                                                                                                                                                            |
| 611 |    306.422796 |    127.829475 | Christoph Schomburg                                                                                                                                                   |
| 612 |   1001.714973 |    336.710254 | Ferran Sayol                                                                                                                                                          |
| 613 |    337.699952 |    767.152338 | Joanna Wolfe                                                                                                                                                          |
| 614 |    995.346319 |     38.267725 | Gareth Monger                                                                                                                                                         |
| 615 |    986.744793 |    329.604761 | Ferran Sayol                                                                                                                                                          |
| 616 |    927.848030 |    152.060054 | Tess Linden                                                                                                                                                           |
| 617 |   1015.060839 |     40.791354 | Philip Chalmers (vectorized by T. Michael Keesey)                                                                                                                     |
| 618 |    542.053081 |    554.977124 | Caleb M. Gordon                                                                                                                                                       |
| 619 |     10.661216 |    430.932596 | Matt Crook                                                                                                                                                            |
| 620 |      7.794073 |    328.213546 | Chris huh                                                                                                                                                             |
| 621 |    788.648596 |    145.011924 | Zimices                                                                                                                                                               |
| 622 |    108.720789 |    672.214163 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                     |
| 623 |    847.605396 |    446.967178 | Becky Barnes                                                                                                                                                          |
| 624 |    198.206121 |     15.134488 | Jagged Fang Designs                                                                                                                                                   |
| 625 |    545.448407 |     65.521104 | Zimices                                                                                                                                                               |
| 626 |    705.687711 |    590.021780 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 627 |    974.123837 |     85.433844 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
| 628 |    346.242771 |    100.751648 | Ferran Sayol                                                                                                                                                          |
| 629 |    411.706752 |    664.195842 | Maija Karala                                                                                                                                                          |
| 630 |    820.551874 |    347.136127 | Sarah Werning                                                                                                                                                         |
| 631 |    793.363868 |     29.990750 | NA                                                                                                                                                                    |
| 632 |    947.200061 |    692.246567 | Yan Wong from SEM by Arnau Sebé-Pedrós (PD agreed by Iñaki Ruiz-Trillo)                                                                                               |
| 633 |    916.987872 |    350.065704 | Katie S. Collins                                                                                                                                                      |
| 634 |     98.594476 |    735.288059 | NA                                                                                                                                                                    |
| 635 |    699.528261 |    189.023773 | Iain Reid                                                                                                                                                             |
| 636 |    883.933993 |    569.404070 | L. Shyamal                                                                                                                                                            |
| 637 |    561.609730 |    654.828436 | Scott Hartman                                                                                                                                                         |
| 638 |    592.133498 |     15.535456 | Scott Hartman                                                                                                                                                         |
| 639 |    174.247241 |    657.039755 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 640 |    451.329523 |    761.995425 | Gareth Monger                                                                                                                                                         |
| 641 |    520.621553 |    409.291610 | Gareth Monger                                                                                                                                                         |
| 642 |    392.039989 |    608.745955 | T. Michael Keesey                                                                                                                                                     |
| 643 |    691.936434 |    176.349457 | NA                                                                                                                                                                    |
| 644 |    514.520121 |    515.102943 | Margot Michaud                                                                                                                                                        |
| 645 |    432.425770 |    668.381416 | NA                                                                                                                                                                    |
| 646 |    402.423054 |    416.921000 | Zimices                                                                                                                                                               |
| 647 |    759.060740 |     18.528556 | Matt Crook                                                                                                                                                            |
| 648 |     23.556176 |     21.397438 | Michael Ströck (vectorized by T. Michael Keesey)                                                                                                                      |
| 649 |    827.802469 |    456.668697 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 650 |     69.186370 |    766.445686 | FunkMonk                                                                                                                                                              |
| 651 |    934.977765 |    222.513548 | Gabriel Lio, vectorized by Zimices                                                                                                                                    |
| 652 |    363.417299 |    533.429266 | Steven Traver                                                                                                                                                         |
| 653 |    383.215134 |    398.081296 | Mali’o Kodis, photograph from Jersabek et al, 2003                                                                                                                    |
| 654 |     14.790313 |    731.230908 | Ferran Sayol                                                                                                                                                          |
| 655 |    770.357328 |    558.389826 | Matt Crook                                                                                                                                                            |
| 656 |    597.267227 |    682.742746 | Cesar Julian                                                                                                                                                          |
| 657 |    376.890437 |    385.742534 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 658 |     96.910220 |    476.461645 | Matt Crook                                                                                                                                                            |
| 659 |    217.175847 |    332.989806 | Beth Reinke                                                                                                                                                           |
| 660 |    837.712624 |    651.956993 | T. Michael Keesey (after Tillyard)                                                                                                                                    |
| 661 |    618.837179 |    567.245165 | Zimices                                                                                                                                                               |
| 662 |    323.521555 |    693.447541 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                      |
| 663 |    973.166915 |     60.458280 | M Kolmann                                                                                                                                                             |
| 664 |    322.987252 |    110.627110 | Melissa Broussard                                                                                                                                                     |
| 665 |    896.186191 |    297.902670 | Chris A. Hamilton                                                                                                                                                     |
| 666 |    240.186761 |    394.899589 | Alexandre Vong                                                                                                                                                        |
| 667 |    749.387678 |     33.594648 | Steven Traver                                                                                                                                                         |
| 668 |    114.436552 |    687.446952 | Matt Crook                                                                                                                                                            |
| 669 |    971.154078 |    781.649106 | Michelle Site                                                                                                                                                         |
| 670 |     96.754069 |    701.206314 | Margot Michaud                                                                                                                                                        |
| 671 |     17.766063 |     47.445607 | NA                                                                                                                                                                    |
| 672 |    470.710916 |    198.175096 | Andrew Farke and Joseph Sertich                                                                                                                                       |
| 673 |    305.502711 |    773.799827 | Margot Michaud                                                                                                                                                        |
| 674 |    461.368353 |    641.937115 | Anthony Caravaggi                                                                                                                                                     |
| 675 |    750.209528 |    190.392109 | T. Michael Keesey                                                                                                                                                     |
| 676 |    320.484215 |    404.554846 | NA                                                                                                                                                                    |
| 677 |    776.439613 |    217.965513 | David Orr                                                                                                                                                             |
| 678 |    176.340805 |    494.179964 | NA                                                                                                                                                                    |
| 679 |    905.791118 |    191.856418 | Mykle Hoban                                                                                                                                                           |
| 680 |     78.512619 |    565.387093 | Jagged Fang Designs                                                                                                                                                   |
| 681 |    858.890634 |    301.309128 | Christoph Schomburg                                                                                                                                                   |
| 682 |    872.697900 |    559.091726 | FunkMonk                                                                                                                                                              |
| 683 |    430.426986 |    568.739353 | Henry Lydecker                                                                                                                                                        |
| 684 |    407.260288 |    388.854466 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 685 |    760.197982 |    643.504421 | Margot Michaud                                                                                                                                                        |
| 686 |    541.134535 |    383.476373 | Emily Jane McTavish                                                                                                                                                   |
| 687 |    868.245344 |    361.823073 | Dean Schnabel                                                                                                                                                         |
| 688 |    329.722599 |    757.250549 | Margot Michaud                                                                                                                                                        |
| 689 |     60.004193 |    141.451386 | Ferran Sayol                                                                                                                                                          |
| 690 |    403.538867 |    204.689317 | Ferran Sayol                                                                                                                                                          |
| 691 |    849.703471 |    272.706560 | Patrick Fisher (vectorized by T. Michael Keesey)                                                                                                                      |
| 692 |   1012.855264 |    591.595340 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 693 |     93.809322 |    494.270985 | Steven Traver                                                                                                                                                         |
| 694 |    935.655107 |     30.438912 | Gareth Monger                                                                                                                                                         |
| 695 |    866.702596 |    760.083860 | Renata F. Martins                                                                                                                                                     |
| 696 |    323.291355 |    268.063997 | Yan Wong                                                                                                                                                              |
| 697 |    726.260226 |    748.541533 | Chris huh                                                                                                                                                             |
| 698 |    637.293262 |    647.423828 | Chase Brownstein                                                                                                                                                      |
| 699 |     34.861820 |    508.077877 | NA                                                                                                                                                                    |
| 700 |    214.406654 |    515.937154 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 701 |    676.755547 |    627.457697 | Margot Michaud                                                                                                                                                        |
| 702 |    355.496415 |    114.739911 | Felix Vaux                                                                                                                                                            |
| 703 |    180.965608 |      8.245087 | Matt Crook                                                                                                                                                            |
| 704 |     10.928783 |    779.802159 | Steven Traver                                                                                                                                                         |
| 705 |    605.436645 |    466.435144 | Ferran Sayol                                                                                                                                                          |
| 706 |    493.521176 |    130.224850 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 707 |    605.442249 |    333.754134 | Gareth Monger                                                                                                                                                         |
| 708 |    219.631282 |    614.528950 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                  |
| 709 |    753.464697 |    789.092460 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 710 |     93.798547 |    555.106426 | Tim H. Heupink, Leon Huynen, and David M. Lambert (vectorized by T. Michael Keesey)                                                                                   |
| 711 |    323.300180 |    577.678924 | Yan Wong                                                                                                                                                              |
| 712 |     26.651068 |     89.695501 | Matt Crook                                                                                                                                                            |
| 713 |    520.971727 |    277.661095 | Yan Wong                                                                                                                                                              |
| 714 |     25.074434 |    519.837095 | Matt Crook                                                                                                                                                            |
| 715 |    318.593276 |     97.044008 | FunkMonk                                                                                                                                                              |
| 716 |    306.755279 |    218.059006 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 717 |    534.466882 |    385.811389 | Saguaro Pictures (source photo) and T. Michael Keesey                                                                                                                 |
| 718 |    973.823407 |     97.666995 | T. Michael Keesey                                                                                                                                                     |
| 719 |    586.462682 |    308.983893 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 720 |    310.008066 |    382.126886 | Maija Karala                                                                                                                                                          |
| 721 |     12.381230 |    110.844926 | Claus Rebler                                                                                                                                                          |
| 722 |    877.718605 |    690.801735 | Jake Warner                                                                                                                                                           |
| 723 |    276.999159 |     31.399800 | NA                                                                                                                                                                    |
| 724 |    685.938579 |    665.403398 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 725 |     65.744195 |    692.524072 | Beth Reinke                                                                                                                                                           |
| 726 |    621.790958 |    680.332908 | Zimices                                                                                                                                                               |
| 727 |    440.224652 |    795.365855 | Emily Willoughby                                                                                                                                                      |
| 728 |    400.449668 |    794.681393 | NA                                                                                                                                                                    |
| 729 |    947.895255 |    660.743926 | Mali’o Kodis, photograph by P. Funch and R.M. Kristensen                                                                                                              |
| 730 |    394.678256 |    361.058522 | Gareth Monger                                                                                                                                                         |
| 731 |      9.808801 |    153.035235 | Matt Crook                                                                                                                                                            |
| 732 |     48.953794 |     76.218040 | Zimices                                                                                                                                                               |
| 733 |      8.018647 |    280.868559 | Matt Crook                                                                                                                                                            |
| 734 |    637.113061 |    503.851692 | Ludwik Gasiorowski                                                                                                                                                    |
| 735 |    379.161637 |    507.576098 | Sarah Werning                                                                                                                                                         |
| 736 |    176.273694 |    246.800295 | Scott Hartman                                                                                                                                                         |
| 737 |    964.680682 |    474.602069 | NA                                                                                                                                                                    |
| 738 |    597.040184 |      7.145703 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 739 |    705.076132 |    469.820752 | CNZdenek                                                                                                                                                              |
| 740 |    841.832040 |    366.427549 | Zimices                                                                                                                                                               |
| 741 |    438.666644 |    740.891491 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 742 |     11.600491 |    443.814814 | Ferran Sayol                                                                                                                                                          |
| 743 |    342.887992 |    488.174284 | Steven Traver                                                                                                                                                         |
| 744 |    577.684150 |    750.080615 | Scott Hartman                                                                                                                                                         |
| 745 |    442.521016 |    416.762551 | Chris huh                                                                                                                                                             |
| 746 |    849.035186 |    374.440494 | Beth Reinke                                                                                                                                                           |
| 747 |    836.572629 |    278.744820 | Oscar Sanisidro                                                                                                                                                       |
| 748 |     84.765050 |    536.231700 | Ferran Sayol                                                                                                                                                          |
| 749 |    948.777562 |     96.860634 | Sarah Werning                                                                                                                                                         |
| 750 |    210.646181 |    671.639107 | Matt Crook                                                                                                                                                            |
| 751 |    391.154683 |    323.311137 | Zimices                                                                                                                                                               |
| 752 |     63.445046 |    181.622567 | Steven Traver                                                                                                                                                         |
| 753 |    540.652231 |    366.157642 | T. Michael Keesey                                                                                                                                                     |
| 754 |     44.301848 |     27.058684 | Martin R. Smith                                                                                                                                                       |
| 755 |     24.937624 |    707.548742 | Matt Crook                                                                                                                                                            |
| 756 |    581.731739 |    319.321906 | Gareth Monger                                                                                                                                                         |
| 757 |    137.518149 |    674.946789 | Margot Michaud                                                                                                                                                        |
| 758 |    930.630730 |    776.751391 | Ghedoghedo, vectorized by Zimices                                                                                                                                     |
| 759 |    271.003122 |    349.668622 | Mark Hannaford (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey        |
| 760 |    421.631020 |     24.720337 | Alexandra van der Geer                                                                                                                                                |
| 761 |    299.046038 |    423.837827 | Jonathan Wells                                                                                                                                                        |
| 762 |    136.220116 |    781.468857 | Dean Schnabel                                                                                                                                                         |
| 763 |    363.731559 |    139.541241 | Alex Slavenko                                                                                                                                                         |
| 764 |    819.380523 |    221.884113 | Zimices                                                                                                                                                               |
| 765 |    759.158432 |    175.370108 | Margot Michaud                                                                                                                                                        |
| 766 |    870.972407 |    786.489062 | Chris huh                                                                                                                                                             |
| 767 |    631.988778 |    671.864368 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 768 |    849.944114 |    387.412220 | Xavier Giroux-Bougard                                                                                                                                                 |
| 769 |    104.851247 |    427.156249 | Scott Hartman                                                                                                                                                         |
| 770 |    426.276035 |    199.042599 | Margot Michaud                                                                                                                                                        |
| 771 |    926.788125 |    209.946519 | Scott Hartman                                                                                                                                                         |
| 772 |    999.154582 |     69.993443 | Gareth Monger                                                                                                                                                         |
| 773 |    943.558043 |    212.991079 | Scott Hartman                                                                                                                                                         |
| 774 |    137.584601 |    211.601228 | T. Michael Keesey (after A. Y. Ivantsov)                                                                                                                              |
| 775 |    157.014680 |     70.597160 | NA                                                                                                                                                                    |
| 776 |    602.628477 |    318.237421 | Matt Martyniuk                                                                                                                                                        |
| 777 |    523.944391 |    569.624958 | Lafage                                                                                                                                                                |
| 778 |    217.224758 |    492.546525 | Arthur S. Brum                                                                                                                                                        |
| 779 |    616.720011 |    742.188189 | Scott Hartman                                                                                                                                                         |
| 780 |    436.173644 |    553.584268 | Pollyanna von Knorring and T. Michael Keesey                                                                                                                          |
| 781 |    568.480723 |    351.382637 | Zimices                                                                                                                                                               |
| 782 |    155.608648 |    560.672189 | Catherine Yasuda                                                                                                                                                      |
| 783 |    224.179087 |    530.982617 | Abraão Leite                                                                                                                                                          |
| 784 |    139.853597 |    590.070482 | C. Camilo Julián-Caballero                                                                                                                                            |
| 785 |    291.418632 |    189.404370 | Roberto Diaz Sibaja, based on Domser                                                                                                                                  |
| 786 |    591.585024 |    378.287716 | Katie S. Collins                                                                                                                                                      |
| 787 |    990.916003 |    467.441814 | Roberto Díaz Sibaja                                                                                                                                                   |
| 788 |    443.198464 |    613.636006 | Jagged Fang Designs                                                                                                                                                   |
| 789 |    864.543418 |    268.625137 | Margot Michaud                                                                                                                                                        |
| 790 |    374.650921 |    744.508970 | Joanna Wolfe                                                                                                                                                          |
| 791 |    805.922312 |    215.611092 | NA                                                                                                                                                                    |
| 792 |    719.487207 |      3.180924 | Dave Souza (vectorized by T. Michael Keesey)                                                                                                                          |
| 793 |    435.006028 |    517.883173 | Michael Scroggie                                                                                                                                                      |
| 794 |    861.852275 |    704.984536 | Tauana J. Cunha                                                                                                                                                       |
| 795 |    562.919479 |    385.402228 | Tasman Dixon                                                                                                                                                          |
| 796 |    957.477026 |    454.846853 | Zimices                                                                                                                                                               |
| 797 |     46.390819 |     49.013896 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 798 |    402.229353 |    296.624769 | xgirouxb                                                                                                                                                              |
| 799 |    394.946617 |    108.853983 | Ferran Sayol                                                                                                                                                          |
| 800 |     81.083013 |     62.964498 | Jagged Fang Designs                                                                                                                                                   |
| 801 |    529.953504 |    523.397085 | Yan Wong from SEM by Arnau Sebé-Pedrós (PD agreed by Iñaki Ruiz-Trillo)                                                                                               |
| 802 |    161.176984 |    551.051779 | NA                                                                                                                                                                    |
| 803 |    502.199206 |    165.116298 | Juan Carlos Jerí                                                                                                                                                      |
| 804 |    373.856321 |    581.617767 | NA                                                                                                                                                                    |
| 805 |    536.411157 |    721.516349 | NA                                                                                                                                                                    |
| 806 |    233.466544 |    255.747559 | Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus                                              |
| 807 |    940.055435 |    313.578162 | Cesar Julian                                                                                                                                                          |
| 808 |    863.395986 |    540.809980 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 809 |    257.462590 |    343.098509 | Lukasiniho                                                                                                                                                            |
| 810 |    827.721304 |    478.449281 | FunkMonk                                                                                                                                                              |
| 811 |    924.994314 |    307.109947 | Matt Crook                                                                                                                                                            |
| 812 |     67.498837 |    163.246166 | Zimices                                                                                                                                                               |
| 813 |    362.261213 |    648.505346 | Alex Slavenko                                                                                                                                                         |
| 814 |    260.415463 |     22.784488 | NA                                                                                                                                                                    |
| 815 |    276.736749 |    571.120448 | NA                                                                                                                                                                    |
| 816 |    131.540875 |    691.749156 | NA                                                                                                                                                                    |
| 817 |    864.914650 |    458.433856 | Gareth Monger                                                                                                                                                         |
| 818 |    411.677937 |     17.515569 | Noah Schlottman, photo by David J Patterson                                                                                                                           |
| 819 |    935.259443 |    181.109387 | Shyamal                                                                                                                                                               |
| 820 |    568.214610 |    542.326084 | Matt Crook                                                                                                                                                            |
| 821 |    741.858298 |    634.429727 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 822 |    265.176224 |    170.949636 | Steven Haddock • Jellywatch.org                                                                                                                                       |
| 823 |    881.489831 |     28.723350 | Margot Michaud                                                                                                                                                        |
| 824 |    284.711996 |    618.818366 | Steven Coombs                                                                                                                                                         |
| 825 |    569.121843 |      8.650450 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 826 |    946.262657 |    790.018402 | Zimices                                                                                                                                                               |
| 827 |    176.741525 |    670.911833 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                     |
| 828 |    252.398968 |    258.685651 | NA                                                                                                                                                                    |
| 829 |    321.806891 |    464.251150 | Konsta Happonen, from a CC-BY-NC image by pelhonen on iNaturalist                                                                                                     |
| 830 |    473.364373 |    313.211266 | Cagri Cevrim                                                                                                                                                          |
| 831 |    776.954962 |    165.457067 | Mali’o Kodis, photograph by Aqua-Photos (<http://www.flickr.com/people/undervannsfotografen/>)                                                                        |
| 832 |    849.454883 |    691.659092 | Zimices                                                                                                                                                               |
| 833 |    383.429270 |    361.717156 | Gareth Monger                                                                                                                                                         |
| 834 |    811.422595 |    469.341378 | Matt Crook                                                                                                                                                            |
| 835 |    613.340542 |    444.490109 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                       |
| 836 |    376.813341 |    526.159893 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 837 |    571.138668 |    684.262481 | Matt Martyniuk                                                                                                                                                        |
| 838 |    213.589215 |    306.161998 | Anthony Caravaggi                                                                                                                                                     |
| 839 |     63.314942 |    347.743600 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 840 |    474.120670 |    436.642865 | NA                                                                                                                                                                    |
| 841 |    892.184032 |    150.458744 | Zimices                                                                                                                                                               |
| 842 |    135.955874 |     78.346693 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 843 |    702.181687 |    665.508837 | Nicolas Huet le Jeune and Jean-Gabriel Prêtre (vectorized by T. Michael Keesey)                                                                                       |
| 844 |      9.070369 |     62.452298 | Matt Crook                                                                                                                                                            |
| 845 |    306.437552 |     63.540861 | Birgit Lang                                                                                                                                                           |
| 846 |    897.231595 |    643.078523 | Zimices                                                                                                                                                               |
| 847 |    261.448287 |    285.065466 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 848 |    661.693723 |    365.856289 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 849 |    434.627684 |    165.402116 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
| 850 |    193.166449 |    479.507929 | Steven Traver                                                                                                                                                         |
| 851 |    575.384076 |    572.503561 | Myriam\_Ramirez                                                                                                                                                       |
| 852 |    158.196322 |    571.300218 | Tracy A. Heath                                                                                                                                                        |
| 853 |    489.242384 |    105.619249 | NA                                                                                                                                                                    |
| 854 |    199.849344 |    258.720691 | Scott Hartman                                                                                                                                                         |
| 855 |    853.810266 |    654.607662 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                                         |
| 856 |    323.481467 |    517.203977 | Sarah Werning                                                                                                                                                         |
| 857 |    324.777104 |    777.491678 | Matt Crook                                                                                                                                                            |
| 858 |    325.662491 |     25.894361 | NA                                                                                                                                                                    |
| 859 |    235.761104 |    536.481988 | Luc Viatour (source photo) and Andreas Plank                                                                                                                          |
| 860 |     47.941107 |      4.361656 | Margot Michaud                                                                                                                                                        |
| 861 |     32.913647 |    739.289541 | Sharon Wegner-Larsen                                                                                                                                                  |
| 862 |    533.089656 |    376.403050 | Nicholas J. Czaplewski, vectorized by Zimices                                                                                                                         |
| 863 |    626.025513 |    523.360875 | Fernando Carezzano                                                                                                                                                    |
| 864 |     64.813743 |    365.304199 | Margot Michaud                                                                                                                                                        |
| 865 |    820.124664 |    636.960629 | Milton Tan                                                                                                                                                            |
| 866 |    989.600237 |    352.907459 | Gareth Monger                                                                                                                                                         |
| 867 |    880.495440 |    642.411678 | Michelle Site                                                                                                                                                         |
| 868 |    763.763259 |    793.357952 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 869 |    932.571029 |    765.866764 | L. Shyamal                                                                                                                                                            |
| 870 |    226.643682 |    237.500374 | Scott Hartman                                                                                                                                                         |
| 871 |     15.161929 |    509.948766 | Mark Miller                                                                                                                                                           |
| 872 |    620.897865 |    419.850678 | Ingo Braasch                                                                                                                                                          |
| 873 |     19.349016 |    127.731276 | Gareth Monger                                                                                                                                                         |
| 874 |    781.486436 |    653.607236 | Chris huh                                                                                                                                                             |
| 875 |    976.220142 |     28.080510 | Martin R. Smith, from photo by Jürgen Schoner                                                                                                                         |
| 876 |    664.247911 |    499.977139 | Steven Traver                                                                                                                                                         |
| 877 |    942.200035 |     83.112947 | Christoph Schomburg                                                                                                                                                   |
| 878 |    327.083736 |    630.421504 | Cagri Cevrim                                                                                                                                                          |
| 879 |    670.283701 |    580.011008 | Chris huh                                                                                                                                                             |
| 880 |    779.907663 |    393.625274 | Julio Garza                                                                                                                                                           |
| 881 |     75.527959 |    308.926528 | Zimices                                                                                                                                                               |
| 882 |    730.781800 |     40.427863 | Steven Traver                                                                                                                                                         |
| 883 |    295.413819 |    340.017051 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 884 |    762.944073 |    192.256979 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 885 |    163.717098 |    641.007697 | Beth Reinke                                                                                                                                                           |
| 886 |    401.637869 |    152.989465 | \[unknown\]                                                                                                                                                           |
| 887 |    465.656993 |     77.562520 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 888 |      7.851093 |    479.622057 | Collin Gross                                                                                                                                                          |
| 889 |     21.916551 |    394.391554 | Sarah Werning                                                                                                                                                         |
| 890 |    976.579806 |    356.250052 | Dr. Thomas G. Barnes, USFWS                                                                                                                                           |
| 891 |    295.315421 |     17.745127 | Zimices                                                                                                                                                               |
| 892 |    342.003316 |    703.620139 | Steven Traver                                                                                                                                                         |
| 893 |    859.425896 |    343.288726 | Chase Brownstein                                                                                                                                                      |
| 894 |     12.762744 |    332.118302 | Lukas Panzarin (vectorized by T. Michael Keesey)                                                                                                                      |
| 895 |    829.316176 |     34.196999 | Scott Hartman                                                                                                                                                         |
| 896 |    968.065687 |    240.154950 | Beth Reinke                                                                                                                                                           |
| 897 |    144.718097 |    500.265118 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 898 |    816.169451 |     68.166726 | Chris huh                                                                                                                                                             |
| 899 |    845.273636 |    421.201525 | Jagged Fang Designs                                                                                                                                                   |
| 900 |    293.324812 |    304.007651 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 901 |    632.850490 |    464.869756 | T. Michael Keesey (after Ponomarenko)                                                                                                                                 |
| 902 |    592.005114 |    693.457795 | T. Michael Keesey                                                                                                                                                     |
| 903 |    782.160557 |    791.843396 | Philip Chalmers (vectorized by T. Michael Keesey)                                                                                                                     |
| 904 |    485.714141 |    635.134948 | T. Michael Keesey                                                                                                                                                     |
| 905 |     13.446452 |    593.448207 | Gareth Monger                                                                                                                                                         |
| 906 |    213.843068 |     92.418862 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 907 |    992.934872 |     47.796136 | Nina Skinner                                                                                                                                                          |
| 908 |     31.497131 |    720.054183 | Dean Schnabel                                                                                                                                                         |
| 909 |    785.703642 |    523.254414 | Joanna Wolfe                                                                                                                                                          |
| 910 |    293.950722 |    132.025640 | Margot Michaud                                                                                                                                                        |
| 911 |    919.837375 |    537.872029 | L. Shyamal                                                                                                                                                            |
| 912 |    199.455944 |    334.901453 | Margot Michaud                                                                                                                                                        |
| 913 |    319.199424 |     80.156806 | Sharon Wegner-Larsen                                                                                                                                                  |
| 914 |    600.305105 |    795.917147 | Iain Reid                                                                                                                                                             |
| 915 |    376.263029 |    640.242543 | Doug Backlund (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey         |
| 916 |    793.349895 |    223.804467 | Matt Crook                                                                                                                                                            |
| 917 |      7.854032 |    409.599571 | Martin R. Smith                                                                                                                                                       |

    #> Your tweet has been posted!
