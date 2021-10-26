
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

Xavier Giroux-Bougard, Zimices, Alex Slavenko, Ferran Sayol, Gareth
Monger, Lafage, Steven Traver, Emily Willoughby, Nobu Tamura (vectorized
by T. Michael Keesey), Scott Hartman, Auckland Museum and T. Michael
Keesey, Xavier A. Jenkins, Gabriel Ugueto, Mason McNair, Terpsichores,
Margot Michaud, Stephen O’Connor (vectorized by T. Michael Keesey),
Jaime Headden, Matt Crook, Campbell Fleming, Robbie N. Cada (vectorized
by T. Michael Keesey), Pearson Scott Foresman (vectorized by T. Michael
Keesey), Ludwik Gasiorowski, James R. Spotila and Ray Chatterji,
Griensteidl and T. Michael Keesey, terngirl, Sherman F. Denton via
rawpixel.com (illustration) and Timothy J. Bartley (silhouette), Brad
McFeeters (vectorized by T. Michael Keesey), Jagged Fang Designs, Felix
Vaux, Fernando Carezzano, Kai R. Caspar, Andrew A. Farke, Chris A.
Hamilton, Sebastian Stabinger, Carlos Cano-Barbacil, CNZdenek, T.
Michael Keesey, Conty (vectorized by T. Michael Keesey), Neil Kelley,
Michelle Site, C. Camilo Julián-Caballero, Mike Hanson, Chris huh, Jesús
Gómez, vectorized by Zimices, Roberto Díaz Sibaja, Scarlet23 (vectorized
by T. Michael Keesey), Birgit Lang, T. Michael Keesey (photo by Sean
Mack), Mateus Zica (modified by T. Michael Keesey), Conty, Tracy A.
Heath, Collin Gross, Amanda Katzer, Ghedoghedo, vectorized by Zimices,
Robert Bruce Horsfall (vectorized by T. Michael Keesey), Michael Ströck
(vectorized by T. Michael Keesey), M. Antonio Todaro, Tobias Kånneby,
Matteo Dal Zotto, and Ulf Jondelius (vectorized by T. Michael Keesey),
Renata F. Martins, Matus Valach, Félix Landry Yuan, Noah Schlottman,
Christoph Schomburg, Sarah Werning, Ben Liebeskind, Kosta Mumcuoglu
(vectorized by T. Michael Keesey), Esme Ashe-Jepson, Young and Zhao
(1972:figure 4), modified by Michael P. Taylor, Matt Celeskey, Smokeybjb
(modified by Mike Keesey), Mathilde Cordellier, Tony Ayling, Matt
Wilkins, Emily Jane McTavish, from
<http://en.wikipedia.org/wiki/File:Coccolithus_pelagicus.jpg>, Yan Wong
from photo by Gyik Toma, Noah Schlottman, photo from Moorea Biocode,
Smokeybjb, Michael Scroggie, Julie Blommaert based on photo by
Sofdrakou, NASA, Oscar Sanisidro, Josefine Bohr Brask, T. Tischler,
Mihai Dragos (vectorized by T. Michael Keesey), Pedro de Siracusa,
Lukasiniho, Lukas Panzarin, Original drawing by Nobu Tamura, vectorized
by Roberto Díaz Sibaja, Christopher Watson (photo) and T. Michael Keesey
(vectorization), Arthur S. Brum, Kent Elson Sorgon, Peileppe, Gabriela
Palomo-Munoz, Mathew Wedel, Kamil S. Jaron, Michael B. H. (vectorized by
T. Michael Keesey), Chloé Schmidt, Lily Hughes, Tony Ayling (vectorized
by T. Michael Keesey), Hanyong Pu, Yoshitsugu Kobayashi, Junchang Lü, Li
Xu, Yanhua Wu, Huali Chang, Jiming Zhang, Songhai Jia & T. Michael
Keesey, White Wolf, Cesar Julian, AnAgnosticGod (vectorized by T.
Michael Keesey), S.Martini, Francesco Veronesi (vectorized by T. Michael
Keesey), kreidefossilien.de, T. Michael Keesey (after Tillyard),
Alexander Schmidt-Lebuhn, Mali’o Kodis, image by Rebecca Ritger, Noah
Schlottman, photo from National Science Foundation - Turbellarian
Taxonomic Database, LeonardoG (photography) and T. Michael Keesey
(vectorization), Stanton F. Fink (vectorized by T. Michael Keesey),
Tauana J. Cunha, Jan A. Venter, Herbert H. T. Prins, David A. Balfour &
Rob Slotow (vectorized by T. Michael Keesey), Walter Vladimir, Crystal
Maier, Christopher Laumer (vectorized by T. Michael Keesey), Joanna
Wolfe, Alexandre Vong, Ghedoghedo (vectorized by T. Michael Keesey),
Maija Karala, Apokryltaros (vectorized by T. Michael Keesey), James I.
Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and
Jelle P. Wiersma (vectorized by T. Michael Keesey), Konsta Happonen,
Patrick Fisher (vectorized by T. Michael Keesey), DW Bapst, modified
from Ishitani et al. 2016, Nobu Tamura, Dean Schnabel, Sergio A.
Muñoz-Gómez, Dmitry Bogdanov (vectorized by T. Michael Keesey), Mattia
Menchetti, Taro Maeda, Emily Jane McTavish, from Haeckel, E. H. P. A.
(1904).Kunstformen der Natur. Bibliographisches, A. R. McCulloch
(vectorized by T. Michael Keesey), Javiera Constanzo, Dianne Bray /
Museum Victoria (vectorized by T. Michael Keesey), Stanton F. Fink,
vectorized by Zimices, I. Geoffroy Saint-Hilaire (vectorized by T.
Michael Keesey), Beth Reinke, Matt Martyniuk, Smokeybjb (vectorized by
T. Michael Keesey), Tasman Dixon, Meyers Konversations-Lexikon 1897
(vectorized: Yan Wong), Steven Coombs, Keith Murdock (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Paul O. Lewis,
xgirouxb, Nobu Tamura, vectorized by Zimices, Brockhaus and Efron, Emily
Jane McTavish, from
<http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>,
Sharon Wegner-Larsen, Bill Bouton (source photo) & T. Michael Keesey
(vectorization), Harold N Eyster, Anthony Caravaggi, Donovan Reginald
Rosevear (vectorized by T. Michael Keesey), Cristina Guijarro, Robert
Gay, Martin R. Smith, Jay Matternes, vectorized by Zimices, Dein Freund
der Baum (vectorized by T. Michael Keesey), Rebecca Groom, Mali’o Kodis,
image from the Smithsonian Institution, Joe Schneid (vectorized by T.
Michael Keesey), Armin Reindl, Yan Wong from drawing by Joseph Smit,
Milton Tan, M Kolmann, Didier Descouens (vectorized by T. Michael
Keesey), Nina Skinner, FunkMonk, Tess Linden, Mo Hassan, John Curtis
(vectorized by T. Michael Keesey), Becky Barnes, L. Shyamal, Sam
Fraser-Smith (vectorized by T. Michael Keesey), Kelly, NOAA Great Lakes
Environmental Research Laboratory (illustration) and Timothy J. Bartley
(silhouette), Chris Jennings (Risiatto), New York Zoological Society,
Alan Manson (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Josep Marti Solans, David Orr, Jose Carlos
Arenas-Monroy, Mariana Ruiz (vectorized by T. Michael Keesey),
Falconaumanni and T. Michael Keesey, Michael P. Taylor, Stuart
Humphries, Tomas Willems (vectorized by T. Michael Keesey), Abraão B.
Leite, Sean McCann, T. Michael Keesey (after MPF), C. Abraczinskas,
Zachary Quigley, Aleksey Nagovitsyn (vectorized by T. Michael Keesey),
Samanta Orellana, Darren Naish (vectorized by T. Michael Keesey),
Aviceda (photo) & T. Michael Keesey, Zimices / Julián Bayona, Trond R.
Oskars, Vanessa Guerra, Shyamal, Farelli (photo), John E. McCormack,
Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C.
Glenn, Robb T. Brumfield & T. Michael Keesey, Jessica Anne Miller, Hans
Hillewaert (vectorized by T. Michael Keesey), Steven Haddock
• Jellywatch.org, Ingo Braasch, Martin R. Smith, after Skovsted et al
2015, Christine Axon, Yan Wong, Nobu Tamura (modified by T. Michael
Keesey), mystica, Michael Scroggie, from original photograph by Gary M.
Stolz, USFWS (original photograph in public domain)., Nobu Tamura
(vectorized by A. Verrière), Mariana Ruiz Villarreal (modified by T.
Michael Keesey), Servien (vectorized by T. Michael Keesey), Scott
Hartman, modified by T. Michael Keesey, Michele M Tobias, Mark
Hofstetter (vectorized by T. Michael Keesey), Melissa Broussard, Noah
Schlottman, photo by Casey Dunn, Wayne Decatur, Peter Coxhead, Karl
Ragnar Gjertsen (vectorized by T. Michael Keesey), Mathew Stewart, Ryan
Cupo, Katie S. Collins, Maxwell Lefroy (vectorized by T. Michael
Keesey), Frank Denota, Manabu Bessho-Uehara, Claus Rebler, E. R. Waite &
H. M. Hale (vectorized by T. Michael Keesey), T. Michael Keesey (after
Kukalová), Jonathan Wells, Mali’o Kodis, photograph property of National
Museums of Northern Ireland, Sarefo (vectorized by T. Michael Keesey),
Francis de Laporte de Castelnau (vectorized by T. Michael Keesey), Matt
Martyniuk (vectorized by T. Michael Keesey), Remes K, Ortega F, Fierro
I, Joger U, Kosma R, et al., Chris Jennings (vectorized by A. Verrière),
Nick Schooler, Iain Reid, Unknown (photo), John E. McCormack, Michael G.
Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb
T. Brumfield & T. Michael Keesey, Maxime Dahirel, Myriam\_Ramirez,
Pollyanna von Knorring and T. Michael Keesey, Chase Brownstein, B. Duygu
Özpolat, Theodore W. Pietsch (photography) and T. Michael Keesey
(vectorization), T. Michael Keesey (after James & al.), Bob Goldstein,
Vectorization:Jake Warner, Scott Reid, Isaure Scavezzoni, T. Michael
Keesey (vector) and Stuart Halliday (photograph), Birgit Lang, based on
a photo by D. Sikes, Henry Fairfield Osborn, vectorized by Zimices,
Yusan Yang, Birgit Lang; based on a drawing by C.L. Koch, Matthew E.
Clapham, Ewald Rübsamen, Gopal Murali, T. Michael Keesey (vectorization)
and Tony Hisgett (photography), E. J. Van Nieukerken, A. Laštuvka, and
Z. Laštuvka (vectorized by T. Michael Keesey), Mathieu Basille, Thibaut
Brunet, Haplochromis (vectorized by T. Michael Keesey), Mali’o Kodis,
image from Higgins and Kristensen, 1986, Julien Louys, Arthur Grosset
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Caleb M. Brown, Cathy, Duane Raver (vectorized by T. Michael
Keesey), Plukenet, Mary Harrsch (modified by T. Michael Keesey), Gustav
Mützel, FJDegrange, Johan Lindgren, Michael W. Caldwell, Takuya Konishi,
Luis M. Chiappe, Inessa Voet, Robert Bruce Horsfall, vectorized by
Zimices, Jaime Chirinos (vectorized by T. Michael Keesey), Madeleine
Price Ball, Michael Day, Diego Fontaneto, Elisabeth A. Herniou, Chiara
Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy
G. Barraclough (vectorized by T. Michael Keesey)

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    255.382095 |     76.836189 | Xavier Giroux-Bougard                                                                                                                                                 |
|   2 |    488.475611 |    611.101386 | Zimices                                                                                                                                                               |
|   3 |    797.301287 |    390.106984 | Alex Slavenko                                                                                                                                                         |
|   4 |    224.680747 |    419.837351 | Ferran Sayol                                                                                                                                                          |
|   5 |    119.830508 |    212.328803 | NA                                                                                                                                                                    |
|   6 |    320.420799 |    417.135641 | Ferran Sayol                                                                                                                                                          |
|   7 |    791.577223 |    201.866679 | Ferran Sayol                                                                                                                                                          |
|   8 |    408.914473 |    294.426525 | Gareth Monger                                                                                                                                                         |
|   9 |    863.886610 |     51.830620 | Lafage                                                                                                                                                                |
|  10 |    704.206676 |     92.320640 | Steven Traver                                                                                                                                                         |
|  11 |    834.429482 |    590.927394 | Emily Willoughby                                                                                                                                                      |
|  12 |    726.844614 |    708.813873 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  13 |    240.434292 |    177.811478 | Scott Hartman                                                                                                                                                         |
|  14 |    473.783833 |    206.159217 | Zimices                                                                                                                                                               |
|  15 |    230.674284 |    630.149004 | Zimices                                                                                                                                                               |
|  16 |    652.987113 |    139.999950 | Auckland Museum and T. Michael Keesey                                                                                                                                 |
|  17 |    948.617418 |    598.419601 | Xavier A. Jenkins, Gabriel Ugueto                                                                                                                                     |
|  18 |    506.382865 |    342.349999 | Mason McNair                                                                                                                                                          |
|  19 |    378.261951 |    134.202063 | Terpsichores                                                                                                                                                          |
|  20 |     61.968664 |    673.077598 | Gareth Monger                                                                                                                                                         |
|  21 |    935.785532 |    301.618975 | Margot Michaud                                                                                                                                                        |
|  22 |    417.188998 |    472.659968 | Stephen O’Connor (vectorized by T. Michael Keesey)                                                                                                                    |
|  23 |    864.354736 |    466.855529 | Gareth Monger                                                                                                                                                         |
|  24 |    144.169750 |    761.703650 | Jaime Headden                                                                                                                                                         |
|  25 |    241.044180 |    280.663464 | Matt Crook                                                                                                                                                            |
|  26 |    895.916545 |    688.222890 | Zimices                                                                                                                                                               |
|  27 |    687.202018 |    511.159877 | Steven Traver                                                                                                                                                         |
|  28 |    295.608839 |    705.739014 | Matt Crook                                                                                                                                                            |
|  29 |    968.362603 |    535.459420 | Campbell Fleming                                                                                                                                                      |
|  30 |    146.276383 |     91.106328 | Scott Hartman                                                                                                                                                         |
|  31 |     18.878138 |    247.238005 | Gareth Monger                                                                                                                                                         |
|  32 |     82.700276 |     39.474590 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
|  33 |    131.297249 |    418.451261 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                              |
|  34 |    680.928349 |    223.047282 | Ludwik Gasiorowski                                                                                                                                                    |
|  35 |    129.453630 |    594.922244 | James R. Spotila and Ray Chatterji                                                                                                                                    |
|  36 |    604.298372 |    369.623754 | Griensteidl and T. Michael Keesey                                                                                                                                     |
|  37 |    914.411374 |    215.958615 | terngirl                                                                                                                                                              |
|  38 |    306.103870 |    201.922390 | Sherman F. Denton via rawpixel.com (illustration) and Timothy J. Bartley (silhouette)                                                                                 |
|  39 |    852.502263 |    344.040816 | Scott Hartman                                                                                                                                                         |
|  40 |    544.436691 |     75.569964 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
|  41 |    545.878269 |    480.198414 | Jagged Fang Designs                                                                                                                                                   |
|  42 |    764.097134 |    655.642363 | Jagged Fang Designs                                                                                                                                                   |
|  43 |    802.024778 |    521.549236 | Scott Hartman                                                                                                                                                         |
|  44 |    702.783201 |    364.428935 | NA                                                                                                                                                                    |
|  45 |     79.004331 |    252.681769 | Felix Vaux                                                                                                                                                            |
|  46 |    406.921437 |    380.928414 | Fernando Carezzano                                                                                                                                                    |
|  47 |    296.580925 |     31.152153 | Kai R. Caspar                                                                                                                                                         |
|  48 |    223.616167 |    693.534501 | Emily Willoughby                                                                                                                                                      |
|  49 |    968.978375 |    112.144329 | Andrew A. Farke                                                                                                                                                       |
|  50 |     73.295145 |    538.960781 | Zimices                                                                                                                                                               |
|  51 |    449.288284 |     26.832304 | Scott Hartman                                                                                                                                                         |
|  52 |    939.370394 |    758.636503 | Zimices                                                                                                                                                               |
|  53 |    196.970037 |    528.416692 | Chris A. Hamilton                                                                                                                                                     |
|  54 |    340.263129 |    252.728907 | Sebastian Stabinger                                                                                                                                                   |
|  55 |    135.833550 |    333.932601 | Carlos Cano-Barbacil                                                                                                                                                  |
|  56 |    397.988141 |    744.286266 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  57 |    683.497952 |    757.431409 | CNZdenek                                                                                                                                                              |
|  58 |    211.638697 |    125.683010 | NA                                                                                                                                                                    |
|  59 |    299.602787 |    777.205470 | Jagged Fang Designs                                                                                                                                                   |
|  60 |    634.360854 |    446.116075 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
|  61 |     39.897466 |    135.910493 | T. Michael Keesey                                                                                                                                                     |
|  62 |    364.081418 |    637.019342 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
|  63 |    752.022366 |    597.429328 | Neil Kelley                                                                                                                                                           |
|  64 |    934.112263 |    374.105322 | Michelle Site                                                                                                                                                         |
|  65 |    550.923556 |    723.319744 | T. Michael Keesey                                                                                                                                                     |
|  66 |    605.615613 |    511.239631 | C. Camilo Julián-Caballero                                                                                                                                            |
|  67 |    468.939168 |    435.568286 | Zimices                                                                                                                                                               |
|  68 |    889.152081 |    565.250286 | Mike Hanson                                                                                                                                                           |
|  69 |    938.573920 |    271.872433 | Chris huh                                                                                                                                                             |
|  70 |    809.946606 |    752.032408 | Jesús Gómez, vectorized by Zimices                                                                                                                                    |
|  71 |    961.263826 |    388.632923 | Scott Hartman                                                                                                                                                         |
|  72 |    728.082587 |     32.686794 | Scott Hartman                                                                                                                                                         |
|  73 |    885.033788 |    629.871533 | Roberto Díaz Sibaja                                                                                                                                                   |
|  74 |    963.886300 |    696.378723 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                                           |
|  75 |    984.031588 |    400.365044 | Birgit Lang                                                                                                                                                           |
|  76 |    619.435636 |    234.626898 | T. Michael Keesey (photo by Sean Mack)                                                                                                                                |
|  77 |    721.956372 |     64.834154 | Steven Traver                                                                                                                                                         |
|  78 |     29.563744 |    333.162868 | Ferran Sayol                                                                                                                                                          |
|  79 |    793.849596 |    464.453465 | Mateus Zica (modified by T. Michael Keesey)                                                                                                                           |
|  80 |    292.457867 |    345.715702 | NA                                                                                                                                                                    |
|  81 |     46.710891 |    596.046668 | Conty                                                                                                                                                                 |
|  82 |     37.156177 |    395.617058 | Tracy A. Heath                                                                                                                                                        |
|  83 |    569.926636 |    772.338613 | Matt Crook                                                                                                                                                            |
|  84 |    862.621574 |    270.569331 | Collin Gross                                                                                                                                                          |
|  85 |    688.910908 |    785.136374 | T. Michael Keesey                                                                                                                                                     |
|  86 |    128.207205 |    651.912772 | Neil Kelley                                                                                                                                                           |
|  87 |    187.218934 |    220.527153 | Gareth Monger                                                                                                                                                         |
|  88 |    103.629885 |    680.413699 | Amanda Katzer                                                                                                                                                         |
|  89 |    286.024238 |    750.802769 | Jagged Fang Designs                                                                                                                                                   |
|  90 |   1007.247119 |    496.023201 | Ghedoghedo, vectorized by Zimices                                                                                                                                     |
|  91 |    910.784320 |    159.177379 | Robert Bruce Horsfall (vectorized by T. Michael Keesey)                                                                                                               |
|  92 |     22.069710 |     51.461296 | Scott Hartman                                                                                                                                                         |
|  93 |    280.865014 |    520.989866 | Michael Ströck (vectorized by T. Michael Keesey)                                                                                                                      |
|  94 |    489.838073 |    252.332212 | M. Antonio Todaro, Tobias Kånneby, Matteo Dal Zotto, and Ulf Jondelius (vectorized by T. Michael Keesey)                                                              |
|  95 |    462.066823 |    776.793066 | Renata F. Martins                                                                                                                                                     |
|  96 |    621.300347 |    738.495869 | Birgit Lang                                                                                                                                                           |
|  97 |    407.518810 |     78.249216 | Jaime Headden                                                                                                                                                         |
|  98 |    789.394650 |    317.527249 | Matus Valach                                                                                                                                                          |
|  99 |    206.033151 |    485.869176 | Félix Landry Yuan                                                                                                                                                     |
| 100 |    580.675154 |    150.355226 | Jaime Headden                                                                                                                                                         |
| 101 |    444.495345 |    349.727723 | Noah Schlottman                                                                                                                                                       |
| 102 |    571.965989 |    300.515269 | Gareth Monger                                                                                                                                                         |
| 103 |      5.785349 |    128.562816 | T. Michael Keesey                                                                                                                                                     |
| 104 |    151.028665 |    696.470149 | Christoph Schomburg                                                                                                                                                   |
| 105 |    144.199864 |    498.379770 | NA                                                                                                                                                                    |
| 106 |    752.958577 |    464.205383 | Sarah Werning                                                                                                                                                         |
| 107 |    675.977901 |    305.430740 | Ben Liebeskind                                                                                                                                                        |
| 108 |   1011.542232 |     33.943560 | Michelle Site                                                                                                                                                         |
| 109 |    157.514479 |    275.487794 | Gareth Monger                                                                                                                                                         |
| 110 |    978.570616 |    536.428342 | Kosta Mumcuoglu (vectorized by T. Michael Keesey)                                                                                                                     |
| 111 |    371.790647 |    666.922556 | Esme Ashe-Jepson                                                                                                                                                      |
| 112 |    313.353470 |    605.640437 | NA                                                                                                                                                                    |
| 113 |    809.511159 |     21.052545 | Zimices                                                                                                                                                               |
| 114 |    940.588613 |    428.000354 | Young and Zhao (1972:figure 4), modified by Michael P. Taylor                                                                                                         |
| 115 |    478.659662 |    364.381282 | Margot Michaud                                                                                                                                                        |
| 116 |    945.586968 |      9.136801 | Sarah Werning                                                                                                                                                         |
| 117 |    296.144613 |    152.316404 | Ferran Sayol                                                                                                                                                          |
| 118 |    262.819816 |    554.182994 | Matt Celeskey                                                                                                                                                         |
| 119 |    987.732509 |    424.361745 | Smokeybjb (modified by Mike Keesey)                                                                                                                                   |
| 120 |    334.855748 |     87.444737 | Mathilde Cordellier                                                                                                                                                   |
| 121 |    807.958822 |     94.831379 | Scott Hartman                                                                                                                                                         |
| 122 |    149.436719 |    295.093964 | Tony Ayling                                                                                                                                                           |
| 123 |    564.353896 |    152.029712 | Michelle Site                                                                                                                                                         |
| 124 |    100.270792 |    623.078149 | Matt Wilkins                                                                                                                                                          |
| 125 |     33.962783 |    769.318297 | Ferran Sayol                                                                                                                                                          |
| 126 |    956.672393 |    648.563525 | Steven Traver                                                                                                                                                         |
| 127 |    961.022088 |    630.184135 | Jaime Headden                                                                                                                                                         |
| 128 |    228.308974 |    448.225729 | Emily Jane McTavish, from <http://en.wikipedia.org/wiki/File:Coccolithus_pelagicus.jpg>                                                                               |
| 129 |    745.853366 |    233.752092 | Yan Wong from photo by Gyik Toma                                                                                                                                      |
| 130 |     38.276786 |    433.230482 | Scott Hartman                                                                                                                                                         |
| 131 |     38.671193 |    426.952669 | Noah Schlottman, photo from Moorea Biocode                                                                                                                            |
| 132 |    850.090161 |     94.989646 | Smokeybjb                                                                                                                                                             |
| 133 |    520.372348 |    124.239912 | Scott Hartman                                                                                                                                                         |
| 134 |    436.423117 |    397.766745 | Michael Scroggie                                                                                                                                                      |
| 135 |    394.727680 |     33.110817 | Sarah Werning                                                                                                                                                         |
| 136 |    896.449056 |    521.413271 | Julie Blommaert based on photo by Sofdrakou                                                                                                                           |
| 137 |    349.617773 |     77.336083 | NASA                                                                                                                                                                  |
| 138 |    520.233035 |    250.972378 | Oscar Sanisidro                                                                                                                                                       |
| 139 |     62.722822 |    392.290580 | Josefine Bohr Brask                                                                                                                                                   |
| 140 |    964.338551 |    795.021588 | T. Tischler                                                                                                                                                           |
| 141 |    469.686305 |    488.033837 | Matt Crook                                                                                                                                                            |
| 142 |    779.848075 |    374.846429 | Mihai Dragos (vectorized by T. Michael Keesey)                                                                                                                        |
| 143 |     27.165749 |    248.051718 | Jagged Fang Designs                                                                                                                                                   |
| 144 |    597.129722 |    205.622961 | Pedro de Siracusa                                                                                                                                                     |
| 145 |     94.117557 |     16.774971 | T. Michael Keesey                                                                                                                                                     |
| 146 |    194.277494 |    645.755799 | NA                                                                                                                                                                    |
| 147 |    216.836183 |     37.571740 | Lukasiniho                                                                                                                                                            |
| 148 |    760.830319 |    125.702165 | Lukas Panzarin                                                                                                                                                        |
| 149 |    487.501654 |     33.668290 | Original drawing by Nobu Tamura, vectorized by Roberto Díaz Sibaja                                                                                                    |
| 150 |    372.004465 |    608.807518 | Chris huh                                                                                                                                                             |
| 151 |    279.425876 |    461.485718 | Margot Michaud                                                                                                                                                        |
| 152 |    538.160933 |    271.815895 | Roberto Díaz Sibaja                                                                                                                                                   |
| 153 |     60.706112 |    579.590748 | Chris huh                                                                                                                                                             |
| 154 |    175.148096 |    670.467476 | NA                                                                                                                                                                    |
| 155 |    580.466756 |    278.730752 | Zimices                                                                                                                                                               |
| 156 |    244.607005 |    662.064196 | Gareth Monger                                                                                                                                                         |
| 157 |     63.754409 |    365.175768 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 158 |    999.578967 |    167.871132 | Birgit Lang                                                                                                                                                           |
| 159 |     42.426707 |    459.711531 | Margot Michaud                                                                                                                                                        |
| 160 |    259.117968 |    139.543005 | Christopher Watson (photo) and T. Michael Keesey (vectorization)                                                                                                      |
| 161 |    541.398986 |    102.939587 | Arthur S. Brum                                                                                                                                                        |
| 162 |    333.910939 |    719.375152 | Chris huh                                                                                                                                                             |
| 163 |    439.168018 |    722.531382 | Kent Elson Sorgon                                                                                                                                                     |
| 164 |    467.366427 |    514.218144 | Zimices                                                                                                                                                               |
| 165 |    556.797355 |     10.274673 | Peileppe                                                                                                                                                              |
| 166 |    601.085969 |     85.825226 | Scott Hartman                                                                                                                                                         |
| 167 |    203.891611 |    406.837246 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 168 |    652.978519 |    363.586753 | Margot Michaud                                                                                                                                                        |
| 169 |    430.822210 |    751.301642 | Mathew Wedel                                                                                                                                                          |
| 170 |    355.159864 |     12.185113 | Kamil S. Jaron                                                                                                                                                        |
| 171 |    267.104102 |    481.331073 | Zimices                                                                                                                                                               |
| 172 |    614.586233 |    100.141421 | Michael B. H. (vectorized by T. Michael Keesey)                                                                                                                       |
| 173 |    426.379416 |    278.677060 | Steven Traver                                                                                                                                                         |
| 174 |    633.058935 |    260.690433 | NA                                                                                                                                                                    |
| 175 |    631.259593 |    206.710599 | Ferran Sayol                                                                                                                                                          |
| 176 |    774.044277 |    154.185183 | Chloé Schmidt                                                                                                                                                         |
| 177 |    930.604096 |    173.433144 | Matt Crook                                                                                                                                                            |
| 178 |    653.614774 |     75.464553 | Margot Michaud                                                                                                                                                        |
| 179 |    833.507399 |    287.964287 | Zimices                                                                                                                                                               |
| 180 |    133.298073 |    128.450897 | Margot Michaud                                                                                                                                                        |
| 181 |    162.764878 |      5.892563 | Lily Hughes                                                                                                                                                           |
| 182 |    558.994961 |    346.135412 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 183 |    174.815925 |     32.936424 | Zimices                                                                                                                                                               |
| 184 |    821.467418 |    422.479516 | Jagged Fang Designs                                                                                                                                                   |
| 185 |    415.209819 |    735.540688 | Zimices                                                                                                                                                               |
| 186 |    336.080018 |    297.915635 | Matt Crook                                                                                                                                                            |
| 187 |    314.980753 |    272.563454 | Hanyong Pu, Yoshitsugu Kobayashi, Junchang Lü, Li Xu, Yanhua Wu, Huali Chang, Jiming Zhang, Songhai Jia & T. Michael Keesey                                           |
| 188 |    755.111806 |    360.352095 | White Wolf                                                                                                                                                            |
| 189 |    334.694491 |    285.309425 | Birgit Lang                                                                                                                                                           |
| 190 |    768.704855 |    353.334078 | T. Michael Keesey                                                                                                                                                     |
| 191 |    639.440505 |    291.984778 | Ferran Sayol                                                                                                                                                          |
| 192 |    671.971975 |      8.488260 | Cesar Julian                                                                                                                                                          |
| 193 |    913.400026 |    414.898388 | Margot Michaud                                                                                                                                                        |
| 194 |    465.840560 |     60.451304 | Jagged Fang Designs                                                                                                                                                   |
| 195 |    656.398980 |    542.288804 | Margot Michaud                                                                                                                                                        |
| 196 |   1013.466450 |    353.032783 | Roberto Díaz Sibaja                                                                                                                                                   |
| 197 |    109.669986 |    731.631275 | AnAgnosticGod (vectorized by T. Michael Keesey)                                                                                                                       |
| 198 |    918.092891 |    716.097274 | Matt Crook                                                                                                                                                            |
| 199 |    444.363105 |    793.183120 | Alex Slavenko                                                                                                                                                         |
| 200 |    460.497123 |    393.636243 | S.Martini                                                                                                                                                             |
| 201 |    282.180817 |    384.127716 | Collin Gross                                                                                                                                                          |
| 202 |   1008.886367 |    460.151043 | T. Michael Keesey                                                                                                                                                     |
| 203 |    109.077032 |     12.214271 | Francesco Veronesi (vectorized by T. Michael Keesey)                                                                                                                  |
| 204 |    107.427327 |    132.228427 | kreidefossilien.de                                                                                                                                                    |
| 205 |    935.414935 |     99.023375 | Jaime Headden                                                                                                                                                         |
| 206 |    748.867225 |     56.670636 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 207 |    190.894807 |    352.694470 | Margot Michaud                                                                                                                                                        |
| 208 |    921.435417 |    504.262774 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 209 |     78.615874 |     15.915846 | Zimices                                                                                                                                                               |
| 210 |    602.671144 |     31.983891 | T. Michael Keesey (after Tillyard)                                                                                                                                    |
| 211 |    233.397369 |    765.327432 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 212 |     26.182571 |    417.084492 | Scott Hartman                                                                                                                                                         |
| 213 |   1003.179988 |    137.020501 | Zimices                                                                                                                                                               |
| 214 |     70.848306 |    101.684606 | Mali’o Kodis, image by Rebecca Ritger                                                                                                                                 |
| 215 |    415.150829 |    123.089603 | Michelle Site                                                                                                                                                         |
| 216 |    773.562365 |    684.932710 | Gareth Monger                                                                                                                                                         |
| 217 |    712.448222 |    448.055198 | Noah Schlottman, photo from National Science Foundation - Turbellarian Taxonomic Database                                                                             |
| 218 |     67.378223 |    121.818254 | LeonardoG (photography) and T. Michael Keesey (vectorization)                                                                                                         |
| 219 |    794.032159 |    674.290834 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                     |
| 220 |    338.025976 |    361.780607 | Chris huh                                                                                                                                                             |
| 221 |    260.296731 |    374.688612 | Tauana J. Cunha                                                                                                                                                       |
| 222 |    154.962460 |    202.666479 | T. Michael Keesey (photo by Sean Mack)                                                                                                                                |
| 223 |     50.084610 |    341.535071 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 224 |    935.234160 |    112.686765 | Walter Vladimir                                                                                                                                                       |
| 225 |    415.106546 |    106.302745 | Crystal Maier                                                                                                                                                         |
| 226 |   1005.100194 |    195.908127 | Steven Traver                                                                                                                                                         |
| 227 |    304.717263 |    364.281312 | Tracy A. Heath                                                                                                                                                        |
| 228 |    391.006750 |    204.178318 | Matt Crook                                                                                                                                                            |
| 229 |    948.715168 |    193.165432 | Christopher Laumer (vectorized by T. Michael Keesey)                                                                                                                  |
| 230 |    957.052741 |    505.526600 | Gareth Monger                                                                                                                                                         |
| 231 |    872.113043 |    236.105945 | Gareth Monger                                                                                                                                                         |
| 232 |    856.243416 |    307.391871 | Margot Michaud                                                                                                                                                        |
| 233 |    172.705293 |     69.820601 | Joanna Wolfe                                                                                                                                                          |
| 234 |    398.167013 |    675.561562 | Alexandre Vong                                                                                                                                                        |
| 235 |    366.589628 |     19.141652 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 236 |   1015.890780 |    121.698160 | Maija Karala                                                                                                                                                          |
| 237 |    425.288857 |    512.187864 | Zimices                                                                                                                                                               |
| 238 |    418.105706 |    647.203915 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                        |
| 239 |    965.411105 |    574.441067 | Matt Crook                                                                                                                                                            |
| 240 |    405.284041 |    725.776899 | Mason McNair                                                                                                                                                          |
| 241 |    352.964833 |    583.155323 | Margot Michaud                                                                                                                                                        |
| 242 |     90.886591 |    728.421927 | Ferran Sayol                                                                                                                                                          |
| 243 |    150.719397 |    172.917838 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                  |
| 244 |    563.190287 |    401.429646 | Jaime Headden                                                                                                                                                         |
| 245 |    376.493079 |    709.372918 | Konsta Happonen                                                                                                                                                       |
| 246 |    170.882202 |    186.341156 | Gareth Monger                                                                                                                                                         |
| 247 |    928.217170 |    544.314147 | Patrick Fisher (vectorized by T. Michael Keesey)                                                                                                                      |
| 248 |    795.904046 |    351.501151 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 249 |    737.594872 |    118.468449 | Felix Vaux                                                                                                                                                            |
| 250 |    263.129850 |    528.948455 | DW Bapst, modified from Ishitani et al. 2016                                                                                                                          |
| 251 |     82.019173 |    409.660590 | Zimices                                                                                                                                                               |
| 252 |     49.147776 |    294.311958 | Kai R. Caspar                                                                                                                                                         |
| 253 |    635.505125 |     70.375762 | Nobu Tamura                                                                                                                                                           |
| 254 |     53.761786 |    436.676576 | Steven Traver                                                                                                                                                         |
| 255 |    754.313663 |    718.288645 | Dean Schnabel                                                                                                                                                         |
| 256 |    575.422456 |    661.775102 | Scott Hartman                                                                                                                                                         |
| 257 |    465.625875 |    339.150080 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 258 |     15.290931 |    595.203719 | Chris huh                                                                                                                                                             |
| 259 |    968.531001 |     35.135919 | Matt Crook                                                                                                                                                            |
| 260 |    234.531490 |    492.457247 | Gareth Monger                                                                                                                                                         |
| 261 |    136.940318 |    561.489379 | NA                                                                                                                                                                    |
| 262 |     81.294053 |    197.353043 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 263 |   1000.538789 |    219.787346 | Mattia Menchetti                                                                                                                                                      |
| 264 |    850.900492 |    594.285555 | Taro Maeda                                                                                                                                                            |
| 265 |    162.425583 |     76.136466 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 266 |    672.777600 |    554.781597 | Ferran Sayol                                                                                                                                                          |
| 267 |    371.711928 |     62.844106 | Margot Michaud                                                                                                                                                        |
| 268 |    889.573558 |    123.412205 | Michelle Site                                                                                                                                                         |
| 269 |    278.348268 |    544.724695 | Gareth Monger                                                                                                                                                         |
| 270 |    210.705218 |    551.398344 | Emily Jane McTavish, from Haeckel, E. H. P. A. (1904).Kunstformen der Natur. Bibliographisches                                                                        |
| 271 |    318.908860 |    736.394277 | Margot Michaud                                                                                                                                                        |
| 272 |    757.485807 |    315.693018 | Steven Traver                                                                                                                                                         |
| 273 |    948.961903 |    240.482839 | Chris huh                                                                                                                                                             |
| 274 |    403.470859 |     93.890516 | A. R. McCulloch (vectorized by T. Michael Keesey)                                                                                                                     |
| 275 |    741.958643 |    257.522349 | Original drawing by Nobu Tamura, vectorized by Roberto Díaz Sibaja                                                                                                    |
| 276 |    876.901230 |     19.431320 | Javiera Constanzo                                                                                                                                                     |
| 277 |    658.251500 |    424.767422 | NA                                                                                                                                                                    |
| 278 |    423.258043 |     85.567293 | Scott Hartman                                                                                                                                                         |
| 279 |     37.271667 |    223.154388 | Zimices                                                                                                                                                               |
| 280 |    909.110943 |    140.040463 | Oscar Sanisidro                                                                                                                                                       |
| 281 |    605.283446 |     13.122781 | Birgit Lang                                                                                                                                                           |
| 282 |    544.088581 |    792.059039 | Dianne Bray / Museum Victoria (vectorized by T. Michael Keesey)                                                                                                       |
| 283 |    246.600798 |    586.721566 | Stanton F. Fink, vectorized by Zimices                                                                                                                                |
| 284 |    743.830730 |    429.891984 | I. Geoffroy Saint-Hilaire (vectorized by T. Michael Keesey)                                                                                                           |
| 285 |     97.502059 |    315.935890 | Beth Reinke                                                                                                                                                           |
| 286 |     17.381807 |    369.695704 | Smokeybjb                                                                                                                                                             |
| 287 |    748.146602 |    168.085354 | Gareth Monger                                                                                                                                                         |
| 288 |    182.885334 |     48.935227 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 289 |    198.479619 |    760.884351 | Kamil S. Jaron                                                                                                                                                        |
| 290 |    655.926243 |    403.459789 | NA                                                                                                                                                                    |
| 291 |    988.815881 |     10.298338 | Steven Traver                                                                                                                                                         |
| 292 |    402.025599 |    769.542792 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 293 |    283.783114 |    644.490006 | Chris huh                                                                                                                                                             |
| 294 |     55.134490 |    413.577255 | Dean Schnabel                                                                                                                                                         |
| 295 |    230.165109 |    350.403063 | Matt Martyniuk                                                                                                                                                        |
| 296 |    621.187919 |    191.949043 | Kamil S. Jaron                                                                                                                                                        |
| 297 |    810.157706 |    351.730973 | Scott Hartman                                                                                                                                                         |
| 298 |    378.488260 |    313.528521 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                           |
| 299 |    766.917925 |    534.828429 | Birgit Lang                                                                                                                                                           |
| 300 |     28.437512 |    634.089711 | Lukasiniho                                                                                                                                                            |
| 301 |    675.190502 |    386.206818 | Tasman Dixon                                                                                                                                                          |
| 302 |    143.191733 |    137.266776 | Alexandre Vong                                                                                                                                                        |
| 303 |   1008.412065 |    364.606070 | Steven Traver                                                                                                                                                         |
| 304 |    148.791058 |    534.881832 | Meyers Konversations-Lexikon 1897 (vectorized: Yan Wong)                                                                                                              |
| 305 |    440.857963 |     66.600561 | Steven Coombs                                                                                                                                                         |
| 306 |    354.550861 |     74.820673 | T. Michael Keesey                                                                                                                                                     |
| 307 |    306.237462 |    159.089954 | Keith Murdock (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey         |
| 308 |    871.431814 |    717.773278 | Gareth Monger                                                                                                                                                         |
| 309 |    445.710992 |    481.010755 | Paul O. Lewis                                                                                                                                                         |
| 310 |    393.198830 |      5.145513 | Margot Michaud                                                                                                                                                        |
| 311 |    656.810264 |     27.956770 | Zimices                                                                                                                                                               |
| 312 |    149.691538 |    648.056877 | Matt Crook                                                                                                                                                            |
| 313 |    776.227464 |    796.135615 | xgirouxb                                                                                                                                                              |
| 314 |     58.520341 |     75.380564 | Lukasiniho                                                                                                                                                            |
| 315 |    172.491515 |    235.813750 | Emily Willoughby                                                                                                                                                      |
| 316 |    355.791974 |    477.747801 | T. Michael Keesey                                                                                                                                                     |
| 317 |    544.021705 |     23.411821 | Matt Crook                                                                                                                                                            |
| 318 |    771.587542 |    292.797778 | NA                                                                                                                                                                    |
| 319 |    125.152030 |    669.421255 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 320 |    148.092953 |    721.298838 | Brockhaus and Efron                                                                                                                                                   |
| 321 |    306.662473 |    233.683732 | Beth Reinke                                                                                                                                                           |
| 322 |     25.759517 |    146.979177 | Joanna Wolfe                                                                                                                                                          |
| 323 |    501.604974 |    234.494584 | Matt Crook                                                                                                                                                            |
| 324 |    421.652382 |    187.945976 | Tasman Dixon                                                                                                                                                          |
| 325 |    758.567971 |    781.434127 | Gareth Monger                                                                                                                                                         |
| 326 |    243.230356 |    503.138982 | T. Michael Keesey                                                                                                                                                     |
| 327 |     66.579547 |    457.761390 | Matt Crook                                                                                                                                                            |
| 328 |    892.505535 |    533.298302 | Roberto Díaz Sibaja                                                                                                                                                   |
| 329 |    905.569073 |    706.404964 | Kamil S. Jaron                                                                                                                                                        |
| 330 |    228.623207 |    234.236433 | T. Michael Keesey                                                                                                                                                     |
| 331 |    462.041922 |    744.480879 | Matt Crook                                                                                                                                                            |
| 332 |    785.964613 |     82.251324 | Emily Jane McTavish, from <http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>                                                           |
| 333 |    934.751749 |     73.382104 | Sharon Wegner-Larsen                                                                                                                                                  |
| 334 |    728.397398 |    779.336524 | Roberto Díaz Sibaja                                                                                                                                                   |
| 335 |    187.266191 |    231.545342 | Chris huh                                                                                                                                                             |
| 336 |   1014.430422 |    149.525682 | Margot Michaud                                                                                                                                                        |
| 337 |    207.591837 |    565.776689 | Bill Bouton (source photo) & T. Michael Keesey (vectorization)                                                                                                        |
| 338 |    230.482758 |    577.697228 | Harold N Eyster                                                                                                                                                       |
| 339 |     18.624412 |    314.099945 | Margot Michaud                                                                                                                                                        |
| 340 |    253.317685 |    641.007907 | Beth Reinke                                                                                                                                                           |
| 341 |    664.319410 |    777.093932 | NA                                                                                                                                                                    |
| 342 |    625.625023 |    299.849420 | Anthony Caravaggi                                                                                                                                                     |
| 343 |    562.809050 |    392.185601 | Chris huh                                                                                                                                                             |
| 344 |    220.249139 |    723.055890 | C. Camilo Julián-Caballero                                                                                                                                            |
| 345 |     54.805603 |    480.402678 | Donovan Reginald Rosevear (vectorized by T. Michael Keesey)                                                                                                           |
| 346 |    456.403980 |     31.837860 | Ferran Sayol                                                                                                                                                          |
| 347 |    647.785360 |    790.591567 | NA                                                                                                                                                                    |
| 348 |    993.031129 |    643.814807 | Matt Crook                                                                                                                                                            |
| 349 |    194.858422 |    255.289017 | Birgit Lang                                                                                                                                                           |
| 350 |    771.601532 |    670.474327 | Cristina Guijarro                                                                                                                                                     |
| 351 |    930.897281 |    409.753402 | Collin Gross                                                                                                                                                          |
| 352 |    269.818616 |     98.948754 | Felix Vaux                                                                                                                                                            |
| 353 |     76.814708 |     83.004007 | Tasman Dixon                                                                                                                                                          |
| 354 |    411.481019 |    719.253538 | Robert Gay                                                                                                                                                            |
| 355 |    437.150775 |    125.419479 | Matt Martyniuk                                                                                                                                                        |
| 356 |    718.826074 |    128.864085 | Martin R. Smith                                                                                                                                                       |
| 357 |    500.683697 |    671.150182 | NA                                                                                                                                                                    |
| 358 |     42.124419 |    210.309791 | Zimices                                                                                                                                                               |
| 359 |    953.995572 |     88.815671 | Jay Matternes, vectorized by Zimices                                                                                                                                  |
| 360 |    237.300762 |     55.911968 | Chris huh                                                                                                                                                             |
| 361 |    970.510422 |    244.488549 | Ferran Sayol                                                                                                                                                          |
| 362 |    804.667083 |    313.441704 | Dein Freund der Baum (vectorized by T. Michael Keesey)                                                                                                                |
| 363 |    722.898548 |     49.992352 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 364 |   1007.769633 |    776.387813 | Matt Martyniuk                                                                                                                                                        |
| 365 |    656.848835 |    458.603967 | Gareth Monger                                                                                                                                                         |
| 366 |    440.887952 |    278.468661 | Michelle Site                                                                                                                                                         |
| 367 |    100.821805 |     64.001853 | Rebecca Groom                                                                                                                                                         |
| 368 |    983.331085 |     30.665579 | Ferran Sayol                                                                                                                                                          |
| 369 |    483.890483 |      6.165816 | NA                                                                                                                                                                    |
| 370 |    873.867894 |    145.816636 | Margot Michaud                                                                                                                                                        |
| 371 |    240.678180 |    207.488029 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 372 |     18.993532 |    504.404612 | Mali’o Kodis, image from the Smithsonian Institution                                                                                                                  |
| 373 |    199.300234 |    485.242137 | Margot Michaud                                                                                                                                                        |
| 374 |    285.268472 |    472.502311 | Matt Crook                                                                                                                                                            |
| 375 |   1004.991061 |     72.894148 | Michelle Site                                                                                                                                                         |
| 376 |    363.378178 |    726.320066 | Jaime Headden                                                                                                                                                         |
| 377 |    536.194941 |    765.384818 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 378 |    338.727197 |    512.169013 | Joe Schneid (vectorized by T. Michael Keesey)                                                                                                                         |
| 379 |    352.858166 |    466.683383 | Tasman Dixon                                                                                                                                                          |
| 380 |    987.205411 |    452.361066 | Scott Hartman                                                                                                                                                         |
| 381 |    577.880871 |    133.303678 | Armin Reindl                                                                                                                                                          |
| 382 |    259.130191 |    363.526511 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 383 |     49.967554 |    313.692460 | Zimices                                                                                                                                                               |
| 384 |    160.944748 |     56.690323 | Margot Michaud                                                                                                                                                        |
| 385 |    893.927727 |    138.402585 | Yan Wong from drawing by Joseph Smit                                                                                                                                  |
| 386 |     88.301538 |    101.713230 | Zimices                                                                                                                                                               |
| 387 |    711.777233 |      7.918134 | Steven Traver                                                                                                                                                         |
| 388 |    997.657845 |    242.682668 | Margot Michaud                                                                                                                                                        |
| 389 |    876.935893 |    540.495055 | Matt Crook                                                                                                                                                            |
| 390 |    848.398185 |    415.457203 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 391 |     22.490708 |     60.885221 | Matt Crook                                                                                                                                                            |
| 392 |    748.642482 |    380.363827 | Milton Tan                                                                                                                                                            |
| 393 |    501.245589 |    723.092168 | Steven Traver                                                                                                                                                         |
| 394 |    881.478047 |     75.955839 | M Kolmann                                                                                                                                                             |
| 395 |    143.958712 |    440.123349 | NA                                                                                                                                                                    |
| 396 |    874.265205 |    607.632829 | Margot Michaud                                                                                                                                                        |
| 397 |    562.302945 |     39.364169 | Christoph Schomburg                                                                                                                                                   |
| 398 |    631.691649 |     14.306309 | Steven Traver                                                                                                                                                         |
| 399 |     34.492520 |    312.487796 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 400 |    574.767953 |    182.377545 | Steven Traver                                                                                                                                                         |
| 401 |    571.043688 |    357.532442 | Jagged Fang Designs                                                                                                                                                   |
| 402 |    443.748323 |     55.445421 | Steven Traver                                                                                                                                                         |
| 403 |    338.145015 |    338.982227 | Nina Skinner                                                                                                                                                          |
| 404 |    607.725219 |    296.354059 | T. Michael Keesey                                                                                                                                                     |
| 405 |    939.339976 |    477.701877 | Michelle Site                                                                                                                                                         |
| 406 |    182.600640 |    720.597018 | James R. Spotila and Ray Chatterji                                                                                                                                    |
| 407 |    520.932684 |    408.906987 | Chris huh                                                                                                                                                             |
| 408 |    694.868752 |    454.821004 | Chris huh                                                                                                                                                             |
| 409 |    122.248841 |    530.935552 | Margot Michaud                                                                                                                                                        |
| 410 |    558.259336 |    425.054229 | Mathew Wedel                                                                                                                                                          |
| 411 |    837.641704 |    570.460634 | FunkMonk                                                                                                                                                              |
| 412 |    421.721013 |    240.578722 | Tess Linden                                                                                                                                                           |
| 413 |    791.615425 |     21.173512 | Collin Gross                                                                                                                                                          |
| 414 |    845.960078 |    317.822537 | Steven Coombs                                                                                                                                                         |
| 415 |     15.307087 |    412.328557 | NA                                                                                                                                                                    |
| 416 |    783.792659 |    426.836969 | Kamil S. Jaron                                                                                                                                                        |
| 417 |    116.487001 |    368.002382 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 418 |    445.802054 |    739.416490 | T. Michael Keesey                                                                                                                                                     |
| 419 |    382.115415 |    401.753950 | Kamil S. Jaron                                                                                                                                                        |
| 420 |    281.773133 |    669.333857 | Mo Hassan                                                                                                                                                             |
| 421 |    816.130731 |    785.163837 | Gareth Monger                                                                                                                                                         |
| 422 |    510.367763 |    269.959991 | Scott Hartman                                                                                                                                                         |
| 423 |     19.106849 |    176.837507 | Matt Crook                                                                                                                                                            |
| 424 |    358.745105 |    450.273970 | Beth Reinke                                                                                                                                                           |
| 425 |    769.987647 |    474.198333 | C. Camilo Julián-Caballero                                                                                                                                            |
| 426 |    637.280489 |    324.165182 | John Curtis (vectorized by T. Michael Keesey)                                                                                                                         |
| 427 |    638.314416 |    303.300997 | Becky Barnes                                                                                                                                                          |
| 428 |    138.104719 |    487.647965 | T. Michael Keesey                                                                                                                                                     |
| 429 |    218.430038 |     17.450026 | NA                                                                                                                                                                    |
| 430 |    495.652146 |    137.567098 | Harold N Eyster                                                                                                                                                       |
| 431 |    574.222036 |     20.062651 | L. Shyamal                                                                                                                                                            |
| 432 |     32.481907 |    783.956525 | Sam Fraser-Smith (vectorized by T. Michael Keesey)                                                                                                                    |
| 433 |     81.156513 |    785.105699 | Ferran Sayol                                                                                                                                                          |
| 434 |    180.578596 |    307.943298 | Carlos Cano-Barbacil                                                                                                                                                  |
| 435 |    200.054257 |     63.435930 | Chris huh                                                                                                                                                             |
| 436 |    243.678827 |    472.464719 | Tasman Dixon                                                                                                                                                          |
| 437 |    531.820262 |    373.960393 | Matt Crook                                                                                                                                                            |
| 438 |    469.677249 |     42.255994 | CNZdenek                                                                                                                                                              |
| 439 |    910.620981 |    115.352946 | NA                                                                                                                                                                    |
| 440 |    469.669671 |    240.975535 | Mattia Menchetti                                                                                                                                                      |
| 441 |    489.311683 |    390.681594 | Dean Schnabel                                                                                                                                                         |
| 442 |    544.791400 |    415.126625 | Margot Michaud                                                                                                                                                        |
| 443 |    691.796200 |    643.654668 | Kelly                                                                                                                                                                 |
| 444 |    986.725395 |    225.807380 | Alex Slavenko                                                                                                                                                         |
| 445 |    608.286913 |     70.258517 | Jagged Fang Designs                                                                                                                                                   |
| 446 |    225.323084 |    742.289455 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
| 447 |   1006.233551 |    731.023362 | Christoph Schomburg                                                                                                                                                   |
| 448 |    592.559996 |    742.982712 | NA                                                                                                                                                                    |
| 449 |    490.162080 |    785.883495 | Matt Crook                                                                                                                                                            |
| 450 |    247.272086 |     99.290692 | T. Michael Keesey                                                                                                                                                     |
| 451 |    223.249934 |    787.616493 | Steven Traver                                                                                                                                                         |
| 452 |    569.143004 |    462.955586 | Steven Coombs                                                                                                                                                         |
| 453 |    814.369244 |    409.089125 | Chris Jennings (Risiatto)                                                                                                                                             |
| 454 |   1013.707716 |    679.100886 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                                           |
| 455 |    780.108661 |    717.309947 | New York Zoological Society                                                                                                                                           |
| 456 |    712.465446 |    287.882066 | Zimices                                                                                                                                                               |
| 457 |    975.832220 |    566.951748 | Alan Manson (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
| 458 |    593.946807 |    182.688075 | Ferran Sayol                                                                                                                                                          |
| 459 |    764.567872 |    566.909502 | T. Michael Keesey                                                                                                                                                     |
| 460 |    181.800727 |    202.851333 | Josep Marti Solans                                                                                                                                                    |
| 461 |    448.050090 |    703.204283 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 462 |    291.977881 |     94.689846 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 463 |    239.275295 |    155.360570 | A. R. McCulloch (vectorized by T. Michael Keesey)                                                                                                                     |
| 464 |      8.679182 |    732.169158 | T. Michael Keesey                                                                                                                                                     |
| 465 |    480.436699 |     51.527308 | David Orr                                                                                                                                                             |
| 466 |    687.872179 |    573.196004 | terngirl                                                                                                                                                              |
| 467 |    542.777456 |    425.375629 | Sarah Werning                                                                                                                                                         |
| 468 |    526.178410 |     36.043141 | Margot Michaud                                                                                                                                                        |
| 469 |    335.227758 |    609.302013 | Sarah Werning                                                                                                                                                         |
| 470 |    432.986772 |    736.808710 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 471 |     93.760585 |    504.536832 | Matt Crook                                                                                                                                                            |
| 472 |    276.907524 |    115.060274 | T. Michael Keesey                                                                                                                                                     |
| 473 |    560.381476 |    435.605140 | Mariana Ruiz (vectorized by T. Michael Keesey)                                                                                                                        |
| 474 |     25.708062 |     90.609495 | Falconaumanni and T. Michael Keesey                                                                                                                                   |
| 475 |    865.039438 |    402.539558 | Gareth Monger                                                                                                                                                         |
| 476 |    315.729586 |    380.788430 | Michael P. Taylor                                                                                                                                                     |
| 477 |    145.702269 |     46.497035 | L. Shyamal                                                                                                                                                            |
| 478 |    988.570706 |    670.772578 | Matt Crook                                                                                                                                                            |
| 479 |     17.045377 |     32.536823 | Matt Crook                                                                                                                                                            |
| 480 |    989.142824 |    178.977782 | Maija Karala                                                                                                                                                          |
| 481 |     21.931217 |    443.869071 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 482 |     47.127760 |     19.979862 | Stuart Humphries                                                                                                                                                      |
| 483 |    788.500867 |    364.697697 | Christoph Schomburg                                                                                                                                                   |
| 484 |    826.155839 |    714.402491 | Jaime Headden                                                                                                                                                         |
| 485 |    754.420748 |      6.131364 | Jagged Fang Designs                                                                                                                                                   |
| 486 |    760.188546 |    493.767072 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 487 |    200.656421 |     54.166593 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 488 |    641.401154 |    379.298173 | Tomas Willems (vectorized by T. Michael Keesey)                                                                                                                       |
| 489 |    900.631072 |    544.113107 | Abraão B. Leite                                                                                                                                                       |
| 490 |    537.840857 |    379.449534 | Kamil S. Jaron                                                                                                                                                        |
| 491 |    741.885315 |    588.355070 | Sam Fraser-Smith (vectorized by T. Michael Keesey)                                                                                                                    |
| 492 |    518.062283 |    785.063840 | Margot Michaud                                                                                                                                                        |
| 493 |    205.280953 |    326.368828 | Steven Traver                                                                                                                                                         |
| 494 |    674.472001 |    682.888858 | Steven Traver                                                                                                                                                         |
| 495 |   1007.273241 |    291.857057 | Mason McNair                                                                                                                                                          |
| 496 |    453.804502 |     73.782742 | Sean McCann                                                                                                                                                           |
| 497 |    120.338777 |    488.761416 | T. Michael Keesey (after MPF)                                                                                                                                         |
| 498 |    773.127808 |    434.145477 | Gareth Monger                                                                                                                                                         |
| 499 |    799.147804 |    410.159182 | C. Abraczinskas                                                                                                                                                       |
| 500 |    443.966853 |    325.260352 | Jagged Fang Designs                                                                                                                                                   |
| 501 |    315.727450 |    100.886102 | Margot Michaud                                                                                                                                                        |
| 502 |    824.066368 |    576.829256 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                                           |
| 503 |    868.373735 |    396.176346 | Michael P. Taylor                                                                                                                                                     |
| 504 |     87.102369 |     70.232110 | David Orr                                                                                                                                                             |
| 505 |    291.042283 |    589.999989 | Armin Reindl                                                                                                                                                          |
| 506 |    982.699830 |    234.003457 | Zachary Quigley                                                                                                                                                       |
| 507 |    428.810009 |     51.898103 | Aleksey Nagovitsyn (vectorized by T. Michael Keesey)                                                                                                                  |
| 508 |    812.581715 |    661.828543 | Matt Crook                                                                                                                                                            |
| 509 |    297.856352 |    109.576545 | Zimices                                                                                                                                                               |
| 510 |    126.410796 |    545.846889 | Zimices                                                                                                                                                               |
| 511 |    432.666266 |    363.078068 | Samanta Orellana                                                                                                                                                      |
| 512 |    907.018107 |    646.863513 | Ferran Sayol                                                                                                                                                          |
| 513 |    126.748264 |    696.101799 | Tauana J. Cunha                                                                                                                                                       |
| 514 |    533.078205 |    452.302453 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                        |
| 515 |      7.424108 |    578.016447 | Aviceda (photo) & T. Michael Keesey                                                                                                                                   |
| 516 |    859.924483 |     14.448615 | Oscar Sanisidro                                                                                                                                                       |
| 517 |    951.539920 |    720.557899 | Chris huh                                                                                                                                                             |
| 518 |    861.576379 |    103.448348 | Zimices / Julián Bayona                                                                                                                                               |
| 519 |    983.874862 |    288.102434 | Trond R. Oskars                                                                                                                                                       |
| 520 |    163.435635 |    194.704456 | Vanessa Guerra                                                                                                                                                        |
| 521 |     51.240498 |    275.406627 | Shyamal                                                                                                                                                               |
| 522 |    918.846883 |    486.880408 | Farelli (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
| 523 |    596.913420 |    169.569796 | Alex Slavenko                                                                                                                                                         |
| 524 |    593.429723 |    671.381312 | Gareth Monger                                                                                                                                                         |
| 525 |    101.053684 |    349.198901 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 526 |    993.233580 |    709.044617 | Matt Crook                                                                                                                                                            |
| 527 |     16.127071 |    459.798183 | Margot Michaud                                                                                                                                                        |
| 528 |   1000.065242 |    482.440027 | Matt Crook                                                                                                                                                            |
| 529 |     83.246588 |    625.048360 | Margot Michaud                                                                                                                                                        |
| 530 |    864.068254 |    182.687084 | Zimices                                                                                                                                                               |
| 531 |    930.122897 |    318.479769 | Jessica Anne Miller                                                                                                                                                   |
| 532 |    577.954905 |    117.410748 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                  |
| 533 |    345.017168 |    497.761387 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 534 |    295.984140 |     57.468778 | Margot Michaud                                                                                                                                                        |
| 535 |    780.695158 |    597.962263 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 536 |    484.989869 |    273.449369 | Armin Reindl                                                                                                                                                          |
| 537 |    412.985285 |    778.758115 | NA                                                                                                                                                                    |
| 538 |    428.584384 |    217.432450 | Rebecca Groom                                                                                                                                                         |
| 539 |    799.797508 |     83.288844 | Ferran Sayol                                                                                                                                                          |
| 540 |    213.558245 |    607.064729 | Matt Crook                                                                                                                                                            |
| 541 |    498.888399 |    705.940884 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 542 |    100.830573 |    655.229987 | Arthur S. Brum                                                                                                                                                        |
| 543 |     19.131366 |    651.022864 | Margot Michaud                                                                                                                                                        |
| 544 |    384.777703 |    657.802462 | Kai R. Caspar                                                                                                                                                         |
| 545 |    580.559195 |    257.601168 | Gareth Monger                                                                                                                                                         |
| 546 |    590.372070 |    254.826628 | Gareth Monger                                                                                                                                                         |
| 547 |    415.419796 |    274.239832 | Steven Haddock • Jellywatch.org                                                                                                                                       |
| 548 |    671.725809 |     42.672798 | Zimices                                                                                                                                                               |
| 549 |    768.364828 |     85.618150 | Ferran Sayol                                                                                                                                                          |
| 550 |    713.127837 |    161.859699 | Zimices                                                                                                                                                               |
| 551 |    769.391548 |    495.569144 | Matt Crook                                                                                                                                                            |
| 552 |    732.777809 |    245.303800 | Alex Slavenko                                                                                                                                                         |
| 553 |    420.940100 |    498.013314 | Margot Michaud                                                                                                                                                        |
| 554 |   1014.686770 |    428.785821 | Tasman Dixon                                                                                                                                                          |
| 555 |     36.188029 |    346.446198 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 556 |    958.838599 |    542.607638 | Ingo Braasch                                                                                                                                                          |
| 557 |    899.323267 |     87.124912 | Matt Crook                                                                                                                                                            |
| 558 |    791.857409 |    405.027169 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 559 |    699.770809 |    153.834850 | Maija Karala                                                                                                                                                          |
| 560 |    369.074118 |    423.884827 | Martin R. Smith, after Skovsted et al 2015                                                                                                                            |
| 561 |    413.131807 |    220.323381 | Gareth Monger                                                                                                                                                         |
| 562 |    495.294259 |    217.748106 | Christine Axon                                                                                                                                                        |
| 563 |    962.813736 |    414.109500 | Steven Traver                                                                                                                                                         |
| 564 |    646.133179 |    723.805570 | Gareth Monger                                                                                                                                                         |
| 565 |    345.389243 |    452.050181 | Matt Crook                                                                                                                                                            |
| 566 |    525.108843 |    755.535155 | John Curtis (vectorized by T. Michael Keesey)                                                                                                                         |
| 567 |    172.362173 |    779.666201 | Ferran Sayol                                                                                                                                                          |
| 568 |    672.812857 |    463.616368 | Yan Wong                                                                                                                                                              |
| 569 |    751.253981 |     76.869076 | Ferran Sayol                                                                                                                                                          |
| 570 |    196.033105 |    385.471746 | Ferran Sayol                                                                                                                                                          |
| 571 |    860.908859 |    639.956409 | Kamil S. Jaron                                                                                                                                                        |
| 572 |    414.584703 |    258.118018 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                           |
| 573 |     64.259938 |    377.016790 | mystica                                                                                                                                                               |
| 574 |    854.611774 |    244.659505 | T. Michael Keesey                                                                                                                                                     |
| 575 |    281.240120 |    373.802173 | Scott Hartman                                                                                                                                                         |
| 576 |    558.385940 |    377.440697 | Sarah Werning                                                                                                                                                         |
| 577 |    867.348864 |    367.472753 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 578 |    395.159204 |    786.839872 | Lukasiniho                                                                                                                                                            |
| 579 |    604.488526 |    694.670273 | NA                                                                                                                                                                    |
| 580 |    225.057057 |    100.696647 | Christine Axon                                                                                                                                                        |
| 581 |     62.814241 |    478.573999 | NA                                                                                                                                                                    |
| 582 |    312.013304 |    306.795811 | Matt Crook                                                                                                                                                            |
| 583 |    784.770452 |    660.776535 | Christoph Schomburg                                                                                                                                                   |
| 584 |    355.886358 |    166.336754 | Renata F. Martins                                                                                                                                                     |
| 585 |    645.136770 |     42.872404 | Sean McCann                                                                                                                                                           |
| 586 |    501.596450 |    735.875484 | Michael Scroggie, from original photograph by Gary M. Stolz, USFWS (original photograph in public domain).                                                            |
| 587 |    315.936557 |    119.410597 | Mateus Zica (modified by T. Michael Keesey)                                                                                                                           |
| 588 |    933.716450 |    486.374835 | Nobu Tamura                                                                                                                                                           |
| 589 |     27.067192 |    606.149590 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                               |
| 590 |     26.725965 |    183.571634 | Mariana Ruiz Villarreal (modified by T. Michael Keesey)                                                                                                               |
| 591 |    237.079306 |    530.913141 | NA                                                                                                                                                                    |
| 592 |    289.174826 |    556.582671 | Jagged Fang Designs                                                                                                                                                   |
| 593 |    959.176130 |    668.692428 | Scott Hartman                                                                                                                                                         |
| 594 |    710.447480 |    775.592014 | Original drawing by Nobu Tamura, vectorized by Roberto Díaz Sibaja                                                                                                    |
| 595 |    995.715463 |    277.398907 | Kai R. Caspar                                                                                                                                                         |
| 596 |    591.524984 |     69.143005 | Tasman Dixon                                                                                                                                                          |
| 597 |   1001.621015 |    721.004811 | Christine Axon                                                                                                                                                        |
| 598 |    741.520848 |     14.636551 | C. Camilo Julián-Caballero                                                                                                                                            |
| 599 |    403.410727 |    510.811477 | Zimices                                                                                                                                                               |
| 600 |     11.785766 |    286.690149 | Jagged Fang Designs                                                                                                                                                   |
| 601 |    722.447619 |    280.771263 | Jagged Fang Designs                                                                                                                                                   |
| 602 |    741.724577 |    441.132954 | Renata F. Martins                                                                                                                                                     |
| 603 |    582.672522 |     95.262851 | Margot Michaud                                                                                                                                                        |
| 604 |    593.983945 |    112.869015 | Collin Gross                                                                                                                                                          |
| 605 |    259.628195 |    507.219069 | Servien (vectorized by T. Michael Keesey)                                                                                                                             |
| 606 |    181.842503 |    571.599214 | Zimices                                                                                                                                                               |
| 607 |    677.363327 |    289.384568 | Steven Traver                                                                                                                                                         |
| 608 |    541.719499 |    447.084933 | Michael Scroggie                                                                                                                                                      |
| 609 |     86.471425 |    168.010554 | Kamil S. Jaron                                                                                                                                                        |
| 610 |    882.216669 |    152.045975 | Chris huh                                                                                                                                                             |
| 611 |    236.797013 |    244.286827 | Zimices                                                                                                                                                               |
| 612 |    290.417271 |    125.248681 | A. R. McCulloch (vectorized by T. Michael Keesey)                                                                                                                     |
| 613 |    434.633032 |    767.858691 | Scott Hartman, modified by T. Michael Keesey                                                                                                                          |
| 614 |    337.438735 |    371.450866 | Michael Scroggie                                                                                                                                                      |
| 615 |    131.732860 |    375.928169 | DW Bapst, modified from Ishitani et al. 2016                                                                                                                          |
| 616 |    925.681036 |    149.997894 | Matt Crook                                                                                                                                                            |
| 617 |   1005.522635 |    256.454608 | L. Shyamal                                                                                                                                                            |
| 618 |    318.221163 |    631.553987 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 619 |    463.444876 |    333.470370 | Felix Vaux                                                                                                                                                            |
| 620 |    291.652248 |    116.246762 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 621 |    754.441250 |    391.062234 | Michele M Tobias                                                                                                                                                      |
| 622 |   1009.258833 |    317.860160 | NA                                                                                                                                                                    |
| 623 |    314.461247 |    656.574439 | Dean Schnabel                                                                                                                                                         |
| 624 |    772.219026 |      8.365540 | Steven Traver                                                                                                                                                         |
| 625 |   1012.071421 |    277.180009 | Mark Hofstetter (vectorized by T. Michael Keesey)                                                                                                                     |
| 626 |     98.062472 |    487.952862 | Steven Traver                                                                                                                                                         |
| 627 |    762.638351 |    636.970043 | Tracy A. Heath                                                                                                                                                        |
| 628 |    318.185717 |    161.839500 | Steven Traver                                                                                                                                                         |
| 629 |   1019.656891 |    579.990787 | Melissa Broussard                                                                                                                                                     |
| 630 |    971.545927 |    646.706541 | Stuart Humphries                                                                                                                                                      |
| 631 |    485.402947 |    347.719593 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 632 |    382.819923 |    777.655431 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
| 633 |    388.070332 |    446.958155 | Cesar Julian                                                                                                                                                          |
| 634 |    441.084470 |    149.797547 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 635 |     38.979510 |    447.623031 | Margot Michaud                                                                                                                                                        |
| 636 |    276.738973 |    655.407818 | Maija Karala                                                                                                                                                          |
| 637 |     70.413773 |    334.644448 | T. Michael Keesey                                                                                                                                                     |
| 638 |    434.224968 |    201.384249 | Wayne Decatur                                                                                                                                                         |
| 639 |    859.901703 |    255.985271 | Michael B. H. (vectorized by T. Michael Keesey)                                                                                                                       |
| 640 |    599.823676 |    268.600668 | Andrew A. Farke                                                                                                                                                       |
| 641 |     38.953672 |    637.723116 | Peter Coxhead                                                                                                                                                         |
| 642 |    611.984731 |    156.911975 | Karl Ragnar Gjertsen (vectorized by T. Michael Keesey)                                                                                                                |
| 643 |    696.566002 |    629.551014 | Ferran Sayol                                                                                                                                                          |
| 644 |    396.580699 |    692.812521 | Mathew Stewart                                                                                                                                                        |
| 645 |    532.676010 |    110.219742 | Dean Schnabel                                                                                                                                                         |
| 646 |    302.123355 |    729.570162 | Matt Crook                                                                                                                                                            |
| 647 |    498.875348 |    750.880201 | Anthony Caravaggi                                                                                                                                                     |
| 648 |    757.235560 |    452.890102 | Ryan Cupo                                                                                                                                                             |
| 649 |    302.821928 |    289.056617 | Katie S. Collins                                                                                                                                                      |
| 650 |    453.169683 |    683.915799 | Matt Crook                                                                                                                                                            |
| 651 |    346.229024 |    235.141182 | NA                                                                                                                                                                    |
| 652 |    179.298971 |     91.908456 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                      |
| 653 |    637.543138 |    780.045940 | Margot Michaud                                                                                                                                                        |
| 654 |    478.143968 |    457.887778 | Steven Traver                                                                                                                                                         |
| 655 |    286.465019 |    489.397264 | Steven Traver                                                                                                                                                         |
| 656 |    725.435102 |    418.121661 | Michael Scroggie                                                                                                                                                      |
| 657 |     24.211958 |    161.217055 | Zimices                                                                                                                                                               |
| 658 |     73.032576 |    177.816512 | Zimices                                                                                                                                                               |
| 659 |     71.894456 |    594.668980 | Melissa Broussard                                                                                                                                                     |
| 660 |    135.959585 |    287.698395 | Chris huh                                                                                                                                                             |
| 661 |    518.403175 |    506.725136 | Rebecca Groom                                                                                                                                                         |
| 662 |    465.901995 |     55.134053 | Collin Gross                                                                                                                                                          |
| 663 |    982.422882 |    782.179706 | NA                                                                                                                                                                    |
| 664 |    730.342284 |    185.982866 | Ferran Sayol                                                                                                                                                          |
| 665 |     32.641091 |    168.226037 | Beth Reinke                                                                                                                                                           |
| 666 |     91.246391 |    653.627008 | Frank Denota                                                                                                                                                          |
| 667 |     60.239666 |    301.714048 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 668 |    927.731583 |     10.575819 | NA                                                                                                                                                                    |
| 669 |    800.281595 |    434.054501 | Katie S. Collins                                                                                                                                                      |
| 670 |    176.462214 |    268.347797 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 671 |    688.160448 |    284.980075 | Ferran Sayol                                                                                                                                                          |
| 672 |    423.878221 |    415.855878 | Samanta Orellana                                                                                                                                                      |
| 673 |    839.341175 |      2.423538 | Manabu Bessho-Uehara                                                                                                                                                  |
| 674 |    923.965470 |    139.208052 | Tasman Dixon                                                                                                                                                          |
| 675 |    946.597797 |    674.097166 | Margot Michaud                                                                                                                                                        |
| 676 |     28.629294 |     72.216399 | Claus Rebler                                                                                                                                                          |
| 677 |    213.373473 |    730.158612 | NA                                                                                                                                                                    |
| 678 |    983.083236 |    579.021213 | Birgit Lang                                                                                                                                                           |
| 679 |     41.725785 |    354.223334 | E. R. Waite & H. M. Hale (vectorized by T. Michael Keesey)                                                                                                            |
| 680 |    149.520402 |    461.024194 | T. Michael Keesey (after Kukalová)                                                                                                                                    |
| 681 |     27.505772 |    494.248350 | Jonathan Wells                                                                                                                                                        |
| 682 |    653.109431 |    640.855577 | Dean Schnabel                                                                                                                                                         |
| 683 |    530.479770 |      6.237794 | Zimices                                                                                                                                                               |
| 684 |    816.957184 |    552.920668 | Michelle Site                                                                                                                                                         |
| 685 |    921.470409 |     66.585041 | Mali’o Kodis, photograph property of National Museums of Northern Ireland                                                                                             |
| 686 |    752.848622 |    532.770704 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 687 |    804.126273 |    567.834048 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                              |
| 688 |    186.181540 |    783.409287 | Sarefo (vectorized by T. Michael Keesey)                                                                                                                              |
| 689 |     95.344348 |    111.947069 | Matt Crook                                                                                                                                                            |
| 690 |    336.780476 |    130.698140 | Matt Crook                                                                                                                                                            |
| 691 |    481.733419 |    401.971186 | Chris huh                                                                                                                                                             |
| 692 |    454.584070 |    454.460754 | Zimices                                                                                                                                                               |
| 693 |     98.225427 |    293.037898 | Tasman Dixon                                                                                                                                                          |
| 694 |    516.876056 |    233.610299 | Felix Vaux                                                                                                                                                            |
| 695 |    978.204497 |    635.765466 | Francis de Laporte de Castelnau (vectorized by T. Michael Keesey)                                                                                                     |
| 696 |    328.091046 |    472.584388 | Gareth Monger                                                                                                                                                         |
| 697 |    843.214253 |    650.607476 | T. Michael Keesey                                                                                                                                                     |
| 698 |     41.774227 |    488.923657 | Katie S. Collins                                                                                                                                                      |
| 699 |     61.213328 |    748.444163 | NA                                                                                                                                                                    |
| 700 |   1010.075960 |     97.728264 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                      |
| 701 |    985.008345 |    213.111586 | NA                                                                                                                                                                    |
| 702 |    622.211320 |    779.346180 | Steven Traver                                                                                                                                                         |
| 703 |    829.002968 |    354.949849 | Zimices                                                                                                                                                               |
| 704 |    275.940848 |    695.802696 | Emily Jane McTavish, from <http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>                                                           |
| 705 |    827.834346 |    686.385965 | Gareth Monger                                                                                                                                                         |
| 706 |    420.363645 |    195.058124 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                     |
| 707 |    204.334906 |      4.826767 | Tracy A. Heath                                                                                                                                                        |
| 708 |    846.070317 |    262.805498 | Jaime Headden                                                                                                                                                         |
| 709 |    472.440442 |    280.400048 | Taro Maeda                                                                                                                                                            |
| 710 |    420.138868 |     67.928829 | Christine Axon                                                                                                                                                        |
| 711 |    343.532754 |    482.459190 | NA                                                                                                                                                                    |
| 712 |    933.996824 |    463.339799 | NA                                                                                                                                                                    |
| 713 |    458.797993 |    358.765873 | Remes K, Ortega F, Fierro I, Joger U, Kosma R, et al.                                                                                                                 |
| 714 |    263.083777 |    391.615083 | Chris Jennings (vectorized by A. Verrière)                                                                                                                            |
| 715 |    931.534996 |    792.087055 | Margot Michaud                                                                                                                                                        |
| 716 |      9.733582 |     16.901625 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 717 |     64.153961 |    404.292809 | Nick Schooler                                                                                                                                                         |
| 718 |    212.420485 |    258.075237 | Zimices                                                                                                                                                               |
| 719 |    921.244996 |    639.608602 | Margot Michaud                                                                                                                                                        |
| 720 |    554.134091 |    452.800341 | NA                                                                                                                                                                    |
| 721 |    482.948620 |    226.684546 | T. Michael Keesey                                                                                                                                                     |
| 722 |    281.779043 |    136.784375 | Jaime Headden                                                                                                                                                         |
| 723 |    366.110090 |    589.332715 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 724 |    866.858024 |    734.422227 | Servien (vectorized by T. Michael Keesey)                                                                                                                             |
| 725 |    534.937065 |    659.549850 | Margot Michaud                                                                                                                                                        |
| 726 |    419.663405 |     90.319119 | Iain Reid                                                                                                                                                             |
| 727 |    206.710249 |    666.334043 | Scott Hartman                                                                                                                                                         |
| 728 |    388.014599 |     88.283826 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
| 729 |     43.247340 |    741.204520 | Scott Hartman                                                                                                                                                         |
| 730 |    929.772140 |    158.361893 | Maxime Dahirel                                                                                                                                                        |
| 731 |    916.200517 |     84.450566 | Pedro de Siracusa                                                                                                                                                     |
| 732 |    827.036968 |    280.346919 | Xavier Giroux-Bougard                                                                                                                                                 |
| 733 |     90.963229 |    443.010644 | Myriam\_Ramirez                                                                                                                                                       |
| 734 |    859.159722 |    162.222430 | Tasman Dixon                                                                                                                                                          |
| 735 |     51.789839 |    238.674789 | NA                                                                                                                                                                    |
| 736 |    923.699111 |    422.369114 | Dean Schnabel                                                                                                                                                         |
| 737 |    757.712713 |    420.972276 | Zimices                                                                                                                                                               |
| 738 |    383.553114 |    344.118563 | Kamil S. Jaron                                                                                                                                                        |
| 739 |     52.574036 |    227.143882 | Chris huh                                                                                                                                                             |
| 740 |    184.090838 |    364.327202 | Matt Crook                                                                                                                                                            |
| 741 |     84.828126 |    157.538915 | Pollyanna von Knorring and T. Michael Keesey                                                                                                                          |
| 742 |    527.367605 |     26.296048 | Michelle Site                                                                                                                                                         |
| 743 |    547.315381 |    124.179388 | Zimices                                                                                                                                                               |
| 744 |    261.668649 |    150.674007 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 745 |    289.238812 |    572.421071 | Matt Crook                                                                                                                                                            |
| 746 |    794.627019 |    110.468979 | Zimices                                                                                                                                                               |
| 747 |    512.992856 |    766.666836 | Margot Michaud                                                                                                                                                        |
| 748 |    440.881102 |    303.535791 | Ferran Sayol                                                                                                                                                          |
| 749 |    829.975779 |    665.070296 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 750 |    567.804570 |    369.663583 | NA                                                                                                                                                                    |
| 751 |    897.842217 |    100.177559 | Zimices                                                                                                                                                               |
| 752 |    207.343879 |    370.296316 | xgirouxb                                                                                                                                                              |
| 753 |    400.651263 |     46.221725 | Chase Brownstein                                                                                                                                                      |
| 754 |    943.692895 |    367.673121 | Steven Traver                                                                                                                                                         |
| 755 |    324.545253 |    150.498101 | Iain Reid                                                                                                                                                             |
| 756 |    814.649524 |    619.525300 | B. Duygu Özpolat                                                                                                                                                      |
| 757 |    365.557646 |    583.654759 | NA                                                                                                                                                                    |
| 758 |     88.632880 |    139.212106 | Margot Michaud                                                                                                                                                        |
| 759 |    658.831780 |    726.027668 | Theodore W. Pietsch (photography) and T. Michael Keesey (vectorization)                                                                                               |
| 760 |    759.472351 |    484.114767 | Birgit Lang                                                                                                                                                           |
| 761 |    325.717787 |    765.080503 | T. Michael Keesey (after James & al.)                                                                                                                                 |
| 762 |    727.598533 |    453.612775 | Katie S. Collins                                                                                                                                                      |
| 763 |    705.395853 |    666.339042 | Steven Traver                                                                                                                                                         |
| 764 |    666.351101 |    160.283566 | Kamil S. Jaron                                                                                                                                                        |
| 765 |    669.613115 |    401.995321 | Bob Goldstein, Vectorization:Jake Warner                                                                                                                              |
| 766 |    845.701738 |     86.267697 | Matt Crook                                                                                                                                                            |
| 767 |     64.321015 |    155.927096 | Alex Slavenko                                                                                                                                                         |
| 768 |     68.960808 |    349.925297 | Martin R. Smith                                                                                                                                                       |
| 769 |    728.038001 |      5.752206 | Zimices                                                                                                                                                               |
| 770 |     67.451288 |    768.216417 | Chris huh                                                                                                                                                             |
| 771 |    929.999424 |    521.855746 | Ferran Sayol                                                                                                                                                          |
| 772 |    149.109318 |    791.407902 | Renata F. Martins                                                                                                                                                     |
| 773 |    552.680572 |    464.081951 | Gareth Monger                                                                                                                                                         |
| 774 |    353.854686 |    428.868495 | Scott Reid                                                                                                                                                            |
| 775 |    339.885411 |    710.254515 | Margot Michaud                                                                                                                                                        |
| 776 |    660.007257 |     19.812442 | Chris huh                                                                                                                                                             |
| 777 |    179.964196 |    370.913321 | Isaure Scavezzoni                                                                                                                                                     |
| 778 |    684.765333 |    117.006211 | Jagged Fang Designs                                                                                                                                                   |
| 779 |    108.714130 |    505.224436 | Matt Crook                                                                                                                                                            |
| 780 |    546.474865 |    498.128993 | Gareth Monger                                                                                                                                                         |
| 781 |    664.832717 |     63.947034 | Chris huh                                                                                                                                                             |
| 782 |    359.094805 |    302.175373 | T. Michael Keesey (vector) and Stuart Halliday (photograph)                                                                                                           |
| 783 |    375.446809 |    186.715125 | Birgit Lang, based on a photo by D. Sikes                                                                                                                             |
| 784 |    397.189528 |    128.149254 | Chris huh                                                                                                                                                             |
| 785 |    780.340908 |    101.000492 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                                         |
| 786 |    377.558747 |    247.089987 | Zimices                                                                                                                                                               |
| 787 |    643.367207 |    171.811219 | Yusan Yang                                                                                                                                                            |
| 788 |      8.943721 |    378.874685 | Tracy A. Heath                                                                                                                                                        |
| 789 |    198.896672 |    788.854793 | Joanna Wolfe                                                                                                                                                          |
| 790 |    260.038370 |    588.896863 | NA                                                                                                                                                                    |
| 791 |    430.173820 |    121.268710 | Shyamal                                                                                                                                                               |
| 792 |   1015.990106 |    294.173049 | Dean Schnabel                                                                                                                                                         |
| 793 |    816.549234 |    323.939253 | Michael P. Taylor                                                                                                                                                     |
| 794 |    962.951382 |    351.208086 | Sean McCann                                                                                                                                                           |
| 795 |    175.712363 |    249.567219 | Birgit Lang                                                                                                                                                           |
| 796 |    185.490046 |    771.578505 | Birgit Lang; based on a drawing by C.L. Koch                                                                                                                          |
| 797 |    827.665793 |    412.461332 | Sean McCann                                                                                                                                                           |
| 798 |    363.665940 |    791.597034 | Michelle Site                                                                                                                                                         |
| 799 |    226.384797 |    251.661660 | NA                                                                                                                                                                    |
| 800 |    313.475117 |    284.102164 | Matthew E. Clapham                                                                                                                                                    |
| 801 |    981.324297 |    720.201780 | NA                                                                                                                                                                    |
| 802 |     54.256192 |    750.887954 | Collin Gross                                                                                                                                                          |
| 803 |    607.994164 |    770.562258 | Ferran Sayol                                                                                                                                                          |
| 804 |    718.893829 |    148.896450 | Zimices                                                                                                                                                               |
| 805 |    519.116402 |     16.074175 | Ewald Rübsamen                                                                                                                                                        |
| 806 |    868.652989 |    535.141968 | Jaime Headden                                                                                                                                                         |
| 807 |    265.073223 |    565.219232 | NA                                                                                                                                                                    |
| 808 |    976.908106 |    364.646061 | Gopal Murali                                                                                                                                                          |
| 809 |    749.008164 |    116.567760 | T. Michael Keesey (vectorization) and Tony Hisgett (photography)                                                                                                      |
| 810 |    726.807188 |    475.314478 | Steven Traver                                                                                                                                                         |
| 811 |    481.337233 |    751.278304 | Birgit Lang                                                                                                                                                           |
| 812 |    976.326578 |    661.278382 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 813 |    696.977714 |    289.923056 | Steven Traver                                                                                                                                                         |
| 814 |    564.584138 |    415.295898 | E. J. Van Nieukerken, A. Laštuvka, and Z. Laštuvka (vectorized by T. Michael Keesey)                                                                                  |
| 815 |    590.449008 |    246.495803 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                        |
| 816 |    361.812244 |    235.876613 | Mathieu Basille                                                                                                                                                       |
| 817 |    312.155272 |    638.615333 | NA                                                                                                                                                                    |
| 818 |    591.147985 |     21.850047 | Thibaut Brunet                                                                                                                                                        |
| 819 |    646.555840 |    314.400441 | Lafage                                                                                                                                                                |
| 820 |    124.628571 |    627.687401 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                        |
| 821 |    525.731732 |    145.823259 | NA                                                                                                                                                                    |
| 822 |    280.372738 |    585.635603 | Steven Traver                                                                                                                                                         |
| 823 |     83.453708 |    740.989801 | Mali’o Kodis, image from Higgins and Kristensen, 1986                                                                                                                 |
| 824 |    400.021617 |    230.816539 | Cesar Julian                                                                                                                                                          |
| 825 |    347.317639 |    614.053213 | Scott Hartman                                                                                                                                                         |
| 826 |     87.713777 |    189.912984 | Scott Hartman                                                                                                                                                         |
| 827 |    164.880628 |    794.120420 | Jagged Fang Designs                                                                                                                                                   |
| 828 |    499.613532 |    499.891631 | New York Zoological Society                                                                                                                                           |
| 829 |    578.814494 |    475.253209 | NA                                                                                                                                                                    |
| 830 |    106.370044 |    557.145904 | Tracy A. Heath                                                                                                                                                        |
| 831 |    812.192429 |    701.797408 | Julien Louys                                                                                                                                                          |
| 832 |    384.064329 |    216.148640 | Mo Hassan                                                                                                                                                             |
| 833 |    180.988557 |    179.819731 | Kamil S. Jaron                                                                                                                                                        |
| 834 |    403.219406 |    500.768937 | Steven Traver                                                                                                                                                         |
| 835 |    727.154656 |    211.150370 | Margot Michaud                                                                                                                                                        |
| 836 |    401.515744 |    192.829086 | Arthur Grosset (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey        |
| 837 |      9.318439 |    796.907658 | Caleb M. Brown                                                                                                                                                        |
| 838 |    158.453819 |     18.903427 | xgirouxb                                                                                                                                                              |
| 839 |    986.986909 |    371.784340 | Steven Traver                                                                                                                                                         |
| 840 |    576.827602 |    749.024385 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 841 |    728.028095 |    225.688056 | Matt Crook                                                                                                                                                            |
| 842 |    128.539803 |     66.824065 | Michelle Site                                                                                                                                                         |
| 843 |    195.539444 |    186.516709 | Griensteidl and T. Michael Keesey                                                                                                                                     |
| 844 |    566.064819 |    328.415141 | Armin Reindl                                                                                                                                                          |
| 845 |    250.509566 |    457.695455 | Noah Schlottman                                                                                                                                                       |
| 846 |    725.025118 |    671.325471 | Sharon Wegner-Larsen                                                                                                                                                  |
| 847 |    469.553717 |    268.435310 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 848 |    804.417032 |    369.266454 | Christoph Schomburg                                                                                                                                                   |
| 849 |    869.540831 |    388.389706 | Matt Crook                                                                                                                                                            |
| 850 |    680.807030 |    418.896902 | Zimices                                                                                                                                                               |
| 851 |    875.326638 |    519.228728 | Michael Scroggie                                                                                                                                                      |
| 852 |    989.548016 |    325.719915 | Cathy                                                                                                                                                                 |
| 853 |    205.663926 |    345.642134 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 854 |    595.853934 |    286.703770 | T. Michael Keesey                                                                                                                                                     |
| 855 |    924.569643 |     25.746711 | Pedro de Siracusa                                                                                                                                                     |
| 856 |    773.197116 |    130.038688 | Matt Crook                                                                                                                                                            |
| 857 |    298.412621 |    617.288204 | Duane Raver (vectorized by T. Michael Keesey)                                                                                                                         |
| 858 |      9.662479 |    694.345103 | Matt Crook                                                                                                                                                            |
| 859 |    861.912737 |    146.001903 | NA                                                                                                                                                                    |
| 860 |   1014.748210 |    482.847075 | NA                                                                                                                                                                    |
| 861 |     87.484926 |    758.493443 | Plukenet                                                                                                                                                              |
| 862 |    737.690825 |    145.463047 | NA                                                                                                                                                                    |
| 863 |    495.568484 |     44.960669 | Zimices                                                                                                                                                               |
| 864 |     60.332185 |    322.969800 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 865 |    219.755598 |     51.617085 | Mary Harrsch (modified by T. Michael Keesey)                                                                                                                          |
| 866 |     88.077485 |    579.769282 | Gustav Mützel                                                                                                                                                         |
| 867 |    731.253580 |    400.807822 | Gareth Monger                                                                                                                                                         |
| 868 |    217.279993 |    204.943166 | FJDegrange                                                                                                                                                            |
| 869 |    453.769537 |    134.396834 | Alex Slavenko                                                                                                                                                         |
| 870 |    861.708411 |    491.989182 | T. Michael Keesey                                                                                                                                                     |
| 871 |    754.381251 |     66.551519 | Johan Lindgren, Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe                                                                                                  |
| 872 |    793.601067 |    446.112243 | NA                                                                                                                                                                    |
| 873 |    592.688668 |    774.659890 | Tracy A. Heath                                                                                                                                                        |
| 874 |    927.916071 |    767.512672 | Claus Rebler                                                                                                                                                          |
| 875 |   1005.836102 |    786.728642 | Inessa Voet                                                                                                                                                           |
| 876 |    184.167618 |    563.718279 | Scott Hartman                                                                                                                                                         |
| 877 |    393.449137 |    601.922412 | Zimices                                                                                                                                                               |
| 878 |    913.634517 |    519.326863 | Margot Michaud                                                                                                                                                        |
| 879 |    230.917508 |    776.778005 | Ferran Sayol                                                                                                                                                          |
| 880 |    165.643302 |     99.003608 | Rebecca Groom                                                                                                                                                         |
| 881 |    754.685986 |    595.744608 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                          |
| 882 |    132.774122 |     11.696809 | Steven Traver                                                                                                                                                         |
| 883 |    403.239445 |    113.362926 | L. Shyamal                                                                                                                                                            |
| 884 |    383.142949 |    788.568387 | Christoph Schomburg                                                                                                                                                   |
| 885 |    421.314421 |    659.827459 | Zimices                                                                                                                                                               |
| 886 |    319.538355 |     65.158202 | Matt Wilkins                                                                                                                                                          |
| 887 |    200.704894 |    422.902697 | Falconaumanni and T. Michael Keesey                                                                                                                                   |
| 888 |   1014.995821 |    452.023497 | Zimices                                                                                                                                                               |
| 889 |    291.355166 |    328.006938 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 890 |    126.608860 |     29.745696 | Steven Traver                                                                                                                                                         |
| 891 |    733.003401 |    354.448892 | Scott Hartman                                                                                                                                                         |
| 892 |    246.459140 |    425.079376 | T. Michael Keesey                                                                                                                                                     |
| 893 |    390.929778 |    145.457796 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 894 |    450.953383 |    313.808342 | Kamil S. Jaron                                                                                                                                                        |
| 895 |    717.520092 |    236.739827 | Zimices                                                                                                                                                               |
| 896 |    159.932809 |    443.973591 | Michelle Site                                                                                                                                                         |
| 897 |     24.101863 |    479.517965 | Zimices                                                                                                                                                               |
| 898 |    377.448346 |    770.216761 | Jaime Chirinos (vectorized by T. Michael Keesey)                                                                                                                      |
| 899 |    787.192918 |    119.250006 | Margot Michaud                                                                                                                                                        |
| 900 |    149.610125 |    631.819024 | Madeleine Price Ball                                                                                                                                                  |
| 901 |    944.594061 |    528.737024 | NA                                                                                                                                                                    |
| 902 |    255.443295 |    341.225287 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 903 |    123.130661 |    722.714422 | Michael Day                                                                                                                                                           |
| 904 |    985.833917 |    194.873810 | Margot Michaud                                                                                                                                                        |
| 905 |     62.009201 |    170.327319 | Matt Crook                                                                                                                                                            |
| 906 |    320.401324 |    742.846990 | T. Michael Keesey                                                                                                                                                     |
| 907 |    733.164093 |    174.873667 | Emily Willoughby                                                                                                                                                      |
| 908 |    340.915279 |    728.646405 | Margot Michaud                                                                                                                                                        |
| 909 |    794.585872 |    610.379567 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 910 |    772.805892 |    112.585724 | Chris huh                                                                                                                                                             |
| 911 |     36.319143 |     14.645837 | Maija Karala                                                                                                                                                          |
| 912 |    652.484934 |    156.180588 | Steven Traver                                                                                                                                                         |
| 913 |    829.156642 |    305.337673 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 914 |    165.288639 |    496.115376 | Chris huh                                                                                                                                                             |
| 915 |    363.013671 |     28.809821 | Tasman Dixon                                                                                                                                                          |
| 916 |    619.050300 |    760.613572 | T. Michael Keesey                                                                                                                                                     |
| 917 |    537.961700 |    133.380539 | Jaime Headden                                                                                                                                                         |
| 918 |    475.303706 |     11.194560 | Amanda Katzer                                                                                                                                                         |
| 919 |    880.125937 |    165.491944 | Margot Michaud                                                                                                                                                        |

    #> Your tweet has been posted!
