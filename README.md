
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

Fir0002/Flagstaffotos (photo), John E. McCormack, Michael G. Harvey,
Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T.
Brumfield & T. Michael Keesey, Matt Crook, Kanchi Nanjo, Lukasiniho,
Beth Reinke, FJDegrange, Nobu Tamura (vectorized by T. Michael Keesey),
Margot Michaud, Dean Schnabel, Dmitry Bogdanov (vectorized by T. Michael
Keesey), Zimices, Martin R. Smith, Jack Mayer Wood, Rebecca Groom,
Zimices, based in Mauricio Antón skeletal, Mathilde Cordellier, .
Original drawing by M. Antón, published in Montoya and Morales 1984.
Vectorized by O. Sanisidro, Felix Vaux, Gabriela Palomo-Munoz, Ferran
Sayol, Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow
(vectorized by T. Michael Keesey), Iain Reid, Sarah Werning, Chris huh,
Jose Carlos Arenas-Monroy, Gareth Monger, Brad McFeeters (vectorized by
T. Michael Keesey), Xavier Giroux-Bougard, Maija Karala, Chris Jennings
(Risiatto), T. Michael Keesey, L. Shyamal, Steven Traver, Scott Hartman
(vectorized by T. Michael Keesey), Melissa Broussard, Jagged Fang
Designs, Mathieu Basille, Gustav Mützel, Michelle Site, Tasman Dixon,
Christian A. Masnaghetti, Markus A. Grohme, Maxime Dahirel, Noah
Schlottman, photo by Casey Dunn, Aleksey Nagovitsyn (vectorized by T.
Michael Keesey), Cristian Osorio & Paula Carrera, Proyecto Carnivoros
Australes (www.carnivorosaustrales.org), Obsidian Soul (vectorized by T.
Michael Keesey), Haplochromis (vectorized by T. Michael Keesey), Richard
Ruggiero, vectorized by Zimices, Geoff Shaw, Chuanixn Yu,
Archaeodontosaurus (vectorized by T. Michael Keesey), Tracy A. Heath,
Greg Schechter (original photo), Renato Santos (vector silhouette),
Chloé Schmidt, Sergio A. Muñoz-Gómez, Scott Hartman, Caleb M. Gordon,
Christoph Schomburg, E. J. Van Nieukerken, A. Laštuvka, and Z. Laštuvka
(vectorized by T. Michael Keesey), Ignacio Contreras, SecretJellyMan -
from Mason McNair, Catherine Yasuda, T. Michael Keesey (after MPF),
Robbie N. Cada (modified by T. Michael Keesey), Jakovche,
kreidefossilien.de, Francesca Belem Lopes Palmeira, Harold N Eyster,
Meliponicultor Itaymbere, New York Zoological Society, T. Michael Keesey
(after James & al.), Ralf Janssen, Nikola-Michael Prpic & Wim G. M.
Damen (vectorized by T. Michael Keesey), Kevin Sánchez, Mark Miller,
Juan Carlos Jerí, Hans Hillewaert (vectorized by T. Michael Keesey),
Robbie N. Cada (vectorized by T. Michael Keesey), Marcos Pérez-Losada,
Jens T. Høeg & Keith A. Crandall, T. Michael Keesey (after Heinrich
Harder), Moussa Direct Ltd. (photography) and T. Michael Keesey
(vectorization), Martin R. Smith, after Skovsted et al 2015, Steven
Coombs, Scott Reid, kotik, Katie S. Collins, Trond R. Oskars, Noah
Schlottman, photo by Gustav Paulay for Moorea Biocode, Francis de
Laporte de Castelnau (vectorized by T. Michael Keesey), Smith609 and T.
Michael Keesey, Nobu Tamura, vectorized by Zimices, Andrew A. Farke,
Charles R. Knight (vectorized by T. Michael Keesey), C. Camilo
Julián-Caballero, CNZdenek, Tony Ayling (vectorized by T. Michael
Keesey), xgirouxb, Darren Naish (vectorized by T. Michael Keesey),
Collin Gross, Matt Martyniuk, E. Lear, 1819 (vectorization by Yan Wong),
Mykle Hoban, Verdilak, Aadx, James I. Kirkland, Luis Alcalá, Mark A.
Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized
by T. Michael Keesey), Joanna Wolfe, Yan Wong, Emily Jane McTavish, from
Haeckel, E. H. P. A. (1904).Kunstformen der Natur. Bibliographisches,
Caleb Brown, Smokeybjb, Ingo Braasch, Berivan Temiz, Martin Kevil,
Danielle Alba, Lee Harding (photo), John E. McCormack, Michael G.
Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb
T. Brumfield & T. Michael Keesey, Dr. Thomas G. Barnes, USFWS, Mario
Quevedo, Ieuan Jones, Mathew Wedel, Auckland Museum, Tony Ayling, Danny
Cicchetti (vectorized by T. Michael Keesey), M. A. Broussard, Kelly, B.
Duygu Özpolat, Birgit Lang, Ray Simpson (vectorized by T. Michael
Keesey), Yan Wong from drawing by Joseph Smit, Jon Hill (Photo by
Benjamint444:
<http://en.wikipedia.org/wiki/File:Blue-footed-booby.jpg>), Joshua
Fowler, Konsta Happonen, from a CC-BY-NC image by pelhonen on
iNaturalist, Ghedoghedo (vectorized by T. Michael Keesey), Roberto Díaz
Sibaja, M Kolmann, Félix Landry Yuan, Sharon Wegner-Larsen, Robert
Hering, Karina Garcia, J. J. Harrison (photo) & T. Michael Keesey,
Darren Naish, Nemo, and T. Michael Keesey, Oliver Voigt, Caleb M. Brown,
Meyer-Wachsmuth I, Curini Galletti M, Jondelius U
(<doi:10.1371/journal.pone.0107688>). Vectorization by Y. Wong, Carlos
Cano-Barbacil, Duane Raver/USFWS, Alex Slavenko, Tyler Greenfield and
Scott Hartman, NOAA Great Lakes Environmental Research Laboratory
(illustration) and Timothy J. Bartley (silhouette), Ville-Veikko
Sinkkonen, Conty (vectorized by T. Michael Keesey), Ben Liebeskind, Matt
Martyniuk (vectorized by T. Michael Keesey), Johan Lindgren, Michael W.
Caldwell, Takuya Konishi, Luis M. Chiappe, Anthony Caravaggi, Frank
Förster, Rene Martin, Matt Wilkins, Stanton F. Fink (vectorized by T.
Michael Keesey), John Gould (vectorized by T. Michael Keesey), Nicholas
J. Czaplewski, vectorized by Zimices, Aviceda (vectorized by T. Michael
Keesey), Abraão B. Leite, Thibaut Brunet, David Tana, Espen Horn (model;
vectorized by T. Michael Keesey from a photo by H. Zell), Emily
Willoughby, Robert Gay, Chris Jennings (vectorized by A. Verrière),
FunkMonk, Tyler McCraney, David Orr, Mathieu Pélissié, Becky Barnes,
Burton Robert, USFWS, Mathew Stewart, Kent Sorgon, Apokryltaros
(vectorized by T. Michael Keesey), Taro Maeda, T. Michael Keesey (after
Mauricio Antón), Meyers Konversations-Lexikon 1897 (vectorized: Yan
Wong), Michael Scroggie, Mr E? (vectorized by T. Michael Keesey), Jake
Warner, Maxwell Lefroy (vectorized by T. Michael Keesey), Jaime Headden,
modified by T. Michael Keesey, Abraão Leite, Robert Bruce Horsfall
(vectorized by T. Michael Keesey), George Edward Lodge, Jan Sevcik
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Sarah Alewijnse, Oscar Sanisidro, Michele Tobias, Andrew R.
Gehrke, Crystal Maier, Alexandre Vong, Robert Gay, modified from
FunkMonk (Michael B.H.) and T. Michael Keesey., Milton Tan, Noah
Schlottman, Ludwik Gasiorowski, Matus Valach, Kamil S. Jaron, Dmitry
Bogdanov, Tauana J. Cunha, T. Tischler, Baheerathan Murugavel, Campbell
Fleming, T. Michael Keesey (vectorization); Yves Bousquet (photography),
Dave Angelini, Duane Raver (vectorized by T. Michael Keesey), Chase
Brownstein, Noah Schlottman, photo from Casey Dunn, Shyamal, Sam
Fraser-Smith (vectorized by T. Michael Keesey), Jon Hill (Photo by
DickDaniels:
<http://en.wikipedia.org/wiki/File:Green_Woodhoopoe_RWD7.jpg>), Jaime
Headden, Alexander Schmidt-Lebuhn, Chris Hay, Ellen Edmonson
(illustration) and Timothy J. Bartley (silhouette), Tess Linden, Lily
Hughes, Qiang Ou, George Edward Lodge (vectorized by T. Michael Keesey),
Jimmy Bernot, Arthur S. Brum, Peter Coxhead, Mihai Dragos (vectorized by
T. Michael Keesey), Dave Souza (vectorized by T. Michael Keesey), John
Conway, L.M. Davalos, T. Michael Keesey (vectorization) and Tony Hisgett
(photography), Kai R. Caspar, Andrew Farke and Joseph Sertich, Armin
Reindl, Mariana Ruiz (vectorized by T. Michael Keesey), Frank Förster
(based on a picture by Jerry Kirkhart; modified by T. Michael Keesey),
V. Deepak, Inessa Voet, Steven Haddock • Jellywatch.org, Karkemish
(vectorized by T. Michael Keesey), Walter Vladimir, Neil Kelley, (after
Spotila 2004), Timothy Knepp (vectorized by T. Michael Keesey), Konsta
Happonen, E. D. Cope (modified by T. Michael Keesey, Michael P. Taylor &
Matthew J. Wedel), Cesar Julian, Lauren Anderson, Frederick William
Frohawk (vectorized by T. Michael Keesey), Nobu Tamura (modified by T.
Michael Keesey), Andrés Sánchez, A. R. McCulloch (vectorized by T.
Michael Keesey), Brockhaus and Efron, Stuart Humphries, Mali’o Kodis,
photograph by “Wildcat Dunny”
(<http://www.flickr.com/people/wildcat_dunny/>), Farelli (photo), John
E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G.
Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Sean
McCann, Andreas Preuss / marauder, Mo Hassan, Jessica Anne Miller, Yan
Wong from photo by Denes Emoke, Mali’o Kodis, photograph by Melissa
Frey, Nobu Tamura, M Hutchinson, Jay Matternes (modified by T. Michael
Keesey)

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    782.329000 |    600.929569 | NA                                                                                                                                                                    |
|   2 |    460.183073 |    428.770613 | Fir0002/Flagstaffotos (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
|   3 |    582.549872 |    318.512218 | Matt Crook                                                                                                                                                            |
|   4 |    363.499569 |    552.919012 | Kanchi Nanjo                                                                                                                                                          |
|   5 |    843.024787 |    288.268188 | Lukasiniho                                                                                                                                                            |
|   6 |    273.516691 |    301.922370 | Beth Reinke                                                                                                                                                           |
|   7 |    403.517179 |    223.480263 | NA                                                                                                                                                                    |
|   8 |    158.811357 |    603.569243 | FJDegrange                                                                                                                                                            |
|   9 |    716.602140 |    479.127562 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  10 |    637.734178 |    194.450538 | Margot Michaud                                                                                                                                                        |
|  11 |    654.185833 |    114.357380 | Dean Schnabel                                                                                                                                                         |
|  12 |    923.117291 |    112.671286 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  13 |    859.148707 |    220.249903 | Zimices                                                                                                                                                               |
|  14 |    542.574012 |     35.535095 | Martin R. Smith                                                                                                                                                       |
|  15 |     60.670970 |    161.277564 | Jack Mayer Wood                                                                                                                                                       |
|  16 |     69.292711 |     55.954808 | Rebecca Groom                                                                                                                                                         |
|  17 |    204.131315 |    408.393604 | Matt Crook                                                                                                                                                            |
|  18 |    360.255408 |    108.873614 | Zimices                                                                                                                                                               |
|  19 |    910.015788 |    699.486930 | Zimices, based in Mauricio Antón skeletal                                                                                                                             |
|  20 |    600.737030 |    607.803831 | NA                                                                                                                                                                    |
|  21 |    969.795374 |    328.392351 | Mathilde Cordellier                                                                                                                                                   |
|  22 |    453.448479 |    109.537434 | . Original drawing by M. Antón, published in Montoya and Morales 1984. Vectorized by O. Sanisidro                                                                     |
|  23 |    271.914876 |     60.168617 | Felix Vaux                                                                                                                                                            |
|  24 |    342.626850 |    398.647476 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  25 |    295.243654 |    633.660060 | Ferran Sayol                                                                                                                                                          |
|  26 |    442.494389 |    683.631282 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
|  27 |     82.394173 |    281.446788 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  28 |    603.471927 |    753.808921 | Iain Reid                                                                                                                                                             |
|  29 |    742.066981 |    346.462086 | Sarah Werning                                                                                                                                                         |
|  30 |     64.904241 |    768.535509 | Chris huh                                                                                                                                                             |
|  31 |    179.615146 |    171.850001 | Jose Carlos Arenas-Monroy                                                                                                                                             |
|  32 |    511.789714 |    611.936696 | Zimices                                                                                                                                                               |
|  33 |    786.119270 |     41.373991 | Margot Michaud                                                                                                                                                        |
|  34 |    920.083991 |     51.110673 | Chris huh                                                                                                                                                             |
|  35 |    679.490128 |    728.311472 | Gareth Monger                                                                                                                                                         |
|  36 |    807.079740 |    117.793580 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
|  37 |    256.354429 |    743.746345 | Xavier Giroux-Bougard                                                                                                                                                 |
|  38 |    564.187637 |    394.662681 | Maija Karala                                                                                                                                                          |
|  39 |     74.622980 |    359.628760 | Chris Jennings (Risiatto)                                                                                                                                             |
|  40 |    629.933470 |    244.875396 | NA                                                                                                                                                                    |
|  41 |     31.709681 |    619.635518 | T. Michael Keesey                                                                                                                                                     |
|  42 |    961.152760 |    207.677163 | L. Shyamal                                                                                                                                                            |
|  43 |    453.922080 |    765.142713 | Steven Traver                                                                                                                                                         |
|  44 |    953.415158 |    650.654730 | Margot Michaud                                                                                                                                                        |
|  45 |     69.290700 |    472.945719 | Scott Hartman (vectorized by T. Michael Keesey)                                                                                                                       |
|  46 |    221.202927 |    496.635474 | Melissa Broussard                                                                                                                                                     |
|  47 |    828.068214 |    733.493875 | Jagged Fang Designs                                                                                                                                                   |
|  48 |    914.242614 |    524.469813 | Mathieu Basille                                                                                                                                                       |
|  49 |     65.612519 |    412.331710 | Gustav Mützel                                                                                                                                                         |
|  50 |    137.852955 |    718.093095 | Michelle Site                                                                                                                                                         |
|  51 |    889.935294 |    378.821670 | Gareth Monger                                                                                                                                                         |
|  52 |    154.840851 |     21.449053 | Tasman Dixon                                                                                                                                                          |
|  53 |    436.605057 |    346.225198 | Zimices                                                                                                                                                               |
|  54 |    290.984753 |    153.756586 | T. Michael Keesey                                                                                                                                                     |
|  55 |    934.194097 |    578.832677 | Christian A. Masnaghetti                                                                                                                                              |
|  56 |    332.964175 |    450.952545 | Markus A. Grohme                                                                                                                                                      |
|  57 |    558.630045 |    116.003066 | Maxime Dahirel                                                                                                                                                        |
|  58 |    331.112545 |    712.011137 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
|  59 |    959.714931 |    475.678868 | L. Shyamal                                                                                                                                                            |
|  60 |    738.858081 |    225.782464 | Aleksey Nagovitsyn (vectorized by T. Michael Keesey)                                                                                                                  |
|  61 |    150.052094 |     81.092064 | Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org)                                                                          |
|  62 |    572.327384 |    704.775749 | Sarah Werning                                                                                                                                                         |
|  63 |    410.567645 |    637.100915 | NA                                                                                                                                                                    |
|  64 |    356.565432 |     39.957136 | NA                                                                                                                                                                    |
|  65 |     93.547057 |    217.249944 | Jagged Fang Designs                                                                                                                                                   |
|  66 |    192.987078 |    333.975522 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
|  67 |    834.940043 |    702.663592 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                        |
|  68 |    473.283851 |    491.774790 | Tasman Dixon                                                                                                                                                          |
|  69 |    127.289640 |    133.702433 | Richard Ruggiero, vectorized by Zimices                                                                                                                               |
|  70 |    183.715330 |    541.460681 | Geoff Shaw                                                                                                                                                            |
|  71 |    996.267720 |    620.157992 | Chuanixn Yu                                                                                                                                                           |
|  72 |    494.647474 |     32.687232 | Chris huh                                                                                                                                                             |
|  73 |    526.550733 |    104.699792 | Archaeodontosaurus (vectorized by T. Michael Keesey)                                                                                                                  |
|  74 |    996.040395 |    416.314603 | Tracy A. Heath                                                                                                                                                        |
|  75 |    463.003897 |    519.936449 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  76 |    737.346490 |    103.341802 | Greg Schechter (original photo), Renato Santos (vector silhouette)                                                                                                    |
|  77 |    255.705749 |    193.999021 | Chloé Schmidt                                                                                                                                                         |
|  78 |     19.247703 |    268.596565 | Matt Crook                                                                                                                                                            |
|  79 |    213.244531 |    116.788170 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
|  80 |    386.991283 |    418.356575 | NA                                                                                                                                                                    |
|  81 |    852.309203 |    486.193746 | Matt Crook                                                                                                                                                            |
|  82 |    296.019125 |    570.395235 | Scott Hartman                                                                                                                                                         |
|  83 |     70.489044 |    569.086349 | Caleb M. Gordon                                                                                                                                                       |
|  84 |    284.004616 |    778.876967 | Margot Michaud                                                                                                                                                        |
|  85 |    249.659487 |    723.963739 | Christoph Schomburg                                                                                                                                                   |
|  86 |    864.128674 |    181.444319 | E. J. Van Nieukerken, A. Laštuvka, and Z. Laštuvka (vectorized by T. Michael Keesey)                                                                                  |
|  87 |    802.401087 |    687.278281 | Ignacio Contreras                                                                                                                                                     |
|  88 |     81.250955 |    673.198203 | SecretJellyMan - from Mason McNair                                                                                                                                    |
|  89 |    474.617376 |    363.827639 | Catherine Yasuda                                                                                                                                                      |
|  90 |    332.569024 |    167.689122 | T. Michael Keesey (after MPF)                                                                                                                                         |
|  91 |    864.507253 |    156.877635 | Gareth Monger                                                                                                                                                         |
|  92 |    681.627193 |    307.460841 | Margot Michaud                                                                                                                                                        |
|  93 |    811.454984 |    371.475037 | T. Michael Keesey                                                                                                                                                     |
|  94 |    238.367983 |    567.403228 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                                        |
|  95 |    678.092242 |    640.835598 | Jagged Fang Designs                                                                                                                                                   |
|  96 |    977.264330 |    540.154721 | Margot Michaud                                                                                                                                                        |
|  97 |    495.845957 |    185.546545 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  98 |    571.317046 |    237.984419 | Jakovche                                                                                                                                                              |
|  99 |    227.893686 |    772.734009 | kreidefossilien.de                                                                                                                                                    |
| 100 |    493.322001 |    500.744780 | Francesca Belem Lopes Palmeira                                                                                                                                        |
| 101 |    204.177832 |    778.544810 | L. Shyamal                                                                                                                                                            |
| 102 |    367.580372 |    678.273357 | Zimices                                                                                                                                                               |
| 103 |    701.926204 |     25.327360 | Sarah Werning                                                                                                                                                         |
| 104 |    354.108336 |    471.326418 | Harold N Eyster                                                                                                                                                       |
| 105 |    437.621006 |    615.351844 | Steven Traver                                                                                                                                                         |
| 106 |    114.184305 |    351.144671 | Gareth Monger                                                                                                                                                         |
| 107 |    825.346690 |    156.255274 | Tasman Dixon                                                                                                                                                          |
| 108 |    525.840416 |    513.336342 | Markus A. Grohme                                                                                                                                                      |
| 109 |    110.597136 |    262.521389 | Meliponicultor Itaymbere                                                                                                                                              |
| 110 |    756.552180 |    787.667186 | Zimices                                                                                                                                                               |
| 111 |    946.429132 |    743.761159 | New York Zoological Society                                                                                                                                           |
| 112 |    862.616234 |    502.890952 | Matt Crook                                                                                                                                                            |
| 113 |    113.355444 |    239.017116 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 114 |    678.980649 |    668.453871 | Tasman Dixon                                                                                                                                                          |
| 115 |     94.802462 |    118.389940 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 116 |    263.645239 |    506.963062 | T. Michael Keesey (after James & al.)                                                                                                                                 |
| 117 |     17.096132 |    180.241435 | Rebecca Groom                                                                                                                                                         |
| 118 |     45.965563 |    322.922099 | Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael Keesey)                                                                                |
| 119 |     55.200806 |    743.917144 | Kevin Sánchez                                                                                                                                                         |
| 120 |    336.995396 |    765.775464 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 121 |     84.010219 |    439.212422 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 122 |    997.687387 |    169.670592 | Mark Miller                                                                                                                                                           |
| 123 |    240.123851 |     42.864360 | Steven Traver                                                                                                                                                         |
| 124 |    160.934973 |    494.701261 | Tasman Dixon                                                                                                                                                          |
| 125 |    170.305157 |    124.438249 | Juan Carlos Jerí                                                                                                                                                      |
| 126 |    907.086839 |    357.941630 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 127 |    225.569853 |    540.660353 | Beth Reinke                                                                                                                                                           |
| 128 |    884.630206 |     19.937305 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
| 129 |    684.462890 |    381.671873 | Marcos Pérez-Losada, Jens T. Høeg & Keith A. Crandall                                                                                                                 |
| 130 |    585.328775 |    443.452045 | Zimices                                                                                                                                                               |
| 131 |    185.465862 |    692.478041 | T. Michael Keesey (after Heinrich Harder)                                                                                                                             |
| 132 |    530.277416 |     75.618305 | Michelle Site                                                                                                                                                         |
| 133 |      6.367070 |     71.952321 | Moussa Direct Ltd. (photography) and T. Michael Keesey (vectorization)                                                                                                |
| 134 |    357.243313 |    388.587062 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 135 |    151.692839 |    309.698315 | Martin R. Smith, after Skovsted et al 2015                                                                                                                            |
| 136 |     43.953818 |    116.301250 | Steven Coombs                                                                                                                                                         |
| 137 |    546.716776 |    263.832252 | Scott Reid                                                                                                                                                            |
| 138 |    854.163035 |     28.015572 | Christoph Schomburg                                                                                                                                                   |
| 139 |    941.373387 |    552.427836 | kotik                                                                                                                                                                 |
| 140 |    680.874837 |    250.918342 | Ferran Sayol                                                                                                                                                          |
| 141 |    246.957842 |    719.950986 | Dean Schnabel                                                                                                                                                         |
| 142 |    556.927657 |    455.003598 | Margot Michaud                                                                                                                                                        |
| 143 |    941.424384 |    403.432392 | Katie S. Collins                                                                                                                                                      |
| 144 |    964.970579 |    124.186021 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 145 |    934.467648 |     22.389208 | Margot Michaud                                                                                                                                                        |
| 146 |    232.442568 |    502.790990 | Dean Schnabel                                                                                                                                                         |
| 147 |     13.187959 |    518.663448 | Harold N Eyster                                                                                                                                                       |
| 148 |    897.665838 |    449.092618 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 149 |    733.715450 |    699.127603 | Gareth Monger                                                                                                                                                         |
| 150 |    998.716439 |    731.313475 | Matt Crook                                                                                                                                                            |
| 151 |    223.700754 |    215.268481 | Trond R. Oskars                                                                                                                                                       |
| 152 |    911.227303 |     74.248674 | Ferran Sayol                                                                                                                                                          |
| 153 |    478.704147 |    316.824118 | Noah Schlottman, photo by Gustav Paulay for Moorea Biocode                                                                                                            |
| 154 |    267.388375 |    355.147693 | Martin R. Smith                                                                                                                                                       |
| 155 |     69.236835 |    200.037767 | Francis de Laporte de Castelnau (vectorized by T. Michael Keesey)                                                                                                     |
| 156 |    513.402663 |    653.110463 | Smith609 and T. Michael Keesey                                                                                                                                        |
| 157 |    929.632540 |    234.837162 | Zimices                                                                                                                                                               |
| 158 |    151.722836 |    271.173166 | Jagged Fang Designs                                                                                                                                                   |
| 159 |    160.146332 |    668.160915 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 160 |    859.403178 |    450.849726 | Andrew A. Farke                                                                                                                                                       |
| 161 |    533.262533 |     59.593530 | Jagged Fang Designs                                                                                                                                                   |
| 162 |    519.600671 |    758.483021 | Charles R. Knight (vectorized by T. Michael Keesey)                                                                                                                   |
| 163 |    892.111376 |    608.596741 | C. Camilo Julián-Caballero                                                                                                                                            |
| 164 |     56.882119 |    720.313778 | Matt Crook                                                                                                                                                            |
| 165 |      8.587288 |    563.778386 | NA                                                                                                                                                                    |
| 166 |    963.191540 |    184.116465 | Steven Traver                                                                                                                                                         |
| 167 |    388.695192 |    314.358968 | T. Michael Keesey                                                                                                                                                     |
| 168 |    948.694859 |    133.295929 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 169 |    779.870918 |    170.426259 | NA                                                                                                                                                                    |
| 170 |    617.379665 |    380.497116 | Margot Michaud                                                                                                                                                        |
| 171 |    519.860730 |    458.504570 | Steven Traver                                                                                                                                                         |
| 172 |    853.753434 |     57.743291 | Margot Michaud                                                                                                                                                        |
| 173 |    408.187415 |    798.395764 | CNZdenek                                                                                                                                                              |
| 174 |    522.102311 |    771.811889 | Scott Hartman                                                                                                                                                         |
| 175 |    218.341848 |    321.013540 | Ferran Sayol                                                                                                                                                          |
| 176 |    236.811281 |    123.783362 | NA                                                                                                                                                                    |
| 177 |    413.330325 |    618.297893 | Geoff Shaw                                                                                                                                                            |
| 178 |   1008.942783 |    355.239732 | Beth Reinke                                                                                                                                                           |
| 179 |    200.255902 |    672.668084 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 180 |    907.402188 |    439.834509 | xgirouxb                                                                                                                                                              |
| 181 |    855.529626 |    786.657355 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                        |
| 182 |    241.939699 |    611.327697 | Zimices                                                                                                                                                               |
| 183 |    480.387001 |    293.682597 | Collin Gross                                                                                                                                                          |
| 184 |    138.216394 |     42.344766 | Matt Martyniuk                                                                                                                                                        |
| 185 |    620.142678 |    732.565809 | E. Lear, 1819 (vectorization by Yan Wong)                                                                                                                             |
| 186 |     33.457208 |    533.475049 | Mykle Hoban                                                                                                                                                           |
| 187 |    633.526723 |     58.298583 | Verdilak                                                                                                                                                              |
| 188 |    676.206822 |    337.810028 | Aadx                                                                                                                                                                  |
| 189 |    920.294598 |    787.058508 | Zimices                                                                                                                                                               |
| 190 |    980.446361 |     24.370142 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                  |
| 191 |    422.661252 |     15.087016 | Joanna Wolfe                                                                                                                                                          |
| 192 |    325.248454 |    781.638938 | Geoff Shaw                                                                                                                                                            |
| 193 |    941.195382 |    767.244723 | Juan Carlos Jerí                                                                                                                                                      |
| 194 |    834.357689 |    174.680088 | Lukasiniho                                                                                                                                                            |
| 195 |     87.919451 |    641.820336 | Yan Wong                                                                                                                                                              |
| 196 |    822.200055 |    488.576921 | Emily Jane McTavish, from Haeckel, E. H. P. A. (1904).Kunstformen der Natur. Bibliographisches                                                                        |
| 197 |     53.720290 |    655.960737 | Sarah Werning                                                                                                                                                         |
| 198 |     30.095969 |    722.249846 | Ferran Sayol                                                                                                                                                          |
| 199 |    677.937616 |     42.845197 | Caleb Brown                                                                                                                                                           |
| 200 |    198.164614 |    216.183290 | Jagged Fang Designs                                                                                                                                                   |
| 201 |    705.864424 |     67.243278 | Melissa Broussard                                                                                                                                                     |
| 202 |    629.763822 |     21.713027 | Margot Michaud                                                                                                                                                        |
| 203 |    143.255150 |    401.519300 | T. Michael Keesey                                                                                                                                                     |
| 204 |    448.736371 |    722.536706 | Zimices                                                                                                                                                               |
| 205 |    577.063305 |    106.658342 | Smokeybjb                                                                                                                                                             |
| 206 |    111.568361 |    165.167245 | Steven Traver                                                                                                                                                         |
| 207 |    492.777939 |    282.916388 | NA                                                                                                                                                                    |
| 208 |    307.396209 |    761.350871 | Chris huh                                                                                                                                                             |
| 209 |    264.470936 |    215.548956 | NA                                                                                                                                                                    |
| 210 |    372.783342 |    744.831905 | NA                                                                                                                                                                    |
| 211 |    844.048714 |    359.230888 | Geoff Shaw                                                                                                                                                            |
| 212 |     82.348188 |    241.736169 | Ingo Braasch                                                                                                                                                          |
| 213 |    872.530249 |    542.178111 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
| 214 |    895.860246 |      5.318833 | Scott Hartman                                                                                                                                                         |
| 215 |    288.290014 |    336.940247 | Dean Schnabel                                                                                                                                                         |
| 216 |    540.542075 |    745.813666 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 217 |    255.401355 |    533.096837 | Zimices                                                                                                                                                               |
| 218 |    968.270849 |    555.349628 | Zimices                                                                                                                                                               |
| 219 |    341.292016 |    185.064961 | Gareth Monger                                                                                                                                                         |
| 220 |     11.062606 |    729.931161 | Margot Michaud                                                                                                                                                        |
| 221 |    195.606998 |     97.177291 | Berivan Temiz                                                                                                                                                         |
| 222 |    945.137718 |     12.515213 | Maija Karala                                                                                                                                                          |
| 223 |    673.069794 |    234.100505 | Jagged Fang Designs                                                                                                                                                   |
| 224 |   1006.728659 |    781.784316 | Matt Crook                                                                                                                                                            |
| 225 |    508.911587 |    316.099635 | Margot Michaud                                                                                                                                                        |
| 226 |    717.710936 |     14.320346 | Steven Traver                                                                                                                                                         |
| 227 |    752.224232 |    684.226590 | Margot Michaud                                                                                                                                                        |
| 228 |    472.827088 |     46.591676 | Matt Crook                                                                                                                                                            |
| 229 |    769.844081 |    300.059681 | Martin Kevil                                                                                                                                                          |
| 230 |    943.029813 |    607.848529 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 231 |    164.140019 |    352.745890 | Beth Reinke                                                                                                                                                           |
| 232 |    401.136110 |    780.804358 | Danielle Alba                                                                                                                                                         |
| 233 |    942.293297 |    147.975522 | Michelle Site                                                                                                                                                         |
| 234 |    905.553155 |    257.093639 | Jagged Fang Designs                                                                                                                                                   |
| 235 |    871.626157 |     26.745211 | Lee Harding (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
| 236 |     15.008260 |    636.026964 | Zimices                                                                                                                                                               |
| 237 |    141.008175 |    363.193992 | Beth Reinke                                                                                                                                                           |
| 238 |    377.765061 |    387.780209 | Ignacio Contreras                                                                                                                                                     |
| 239 |    288.108504 |    251.843659 | Chris huh                                                                                                                                                             |
| 240 |    327.524959 |    794.182393 | Markus A. Grohme                                                                                                                                                      |
| 241 |    357.940963 |    439.451643 | Margot Michaud                                                                                                                                                        |
| 242 |    896.496630 |     73.539191 | Chloé Schmidt                                                                                                                                                         |
| 243 |     68.038077 |    210.632326 | Scott Hartman                                                                                                                                                         |
| 244 |     20.330389 |    442.174120 | Margot Michaud                                                                                                                                                        |
| 245 |    176.826316 |    253.443146 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 246 |    886.313794 |    626.921784 | NA                                                                                                                                                                    |
| 247 |    385.893245 |    484.394826 | Markus A. Grohme                                                                                                                                                      |
| 248 |    230.973652 |     10.669613 | T. Michael Keesey                                                                                                                                                     |
| 249 |    788.898011 |    215.295767 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 250 |    972.886833 |    407.562637 | NA                                                                                                                                                                    |
| 251 |    955.943059 |    743.620017 | Tasman Dixon                                                                                                                                                          |
| 252 |    520.812031 |    532.443309 | CNZdenek                                                                                                                                                              |
| 253 |    623.809171 |    218.195576 | Zimices                                                                                                                                                               |
| 254 |    651.515816 |    352.578712 | Zimices                                                                                                                                                               |
| 255 |    590.249977 |     90.183348 | Dr. Thomas G. Barnes, USFWS                                                                                                                                           |
| 256 |    785.916202 |    232.573612 | Matt Crook                                                                                                                                                            |
| 257 |    533.313451 |    251.137333 | Collin Gross                                                                                                                                                          |
| 258 |    379.063130 |    432.262894 | Joanna Wolfe                                                                                                                                                          |
| 259 |    301.104728 |    531.990909 | Matt Crook                                                                                                                                                            |
| 260 |    888.767841 |    488.036530 | Zimices                                                                                                                                                               |
| 261 |    799.637320 |    791.523837 | Mario Quevedo                                                                                                                                                         |
| 262 |    350.256602 |    698.249829 | Gareth Monger                                                                                                                                                         |
| 263 |    605.153733 |    202.709320 | Ieuan Jones                                                                                                                                                           |
| 264 |    526.726640 |    156.166550 | Matt Crook                                                                                                                                                            |
| 265 |     17.227881 |    754.440702 | Gareth Monger                                                                                                                                                         |
| 266 |    691.446393 |    178.363428 | Lukasiniho                                                                                                                                                            |
| 267 |     63.972356 |    113.999197 | Juan Carlos Jerí                                                                                                                                                      |
| 268 |    405.302632 |    149.717698 | Mathew Wedel                                                                                                                                                          |
| 269 |    940.600579 |    617.337413 | Auckland Museum                                                                                                                                                       |
| 270 |    661.150610 |    405.344136 | Gareth Monger                                                                                                                                                         |
| 271 |     22.570410 |    284.226248 | Scott Hartman                                                                                                                                                         |
| 272 |    270.420026 |    241.035473 | Melissa Broussard                                                                                                                                                     |
| 273 |     73.193744 |     93.475291 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 274 |    287.406333 |    417.989691 | NA                                                                                                                                                                    |
| 275 |    715.334634 |    124.791783 | Zimices                                                                                                                                                               |
| 276 |    299.645363 |    589.382358 | Jagged Fang Designs                                                                                                                                                   |
| 277 |    796.610457 |     83.752042 | Matt Crook                                                                                                                                                            |
| 278 |    112.793128 |    649.060704 | Tony Ayling                                                                                                                                                           |
| 279 |    132.323239 |    784.974340 | Danny Cicchetti (vectorized by T. Michael Keesey)                                                                                                                     |
| 280 |    164.642689 |    370.947249 | Tasman Dixon                                                                                                                                                          |
| 281 |    139.334868 |    204.204657 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 282 |    516.602784 |    361.760729 | T. Michael Keesey                                                                                                                                                     |
| 283 |    522.191507 |    219.663030 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 284 |    906.422733 |    156.101252 | Tasman Dixon                                                                                                                                                          |
| 285 |     23.314630 |    499.695731 | Catherine Yasuda                                                                                                                                                      |
| 286 |    992.944667 |    710.231924 | M. A. Broussard                                                                                                                                                       |
| 287 |    455.770592 |    293.187638 | NA                                                                                                                                                                    |
| 288 |    566.637987 |    165.559185 | Zimices                                                                                                                                                               |
| 289 |     59.965122 |    516.446361 | Kelly                                                                                                                                                                 |
| 290 |    861.754809 |    460.892745 | B. Duygu Özpolat                                                                                                                                                      |
| 291 |    104.549306 |    357.557457 | Ferran Sayol                                                                                                                                                          |
| 292 |   1011.961980 |    428.168466 | Birgit Lang                                                                                                                                                           |
| 293 |    513.155966 |    409.135127 | Scott Hartman                                                                                                                                                         |
| 294 |    607.675603 |    567.386358 | Matt Crook                                                                                                                                                            |
| 295 |    256.914308 |    435.719192 | Dean Schnabel                                                                                                                                                         |
| 296 |    592.750480 |    249.725044 | Ray Simpson (vectorized by T. Michael Keesey)                                                                                                                         |
| 297 |    275.536477 |    484.221467 | Yan Wong from drawing by Joseph Smit                                                                                                                                  |
| 298 |   1010.492717 |     72.583137 | Jon Hill (Photo by Benjamint444: <http://en.wikipedia.org/wiki/File:Blue-footed-booby.jpg>)                                                                           |
| 299 |    415.283202 |    381.071105 | Zimices                                                                                                                                                               |
| 300 |    476.998230 |    154.737820 | Andrew A. Farke                                                                                                                                                       |
| 301 |    562.769337 |    741.291541 | NA                                                                                                                                                                    |
| 302 |    258.644922 |    677.268572 | Gareth Monger                                                                                                                                                         |
| 303 |   1008.733629 |    521.930793 | Margot Michaud                                                                                                                                                        |
| 304 |    420.271459 |    153.460369 | xgirouxb                                                                                                                                                              |
| 305 |    194.096905 |    731.006518 | Dean Schnabel                                                                                                                                                         |
| 306 |    452.829880 |     35.114643 | Zimices                                                                                                                                                               |
| 307 |    149.783130 |    682.427638 | T. Michael Keesey                                                                                                                                                     |
| 308 |    714.618636 |    552.535853 | Zimices                                                                                                                                                               |
| 309 |    532.820310 |    497.279229 | Steven Traver                                                                                                                                                         |
| 310 |    140.191335 |    375.777343 | Lukasiniho                                                                                                                                                            |
| 311 |   1012.629104 |     92.642751 | Joshua Fowler                                                                                                                                                         |
| 312 |    734.006223 |    768.510016 | Konsta Happonen, from a CC-BY-NC image by pelhonen on iNaturalist                                                                                                     |
| 313 |    819.845632 |    246.972834 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 314 |     77.164620 |    544.930863 | Ferran Sayol                                                                                                                                                          |
| 315 |   1012.241370 |    125.490642 | Matt Crook                                                                                                                                                            |
| 316 |    120.771935 |     22.712709 | Ignacio Contreras                                                                                                                                                     |
| 317 |    184.532373 |    786.724692 | Chris huh                                                                                                                                                             |
| 318 |    981.390072 |     90.780305 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 319 |    377.420839 |    351.004671 | Beth Reinke                                                                                                                                                           |
| 320 |    981.016600 |    677.566743 | Margot Michaud                                                                                                                                                        |
| 321 |    279.624783 |    655.300418 | Roberto Díaz Sibaja                                                                                                                                                   |
| 322 |     36.334374 |    743.825779 | M Kolmann                                                                                                                                                             |
| 323 |    582.940870 |     67.707321 | Andrew A. Farke                                                                                                                                                       |
| 324 |    952.501607 |    585.249875 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 325 |    795.229451 |      8.113786 | Matt Crook                                                                                                                                                            |
| 326 |     52.870082 |     11.490801 | Margot Michaud                                                                                                                                                        |
| 327 |    243.262552 |     74.252608 | Collin Gross                                                                                                                                                          |
| 328 |   1007.652518 |    199.561705 | Margot Michaud                                                                                                                                                        |
| 329 |    383.912110 |    616.058284 | Gareth Monger                                                                                                                                                         |
| 330 |    708.576624 |    316.601252 | Steven Traver                                                                                                                                                         |
| 331 |    961.403593 |    529.570886 | Matt Crook                                                                                                                                                            |
| 332 |    939.390865 |    281.278189 | Roberto Díaz Sibaja                                                                                                                                                   |
| 333 |    418.067265 |    562.617957 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 334 |    667.549147 |    606.834590 | Lukasiniho                                                                                                                                                            |
| 335 |    803.278163 |    132.809453 | Christoph Schomburg                                                                                                                                                   |
| 336 |    893.695555 |    303.708013 | Félix Landry Yuan                                                                                                                                                     |
| 337 |    642.149089 |    723.769581 | Maija Karala                                                                                                                                                          |
| 338 |    970.055003 |    160.440541 | Sharon Wegner-Larsen                                                                                                                                                  |
| 339 |    470.653198 |     69.619943 | Robert Hering                                                                                                                                                         |
| 340 |    457.856953 |    170.413431 | Roberto Díaz Sibaja                                                                                                                                                   |
| 341 |    546.418319 |    480.723586 | Karina Garcia                                                                                                                                                         |
| 342 |    968.140799 |    791.883601 | Matt Crook                                                                                                                                                            |
| 343 |    243.440589 |    625.959035 | Scott Hartman                                                                                                                                                         |
| 344 |    287.941857 |    235.726603 | J. J. Harrison (photo) & T. Michael Keesey                                                                                                                            |
| 345 |    981.100223 |    731.807673 | Darren Naish, Nemo, and T. Michael Keesey                                                                                                                             |
| 346 |    415.791665 |    361.301797 | NA                                                                                                                                                                    |
| 347 |    455.307832 |    541.539844 | NA                                                                                                                                                                    |
| 348 |    949.692694 |    771.869060 | Beth Reinke                                                                                                                                                           |
| 349 |    531.213837 |     18.152424 | Chris huh                                                                                                                                                             |
| 350 |    838.425727 |    513.516880 | Steven Traver                                                                                                                                                         |
| 351 |    642.913881 |     28.606348 | Steven Traver                                                                                                                                                         |
| 352 |    759.266446 |    769.409716 | Felix Vaux                                                                                                                                                            |
| 353 |    987.818583 |    261.125217 | Oliver Voigt                                                                                                                                                          |
| 354 |    988.262074 |    150.179565 | NA                                                                                                                                                                    |
| 355 |    286.335034 |    521.975991 | Chris huh                                                                                                                                                             |
| 356 |    159.780803 |    288.538769 | Joanna Wolfe                                                                                                                                                          |
| 357 |    824.976991 |     17.731611 | Zimices                                                                                                                                                               |
| 358 |    993.717500 |    195.455158 | Caleb M. Brown                                                                                                                                                        |
| 359 |    504.724766 |    308.641102 | Ignacio Contreras                                                                                                                                                     |
| 360 |    839.714114 |    476.539935 | Meyer-Wachsmuth I, Curini Galletti M, Jondelius U (<doi:10.1371/journal.pone.0107688>). Vectorization by Y. Wong                                                      |
| 361 |   1004.048578 |    148.064420 | Carlos Cano-Barbacil                                                                                                                                                  |
| 362 |   1005.203215 |     55.721855 | Steven Traver                                                                                                                                                         |
| 363 |    758.085399 |    101.230690 | Mathew Wedel                                                                                                                                                          |
| 364 |    627.766510 |    561.387374 | Ferran Sayol                                                                                                                                                          |
| 365 |    525.791770 |    425.185141 | Zimices                                                                                                                                                               |
| 366 |    194.213738 |     45.263015 | Gareth Monger                                                                                                                                                         |
| 367 |    357.376916 |    654.276667 | C. Camilo Julián-Caballero                                                                                                                                            |
| 368 |    258.562537 |    262.113794 | Duane Raver/USFWS                                                                                                                                                     |
| 369 |     60.192667 |    619.783912 | Matt Crook                                                                                                                                                            |
| 370 |    477.775517 |    554.314172 | Dean Schnabel                                                                                                                                                         |
| 371 |    644.392598 |    785.141536 | Alex Slavenko                                                                                                                                                         |
| 372 |     23.554196 |      6.618104 | Tyler Greenfield and Scott Hartman                                                                                                                                    |
| 373 |    727.445605 |    788.988259 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
| 374 |    544.096694 |    789.687312 | Steven Coombs                                                                                                                                                         |
| 375 |     18.678019 |    230.085918 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                  |
| 376 |    569.683081 |    623.957189 | T. Michael Keesey                                                                                                                                                     |
| 377 |    639.994151 |    767.097854 | Iain Reid                                                                                                                                                             |
| 378 |    184.189305 |    779.953329 | Chris huh                                                                                                                                                             |
| 379 |    660.930319 |    718.503931 | Margot Michaud                                                                                                                                                        |
| 380 |    316.483468 |    473.831846 | Ville-Veikko Sinkkonen                                                                                                                                                |
| 381 |    493.697720 |    540.558817 | Matt Crook                                                                                                                                                            |
| 382 |     99.998265 |    663.895277 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 383 |    255.718757 |    459.888468 | NA                                                                                                                                                                    |
| 384 |    141.738543 |    244.637872 | Matt Crook                                                                                                                                                            |
| 385 |     86.675447 |    182.156230 | T. Michael Keesey                                                                                                                                                     |
| 386 |    874.872853 |    564.495230 | Ben Liebeskind                                                                                                                                                        |
| 387 |    128.192496 |    202.312013 | Matt Crook                                                                                                                                                            |
| 388 |    821.700549 |      6.832637 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 389 |     87.653697 |    621.081074 | Steven Coombs                                                                                                                                                         |
| 390 |    999.324230 |    539.410402 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                      |
| 391 |    360.776487 |    663.948230 | Carlos Cano-Barbacil                                                                                                                                                  |
| 392 |    739.323974 |    366.296790 | Joanna Wolfe                                                                                                                                                          |
| 393 |     87.937393 |    333.179153 | Zimices                                                                                                                                                               |
| 394 |    563.696972 |    483.018051 | Scott Hartman                                                                                                                                                         |
| 395 |    682.261997 |    164.802603 | Johan Lindgren, Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe                                                                                                  |
| 396 |    437.009067 |    317.179803 | Michelle Site                                                                                                                                                         |
| 397 |    546.354983 |    166.828071 | Anthony Caravaggi                                                                                                                                                     |
| 398 |    497.422100 |    290.882732 | T. Michael Keesey                                                                                                                                                     |
| 399 |    510.525548 |    267.918482 | Zimices                                                                                                                                                               |
| 400 |    577.970765 |    458.321576 | Frank Förster                                                                                                                                                         |
| 401 |    175.017259 |    486.227122 | Rene Martin                                                                                                                                                           |
| 402 |   1017.878757 |    262.830129 | Matt Wilkins                                                                                                                                                          |
| 403 |    823.719157 |     87.335237 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                     |
| 404 |    977.351903 |    178.817025 | John Gould (vectorized by T. Michael Keesey)                                                                                                                          |
| 405 |    710.231710 |    770.412488 | Scott Hartman                                                                                                                                                         |
| 406 |   1012.315817 |    382.872014 | Zimices                                                                                                                                                               |
| 407 |     37.558931 |    418.244960 | Ferran Sayol                                                                                                                                                          |
| 408 |    325.801914 |    487.097700 | NA                                                                                                                                                                    |
| 409 |    506.161473 |    560.245652 | Nicholas J. Czaplewski, vectorized by Zimices                                                                                                                         |
| 410 |    686.781129 |     63.338882 | Aviceda (vectorized by T. Michael Keesey)                                                                                                                             |
| 411 |    219.097977 |     45.322718 | Steven Traver                                                                                                                                                         |
| 412 |    642.550881 |    225.257915 | NA                                                                                                                                                                    |
| 413 |    239.739607 |     59.971612 | Carlos Cano-Barbacil                                                                                                                                                  |
| 414 |    519.828752 |      4.647282 | Margot Michaud                                                                                                                                                        |
| 415 |    258.530991 |    481.748557 | Xavier Giroux-Bougard                                                                                                                                                 |
| 416 |    349.226232 |    376.646808 | Abraão B. Leite                                                                                                                                                       |
| 417 |    992.897462 |     24.687718 | Steven Traver                                                                                                                                                         |
| 418 |    510.836069 |    399.478072 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 419 |     11.524275 |    272.024846 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 420 |    697.856070 |     45.294167 | Thibaut Brunet                                                                                                                                                        |
| 421 |    332.323562 |    360.156127 | NA                                                                                                                                                                    |
| 422 |    305.353121 |    220.743677 | Zimices                                                                                                                                                               |
| 423 |    653.074238 |    375.622290 | Gareth Monger                                                                                                                                                         |
| 424 |    702.858726 |    789.579666 | Gareth Monger                                                                                                                                                         |
| 425 |    360.043444 |    794.310477 | Zimices                                                                                                                                                               |
| 426 |     45.100513 |    192.046960 | Rebecca Groom                                                                                                                                                         |
| 427 |    635.355211 |    414.619516 | David Tana                                                                                                                                                            |
| 428 |    580.416122 |     60.206802 | Margot Michaud                                                                                                                                                        |
| 429 |     83.431250 |    587.670970 | Mathieu Basille                                                                                                                                                       |
| 430 |    173.720259 |    218.462674 | Christoph Schomburg                                                                                                                                                   |
| 431 |    838.686954 |    329.630146 | Espen Horn (model; vectorized by T. Michael Keesey from a photo by H. Zell)                                                                                           |
| 432 |    848.168921 |    664.508065 | Jagged Fang Designs                                                                                                                                                   |
| 433 |    252.808697 |    793.152156 | C. Camilo Julián-Caballero                                                                                                                                            |
| 434 |     42.555271 |    701.300798 | Emily Willoughby                                                                                                                                                      |
| 435 |    241.436670 |    246.714125 | Gareth Monger                                                                                                                                                         |
| 436 |    517.789967 |    442.910806 | Robert Gay                                                                                                                                                            |
| 437 |    795.876300 |    254.803961 | Chris Jennings (vectorized by A. Verrière)                                                                                                                            |
| 438 |    375.396414 |    462.485850 | FunkMonk                                                                                                                                                              |
| 439 |    741.570197 |    747.967889 | Zimices                                                                                                                                                               |
| 440 |    273.605639 |    692.857505 | Matt Crook                                                                                                                                                            |
| 441 |    115.149915 |    792.751655 | Scott Hartman                                                                                                                                                         |
| 442 |    244.654067 |    451.736083 | Tyler McCraney                                                                                                                                                        |
| 443 |    183.072516 |    681.557479 | Yan Wong                                                                                                                                                              |
| 444 |    987.946749 |    794.866629 | Katie S. Collins                                                                                                                                                      |
| 445 |    887.933459 |    338.513156 | David Orr                                                                                                                                                             |
| 446 |    412.294681 |    482.926886 | Steven Traver                                                                                                                                                         |
| 447 |    493.363739 |    410.402323 | Sarah Werning                                                                                                                                                         |
| 448 |    431.300088 |     33.489909 | Mathieu Pélissié                                                                                                                                                      |
| 449 |    555.455893 |    579.507293 | Becky Barnes                                                                                                                                                          |
| 450 |    584.704134 |    670.891265 | Burton Robert, USFWS                                                                                                                                                  |
| 451 |    652.539244 |    296.522445 | Margot Michaud                                                                                                                                                        |
| 452 |    622.222783 |    167.531575 | Mathew Stewart                                                                                                                                                        |
| 453 |    925.451706 |    622.119013 | L. Shyamal                                                                                                                                                            |
| 454 |    126.779229 |    291.251771 | Steven Traver                                                                                                                                                         |
| 455 |    241.521989 |    261.494751 | Kent Sorgon                                                                                                                                                           |
| 456 |     43.895234 |     72.516587 | Margot Michaud                                                                                                                                                        |
| 457 |    955.414051 |    519.055631 | Jagged Fang Designs                                                                                                                                                   |
| 458 |    393.904916 |    370.946229 | T. Michael Keesey                                                                                                                                                     |
| 459 |    232.934562 |    701.535242 | Chris huh                                                                                                                                                             |
| 460 |    466.121305 |    615.358032 | Ignacio Contreras                                                                                                                                                     |
| 461 |    986.564375 |    773.982196 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 462 |    378.523126 |    129.598326 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 463 |    964.801070 |     26.803617 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                        |
| 464 |    650.785570 |    389.761588 | Michelle Site                                                                                                                                                         |
| 465 |    876.808463 |    465.001394 | Steven Traver                                                                                                                                                         |
| 466 |    889.138074 |    777.749435 | Taro Maeda                                                                                                                                                            |
| 467 |    148.752703 |    469.842136 | Matt Crook                                                                                                                                                            |
| 468 |    467.675731 |    395.944466 | T. Michael Keesey (after Mauricio Antón)                                                                                                                              |
| 469 |     70.061759 |    644.931488 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                        |
| 470 |    472.628890 |    726.913136 | Steven Traver                                                                                                                                                         |
| 471 |     66.860813 |    506.288181 | Birgit Lang                                                                                                                                                           |
| 472 |    549.691961 |    498.017486 | Meyers Konversations-Lexikon 1897 (vectorized: Yan Wong)                                                                                                              |
| 473 |    862.217166 |    525.440822 | C. Camilo Julián-Caballero                                                                                                                                            |
| 474 |     95.589621 |    678.919668 | Michael Scroggie                                                                                                                                                      |
| 475 |    365.036205 |    615.824632 | NA                                                                                                                                                                    |
| 476 |     41.653914 |    547.952941 | Felix Vaux                                                                                                                                                            |
| 477 |    820.114576 |    316.593025 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                     |
| 478 |   1000.079526 |    585.994388 | Mr E? (vectorized by T. Michael Keesey)                                                                                                                               |
| 479 |     98.332365 |    183.833321 | L. Shyamal                                                                                                                                                            |
| 480 |    946.828808 |    393.412487 | Yan Wong                                                                                                                                                              |
| 481 |    172.358126 |    235.941548 | Zimices                                                                                                                                                               |
| 482 |     11.119249 |    659.604848 | Jake Warner                                                                                                                                                           |
| 483 |    870.774848 |    245.661547 | Chris huh                                                                                                                                                             |
| 484 |    929.780341 |    255.673331 | Zimices                                                                                                                                                               |
| 485 |    462.283434 |    558.675182 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 486 |    288.196675 |    668.701803 | Zimices                                                                                                                                                               |
| 487 |    512.165749 |    703.466405 | Scott Hartman                                                                                                                                                         |
| 488 |    708.079451 |    141.302322 | Zimices                                                                                                                                                               |
| 489 |    266.609188 |    128.209579 | Jagged Fang Designs                                                                                                                                                   |
| 490 |    187.816920 |    702.718835 | Collin Gross                                                                                                                                                          |
| 491 |    895.955832 |    187.574279 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 492 |   1012.826932 |    542.081673 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 493 |    956.865717 |     99.370666 | Zimices                                                                                                                                                               |
| 494 |    620.211819 |    432.875924 | Maxime Dahirel                                                                                                                                                        |
| 495 |    453.618519 |     15.787495 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                      |
| 496 |     15.254192 |     95.120291 | Jaime Headden, modified by T. Michael Keesey                                                                                                                          |
| 497 |    919.293685 |    795.192926 | Alex Slavenko                                                                                                                                                         |
| 498 |    658.846671 |     29.941073 | NA                                                                                                                                                                    |
| 499 |    275.155896 |    392.361338 | Abraão Leite                                                                                                                                                          |
| 500 |    518.956670 |    723.745595 | Robert Bruce Horsfall (vectorized by T. Michael Keesey)                                                                                                               |
| 501 |    936.150888 |    779.969673 | NA                                                                                                                                                                    |
| 502 |    514.982115 |    165.932361 | George Edward Lodge                                                                                                                                                   |
| 503 |    453.165205 |     59.488206 | Margot Michaud                                                                                                                                                        |
| 504 |    259.957086 |    780.249709 | Jan Sevcik (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey            |
| 505 |    311.085207 |    726.979035 | Margot Michaud                                                                                                                                                        |
| 506 |    383.797127 |    471.053691 | Birgit Lang                                                                                                                                                           |
| 507 |    984.577129 |     66.036914 | Sarah Alewijnse                                                                                                                                                       |
| 508 |    260.662819 |    447.768433 | Oscar Sanisidro                                                                                                                                                       |
| 509 |    978.898202 |    388.587782 | Michele Tobias                                                                                                                                                        |
| 510 |     21.415795 |    378.475604 | Margot Michaud                                                                                                                                                        |
| 511 |    503.113260 |     92.882573 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 512 |    238.952524 |    635.838773 | Andrew R. Gehrke                                                                                                                                                      |
| 513 |    646.519387 |    733.288248 | Ignacio Contreras                                                                                                                                                     |
| 514 |    639.626620 |    366.182838 | Ray Simpson (vectorized by T. Michael Keesey)                                                                                                                         |
| 515 |    287.300157 |    539.643807 | Roberto Díaz Sibaja                                                                                                                                                   |
| 516 |    420.968484 |    302.739179 | Matt Crook                                                                                                                                                            |
| 517 |    984.523901 |     77.898510 | Crystal Maier                                                                                                                                                         |
| 518 |    466.875205 |    155.748299 | Alexandre Vong                                                                                                                                                        |
| 519 |    884.576406 |    102.141377 | Steven Traver                                                                                                                                                         |
| 520 |    776.794322 |    700.690469 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                              |
| 521 |    544.472132 |    102.568523 | Ferran Sayol                                                                                                                                                          |
| 522 |    418.949553 |    131.705064 | NA                                                                                                                                                                    |
| 523 |    970.535178 |    382.323470 | Margot Michaud                                                                                                                                                        |
| 524 |    640.034981 |    278.432275 | Chris huh                                                                                                                                                             |
| 525 |    861.972499 |     78.294932 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 526 |    733.802163 |    733.458419 | Steven Traver                                                                                                                                                         |
| 527 |    952.846994 |    112.095067 | Margot Michaud                                                                                                                                                        |
| 528 |    976.039799 |    131.970886 | Rebecca Groom                                                                                                                                                         |
| 529 |    619.744712 |    654.352888 | Margot Michaud                                                                                                                                                        |
| 530 |    319.861678 |    212.690073 | Michael Scroggie                                                                                                                                                      |
| 531 |    261.038822 |    656.956012 | Matt Crook                                                                                                                                                            |
| 532 |     54.371735 |    633.282224 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 533 |    555.903635 |    766.545583 | NA                                                                                                                                                                    |
| 534 |     97.801964 |    144.831364 | Matt Crook                                                                                                                                                            |
| 535 |     14.715841 |     54.694146 | Chris huh                                                                                                                                                             |
| 536 |    964.253609 |    616.974870 | Zimices                                                                                                                                                               |
| 537 |    483.385520 |     10.415356 | Milton Tan                                                                                                                                                            |
| 538 |     91.546059 |    257.291454 | Noah Schlottman                                                                                                                                                       |
| 539 |    678.374388 |    168.862143 | Markus A. Grohme                                                                                                                                                      |
| 540 |    339.809634 |    786.871442 | Ludwik Gasiorowski                                                                                                                                                    |
| 541 |    251.616325 |    151.940410 | Gareth Monger                                                                                                                                                         |
| 542 |    166.203869 |    685.673158 | Gareth Monger                                                                                                                                                         |
| 543 |      7.503243 |    674.590002 | Matus Valach                                                                                                                                                          |
| 544 |    422.710336 |     49.272917 | Zimices                                                                                                                                                               |
| 545 |     78.714784 |    630.580820 | Steven Traver                                                                                                                                                         |
| 546 |     32.294130 |    386.868327 | Thibaut Brunet                                                                                                                                                        |
| 547 |    780.562840 |    523.851328 | Scott Hartman                                                                                                                                                         |
| 548 |    415.421750 |    499.950405 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 549 |    693.819320 |    561.850487 | Tasman Dixon                                                                                                                                                          |
| 550 |    127.632556 |    191.596608 | Matt Crook                                                                                                                                                            |
| 551 |    910.951974 |    622.058145 | Gareth Monger                                                                                                                                                         |
| 552 |    139.949011 |    768.920634 | Joanna Wolfe                                                                                                                                                          |
| 553 |    143.675034 |    195.332289 | Kamil S. Jaron                                                                                                                                                        |
| 554 |   1008.460488 |    642.666817 | Yan Wong from drawing by Joseph Smit                                                                                                                                  |
| 555 |    499.770385 |     72.148112 | Sharon Wegner-Larsen                                                                                                                                                  |
| 556 |    711.387349 |    379.189632 | Margot Michaud                                                                                                                                                        |
| 557 |      8.335012 |    118.244389 | Maija Karala                                                                                                                                                          |
| 558 |   1011.303413 |     13.003207 | Carlos Cano-Barbacil                                                                                                                                                  |
| 559 |    294.694487 |    501.779031 | Zimices                                                                                                                                                               |
| 560 |     88.313322 |    478.413678 | xgirouxb                                                                                                                                                              |
| 561 |     21.751076 |    295.327483 | Birgit Lang                                                                                                                                                           |
| 562 |    676.396961 |    222.750883 | Zimices                                                                                                                                                               |
| 563 |    879.706937 |    168.812343 | Emily Willoughby                                                                                                                                                      |
| 564 |    684.949779 |     52.997492 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 565 |    739.946608 |    154.086330 | Sarah Werning                                                                                                                                                         |
| 566 |    117.517728 |    393.791374 | Steven Traver                                                                                                                                                         |
| 567 |    953.963100 |    151.977997 | Dr. Thomas G. Barnes, USFWS                                                                                                                                           |
| 568 |    137.018021 |    389.471118 | Scott Hartman                                                                                                                                                         |
| 569 |    211.246131 |    665.235527 | David Orr                                                                                                                                                             |
| 570 |    640.816422 |    655.029247 | Matt Crook                                                                                                                                                            |
| 571 |    424.140684 |    725.076568 | NA                                                                                                                                                                    |
| 572 |    508.722571 |    576.710507 | Christoph Schomburg                                                                                                                                                   |
| 573 |    490.146202 |    573.222480 | Dmitry Bogdanov                                                                                                                                                       |
| 574 |    653.017588 |    589.409418 | Carlos Cano-Barbacil                                                                                                                                                  |
| 575 |    581.070493 |    790.716734 | Steven Traver                                                                                                                                                         |
| 576 |    976.845447 |    690.927400 | NA                                                                                                                                                                    |
| 577 |    955.060646 |    279.932950 | Tauana J. Cunha                                                                                                                                                       |
| 578 |    778.143336 |     92.597968 | Milton Tan                                                                                                                                                            |
| 579 |     15.424409 |    482.806568 | Steven Traver                                                                                                                                                         |
| 580 |     13.658360 |    716.055333 | Michael Scroggie                                                                                                                                                      |
| 581 |     71.895117 |    134.829311 | Yan Wong                                                                                                                                                              |
| 582 |    470.092690 |     83.715261 | Zimices                                                                                                                                                               |
| 583 |     69.629538 |    625.564516 | T. Tischler                                                                                                                                                           |
| 584 |    775.869561 |    784.635567 | Matt Crook                                                                                                                                                            |
| 585 |    759.490489 |     93.705138 | L. Shyamal                                                                                                                                                            |
| 586 |    156.466601 |    373.316636 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 587 |    267.225688 |    415.423662 | Baheerathan Murugavel                                                                                                                                                 |
| 588 |    724.196963 |     76.217223 | Melissa Broussard                                                                                                                                                     |
| 589 |    572.623792 |    634.201605 | Andrew A. Farke                                                                                                                                                       |
| 590 |    808.325212 |     67.770143 | Margot Michaud                                                                                                                                                        |
| 591 |     61.187561 |    241.773214 | Gareth Monger                                                                                                                                                         |
| 592 |     89.728567 |    505.390358 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 593 |    946.705364 |    453.950463 | Campbell Fleming                                                                                                                                                      |
| 594 |     25.047636 |    126.856683 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 595 |    382.363595 |    759.982655 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                                        |
| 596 |     81.572845 |    598.256543 | Scott Hartman                                                                                                                                                         |
| 597 |    445.864183 |    774.028831 | Birgit Lang                                                                                                                                                           |
| 598 |    973.550450 |      6.236906 | Zimices                                                                                                                                                               |
| 599 |    160.351990 |    479.629597 | Ignacio Contreras                                                                                                                                                     |
| 600 |    400.025596 |    495.764338 | Anthony Caravaggi                                                                                                                                                     |
| 601 |    996.826313 |    549.309424 | Carlos Cano-Barbacil                                                                                                                                                  |
| 602 |    223.523441 |    689.811891 | xgirouxb                                                                                                                                                              |
| 603 |    775.864670 |    281.147949 | NA                                                                                                                                                                    |
| 604 |    517.725133 |    189.321762 | Tasman Dixon                                                                                                                                                          |
| 605 |    229.321064 |     96.791915 | Steven Traver                                                                                                                                                         |
| 606 |    593.887573 |    645.197453 | Gareth Monger                                                                                                                                                         |
| 607 |    892.355296 |    397.706528 | Sarah Werning                                                                                                                                                         |
| 608 |    285.062438 |    410.999798 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 609 |    509.322522 |    293.106786 | T. Michael Keesey (vectorization); Yves Bousquet (photography)                                                                                                        |
| 610 |    298.597349 |      8.739887 | Scott Reid                                                                                                                                                            |
| 611 |    166.388548 |    278.192259 | Dave Angelini                                                                                                                                                         |
| 612 |    711.540101 |     96.608695 | Scott Hartman                                                                                                                                                         |
| 613 |    156.174611 |    264.143165 | Duane Raver (vectorized by T. Michael Keesey)                                                                                                                         |
| 614 |    422.049962 |    732.974716 | Tasman Dixon                                                                                                                                                          |
| 615 |    608.628097 |      7.378653 | Margot Michaud                                                                                                                                                        |
| 616 |    528.458901 |    481.233742 | Alexandre Vong                                                                                                                                                        |
| 617 |    129.901119 |    344.364936 | Chase Brownstein                                                                                                                                                      |
| 618 |    881.153265 |    549.928903 | Yan Wong                                                                                                                                                              |
| 619 |    306.077655 |    433.571329 | Noah Schlottman, photo from Casey Dunn                                                                                                                                |
| 620 |    826.557084 |    764.230933 | Shyamal                                                                                                                                                               |
| 621 |    931.752690 |    417.124703 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 622 |     47.436234 |    105.083122 | Steven Traver                                                                                                                                                         |
| 623 |    134.978907 |    271.417134 | Ferran Sayol                                                                                                                                                          |
| 624 |    999.395008 |    758.473297 | Matt Crook                                                                                                                                                            |
| 625 |    511.649241 |    672.642317 | Birgit Lang                                                                                                                                                           |
| 626 |    974.837802 |    427.833014 | Sam Fraser-Smith (vectorized by T. Michael Keesey)                                                                                                                    |
| 627 |    618.607447 |    574.801806 | Martin R. Smith                                                                                                                                                       |
| 628 |    262.464262 |    104.691548 | Tasman Dixon                                                                                                                                                          |
| 629 |    480.205884 |    305.250730 | Ferran Sayol                                                                                                                                                          |
| 630 |    860.318109 |    349.124528 | Abraão Leite                                                                                                                                                          |
| 631 |    807.498345 |    768.799981 | FunkMonk                                                                                                                                                              |
| 632 |    991.313659 |     11.414816 | C. Camilo Julián-Caballero                                                                                                                                            |
| 633 |    951.798010 |    673.089778 | Tasman Dixon                                                                                                                                                          |
| 634 |    960.899260 |    362.938633 | NA                                                                                                                                                                    |
| 635 |    100.597813 |    624.211387 | Carlos Cano-Barbacil                                                                                                                                                  |
| 636 |    174.758830 |    466.758730 | Margot Michaud                                                                                                                                                        |
| 637 |     47.009726 |    400.783975 | Gareth Monger                                                                                                                                                         |
| 638 |    702.199349 |    150.287246 | Matt Crook                                                                                                                                                            |
| 639 |    523.987781 |    239.925215 | Steven Traver                                                                                                                                                         |
| 640 |    120.842930 |    482.025194 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 641 |    721.801363 |    712.128393 | Roberto Díaz Sibaja                                                                                                                                                   |
| 642 |    197.495192 |     83.064314 | L. Shyamal                                                                                                                                                            |
| 643 |    996.512917 |    112.307161 | Margot Michaud                                                                                                                                                        |
| 644 |    105.847885 |    749.275142 | Zimices                                                                                                                                                               |
| 645 |    896.633028 |    462.040165 | Sarah Werning                                                                                                                                                         |
| 646 |     57.943591 |    792.133734 | Martin Kevil                                                                                                                                                          |
| 647 |    936.546735 |    601.436529 | Matt Crook                                                                                                                                                            |
| 648 |    412.968390 |    592.349475 | Matt Crook                                                                                                                                                            |
| 649 |    501.285343 |    518.488410 | Jon Hill (Photo by DickDaniels: <http://en.wikipedia.org/wiki/File:Green_Woodhoopoe_RWD7.jpg>)                                                                        |
| 650 |    484.607635 |     57.961352 | Caleb M. Brown                                                                                                                                                        |
| 651 |    537.866380 |    413.042841 | Ferran Sayol                                                                                                                                                          |
| 652 |    274.235041 |    721.139366 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 653 |     94.825703 |    328.283427 | Jagged Fang Designs                                                                                                                                                   |
| 654 |     12.980655 |    204.483609 | Maija Karala                                                                                                                                                          |
| 655 |   1013.506834 |    614.793828 | Joanna Wolfe                                                                                                                                                          |
| 656 |     78.999543 |    720.915447 | Jaime Headden                                                                                                                                                         |
| 657 |     89.123690 |    348.499482 | Kanchi Nanjo                                                                                                                                                          |
| 658 |    819.740343 |    779.844482 | Ferran Sayol                                                                                                                                                          |
| 659 |    692.110630 |    572.303399 | Sharon Wegner-Larsen                                                                                                                                                  |
| 660 |    199.649471 |    312.078274 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
| 661 |    573.536751 |    752.239665 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 662 |    337.771051 |    431.593907 | Beth Reinke                                                                                                                                                           |
| 663 |    265.102871 |    223.617594 | Steven Traver                                                                                                                                                         |
| 664 |    816.108962 |    179.948541 | Jagged Fang Designs                                                                                                                                                   |
| 665 |    673.496051 |    650.938033 | Chris Hay                                                                                                                                                             |
| 666 |    985.520244 |     38.950656 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                                     |
| 667 |    694.270834 |      1.554981 | NA                                                                                                                                                                    |
| 668 |     10.206093 |     61.669139 | Mykle Hoban                                                                                                                                                           |
| 669 |    283.403558 |    437.320949 | Chris huh                                                                                                                                                             |
| 670 |    658.376646 |    233.774926 | T. Michael Keesey                                                                                                                                                     |
| 671 |    395.356667 |    728.387601 | Felix Vaux                                                                                                                                                            |
| 672 |    158.400088 |    221.757409 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 673 |    236.615883 |    460.889202 | Tess Linden                                                                                                                                                           |
| 674 |     52.445991 |    523.759482 | NA                                                                                                                                                                    |
| 675 |    873.628746 |    452.632060 | Zimices                                                                                                                                                               |
| 676 |    615.928879 |    409.577015 | Gareth Monger                                                                                                                                                         |
| 677 |    519.870867 |    624.907723 | Aleksey Nagovitsyn (vectorized by T. Michael Keesey)                                                                                                                  |
| 678 |    638.817730 |    774.330522 | Chris huh                                                                                                                                                             |
| 679 |    793.762380 |    192.519476 | Lily Hughes                                                                                                                                                           |
| 680 |    876.181683 |    726.397083 | Archaeodontosaurus (vectorized by T. Michael Keesey)                                                                                                                  |
| 681 |    219.752916 |    792.600878 | C. Camilo Julián-Caballero                                                                                                                                            |
| 682 |    889.200903 |    643.762425 | Ingo Braasch                                                                                                                                                          |
| 683 |    909.564986 |    729.643198 | NA                                                                                                                                                                    |
| 684 |    731.420710 |    132.592342 | T. Michael Keesey                                                                                                                                                     |
| 685 |     13.925651 |    548.981790 | Matt Crook                                                                                                                                                            |
| 686 |    590.420994 |    209.697387 | Becky Barnes                                                                                                                                                          |
| 687 |    611.719847 |    217.492377 | Qiang Ou                                                                                                                                                              |
| 688 |    678.508612 |     19.253580 | Ferran Sayol                                                                                                                                                          |
| 689 |    560.416344 |    188.355103 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 690 |   1016.859205 |    449.816241 | George Edward Lodge (vectorized by T. Michael Keesey)                                                                                                                 |
| 691 |    398.988414 |    409.237295 | Chris huh                                                                                                                                                             |
| 692 |    476.831850 |    284.472247 | Margot Michaud                                                                                                                                                        |
| 693 |    885.802130 |     86.423407 | Joanna Wolfe                                                                                                                                                          |
| 694 |    649.552080 |     11.357501 | Yan Wong                                                                                                                                                              |
| 695 |    779.718090 |    311.016243 | Matt Crook                                                                                                                                                            |
| 696 |    443.096405 |    561.541646 | Ignacio Contreras                                                                                                                                                     |
| 697 |    478.897440 |    571.966971 | Margot Michaud                                                                                                                                                        |
| 698 |    875.604762 |    392.630124 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 699 |   1012.970129 |    710.360337 | NA                                                                                                                                                                    |
| 700 |    313.690756 |    105.678738 | Chuanixn Yu                                                                                                                                                           |
| 701 |    999.631472 |    512.801480 | Steven Traver                                                                                                                                                         |
| 702 |    533.831885 |    366.336614 | Jimmy Bernot                                                                                                                                                          |
| 703 |    350.812827 |    726.088528 | Sharon Wegner-Larsen                                                                                                                                                  |
| 704 |    925.357501 |    366.569622 | Arthur S. Brum                                                                                                                                                        |
| 705 |    964.017684 |    740.480252 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 706 |    438.701218 |    511.237596 | Peter Coxhead                                                                                                                                                         |
| 707 |    829.720835 |    685.254955 | Margot Michaud                                                                                                                                                        |
| 708 |    282.529015 |    217.946564 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 709 |    207.482103 |    546.786916 | Margot Michaud                                                                                                                                                        |
| 710 |    460.294744 |    506.462207 | Harold N Eyster                                                                                                                                                       |
| 711 |    245.004683 |    104.963336 | Carlos Cano-Barbacil                                                                                                                                                  |
| 712 |   1015.835265 |     29.359378 | Jagged Fang Designs                                                                                                                                                   |
| 713 |    413.412497 |    322.203924 | Mihai Dragos (vectorized by T. Michael Keesey)                                                                                                                        |
| 714 |    474.907254 |    168.187546 | Matt Crook                                                                                                                                                            |
| 715 |    328.355383 |    272.147023 | Scott Hartman                                                                                                                                                         |
| 716 |    956.350352 |    261.708760 | Dave Souza (vectorized by T. Michael Keesey)                                                                                                                          |
| 717 |     48.141196 |    502.532981 | Chris huh                                                                                                                                                             |
| 718 |     10.523795 |    328.704373 | John Conway                                                                                                                                                           |
| 719 |     59.767254 |    184.525645 | NA                                                                                                                                                                    |
| 720 |    595.519195 |    379.639157 | Chase Brownstein                                                                                                                                                      |
| 721 |    438.311593 |    579.037700 | Steven Traver                                                                                                                                                         |
| 722 |    120.800080 |     18.312450 | Markus A. Grohme                                                                                                                                                      |
| 723 |    607.854058 |    135.827067 | Zimices                                                                                                                                                               |
| 724 |    666.203867 |    183.904139 | Gareth Monger                                                                                                                                                         |
| 725 |    896.810267 |    632.441815 | Margot Michaud                                                                                                                                                        |
| 726 |    540.066760 |    179.956105 | Ignacio Contreras                                                                                                                                                     |
| 727 |    675.723111 |    395.679255 | Scott Hartman                                                                                                                                                         |
| 728 |    613.191770 |     64.862592 | Matt Crook                                                                                                                                                            |
| 729 |   1001.822779 |    373.948860 | Marcos Pérez-Losada, Jens T. Høeg & Keith A. Crandall                                                                                                                 |
| 730 |    128.819017 |    753.168547 | Margot Michaud                                                                                                                                                        |
| 731 |    154.635152 |    103.026593 | Archaeodontosaurus (vectorized by T. Michael Keesey)                                                                                                                  |
| 732 |      6.974380 |    766.093919 | Gareth Monger                                                                                                                                                         |
| 733 |    567.611580 |    204.943517 | Zimices                                                                                                                                                               |
| 734 |    863.515839 |    531.833365 | Zimices                                                                                                                                                               |
| 735 |     34.755099 |    509.966838 | L.M. Davalos                                                                                                                                                          |
| 736 |    343.324096 |    738.663993 | Matt Crook                                                                                                                                                            |
| 737 |    967.761664 |    766.826678 | Katie S. Collins                                                                                                                                                      |
| 738 |    472.678963 |    180.579055 | T. Michael Keesey (vectorization) and Tony Hisgett (photography)                                                                                                      |
| 739 |    976.115605 |    586.028346 | Gareth Monger                                                                                                                                                         |
| 740 |    829.136969 |     35.633460 | NA                                                                                                                                                                    |
| 741 |    973.992968 |    196.301620 | Tyler McCraney                                                                                                                                                        |
| 742 |    638.265333 |    234.217616 | Kai R. Caspar                                                                                                                                                         |
| 743 |    764.875675 |     86.461569 | Steven Traver                                                                                                                                                         |
| 744 |    146.221130 |    487.102740 | Tasman Dixon                                                                                                                                                          |
| 745 |    837.151850 |    387.078307 | Margot Michaud                                                                                                                                                        |
| 746 |    801.983548 |    158.374738 | Andrew Farke and Joseph Sertich                                                                                                                                       |
| 747 |    403.032250 |    444.697720 | NA                                                                                                                                                                    |
| 748 |     53.615329 |    134.719249 | T. Michael Keesey                                                                                                                                                     |
| 749 |    670.637927 |    324.907496 | Jagged Fang Designs                                                                                                                                                   |
| 750 |    377.691079 |    426.326216 | Jagged Fang Designs                                                                                                                                                   |
| 751 |    574.906156 |    656.701927 | Chuanixn Yu                                                                                                                                                           |
| 752 |    334.386668 |    378.642029 | Emily Willoughby                                                                                                                                                      |
| 753 |     80.187117 |    743.808976 | Gareth Monger                                                                                                                                                         |
| 754 |    528.779302 |     25.339421 | Sarah Werning                                                                                                                                                         |
| 755 |    812.244586 |    172.052346 | Ignacio Contreras                                                                                                                                                     |
| 756 |    915.833512 |    157.414737 | Jaime Headden                                                                                                                                                         |
| 757 |     92.299306 |     29.850216 | Scott Hartman                                                                                                                                                         |
| 758 |    981.058510 |    746.805648 | Steven Traver                                                                                                                                                         |
| 759 |    594.629104 |     98.873607 | Tasman Dixon                                                                                                                                                          |
| 760 |    227.761751 |    695.629965 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
| 761 |    758.691432 |    315.152651 | Steven Traver                                                                                                                                                         |
| 762 |    849.202574 |    140.842201 | Armin Reindl                                                                                                                                                          |
| 763 |    799.879904 |    228.775626 | Mariana Ruiz (vectorized by T. Michael Keesey)                                                                                                                        |
| 764 |     77.107927 |    170.346513 | Roberto Díaz Sibaja                                                                                                                                                   |
| 765 |    460.592262 |    139.984287 | Frank Förster (based on a picture by Jerry Kirkhart; modified by T. Michael Keesey)                                                                                   |
| 766 |    662.271544 |    682.089714 | Jagged Fang Designs                                                                                                                                                   |
| 767 |    995.893634 |    745.353149 | Jagged Fang Designs                                                                                                                                                   |
| 768 |     27.133535 |     73.036342 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 769 |    958.044812 |    380.220236 | Gareth Monger                                                                                                                                                         |
| 770 |    986.468489 |    173.679371 | NA                                                                                                                                                                    |
| 771 |    383.704768 |    788.240163 | Zimices                                                                                                                                                               |
| 772 |    913.886641 |    428.811006 | Alexandre Vong                                                                                                                                                        |
| 773 |    329.615151 |    493.838576 | Smokeybjb                                                                                                                                                             |
| 774 |    707.190463 |    643.977628 | V. Deepak                                                                                                                                                             |
| 775 |    862.531721 |     42.040505 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 776 |   1002.302694 |    225.281259 | David Orr                                                                                                                                                             |
| 777 |    251.129261 |    771.637812 | Gareth Monger                                                                                                                                                         |
| 778 |    201.000863 |    203.757785 | Birgit Lang                                                                                                                                                           |
| 779 |    567.146321 |    423.817786 | Inessa Voet                                                                                                                                                           |
| 780 |    116.599209 |    180.663785 | Ferran Sayol                                                                                                                                                          |
| 781 |    719.178028 |    113.927134 | Matt Crook                                                                                                                                                            |
| 782 |     23.026947 |    141.388999 | Steven Traver                                                                                                                                                         |
| 783 |    418.385929 |    160.672435 | Zimices                                                                                                                                                               |
| 784 |     70.929555 |    689.333145 | Margot Michaud                                                                                                                                                        |
| 785 |     16.555131 |    357.214904 | Becky Barnes                                                                                                                                                          |
| 786 |    262.895397 |    631.604526 | Steven Traver                                                                                                                                                         |
| 787 |     93.363538 |    429.271235 | T. Michael Keesey                                                                                                                                                     |
| 788 |    428.324041 |    482.717434 | T. Michael Keesey                                                                                                                                                     |
| 789 |    344.867470 |    150.617332 | Roberto Díaz Sibaja                                                                                                                                                   |
| 790 |    627.733961 |    790.790943 | Steven Haddock • Jellywatch.org                                                                                                                                       |
| 791 |    474.746195 |    301.041236 | Kamil S. Jaron                                                                                                                                                        |
| 792 |    236.001124 |    490.255948 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 793 |    632.304271 |    310.104060 | Collin Gross                                                                                                                                                          |
| 794 |     80.080354 |    790.408759 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 795 |    300.726342 |    551.426517 | Karkemish (vectorized by T. Michael Keesey)                                                                                                                           |
| 796 |    455.656730 |     47.782286 | Walter Vladimir                                                                                                                                                       |
| 797 |    556.817561 |    746.691271 | Jagged Fang Designs                                                                                                                                                   |
| 798 |    498.198246 |    752.573635 | Ben Liebeskind                                                                                                                                                        |
| 799 |    349.033875 |    360.993412 | Ferran Sayol                                                                                                                                                          |
| 800 |    150.634600 |    124.803317 | Margot Michaud                                                                                                                                                        |
| 801 |     13.631228 |    259.383332 | Matt Crook                                                                                                                                                            |
| 802 |    393.449497 |    475.067722 | Margot Michaud                                                                                                                                                        |
| 803 |     29.990931 |    448.583696 | Margot Michaud                                                                                                                                                        |
| 804 |    957.876089 |    236.576410 | Matt Crook                                                                                                                                                            |
| 805 |   1012.440483 |    576.314387 | Ferran Sayol                                                                                                                                                          |
| 806 |    533.455346 |    120.865537 | Neil Kelley                                                                                                                                                           |
| 807 |    935.905603 |    351.884677 | Anthony Caravaggi                                                                                                                                                     |
| 808 |    140.754416 |    459.006713 | Katie S. Collins                                                                                                                                                      |
| 809 |     85.104482 |    609.483501 | Ferran Sayol                                                                                                                                                          |
| 810 |    496.130848 |    362.394820 | Steven Traver                                                                                                                                                         |
| 811 |    995.029740 |    503.554902 | Sarah Werning                                                                                                                                                         |
| 812 |    513.613384 |    541.764628 | (after Spotila 2004)                                                                                                                                                  |
| 813 |    506.849562 |    757.940940 | Andrew A. Farke                                                                                                                                                       |
| 814 |    915.895986 |    760.009635 | Timothy Knepp (vectorized by T. Michael Keesey)                                                                                                                       |
| 815 |    881.752866 |     39.988859 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 816 |      6.566979 |    310.391109 | Crystal Maier                                                                                                                                                         |
| 817 |     52.068069 |    314.155081 | Steven Traver                                                                                                                                                         |
| 818 |    853.362398 |    766.852729 | Gareth Monger                                                                                                                                                         |
| 819 |    439.945597 |    493.981144 | Maija Karala                                                                                                                                                          |
| 820 |    571.426173 |     10.562869 | Dave Angelini                                                                                                                                                         |
| 821 |    506.023368 |    724.070255 | Steven Traver                                                                                                                                                         |
| 822 |    490.344876 |    521.904599 | Lukasiniho                                                                                                                                                            |
| 823 |    848.714056 |     42.987964 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 824 |    677.469542 |    293.953075 | Collin Gross                                                                                                                                                          |
| 825 |     16.774725 |    533.379701 | Smokeybjb                                                                                                                                                             |
| 826 |   1005.521012 |    488.131249 | Christoph Schomburg                                                                                                                                                   |
| 827 |    174.516048 |    714.010945 | NA                                                                                                                                                                    |
| 828 |    230.607911 |    199.275847 | Birgit Lang                                                                                                                                                           |
| 829 |    907.178824 |    606.557143 | Konsta Happonen                                                                                                                                                       |
| 830 |    364.059941 |    647.467997 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 831 |    483.868013 |     69.225548 | Matt Crook                                                                                                                                                            |
| 832 |    295.372360 |    465.800348 | Jimmy Bernot                                                                                                                                                          |
| 833 |    358.002602 |    483.977973 | Chris huh                                                                                                                                                             |
| 834 |    286.434635 |    261.712821 | Margot Michaud                                                                                                                                                        |
| 835 |    610.408408 |    682.480972 | NA                                                                                                                                                                    |
| 836 |    509.121058 |    347.975748 | Scott Hartman                                                                                                                                                         |
| 837 |    924.698981 |    445.934776 | Anthony Caravaggi                                                                                                                                                     |
| 838 |    602.041830 |    153.989358 | Ferran Sayol                                                                                                                                                          |
| 839 |    904.043110 |    670.272374 | Matt Crook                                                                                                                                                            |
| 840 |    655.879112 |    315.838424 | Zimices                                                                                                                                                               |
| 841 |   1010.956475 |    745.259584 | Katie S. Collins                                                                                                                                                      |
| 842 |    852.353475 |    160.905145 | Tracy A. Heath                                                                                                                                                        |
| 843 |    544.220005 |      9.550260 | Kai R. Caspar                                                                                                                                                         |
| 844 |    141.550176 |    477.857305 | T. Michael Keesey (after Mauricio Antón)                                                                                                                              |
| 845 |     57.701690 |    419.497871 | E. D. Cope (modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel)                                                                                      |
| 846 |    724.656690 |    541.235349 | Cesar Julian                                                                                                                                                          |
| 847 |    111.362114 |     36.048028 | Birgit Lang                                                                                                                                                           |
| 848 |    589.388799 |    187.963749 | Lauren Anderson                                                                                                                                                       |
| 849 |    495.817789 |    372.568520 | Frederick William Frohawk (vectorized by T. Michael Keesey)                                                                                                           |
| 850 |    216.161849 |     30.069050 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                           |
| 851 |    839.292124 |     22.022029 | Andrés Sánchez                                                                                                                                                        |
| 852 |    188.870447 |    347.326916 | Francesca Belem Lopes Palmeira                                                                                                                                        |
| 853 |     94.014228 |    488.221590 | A. R. McCulloch (vectorized by T. Michael Keesey)                                                                                                                     |
| 854 |     24.656219 |    119.324721 | Caleb M. Brown                                                                                                                                                        |
| 855 |    683.124186 |    235.943148 | Brockhaus and Efron                                                                                                                                                   |
| 856 |    264.084887 |    326.788529 | Dean Schnabel                                                                                                                                                         |
| 857 |     21.888108 |    210.623742 | Stuart Humphries                                                                                                                                                      |
| 858 |    527.208912 |    784.269678 | Mali’o Kodis, photograph by “Wildcat Dunny” (<http://www.flickr.com/people/wildcat_dunny/>)                                                                           |
| 859 |    775.025635 |    272.187093 | NA                                                                                                                                                                    |
| 860 |    910.861677 |    745.313639 | Margot Michaud                                                                                                                                                        |
| 861 |    221.153379 |    181.067284 | Farelli (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
| 862 |    396.179183 |    461.941966 | Maija Karala                                                                                                                                                          |
| 863 |    918.086853 |    716.982112 | Zimices                                                                                                                                                               |
| 864 |     74.538455 |    234.054284 | Margot Michaud                                                                                                                                                        |
| 865 |    184.713312 |    267.055288 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 866 |    509.339097 |    206.057117 | Ferran Sayol                                                                                                                                                          |
| 867 |    640.351960 |    551.451681 | Shyamal                                                                                                                                                               |
| 868 |    396.183240 |    383.115746 | Scott Hartman                                                                                                                                                         |
| 869 |    787.135409 |     76.473882 | Jagged Fang Designs                                                                                                                                                   |
| 870 |    338.785171 |    499.371519 | Chris huh                                                                                                                                                             |
| 871 |    126.434030 |    421.949565 | Gareth Monger                                                                                                                                                         |
| 872 |   1016.221377 |    283.178694 | Milton Tan                                                                                                                                                            |
| 873 |    848.462966 |    395.781943 | B. Duygu Özpolat                                                                                                                                                      |
| 874 |     12.477619 |    105.013368 | Sean McCann                                                                                                                                                           |
| 875 |    244.362684 |    515.002633 | Zimices                                                                                                                                                               |
| 876 |    376.027604 |    360.462453 | Andreas Preuss / marauder                                                                                                                                             |
| 877 |    829.267938 |    523.316445 | Mo Hassan                                                                                                                                                             |
| 878 |    999.360638 |    251.373002 | Beth Reinke                                                                                                                                                           |
| 879 |    108.778839 |     19.891914 | Ferran Sayol                                                                                                                                                          |
| 880 |     39.147027 |    757.579178 | Dean Schnabel                                                                                                                                                         |
| 881 |    359.473418 |    285.197968 | T. Michael Keesey                                                                                                                                                     |
| 882 |    500.778343 |    428.953208 | Joanna Wolfe                                                                                                                                                          |
| 883 |    705.562939 |    304.049448 | B. Duygu Özpolat                                                                                                                                                      |
| 884 |    810.512899 |     73.192373 | Zimices                                                                                                                                                               |
| 885 |    998.422112 |    444.754209 | Joanna Wolfe                                                                                                                                                          |
| 886 |    625.148978 |    708.945591 | Andrew A. Farke                                                                                                                                                       |
| 887 |    387.782371 |    703.145376 | Gareth Monger                                                                                                                                                         |
| 888 |     22.283365 |    693.174510 | Scott Hartman                                                                                                                                                         |
| 889 |    760.135227 |    514.273920 | Margot Michaud                                                                                                                                                        |
| 890 |    139.575457 |    118.035106 | Markus A. Grohme                                                                                                                                                      |
| 891 |    552.984244 |    432.323608 | Chris huh                                                                                                                                                             |
| 892 |    997.922980 |    283.322262 | Chuanixn Yu                                                                                                                                                           |
| 893 |    989.524063 |    604.041051 | Matt Crook                                                                                                                                                            |
| 894 |    777.322834 |    185.946492 | Jessica Anne Miller                                                                                                                                                   |
| 895 |    596.678032 |    689.810909 | Yan Wong from photo by Denes Emoke                                                                                                                                    |
| 896 |    941.518748 |    440.844489 | NA                                                                                                                                                                    |
| 897 |    583.121319 |    464.674592 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                           |
| 898 |    845.417999 |    711.295651 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 899 |    897.927696 |    542.529515 | Mali’o Kodis, photograph by Melissa Frey                                                                                                                              |
| 900 |    843.168630 |    338.802917 | T. Michael Keesey                                                                                                                                                     |
| 901 |    597.544811 |    418.095577 | Kamil S. Jaron                                                                                                                                                        |
| 902 |    291.395155 |    347.307074 | Kamil S. Jaron                                                                                                                                                        |
| 903 |    308.437987 |      7.937918 | Margot Michaud                                                                                                                                                        |
| 904 |    886.987762 |    162.839962 | Zimices                                                                                                                                                               |
| 905 |    566.853478 |    247.281008 | Michael Scroggie                                                                                                                                                      |
| 906 |    857.910201 |    713.788779 | Matt Crook                                                                                                                                                            |
| 907 |    553.988227 |    785.688882 | Markus A. Grohme                                                                                                                                                      |
| 908 |    292.630543 |     25.746120 | Chris huh                                                                                                                                                             |
| 909 |    343.385888 |    623.675665 | FJDegrange                                                                                                                                                            |
| 910 |    212.768148 |     54.119485 | Ingo Braasch                                                                                                                                                          |
| 911 |    271.805692 |    557.720031 | Felix Vaux                                                                                                                                                            |
| 912 |    261.838084 |    619.793667 | Nobu Tamura                                                                                                                                                           |
| 913 |      7.823753 |    133.095903 | M Hutchinson                                                                                                                                                          |
| 914 |   1006.183619 |    293.374119 | Jagged Fang Designs                                                                                                                                                   |
| 915 |    150.429575 |     47.857124 | Ferran Sayol                                                                                                                                                          |
| 916 |    412.578246 |    292.797326 | Zimices                                                                                                                                                               |
| 917 |    260.085068 |    492.133139 | Tracy A. Heath                                                                                                                                                        |
| 918 |    432.374066 |    590.883410 | Jay Matternes (modified by T. Michael Keesey)                                                                                                                         |
| 919 |    161.630044 |    501.682419 | Gareth Monger                                                                                                                                                         |

    #> Your tweet has been posted!
