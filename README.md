
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

Zimices, Gareth Monger, Yan Wong, Jaime Chirinos (vectorized by T.
Michael Keesey), Ellen Edmonson and Hugh Chrisp (illustration) and
Timothy J. Bartley (silhouette), Scott Hartman, Didier Descouens
(vectorized by T. Michael Keesey), Tauana J. Cunha, Steven Traver, Jose
Carlos Arenas-Monroy, Joanna Wolfe, Collin Gross, Juan Carlos Jerí,
Ferran Sayol, Matt Crook, Chris huh, Frank Förster (based on a picture
by Jerry Kirkhart; modified by T. Michael Keesey), Margot Michaud,
Jagged Fang Designs, Christoph Schomburg, Steven Coombs, Mali’o Kodis,
photograph by Derek Keats (<http://www.flickr.com/photos/dkeats/>), Jon
M Laurent, T. Michael Keesey, DFoidl (vectorized by T. Michael Keesey),
Mathilde Cordellier, T. Michael Keesey (vectorization) and Larry Loos
(photography), Andrés Sánchez, Gabriela Palomo-Munoz, Xavier
Giroux-Bougard, John Curtis (vectorized by T. Michael Keesey), Lukas
Panzarin, Jiekun He, M Hutchinson, Dmitry Bogdanov, Alyssa Bell & Luis
Chiappe 2015, dx.doi.org/10.1371/journal.pone.0141690, Cesar Julian,
Lukasiniho, Dean Schnabel, Caleb M. Brown, Sarah Werning, Andrew A.
Farke, Douglas Brown (modified by T. Michael Keesey), Jaime Headden,
CNZdenek, FunkMonk, C. Camilo Julián-Caballero, Alex Slavenko, Charles
Doolittle Walcott (vectorized by T. Michael Keesey), Nobu Tamura
(vectorized by T. Michael Keesey), Tony Ayling (vectorized by Milton
Tan), Carlos Cano-Barbacil, Ludwik Gasiorowski, Yan Wong from drawing in
The Century Dictionary (1911), Kai R. Caspar, Melissa Broussard,
Meliponicultor Itaymbere, Tracy A. Heath, Sharon Wegner-Larsen, Rebecca
Groom, C. Abraczinskas, Matt Dempsey, Maxime Dahirel, Nobu Tamura,
vectorized by Zimices, Tony Ayling (vectorized by T. Michael Keesey),
Steve Hillebrand/U. S. Fish and Wildlife Service (source photo), T.
Michael Keesey (vectorization), Tasman Dixon, Eric Moody, Armin Reindl,
Smokeybjb, Michelle Site, Jan A. Venter, Herbert H. T. Prins, David A.
Balfour & Rob Slotow (vectorized by T. Michael Keesey), Matthew E.
Clapham, Birgit Lang, James R. Spotila and Ray Chatterji, Christine
Axon, Arthur Weasley (vectorized by T. Michael Keesey), Félix Landry
Yuan, Ville-Veikko Sinkkonen, V. Deepak, Catherine Yasuda, Felix Vaux,
Joedison Rocha, Emily Willoughby, Neil Kelley, Chloé Schmidt, Kosta
Mumcuoglu (vectorized by T. Michael Keesey), Christopher Watson (photo)
and T. Michael Keesey (vectorization), Smokeybjb (vectorized by T.
Michael Keesey), Mali’o Kodis, image from Brockhaus and Efron
Encyclopedic Dictionary, Robbie N. Cada (vectorized by T. Michael
Keesey), Beth Reinke, Steven Haddock • Jellywatch.org, Hans Hillewaert
(vectorized by T. Michael Keesey), Danielle Alba, Auckland Museum and T.
Michael Keesey, Matt Martyniuk, T. Michael Keesey (vectorization) and
Tony Hisgett (photography), Noah Schlottman, L. Shyamal, Roberto Díaz
Sibaja, LeonardoG (photography) and T. Michael Keesey (vectorization),
Apokryltaros (vectorized by T. Michael Keesey), Julio Garza, DW Bapst,
modified from Ishitani et al. 2016, Iain Reid, Cathy, Archaeodontosaurus
(vectorized by T. Michael Keesey), Tony Ayling, Mali’o Kodis, photograph
by Melissa Frey, J Levin W (illustration) and T. Michael Keesey
(vectorization), B. Duygu Özpolat, C. W. Nash (illustration) and Timothy
J. Bartley (silhouette), Ville Koistinen (vectorized by T. Michael
Keesey), Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen
(vectorized by T. Michael Keesey), Gopal Murali, Mathew Wedel, Mattia
Menchetti, M. Antonio Todaro, Tobias Kånneby, Matteo Dal Zotto, and Ulf
Jondelius (vectorized by T. Michael Keesey), Auckland Museum, Stanton F.
Fink (vectorized by T. Michael Keesey), Dmitry Bogdanov (vectorized by
T. Michael Keesey), Chris A. Hamilton, Harold N Eyster, Cyril
Matthey-Doret, adapted from Bernard Chaubet, Ville Koistinen and T.
Michael Keesey, T. Michael Keesey (vectorization) and Nadiatalent
(photography), Ben Liebeskind, Oren Peles / vectorized by Yan Wong,
Jessica Anne Miller, Emily Jane McTavish, George Edward Lodge (modified
by T. Michael Keesey), Shyamal, Milton Tan, Jakovche, Darren Naish
(vectorized by T. Michael Keesey), Ernst Haeckel (vectorized by T.
Michael Keesey), Pranav Iyer (grey ideas), Rachel Shoop, Kenneth
Lacovara (vectorized by T. Michael Keesey), Thibaut Brunet, Tarique Sani
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Yan Wong from illustration by Jules Richard (1907), Michele M
Tobias, Courtney Rockenbach, Joris van der Ham (vectorized by T. Michael
Keesey), Pete Buchholz, Francis de Laporte de Castelnau (vectorized by
T. Michael Keesey), B Kimmel, Anthony Caravaggi, James I. Kirkland, Luis
Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P.
Wiersma (vectorized by T. Michael Keesey), Eduard Solà Vázquez,
vectorised by Yan Wong, Meyers Konversations-Lexikon 1897 (vectorized:
Yan Wong), Noah Schlottman, photo by Gustav Paulay for Moorea Biocode,
Kamil S. Jaron, Trond R. Oskars, Todd Marshall, vectorized by Zimices,
DW Bapst (modified from Bulman, 1970), Qiang Ou, Sergio A. Muñoz-Gómez,
Maija Karala, Mali’o Kodis, photograph by Cordell Expeditions at Cal
Academy, T. Michael Keesey (after Colin M. L. Burnett), Warren H
(photography), T. Michael Keesey (vectorization), Darius Nau, Kent Elson
Sorgon, Mason McNair, xgirouxb, Matus Valach, Rene Martin, Ingo Braasch,
Becky Barnes, Nobu Tamura, Yan Wong from wikipedia drawing (PD: Pearson
Scott Foresman), Liftarn, Mali’o Kodis, image from the Biodiversity
Heritage Library, Marcos Pérez-Losada, Jens T. Høeg & Keith A. Crandall,
Martin R. Smith, Taro Maeda, \[unknown\], Kimberly Haddrell, Maky
(vectorization), Gabriella Skollar (photography), Rebecca Lewis
(editing), Don Armstrong, Keith Murdock (photo), John E. McCormack,
Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C.
Glenn, Robb T. Brumfield & T. Michael Keesey, T. Michael Keesey (after
James & al.), Brad McFeeters (vectorized by T. Michael Keesey), Pearson
Scott Foresman (vectorized by T. Michael Keesey), terngirl, DW Bapst,
modified from Figure 1 of Belanger (2011, PALAIOS)., Filip em, Mo
Hassan, Florian Pfaff, M Kolmann, Ray Simpson (vectorized by T. Michael
Keesey), Michael P. Taylor, Scott Hartman (vectorized by T. Michael
Keesey), Noah Schlottman, photo by Adam G. Clause, Paul O. Lewis,
Francisco Manuel Blanco (vectorized by T. Michael Keesey), Roderic Page
and Lois Page, Darren Naish (vectorize by T. Michael Keesey), Martin
Kevil, Cristopher Silva, Ryan Cupo, Sean McCann, Henry Lydecker, Noah
Schlottman, photo by Carol Cummings, Richard Parker (vectorized by T.
Michael Keesey), Katie S. Collins, Patrick Fisher (vectorized by T.
Michael Keesey), Crystal Maier, Jack Mayer Wood, Scott Reid, Jaime
Headden (vectorized by T. Michael Keesey), Lauren Anderson, Chase
Brownstein, Jaime Headden, modified by T. Michael Keesey, Kailah Thorn &
Mark Hutchinson, Cagri Cevrim, Noah Schlottman, photo from National
Science Foundation - Turbellarian Taxonomic Database, Emma Hughes,
Kanako Bessho-Uehara, Jonathan Wells, Fernando Carezzano, Nicholas J.
Czaplewski, vectorized by Zimices, Michael Scroggie, kotik, Yan Wong
from photo by Gyik Toma, Konsta Happonen, Javier Luque, Philippe Janvier
(vectorized by T. Michael Keesey), Lee Harding (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Mali’o Kodis,
photograph by Hans Hillewaert, François Michonneau, Sibi (vectorized by
T. Michael Keesey), Josefine Bohr Brask, Philip Chalmers (vectorized by
T. Michael Keesey), Campbell Fleming, Noah Schlottman, photo by Casey
Dunn, Pollyanna von Knorring and T. Michael Keesey, Konsta Happonen,
from a CC-BY-NC image by sokolkov2002 on iNaturalist, Jake Warner,
Benchill, Kailah Thorn & Ben King, Robert Gay, Obsidian Soul (vectorized
by T. Michael Keesey), Dann Pigdon, Nicolas Huet le Jeune and
Jean-Gabriel Prêtre (vectorized by T. Michael Keesey), Matt Martyniuk
(modified by T. Michael Keesey), Lani Mohan, Leann Biancani, photo by
Kenneth Clifton, T. Michael Keesey, from a photograph by Thea Boodhoo,
Manabu Sakamoto, mystica, JJ Harrison (vectorized by T. Michael Keesey),
Notafly (vectorized by T. Michael Keesey), T. Michael Keesey (photo by
Darren Swim), Tomas Willems (vectorized by T. Michael Keesey), Chris
Jennings (Risiatto), Martien Brand (original photo), Renato Santos
(vector silhouette), Christian A. Masnaghetti, Matthias Buschmann
(vectorized by T. Michael Keesey), Mike Hanson, Caio Bernardes,
vectorized by Zimices

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                        |
| --: | ------------: | ------------: | :------------------------------------------------------------------------------------------------------------------------------------------------------------ |
|   1 |    568.200763 |    430.573914 | Zimices                                                                                                                                                       |
|   2 |     85.587017 |    286.441898 | Gareth Monger                                                                                                                                                 |
|   3 |    886.947274 |    756.235867 | Yan Wong                                                                                                                                                      |
|   4 |    875.422716 |    164.896755 | Jaime Chirinos (vectorized by T. Michael Keesey)                                                                                                              |
|   5 |    411.247139 |    285.486266 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                             |
|   6 |    515.581263 |    582.778820 | Scott Hartman                                                                                                                                                 |
|   7 |    946.421737 |     57.199883 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                            |
|   8 |     63.533650 |    758.584608 | Tauana J. Cunha                                                                                                                                               |
|   9 |    624.558941 |     85.875402 | Steven Traver                                                                                                                                                 |
|  10 |    864.328071 |    243.123733 | Zimices                                                                                                                                                       |
|  11 |    261.569619 |    402.931311 | Jose Carlos Arenas-Monroy                                                                                                                                     |
|  12 |    709.335183 |    186.773564 | Joanna Wolfe                                                                                                                                                  |
|  13 |    707.027619 |    651.015496 | Collin Gross                                                                                                                                                  |
|  14 |    299.771165 |    135.887224 | Juan Carlos Jerí                                                                                                                                              |
|  15 |    752.876355 |    537.483609 | Ferran Sayol                                                                                                                                                  |
|  16 |    333.086054 |    611.850488 | Matt Crook                                                                                                                                                    |
|  17 |    555.214744 |    192.522297 | Chris huh                                                                                                                                                     |
|  18 |    946.806224 |    648.131272 | Gareth Monger                                                                                                                                                 |
|  19 |    526.560146 |    688.603686 | Matt Crook                                                                                                                                                    |
|  20 |    147.654279 |    529.129488 | Frank Förster (based on a picture by Jerry Kirkhart; modified by T. Michael Keesey)                                                                           |
|  21 |    273.028489 |    550.391820 | Margot Michaud                                                                                                                                                |
|  22 |    734.190462 |    291.271171 | NA                                                                                                                                                            |
|  23 |    198.893392 |    706.937293 | Chris huh                                                                                                                                                     |
|  24 |    769.040017 |     53.835325 | Jagged Fang Designs                                                                                                                                           |
|  25 |    204.073862 |    639.061183 | Christoph Schomburg                                                                                                                                           |
|  26 |    255.260368 |    236.974972 | Steven Coombs                                                                                                                                                 |
|  27 |    425.366485 |    635.281138 | Chris huh                                                                                                                                                     |
|  28 |    396.041884 |    195.014945 | Mali’o Kodis, photograph by Derek Keats (<http://www.flickr.com/photos/dkeats/>)                                                                              |
|  29 |    888.882830 |    411.998953 | Jon M Laurent                                                                                                                                                 |
|  30 |     69.257040 |    644.408072 | Chris huh                                                                                                                                                     |
|  31 |    437.135887 |     57.273697 | T. Michael Keesey                                                                                                                                             |
|  32 |    503.710926 |    243.157992 | DFoidl (vectorized by T. Michael Keesey)                                                                                                                      |
|  33 |    355.302807 |    746.538487 | Mathilde Cordellier                                                                                                                                           |
|  34 |    627.904833 |    742.254519 | Scott Hartman                                                                                                                                                 |
|  35 |    978.056905 |    172.484469 | T. Michael Keesey (vectorization) and Larry Loos (photography)                                                                                                |
|  36 |    220.290866 |     75.451225 | Andrés Sánchez                                                                                                                                                |
|  37 |    612.220086 |    301.494765 | Gabriela Palomo-Munoz                                                                                                                                         |
|  38 |     85.605236 |     31.405506 | Xavier Giroux-Bougard                                                                                                                                         |
|  39 |    511.704803 |    136.127671 | John Curtis (vectorized by T. Michael Keesey)                                                                                                                 |
|  40 |    926.620840 |    565.666598 | Gareth Monger                                                                                                                                                 |
|  41 |    939.209979 |    496.698922 | Lukas Panzarin                                                                                                                                                |
|  42 |    923.310281 |    300.082832 | Jiekun He                                                                                                                                                     |
|  43 |    540.616681 |    539.862202 | Zimices                                                                                                                                                       |
|  44 |    137.787887 |    611.909749 | M Hutchinson                                                                                                                                                  |
|  45 |    335.049267 |     73.118385 | Zimices                                                                                                                                                       |
|  46 |    635.548262 |    229.216072 | Jagged Fang Designs                                                                                                                                           |
|  47 |    831.723051 |    656.681880 | Joanna Wolfe                                                                                                                                                  |
|  48 |    504.525591 |    768.637429 | Dmitry Bogdanov                                                                                                                                               |
|  49 |    819.103828 |    312.745760 | Alyssa Bell & Luis Chiappe 2015, dx.doi.org/10.1371/journal.pone.0141690                                                                                      |
|  50 |    415.023605 |    674.571001 | Jagged Fang Designs                                                                                                                                           |
|  51 |    700.918935 |    494.180500 | Gareth Monger                                                                                                                                                 |
|  52 |    187.576906 |    670.729502 | Cesar Julian                                                                                                                                                  |
|  53 |    991.152119 |    387.382779 | Lukasiniho                                                                                                                                                    |
|  54 |     71.077540 |    694.180228 | Chris huh                                                                                                                                                     |
|  55 |    840.507535 |     38.434491 | T. Michael Keesey                                                                                                                                             |
|  56 |    348.661668 |    330.041959 | Scott Hartman                                                                                                                                                 |
|  57 |    161.208353 |    127.869704 | Steven Traver                                                                                                                                                 |
|  58 |    673.172442 |    694.077904 | Dean Schnabel                                                                                                                                                 |
|  59 |    733.784284 |    773.124845 | Cesar Julian                                                                                                                                                  |
|  60 |    784.357331 |    447.872067 | Christoph Schomburg                                                                                                                                           |
|  61 |    265.839692 |    507.236440 | Caleb M. Brown                                                                                                                                                |
|  62 |    625.577273 |    648.316876 | Matt Crook                                                                                                                                                    |
|  63 |    549.745676 |     36.600276 | Sarah Werning                                                                                                                                                 |
|  64 |    277.677819 |    730.716926 | Steven Traver                                                                                                                                                 |
|  65 |    185.144687 |    760.464723 | Andrew A. Farke                                                                                                                                               |
|  66 |     65.150514 |    524.326847 | Douglas Brown (modified by T. Michael Keesey)                                                                                                                 |
|  67 |    231.971179 |    614.536444 | Jaime Headden                                                                                                                                                 |
|  68 |    810.659233 |    409.311856 | CNZdenek                                                                                                                                                      |
|  69 |    995.429449 |    103.436116 | Matt Crook                                                                                                                                                    |
|  70 |    350.907953 |    249.618921 | Zimices                                                                                                                                                       |
|  71 |    248.259708 |    294.690125 | FunkMonk                                                                                                                                                      |
|  72 |    190.259311 |    345.178906 | Margot Michaud                                                                                                                                                |
|  73 |    698.110477 |    118.733119 | Scott Hartman                                                                                                                                                 |
|  74 |    183.656871 |    308.552827 | Sarah Werning                                                                                                                                                 |
|  75 |    554.188042 |     87.915838 | Gabriela Palomo-Munoz                                                                                                                                         |
|  76 |    581.160081 |    627.460917 | C. Camilo Julián-Caballero                                                                                                                                    |
|  77 |    442.547458 |     25.434289 | Scott Hartman                                                                                                                                                 |
|  78 |    711.016234 |    339.067348 | Alex Slavenko                                                                                                                                                 |
|  79 |    344.907004 |     12.820610 | NA                                                                                                                                                            |
|  80 |    992.568475 |    275.193983 | Charles Doolittle Walcott (vectorized by T. Michael Keesey)                                                                                                   |
|  81 |    358.751382 |    133.619552 | Chris huh                                                                                                                                                     |
|  82 |    845.040078 |    346.144739 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                 |
|  83 |    478.763865 |    322.284743 | NA                                                                                                                                                            |
|  84 |    387.186128 |    533.713458 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                 |
|  85 |    513.278665 |    459.218451 | Tony Ayling (vectorized by Milton Tan)                                                                                                                        |
|  86 |    746.420548 |    488.446196 | Carlos Cano-Barbacil                                                                                                                                          |
|  87 |    625.818875 |    568.452460 | C. Camilo Julián-Caballero                                                                                                                                    |
|  88 |    760.618192 |    122.546555 | Jagged Fang Designs                                                                                                                                           |
|  89 |    615.934451 |    150.536654 | Ferran Sayol                                                                                                                                                  |
|  90 |    800.892686 |    163.411091 | Ludwik Gasiorowski                                                                                                                                            |
|  91 |    445.168092 |    245.684842 | Yan Wong from drawing in The Century Dictionary (1911)                                                                                                        |
|  92 |    712.379059 |    604.835513 | Kai R. Caspar                                                                                                                                                 |
|  93 |    277.273675 |    163.758448 | Chris huh                                                                                                                                                     |
|  94 |     68.038356 |     65.496482 | Melissa Broussard                                                                                                                                             |
|  95 |    183.372027 |    201.165854 | Melissa Broussard                                                                                                                                             |
|  96 |    260.262672 |    578.663045 | Meliponicultor Itaymbere                                                                                                                                      |
|  97 |    471.452154 |    601.806510 | Tracy A. Heath                                                                                                                                                |
|  98 |    228.216532 |    582.655438 | Sharon Wegner-Larsen                                                                                                                                          |
|  99 |    454.370271 |    687.258298 | Steven Traver                                                                                                                                                 |
| 100 |    264.454616 |    771.448975 | Rebecca Groom                                                                                                                                                 |
| 101 |    201.926727 |    137.335254 | T. Michael Keesey                                                                                                                                             |
| 102 |    667.310497 |    433.799945 | Margot Michaud                                                                                                                                                |
| 103 |    596.413630 |    786.036768 | Matt Crook                                                                                                                                                    |
| 104 |    329.490483 |    690.840233 | C. Abraczinskas                                                                                                                                               |
| 105 |    616.994908 |    269.553603 | Matt Dempsey                                                                                                                                                  |
| 106 |    322.159946 |    276.816806 | Gareth Monger                                                                                                                                                 |
| 107 |    161.761165 |    367.102352 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                 |
| 108 |    809.450941 |    728.871000 | Maxime Dahirel                                                                                                                                                |
| 109 |    267.231584 |    687.529315 | Nobu Tamura, vectorized by Zimices                                                                                                                            |
| 110 |    706.563913 |     52.050863 | Zimices                                                                                                                                                       |
| 111 |    376.743131 |    718.409269 | Ferran Sayol                                                                                                                                                  |
| 112 |    846.253052 |    475.042986 | Lukasiniho                                                                                                                                                    |
| 113 |    657.953561 |    108.880703 | Zimices                                                                                                                                                       |
| 114 |    664.926925 |    765.332470 | Jagged Fang Designs                                                                                                                                           |
| 115 |    963.705604 |    226.090268 | Ferran Sayol                                                                                                                                                  |
| 116 |    723.453408 |     73.352786 | Zimices                                                                                                                                                       |
| 117 |    430.269639 |    115.972401 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                 |
| 118 |    876.862089 |    262.219754 | Steve Hillebrand/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                            |
| 119 |    252.860800 |    649.590977 | Tasman Dixon                                                                                                                                                  |
| 120 |     15.690833 |    475.666438 | Gareth Monger                                                                                                                                                 |
| 121 |    922.283380 |    109.260099 | Eric Moody                                                                                                                                                    |
| 122 |    874.655993 |    463.566329 | Steven Traver                                                                                                                                                 |
| 123 |     66.377752 |    542.031462 | Steven Traver                                                                                                                                                 |
| 124 |    816.268066 |    292.838468 | Dean Schnabel                                                                                                                                                 |
| 125 |    383.628907 |    122.962348 | Zimices                                                                                                                                                       |
| 126 |   1002.780670 |    569.466746 | Armin Reindl                                                                                                                                                  |
| 127 |    441.372938 |    614.233896 | Zimices                                                                                                                                                       |
| 128 |    877.686326 |     96.906466 | Smokeybjb                                                                                                                                                     |
| 129 |    558.195269 |    463.006329 | Michelle Site                                                                                                                                                 |
| 130 |    463.791110 |    535.986041 | NA                                                                                                                                                            |
| 131 |    383.531649 |    390.586094 | Sarah Werning                                                                                                                                                 |
| 132 |   1012.094033 |    788.341153 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                           |
| 133 |    674.430642 |    418.555005 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                 |
| 134 |    867.707846 |     25.922008 | Matthew E. Clapham                                                                                                                                            |
| 135 |    633.718832 |     18.453840 | Scott Hartman                                                                                                                                                 |
| 136 |    349.496197 |    696.129885 | Birgit Lang                                                                                                                                                   |
| 137 |    972.421410 |     99.579352 | Gareth Monger                                                                                                                                                 |
| 138 |    900.910852 |    704.170600 | James R. Spotila and Ray Chatterji                                                                                                                            |
| 139 |    785.495734 |    377.527117 | Joanna Wolfe                                                                                                                                                  |
| 140 |    434.221488 |    687.881288 | Christine Axon                                                                                                                                                |
| 141 |   1010.594683 |    519.595395 | Scott Hartman                                                                                                                                                 |
| 142 |     53.041692 |    710.086795 | Alex Slavenko                                                                                                                                                 |
| 143 |    570.079147 |    714.011330 | Arthur Weasley (vectorized by T. Michael Keesey)                                                                                                              |
| 144 |    647.153603 |    428.039187 | Matt Crook                                                                                                                                                    |
| 145 |    133.564595 |    469.572926 | Félix Landry Yuan                                                                                                                                             |
| 146 |    254.808763 |    180.689037 | Scott Hartman                                                                                                                                                 |
| 147 |     31.804531 |    563.134893 | Zimices                                                                                                                                                       |
| 148 |     67.357231 |    570.811185 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                 |
| 149 |    241.179633 |    728.790984 | Ville-Veikko Sinkkonen                                                                                                                                        |
| 150 |    169.253148 |    462.229788 | Zimices                                                                                                                                                       |
| 151 |    598.368451 |    195.966699 | Tasman Dixon                                                                                                                                                  |
| 152 |    115.609957 |    736.395543 | V. Deepak                                                                                                                                                     |
| 153 |    792.899609 |    595.206109 | Scott Hartman                                                                                                                                                 |
| 154 |     27.808281 |    573.877962 | Catherine Yasuda                                                                                                                                              |
| 155 |    654.095546 |    270.761898 | Margot Michaud                                                                                                                                                |
| 156 |    730.184709 |    614.492470 | Steven Traver                                                                                                                                                 |
| 157 |    211.926402 |    154.985460 | Scott Hartman                                                                                                                                                 |
| 158 |    778.066326 |     18.952999 | Felix Vaux                                                                                                                                                    |
| 159 |    387.452794 |    790.581084 | Gareth Monger                                                                                                                                                 |
| 160 |    541.544185 |    723.362626 | Joedison Rocha                                                                                                                                                |
| 161 |     35.929822 |    782.891899 | Emily Willoughby                                                                                                                                              |
| 162 |    815.215862 |    791.844080 | Neil Kelley                                                                                                                                                   |
| 163 |    327.442796 |    775.913463 | Jagged Fang Designs                                                                                                                                           |
| 164 |    534.696790 |    212.046278 | Zimices                                                                                                                                                       |
| 165 |    924.581316 |    170.278594 | Chloé Schmidt                                                                                                                                                 |
| 166 |    715.249506 |    525.950725 | NA                                                                                                                                                            |
| 167 |    386.965567 |    774.286890 | Kosta Mumcuoglu (vectorized by T. Michael Keesey)                                                                                                             |
| 168 |    946.551182 |    358.628233 | Jagged Fang Designs                                                                                                                                           |
| 169 |    400.078715 |    121.139905 | Nobu Tamura, vectorized by Zimices                                                                                                                            |
| 170 |    951.625636 |    240.450807 | Christopher Watson (photo) and T. Michael Keesey (vectorization)                                                                                              |
| 171 |    146.303304 |     58.269851 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                   |
| 172 |    346.569393 |    527.797088 | NA                                                                                                                                                            |
| 173 |    693.541375 |    466.917680 | Gareth Monger                                                                                                                                                 |
| 174 |      9.163348 |    595.810959 | Mali’o Kodis, image from Brockhaus and Efron Encyclopedic Dictionary                                                                                          |
| 175 |    653.929524 |    289.482214 | Melissa Broussard                                                                                                                                             |
| 176 |    488.968043 |    736.367752 | Felix Vaux                                                                                                                                                    |
| 177 |    709.880328 |    184.573298 | Michelle Site                                                                                                                                                 |
| 178 |    686.345028 |     88.110671 | Scott Hartman                                                                                                                                                 |
| 179 |    473.616880 |    161.474495 | Margot Michaud                                                                                                                                                |
| 180 |    508.724547 |    482.611608 | NA                                                                                                                                                            |
| 181 |    963.376029 |    272.517196 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                              |
| 182 |    550.163404 |     21.287140 | Beth Reinke                                                                                                                                                   |
| 183 |    521.359017 |     17.906217 | NA                                                                                                                                                            |
| 184 |    169.396885 |    327.971425 | Zimices                                                                                                                                                       |
| 185 |    705.399189 |     29.329729 | Steven Haddock • Jellywatch.org                                                                                                                               |
| 186 |    631.230063 |    600.318636 | Matt Crook                                                                                                                                                    |
| 187 |    398.771508 |    407.924288 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                 |
| 188 |    145.311280 |    463.489806 | Michelle Site                                                                                                                                                 |
| 189 |    496.102290 |    212.519586 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                             |
| 190 |    806.242837 |    593.836697 | Tasman Dixon                                                                                                                                                  |
| 191 |     10.614642 |    219.289536 | NA                                                                                                                                                            |
| 192 |    407.146475 |    778.555896 | Danielle Alba                                                                                                                                                 |
| 193 |    706.612308 |    234.195706 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                 |
| 194 |     44.326378 |    668.848757 | Margot Michaud                                                                                                                                                |
| 195 |    360.059238 |    721.975869 | Auckland Museum and T. Michael Keesey                                                                                                                         |
| 196 |    207.918347 |    199.734982 | Scott Hartman                                                                                                                                                 |
| 197 |    627.295843 |    619.485478 | Matt Martyniuk                                                                                                                                                |
| 198 |    535.770344 |    316.620558 | Tracy A. Heath                                                                                                                                                |
| 199 |    164.246834 |    224.210935 | T. Michael Keesey (vectorization) and Tony Hisgett (photography)                                                                                              |
| 200 |    974.641505 |    595.095320 | Matt Crook                                                                                                                                                    |
| 201 |    294.864740 |    500.533201 | Matt Crook                                                                                                                                                    |
| 202 |    934.474723 |    152.501167 | T. Michael Keesey                                                                                                                                             |
| 203 |    986.738103 |    316.474902 | Margot Michaud                                                                                                                                                |
| 204 |     24.254833 |    636.964139 | NA                                                                                                                                                            |
| 205 |    393.547587 |    265.365267 | Steven Coombs                                                                                                                                                 |
| 206 |    737.845594 |    450.597040 | Steven Traver                                                                                                                                                 |
| 207 |    349.394354 |    104.009297 | Steven Traver                                                                                                                                                 |
| 208 |    238.508424 |    150.537979 | Noah Schlottman                                                                                                                                               |
| 209 |    266.435867 |    145.656833 | Ferran Sayol                                                                                                                                                  |
| 210 |    717.953236 |    158.348952 | Steven Traver                                                                                                                                                 |
| 211 |    379.245777 |    687.659406 | Matt Crook                                                                                                                                                    |
| 212 |    874.627321 |    619.133805 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                 |
| 213 |    478.741514 |     37.440474 | Scott Hartman                                                                                                                                                 |
| 214 |    991.951899 |    749.824367 | Kai R. Caspar                                                                                                                                                 |
| 215 |   1015.589148 |     63.843834 | Dean Schnabel                                                                                                                                                 |
| 216 |    963.167884 |    438.422826 | Matt Crook                                                                                                                                                    |
| 217 |    559.114392 |    688.753175 | L. Shyamal                                                                                                                                                    |
| 218 |    514.808964 |     74.431240 | Gabriela Palomo-Munoz                                                                                                                                         |
| 219 |    526.418976 |    491.486688 | Felix Vaux                                                                                                                                                    |
| 220 |   1005.699350 |    475.129425 | Ferran Sayol                                                                                                                                                  |
| 221 |    149.626805 |    692.767166 | Roberto Díaz Sibaja                                                                                                                                           |
| 222 |    215.713012 |    504.185418 | LeonardoG (photography) and T. Michael Keesey (vectorization)                                                                                                 |
| 223 |    789.097392 |    737.490210 | Zimices                                                                                                                                                       |
| 224 |    954.476300 |    359.276361 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                |
| 225 |    810.827668 |    257.900891 | Steven Traver                                                                                                                                                 |
| 226 |    991.368445 |    103.088709 | Julio Garza                                                                                                                                                   |
| 227 |    247.750354 |    552.357515 | T. Michael Keesey                                                                                                                                             |
| 228 |    363.373995 |     39.378648 | Tauana J. Cunha                                                                                                                                               |
| 229 |    809.880303 |    246.863868 | Joanna Wolfe                                                                                                                                                  |
| 230 |    702.168353 |    257.881154 | Nobu Tamura, vectorized by Zimices                                                                                                                            |
| 231 |    347.906082 |    470.844096 | NA                                                                                                                                                            |
| 232 |    892.624750 |    532.490711 | Gabriela Palomo-Munoz                                                                                                                                         |
| 233 |    779.155426 |    211.337591 | Roberto Díaz Sibaja                                                                                                                                           |
| 234 |    761.829786 |    358.903618 | DW Bapst, modified from Ishitani et al. 2016                                                                                                                  |
| 235 |    861.620732 |     79.137906 | James R. Spotila and Ray Chatterji                                                                                                                            |
| 236 |   1009.754570 |    609.881733 | Iain Reid                                                                                                                                                     |
| 237 |    648.952375 |    604.497209 | T. Michael Keesey                                                                                                                                             |
| 238 |    755.000118 |     21.310063 | Gareth Monger                                                                                                                                                 |
| 239 |    366.487038 |    325.796012 | NA                                                                                                                                                            |
| 240 |     21.741276 |    794.964183 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                 |
| 241 |    181.727033 |     72.021680 | Cathy                                                                                                                                                         |
| 242 |    289.645758 |    298.359610 | Tasman Dixon                                                                                                                                                  |
| 243 |    852.046878 |     13.771369 | Zimices                                                                                                                                                       |
| 244 |   1013.414222 |    697.649107 | Archaeodontosaurus (vectorized by T. Michael Keesey)                                                                                                          |
| 245 |    403.125787 |    358.130178 | NA                                                                                                                                                            |
| 246 |    334.866001 |    467.954466 | Tasman Dixon                                                                                                                                                  |
| 247 |   1003.706801 |    460.573883 | Zimices                                                                                                                                                       |
| 248 |    462.743985 |    205.317308 | Zimices                                                                                                                                                       |
| 249 |    479.739825 |    537.241784 | Cesar Julian                                                                                                                                                  |
| 250 |    384.844101 |    708.006904 | Margot Michaud                                                                                                                                                |
| 251 |    494.338836 |    677.557434 | Alex Slavenko                                                                                                                                                 |
| 252 |     85.486544 |    667.346736 | Chris huh                                                                                                                                                     |
| 253 |    785.176367 |    115.514080 | Tony Ayling                                                                                                                                                   |
| 254 |    348.576726 |    306.308138 | T. Michael Keesey                                                                                                                                             |
| 255 |   1011.788387 |    242.348673 | Mali’o Kodis, photograph by Melissa Frey                                                                                                                      |
| 256 |    877.202629 |     45.570883 | Chris huh                                                                                                                                                     |
| 257 |    753.046260 |    705.593997 | T. Michael Keesey                                                                                                                                             |
| 258 |   1010.034790 |    446.072868 | Margot Michaud                                                                                                                                                |
| 259 |    343.281328 |    498.315767 | L. Shyamal                                                                                                                                                    |
| 260 |     14.397072 |     21.858641 | J Levin W (illustration) and T. Michael Keesey (vectorization)                                                                                                |
| 261 |    215.983139 |     10.729969 | B. Duygu Özpolat                                                                                                                                              |
| 262 |    880.463241 |    105.535359 | Zimices                                                                                                                                                       |
| 263 |    437.911608 |    579.617098 | Margot Michaud                                                                                                                                                |
| 264 |     16.453617 |    179.124920 | Tauana J. Cunha                                                                                                                                               |
| 265 |    572.150050 |    135.232543 | Steven Traver                                                                                                                                                 |
| 266 |    368.393557 |    426.471854 | Ferran Sayol                                                                                                                                                  |
| 267 |    478.071357 |    690.796329 | Collin Gross                                                                                                                                                  |
| 268 |    892.699052 |    694.759141 | Scott Hartman                                                                                                                                                 |
| 269 |    846.642804 |    573.550500 | Gareth Monger                                                                                                                                                 |
| 270 |    412.604512 |    734.042200 | C. W. Nash (illustration) and Timothy J. Bartley (silhouette)                                                                                                 |
| 271 |    301.401587 |    675.550579 | Ville Koistinen (vectorized by T. Michael Keesey)                                                                                                             |
| 272 |    863.035346 |    541.276246 | Steven Traver                                                                                                                                                 |
| 273 |   1000.200027 |     78.738518 | Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael Keesey)                                                                        |
| 274 |    297.591255 |     23.596216 | Gopal Murali                                                                                                                                                  |
| 275 |    411.144421 |    325.443377 | NA                                                                                                                                                            |
| 276 |    883.402417 |    367.128842 | Mathew Wedel                                                                                                                                                  |
| 277 |    895.606407 |    525.794177 | Zimices                                                                                                                                                       |
| 278 |    330.672637 |    673.565143 | Ferran Sayol                                                                                                                                                  |
| 279 |    444.927987 |    340.559026 | Mattia Menchetti                                                                                                                                              |
| 280 |    506.270584 |    566.314241 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                 |
| 281 |    501.962979 |    540.621960 | Gareth Monger                                                                                                                                                 |
| 282 |     41.942203 |    484.733927 | Birgit Lang                                                                                                                                                   |
| 283 |    757.390377 |    628.755164 | M. Antonio Todaro, Tobias Kånneby, Matteo Dal Zotto, and Ulf Jondelius (vectorized by T. Michael Keesey)                                                      |
| 284 |    468.403208 |    334.778872 | Auckland Museum                                                                                                                                               |
| 285 |    192.993900 |    784.088109 | Chris huh                                                                                                                                                     |
| 286 |    918.115447 |    129.214890 | Andrew A. Farke                                                                                                                                               |
| 287 |    792.031729 |    207.558009 | Joanna Wolfe                                                                                                                                                  |
| 288 |    965.429454 |     31.941782 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                             |
| 289 |     13.657907 |    328.043570 | NA                                                                                                                                                            |
| 290 |    593.335436 |    698.039779 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                             |
| 291 |    514.690425 |    214.561099 | Chris A. Hamilton                                                                                                                                             |
| 292 |    958.180516 |    796.240855 | Smokeybjb                                                                                                                                                     |
| 293 |    283.815635 |    693.908905 | Harold N Eyster                                                                                                                                               |
| 294 |    569.180565 |    147.723223 | Cyril Matthey-Doret, adapted from Bernard Chaubet                                                                                                             |
| 295 |    837.002788 |    464.631161 | NA                                                                                                                                                            |
| 296 |    180.466195 |    366.679604 | Jagged Fang Designs                                                                                                                                           |
| 297 |    575.062380 |    254.784799 | Yan Wong                                                                                                                                                      |
| 298 |    579.109399 |    105.612197 | Matt Crook                                                                                                                                                    |
| 299 |    392.997274 |    319.908947 | Zimices                                                                                                                                                       |
| 300 |    238.968725 |    310.719830 | Chris huh                                                                                                                                                     |
| 301 |    349.165602 |    788.260310 | Margot Michaud                                                                                                                                                |
| 302 |    486.058435 |    106.487314 | Scott Hartman                                                                                                                                                 |
| 303 |     56.386581 |    558.077709 | Sharon Wegner-Larsen                                                                                                                                          |
| 304 |    355.129524 |    474.094184 | Matt Crook                                                                                                                                                    |
| 305 |    669.326087 |     73.868597 | Ville Koistinen and T. Michael Keesey                                                                                                                         |
| 306 |     79.906256 |    720.216857 | Margot Michaud                                                                                                                                                |
| 307 |    771.959818 |    319.059924 | Chris huh                                                                                                                                                     |
| 308 |    625.028241 |    670.457237 | Dmitry Bogdanov                                                                                                                                               |
| 309 |    593.155581 |     15.830576 | T. Michael Keesey (vectorization) and Nadiatalent (photography)                                                                                               |
| 310 |    582.718084 |    597.496278 | Scott Hartman                                                                                                                                                 |
| 311 |    948.778547 |    790.841134 | Steven Traver                                                                                                                                                 |
| 312 |     84.971471 |    774.111018 | Gareth Monger                                                                                                                                                 |
| 313 |    367.234813 |    378.567005 | Ben Liebeskind                                                                                                                                                |
| 314 |    312.102656 |    505.295377 | Matt Crook                                                                                                                                                    |
| 315 |    205.540072 |    787.216028 | Jaime Headden                                                                                                                                                 |
| 316 |    414.177620 |    142.622039 | Margot Michaud                                                                                                                                                |
| 317 |    848.712589 |    593.393233 | Jagged Fang Designs                                                                                                                                           |
| 318 |    998.255369 |     34.758316 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                 |
| 319 |    900.304985 |    719.847046 | Ferran Sayol                                                                                                                                                  |
| 320 |    117.926013 |     56.641393 | Christoph Schomburg                                                                                                                                           |
| 321 |    158.661645 |     61.515306 | Matt Crook                                                                                                                                                    |
| 322 |    906.711490 |    293.385079 | NA                                                                                                                                                            |
| 323 |    224.828235 |    781.769470 | Zimices                                                                                                                                                       |
| 324 |    960.673340 |    573.180749 | Oren Peles / vectorized by Yan Wong                                                                                                                           |
| 325 |    517.157032 |    718.792950 | Jessica Anne Miller                                                                                                                                           |
| 326 |    780.887430 |    468.725676 | Emily Jane McTavish                                                                                                                                           |
| 327 |    586.370269 |    202.839980 | Gareth Monger                                                                                                                                                 |
| 328 |    954.923430 |    100.731713 | Steven Traver                                                                                                                                                 |
| 329 |    284.529177 |    791.570850 | Matt Crook                                                                                                                                                    |
| 330 |     27.674176 |    642.922229 | Margot Michaud                                                                                                                                                |
| 331 |    872.942821 |    331.962695 | Steven Traver                                                                                                                                                 |
| 332 |    496.232603 |    494.660769 | George Edward Lodge (modified by T. Michael Keesey)                                                                                                           |
| 333 |    517.913449 |    326.447094 | Michelle Site                                                                                                                                                 |
| 334 |     34.593167 |     58.360455 | Zimices                                                                                                                                                       |
| 335 |    256.825375 |     75.514758 | Ferran Sayol                                                                                                                                                  |
| 336 |    569.759255 |     17.610684 | Margot Michaud                                                                                                                                                |
| 337 |    529.810304 |     66.267129 | Gabriela Palomo-Munoz                                                                                                                                         |
| 338 |    964.759068 |    241.644054 | T. Michael Keesey                                                                                                                                             |
| 339 |    184.358244 |     56.027907 | Shyamal                                                                                                                                                       |
| 340 |    207.865957 |    189.518921 | Zimices                                                                                                                                                       |
| 341 |    895.253332 |    118.556023 | Milton Tan                                                                                                                                                    |
| 342 |    758.250520 |    744.736494 | Matt Crook                                                                                                                                                    |
| 343 |    665.954805 |    123.484959 | Zimices                                                                                                                                                       |
| 344 |    762.103169 |    531.276242 | Jakovche                                                                                                                                                      |
| 345 |    439.890213 |    699.386005 | Christopher Watson (photo) and T. Michael Keesey (vectorization)                                                                                              |
| 346 |    672.348951 |    562.280144 | Steven Traver                                                                                                                                                 |
| 347 |    188.509162 |    621.725185 | Gareth Monger                                                                                                                                                 |
| 348 |    804.515232 |    348.876558 | Danielle Alba                                                                                                                                                 |
| 349 |    925.188477 |    374.045831 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                |
| 350 |    207.698502 |    345.043500 | Matt Crook                                                                                                                                                    |
| 351 |    746.522852 |    246.265658 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                               |
| 352 |     11.192245 |    516.704671 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                             |
| 353 |    794.344293 |    395.133667 | Pranav Iyer (grey ideas)                                                                                                                                      |
| 354 |    187.368811 |      8.619242 | Rachel Shoop                                                                                                                                                  |
| 355 |    491.340331 |    282.826317 | Kenneth Lacovara (vectorized by T. Michael Keesey)                                                                                                            |
| 356 |    262.614870 |    306.117261 | Thibaut Brunet                                                                                                                                                |
| 357 |    920.381780 |    142.963079 | Tarique Sani (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey  |
| 358 |    455.685435 |    140.482437 | Dean Schnabel                                                                                                                                                 |
| 359 |    741.330885 |    169.816185 | Jose Carlos Arenas-Monroy                                                                                                                                     |
| 360 |     59.447241 |    604.750979 | Yan Wong from illustration by Jules Richard (1907)                                                                                                            |
| 361 |    658.045987 |    144.814087 | Michele M Tobias                                                                                                                                              |
| 362 |    307.902653 |     83.760673 | L. Shyamal                                                                                                                                                    |
| 363 |    402.015864 |    564.331733 | Matt Crook                                                                                                                                                    |
| 364 |    455.252303 |    184.150562 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                 |
| 365 |    438.508552 |    312.943241 | Steven Traver                                                                                                                                                 |
| 366 |   1008.739519 |    685.068391 | Margot Michaud                                                                                                                                                |
| 367 |    251.478791 |    294.660936 | C. Camilo Julián-Caballero                                                                                                                                    |
| 368 |    344.121179 |    512.121877 | Courtney Rockenbach                                                                                                                                           |
| 369 |    765.033757 |     57.923622 | NA                                                                                                                                                            |
| 370 |    291.288198 |    285.335318 | Matt Crook                                                                                                                                                    |
| 371 |    965.995369 |     10.903568 | Gareth Monger                                                                                                                                                 |
| 372 |    481.389925 |    292.826743 | Mathilde Cordellier                                                                                                                                           |
| 373 |    781.557471 |    401.040723 | Joris van der Ham (vectorized by T. Michael Keesey)                                                                                                           |
| 374 |    807.947096 |     79.632050 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                 |
| 375 |    177.049304 |    188.815889 | Emily Willoughby                                                                                                                                              |
| 376 |    521.994444 |    781.696321 | Kai R. Caspar                                                                                                                                                 |
| 377 |    687.979623 |    273.258411 | Scott Hartman                                                                                                                                                 |
| 378 |     66.642978 |    613.183657 | Ferran Sayol                                                                                                                                                  |
| 379 |    141.923950 |    732.568392 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                 |
| 380 |    699.336894 |    429.554479 | Matt Crook                                                                                                                                                    |
| 381 |    336.852107 |    708.563940 | Margot Michaud                                                                                                                                                |
| 382 |    768.638091 |    150.550757 | Chris huh                                                                                                                                                     |
| 383 |    977.709238 |    437.123449 | Birgit Lang                                                                                                                                                   |
| 384 |    794.203074 |    368.848106 | Pete Buchholz                                                                                                                                                 |
| 385 |    497.539489 |    653.073449 | T. Michael Keesey                                                                                                                                             |
| 386 |   1012.916199 |    133.058815 | Francis de Laporte de Castelnau (vectorized by T. Michael Keesey)                                                                                             |
| 387 |    296.259891 |    747.965445 | Shyamal                                                                                                                                                       |
| 388 |    480.240959 |    479.410335 | B Kimmel                                                                                                                                                      |
| 389 |    770.082858 |    255.813075 | Margot Michaud                                                                                                                                                |
| 390 |    682.676186 |    733.501035 | Juan Carlos Jerí                                                                                                                                              |
| 391 |    496.272190 |    726.748234 | Michele M Tobias                                                                                                                                              |
| 392 |    826.091963 |    193.717133 | Zimices                                                                                                                                                       |
| 393 |    392.483034 |    426.888952 | Zimices                                                                                                                                                       |
| 394 |    910.728003 |    541.393252 | Caleb M. Brown                                                                                                                                                |
| 395 |    652.990900 |    121.528971 | Melissa Broussard                                                                                                                                             |
| 396 |    763.929175 |    380.867985 | Jose Carlos Arenas-Monroy                                                                                                                                     |
| 397 |    288.459602 |      7.680072 | CNZdenek                                                                                                                                                      |
| 398 |    912.084847 |     14.489224 | Gareth Monger                                                                                                                                                 |
| 399 |     13.820396 |    564.876689 | Birgit Lang                                                                                                                                                   |
| 400 |    375.681822 |    795.123529 | Gabriela Palomo-Munoz                                                                                                                                         |
| 401 |    488.992711 |     91.153575 | Felix Vaux                                                                                                                                                    |
| 402 |    342.070897 |    297.670165 | B. Duygu Özpolat                                                                                                                                              |
| 403 |    646.601680 |    312.659807 | Anthony Caravaggi                                                                                                                                             |
| 404 |    551.632140 |    705.200955 | Zimices                                                                                                                                                       |
| 405 |    330.583978 |    197.841248 | NA                                                                                                                                                            |
| 406 |     51.307566 |     58.412113 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                          |
| 407 |    542.846900 |    463.519280 | Zimices                                                                                                                                                       |
| 408 |    860.455784 |    517.247237 | Zimices                                                                                                                                                       |
| 409 |    693.886404 |    721.805297 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                 |
| 410 |    261.153642 |     51.383811 | Eduard Solà Vázquez, vectorised by Yan Wong                                                                                                                   |
| 411 |    825.965356 |    420.388052 | Tracy A. Heath                                                                                                                                                |
| 412 |    347.508635 |    563.647919 | Yan Wong                                                                                                                                                      |
| 413 |    480.009602 |     30.518871 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                             |
| 414 |    955.369418 |     39.350729 | Meyers Konversations-Lexikon 1897 (vectorized: Yan Wong)                                                                                                      |
| 415 |    985.389910 |    721.009677 | Gareth Monger                                                                                                                                                 |
| 416 |    125.468394 |    723.058938 | Noah Schlottman, photo by Gustav Paulay for Moorea Biocode                                                                                                    |
| 417 |    389.317482 |    361.061509 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                 |
| 418 |    439.443508 |    730.124142 | Matt Crook                                                                                                                                                    |
| 419 |    620.583668 |    790.528917 | Kamil S. Jaron                                                                                                                                                |
| 420 |    663.072137 |    753.931386 | Emily Willoughby                                                                                                                                              |
| 421 |      8.152147 |    646.972939 | Trond R. Oskars                                                                                                                                               |
| 422 |    646.433684 |    785.476161 | Matthew E. Clapham                                                                                                                                            |
| 423 |    150.487586 |     11.602811 | Todd Marshall, vectorized by Zimices                                                                                                                          |
| 424 |   1000.935076 |    598.733005 | Matt Crook                                                                                                                                                    |
| 425 |     25.493989 |    601.972979 | Matt Crook                                                                                                                                                    |
| 426 |    966.083260 |    467.930237 | Melissa Broussard                                                                                                                                             |
| 427 |    514.208278 |    665.095999 | Margot Michaud                                                                                                                                                |
| 428 |    684.747931 |    287.414175 | Margot Michaud                                                                                                                                                |
| 429 |    334.989899 |    307.155206 | DW Bapst (modified from Bulman, 1970)                                                                                                                         |
| 430 |   1013.087985 |    427.190311 | Tracy A. Heath                                                                                                                                                |
| 431 |    249.508730 |     60.197566 | Qiang Ou                                                                                                                                                      |
| 432 |    437.353481 |    129.694879 | Scott Hartman                                                                                                                                                 |
| 433 |    138.046868 |    793.752717 | Zimices                                                                                                                                                       |
| 434 |    273.455363 |     38.149692 | Anthony Caravaggi                                                                                                                                             |
| 435 |    359.961796 |    268.491482 | Steven Traver                                                                                                                                                 |
| 436 |    501.374700 |     64.007932 | Chris huh                                                                                                                                                     |
| 437 |    705.767401 |    705.380375 | Zimices                                                                                                                                                       |
| 438 |    913.488028 |    524.840754 | Matt Crook                                                                                                                                                    |
| 439 |    665.194804 |      9.183378 | Sergio A. Muñoz-Gómez                                                                                                                                         |
| 440 |    654.115295 |     11.665271 | Maija Karala                                                                                                                                                  |
| 441 |    985.654899 |    713.556259 | John Curtis (vectorized by T. Michael Keesey)                                                                                                                 |
| 442 |    312.067759 |    231.428092 | Scott Hartman                                                                                                                                                 |
| 443 |    639.883019 |    440.183258 | Tauana J. Cunha                                                                                                                                               |
| 444 |     14.551689 |    294.287110 | Beth Reinke                                                                                                                                                   |
| 445 |    464.177169 |     10.787700 | Steven Coombs                                                                                                                                                 |
| 446 |    464.145321 |     27.692016 | Gareth Monger                                                                                                                                                 |
| 447 |    540.004206 |    647.698079 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                             |
| 448 |     46.443808 |     86.166213 | Steven Traver                                                                                                                                                 |
| 449 |    481.320664 |    553.291564 | Sarah Werning                                                                                                                                                 |
| 450 |    857.820631 |    194.656326 | Jagged Fang Designs                                                                                                                                           |
| 451 |    829.366521 |    201.146301 | Scott Hartman                                                                                                                                                 |
| 452 |    279.299319 |    604.212076 | Mali’o Kodis, photograph by Cordell Expeditions at Cal Academy                                                                                                |
| 453 |    588.299439 |    721.916745 | Sergio A. Muñoz-Gómez                                                                                                                                         |
| 454 |    342.309320 |    650.530999 | T. Michael Keesey (after Colin M. L. Burnett)                                                                                                                 |
| 455 |    673.112039 |     59.151420 | Zimices                                                                                                                                                       |
| 456 |    441.513439 |    332.868270 | Steven Traver                                                                                                                                                 |
| 457 |     41.000224 |    631.856420 | Warren H (photography), T. Michael Keesey (vectorization)                                                                                                     |
| 458 |    561.874630 |    239.143306 | Darius Nau                                                                                                                                                    |
| 459 |      8.422957 |     93.054454 | Dmitry Bogdanov                                                                                                                                               |
| 460 |    528.906861 |    736.680104 | FunkMonk                                                                                                                                                      |
| 461 |    354.985719 |    556.114237 | Kent Elson Sorgon                                                                                                                                             |
| 462 |    763.858138 |    760.465235 | NA                                                                                                                                                            |
| 463 |    645.164546 |    201.426934 | Sharon Wegner-Larsen                                                                                                                                          |
| 464 |    819.037602 |    447.807176 | Eric Moody                                                                                                                                                    |
| 465 |    893.256361 |    660.849491 | Maija Karala                                                                                                                                                  |
| 466 |    539.694469 |    264.396121 | Mason McNair                                                                                                                                                  |
| 467 |    703.464610 |    172.798711 | Matt Crook                                                                                                                                                    |
| 468 |    721.019133 |     40.982602 | T. Michael Keesey                                                                                                                                             |
| 469 |    641.663704 |    258.561451 | Emily Willoughby                                                                                                                                              |
| 470 |    173.921753 |    283.099825 | xgirouxb                                                                                                                                                      |
| 471 |     85.434730 |    559.674157 | Christine Axon                                                                                                                                                |
| 472 |    789.541691 |    249.484488 | Ferran Sayol                                                                                                                                                  |
| 473 |    978.376901 |    573.813252 | Matus Valach                                                                                                                                                  |
| 474 |     26.492528 |    502.886362 | Michelle Site                                                                                                                                                 |
| 475 |    678.548490 |    184.891079 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                             |
| 476 |    989.104635 |    553.467575 | Gareth Monger                                                                                                                                                 |
| 477 |    434.451461 |    135.071862 | Rene Martin                                                                                                                                                   |
| 478 |     24.343287 |     98.580388 | Gareth Monger                                                                                                                                                 |
| 479 |    210.789277 |    596.888015 | Ingo Braasch                                                                                                                                                  |
| 480 |    677.412041 |    100.403406 | Mattia Menchetti                                                                                                                                              |
| 481 |    937.291360 |     90.656733 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                 |
| 482 |    615.770749 |    510.490017 | Gabriela Palomo-Munoz                                                                                                                                         |
| 483 |    509.116796 |    645.362215 | Margot Michaud                                                                                                                                                |
| 484 |    378.232843 |    410.315539 | Becky Barnes                                                                                                                                                  |
| 485 |    911.291614 |    104.619126 | Gareth Monger                                                                                                                                                 |
| 486 |    532.057199 |    502.289827 | Matt Martyniuk                                                                                                                                                |
| 487 |    944.075475 |    141.256937 | Gareth Monger                                                                                                                                                 |
| 488 |    187.819213 |    779.559329 | Nobu Tamura                                                                                                                                                   |
| 489 |    661.249162 |    313.994328 | Courtney Rockenbach                                                                                                                                           |
| 490 |    778.109311 |    341.767894 | Yan Wong from wikipedia drawing (PD: Pearson Scott Foresman)                                                                                                  |
| 491 |    409.868111 |    584.296150 | NA                                                                                                                                                            |
| 492 |    678.342343 |    160.674772 | Liftarn                                                                                                                                                       |
| 493 |    367.532927 |    439.841092 | Scott Hartman                                                                                                                                                 |
| 494 |    758.436673 |    637.685084 | Zimices                                                                                                                                                       |
| 495 |    303.122358 |    716.933646 | Jaime Headden                                                                                                                                                 |
| 496 |    983.428015 |    326.540215 | Mali’o Kodis, image from the Biodiversity Heritage Library                                                                                                    |
| 497 |    152.589148 |    474.315876 | NA                                                                                                                                                            |
| 498 |     90.225362 |    568.974221 | Margot Michaud                                                                                                                                                |
| 499 |    811.576207 |    390.309654 | NA                                                                                                                                                            |
| 500 |    386.066693 |    327.432847 | Jagged Fang Designs                                                                                                                                           |
| 501 |    889.505468 |    209.748190 | Marcos Pérez-Losada, Jens T. Høeg & Keith A. Crandall                                                                                                         |
| 502 |    261.253101 |    626.630649 | Martin R. Smith                                                                                                                                               |
| 503 |    122.535951 |    625.375188 | Taro Maeda                                                                                                                                                    |
| 504 |    220.205761 |     37.051055 | \[unknown\]                                                                                                                                                   |
| 505 |    307.345037 |    292.356963 | Tony Ayling                                                                                                                                                   |
| 506 |    887.778203 |     67.354720 | Kamil S. Jaron                                                                                                                                                |
| 507 |    775.358563 |    239.614812 | Kimberly Haddrell                                                                                                                                             |
| 508 |    711.394000 |    664.865040 | Matt Dempsey                                                                                                                                                  |
| 509 |    602.103791 |    640.396968 | Gareth Monger                                                                                                                                                 |
| 510 |    552.058614 |    230.113418 | Maky (vectorization), Gabriella Skollar (photography), Rebecca Lewis (editing)                                                                                |
| 511 |    753.851096 |    233.911494 | Ferran Sayol                                                                                                                                                  |
| 512 |    745.579666 |     90.300346 | Zimices                                                                                                                                                       |
| 513 |    921.650967 |     51.745906 | Don Armstrong                                                                                                                                                 |
| 514 |      8.079632 |    698.531871 | Keith Murdock (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
| 515 |    781.788183 |    309.152340 | T. Michael Keesey (after James & al.)                                                                                                                         |
| 516 |   1013.645912 |    485.935646 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                 |
| 517 |     36.900507 |    534.020198 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                              |
| 518 |    197.503035 |      8.281572 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                             |
| 519 |    825.205964 |    244.934821 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                      |
| 520 |   1012.883259 |    727.453934 | terngirl                                                                                                                                                      |
| 521 |    409.764387 |    767.812232 | Margot Michaud                                                                                                                                                |
| 522 |    852.171468 |    552.470435 | Rene Martin                                                                                                                                                   |
| 523 |    763.101079 |    709.618097 | Tasman Dixon                                                                                                                                                  |
| 524 |    842.019216 |    451.348986 | Steven Traver                                                                                                                                                 |
| 525 |    875.639534 |    533.805941 | Mali’o Kodis, image from Brockhaus and Efron Encyclopedic Dictionary                                                                                          |
| 526 |    509.181136 |     52.058396 | Matt Crook                                                                                                                                                    |
| 527 |    621.899836 |    206.978134 | Gareth Monger                                                                                                                                                 |
| 528 |    476.138917 |    495.926877 | Kamil S. Jaron                                                                                                                                                |
| 529 |    553.537896 |    105.066132 | Matt Crook                                                                                                                                                    |
| 530 |    485.400642 |    308.343159 | Dmitry Bogdanov                                                                                                                                               |
| 531 |    955.445565 |    340.926711 | Zimices                                                                                                                                                       |
| 532 |     65.788858 |    665.503645 | Matt Crook                                                                                                                                                    |
| 533 |    799.772347 |    467.935011 | Tasman Dixon                                                                                                                                                  |
| 534 |    698.135460 |    530.339315 | DW Bapst, modified from Figure 1 of Belanger (2011, PALAIOS).                                                                                                 |
| 535 |    292.724501 |    608.892861 | Alex Slavenko                                                                                                                                                 |
| 536 |    921.089156 |    381.385505 | NA                                                                                                                                                            |
| 537 |     27.791593 |    688.357724 | Joanna Wolfe                                                                                                                                                  |
| 538 |    243.951940 |    797.104362 | Chris huh                                                                                                                                                     |
| 539 |    149.518334 |    585.781139 | Pete Buchholz                                                                                                                                                 |
| 540 |    411.437069 |    596.766231 | Filip em                                                                                                                                                      |
| 541 |   1016.490698 |    746.899652 | Mo Hassan                                                                                                                                                     |
| 542 |    397.575533 |    336.744434 | Gareth Monger                                                                                                                                                 |
| 543 |    180.436552 |    479.885926 | NA                                                                                                                                                            |
| 544 |    221.344360 |    301.099283 | Zimices                                                                                                                                                       |
| 545 |    461.463645 |    720.268542 | Steve Hillebrand/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                            |
| 546 |    704.305482 |    734.610343 | Tasman Dixon                                                                                                                                                  |
| 547 |    233.716989 |    556.105326 | NA                                                                                                                                                            |
| 548 |    790.163050 |    428.423252 | Matt Crook                                                                                                                                                    |
| 549 |    482.369200 |    257.540999 | T. Michael Keesey                                                                                                                                             |
| 550 |    381.545004 |    382.287121 | Chris huh                                                                                                                                                     |
| 551 |    255.097518 |    674.576605 | Juan Carlos Jerí                                                                                                                                              |
| 552 |    491.896014 |    178.656579 | Tracy A. Heath                                                                                                                                                |
| 553 |    993.949754 |    587.914948 | Gabriela Palomo-Munoz                                                                                                                                         |
| 554 |     11.068235 |    152.066656 | T. Michael Keesey                                                                                                                                             |
| 555 |    480.908514 |    507.801152 | Florian Pfaff                                                                                                                                                 |
| 556 |     80.856936 |    503.944590 | Margot Michaud                                                                                                                                                |
| 557 |    550.868498 |    152.207375 | Sarah Werning                                                                                                                                                 |
| 558 |    862.712977 |    498.435638 | Beth Reinke                                                                                                                                                   |
| 559 |    885.936769 |    552.346979 | M Kolmann                                                                                                                                                     |
| 560 |    948.054221 |    393.831208 | Ray Simpson (vectorized by T. Michael Keesey)                                                                                                                 |
| 561 |   1003.904349 |    161.284722 | Michael P. Taylor                                                                                                                                             |
| 562 |    325.557440 |    209.784676 | Ingo Braasch                                                                                                                                                  |
| 563 |    928.919449 |    716.631463 | V. Deepak                                                                                                                                                     |
| 564 |    403.598502 |    252.786803 | Chris huh                                                                                                                                                     |
| 565 |   1015.318109 |    151.357576 | Christoph Schomburg                                                                                                                                           |
| 566 |    165.731944 |    271.640643 | Matt Crook                                                                                                                                                    |
| 567 |    940.915341 |    228.339541 | T. Michael Keesey                                                                                                                                             |
| 568 |    717.418758 |    728.406034 | NA                                                                                                                                                            |
| 569 |    320.593776 |    481.730767 | Gareth Monger                                                                                                                                                 |
| 570 |    515.717429 |    556.095683 | Kamil S. Jaron                                                                                                                                                |
| 571 |    315.029946 |    577.864196 | Beth Reinke                                                                                                                                                   |
| 572 |    719.586995 |    444.948853 | C. Camilo Julián-Caballero                                                                                                                                    |
| 573 |    227.165156 |    599.054534 | Mattia Menchetti                                                                                                                                              |
| 574 |    191.564602 |    457.724372 | Scott Hartman (vectorized by T. Michael Keesey)                                                                                                               |
| 575 |    559.778868 |    486.239228 | Gareth Monger                                                                                                                                                 |
| 576 |    300.486864 |    776.087033 | Margot Michaud                                                                                                                                                |
| 577 |    420.944658 |    488.134523 | Noah Schlottman, photo by Adam G. Clause                                                                                                                      |
| 578 |    815.482494 |     10.982510 | Margot Michaud                                                                                                                                                |
| 579 |    684.054205 |     70.585574 | Paul O. Lewis                                                                                                                                                 |
| 580 |    347.927417 |    452.025268 | Ingo Braasch                                                                                                                                                  |
| 581 |    264.567418 |    193.247195 | Matt Crook                                                                                                                                                    |
| 582 |    993.664583 |    142.493004 | Dean Schnabel                                                                                                                                                 |
| 583 |    959.955793 |    716.162884 | Gareth Monger                                                                                                                                                 |
| 584 |    279.566010 |    310.117384 | Christoph Schomburg                                                                                                                                           |
| 585 |    646.054612 |    468.150034 | NA                                                                                                                                                            |
| 586 |    109.517802 |     64.336381 | Francisco Manuel Blanco (vectorized by T. Michael Keesey)                                                                                                     |
| 587 |   1015.007148 |    636.623435 | Roderic Page and Lois Page                                                                                                                                    |
| 588 |    559.128261 |    730.544044 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                 |
| 589 |    549.661769 |    448.808908 | Matt Crook                                                                                                                                                    |
| 590 |    759.375431 |    676.580203 | Martin Kevil                                                                                                                                                  |
| 591 |    729.315972 |    693.126820 | Scott Hartman                                                                                                                                                 |
| 592 |    300.245853 |    732.191532 | Cristopher Silva                                                                                                                                              |
| 593 |    536.703898 |      8.510059 | L. Shyamal                                                                                                                                                    |
| 594 |    601.238829 |    772.598148 | Zimices                                                                                                                                                       |
| 595 |   1000.531979 |    775.103186 | Qiang Ou                                                                                                                                                      |
| 596 |    635.895368 |    612.665795 | T. Michael Keesey                                                                                                                                             |
| 597 |    906.038746 |     27.644638 | Zimices                                                                                                                                                       |
| 598 |    202.584394 |    284.722067 | Matt Crook                                                                                                                                                    |
| 599 |    556.721652 |    279.420759 | Yan Wong from drawing in The Century Dictionary (1911)                                                                                                        |
| 600 |     10.299181 |    783.339234 | Ryan Cupo                                                                                                                                                     |
| 601 |    624.993042 |    773.654701 | Sean McCann                                                                                                                                                   |
| 602 |    748.898295 |    684.734327 | Tracy A. Heath                                                                                                                                                |
| 603 |    966.958773 |    419.433936 | Zimices                                                                                                                                                       |
| 604 |    800.156902 |     60.274160 | Margot Michaud                                                                                                                                                |
| 605 |    390.094458 |    654.808283 | Scott Hartman                                                                                                                                                 |
| 606 |    350.573425 |    143.645314 | Zimices                                                                                                                                                       |
| 607 |    132.961094 |    782.327094 | Gareth Monger                                                                                                                                                 |
| 608 |    773.678350 |    521.808294 | Iain Reid                                                                                                                                                     |
| 609 |    671.060524 |    324.258177 | T. Michael Keesey                                                                                                                                             |
| 610 |   1000.960295 |    314.572824 | Gareth Monger                                                                                                                                                 |
| 611 |    806.850120 |     55.130468 | Gareth Monger                                                                                                                                                 |
| 612 |    380.860428 |    755.886514 | Zimices                                                                                                                                                       |
| 613 |    281.176029 |    507.970902 | Matt Crook                                                                                                                                                    |
| 614 |    787.114258 |     99.582683 | Juan Carlos Jerí                                                                                                                                              |
| 615 |    782.028825 |    387.029920 | Tasman Dixon                                                                                                                                                  |
| 616 |    680.491014 |    791.656961 | Henry Lydecker                                                                                                                                                |
| 617 |    826.609089 |    165.688710 | Matt Crook                                                                                                                                                    |
| 618 |      6.885565 |    274.385362 | B. Duygu Özpolat                                                                                                                                              |
| 619 |    336.923428 |    163.974997 | Zimices                                                                                                                                                       |
| 620 |     97.611738 |    670.290791 | Chris huh                                                                                                                                                     |
| 621 |    986.832924 |      6.755254 | T. Michael Keesey                                                                                                                                             |
| 622 |    370.928664 |    452.982696 | Matt Crook                                                                                                                                                    |
| 623 |    351.074437 |    466.827743 | Scott Hartman                                                                                                                                                 |
| 624 |    289.802365 |    152.495675 | Ferran Sayol                                                                                                                                                  |
| 625 |    632.376675 |    178.622913 | Scott Hartman                                                                                                                                                 |
| 626 |    201.257748 |    104.669935 | Dean Schnabel                                                                                                                                                 |
| 627 |    599.926646 |    173.343490 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                              |
| 628 |    730.932252 |    741.341119 | T. Michael Keesey                                                                                                                                             |
| 629 |    136.205677 |    682.322423 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                             |
| 630 |    627.078909 |    543.767941 | Matt Crook                                                                                                                                                    |
| 631 |     32.103029 |    581.660422 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                             |
| 632 |    154.260895 |    342.813286 | Noah Schlottman, photo by Carol Cummings                                                                                                                      |
| 633 |     73.596046 |    488.601233 | Richard Parker (vectorized by T. Michael Keesey)                                                                                                              |
| 634 |   1012.385464 |    332.270200 | Zimices                                                                                                                                                       |
| 635 |    357.551465 |    644.418190 | Tracy A. Heath                                                                                                                                                |
| 636 |   1007.548771 |    504.279337 | T. Michael Keesey                                                                                                                                             |
| 637 |     82.376125 |    516.881999 | Steven Traver                                                                                                                                                 |
| 638 |    547.126402 |    296.526112 | Jaime Headden                                                                                                                                                 |
| 639 |    481.627161 |    655.559645 | Katie S. Collins                                                                                                                                              |
| 640 |    302.565840 |    791.686406 | Matt Crook                                                                                                                                                    |
| 641 |    373.469896 |    553.733181 | Steven Traver                                                                                                                                                 |
| 642 |     14.128190 |    523.591713 | Tracy A. Heath                                                                                                                                                |
| 643 |    419.426682 |    713.194017 | Patrick Fisher (vectorized by T. Michael Keesey)                                                                                                              |
| 644 |    916.878915 |    221.655269 | Chris huh                                                                                                                                                     |
| 645 |    469.248468 |    782.133987 | Gareth Monger                                                                                                                                                 |
| 646 |    726.212655 |    472.133563 | NA                                                                                                                                                            |
| 647 |   1015.632979 |    357.634767 | Zimices                                                                                                                                                       |
| 648 |    747.669387 |    535.193800 | Matt Crook                                                                                                                                                    |
| 649 |    466.697018 |    151.237888 | Crystal Maier                                                                                                                                                 |
| 650 |    351.449468 |    675.820284 | Michelle Site                                                                                                                                                 |
| 651 |    502.730009 |    571.077240 | FunkMonk                                                                                                                                                      |
| 652 |    831.264908 |    269.458255 | NA                                                                                                                                                            |
| 653 |    568.780915 |    590.085515 | Ferran Sayol                                                                                                                                                  |
| 654 |     46.854747 |    568.414890 | Roberto Díaz Sibaja                                                                                                                                           |
| 655 |    973.906638 |    585.334489 | Dean Schnabel                                                                                                                                                 |
| 656 |    364.064893 |    228.137329 | Scott Hartman                                                                                                                                                 |
| 657 |    395.751010 |    779.369858 | Zimices                                                                                                                                                       |
| 658 |    301.180776 |    599.218006 | Steven Traver                                                                                                                                                 |
| 659 |    935.959668 |    585.878161 | Matt Crook                                                                                                                                                    |
| 660 |    797.961997 |    362.119819 | Jack Mayer Wood                                                                                                                                               |
| 661 |    447.783662 |    119.443224 | NA                                                                                                                                                            |
| 662 |    519.032842 |     96.053099 | Scott Reid                                                                                                                                                    |
| 663 |     59.490594 |    585.771851 | Beth Reinke                                                                                                                                                   |
| 664 |    643.588568 |    539.022923 | Gareth Monger                                                                                                                                                 |
| 665 |    256.569817 |      4.105085 | Felix Vaux                                                                                                                                                    |
| 666 |    992.934418 |    238.909800 | Margot Michaud                                                                                                                                                |
| 667 |    787.861052 |    499.563438 | Matt Crook                                                                                                                                                    |
| 668 |    656.219239 |    327.888725 | Christoph Schomburg                                                                                                                                           |
| 669 |    309.144034 |    347.097683 | Joanna Wolfe                                                                                                                                                  |
| 670 |    794.905174 |    735.074447 | Michelle Site                                                                                                                                                 |
| 671 |    268.065976 |    173.259414 | NA                                                                                                                                                            |
| 672 |    316.085694 |    756.366569 | C. Camilo Julián-Caballero                                                                                                                                    |
| 673 |    284.375838 |     27.225839 | Michelle Site                                                                                                                                                 |
| 674 |    507.248794 |     42.007210 | Margot Michaud                                                                                                                                                |
| 675 |    843.716384 |     78.034479 | Maija Karala                                                                                                                                                  |
| 676 |    135.160830 |     48.630199 | Chris huh                                                                                                                                                     |
| 677 |    248.718178 |     22.698679 | Jaime Headden (vectorized by T. Michael Keesey)                                                                                                               |
| 678 |    785.144961 |    710.739277 | Gareth Monger                                                                                                                                                 |
| 679 |    953.780332 |    389.049891 | Birgit Lang                                                                                                                                                   |
| 680 |    364.392148 |    518.268585 | Lukasiniho                                                                                                                                                    |
| 681 |    788.692947 |    351.930909 | Dean Schnabel                                                                                                                                                 |
| 682 |    306.159579 |    740.849150 | Tauana J. Cunha                                                                                                                                               |
| 683 |    810.997320 |    229.742120 | Mali’o Kodis, image from Brockhaus and Efron Encyclopedic Dictionary                                                                                          |
| 684 |    401.124137 |     34.316429 | Jagged Fang Designs                                                                                                                                           |
| 685 |    368.775176 |    319.001959 | Jose Carlos Arenas-Monroy                                                                                                                                     |
| 686 |    612.909127 |    704.656346 | Lauren Anderson                                                                                                                                               |
| 687 |    797.523688 |    603.339167 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                 |
| 688 |    844.388419 |    103.034529 | NA                                                                                                                                                            |
| 689 |    162.644086 |    167.491465 | Birgit Lang                                                                                                                                                   |
| 690 |    492.827827 |    290.411233 | Jiekun He                                                                                                                                                     |
| 691 |    835.090589 |     85.224915 | Jaime Headden                                                                                                                                                 |
| 692 |    740.192293 |    104.724965 | Smokeybjb                                                                                                                                                     |
| 693 |    935.264988 |    522.362059 | Mathew Wedel                                                                                                                                                  |
| 694 |    242.607154 |     43.375070 | C. Camilo Julián-Caballero                                                                                                                                    |
| 695 |    302.734334 |    213.038156 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                           |
| 696 |    197.169349 |    571.885438 | Steven Traver                                                                                                                                                 |
| 697 |     51.528429 |    612.317188 | Scott Hartman                                                                                                                                                 |
| 698 |    465.822683 |    528.868851 | Roberto Díaz Sibaja                                                                                                                                           |
| 699 |    940.227135 |    379.865477 | Kai R. Caspar                                                                                                                                                 |
| 700 |      8.334403 |     48.996881 | Chase Brownstein                                                                                                                                              |
| 701 |    632.548692 |    187.775703 | Katie S. Collins                                                                                                                                              |
| 702 |    914.111154 |    154.777986 | Zimices                                                                                                                                                       |
| 703 |    960.897767 |    257.201674 | Jaime Headden, modified by T. Michael Keesey                                                                                                                  |
| 704 |   1002.060252 |    655.581760 | Steven Traver                                                                                                                                                 |
| 705 |    241.206874 |    627.250735 | Scott Hartman                                                                                                                                                 |
| 706 |    261.803873 |     12.347241 | Steven Traver                                                                                                                                                 |
| 707 |    884.209010 |    539.696337 | Matt Crook                                                                                                                                                    |
| 708 |    513.783102 |    306.048531 | Kailah Thorn & Mark Hutchinson                                                                                                                                |
| 709 |    998.823610 |    183.086961 | Beth Reinke                                                                                                                                                   |
| 710 |    340.511575 |     37.542676 | Sarah Werning                                                                                                                                                 |
| 711 |    940.348289 |    131.131145 | Archaeodontosaurus (vectorized by T. Michael Keesey)                                                                                                          |
| 712 |    360.898572 |    366.344067 | Zimices                                                                                                                                                       |
| 713 |    959.976525 |    368.342496 | Cagri Cevrim                                                                                                                                                  |
| 714 |    671.477876 |     88.988395 | Lukasiniho                                                                                                                                                    |
| 715 |    796.489430 |    224.687718 | Margot Michaud                                                                                                                                                |
| 716 |    932.301941 |    469.013736 | Tracy A. Heath                                                                                                                                                |
| 717 |    325.705030 |     35.205903 | Matt Crook                                                                                                                                                    |
| 718 |    556.340187 |    557.609213 | Noah Schlottman, photo from National Science Foundation - Turbellarian Taxonomic Database                                                                     |
| 719 |    304.735371 |    199.020177 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                            |
| 720 |    871.831361 |    315.986509 | Emma Hughes                                                                                                                                                   |
| 721 |   1000.830677 |    537.269666 | NA                                                                                                                                                            |
| 722 |    607.833198 |    495.925790 | Kanako Bessho-Uehara                                                                                                                                          |
| 723 |   1014.058159 |      3.094354 | Nobu Tamura                                                                                                                                                   |
| 724 |    947.212753 |     30.144200 | Jonathan Wells                                                                                                                                                |
| 725 |     19.633904 |    161.924357 | Fernando Carezzano                                                                                                                                            |
| 726 |    193.665117 |    789.951808 | Nicholas J. Czaplewski, vectorized by Zimices                                                                                                                 |
| 727 |    908.752701 |     42.347230 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                             |
| 728 |    337.623018 |    481.095187 | Carlos Cano-Barbacil                                                                                                                                          |
| 729 |    672.147937 |    470.793587 | Sean McCann                                                                                                                                                   |
| 730 |    277.745941 |     67.995185 | T. Michael Keesey                                                                                                                                             |
| 731 |    993.693150 |    335.478846 | Christoph Schomburg                                                                                                                                           |
| 732 |    517.785423 |    476.565868 | Matt Crook                                                                                                                                                    |
| 733 |    367.060964 |    333.119601 | Steven Coombs                                                                                                                                                 |
| 734 |    679.864018 |    305.647518 | Michael Scroggie                                                                                                                                              |
| 735 |     91.116175 |    619.067812 | Zimices                                                                                                                                                       |
| 736 |    397.983636 |    437.683341 | Jaime Headden                                                                                                                                                 |
| 737 |     13.446039 |    251.264146 | kotik                                                                                                                                                         |
| 738 |    799.224632 |    126.369585 | NA                                                                                                                                                            |
| 739 |    320.272843 |    698.633291 | Maija Karala                                                                                                                                                  |
| 740 |     17.694879 |    541.334309 | NA                                                                                                                                                            |
| 741 |    395.785312 |    553.188911 | NA                                                                                                                                                            |
| 742 |    522.251372 |    574.511099 | Meliponicultor Itaymbere                                                                                                                                      |
| 743 |    433.111970 |    782.625106 | Yan Wong from photo by Gyik Toma                                                                                                                              |
| 744 |      7.993205 |    438.857867 | FunkMonk                                                                                                                                                      |
| 745 |    200.824556 |     90.123963 | C. Camilo Julián-Caballero                                                                                                                                    |
| 746 |    190.446093 |     40.409870 | Zimices                                                                                                                                                       |
| 747 |    276.369603 |    588.721171 | Gareth Monger                                                                                                                                                 |
| 748 |    172.258001 |    150.050485 | Zimices                                                                                                                                                       |
| 749 |    984.194856 |    652.909597 | Konsta Happonen                                                                                                                                               |
| 750 |    744.625728 |      6.599805 | Jaime Headden                                                                                                                                                 |
| 751 |    123.338807 |    706.615908 | Javier Luque                                                                                                                                                  |
| 752 |    250.512424 |    482.316500 | Chris huh                                                                                                                                                     |
| 753 |    940.922140 |     38.876540 | Xavier Giroux-Bougard                                                                                                                                         |
| 754 |    703.353392 |    621.173607 | Gabriela Palomo-Munoz                                                                                                                                         |
| 755 |    918.525998 |    615.877016 | NA                                                                                                                                                            |
| 756 |    752.403611 |    611.443906 | Emily Willoughby                                                                                                                                              |
| 757 |    447.929498 |     97.117198 | Philippe Janvier (vectorized by T. Michael Keesey)                                                                                                            |
| 758 |    277.050310 |    100.674339 | Matt Crook                                                                                                                                                    |
| 759 |    861.146240 |     41.182715 | Steven Traver                                                                                                                                                 |
| 760 |    353.239880 |    545.486148 | Margot Michaud                                                                                                                                                |
| 761 |    704.335107 |    673.804061 | Steven Traver                                                                                                                                                 |
| 762 |    603.795801 |    322.411149 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                 |
| 763 |    813.921457 |    710.429197 | Maxime Dahirel                                                                                                                                                |
| 764 |   1010.929894 |    111.419604 | Sarah Werning                                                                                                                                                 |
| 765 |    874.444406 |     13.160052 | Lee Harding (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey   |
| 766 |    451.609136 |    310.575494 | Tasman Dixon                                                                                                                                                  |
| 767 |    401.003419 |    700.521722 | Margot Michaud                                                                                                                                                |
| 768 |    485.671099 |     77.624669 | Matt Crook                                                                                                                                                    |
| 769 |    769.002984 |    642.306827 | Mali’o Kodis, photograph by Hans Hillewaert                                                                                                                   |
| 770 |    759.304128 |    545.250611 | Smokeybjb                                                                                                                                                     |
| 771 |    689.787037 |    438.938478 | Beth Reinke                                                                                                                                                   |
| 772 |    425.567203 |    516.167814 | Catherine Yasuda                                                                                                                                              |
| 773 |    202.213343 |    724.152815 | Scott Hartman                                                                                                                                                 |
| 774 |    927.459492 |    226.114284 | François Michonneau                                                                                                                                           |
| 775 |    224.636142 |    185.735249 | Sibi (vectorized by T. Michael Keesey)                                                                                                                        |
| 776 |    807.611224 |    271.502779 | Ferran Sayol                                                                                                                                                  |
| 777 |    741.591893 |    325.115582 | T. Michael Keesey                                                                                                                                             |
| 778 |    602.023407 |     37.773857 | Katie S. Collins                                                                                                                                              |
| 779 |    114.650701 |    668.513681 | T. Michael Keesey                                                                                                                                             |
| 780 |    382.115100 |    371.163282 | Margot Michaud                                                                                                                                                |
| 781 |    430.756959 |    574.068544 | Josefine Bohr Brask                                                                                                                                           |
| 782 |    690.429065 |    522.567218 | T. Michael Keesey                                                                                                                                             |
| 783 |     31.733283 |     78.443470 | Philip Chalmers (vectorized by T. Michael Keesey)                                                                                                             |
| 784 |    420.653496 |    746.690525 | Sharon Wegner-Larsen                                                                                                                                          |
| 785 |    417.473144 |    699.436067 | FunkMonk                                                                                                                                                      |
| 786 |    468.450938 |    253.754589 | T. Michael Keesey                                                                                                                                             |
| 787 |    780.497355 |    797.081216 | Nobu Tamura, vectorized by Zimices                                                                                                                            |
| 788 |      7.461976 |    306.116916 | Zimices                                                                                                                                                       |
| 789 |   1015.240559 |    175.770245 | Jagged Fang Designs                                                                                                                                           |
| 790 |    459.294112 |    654.919817 | Campbell Fleming                                                                                                                                              |
| 791 |    463.459982 |    705.737185 | Noah Schlottman, photo by Casey Dunn                                                                                                                          |
| 792 |    132.174440 |    653.944195 | NA                                                                                                                                                            |
| 793 |    613.307621 |    605.258569 | Pollyanna von Knorring and T. Michael Keesey                                                                                                                  |
| 794 |    717.174074 |    355.906057 | Scott Hartman                                                                                                                                                 |
| 795 |    318.715782 |    671.744603 | Konsta Happonen, from a CC-BY-NC image by sokolkov2002 on iNaturalist                                                                                         |
| 796 |    923.313152 |    367.518707 | L. Shyamal                                                                                                                                                    |
| 797 |    964.868421 |    402.737968 | Andrew A. Farke                                                                                                                                               |
| 798 |      6.232874 |    195.507689 | Michelle Site                                                                                                                                                 |
| 799 |    796.205943 |     68.740306 | Gareth Monger                                                                                                                                                 |
| 800 |    949.262508 |    206.382894 | Mo Hassan                                                                                                                                                     |
| 801 |    699.505415 |    444.603598 | Jake Warner                                                                                                                                                   |
| 802 |    765.382633 |    594.783506 | Christoph Schomburg                                                                                                                                           |
| 803 |    253.587572 |    726.143890 | Tasman Dixon                                                                                                                                                  |
| 804 |    108.626358 |     15.188301 | Gareth Monger                                                                                                                                                 |
| 805 |    111.781355 |      4.031146 | Benchill                                                                                                                                                      |
| 806 |    699.974205 |     15.081450 | Matt Crook                                                                                                                                                    |
| 807 |     42.793805 |    548.359242 | Matt Crook                                                                                                                                                    |
| 808 |    333.525769 |    526.744444 | Matt Crook                                                                                                                                                    |
| 809 |    805.249748 |    332.196003 | Kamil S. Jaron                                                                                                                                                |
| 810 |    770.719473 |    658.565552 | Kailah Thorn & Ben King                                                                                                                                       |
| 811 |      9.337574 |      6.108736 | Dean Schnabel                                                                                                                                                 |
| 812 |    558.039066 |    509.901657 | Ferran Sayol                                                                                                                                                  |
| 813 |    901.930581 |    690.280479 | Robert Gay                                                                                                                                                    |
| 814 |    974.817010 |    306.544697 | Zimices                                                                                                                                                       |
| 815 |    597.930144 |    543.178009 | Mali’o Kodis, photograph by Cordell Expeditions at Cal Academy                                                                                                |
| 816 |    171.336283 |    377.670232 | NA                                                                                                                                                            |
| 817 |    749.099707 |    349.650820 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                           |
| 818 |    354.070359 |    631.735205 | Matt Crook                                                                                                                                                    |
| 819 |    399.690601 |    607.087497 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                 |
| 820 |    530.546862 |    202.676894 | Sergio A. Muñoz-Gómez                                                                                                                                         |
| 821 |    285.508509 |    707.983139 | Jiekun He                                                                                                                                                     |
| 822 |    515.917494 |     83.198455 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                               |
| 823 |    611.475006 |     11.823118 | Margot Michaud                                                                                                                                                |
| 824 |    127.489897 |      7.066166 | Matt Crook                                                                                                                                                    |
| 825 |    610.341304 |    590.696371 | Steven Traver                                                                                                                                                 |
| 826 |    810.366492 |    462.975564 | Jagged Fang Designs                                                                                                                                           |
| 827 |    661.619480 |    774.035113 | Dann Pigdon                                                                                                                                                   |
| 828 |    358.099941 |    704.311604 | Margot Michaud                                                                                                                                                |
| 829 |    200.800517 |    499.900861 | Mason McNair                                                                                                                                                  |
| 830 |   1007.081795 |    301.079157 | Margot Michaud                                                                                                                                                |
| 831 |    151.013390 |    265.322591 | Nicolas Huet le Jeune and Jean-Gabriel Prêtre (vectorized by T. Michael Keesey)                                                                               |
| 832 |    488.549623 |     40.019944 | Steven Coombs                                                                                                                                                 |
| 833 |    942.531798 |    212.895157 | Scott Hartman                                                                                                                                                 |
| 834 |    477.768366 |     67.060246 | Margot Michaud                                                                                                                                                |
| 835 |   1005.959907 |    208.380521 | Mathilde Cordellier                                                                                                                                           |
| 836 |     38.185701 |    789.926308 | Margot Michaud                                                                                                                                                |
| 837 |    871.987041 |    566.782680 | Armin Reindl                                                                                                                                                  |
| 838 |    132.406281 |    584.639110 | Steven Traver                                                                                                                                                 |
| 839 |    978.234423 |    454.701395 | Jagged Fang Designs                                                                                                                                           |
| 840 |    964.380840 |    319.065418 | Margot Michaud                                                                                                                                                |
| 841 |    331.250432 |    268.478801 | Matt Martyniuk (modified by T. Michael Keesey)                                                                                                                |
| 842 |    292.038393 |    226.558417 | Becky Barnes                                                                                                                                                  |
| 843 |    276.471668 |    620.275190 | Zimices                                                                                                                                                       |
| 844 |    542.085047 |    281.297423 | Jake Warner                                                                                                                                                   |
| 845 |    226.441190 |    741.722295 | Lani Mohan                                                                                                                                                    |
| 846 |    332.376042 |    464.369645 | Andrew A. Farke                                                                                                                                               |
| 847 |    614.696388 |    190.983832 | Nobu Tamura, vectorized by Zimices                                                                                                                            |
| 848 |    827.236246 |    348.622654 | Scott Hartman                                                                                                                                                 |
| 849 |    949.359120 |    251.761535 | NA                                                                                                                                                            |
| 850 |    895.948706 |    558.088496 | Zimices                                                                                                                                                       |
| 851 |     44.105493 |    594.279541 | Zimices                                                                                                                                                       |
| 852 |    641.448412 |    712.690136 | Leann Biancani, photo by Kenneth Clifton                                                                                                                      |
| 853 |    902.446527 |    604.802995 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                |
| 854 |    294.491134 |    196.327506 | Alyssa Bell & Luis Chiappe 2015, dx.doi.org/10.1371/journal.pone.0141690                                                                                      |
| 855 |    344.488462 |     86.601721 | NA                                                                                                                                                            |
| 856 |    121.192820 |    681.897704 | Collin Gross                                                                                                                                                  |
| 857 |    215.275099 |    557.182034 | T. Michael Keesey, from a photograph by Thea Boodhoo                                                                                                          |
| 858 |    863.913303 |    606.699371 | Matt Crook                                                                                                                                                    |
| 859 |    663.563096 |    420.364110 | Gareth Monger                                                                                                                                                 |
| 860 |    328.690096 |    224.207961 | Cristopher Silva                                                                                                                                              |
| 861 |    850.691613 |    582.186357 | Matt Crook                                                                                                                                                    |
| 862 |    396.869909 |    721.983360 | Manabu Sakamoto                                                                                                                                               |
| 863 |    706.939892 |    541.164934 | Gareth Monger                                                                                                                                                 |
| 864 |    780.809725 |    749.242446 | xgirouxb                                                                                                                                                      |
| 865 |    876.660104 |     34.562128 | mystica                                                                                                                                                       |
| 866 |    431.257042 |    476.922796 | JJ Harrison (vectorized by T. Michael Keesey)                                                                                                                 |
| 867 |     92.359704 |     74.436969 | Zimices                                                                                                                                                       |
| 868 |    563.147332 |    643.911209 | Notafly (vectorized by T. Michael Keesey)                                                                                                                     |
| 869 |    986.420143 |    451.799661 | Maija Karala                                                                                                                                                  |
| 870 |    949.779968 |    196.056200 | Matt Crook                                                                                                                                                    |
| 871 |    213.916114 |    146.269891 | Christine Axon                                                                                                                                                |
| 872 |    672.297794 |    263.988444 | Jaime Headden                                                                                                                                                 |
| 873 |    618.826309 |    627.427721 | T. Michael Keesey (photo by Darren Swim)                                                                                                                      |
| 874 |    545.123925 |    580.752249 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                |
| 875 |    540.588805 |    489.202566 | Margot Michaud                                                                                                                                                |
| 876 |    520.378752 |      6.144508 | Tomas Willems (vectorized by T. Michael Keesey)                                                                                                               |
| 877 |    722.593647 |    125.277069 | Matt Crook                                                                                                                                                    |
| 878 |    689.986813 |    554.532766 | Gabriela Palomo-Munoz                                                                                                                                         |
| 879 |    939.084453 |    327.537380 | Birgit Lang                                                                                                                                                   |
| 880 |    751.799064 |    338.680756 | Chris Jennings (Risiatto)                                                                                                                                     |
| 881 |    862.191690 |     89.250867 | Steven Traver                                                                                                                                                 |
| 882 |    745.736749 |    723.413413 | Chloé Schmidt                                                                                                                                                 |
| 883 |     20.272241 |    265.338510 | Martien Brand (original photo), Renato Santos (vector silhouette)                                                                                             |
| 884 |    566.380948 |    166.715706 | Christian A. Masnaghetti                                                                                                                                      |
| 885 |    299.356140 |    514.663295 | Matthias Buschmann (vectorized by T. Michael Keesey)                                                                                                          |
| 886 |    242.051301 |    106.200524 | Gareth Monger                                                                                                                                                 |
| 887 |    321.503338 |    518.210356 | Chris huh                                                                                                                                                     |
| 888 |    769.459350 |    221.614900 | Zimices                                                                                                                                                       |
| 889 |    260.301302 |    122.779049 | Mike Hanson                                                                                                                                                   |
| 890 |    363.406666 |    496.048315 | Gabriela Palomo-Munoz                                                                                                                                         |
| 891 |    318.938462 |      3.228921 | Caio Bernardes, vectorized by Zimices                                                                                                                         |
