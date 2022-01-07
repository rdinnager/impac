
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

Tasman Dixon, Joseph J. W. Sertich, Mark A. Loewen, Chris huh, Matt
Martyniuk, Gabriela Palomo-Munoz, T. Michael Keesey (after Monika
Betley), Matt Crook, Margot Michaud, M Kolmann, Gareth Monger, Zimices,
Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow
(vectorized by T. Michael Keesey), DFoidl (vectorized by T. Michael
Keesey), Robbie N. Cada (modified by T. Michael Keesey), Lafage, Cagri
Cevrim, Beth Reinke, Anthony Caravaggi, Maxime Dahirel, Scott Hartman,
Joedison Rocha, T. Michael Keesey, Joanna Wolfe, Smokeybjb, Collin
Gross, Philippe Janvier (vectorized by T. Michael Keesey), Mathew
Stewart, Lily Hughes, Burton Robert, USFWS, Dmitry Bogdanov (vectorized
by T. Michael Keesey), Noah Schlottman, photo by Gustav Paulay for
Moorea Biocode, Pearson Scott Foresman (vectorized by T. Michael
Keesey), Young and Zhao (1972:figure 4), modified by Michael P. Taylor,
Karina Garcia, Jaime Headden, Christoph Schomburg, Martin R. Smith,
Rebecca Groom, Ferran Sayol, Apokryltaros (vectorized by T. Michael
Keesey), Noah Schlottman, Noah Schlottman, photo by Martin V. Sørensen,
C. Camilo Julián-Caballero, Tyler Greenfield and Scott Hartman, John
Conway, Steven Traver, CNZdenek, Peter Coxhead, Mathieu Basille, M.
Antonio Todaro, Tobias Kånneby, Matteo Dal Zotto, and Ulf Jondelius
(vectorized by T. Michael Keesey), Nobu Tamura (vectorized by T. Michael
Keesey), Arthur S. Brum, Kai R. Caspar, Jagged Fang Designs, Obsidian
Soul (vectorized by T. Michael Keesey), Sergio A. Muñoz-Gómez, Mathilde
Cordellier, Dave Angelini, Roberto Díaz Sibaja, Lukasiniho, Andrew A.
Farke, Farelli (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Mike Keesey (vectorization) and Vaibhavcho
(photography), Enoch Joseph Wetsy (photo), John E. McCormack, Michael G.
Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb
T. Brumfield & T. Michael Keesey, Alexander Schmidt-Lebuhn, Jose Carlos
Arenas-Monroy, Matthew E. Clapham, LeonardoG (photography) and T.
Michael Keesey (vectorization), Mariana Ruiz Villarreal, Michelle Site,
New York Zoological Society, NOAA Great Lakes Environmental Research
Laboratory (illustration) and Timothy J. Bartley (silhouette), Ray
Simpson (vectorized by T. Michael Keesey), Noah Schlottman, photo from
Casey Dunn, Birgit Lang; original image by virmisco.org, Charles R.
Knight, vectorized by Zimices, Michele M Tobias from an image By Dcrjsr
- Own work, CC BY 3.0,
<https://commons.wikimedia.org/w/index.php?curid=18059686>, (after
Spotila 2004), Ingo Braasch, Mathew Wedel, Mark Miller, Maha Ghazal,
Pete Buchholz, xgirouxb, Geoff Shaw, Becky Barnes, Lisa Byrne, T.
Michael Keesey (after James & al.), Sharon Wegner-Larsen, Maija Karala,
Sarah Werning, Iain Reid, Prin Pattawaro (photo), John E. McCormack,
Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C.
Glenn, Robb T. Brumfield & T. Michael Keesey, JCGiron, Michael Scroggie,
RS, Darren Naish (vectorize by T. Michael Keesey), Johan Lindgren,
Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe, Dmitry Bogdanov,
vectorized by Zimices, Rafael Maia, SauropodomorphMonarch, Mali’o Kodis,
image from the “Proceedings of the Zoological Society of London”, Markus
A. Grohme, Scott Reid, Cristian Osorio & Paula Carrera, Proyecto
Carnivoros Australes (www.carnivorosaustrales.org), Michael Day,
Smokeybjb (vectorized by T. Michael Keesey), Notafly (vectorized by T.
Michael Keesey), Kimberly Haddrell, Berivan Temiz, (after McCulloch
1908), Emily Willoughby, Ville-Veikko Sinkkonen, Cesar Julian, Caroline
Harding, MAF (vectorized by T. Michael Keesey), Chuanixn Yu, Birgit
Lang, Noah Schlottman, photo by Reinhard Jahn, Sean McCann, T. Michael
Keesey (after MPF), Manabu Bessho-Uehara, Agnello Picorelli, Katie S.
Collins, Mali’o Kodis, photograph by Aqua-Photos
(<http://www.flickr.com/people/undervannsfotografen/>), david maas /
dave hone, Yan Wong from illustration by Jules Richard (1907), J. J.
Harrison (photo) & T. Michael Keesey, James R. Spotila and Ray
Chatterji, David Orr, Chase Brownstein, Jack Mayer Wood, T. Michael
Keesey (after Kukalová), Kamil S. Jaron, M. A. Broussard, Nobu Tamura
and T. Michael Keesey, Antonov (vectorized by T. Michael Keesey), Tony
Ayling (vectorized by T. Michael Keesey), Ernst Haeckel (vectorized by
T. Michael Keesey), Jon Hill, Y. de Hoev. (vectorized by T. Michael
Keesey), Shyamal, Nobu Tamura, vectorized by Zimices, Felix Vaux,
Ignacio Contreras, Kelly, Fernando Campos De Domenico, Matthias
Buschmann (vectorized by T. Michael Keesey), Neil Kelley, Peileppe, Noah
Schlottman, photo by Casey Dunn, Smokeybjb, vectorized by Zimices, James
I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel,
and Jelle P. Wiersma (vectorized by T. Michael Keesey), Milton Tan,
Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja,
Tomas Willems (vectorized by T. Michael Keesey), Christopher Watson
(photo) and T. Michael Keesey (vectorization), Tracy A. Heath, Hans
Hillewaert, V. Deepak, Mali’o Kodis, photograph by Hans Hillewaert,
Crystal Maier, Harold N Eyster, Tauana J. Cunha, Robert Gay, Lauren
Anderson, Nobu Tamura (modified by T. Michael Keesey), J Levin W
(illustration) and T. Michael Keesey (vectorization), Julien Louys, Ryan
Cupo, FunkMonk, Nobu Tamura, Jimmy Bernot, Bruno C. Vellutini, Jakovche,
Didier Descouens (vectorized by T. Michael Keesey), Matt Dempsey, Jaime
Chirinos (vectorized by T. Michael Keesey), Stuart Humphries, Scott D.
Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A.
Forster, Joshua A. Smith, Alan L. Titus, Marcos Pérez-Losada, Jens T.
Høeg & Keith A. Crandall, Douglas Brown (modified by T. Michael
Keesey), Lee Harding (photo), John E. McCormack, Michael G. Harvey,
Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T.
Brumfield & T. Michael Keesey, Noah Schlottman, photo by Antonio
Guillén, Sherman Foote Denton (illustration, 1897) and Timothy J.
Bartley (silhouette), T. Michael Keesey (photo by Darren Swim), Manabu
Sakamoto, Dr. Thomas G. Barnes, USFWS, Yan Wong from drawing by Joseph
Smit, Alex Slavenko, Tommaso Cancellario, Conty (vectorized by T.
Michael Keesey), Chloé Schmidt, Verdilak, Keith Murdock (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Mo Hassan,
Cathy, Kevin Sánchez, Kent Elson Sorgon, Steven Coombs, Robert Gay,
modified from FunkMonk (Michael B.H.) and T. Michael Keesey., NASA,
Scott Hartman (vectorized by T. Michael Keesey), Juan Carlos Jerí, Todd
Marshall, vectorized by Zimices, Esme Ashe-Jepson, L. Shyamal,
Ghedoghedo (vectorized by T. Michael Keesey), Michele M Tobias, Sherman
F. Denton via rawpixel.com (illustration) and Timothy J. Bartley
(silhouette), H. F. O. March (vectorized by T. Michael Keesey), Joseph
Wolf, 1863 (vectorization by Dinah Challen), Paul Baker (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, DW Bapst,
modified from Figure 1 of Belanger (2011, PALAIOS)., Brad McFeeters
(vectorized by T. Michael Keesey), Diego Fontaneto, Elisabeth A.
Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia
Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey), Ian
Burt (original) and T. Michael Keesey (vectorization), Hans Hillewaert
(vectorized by T. Michael Keesey), Kailah Thorn & Ben King, Christopher
Laumer (vectorized by T. Michael Keesey), Caleb M. Brown, Chris Jennings
(Risiatto), Chris A. Hamilton, Sidney Frederic Harmer, Arthur Everett
Shipley (vectorized by Maxime Dahirel), Julio Garza,
\<U+0412\>\<U+0430\>\<U+043B\>\<U+044C\>\<U+0434\>\<U+0438\>\<U+043C\>\<U+0430\>\<U+0440\>
(vectorized by T. Michael Keesey), Robert Gay, modifed from Olegivvit,
Matus Valach, Leann Biancani, photo by Kenneth Clifton, H. F. O. March
(modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel),
Kailah Thorn & Mark Hutchinson, Ekaterina Kopeykina (vectorized by T.
Michael Keesey), Marmelad, Melissa Broussard, Charles R. Knight
(vectorized by T. Michael Keesey), Oscar Sanisidro, T. K. Robinson, Dean
Schnabel, Mali’o Kodis, image from Brockhaus and Efron Encyclopedic
Dictionary, Oliver Voigt, Mali’o Kodis, traced image from the National
Science Foundation’s Turbellarian Taxonomic Database, FJDegrange, Carlos
Cano-Barbacil, M. Garfield & K. Anderson (modified by T. Michael
Keesey), Javier Luque & Sarah Gerken, Alan Manson (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Abraão Leite, C.
W. Nash (illustration) and Timothy J. Bartley (silhouette), Mattia
Menchetti / Yan Wong, Estelle Bourdon, kreidefossilien.de, Mike Hanson,
SecretJellyMan, Francesca Belem Lopes Palmeira, Maxwell Lefroy
(vectorized by T. Michael Keesey), Mali’o Kodis, photograph from
Jersabek et al, 2003, Inessa Voet, Leon P. A. M. Claessens, Patrick M.
O’Connor, David M. Unwin, Baheerathan Murugavel, A. H. Baldwin
(vectorized by T. Michael Keesey), Noah Schlottman, photo from National
Science Foundation - Turbellarian Taxonomic Database, Darius Nau, Luis
Cunha, Oliver Griffith, Chris Jennings (vectorized by A. Verrière), Noah
Schlottman, photo by Museum of Geology, University of Tartu, Michael
“FunkMonk” B. H. (vectorized by T. Michael Keesey), DW Bapst (modified
from Bulman, 1970), Mathew Callaghan, Yan Wong (vectorization) from 1873
illustration, Xavier Giroux-Bougard, Mali’o Kodis, photograph from
<http://commons.wikimedia.org/wiki/File:Trichoplax.jpg>, Matt Martyniuk
(vectorized by T. Michael Keesey), Yan Wong, Derek Bakken (photograph)
and T. Michael Keesey (vectorization)

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    386.266976 |     98.427552 | Tasman Dixon                                                                                                                                                          |
|   2 |    476.616198 |    414.691903 | Joseph J. W. Sertich, Mark A. Loewen                                                                                                                                  |
|   3 |    147.139707 |    183.403438 | Chris huh                                                                                                                                                             |
|   4 |    865.812243 |    435.369348 | Matt Martyniuk                                                                                                                                                        |
|   5 |    491.247018 |    454.135863 | Gabriela Palomo-Munoz                                                                                                                                                 |
|   6 |    437.137015 |    299.675567 | T. Michael Keesey (after Monika Betley)                                                                                                                               |
|   7 |    284.735809 |    226.633378 | Matt Crook                                                                                                                                                            |
|   8 |    665.676293 |    433.263250 | Margot Michaud                                                                                                                                                        |
|   9 |    271.444017 |    381.046753 | M Kolmann                                                                                                                                                             |
|  10 |    697.133649 |    206.815016 | Gareth Monger                                                                                                                                                         |
|  11 |    630.211899 |    677.536142 | Margot Michaud                                                                                                                                                        |
|  12 |    480.191274 |    530.416240 | Zimices                                                                                                                                                               |
|  13 |    252.682854 |    620.883514 | Margot Michaud                                                                                                                                                        |
|  14 |    345.711621 |    333.347696 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
|  15 |    735.136113 |    110.370846 | DFoidl (vectorized by T. Michael Keesey)                                                                                                                              |
|  16 |    164.362993 |    633.307400 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                                        |
|  17 |    902.791780 |    146.112155 | Lafage                                                                                                                                                                |
|  18 |    107.863480 |    477.943163 | NA                                                                                                                                                                    |
|  19 |    582.004361 |    164.758350 | Cagri Cevrim                                                                                                                                                          |
|  20 |    167.096014 |     46.427468 | Beth Reinke                                                                                                                                                           |
|  21 |    619.181937 |    554.920027 | Anthony Caravaggi                                                                                                                                                     |
|  22 |    722.416752 |    509.607095 | Maxime Dahirel                                                                                                                                                        |
|  23 |    768.009229 |    326.719567 | Scott Hartman                                                                                                                                                         |
|  24 |    199.789930 |    378.283460 | Joedison Rocha                                                                                                                                                        |
|  25 |    848.200089 |    624.441205 | Matt Crook                                                                                                                                                            |
|  26 |    952.246119 |    534.011516 | T. Michael Keesey                                                                                                                                                     |
|  27 |     69.008497 |    729.835768 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  28 |    365.771109 |    489.980498 | Joanna Wolfe                                                                                                                                                          |
|  29 |    344.571637 |    744.881541 | Smokeybjb                                                                                                                                                             |
|  30 |    402.396546 |    671.067420 | Tasman Dixon                                                                                                                                                          |
|  31 |    145.977766 |    240.539831 | Collin Gross                                                                                                                                                          |
|  32 |    597.122947 |    303.328800 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
|  33 |    814.022735 |    243.293641 | Philippe Janvier (vectorized by T. Michael Keesey)                                                                                                                    |
|  34 |    527.814623 |    713.324219 | Zimices                                                                                                                                                               |
|  35 |    951.715100 |    685.622436 | Mathew Stewart                                                                                                                                                        |
|  36 |    493.821982 |     53.701667 | Lily Hughes                                                                                                                                                           |
|  37 |    939.946768 |    257.018185 | NA                                                                                                                                                                    |
|  38 |     57.280300 |    135.380533 | Burton Robert, USFWS                                                                                                                                                  |
|  39 |    847.278570 |    712.024266 | NA                                                                                                                                                                    |
|  40 |    468.503430 |    178.669515 | Gareth Monger                                                                                                                                                         |
|  41 |    216.379095 |    159.492847 | Collin Gross                                                                                                                                                          |
|  42 |    789.834540 |    186.255083 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  43 |     86.184995 |    286.625008 | Noah Schlottman, photo by Gustav Paulay for Moorea Biocode                                                                                                            |
|  44 |    810.731950 |     64.781628 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                              |
|  45 |    378.757177 |    577.621760 | NA                                                                                                                                                                    |
|  46 |    636.239227 |    372.936234 | Margot Michaud                                                                                                                                                        |
|  47 |    783.906195 |    560.749206 | NA                                                                                                                                                                    |
|  48 |    634.914427 |     77.715538 | Collin Gross                                                                                                                                                          |
|  49 |    652.965201 |    763.068384 | Young and Zhao (1972:figure 4), modified by Michael P. Taylor                                                                                                         |
|  50 |    957.893046 |     55.631088 | Scott Hartman                                                                                                                                                         |
|  51 |    214.597529 |    702.531286 | Scott Hartman                                                                                                                                                         |
|  52 |    331.173228 |     16.089584 | Chris huh                                                                                                                                                             |
|  53 |    480.944617 |    629.068732 | Margot Michaud                                                                                                                                                        |
|  54 |    738.187850 |    635.059000 | Karina Garcia                                                                                                                                                         |
|  55 |    947.767637 |    103.257301 | Jaime Headden                                                                                                                                                         |
|  56 |    847.976863 |    779.199486 | NA                                                                                                                                                                    |
|  57 |    325.198668 |    245.599744 | Matt Crook                                                                                                                                                            |
|  58 |    268.182203 |    501.691892 | Christoph Schomburg                                                                                                                                                   |
|  59 |    446.028944 |    772.152354 | Margot Michaud                                                                                                                                                        |
|  60 |    192.980042 |    765.298058 | NA                                                                                                                                                                    |
|  61 |    776.959462 |    371.596285 | Chris huh                                                                                                                                                             |
|  62 |    986.782074 |    275.751733 | Martin R. Smith                                                                                                                                                       |
|  63 |    617.200143 |    626.729044 | Rebecca Groom                                                                                                                                                         |
|  64 |    206.784983 |    108.457095 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  65 |    565.967726 |    422.122050 | Ferran Sayol                                                                                                                                                          |
|  66 |     85.648247 |    599.163745 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                        |
|  67 |    496.275602 |    381.901260 | Noah Schlottman                                                                                                                                                       |
|  68 |    360.444047 |    409.900457 | Noah Schlottman, photo by Martin V. Sørensen                                                                                                                          |
|  69 |    961.768835 |    432.767269 | C. Camilo Julián-Caballero                                                                                                                                            |
|  70 |    870.212476 |     27.139802 | Tyler Greenfield and Scott Hartman                                                                                                                                    |
|  71 |    294.008681 |     39.315653 | John Conway                                                                                                                                                           |
|  72 |    738.710363 |     28.374327 | Scott Hartman                                                                                                                                                         |
|  73 |    953.760009 |    756.130744 | Joseph J. W. Sertich, Mark A. Loewen                                                                                                                                  |
|  74 |    926.165711 |    349.975673 | Scott Hartman                                                                                                                                                         |
|  75 |    112.606917 |    382.829842 | Matt Crook                                                                                                                                                            |
|  76 |    402.638223 |    613.043146 | Steven Traver                                                                                                                                                         |
|  77 |     85.009446 |    280.764326 | CNZdenek                                                                                                                                                              |
|  78 |     95.272584 |     49.998285 | Martin R. Smith                                                                                                                                                       |
|  79 |    763.410513 |    739.079443 | Peter Coxhead                                                                                                                                                         |
|  80 |    713.710174 |    733.824410 | T. Michael Keesey                                                                                                                                                     |
|  81 |    830.891617 |    102.831982 | Mathieu Basille                                                                                                                                                       |
|  82 |    395.881238 |    390.256719 | NA                                                                                                                                                                    |
|  83 |    210.200993 |    223.428162 | M. Antonio Todaro, Tobias Kånneby, Matteo Dal Zotto, and Ulf Jondelius (vectorized by T. Michael Keesey)                                                              |
|  84 |    121.107803 |    268.544166 | Christoph Schomburg                                                                                                                                                   |
|  85 |    166.372580 |    313.089800 | Gareth Monger                                                                                                                                                         |
|  86 |    747.021397 |    472.094946 | Matt Crook                                                                                                                                                            |
|  87 |    607.661565 |    747.109824 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  88 |    989.254304 |    394.790439 | Steven Traver                                                                                                                                                         |
|  89 |    345.821832 |    776.642460 | Arthur S. Brum                                                                                                                                                        |
|  90 |    694.646251 |    308.001671 | Kai R. Caspar                                                                                                                                                         |
|  91 |     29.050339 |    474.515718 | Steven Traver                                                                                                                                                         |
|  92 |    795.753396 |    144.323835 | Gareth Monger                                                                                                                                                         |
|  93 |    265.742870 |    338.936261 | Jagged Fang Designs                                                                                                                                                   |
|  94 |    123.931838 |    329.861333 | Steven Traver                                                                                                                                                         |
|  95 |    684.748688 |    282.108156 | Rebecca Groom                                                                                                                                                         |
|  96 |    617.522397 |    189.542248 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
|  97 |    945.937929 |    471.984309 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
|  98 |     87.590251 |    355.958366 | Scott Hartman                                                                                                                                                         |
|  99 |    356.492502 |    626.076954 | Ferran Sayol                                                                                                                                                          |
| 100 |    393.891499 |    548.976480 | Scott Hartman                                                                                                                                                         |
| 101 |    519.928431 |    100.589647 | Mathilde Cordellier                                                                                                                                                   |
| 102 |    166.737870 |    431.612032 | NA                                                                                                                                                                    |
| 103 |     29.823065 |    222.560345 | Dave Angelini                                                                                                                                                         |
| 104 |    700.977675 |    620.470900 | T. Michael Keesey                                                                                                                                                     |
| 105 |    437.762219 |    735.247150 | NA                                                                                                                                                                    |
| 106 |     44.679047 |    513.168032 | Margot Michaud                                                                                                                                                        |
| 107 |    232.297673 |    195.916858 | Roberto Díaz Sibaja                                                                                                                                                   |
| 108 |    750.470604 |     35.552840 | Scott Hartman                                                                                                                                                         |
| 109 |    769.373570 |    781.054009 | Rebecca Groom                                                                                                                                                         |
| 110 |    197.423357 |    605.757914 | Lukasiniho                                                                                                                                                            |
| 111 |    999.594748 |    647.635260 | Andrew A. Farke                                                                                                                                                       |
| 112 |    299.566238 |    574.057209 | Farelli (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
| 113 |    701.989636 |    247.170884 | NA                                                                                                                                                                    |
| 114 |    345.634192 |    699.293252 | Mike Keesey (vectorization) and Vaibhavcho (photography)                                                                                                              |
| 115 |     42.295216 |     18.133700 | Gareth Monger                                                                                                                                                         |
| 116 |    905.032226 |    196.512811 | Ferran Sayol                                                                                                                                                          |
| 117 |    892.777858 |    323.630356 | Chris huh                                                                                                                                                             |
| 118 |    202.406274 |    553.741218 | Jaime Headden                                                                                                                                                         |
| 119 |     46.625864 |     84.435382 | CNZdenek                                                                                                                                                              |
| 120 |    806.325672 |    541.899267 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 121 |    187.106699 |    453.371665 | Ferran Sayol                                                                                                                                                          |
| 122 |     81.982013 |    295.585499 | Scott Hartman                                                                                                                                                         |
| 123 |    281.419210 |    119.108746 | Steven Traver                                                                                                                                                         |
| 124 |    615.272769 |    391.749189 | Enoch Joseph Wetsy (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey    |
| 125 |    640.149490 |    496.734402 | Margot Michaud                                                                                                                                                        |
| 126 |    316.888133 |    122.066372 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 127 |     73.531340 |    560.898412 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 128 |    632.660531 |    175.812715 | Matthew E. Clapham                                                                                                                                                    |
| 129 |    296.696414 |    418.715549 | Christoph Schomburg                                                                                                                                                   |
| 130 |    384.257157 |    788.682833 | Zimices                                                                                                                                                               |
| 131 |    203.955200 |    462.278632 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 132 |    107.997322 |     84.794857 | LeonardoG (photography) and T. Michael Keesey (vectorization)                                                                                                         |
| 133 |    282.679979 |    359.065330 | Zimices                                                                                                                                                               |
| 134 |    216.708896 |    484.773422 | Mariana Ruiz Villarreal                                                                                                                                               |
| 135 |    913.921987 |    785.503837 | Gareth Monger                                                                                                                                                         |
| 136 |    644.758357 |    633.130980 | Michelle Site                                                                                                                                                         |
| 137 |     28.844534 |    663.355871 | Christoph Schomburg                                                                                                                                                   |
| 138 |    285.164473 |    331.284128 | New York Zoological Society                                                                                                                                           |
| 139 |     61.992948 |    355.641295 | T. Michael Keesey                                                                                                                                                     |
| 140 |    668.068547 |    639.651534 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
| 141 |    649.886615 |    159.597198 | Jaime Headden                                                                                                                                                         |
| 142 |    707.769122 |    363.075339 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 143 |    350.854508 |    308.460598 | Kai R. Caspar                                                                                                                                                         |
| 144 |    748.535161 |     45.845454 | Ray Simpson (vectorized by T. Michael Keesey)                                                                                                                         |
| 145 |    775.484263 |    576.557033 | John Conway                                                                                                                                                           |
| 146 |    959.249648 |    164.129606 | Noah Schlottman, photo from Casey Dunn                                                                                                                                |
| 147 |    256.619282 |     84.614160 | Christoph Schomburg                                                                                                                                                   |
| 148 |    503.976178 |     19.403532 | Birgit Lang; original image by virmisco.org                                                                                                                           |
| 149 |    613.633628 |    231.757247 | Charles R. Knight, vectorized by Zimices                                                                                                                              |
| 150 |    328.213616 |    688.986484 | Beth Reinke                                                                                                                                                           |
| 151 |    225.385533 |     84.340088 | Michele M Tobias from an image By Dcrjsr - Own work, CC BY 3.0, <https://commons.wikimedia.org/w/index.php?curid=18059686>                                            |
| 152 |     88.006920 |    681.249967 | (after Spotila 2004)                                                                                                                                                  |
| 153 |    505.605242 |    566.406058 | Scott Hartman                                                                                                                                                         |
| 154 |    648.062921 |    354.904139 | Matt Crook                                                                                                                                                            |
| 155 |     41.873157 |    372.852312 | Chris huh                                                                                                                                                             |
| 156 |    271.664823 |    769.581599 | T. Michael Keesey                                                                                                                                                     |
| 157 |    871.304192 |    557.072044 | Chris huh                                                                                                                                                             |
| 158 |    372.764488 |    713.055182 | Ingo Braasch                                                                                                                                                          |
| 159 |     18.063855 |    281.211116 | Gareth Monger                                                                                                                                                         |
| 160 |    735.012605 |    786.049371 | Mathew Wedel                                                                                                                                                          |
| 161 |    322.127857 |    654.058691 | Mark Miller                                                                                                                                                           |
| 162 |    547.139186 |    770.962924 | NA                                                                                                                                                                    |
| 163 |     42.931739 |    570.576405 | Jaime Headden                                                                                                                                                         |
| 164 |     49.935531 |    539.718787 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 165 |     93.926085 |    268.446459 | Tasman Dixon                                                                                                                                                          |
| 166 |    389.137242 |    150.976268 | Maha Ghazal                                                                                                                                                           |
| 167 |     26.099504 |    533.851454 | Matt Crook                                                                                                                                                            |
| 168 |     50.725756 |    197.776706 | Pete Buchholz                                                                                                                                                         |
| 169 |   1011.765804 |    548.660686 | xgirouxb                                                                                                                                                              |
| 170 |    120.279212 |    140.099787 | Geoff Shaw                                                                                                                                                            |
| 171 |    923.332848 |    622.099829 | Becky Barnes                                                                                                                                                          |
| 172 |    382.615452 |    795.901695 | Lisa Byrne                                                                                                                                                            |
| 173 |    862.361680 |    299.233756 | T. Michael Keesey (after James & al.)                                                                                                                                 |
| 174 |    947.268535 |     20.572651 | Scott Hartman                                                                                                                                                         |
| 175 |    839.328200 |    380.489751 | Rebecca Groom                                                                                                                                                         |
| 176 |    666.977812 |    254.555227 | Jagged Fang Designs                                                                                                                                                   |
| 177 |    661.103430 |    296.068762 | Matt Crook                                                                                                                                                            |
| 178 |    673.401928 |    514.527506 | Andrew A. Farke                                                                                                                                                       |
| 179 |    513.003900 |    361.745185 | Jagged Fang Designs                                                                                                                                                   |
| 180 |    311.092522 |    162.545224 | Sharon Wegner-Larsen                                                                                                                                                  |
| 181 |     11.845194 |    725.604917 | Maija Karala                                                                                                                                                          |
| 182 |    981.204958 |    583.504935 | Tasman Dixon                                                                                                                                                          |
| 183 |    596.307933 |    716.441056 | Matt Crook                                                                                                                                                            |
| 184 |    813.492757 |    125.244532 | Smokeybjb                                                                                                                                                             |
| 185 |    113.910862 |    125.500897 | Margot Michaud                                                                                                                                                        |
| 186 |    835.285124 |    525.662041 | Sarah Werning                                                                                                                                                         |
| 187 |    270.760213 |    326.075450 | Iain Reid                                                                                                                                                             |
| 188 |    720.676114 |    548.816251 | Prin Pattawaro (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey        |
| 189 |    399.409256 |    441.835306 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 190 |    335.449352 |    588.296951 | Steven Traver                                                                                                                                                         |
| 191 |     72.713258 |    233.441662 | Jagged Fang Designs                                                                                                                                                   |
| 192 |    418.294667 |    150.381044 | Zimices                                                                                                                                                               |
| 193 |    983.457067 |    781.884271 | JCGiron                                                                                                                                                               |
| 194 |    822.367463 |    142.177594 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 195 |    780.556006 |    524.792179 | Michael Scroggie                                                                                                                                                      |
| 196 |    686.376840 |    115.745325 | Matt Crook                                                                                                                                                            |
| 197 |   1005.895349 |    738.179718 | Matt Crook                                                                                                                                                            |
| 198 |    921.920084 |    462.941586 | RS                                                                                                                                                                    |
| 199 |    440.020339 |    163.323446 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                         |
| 200 |    879.766437 |    535.953611 | M Kolmann                                                                                                                                                             |
| 201 |    910.704799 |    134.419933 | Johan Lindgren, Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe                                                                                                  |
| 202 |    683.369613 |    588.534303 | Lukasiniho                                                                                                                                                            |
| 203 |    243.168644 |    564.746240 | Dmitry Bogdanov, vectorized by Zimices                                                                                                                                |
| 204 |     52.696771 |    275.759960 | Rafael Maia                                                                                                                                                           |
| 205 |    641.369015 |     92.591370 | Zimices                                                                                                                                                               |
| 206 |    591.450525 |     35.459014 | Rebecca Groom                                                                                                                                                         |
| 207 |     14.426760 |    590.360425 | Ferran Sayol                                                                                                                                                          |
| 208 |    471.679580 |    238.159539 | Matt Crook                                                                                                                                                            |
| 209 |    373.434628 |    379.235972 | Chris huh                                                                                                                                                             |
| 210 |    650.233353 |    510.007459 | NA                                                                                                                                                                    |
| 211 |    140.557383 |     81.808202 | SauropodomorphMonarch                                                                                                                                                 |
| 212 |    654.160296 |     25.671258 | Joseph J. W. Sertich, Mark A. Loewen                                                                                                                                  |
| 213 |    579.928907 |    752.988052 | Mali’o Kodis, image from the “Proceedings of the Zoological Society of London”                                                                                        |
| 214 |    174.442455 |    609.837291 | Markus A. Grohme                                                                                                                                                      |
| 215 |    644.375110 |    203.231623 | Scott Reid                                                                                                                                                            |
| 216 |    161.956102 |    669.692375 | Joseph J. W. Sertich, Mark A. Loewen                                                                                                                                  |
| 217 |    284.948511 |    448.851617 | Michael Scroggie                                                                                                                                                      |
| 218 |    210.035263 |    454.632361 | Gareth Monger                                                                                                                                                         |
| 219 |    859.136272 |    387.625913 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 220 |     64.223417 |    508.557294 | Jagged Fang Designs                                                                                                                                                   |
| 221 |    622.476870 |    110.273429 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                                        |
| 222 |    306.367969 |    442.492995 | Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org)                                                                          |
| 223 |    663.473650 |    790.224148 | Margot Michaud                                                                                                                                                        |
| 224 |    333.191677 |    525.008523 | Margot Michaud                                                                                                                                                        |
| 225 |    551.248038 |    588.961249 | Michael Day                                                                                                                                                           |
| 226 |    139.515562 |    142.992667 | Mathew Wedel                                                                                                                                                          |
| 227 |    886.654596 |    440.964422 | Collin Gross                                                                                                                                                          |
| 228 |    127.340428 |    158.947422 | Ferran Sayol                                                                                                                                                          |
| 229 |    226.860302 |    437.390540 | Collin Gross                                                                                                                                                          |
| 230 |    707.656008 |    437.726439 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                           |
| 231 |    782.288016 |    488.655889 | Notafly (vectorized by T. Michael Keesey)                                                                                                                             |
| 232 |    858.212518 |    177.230622 | Chris huh                                                                                                                                                             |
| 233 |    970.033575 |    148.278992 | Zimices                                                                                                                                                               |
| 234 |    250.350082 |    747.938768 | Collin Gross                                                                                                                                                          |
| 235 |    844.510111 |    744.036449 | T. Michael Keesey                                                                                                                                                     |
| 236 |    811.678459 |    598.071073 | Chris huh                                                                                                                                                             |
| 237 |    937.719783 |    604.128340 | Margot Michaud                                                                                                                                                        |
| 238 |    261.736863 |    205.787881 | Matt Crook                                                                                                                                                            |
| 239 |    460.407278 |    744.641342 | NA                                                                                                                                                                    |
| 240 |    897.917469 |    563.871897 | Matt Crook                                                                                                                                                            |
| 241 |    164.170553 |    145.904675 | Kimberly Haddrell                                                                                                                                                     |
| 242 |    429.885788 |    143.186220 | T. Michael Keesey                                                                                                                                                     |
| 243 |    443.191837 |     13.908667 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 244 |    882.486156 |     53.685394 | Berivan Temiz                                                                                                                                                         |
| 245 |    694.474671 |    546.411373 | Steven Traver                                                                                                                                                         |
| 246 |    537.218855 |    351.911781 | Jagged Fang Designs                                                                                                                                                   |
| 247 |    850.645556 |    265.425068 | Margot Michaud                                                                                                                                                        |
| 248 |    539.005632 |    441.170618 | NA                                                                                                                                                                    |
| 249 |    736.424360 |    253.980164 | Michelle Site                                                                                                                                                         |
| 250 |    968.318290 |    216.729187 | Jaime Headden                                                                                                                                                         |
| 251 |    373.947981 |    735.643707 | C. Camilo Julián-Caballero                                                                                                                                            |
| 252 |    272.824438 |     94.817080 | (after McCulloch 1908)                                                                                                                                                |
| 253 |    115.795353 |    794.530298 | Emily Willoughby                                                                                                                                                      |
| 254 |    707.892788 |    580.182657 | Ville-Veikko Sinkkonen                                                                                                                                                |
| 255 |    957.076061 |    380.789995 | Cesar Julian                                                                                                                                                          |
| 256 |    292.695589 |    760.589933 | Caroline Harding, MAF (vectorized by T. Michael Keesey)                                                                                                               |
| 257 |    813.684107 |    506.897542 | Steven Traver                                                                                                                                                         |
| 258 |    651.907237 |    399.279530 | Gareth Monger                                                                                                                                                         |
| 259 |    235.786462 |    457.712622 | Markus A. Grohme                                                                                                                                                      |
| 260 |    562.628436 |     22.780240 | Scott Hartman                                                                                                                                                         |
| 261 |    910.283960 |    110.674986 | Matt Crook                                                                                                                                                            |
| 262 |    702.129885 |    348.459949 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 263 |    663.267984 |    723.265171 | NA                                                                                                                                                                    |
| 264 |    930.890683 |    106.464254 | Chuanixn Yu                                                                                                                                                           |
| 265 |   1003.998678 |     17.991393 | Gareth Monger                                                                                                                                                         |
| 266 |    730.557797 |    281.815727 | Zimices                                                                                                                                                               |
| 267 |    207.762962 |    317.240721 | Birgit Lang                                                                                                                                                           |
| 268 |    537.637158 |    760.824466 | Zimices                                                                                                                                                               |
| 269 |    322.045677 |    542.146010 | Noah Schlottman, photo by Reinhard Jahn                                                                                                                               |
| 270 |    976.182188 |    192.714785 | Sean McCann                                                                                                                                                           |
| 271 |    309.192032 |    728.078793 | Zimices                                                                                                                                                               |
| 272 |    770.241929 |     28.119911 | Maija Karala                                                                                                                                                          |
| 273 |     31.823636 |    355.868132 | Michael Scroggie                                                                                                                                                      |
| 274 |    717.044683 |    600.526772 | Steven Traver                                                                                                                                                         |
| 275 |    589.280695 |      6.407535 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 276 |    143.104171 |    385.291094 | Matt Crook                                                                                                                                                            |
| 277 |    552.322740 |    546.894634 | T. Michael Keesey (after MPF)                                                                                                                                         |
| 278 |    871.717732 |    278.680651 | Sarah Werning                                                                                                                                                         |
| 279 |   1007.981662 |     63.531060 | Steven Traver                                                                                                                                                         |
| 280 |     72.853238 |     20.591254 | Matt Crook                                                                                                                                                            |
| 281 |    408.280915 |     51.680298 | Matt Crook                                                                                                                                                            |
| 282 |    655.265331 |    502.877199 | Manabu Bessho-Uehara                                                                                                                                                  |
| 283 |    550.563247 |    725.130960 | Andrew A. Farke                                                                                                                                                       |
| 284 |   1013.813583 |    565.962557 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 285 |    177.872665 |    392.124198 | Agnello Picorelli                                                                                                                                                     |
| 286 |     55.697295 |    166.440089 | Beth Reinke                                                                                                                                                           |
| 287 |   1012.769857 |    316.524288 | Katie S. Collins                                                                                                                                                      |
| 288 |    779.409473 |    747.405582 | Mali’o Kodis, photograph by Aqua-Photos (<http://www.flickr.com/people/undervannsfotografen/>)                                                                        |
| 289 |     42.090639 |    589.208750 | Ferran Sayol                                                                                                                                                          |
| 290 |    877.672906 |    249.759177 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 291 |    487.753142 |    232.195445 | david maas / dave hone                                                                                                                                                |
| 292 |    978.335341 |    203.971489 | Kai R. Caspar                                                                                                                                                         |
| 293 |    431.397342 |    222.161361 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 294 |    630.079614 |     53.758635 | Chris huh                                                                                                                                                             |
| 295 |    891.814183 |     65.070413 | Yan Wong from illustration by Jules Richard (1907)                                                                                                                    |
| 296 |    539.656124 |    435.674870 | Zimices                                                                                                                                                               |
| 297 |     62.035238 |    269.728019 | Matt Crook                                                                                                                                                            |
| 298 |    832.995456 |    575.794703 | J. J. Harrison (photo) & T. Michael Keesey                                                                                                                            |
| 299 |    891.337757 |    691.962322 | Zimices                                                                                                                                                               |
| 300 |    997.152022 |    147.504041 | Birgit Lang                                                                                                                                                           |
| 301 |    336.976945 |     36.043197 | Scott Hartman                                                                                                                                                         |
| 302 |    435.579652 |     24.967141 | Margot Michaud                                                                                                                                                        |
| 303 |    343.550495 |    389.134491 | Beth Reinke                                                                                                                                                           |
| 304 |    861.396843 |     85.627041 | James R. Spotila and Ray Chatterji                                                                                                                                    |
| 305 |    677.959561 |     10.762644 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 306 |    547.350101 |     37.037453 | Scott Hartman                                                                                                                                                         |
| 307 |    614.197688 |     62.348098 | David Orr                                                                                                                                                             |
| 308 |    719.372195 |    298.128383 | Zimices                                                                                                                                                               |
| 309 |   1010.998180 |    192.323552 | Chase Brownstein                                                                                                                                                      |
| 310 |    485.373042 |    361.017330 | Jack Mayer Wood                                                                                                                                                       |
| 311 |     37.325280 |    328.798275 | NA                                                                                                                                                                    |
| 312 |    779.078829 |    631.133212 | Michael Scroggie                                                                                                                                                      |
| 313 |    745.112395 |    723.841206 | NA                                                                                                                                                                    |
| 314 |     10.605062 |    410.185730 | Birgit Lang; original image by virmisco.org                                                                                                                           |
| 315 |    154.932313 |    558.673841 | Zimices                                                                                                                                                               |
| 316 |    844.991135 |    396.947440 | T. Michael Keesey (after Kukalová)                                                                                                                                    |
| 317 |   1001.946683 |    357.788458 | NA                                                                                                                                                                    |
| 318 |     70.628695 |    645.848822 | Kamil S. Jaron                                                                                                                                                        |
| 319 |    519.008947 |    658.039773 | M. A. Broussard                                                                                                                                                       |
| 320 |    519.364477 |    126.298142 | NA                                                                                                                                                                    |
| 321 |    726.114859 |    468.173044 | Martin R. Smith                                                                                                                                                       |
| 322 |   1015.211428 |    504.509555 | Matt Crook                                                                                                                                                            |
| 323 |    864.036078 |    133.746624 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 324 |    521.816517 |    576.404413 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 325 |    881.977886 |    222.098460 | Margot Michaud                                                                                                                                                        |
| 326 |    994.075900 |    154.738324 | Nobu Tamura and T. Michael Keesey                                                                                                                                     |
| 327 |    525.497227 |    427.763034 | Kai R. Caspar                                                                                                                                                         |
| 328 |    333.022876 |    721.289241 | Birgit Lang                                                                                                                                                           |
| 329 |    476.954337 |    478.031303 | Antonov (vectorized by T. Michael Keesey)                                                                                                                             |
| 330 |     17.143324 |     16.914447 | T. Michael Keesey                                                                                                                                                     |
| 331 |    884.083966 |     90.662504 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 332 |    529.715345 |    265.081652 | Kamil S. Jaron                                                                                                                                                        |
| 333 |    702.508699 |    256.445185 | Chuanixn Yu                                                                                                                                                           |
| 334 |    689.660861 |    689.645881 | NA                                                                                                                                                                    |
| 335 |    158.526927 |    262.320453 | Matt Crook                                                                                                                                                            |
| 336 |    358.108611 |    452.642005 | Jagged Fang Designs                                                                                                                                                   |
| 337 |     10.434702 |    212.157627 | NA                                                                                                                                                                    |
| 338 |    990.144178 |     61.044234 | Zimices                                                                                                                                                               |
| 339 |    406.533332 |    743.896231 | Steven Traver                                                                                                                                                         |
| 340 |    278.364257 |    788.321159 | Beth Reinke                                                                                                                                                           |
| 341 |    105.257606 |    345.795750 | Matt Crook                                                                                                                                                            |
| 342 |    177.828299 |    578.517626 | Gareth Monger                                                                                                                                                         |
| 343 |    535.034563 |    670.328363 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                       |
| 344 |    685.657412 |    366.903426 | Mathew Wedel                                                                                                                                                          |
| 345 |    128.060048 |    714.096723 | Tasman Dixon                                                                                                                                                          |
| 346 |    613.305573 |    795.974586 | Zimices                                                                                                                                                               |
| 347 |    787.980801 |    733.820807 | Christoph Schomburg                                                                                                                                                   |
| 348 |    552.051086 |    271.399348 | Ferran Sayol                                                                                                                                                          |
| 349 |    704.957806 |    661.215118 | Jon Hill                                                                                                                                                              |
| 350 |    781.696868 |    763.704868 | Y. de Hoev. (vectorized by T. Michael Keesey)                                                                                                                         |
| 351 |    712.077608 |    356.650268 | Shyamal                                                                                                                                                               |
| 352 |    542.182392 |    275.080402 | Tasman Dixon                                                                                                                                                          |
| 353 |     77.987724 |     57.455951 | Michael Scroggie                                                                                                                                                      |
| 354 |    354.284256 |     43.364273 | Chris huh                                                                                                                                                             |
| 355 |    291.902659 |    558.500765 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 356 |    645.478798 |    482.078766 | Matt Crook                                                                                                                                                            |
| 357 |    605.035220 |    438.133818 | Felix Vaux                                                                                                                                                            |
| 358 |     82.632501 |    764.274275 | Felix Vaux                                                                                                                                                            |
| 359 |    816.516168 |    200.452689 | Zimices                                                                                                                                                               |
| 360 |    294.416949 |    692.210689 | Kamil S. Jaron                                                                                                                                                        |
| 361 |    940.710234 |    374.863988 | Ferran Sayol                                                                                                                                                          |
| 362 |    403.331987 |    237.435668 | Ignacio Contreras                                                                                                                                                     |
| 363 |    917.087863 |    638.885637 | T. Michael Keesey                                                                                                                                                     |
| 364 |     19.530116 |    133.796822 | Zimices                                                                                                                                                               |
| 365 |    612.657846 |      8.419689 | Chris huh                                                                                                                                                             |
| 366 |    774.817368 |    158.055036 | Andrew A. Farke                                                                                                                                                       |
| 367 |    504.211128 |    259.062974 | Zimices                                                                                                                                                               |
| 368 |    319.787670 |    606.658494 | Gareth Monger                                                                                                                                                         |
| 369 |    404.575837 |    636.126456 | Kelly                                                                                                                                                                 |
| 370 |     48.446838 |    242.358568 | Ignacio Contreras                                                                                                                                                     |
| 371 |     36.956297 |    657.060637 | Fernando Campos De Domenico                                                                                                                                           |
| 372 |    737.436256 |    435.445205 | Matthias Buschmann (vectorized by T. Michael Keesey)                                                                                                                  |
| 373 |    990.798515 |    592.554831 | Andrew A. Farke                                                                                                                                                       |
| 374 |    678.115621 |     28.132271 | Neil Kelley                                                                                                                                                           |
| 375 |     37.953233 |     69.418524 | Margot Michaud                                                                                                                                                        |
| 376 |    561.395685 |    447.258696 | Peileppe                                                                                                                                                              |
| 377 |    457.485906 |    600.383906 | Matt Crook                                                                                                                                                            |
| 378 |    685.984170 |    358.010712 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
| 379 |    738.583973 |    769.534159 | Matt Crook                                                                                                                                                            |
| 380 |    629.956863 |    593.464176 | Smokeybjb, vectorized by Zimices                                                                                                                                      |
| 381 |    615.695851 |    477.504809 | NA                                                                                                                                                                    |
| 382 |    908.730019 |    687.767912 | NA                                                                                                                                                                    |
| 383 |    406.875084 |     27.421167 | Scott Hartman                                                                                                                                                         |
| 384 |    983.026134 |    700.932979 | Gareth Monger                                                                                                                                                         |
| 385 |    902.610612 |      8.654253 | Matt Crook                                                                                                                                                            |
| 386 |    753.316383 |    571.223530 | Zimices                                                                                                                                                               |
| 387 |    866.223051 |    518.728181 | Becky Barnes                                                                                                                                                          |
| 388 |     35.792656 |     46.872357 | Matt Crook                                                                                                                                                            |
| 389 |    502.586877 |    592.816866 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                  |
| 390 |    212.443708 |    656.571137 | Milton Tan                                                                                                                                                            |
| 391 |    223.269386 |    314.615525 | NA                                                                                                                                                                    |
| 392 |    870.234000 |    656.216925 | Gareth Monger                                                                                                                                                         |
| 393 |     67.850884 |    764.160471 | NA                                                                                                                                                                    |
| 394 |    713.529370 |    132.856052 | Matt Crook                                                                                                                                                            |
| 395 |    826.835194 |    589.003253 | Michelle Site                                                                                                                                                         |
| 396 |    581.960769 |     90.416087 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                                |
| 397 |    545.296822 |    316.645772 | Michelle Site                                                                                                                                                         |
| 398 |    964.478193 |    641.757228 | Tomas Willems (vectorized by T. Michael Keesey)                                                                                                                       |
| 399 |    797.938040 |    615.276891 | Christopher Watson (photo) and T. Michael Keesey (vectorization)                                                                                                      |
| 400 |    701.057608 |    111.704791 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 401 |    587.754698 |    463.412046 | Margot Michaud                                                                                                                                                        |
| 402 |    592.491650 |    268.718976 | Becky Barnes                                                                                                                                                          |
| 403 |    378.530935 |    138.994565 | Tracy A. Heath                                                                                                                                                        |
| 404 |    988.234852 |    618.170065 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 405 |    717.633842 |    148.204825 | Hans Hillewaert                                                                                                                                                       |
| 406 |    140.113220 |    550.888909 | NA                                                                                                                                                                    |
| 407 |    551.073559 |    630.017155 | Scott Hartman                                                                                                                                                         |
| 408 |    132.864986 |    774.447638 | V. Deepak                                                                                                                                                             |
| 409 |    173.774545 |    676.363258 | Zimices                                                                                                                                                               |
| 410 |    862.741524 |    753.962270 | Andrew A. Farke                                                                                                                                                       |
| 411 |     75.066152 |    520.678877 | Margot Michaud                                                                                                                                                        |
| 412 |    437.563617 |    236.561924 | Christoph Schomburg                                                                                                                                                   |
| 413 |    482.614452 |    584.438746 | Mali’o Kodis, photograph by Hans Hillewaert                                                                                                                           |
| 414 |    547.372964 |    120.822977 | Jack Mayer Wood                                                                                                                                                       |
| 415 |    646.690529 |     10.708148 | Margot Michaud                                                                                                                                                        |
| 416 |    445.431760 |    593.476028 | Crystal Maier                                                                                                                                                         |
| 417 |    535.894628 |    102.172968 | Harold N Eyster                                                                                                                                                       |
| 418 |    300.811467 |    496.550983 | Tauana J. Cunha                                                                                                                                                       |
| 419 |    616.160016 |    177.082827 | Robert Gay                                                                                                                                                            |
| 420 |    552.710843 |     55.518362 | Lauren Anderson                                                                                                                                                       |
| 421 |    271.081650 |    368.974492 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                           |
| 422 |     60.537257 |    666.006175 | Maxime Dahirel                                                                                                                                                        |
| 423 |    718.542114 |    376.021305 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 424 |     51.961099 |    221.264919 | J Levin W (illustration) and T. Michael Keesey (vectorization)                                                                                                        |
| 425 |    611.266669 |    411.388843 | Julien Louys                                                                                                                                                          |
| 426 |     21.335383 |    615.468773 | Margot Michaud                                                                                                                                                        |
| 427 |    414.243646 |    734.290084 | Zimices                                                                                                                                                               |
| 428 |   1006.479028 |    173.400476 | Kamil S. Jaron                                                                                                                                                        |
| 429 |    131.340869 |    354.441580 | Zimices                                                                                                                                                               |
| 430 |    302.112178 |    766.595432 | Margot Michaud                                                                                                                                                        |
| 431 |    256.408267 |    291.324471 | Michael Scroggie                                                                                                                                                      |
| 432 |    786.315699 |     86.638195 | Zimices                                                                                                                                                               |
| 433 |     84.259996 |    166.449254 | Ryan Cupo                                                                                                                                                             |
| 434 |    395.722577 |    187.747584 | FunkMonk                                                                                                                                                              |
| 435 |    721.384944 |     73.760514 | Margot Michaud                                                                                                                                                        |
| 436 |    141.994844 |    116.292600 | Steven Traver                                                                                                                                                         |
| 437 |    821.944777 |     50.980377 | Felix Vaux                                                                                                                                                            |
| 438 |    503.464297 |    116.994600 | Nobu Tamura                                                                                                                                                           |
| 439 |     75.823532 |    252.252343 | T. Michael Keesey                                                                                                                                                     |
| 440 |     74.424879 |    771.791835 | Gareth Monger                                                                                                                                                         |
| 441 |      4.669594 |    782.053041 | Gareth Monger                                                                                                                                                         |
| 442 |   1005.901010 |    214.921802 | Iain Reid                                                                                                                                                             |
| 443 |    954.741721 |     31.107709 | Jimmy Bernot                                                                                                                                                          |
| 444 |    258.947737 |    364.104169 | Margot Michaud                                                                                                                                                        |
| 445 |    927.163610 |    196.618224 | Zimices                                                                                                                                                               |
| 446 |    684.217348 |     89.835090 | Jagged Fang Designs                                                                                                                                                   |
| 447 |    436.000754 |    708.917887 | Bruno C. Vellutini                                                                                                                                                    |
| 448 |    455.126359 |    229.968036 | Jakovche                                                                                                                                                              |
| 449 |    583.690009 |     23.058256 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 450 |    783.899423 |     41.986463 | Matt Crook                                                                                                                                                            |
| 451 |    466.282942 |    672.810052 | Christoph Schomburg                                                                                                                                                   |
| 452 |     11.909305 |    563.376173 | Kai R. Caspar                                                                                                                                                         |
| 453 |    773.453620 |     13.309434 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 454 |     13.077476 |    257.637945 | Margot Michaud                                                                                                                                                        |
| 455 |     93.478955 |    152.666932 | Matt Crook                                                                                                                                                            |
| 456 |    490.398544 |      3.919027 | Matt Dempsey                                                                                                                                                          |
| 457 |    238.407078 |     70.655575 | Jaime Chirinos (vectorized by T. Michael Keesey)                                                                                                                      |
| 458 |    641.894379 |    256.427843 | Stuart Humphries                                                                                                                                                      |
| 459 |    106.227755 |    659.347753 | T. Michael Keesey                                                                                                                                                     |
| 460 |    828.712522 |    343.718157 | Neil Kelley                                                                                                                                                           |
| 461 |    748.488098 |    413.684853 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 462 |    991.476893 |    190.871251 | Felix Vaux                                                                                                                                                            |
| 463 |    395.103013 |    228.290867 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 464 |   1014.230183 |    712.883862 | Gareth Monger                                                                                                                                                         |
| 465 |    585.855245 |     54.723250 | Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus                                              |
| 466 |    450.822025 |    720.386515 | Harold N Eyster                                                                                                                                                       |
| 467 |    390.518085 |    726.133747 | Chase Brownstein                                                                                                                                                      |
| 468 |    467.208706 |    104.608766 | Marcos Pérez-Losada, Jens T. Høeg & Keith A. Crandall                                                                                                                 |
| 469 |   1007.266054 |    130.990207 | Douglas Brown (modified by T. Michael Keesey)                                                                                                                         |
| 470 |    738.131490 |    394.744178 | Chris huh                                                                                                                                                             |
| 471 |    652.144368 |    715.588414 | Christoph Schomburg                                                                                                                                                   |
| 472 |    781.071529 |    474.326078 | Gareth Monger                                                                                                                                                         |
| 473 |    357.460821 |    790.121138 | Lee Harding (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
| 474 |    624.954422 |    137.251751 | Joanna Wolfe                                                                                                                                                          |
| 475 |    165.523253 |     59.676603 | Noah Schlottman, photo by Antonio Guillén                                                                                                                             |
| 476 |    946.826717 |     81.499996 | Tasman Dixon                                                                                                                                                          |
| 477 |   1006.473760 |     39.871483 | Tasman Dixon                                                                                                                                                          |
| 478 |    119.560005 |    412.824471 | Sherman Foote Denton (illustration, 1897) and Timothy J. Bartley (silhouette)                                                                                         |
| 479 |    597.722046 |    643.995961 | Andrew A. Farke                                                                                                                                                       |
| 480 |    796.207296 |    310.068939 | Matt Crook                                                                                                                                                            |
| 481 |    811.591835 |    168.395097 | Roberto Díaz Sibaja                                                                                                                                                   |
| 482 |    416.765277 |    368.619869 | Hans Hillewaert                                                                                                                                                       |
| 483 |     23.540013 |    428.209958 | Ferran Sayol                                                                                                                                                          |
| 484 |    432.660082 |    465.650290 | Steven Traver                                                                                                                                                         |
| 485 |     81.947114 |    263.407313 | T. Michael Keesey                                                                                                                                                     |
| 486 |     65.872288 |     75.393968 | Matt Crook                                                                                                                                                            |
| 487 |    955.563019 |    605.104324 | T. Michael Keesey (photo by Darren Swim)                                                                                                                              |
| 488 |    491.816724 |    329.945897 | Beth Reinke                                                                                                                                                           |
| 489 |    597.793746 |    244.963064 | Zimices                                                                                                                                                               |
| 490 |    356.266073 |    604.921606 | Steven Traver                                                                                                                                                         |
| 491 |     68.609767 |    305.075984 | Manabu Bessho-Uehara                                                                                                                                                  |
| 492 |    886.451835 |    295.163934 | Scott Hartman                                                                                                                                                         |
| 493 |    689.849255 |    710.323702 | Birgit Lang                                                                                                                                                           |
| 494 |     11.416600 |    293.962380 | Manabu Sakamoto                                                                                                                                                       |
| 495 |    611.171666 |    714.579170 | T. Michael Keesey                                                                                                                                                     |
| 496 |    737.822798 |     77.323709 | NA                                                                                                                                                                    |
| 497 |    209.941500 |    538.187638 | Dr. Thomas G. Barnes, USFWS                                                                                                                                           |
| 498 |    114.943926 |    165.022492 | Yan Wong from drawing by Joseph Smit                                                                                                                                  |
| 499 |    697.249635 |    151.569811 | Sarah Werning                                                                                                                                                         |
| 500 |    660.818253 |    275.311286 | Alex Slavenko                                                                                                                                                         |
| 501 |      8.767353 |    604.193236 | Sharon Wegner-Larsen                                                                                                                                                  |
| 502 |    389.239978 |    246.686910 | Gareth Monger                                                                                                                                                         |
| 503 |    835.238646 |    168.298484 | Zimices                                                                                                                                                               |
| 504 |    385.041220 |    622.258540 | Tommaso Cancellario                                                                                                                                                   |
| 505 |    860.859684 |    363.838642 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 506 |    692.262440 |    727.876497 | Chloé Schmidt                                                                                                                                                         |
| 507 |      8.430566 |    638.548193 | Verdilak                                                                                                                                                              |
| 508 |    835.129348 |    281.962372 | T. Michael Keesey                                                                                                                                                     |
| 509 |    969.533817 |     21.475545 | Scott Hartman                                                                                                                                                         |
| 510 |    108.914050 |      4.104798 | NA                                                                                                                                                                    |
| 511 |     81.979604 |    203.744709 | Gareth Monger                                                                                                                                                         |
| 512 |    569.737802 |     82.435205 | Keith Murdock (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey         |
| 513 |    572.056705 |     46.852878 | Ferran Sayol                                                                                                                                                          |
| 514 |    638.855352 |    107.155164 | Birgit Lang                                                                                                                                                           |
| 515 |    876.571407 |    265.316266 | Mo Hassan                                                                                                                                                             |
| 516 |    548.174058 |    512.812933 | Emily Willoughby                                                                                                                                                      |
| 517 |   1014.330109 |    359.751458 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 518 |    112.393738 |    698.562687 | Cathy                                                                                                                                                                 |
| 519 |    283.409000 |    776.316537 | Christoph Schomburg                                                                                                                                                   |
| 520 |     20.256778 |    510.167438 | Maija Karala                                                                                                                                                          |
| 521 |    244.403811 |    219.493938 | Steven Traver                                                                                                                                                         |
| 522 |    631.196842 |     10.336752 | Cathy                                                                                                                                                                 |
| 523 |    188.154772 |    667.694019 | Gareth Monger                                                                                                                                                         |
| 524 |    667.973723 |    467.610332 | Margot Michaud                                                                                                                                                        |
| 525 |    765.986329 |    526.663532 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 526 |    404.427544 |    466.282116 | Kevin Sánchez                                                                                                                                                         |
| 527 |    181.461067 |    592.596023 | Jagged Fang Designs                                                                                                                                                   |
| 528 |    649.096545 |    288.862393 | Kent Elson Sorgon                                                                                                                                                     |
| 529 |    322.971885 |    278.215211 | Scott Reid                                                                                                                                                            |
| 530 |    668.927167 |    578.977745 | Michelle Site                                                                                                                                                         |
| 531 |     20.866476 |    764.500326 | NA                                                                                                                                                                    |
| 532 |    990.249111 |    367.320695 | Steven Coombs                                                                                                                                                         |
| 533 |    901.750141 |    766.686476 | T. Michael Keesey                                                                                                                                                     |
| 534 |    437.168756 |    662.375146 | Jagged Fang Designs                                                                                                                                                   |
| 535 |    595.939957 |    791.099004 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 536 |    434.276019 |    556.492245 | Steven Traver                                                                                                                                                         |
| 537 |    608.230881 |     32.654345 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                              |
| 538 |    268.957435 |    727.959230 | Chris huh                                                                                                                                                             |
| 539 |    888.484814 |    507.279055 | Steven Traver                                                                                                                                                         |
| 540 |    760.522752 |    209.014884 | NASA                                                                                                                                                                  |
| 541 |    144.522462 |    669.002182 | FunkMonk                                                                                                                                                              |
| 542 |    523.350160 |    758.513693 | Kamil S. Jaron                                                                                                                                                        |
| 543 |    898.218232 |    429.538971 | Scott Hartman (vectorized by T. Michael Keesey)                                                                                                                       |
| 544 |    769.061620 |    394.996266 | Beth Reinke                                                                                                                                                           |
| 545 |    237.327484 |    676.544583 | Juan Carlos Jerí                                                                                                                                                      |
| 546 |    979.996735 |     75.699287 | Ignacio Contreras                                                                                                                                                     |
| 547 |    641.044928 |    463.510511 | T. Michael Keesey                                                                                                                                                     |
| 548 |    714.038408 |    588.614135 | Todd Marshall, vectorized by Zimices                                                                                                                                  |
| 549 |    389.133571 |    462.159765 | Margot Michaud                                                                                                                                                        |
| 550 |    926.916302 |    415.482555 | Markus A. Grohme                                                                                                                                                      |
| 551 |    379.058643 |    637.924475 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 552 |    807.201806 |    608.391682 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                           |
| 553 |    959.214637 |    789.430319 | Margot Michaud                                                                                                                                                        |
| 554 |    936.267695 |    168.058968 | Esme Ashe-Jepson                                                                                                                                                      |
| 555 |    744.011615 |      9.147508 | Markus A. Grohme                                                                                                                                                      |
| 556 |    642.241701 |    743.741764 | Emily Willoughby                                                                                                                                                      |
| 557 |    768.560880 |    549.731757 | Farelli (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
| 558 |    145.304974 |    596.729083 | Michael Day                                                                                                                                                           |
| 559 |    704.309278 |    693.141800 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 560 |    259.416977 |    179.923832 | L. Shyamal                                                                                                                                                            |
| 561 |    948.714194 |    405.853076 | Margot Michaud                                                                                                                                                        |
| 562 |    704.929969 |    282.584280 | Sean McCann                                                                                                                                                           |
| 563 |    476.622965 |    752.688414 | Steven Traver                                                                                                                                                         |
| 564 |    952.205194 |    588.605181 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 565 |    919.280760 |    326.780140 | Margot Michaud                                                                                                                                                        |
| 566 |    947.955397 |    552.023549 | Michele M Tobias                                                                                                                                                      |
| 567 |    917.944752 |     31.072096 | Mathew Wedel                                                                                                                                                          |
| 568 |     73.220450 |    793.320896 | Steven Traver                                                                                                                                                         |
| 569 |    893.889588 |    228.403816 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 570 |    679.974145 |    152.329573 | Sherman F. Denton via rawpixel.com (illustration) and Timothy J. Bartley (silhouette)                                                                                 |
| 571 |     80.748484 |     99.304915 | Margot Michaud                                                                                                                                                        |
| 572 |    441.142098 |    519.148280 | Kamil S. Jaron                                                                                                                                                        |
| 573 |    537.600574 |     10.210360 | H. F. O. March (vectorized by T. Michael Keesey)                                                                                                                      |
| 574 |    201.421994 |    499.502961 | Birgit Lang                                                                                                                                                           |
| 575 |    401.326566 |    170.060967 | Scott Hartman (vectorized by T. Michael Keesey)                                                                                                                       |
| 576 |    897.242626 |    455.645236 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 577 |    235.398807 |    327.246871 | Steven Traver                                                                                                                                                         |
| 578 |    530.243113 |    582.518721 | Tasman Dixon                                                                                                                                                          |
| 579 |    161.769309 |    581.144565 | Joseph Wolf, 1863 (vectorization by Dinah Challen)                                                                                                                    |
| 580 |    616.631332 |    268.166418 | Zimices                                                                                                                                                               |
| 581 |    633.839022 |    643.953558 | Collin Gross                                                                                                                                                          |
| 582 |     22.302761 |    402.011601 | Steven Traver                                                                                                                                                         |
| 583 |    287.808260 |    426.847461 | Paul Baker (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey            |
| 584 |    357.114901 |    728.062099 | Verdilak                                                                                                                                                              |
| 585 |    478.237396 |    603.805925 | Tasman Dixon                                                                                                                                                          |
| 586 |    654.129590 |    733.657477 | C. Camilo Julián-Caballero                                                                                                                                            |
| 587 |    416.936637 |    383.870667 | DW Bapst, modified from Figure 1 of Belanger (2011, PALAIOS).                                                                                                         |
| 588 |     15.869741 |    158.928159 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 589 |    959.449665 |    618.366331 | Markus A. Grohme                                                                                                                                                      |
| 590 |    290.898251 |    144.352159 | Matt Crook                                                                                                                                                            |
| 591 |    346.777182 |    545.573595 | Kai R. Caspar                                                                                                                                                         |
| 592 |    277.210048 |    412.378619 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 593 |    151.722007 |    543.216165 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 594 |    306.205349 |    343.338852 | Maija Karala                                                                                                                                                          |
| 595 |    791.944291 |    597.693011 | Kamil S. Jaron                                                                                                                                                        |
| 596 |    424.245610 |    508.546615 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 597 |    752.866728 |    457.449670 | Scott Hartman                                                                                                                                                         |
| 598 |    712.030977 |    477.226374 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 599 |    912.631451 |    301.384874 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 600 |    676.541370 |    137.994655 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 601 |    835.399150 |     49.565096 | Matt Crook                                                                                                                                                            |
| 602 |    958.402684 |     82.717378 | Chris huh                                                                                                                                                             |
| 603 |    230.429233 |     17.869765 | Gareth Monger                                                                                                                                                         |
| 604 |    421.677990 |    713.487852 | Steven Coombs                                                                                                                                                         |
| 605 |    573.552934 |    264.243333 | Ferran Sayol                                                                                                                                                          |
| 606 |    882.074197 |    651.805263 | Birgit Lang                                                                                                                                                           |
| 607 |    385.058390 |    201.577830 | Arthur S. Brum                                                                                                                                                        |
| 608 |    850.893488 |    571.994134 | Ian Burt (original) and T. Michael Keesey (vectorization)                                                                                                             |
| 609 |    424.398557 |    706.808795 | Margot Michaud                                                                                                                                                        |
| 610 |    651.365757 |     54.628258 | Emily Willoughby                                                                                                                                                      |
| 611 |    822.167253 |    386.775892 | Matt Crook                                                                                                                                                            |
| 612 |    279.794165 |    752.993585 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 613 |    851.368399 |    369.598200 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 614 |    549.456323 |    655.768461 | Gareth Monger                                                                                                                                                         |
| 615 |    492.875040 |    669.247838 | Margot Michaud                                                                                                                                                        |
| 616 |   1009.701732 |    657.294896 | Kailah Thorn & Ben King                                                                                                                                               |
| 617 |    897.416786 |    317.601792 | Zimices                                                                                                                                                               |
| 618 |    534.865917 |    546.585437 | Tauana J. Cunha                                                                                                                                                       |
| 619 |    433.433466 |    594.993866 | Margot Michaud                                                                                                                                                        |
| 620 |    986.069776 |     85.179449 | Emily Willoughby                                                                                                                                                      |
| 621 |    607.204286 |    219.538458 | Gareth Monger                                                                                                                                                         |
| 622 |    262.653400 |    426.260309 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 623 |     10.041712 |    660.217999 | Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org)                                                                          |
| 624 |    978.051130 |    457.897350 | Chris huh                                                                                                                                                             |
| 625 |    127.946371 |    673.905039 | Matt Crook                                                                                                                                                            |
| 626 |    862.330580 |    257.571371 | NA                                                                                                                                                                    |
| 627 |     64.989549 |     37.791536 | Gareth Monger                                                                                                                                                         |
| 628 |   1011.328429 |    249.811899 | Kamil S. Jaron                                                                                                                                                        |
| 629 |    946.442253 |    627.528880 | Maija Karala                                                                                                                                                          |
| 630 |    512.111939 |    251.235749 | NA                                                                                                                                                                    |
| 631 |    318.023513 |    697.799103 | Zimices                                                                                                                                                               |
| 632 |    698.255100 |    459.144028 | FunkMonk                                                                                                                                                              |
| 633 |    556.980038 |     87.026058 | Matt Crook                                                                                                                                                            |
| 634 |     55.635372 |    780.057469 | Christopher Laumer (vectorized by T. Michael Keesey)                                                                                                                  |
| 635 |    729.375892 |      7.969758 | Chris huh                                                                                                                                                             |
| 636 |    909.401777 |    294.034339 | Jagged Fang Designs                                                                                                                                                   |
| 637 |   1011.245559 |    287.675874 | Becky Barnes                                                                                                                                                          |
| 638 |     48.919965 |    361.524584 | Caleb M. Brown                                                                                                                                                        |
| 639 |    615.979729 |    610.575917 | Scott Hartman                                                                                                                                                         |
| 640 |    121.121038 |    357.665314 | Chris Jennings (Risiatto)                                                                                                                                             |
| 641 |    395.597929 |    716.147591 | Juan Carlos Jerí                                                                                                                                                      |
| 642 |    899.249797 |    734.624768 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 643 |    876.891374 |    313.512493 | Zimices                                                                                                                                                               |
| 644 |    193.921316 |    257.339340 | Maija Karala                                                                                                                                                          |
| 645 |     97.021566 |     91.886005 | Tasman Dixon                                                                                                                                                          |
| 646 |    565.566179 |     10.879501 | Chris A. Hamilton                                                                                                                                                     |
| 647 |     85.771079 |    369.016852 | NA                                                                                                                                                                    |
| 648 |    430.665979 |    213.796511 | Scott Hartman                                                                                                                                                         |
| 649 |    932.597471 |    115.202297 | Emily Willoughby                                                                                                                                                      |
| 650 |    957.649776 |    568.233373 | Zimices                                                                                                                                                               |
| 651 |    423.900666 |    419.321613 | Gareth Monger                                                                                                                                                         |
| 652 |    410.335942 |    312.081444 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 653 |    870.240776 |    190.193577 | Zimices                                                                                                                                                               |
| 654 |    451.094362 |    132.224419 | Birgit Lang                                                                                                                                                           |
| 655 |    741.138681 |    197.637435 | Sidney Frederic Harmer, Arthur Everett Shipley (vectorized by Maxime Dahirel)                                                                                         |
| 656 |    259.969356 |    563.187875 | Chris huh                                                                                                                                                             |
| 657 |    866.874762 |    548.815893 | Julio Garza                                                                                                                                                           |
| 658 |    807.820861 |    757.965507 | \<U+0412\>\<U+0430\>\<U+043B\>\<U+044C\>\<U+0434\>\<U+0438\>\<U+043C\>\<U+0430\>\<U+0440\> (vectorized by T. Michael Keesey)                                          |
| 659 |    424.841002 |    539.251435 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 660 |    798.338155 |    739.028426 | NA                                                                                                                                                                    |
| 661 |    559.717768 |    791.781626 | Michael Scroggie                                                                                                                                                      |
| 662 |    308.002029 |    515.610120 | Mathieu Basille                                                                                                                                                       |
| 663 |      7.788747 |    330.356188 | NA                                                                                                                                                                    |
| 664 |    993.207646 |    604.940176 | Joanna Wolfe                                                                                                                                                          |
| 665 |    636.038735 |    729.205087 | Robert Gay, modifed from Olegivvit                                                                                                                                    |
| 666 |    277.847528 |     52.597325 | Sarah Werning                                                                                                                                                         |
| 667 |    955.627754 |    456.633560 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 668 |    219.596591 |    180.502603 | Scott Hartman                                                                                                                                                         |
| 669 |    318.794494 |    484.271331 | Matus Valach                                                                                                                                                          |
| 670 |    673.189739 |     41.025432 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 671 |    892.269566 |    547.416398 | Chris huh                                                                                                                                                             |
| 672 |    484.101038 |    489.737793 | Gareth Monger                                                                                                                                                         |
| 673 |    823.999528 |     37.062638 | Leann Biancani, photo by Kenneth Clifton                                                                                                                              |
| 674 |    984.774724 |    769.589225 | Christoph Schomburg                                                                                                                                                   |
| 675 |    380.643956 |     42.566910 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 676 |    791.300645 |    390.202705 | Steven Traver                                                                                                                                                         |
| 677 |    883.950127 |    520.634138 | Tasman Dixon                                                                                                                                                          |
| 678 |    361.202894 |    403.083211 | Zimices                                                                                                                                                               |
| 679 |     66.510429 |      5.845907 | T. Michael Keesey                                                                                                                                                     |
| 680 |    806.943990 |    105.955393 | Jagged Fang Designs                                                                                                                                                   |
| 681 |    407.149705 |      7.905151 | H. F. O. March (modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel)                                                                                  |
| 682 |     58.723426 |    100.177116 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                              |
| 683 |    964.223211 |    180.297779 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 684 |    685.044790 |    464.288761 | Jaime Headden                                                                                                                                                         |
| 685 |    259.946627 |    788.101361 | Kailah Thorn & Mark Hutchinson                                                                                                                                        |
| 686 |    680.847234 |    258.126250 | Ignacio Contreras                                                                                                                                                     |
| 687 |    619.395951 |    731.396367 | Zimices                                                                                                                                                               |
| 688 |    845.205403 |    351.640180 | Chris huh                                                                                                                                                             |
| 689 |    691.750141 |    630.880921 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 690 |    988.349305 |    739.784056 | Lafage                                                                                                                                                                |
| 691 |    857.436315 |    376.164769 | Zimices                                                                                                                                                               |
| 692 |    673.033428 |    333.530144 | Chris huh                                                                                                                                                             |
| 693 |    211.577984 |    613.414962 | Scott Reid                                                                                                                                                            |
| 694 |     73.946902 |    537.887080 | Emily Willoughby                                                                                                                                                      |
| 695 |     49.696435 |    295.948838 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 696 |    351.374675 |    256.998422 | Matt Crook                                                                                                                                                            |
| 697 |     30.066842 |    439.313345 | Tracy A. Heath                                                                                                                                                        |
| 698 |    250.794740 |    413.002447 | Maija Karala                                                                                                                                                          |
| 699 |     36.156280 |      7.671084 | Katie S. Collins                                                                                                                                                      |
| 700 |    510.563693 |    764.670718 | NA                                                                                                                                                                    |
| 701 |    371.998199 |    409.704801 | NA                                                                                                                                                                    |
| 702 |    526.344739 |    221.960799 | Ekaterina Kopeykina (vectorized by T. Michael Keesey)                                                                                                                 |
| 703 |    320.871102 |    291.096808 | Marmelad                                                                                                                                                              |
| 704 |    416.403669 |    203.851094 | Melissa Broussard                                                                                                                                                     |
| 705 |    444.134993 |    376.729834 | NA                                                                                                                                                                    |
| 706 |   1008.121667 |    776.819685 | Anthony Caravaggi                                                                                                                                                     |
| 707 |    882.252212 |    207.472406 | Andrew A. Farke                                                                                                                                                       |
| 708 |    992.153398 |    134.508617 | Collin Gross                                                                                                                                                          |
| 709 |    827.840277 |    359.879090 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 710 |     11.652130 |    489.528088 | Maija Karala                                                                                                                                                          |
| 711 |    786.584839 |    128.699988 | T. Michael Keesey                                                                                                                                                     |
| 712 |    845.638928 |    135.493150 | Gareth Monger                                                                                                                                                         |
| 713 |    758.368992 |    432.380343 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 714 |    956.422125 |    344.591324 | Jagged Fang Designs                                                                                                                                                   |
| 715 |    145.461209 |    150.360112 | Gareth Monger                                                                                                                                                         |
| 716 |    990.109393 |    474.587285 | Margot Michaud                                                                                                                                                        |
| 717 |     22.446833 |    652.177329 | Christoph Schomburg                                                                                                                                                   |
| 718 |    920.326554 |    769.554056 | Charles R. Knight (vectorized by T. Michael Keesey)                                                                                                                   |
| 719 |    974.866106 |    369.578563 | NA                                                                                                                                                                    |
| 720 |    424.094457 |    355.999089 | Scott Hartman                                                                                                                                                         |
| 721 |    565.701446 |    713.703629 | Chris huh                                                                                                                                                             |
| 722 |    683.374964 |     95.638469 | Chris huh                                                                                                                                                             |
| 723 |    300.503339 |    536.185590 | NASA                                                                                                                                                                  |
| 724 |    894.847747 |    285.209437 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                         |
| 725 |     76.081823 |    584.209331 | Markus A. Grohme                                                                                                                                                      |
| 726 |    418.141490 |    227.595179 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 727 |    783.326999 |    711.458564 | Matt Crook                                                                                                                                                            |
| 728 |    994.919231 |    205.336531 | Oscar Sanisidro                                                                                                                                                       |
| 729 |    258.062878 |    432.531976 | Kamil S. Jaron                                                                                                                                                        |
| 730 |    764.730989 |    795.560832 | Scott Hartman                                                                                                                                                         |
| 731 |    640.104726 |    396.992434 | Alex Slavenko                                                                                                                                                         |
| 732 |    802.546388 |    511.968349 | Steven Coombs                                                                                                                                                         |
| 733 |    391.069268 |    634.896881 | Collin Gross                                                                                                                                                          |
| 734 |    394.714311 |    453.365812 | Chris huh                                                                                                                                                             |
| 735 |    333.825672 |    116.375671 | Rebecca Groom                                                                                                                                                         |
| 736 |    610.052048 |    279.806960 | T. K. Robinson                                                                                                                                                        |
| 737 |    785.631621 |    405.052400 | Gareth Monger                                                                                                                                                         |
| 738 |     66.973111 |    532.126382 | Chris huh                                                                                                                                                             |
| 739 |    310.430978 |    618.488452 | Chris huh                                                                                                                                                             |
| 740 |    752.220218 |     70.056886 | Margot Michaud                                                                                                                                                        |
| 741 |    512.149541 |    432.690051 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 742 |    921.411919 |    127.647140 | Dean Schnabel                                                                                                                                                         |
| 743 |    386.994009 |    533.258977 | Matt Crook                                                                                                                                                            |
| 744 |    782.833965 |    605.682386 | Steven Traver                                                                                                                                                         |
| 745 |    149.105409 |    324.346705 | NA                                                                                                                                                                    |
| 746 |    983.352480 |     27.515450 | NA                                                                                                                                                                    |
| 747 |    868.223949 |    364.561357 | Kai R. Caspar                                                                                                                                                         |
| 748 |    908.622546 |    548.105397 | Zimices                                                                                                                                                               |
| 749 |    679.723027 |    633.304878 | Mali’o Kodis, image from Brockhaus and Efron Encyclopedic Dictionary                                                                                                  |
| 750 |    686.494448 |    534.580983 | Gareth Monger                                                                                                                                                         |
| 751 |    830.166113 |     86.809768 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
| 752 |    444.108789 |     87.857994 | Oliver Voigt                                                                                                                                                          |
| 753 |    957.451616 |    207.012542 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 754 |   1013.611441 |    380.392561 | CNZdenek                                                                                                                                                              |
| 755 |    385.532491 |    411.789141 | Zimices                                                                                                                                                               |
| 756 |    507.646101 |    793.866623 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                       |
| 757 |    539.376802 |    455.696414 | Chris huh                                                                                                                                                             |
| 758 |    245.257105 |    318.426231 | Maija Karala                                                                                                                                                          |
| 759 |    508.944514 |    549.159493 | L. Shyamal                                                                                                                                                            |
| 760 |    619.610255 |    126.358517 | Sharon Wegner-Larsen                                                                                                                                                  |
| 761 |     96.223193 |    382.733926 | Emily Willoughby                                                                                                                                                      |
| 762 |    221.926446 |    508.770556 | Mali’o Kodis, traced image from the National Science Foundation’s Turbellarian Taxonomic Database                                                                     |
| 763 |     73.814573 |    217.551149 | FJDegrange                                                                                                                                                            |
| 764 |    554.918553 |    433.815269 | Sharon Wegner-Larsen                                                                                                                                                  |
| 765 |    833.497272 |     79.234267 | Margot Michaud                                                                                                                                                        |
| 766 |     90.045665 |    532.844603 | Carlos Cano-Barbacil                                                                                                                                                  |
| 767 |    449.702803 |    361.423895 | M. Garfield & K. Anderson (modified by T. Michael Keesey)                                                                                                             |
| 768 |   1020.594418 |    262.889886 | Gareth Monger                                                                                                                                                         |
| 769 |    699.214848 |    138.125650 | Matt Crook                                                                                                                                                            |
| 770 |    709.180318 |    393.084237 | Christoph Schomburg                                                                                                                                                   |
| 771 |    185.661744 |    147.481692 | NA                                                                                                                                                                    |
| 772 |    145.997153 |    659.652770 | Margot Michaud                                                                                                                                                        |
| 773 |    462.954353 |    787.657273 | Alex Slavenko                                                                                                                                                         |
| 774 |   1012.159299 |    488.419986 | Christoph Schomburg                                                                                                                                                   |
| 775 |    947.069897 |    125.620022 | Zimices                                                                                                                                                               |
| 776 |    369.658491 |    393.381431 | Antonov (vectorized by T. Michael Keesey)                                                                                                                             |
| 777 |    485.629612 |     32.113623 | Zimices                                                                                                                                                               |
| 778 |    782.622238 |    304.078092 | Christoph Schomburg                                                                                                                                                   |
| 779 |    618.395257 |    786.515073 | Tasman Dixon                                                                                                                                                          |
| 780 |    935.180338 |    181.021661 | Chris huh                                                                                                                                                             |
| 781 |    144.754953 |    612.036295 | Javier Luque & Sarah Gerken                                                                                                                                           |
| 782 |    393.330292 |    506.870517 | Kent Elson Sorgon                                                                                                                                                     |
| 783 |    849.408585 |    274.014578 | Birgit Lang                                                                                                                                                           |
| 784 |     53.038222 |    493.355071 | Matt Crook                                                                                                                                                            |
| 785 |    963.745790 |     58.428827 | Steven Traver                                                                                                                                                         |
| 786 |    316.979568 |    457.145191 | Alan Manson (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
| 787 |    690.925867 |     50.801016 | Abraão Leite                                                                                                                                                          |
| 788 |    265.234403 |    678.652237 | Zimices                                                                                                                                                               |
| 789 |    899.142759 |    185.199178 | Margot Michaud                                                                                                                                                        |
| 790 |    654.024168 |    138.544017 | Margot Michaud                                                                                                                                                        |
| 791 |    145.741550 |    416.796216 | Dean Schnabel                                                                                                                                                         |
| 792 |    138.787091 |    429.268055 | Matt Crook                                                                                                                                                            |
| 793 |    179.496117 |    400.242717 | C. W. Nash (illustration) and Timothy J. Bartley (silhouette)                                                                                                         |
| 794 |    579.793494 |    483.927066 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 795 |    976.856808 |    408.756154 | Scott Hartman                                                                                                                                                         |
| 796 |    878.552312 |    762.029139 | Mattia Menchetti / Yan Wong                                                                                                                                           |
| 797 |    688.038341 |      2.704078 | NA                                                                                                                                                                    |
| 798 |   1007.928363 |    792.154335 | Margot Michaud                                                                                                                                                        |
| 799 |    102.205538 |    541.755281 | Jagged Fang Designs                                                                                                                                                   |
| 800 |    232.407874 |    313.256479 | Estelle Bourdon                                                                                                                                                       |
| 801 |    121.744183 |    758.001166 | kreidefossilien.de                                                                                                                                                    |
| 802 |    117.198652 |    734.206277 | Steven Traver                                                                                                                                                         |
| 803 |    883.380254 |    661.365651 | Beth Reinke                                                                                                                                                           |
| 804 |    823.147549 |    404.157523 | Collin Gross                                                                                                                                                          |
| 805 |    422.430462 |     46.572504 | Felix Vaux                                                                                                                                                            |
| 806 |    937.994709 |    647.165901 | Tasman Dixon                                                                                                                                                          |
| 807 |    321.909067 |    632.868398 | Sean McCann                                                                                                                                                           |
| 808 |    703.550614 |    120.163537 | T. Michael Keesey                                                                                                                                                     |
| 809 |    316.718779 |    646.078213 | Noah Schlottman, photo from Casey Dunn                                                                                                                                |
| 810 |    424.605525 |    241.180814 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 811 |    705.296712 |    608.804504 | Felix Vaux                                                                                                                                                            |
| 812 |    567.953994 |    358.249144 | Agnello Picorelli                                                                                                                                                     |
| 813 |    515.895987 |    402.621773 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 814 |     51.196461 |    176.289059 | Jagged Fang Designs                                                                                                                                                   |
| 815 |    282.573554 |    341.533457 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                         |
| 816 |    308.653413 |    702.900667 | Mike Hanson                                                                                                                                                           |
| 817 |   1015.828727 |    388.523167 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 818 |    638.297401 |    214.082108 | Gareth Monger                                                                                                                                                         |
| 819 |    315.056057 |    678.646169 | Christoph Schomburg                                                                                                                                                   |
| 820 |     50.411352 |     28.409993 | NA                                                                                                                                                                    |
| 821 |    818.599640 |    759.743714 | Andrew A. Farke                                                                                                                                                       |
| 822 |    726.398579 |     60.617382 | SecretJellyMan                                                                                                                                                        |
| 823 |    179.565008 |    207.553814 | Francesca Belem Lopes Palmeira                                                                                                                                        |
| 824 |    548.486174 |    560.828283 | Chris huh                                                                                                                                                             |
| 825 |    964.410116 |    573.970888 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                      |
| 826 |    756.798452 |    398.766804 | Zimices                                                                                                                                                               |
| 827 |    168.456425 |    255.815473 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 828 |    793.445035 |    518.148527 | H. F. O. March (vectorized by T. Michael Keesey)                                                                                                                      |
| 829 |    162.046369 |    215.363770 | Zimices                                                                                                                                                               |
| 830 |    666.901647 |    145.847407 | Mali’o Kodis, photograph from Jersabek et al, 2003                                                                                                                    |
| 831 |    829.597785 |    318.408833 | Inessa Voet                                                                                                                                                           |
| 832 |    702.153793 |    537.391709 | Ferran Sayol                                                                                                                                                          |
| 833 |    843.721555 |    124.245849 | Todd Marshall, vectorized by Zimices                                                                                                                                  |
| 834 |    149.065163 |    369.577842 | Leon P. A. M. Claessens, Patrick M. O’Connor, David M. Unwin                                                                                                          |
| 835 |    798.248347 |    580.462241 | Baheerathan Murugavel                                                                                                                                                 |
| 836 |    619.507967 |    779.853737 | Margot Michaud                                                                                                                                                        |
| 837 |    847.324601 |    290.621387 | Zimices                                                                                                                                                               |
| 838 |    318.391095 |    754.253351 | Berivan Temiz                                                                                                                                                         |
| 839 |     44.465046 |    552.672881 | Zimices                                                                                                                                                               |
| 840 |    423.517252 |    390.817145 | Matt Crook                                                                                                                                                            |
| 841 |    421.980072 |     66.658585 | Ferran Sayol                                                                                                                                                          |
| 842 |    273.241503 |    300.891228 | FunkMonk                                                                                                                                                              |
| 843 |     21.602592 |     62.047726 | A. H. Baldwin (vectorized by T. Michael Keesey)                                                                                                                       |
| 844 |    165.456248 |    405.061689 | Noah Schlottman, photo from National Science Foundation - Turbellarian Taxonomic Database                                                                             |
| 845 |    595.815273 |     46.761547 | Chris huh                                                                                                                                                             |
| 846 |    877.856156 |    678.137338 | Steven Traver                                                                                                                                                         |
| 847 |     22.392433 |    580.580988 | Gareth Monger                                                                                                                                                         |
| 848 |    194.933303 |    390.980438 | Gareth Monger                                                                                                                                                         |
| 849 |    425.970253 |    523.943486 | Manabu Sakamoto                                                                                                                                                       |
| 850 |    983.476056 |    355.092022 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 851 |    687.304675 |    264.518370 | Darius Nau                                                                                                                                                            |
| 852 |    954.642785 |    355.945908 | Steven Traver                                                                                                                                                         |
| 853 |    943.909485 |    720.416377 | Luis Cunha                                                                                                                                                            |
| 854 |    218.927478 |    210.387417 | Oliver Griffith                                                                                                                                                       |
| 855 |    401.978442 |    347.948457 | NA                                                                                                                                                                    |
| 856 |     99.662066 |    369.402775 | T. Michael Keesey                                                                                                                                                     |
| 857 |    125.330561 |    661.933812 | Matt Crook                                                                                                                                                            |
| 858 |    743.561043 |      3.674995 | Milton Tan                                                                                                                                                            |
| 859 |    274.631379 |    198.051862 | Chuanixn Yu                                                                                                                                                           |
| 860 |    710.002135 |    273.003639 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 861 |    498.403322 |    111.142899 | Chris Jennings (vectorized by A. Verrière)                                                                                                                            |
| 862 |    954.812635 |    200.999971 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 863 |    586.065964 |    246.897813 | Noah Schlottman, photo by Museum of Geology, University of Tartu                                                                                                      |
| 864 |    404.882967 |     34.778553 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 865 |     29.568896 |    493.783294 | Dean Schnabel                                                                                                                                                         |
| 866 |   1002.736486 |     82.714449 | Michael “FunkMonk” B. H. (vectorized by T. Michael Keesey)                                                                                                            |
| 867 |    245.215496 |    396.155104 | Ferran Sayol                                                                                                                                                          |
| 868 |    560.539890 |    735.545473 | Ferran Sayol                                                                                                                                                          |
| 869 |    490.769897 |     99.119318 | Lukasiniho                                                                                                                                                            |
| 870 |   1011.757409 |    331.988120 | Margot Michaud                                                                                                                                                        |
| 871 |    678.841791 |    159.937854 | Scott Hartman                                                                                                                                                         |
| 872 |    301.995716 |    305.561342 | Mathew Wedel                                                                                                                                                          |
| 873 |    724.517713 |    409.434672 | Kai R. Caspar                                                                                                                                                         |
| 874 |    110.838075 |    417.169164 | Michael Scroggie                                                                                                                                                      |
| 875 |    131.351489 |    725.088951 | Steven Traver                                                                                                                                                         |
| 876 |    498.920137 |    785.099766 | Kent Elson Sorgon                                                                                                                                                     |
| 877 |     16.242826 |    745.400654 | DW Bapst (modified from Bulman, 1970)                                                                                                                                 |
| 878 |     52.674242 |    235.127466 | Margot Michaud                                                                                                                                                        |
| 879 |    774.364917 |    697.295994 | Mathew Callaghan                                                                                                                                                      |
| 880 |    974.920931 |    728.424524 | Kamil S. Jaron                                                                                                                                                        |
| 881 |    759.653892 |    590.406437 | J. J. Harrison (photo) & T. Michael Keesey                                                                                                                            |
| 882 |    296.425498 |    787.278567 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 883 |    582.338408 |    791.666802 | Margot Michaud                                                                                                                                                        |
| 884 |    626.997224 |    402.847121 | NA                                                                                                                                                                    |
| 885 |     81.810460 |    344.237432 | Matt Crook                                                                                                                                                            |
| 886 |    623.153138 |     76.380127 | Crystal Maier                                                                                                                                                         |
| 887 |    146.879888 |     96.819173 | Yan Wong (vectorization) from 1873 illustration                                                                                                                       |
| 888 |    917.855393 |    592.321850 | NA                                                                                                                                                                    |
| 889 |    312.021087 |     48.510620 | Inessa Voet                                                                                                                                                           |
| 890 |    907.444155 |    723.297861 | Steven Traver                                                                                                                                                         |
| 891 |    810.375554 |    150.845336 | Alex Slavenko                                                                                                                                                         |
| 892 |    193.114785 |    305.317531 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 893 |    595.334621 |    394.714610 | T. Michael Keesey                                                                                                                                                     |
| 894 |    141.101025 |    703.003576 | Birgit Lang                                                                                                                                                           |
| 895 |    299.545691 |    291.028651 | Chris huh                                                                                                                                                             |
| 896 |    984.873674 |    179.547564 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 897 |    447.982448 |    142.811734 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 898 |    142.083050 |    582.662611 | Steven Traver                                                                                                                                                         |
| 899 |    558.207570 |    352.188237 | Xavier Giroux-Bougard                                                                                                                                                 |
| 900 |    794.380201 |    210.971883 | Ingo Braasch                                                                                                                                                          |
| 901 |    682.960576 |    555.527565 | NA                                                                                                                                                                    |
| 902 |     12.615282 |     70.026373 | Collin Gross                                                                                                                                                          |
| 903 |    857.105929 |    118.211948 | Mali’o Kodis, photograph from <http://commons.wikimedia.org/wiki/File:Trichoplax.jpg>                                                                                 |
| 904 |     25.457059 |    148.647970 | Scott Hartman                                                                                                                                                         |
| 905 |    130.542798 |    202.498672 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                      |
| 906 |    229.097143 |    570.457490 | Yan Wong                                                                                                                                                              |
| 907 |    269.431740 |    311.177477 | Chris Jennings (Risiatto)                                                                                                                                             |
| 908 |     50.061143 |    795.918039 | Margot Michaud                                                                                                                                                        |
| 909 |    840.701211 |    117.482834 | Beth Reinke                                                                                                                                                           |
| 910 |    462.726037 |    700.825650 | Derek Bakken (photograph) and T. Michael Keesey (vectorization)                                                                                                       |
| 911 |    509.548441 |     26.007813 | Chris huh                                                                                                                                                             |
| 912 |    426.840838 |    445.765065 | Scott Hartman                                                                                                                                                         |
| 913 |    681.691754 |    345.649514 | Matt Crook                                                                                                                                                            |
| 914 |    979.436389 |    105.011794 | Michelle Site                                                                                                                                                         |
| 915 |    874.678997 |    108.880303 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 916 |    569.745296 |     67.138762 | NA                                                                                                                                                                    |

    #> Your tweet has been posted!
