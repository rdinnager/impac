
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

Ferran Sayol, Markus A. Grohme, Matthew E. Clapham, Tracy A. Heath, Nobu
Tamura (vectorized by T. Michael Keesey), Dean Schnabel, Martin R.
Smith, Margot Michaud, Yan Wong, Christoph Schomburg, Dmitry Bogdanov
(vectorized by T. Michael Keesey), Matt Crook, Noah Schlottman, Ingo
Braasch, Richard Parker (vectorized by T. Michael Keesey), Andy Wilson,
Agnello Picorelli, Abraão Leite, Sharon Wegner-Larsen, T. Michael
Keesey, Mykle Hoban, Beth Reinke, Gabriela Palomo-Munoz, Gareth Monger,
Zimices, Erika Schumacher, Obsidian Soul (vectorized by T. Michael
Keesey), FunkMonk, Tasman Dixon, Kamil S. Jaron, Steven Traver, Scott
Hartman, Jon Hill (Photo by DickDaniels:
<http://en.wikipedia.org/wiki/File:Green_Woodhoopoe_RWD7.jpg>), Jagged
Fang Designs, FunkMonk \[Michael B.H.\] (modified by T. Michael Keesey),
Iain Reid, Chris huh, Eric Moody, Felix Vaux, Skye McDavid, Meyers
Konversations-Lexikon 1897 (vectorized: Yan Wong), Yan Wong from drawing
in The Century Dictionary (1911), Smokeybjb, Dantheman9758 (vectorized
by T. Michael Keesey), nicubunu, Alexander Schmidt-Lebuhn, Lindberg
(vectorized by T. Michael Keesey), David Tana, Renata F. Martins, Mike
Hanson, Frederick William Frohawk (vectorized by T. Michael Keesey),
Mathew Callaghan, Bruno C. Vellutini, Brad McFeeters (vectorized by T.
Michael Keesey), NASA, Maija Karala, Jessica Anne Miller, L. Shyamal,
Lafage, Nobu Tamura, Cesar Julian, Raven Amos, Hans Hillewaert, Dann
Pigdon, FJDegrange, Sergio A. Muñoz-Gómez, Conty (vectorized by T.
Michael Keesey), Arthur S. Brum, Anthony Caravaggi, Stemonitis
(photography) and T. Michael Keesey (vectorization), Mason McNair,
Steven Coombs (vectorized by T. Michael Keesey), Alexandre Vong, New
York Zoological Society, Verdilak, Birgit Lang, Siobhon Egan, xgirouxb,
Maxwell Lefroy (vectorized by T. Michael Keesey), Tauana J. Cunha,
Steven Haddock • Jellywatch.org, Sarah Werning, Michele M Tobias from an
image By Dcrjsr - Own work, CC BY 3.0,
<https://commons.wikimedia.org/w/index.php?curid=18059686>, Kimberly
Haddrell, Oscar Sanisidro, Meliponicultor Itaymbere, Lukasiniho, Roule
Jammes (vectorized by T. Michael Keesey), Scott Reid, Joshua Fowler,
Ignacio Contreras, James R. Spotila and Ray Chatterji, Emily Willoughby,
FunkMonk (Michael B.H.; vectorized by T. Michael Keesey), T. Tischler,
Tyler Greenfield and Dean Schnabel, Michael Scroggie, Pedro de Siracusa,
Collin Gross, Katie S. Collins, U.S. National Park Service (vectorized
by William Gearty), Caleb M. Brown, C. Camilo Julián-Caballero, Mathilde
Cordellier, Hugo Gruson, Caroline Harding, MAF (vectorized by T. Michael
Keesey), Michelle Site, 于川云, Rebecca Groom, M. A. Broussard, (after
Spotila 2004), Steven Blackwood, Griensteidl and T. Michael Keesey,
Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela
Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough
(vectorized by T. Michael Keesey), Lily Hughes, Mo Hassan, Mark
Hofstetter (vectorized by T. Michael Keesey), Peileppe, Steven Coombs,
Yan Wong from illustration by Charles Orbigny, Amanda Katzer, Matt
Martyniuk (modified by T. Michael Keesey), Mathew Wedel, Haplochromis
(vectorized by T. Michael Keesey), Air Kebir NRG, Tyler Greenfield,
Jaime Headden, Mathieu Basille, Armin Reindl, Chase Brownstein, Dmitry
Bogdanov, Diana Pomeroy, Sam Droege (photography) and T. Michael Keesey
(vectorization), SauropodomorphMonarch, Dr. Thomas G. Barnes, USFWS,
James Neenan, Nobu Tamura (vectorized by A. Verrière), T. Michael Keesey
(after Kukalová), Tyler McCraney, Kai R. Caspar, Duane Raver (vectorized
by T. Michael Keesey), Jan A. Venter, Herbert H. T. Prins, David A.
Balfour & Rob Slotow (vectorized by T. Michael Keesey), Robert Bruce
Horsfall, vectorized by Zimices, Frank Förster (based on a picture by
Jerry Kirkhart; modified by T. Michael Keesey), Antonov (vectorized by
T. Michael Keesey), Hans Hillewaert (vectorized by T. Michael Keesey),
L.M. Davalos, Mali’o Kodis, photograph by G. Giribet, David Orr, Juan
Carlos Jerí, Crystal Maier, Dmitry Bogdanov and FunkMonk (vectorized by
T. Michael Keesey), Jennifer Trimble, Mali’o Kodis, photograph by
“Wildcat Dunny” (<http://www.flickr.com/people/wildcat_dunny/>), Thea
Boodhoo (photograph) and T. Michael Keesey (vectorization), Theodore W.
Pietsch (photography) and T. Michael Keesey (vectorization), Jay
Matternes (vectorized by T. Michael Keesey), Maxime Dahirel, FunkMonk
(Michael B. H.), Dave Angelini, Melissa Ingala, Isaure Scavezzoni, Chris
Jennings (Risiatto), Julio Garza, Jack Mayer Wood, Kent Elson Sorgon,
Manabu Sakamoto, Noah Schlottman, photo from Casey Dunn, T. Michael
Keesey (vectorization) and Larry Loos (photography), Lisa Byrne, Renato
Santos, Caleb M. Gordon, E. Lear, 1819 (vectorization by Yan Wong),
Scarlet23 (vectorized by T. Michael Keesey), Elisabeth Östman, Catherine
Yasuda, Matt Martyniuk, T. Michael Keesey (photo by Bc999 \[Black
crow\]), Christine Axon, Marmelad, \[unknown\], Ieuan Jones, Paul O.
Lewis, Roberto Díaz Sibaja, Timothy Knepp of the U.S. Fish and Wildlife
Service (illustration) and Timothy J. Bartley (silhouette), Apokryltaros
(vectorized by T. Michael Keesey), terngirl, Jiekun He, Yan Wong
(vectorization) from 1873 illustration, Baheerathan Murugavel, Ville
Koistinen and T. Michael Keesey, Derek Bakken (photograph) and T.
Michael Keesey (vectorization), Jakovche, Martin R. Smith, from photo by
Jürgen Schoner, Maxime Dahirel (digitisation), Kees van Achterberg et al
(doi: 10.3897/BDJ.8.e49017)(original publication), Chloé Schmidt, Ben
Liebeskind, Martin Kevil, CNZdenek, Smokeybjb, vectorized by Zimices,
Nobu Tamura, vectorized by Zimices, Noah Schlottman, photo by Casey
Dunn, François Michonneau, Alan Manson (photo), John E. McCormack,
Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C.
Glenn, Robb T. Brumfield & T. Michael Keesey, Duane Raver/USFWS, Martin
R. Smith, after Skovsted et al 2015, Caio Bernardes, vectorized by
Zimices, Jose Carlos Arenas-Monroy, Mattia Menchetti, Jon Hill, Michael
Day, Leon P. A. M. Claessens, Patrick M. O’Connor, David M. Unwin,
annaleeblysse, Kanchi Nanjo, Benjamin Monod-Broca, Mali’o Kodis,
photograph by P. Funch and R.M. Kristensen, Y. de Hoev. (vectorized by
T. Michael Keesey), Lisa M. “Pixxl” (photo), John E. McCormack, Michael
G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn,
Robb T. Brumfield & T. Michael Keesey, Tony Ayling (vectorized by T.
Michael Keesey), Emma Hughes, Joanna Wolfe, Qiang Ou, Terpsichores, DW
Bapst (Modified from photograph taken by Charles Mitchell), Yusan Yang,
Mette Aumala, Chuanixn Yu, Ghedoghedo (vectorized by T. Michael Keesey),
Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael
Keesey., Melissa Broussard, Farelli (photo), John E. McCormack, Michael
G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn,
Robb T. Brumfield & T. Michael Keesey, Joseph Smit (modified by T.
Michael Keesey), Darren Naish (vectorized by T. Michael Keesey), Mareike
C. Janiak, Alexis Simon, Maha Ghazal, MPF (vectorized by T. Michael
Keesey), Almandine (vectorized by T. Michael Keesey), Andrew A. Farke,
Sean McCann, M Kolmann, Mali’o Kodis, photograph by Cordell Expeditions
at Cal Academy, Archaeodontosaurus (vectorized by T. Michael Keesey),
Robbie Cada (vectorized by T. Michael Keesey), Robert Gay, Esme
Ashe-Jepson, Stacy Spensley (Modified), Douglas Brown (modified by T.
Michael Keesey), Jimmy Bernot, James I. Kirkland, Luis Alcalá, Mark A.
Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized
by T. Michael Keesey), Zachary Quigley, Tommaso Cancellario,
Jean-Raphaël Guillaumin (photography) and T. Michael Keesey
(vectorization), Metalhead64 (vectorized by T. Michael Keesey), Matt
Dempsey, Xavier Giroux-Bougard, Skye M

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    554.525151 |    452.258608 | Ferran Sayol                                                                                                                                                          |
|   2 |    374.821386 |    516.383925 | Markus A. Grohme                                                                                                                                                      |
|   3 |    232.700999 |     74.154596 | Matthew E. Clapham                                                                                                                                                    |
|   4 |    536.905988 |    114.147973 | Tracy A. Heath                                                                                                                                                        |
|   5 |    895.814927 |    113.478237 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|   6 |    304.473339 |    436.434649 | Dean Schnabel                                                                                                                                                         |
|   7 |    456.474094 |     86.643945 | Martin R. Smith                                                                                                                                                       |
|   8 |    601.768478 |    214.094547 | Margot Michaud                                                                                                                                                        |
|   9 |    966.208085 |    588.590817 | Yan Wong                                                                                                                                                              |
|  10 |    910.273595 |     44.712907 | Markus A. Grohme                                                                                                                                                      |
|  11 |    164.604950 |    690.980032 | Tracy A. Heath                                                                                                                                                        |
|  12 |    477.175540 |    222.501742 | NA                                                                                                                                                                    |
|  13 |    778.270795 |    396.717051 | Christoph Schomburg                                                                                                                                                   |
|  14 |    935.305660 |    279.592860 | Matthew E. Clapham                                                                                                                                                    |
|  15 |     79.519156 |    617.550134 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  16 |    705.718947 |    717.091943 | Matt Crook                                                                                                                                                            |
|  17 |    660.017483 |    656.800755 | Noah Schlottman                                                                                                                                                       |
|  18 |    862.922521 |    733.548740 | Ingo Braasch                                                                                                                                                          |
|  19 |    941.440127 |    471.176752 | Richard Parker (vectorized by T. Michael Keesey)                                                                                                                      |
|  20 |    847.088035 |    611.781084 | Andy Wilson                                                                                                                                                           |
|  21 |    435.028792 |    655.699068 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  22 |    275.878350 |    277.295175 | Agnello Picorelli                                                                                                                                                     |
|  23 |    147.898848 |    486.735334 | Margot Michaud                                                                                                                                                        |
|  24 |    135.153685 |    411.075941 | Abraão Leite                                                                                                                                                          |
|  25 |    666.975523 |    336.112564 | Sharon Wegner-Larsen                                                                                                                                                  |
|  26 |    687.988617 |    602.678058 | T. Michael Keesey                                                                                                                                                     |
|  27 |     67.750967 |    146.546454 | NA                                                                                                                                                                    |
|  28 |    400.479477 |    758.864604 | Mykle Hoban                                                                                                                                                           |
|  29 |    217.046459 |    164.828305 | Beth Reinke                                                                                                                                                           |
|  30 |    160.446424 |    283.906531 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  31 |    775.592094 |    146.220234 | NA                                                                                                                                                                    |
|  32 |    300.142531 |    593.522503 | Gareth Monger                                                                                                                                                         |
|  33 |    179.806503 |    578.287491 | Zimices                                                                                                                                                               |
|  34 |    492.701299 |    365.796749 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  35 |    551.213756 |    526.357605 | Erika Schumacher                                                                                                                                                      |
|  36 |    497.082420 |    431.069173 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
|  37 |    628.933205 |     69.290331 | FunkMonk                                                                                                                                                              |
|  38 |    565.774432 |    669.035462 | NA                                                                                                                                                                    |
|  39 |    707.697673 |    272.356162 | Tasman Dixon                                                                                                                                                          |
|  40 |    969.711817 |    130.731799 | Kamil S. Jaron                                                                                                                                                        |
|  41 |    846.707590 |    190.996973 | Steven Traver                                                                                                                                                         |
|  42 |    358.532306 |    125.633341 | Scott Hartman                                                                                                                                                         |
|  43 |     95.891838 |    556.339499 | Yan Wong                                                                                                                                                              |
|  44 |    357.598148 |    229.244356 | Steven Traver                                                                                                                                                         |
|  45 |     66.024365 |    327.297437 | Andy Wilson                                                                                                                                                           |
|  46 |    826.665043 |    674.584007 | Markus A. Grohme                                                                                                                                                      |
|  47 |    650.599735 |    480.039339 | Jon Hill (Photo by DickDaniels: <http://en.wikipedia.org/wiki/File:Green_Woodhoopoe_RWD7.jpg>)                                                                        |
|  48 |     74.122247 |    732.414252 | Jagged Fang Designs                                                                                                                                                   |
|  49 |     73.297394 |     54.681892 | FunkMonk \[Michael B.H.\] (modified by T. Michael Keesey)                                                                                                             |
|  50 |    709.743532 |    532.932395 | Ingo Braasch                                                                                                                                                          |
|  51 |    387.238537 |    564.138224 | Iain Reid                                                                                                                                                             |
|  52 |    479.188065 |    568.480479 | Chris huh                                                                                                                                                             |
|  53 |     67.020923 |    647.263546 | Gareth Monger                                                                                                                                                         |
|  54 |    659.443659 |    137.592873 | Eric Moody                                                                                                                                                            |
|  55 |    257.100003 |    652.517989 | Felix Vaux                                                                                                                                                            |
|  56 |    912.594482 |    396.330571 | Markus A. Grohme                                                                                                                                                      |
|  57 |     70.398633 |    405.058771 | Matt Crook                                                                                                                                                            |
|  58 |    769.535417 |    241.519521 | Zimices                                                                                                                                                               |
|  59 |    179.703782 |    196.359797 | Skye McDavid                                                                                                                                                          |
|  60 |    915.170362 |    667.308753 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  61 |    364.215792 |    362.302915 | Meyers Konversations-Lexikon 1897 (vectorized: Yan Wong)                                                                                                              |
|  62 |    527.346553 |    600.029123 | Markus A. Grohme                                                                                                                                                      |
|  63 |    839.527866 |    511.891953 | Yan Wong from drawing in The Century Dictionary (1911)                                                                                                                |
|  64 |    127.598307 |    781.005840 | Jagged Fang Designs                                                                                                                                                   |
|  65 |    229.344032 |    231.621606 | Smokeybjb                                                                                                                                                             |
|  66 |    212.446396 |    429.533163 | T. Michael Keesey                                                                                                                                                     |
|  67 |    563.110244 |    740.975819 | Tasman Dixon                                                                                                                                                          |
|  68 |    326.241779 |     45.174797 | Dantheman9758 (vectorized by T. Michael Keesey)                                                                                                                       |
|  69 |    748.922761 |    765.970149 | nicubunu                                                                                                                                                              |
|  70 |    301.302630 |    340.911957 | Matt Crook                                                                                                                                                            |
|  71 |    772.018143 |     62.415577 | Margot Michaud                                                                                                                                                        |
|  72 |     73.350593 |     18.686979 | Jagged Fang Designs                                                                                                                                                   |
|  73 |    672.936311 |    380.121345 | Andy Wilson                                                                                                                                                           |
|  74 |    547.679382 |    291.275179 | Gareth Monger                                                                                                                                                         |
|  75 |    897.355009 |    354.537297 | Alexander Schmidt-Lebuhn                                                                                                                                              |
|  76 |     85.629902 |    220.309322 | Markus A. Grohme                                                                                                                                                      |
|  77 |    412.193650 |    291.756488 | Jagged Fang Designs                                                                                                                                                   |
|  78 |    872.927561 |     21.227091 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  79 |    560.017248 |     23.621849 | Markus A. Grohme                                                                                                                                                      |
|  80 |    198.370140 |    745.070355 | Margot Michaud                                                                                                                                                        |
|  81 |    986.971022 |    524.111386 | Zimices                                                                                                                                                               |
|  82 |     17.943000 |    429.602862 | Gareth Monger                                                                                                                                                         |
|  83 |     33.446552 |    108.647100 | Zimices                                                                                                                                                               |
|  84 |    426.406633 |    596.768533 | Lindberg (vectorized by T. Michael Keesey)                                                                                                                            |
|  85 |     24.100801 |    239.085410 | Margot Michaud                                                                                                                                                        |
|  86 |    735.086554 |    629.028578 | David Tana                                                                                                                                                            |
|  87 |    175.963078 |    150.393719 | Chris huh                                                                                                                                                             |
|  88 |    500.114809 |    705.600835 | Renata F. Martins                                                                                                                                                     |
|  89 |    338.720447 |    615.528099 | Matt Crook                                                                                                                                                            |
|  90 |    366.873925 |    172.809621 | NA                                                                                                                                                                    |
|  91 |    645.985614 |     19.452553 | Margot Michaud                                                                                                                                                        |
|  92 |    623.416666 |    501.262279 | NA                                                                                                                                                                    |
|  93 |    366.002478 |    599.598804 | Yan Wong                                                                                                                                                              |
|  94 |    461.845648 |    514.449466 | Matt Crook                                                                                                                                                            |
|  95 |    404.296271 |    131.410539 | Mike Hanson                                                                                                                                                           |
|  96 |    960.424062 |    735.319667 | FunkMonk                                                                                                                                                              |
|  97 |    650.038353 |     39.097262 | Frederick William Frohawk (vectorized by T. Michael Keesey)                                                                                                           |
|  98 |    897.740002 |    780.454017 | Scott Hartman                                                                                                                                                         |
|  99 |    445.888996 |    404.847137 | Mathew Callaghan                                                                                                                                                      |
| 100 |    775.868544 |    641.133342 | Margot Michaud                                                                                                                                                        |
| 101 |    593.389631 |    448.769357 | NA                                                                                                                                                                    |
| 102 |    671.089647 |    223.431037 | Gareth Monger                                                                                                                                                         |
| 103 |    169.985367 |    460.775054 | T. Michael Keesey                                                                                                                                                     |
| 104 |    515.254129 |    782.674008 | FunkMonk                                                                                                                                                              |
| 105 |    655.848655 |    561.568680 | Bruno C. Vellutini                                                                                                                                                    |
| 106 |    317.231502 |    146.902219 | Steven Traver                                                                                                                                                         |
| 107 |    485.733367 |    421.101586 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 108 |    259.635999 |    132.157782 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 109 |     44.235311 |    549.137340 | Chris huh                                                                                                                                                             |
| 110 |    433.651980 |    140.348302 | NASA                                                                                                                                                                  |
| 111 |    491.051231 |    305.326562 | Maija Karala                                                                                                                                                          |
| 112 |    171.595525 |    378.035418 | Margot Michaud                                                                                                                                                        |
| 113 |    111.599443 |    697.887980 | Jessica Anne Miller                                                                                                                                                   |
| 114 |    315.486839 |    718.713754 | L. Shyamal                                                                                                                                                            |
| 115 |    858.799186 |    257.540751 | FunkMonk                                                                                                                                                              |
| 116 |    974.549305 |    717.971778 | Jagged Fang Designs                                                                                                                                                   |
| 117 |    259.300958 |    363.653882 | Lafage                                                                                                                                                                |
| 118 |    243.631980 |    604.673345 | Nobu Tamura                                                                                                                                                           |
| 119 |    707.305472 |     67.255755 | NA                                                                                                                                                                    |
| 120 |    600.378189 |    504.590533 | Jagged Fang Designs                                                                                                                                                   |
| 121 |    544.595437 |    315.608290 | Cesar Julian                                                                                                                                                          |
| 122 |    996.087691 |    164.571538 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 123 |    230.996072 |    347.201428 | T. Michael Keesey                                                                                                                                                     |
| 124 |    269.435494 |    211.449104 | Raven Amos                                                                                                                                                            |
| 125 |    643.822105 |    783.388308 | Hans Hillewaert                                                                                                                                                       |
| 126 |    971.854307 |    213.857659 | NA                                                                                                                                                                    |
| 127 |    990.288279 |     77.901609 | Dann Pigdon                                                                                                                                                           |
| 128 |    901.544432 |    223.179474 | Matt Crook                                                                                                                                                            |
| 129 |    836.680176 |    156.850657 | FJDegrange                                                                                                                                                            |
| 130 |   1015.560385 |    440.253688 | Andy Wilson                                                                                                                                                           |
| 131 |    598.461274 |    494.230457 | L. Shyamal                                                                                                                                                            |
| 132 |    151.778771 |    575.852306 | Yan Wong                                                                                                                                                              |
| 133 |    491.252526 |     33.565815 | Steven Traver                                                                                                                                                         |
| 134 |    421.608111 |    477.078830 | Kamil S. Jaron                                                                                                                                                        |
| 135 |    638.308715 |    551.762169 | Lafage                                                                                                                                                                |
| 136 |    561.862305 |    466.693312 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 137 |   1000.260689 |    353.736438 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 138 |     48.404351 |    407.216983 | Gareth Monger                                                                                                                                                         |
| 139 |    255.624628 |    459.744946 | Zimices                                                                                                                                                               |
| 140 |    991.001693 |     84.546015 | Arthur S. Brum                                                                                                                                                        |
| 141 |    673.615352 |    683.295124 | Anthony Caravaggi                                                                                                                                                     |
| 142 |    279.243805 |    504.660436 | Margot Michaud                                                                                                                                                        |
| 143 |    339.465922 |    250.148380 | Matt Crook                                                                                                                                                            |
| 144 |    819.232886 |    759.766261 | T. Michael Keesey                                                                                                                                                     |
| 145 |    437.382908 |    277.561048 | Matt Crook                                                                                                                                                            |
| 146 |    135.579105 |     70.070581 | Gareth Monger                                                                                                                                                         |
| 147 |    398.010753 |    326.970964 | Matt Crook                                                                                                                                                            |
| 148 |    951.688503 |    137.959219 | Stemonitis (photography) and T. Michael Keesey (vectorization)                                                                                                        |
| 149 |    562.122373 |    207.547239 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 150 |   1001.079019 |    183.569103 | Mason McNair                                                                                                                                                          |
| 151 |    967.512599 |    431.739214 | NA                                                                                                                                                                    |
| 152 |    128.697556 |    599.325938 | Matt Crook                                                                                                                                                            |
| 153 |    535.581022 |    306.085991 | Steven Coombs (vectorized by T. Michael Keesey)                                                                                                                       |
| 154 |     58.769975 |    688.280824 | Alexandre Vong                                                                                                                                                        |
| 155 |     38.233023 |    334.653715 | NA                                                                                                                                                                    |
| 156 |    213.607868 |    134.988393 | New York Zoological Society                                                                                                                                           |
| 157 |    984.906624 |    437.482805 | Steven Traver                                                                                                                                                         |
| 158 |    868.676324 |    354.261489 | Gareth Monger                                                                                                                                                         |
| 159 |    539.181602 |    243.983007 | Matt Crook                                                                                                                                                            |
| 160 |    387.690733 |     32.968302 | Beth Reinke                                                                                                                                                           |
| 161 |     13.858452 |    766.402750 | L. Shyamal                                                                                                                                                            |
| 162 |     11.567971 |    703.575461 | Verdilak                                                                                                                                                              |
| 163 |    680.332102 |     96.976466 | Ferran Sayol                                                                                                                                                          |
| 164 |    577.827544 |    572.821946 | Birgit Lang                                                                                                                                                           |
| 165 |    536.425744 |    734.073609 | Kamil S. Jaron                                                                                                                                                        |
| 166 |    652.740812 |    625.233782 | Siobhon Egan                                                                                                                                                          |
| 167 |   1008.018819 |    541.466827 | Steven Traver                                                                                                                                                         |
| 168 |    495.219126 |    626.974985 | FunkMonk                                                                                                                                                              |
| 169 |    499.685616 |     52.669867 | xgirouxb                                                                                                                                                              |
| 170 |    446.937604 |    495.375015 | Jagged Fang Designs                                                                                                                                                   |
| 171 |    922.944771 |    776.321658 | Chris huh                                                                                                                                                             |
| 172 |    186.552922 |    331.606290 | NA                                                                                                                                                                    |
| 173 |    127.498285 |    200.533775 | Steven Traver                                                                                                                                                         |
| 174 |    867.921535 |    225.572943 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                      |
| 175 |     28.877944 |    794.428627 | Tauana J. Cunha                                                                                                                                                       |
| 176 |    301.942024 |    150.025762 | Steven Haddock • Jellywatch.org                                                                                                                                       |
| 177 |    976.413364 |    690.479017 | Markus A. Grohme                                                                                                                                                      |
| 178 |     30.967056 |    690.401810 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 179 |    416.949870 |     94.783528 | Andy Wilson                                                                                                                                                           |
| 180 |   1006.769280 |    612.306732 | Matt Crook                                                                                                                                                            |
| 181 |    191.946265 |    123.749151 | Kamil S. Jaron                                                                                                                                                        |
| 182 |    154.564270 |    107.086599 | Markus A. Grohme                                                                                                                                                      |
| 183 |    935.133242 |    541.742805 | Sarah Werning                                                                                                                                                         |
| 184 |    336.446217 |    334.128242 | Matt Crook                                                                                                                                                            |
| 185 |    241.504292 |    499.072480 | Sarah Werning                                                                                                                                                         |
| 186 |    719.749639 |    423.441350 | Kamil S. Jaron                                                                                                                                                        |
| 187 |    489.282670 |     88.326200 | Matt Crook                                                                                                                                                            |
| 188 |    303.544269 |    701.111721 | T. Michael Keesey                                                                                                                                                     |
| 189 |    809.939205 |    117.418182 | Michele M Tobias from an image By Dcrjsr - Own work, CC BY 3.0, <https://commons.wikimedia.org/w/index.php?curid=18059686>                                            |
| 190 |    673.837260 |    202.406134 | Andy Wilson                                                                                                                                                           |
| 191 |   1010.952179 |    291.103982 | nicubunu                                                                                                                                                              |
| 192 |    665.021559 |    489.859599 | Markus A. Grohme                                                                                                                                                      |
| 193 |    464.917550 |     20.070808 | Matt Crook                                                                                                                                                            |
| 194 |    324.739491 |    374.088545 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 195 |     14.176492 |    148.087442 | Ferran Sayol                                                                                                                                                          |
| 196 |    568.413076 |    488.839428 | Kimberly Haddrell                                                                                                                                                     |
| 197 |    995.626490 |    688.772582 | Erika Schumacher                                                                                                                                                      |
| 198 |    178.958563 |    624.818270 | Gareth Monger                                                                                                                                                         |
| 199 |    893.741769 |    678.910791 | Ferran Sayol                                                                                                                                                          |
| 200 |    853.163570 |    777.024059 | Yan Wong                                                                                                                                                              |
| 201 |    561.165604 |    160.946680 | Tracy A. Heath                                                                                                                                                        |
| 202 |    845.166167 |    290.536079 | Oscar Sanisidro                                                                                                                                                       |
| 203 |    909.149914 |    202.546622 | L. Shyamal                                                                                                                                                            |
| 204 |    811.192560 |    570.022645 | Kamil S. Jaron                                                                                                                                                        |
| 205 |    336.087349 |    726.325160 | Anthony Caravaggi                                                                                                                                                     |
| 206 |    596.017920 |    776.845661 | Matt Crook                                                                                                                                                            |
| 207 |    321.115033 |    187.439951 | Noah Schlottman                                                                                                                                                       |
| 208 |    312.796978 |    653.500235 | Meliponicultor Itaymbere                                                                                                                                              |
| 209 |   1003.023889 |    378.066839 | Lukasiniho                                                                                                                                                            |
| 210 |    366.235773 |    681.445249 | Matt Crook                                                                                                                                                            |
| 211 |    718.621799 |    196.607495 | Roule Jammes (vectorized by T. Michael Keesey)                                                                                                                        |
| 212 |    596.851169 |    411.514878 | Ferran Sayol                                                                                                                                                          |
| 213 |    102.268671 |    262.575481 | Scott Reid                                                                                                                                                            |
| 214 |     46.378280 |     81.034923 | Joshua Fowler                                                                                                                                                         |
| 215 |    855.369748 |    578.478912 | Ignacio Contreras                                                                                                                                                     |
| 216 |    819.791683 |    771.283637 | Matt Crook                                                                                                                                                            |
| 217 |    289.838248 |    331.567558 | James R. Spotila and Ray Chatterji                                                                                                                                    |
| 218 |    663.377876 |     99.184337 | Emily Willoughby                                                                                                                                                      |
| 219 |    356.052926 |    613.815404 | Yan Wong                                                                                                                                                              |
| 220 |    606.360871 |    420.479682 | Birgit Lang                                                                                                                                                           |
| 221 |    791.599693 |    785.727244 | Iain Reid                                                                                                                                                             |
| 222 |     61.118429 |    595.621020 | NA                                                                                                                                                                    |
| 223 |    283.536268 |    773.397135 | Gareth Monger                                                                                                                                                         |
| 224 |    404.774098 |     16.395824 | NA                                                                                                                                                                    |
| 225 |    994.681886 |    218.330049 | Ferran Sayol                                                                                                                                                          |
| 226 |    349.483807 |    700.903898 | FunkMonk (Michael B.H.; vectorized by T. Michael Keesey)                                                                                                              |
| 227 |    638.372467 |    229.667240 | Matt Crook                                                                                                                                                            |
| 228 |    561.979323 |    154.394036 | T. Tischler                                                                                                                                                           |
| 229 |    574.955716 |    368.939449 | Tyler Greenfield and Dean Schnabel                                                                                                                                    |
| 230 |     16.675348 |    527.062881 | Michael Scroggie                                                                                                                                                      |
| 231 |     70.699450 |     72.519661 | Jagged Fang Designs                                                                                                                                                   |
| 232 |    704.572695 |    461.365943 | Markus A. Grohme                                                                                                                                                      |
| 233 |    543.106651 |    257.911478 | Pedro de Siracusa                                                                                                                                                     |
| 234 |    924.309276 |      7.822490 | Collin Gross                                                                                                                                                          |
| 235 |    721.409006 |    663.613960 | Steven Traver                                                                                                                                                         |
| 236 |    518.853939 |    618.883952 | Katie S. Collins                                                                                                                                                      |
| 237 |    273.061171 |    121.444730 | Zimices                                                                                                                                                               |
| 238 |    984.346494 |    410.093245 | xgirouxb                                                                                                                                                              |
| 239 |    576.694309 |    279.959606 | U.S. National Park Service (vectorized by William Gearty)                                                                                                             |
| 240 |    144.119263 |    351.623099 | Margot Michaud                                                                                                                                                        |
| 241 |    649.262733 |    215.857761 | FunkMonk                                                                                                                                                              |
| 242 |    177.195535 |    299.052039 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 243 |    403.066078 |     36.383847 | FunkMonk                                                                                                                                                              |
| 244 |     38.881542 |    674.706476 | FunkMonk                                                                                                                                                              |
| 245 |    635.714819 |    769.150309 | Caleb M. Brown                                                                                                                                                        |
| 246 |      9.434851 |    255.220388 | Margot Michaud                                                                                                                                                        |
| 247 |    623.621382 |    180.368975 | New York Zoological Society                                                                                                                                           |
| 248 |    594.044107 |    558.366416 | Scott Hartman                                                                                                                                                         |
| 249 |    906.502824 |    186.855337 | Scott Hartman                                                                                                                                                         |
| 250 |    991.016633 |    676.467719 | Steven Traver                                                                                                                                                         |
| 251 |    389.134562 |    340.781276 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 252 |    109.110493 |    679.484090 | C. Camilo Julián-Caballero                                                                                                                                            |
| 253 |    997.226889 |    626.131683 | Matt Crook                                                                                                                                                            |
| 254 |    998.675924 |    579.164977 | Matt Crook                                                                                                                                                            |
| 255 |    281.489231 |    179.990117 | Zimices                                                                                                                                                               |
| 256 |    421.543024 |    168.519939 | Mathilde Cordellier                                                                                                                                                   |
| 257 |     36.495477 |    760.169169 | Hugo Gruson                                                                                                                                                           |
| 258 |    381.619083 |    172.818808 | T. Michael Keesey                                                                                                                                                     |
| 259 |    939.676180 |    757.070312 | Mathilde Cordellier                                                                                                                                                   |
| 260 |    616.064365 |    397.014919 | Gareth Monger                                                                                                                                                         |
| 261 |    345.127476 |    175.609068 | Caroline Harding, MAF (vectorized by T. Michael Keesey)                                                                                                               |
| 262 |     17.449005 |    110.162929 | Michelle Site                                                                                                                                                         |
| 263 |    541.663894 |    748.443743 | Birgit Lang                                                                                                                                                           |
| 264 |    880.217140 |    536.008244 | 于川云                                                                                                                                                                   |
| 265 |    579.612193 |    102.168589 | Gareth Monger                                                                                                                                                         |
| 266 |    253.569739 |    202.541311 | Emily Willoughby                                                                                                                                                      |
| 267 |    639.567087 |    200.092820 | Erika Schumacher                                                                                                                                                      |
| 268 |    682.305892 |     38.635887 | Dean Schnabel                                                                                                                                                         |
| 269 |   1011.996594 |    764.453448 | nicubunu                                                                                                                                                              |
| 270 |    652.081754 |    521.391901 | Matt Crook                                                                                                                                                            |
| 271 |    293.513174 |    526.340018 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 272 |    842.002219 |    705.309510 | Rebecca Groom                                                                                                                                                         |
| 273 |    522.220049 |    374.554544 | Margot Michaud                                                                                                                                                        |
| 274 |    305.280560 |    194.388880 | M. A. Broussard                                                                                                                                                       |
| 275 |    177.676378 |    109.799545 | Matt Crook                                                                                                                                                            |
| 276 |    979.151860 |    748.116163 | Andy Wilson                                                                                                                                                           |
| 277 |    628.799343 |    698.990936 | Erika Schumacher                                                                                                                                                      |
| 278 |      8.796997 |    752.302274 | (after Spotila 2004)                                                                                                                                                  |
| 279 |    496.026191 |    728.689585 | Ignacio Contreras                                                                                                                                                     |
| 280 |    706.468057 |    637.163575 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 281 |    323.211793 |    686.422587 | Steven Blackwood                                                                                                                                                      |
| 282 |      9.879879 |    791.625166 | Mason McNair                                                                                                                                                          |
| 283 |    997.439983 |    731.094863 | Matt Crook                                                                                                                                                            |
| 284 |    792.005516 |    559.550126 | Griensteidl and T. Michael Keesey                                                                                                                                     |
| 285 |    861.741497 |    161.798871 | Matt Crook                                                                                                                                                            |
| 286 |    383.252123 |    364.389031 | Felix Vaux                                                                                                                                                            |
| 287 |    404.794229 |    123.373206 | Steven Traver                                                                                                                                                         |
| 288 |    467.522430 |    731.807665 | Rebecca Groom                                                                                                                                                         |
| 289 |    199.685019 |    603.115052 | Chris huh                                                                                                                                                             |
| 290 |    340.526213 |     85.118059 | Margot Michaud                                                                                                                                                        |
| 291 |    994.723969 |    151.656001 | T. Tischler                                                                                                                                                           |
| 292 |      9.896765 |    738.248008 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 293 |     65.315406 |    388.284781 | Andy Wilson                                                                                                                                                           |
| 294 |    173.024726 |    350.275939 | Lily Hughes                                                                                                                                                           |
| 295 |    250.649264 |     22.228503 | Gareth Monger                                                                                                                                                         |
| 296 |    545.277571 |    283.844565 | Mo Hassan                                                                                                                                                             |
| 297 |    180.239513 |    717.508498 | Ignacio Contreras                                                                                                                                                     |
| 298 |    143.353934 |    723.954662 | Sarah Werning                                                                                                                                                         |
| 299 |    810.961033 |    390.715519 | Birgit Lang                                                                                                                                                           |
| 300 |    151.923728 |    643.932428 | Markus A. Grohme                                                                                                                                                      |
| 301 |    613.000293 |    578.343799 | Christoph Schomburg                                                                                                                                                   |
| 302 |    481.859788 |    484.203720 | Tasman Dixon                                                                                                                                                          |
| 303 |    697.748325 |    200.156548 | Jagged Fang Designs                                                                                                                                                   |
| 304 |    249.941446 |    513.738709 | Jagged Fang Designs                                                                                                                                                   |
| 305 |    767.169244 |    118.623032 | Matt Crook                                                                                                                                                            |
| 306 |    152.757524 |    608.078119 | Mark Hofstetter (vectorized by T. Michael Keesey)                                                                                                                     |
| 307 |    926.167134 |    699.988239 | Abraão Leite                                                                                                                                                          |
| 308 |    388.526804 |    438.747856 | Peileppe                                                                                                                                                              |
| 309 |    968.412906 |     65.894796 | Steven Coombs                                                                                                                                                         |
| 310 |    505.348461 |     66.929701 | Yan Wong from illustration by Charles Orbigny                                                                                                                         |
| 311 |    560.583930 |    384.463012 | T. Michael Keesey                                                                                                                                                     |
| 312 |    268.849797 |    771.234832 | T. Michael Keesey                                                                                                                                                     |
| 313 |    987.177030 |    329.598684 | Amanda Katzer                                                                                                                                                         |
| 314 |    250.060736 |    689.523231 | Beth Reinke                                                                                                                                                           |
| 315 |    825.780134 |    418.999122 | Matt Martyniuk (modified by T. Michael Keesey)                                                                                                                        |
| 316 |    635.831716 |    182.448922 | Mathew Wedel                                                                                                                                                          |
| 317 |    697.821379 |    236.516109 | Margot Michaud                                                                                                                                                        |
| 318 |    637.140695 |    358.174501 | Gareth Monger                                                                                                                                                         |
| 319 |    132.358708 |    374.716195 | Gareth Monger                                                                                                                                                         |
| 320 |     20.196737 |    265.633175 | Andy Wilson                                                                                                                                                           |
| 321 |     62.941680 |    278.709119 | Tasman Dixon                                                                                                                                                          |
| 322 |    537.840381 |    196.356524 | Rebecca Groom                                                                                                                                                         |
| 323 |    462.675010 |    677.526888 | Matt Crook                                                                                                                                                            |
| 324 |    339.078246 |    580.213935 | Katie S. Collins                                                                                                                                                      |
| 325 |    470.538329 |    405.581388 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                        |
| 326 |    426.619979 |    611.316506 | Ignacio Contreras                                                                                                                                                     |
| 327 |    811.749368 |    315.197602 | T. Michael Keesey                                                                                                                                                     |
| 328 |    151.346347 |    472.128632 | Air Kebir NRG                                                                                                                                                         |
| 329 |    677.972822 |    232.947404 | Matt Crook                                                                                                                                                            |
| 330 |    664.676256 |    296.226043 | Markus A. Grohme                                                                                                                                                      |
| 331 |    778.739138 |    720.185741 | Scott Hartman                                                                                                                                                         |
| 332 |    906.150552 |    651.714557 | Tyler Greenfield                                                                                                                                                      |
| 333 |   1000.036818 |    755.900816 | Zimices                                                                                                                                                               |
| 334 |    548.824292 |    623.100352 | Michael Scroggie                                                                                                                                                      |
| 335 |    245.235642 |    540.130742 | James R. Spotila and Ray Chatterji                                                                                                                                    |
| 336 |     84.833514 |    699.122696 | FJDegrange                                                                                                                                                            |
| 337 |    936.023301 |    601.930999 | NA                                                                                                                                                                    |
| 338 |    701.409618 |     45.923343 | Matt Crook                                                                                                                                                            |
| 339 |     30.927313 |    139.917668 | Steven Traver                                                                                                                                                         |
| 340 |    749.012690 |    520.900470 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 341 |    936.928930 |    125.582408 | Jaime Headden                                                                                                                                                         |
| 342 |     56.716077 |    257.938284 | Mathieu Basille                                                                                                                                                       |
| 343 |    347.838902 |      2.153230 | Armin Reindl                                                                                                                                                          |
| 344 |    296.582198 |    208.900154 | Sarah Werning                                                                                                                                                         |
| 345 |    841.205468 |    397.515170 | Ferran Sayol                                                                                                                                                          |
| 346 |    155.137500 |      5.471702 | NA                                                                                                                                                                    |
| 347 |    137.394079 |    746.147020 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 348 |    247.100984 |    561.304028 | Gareth Monger                                                                                                                                                         |
| 349 |    238.306545 |    326.086026 | C. Camilo Julián-Caballero                                                                                                                                            |
| 350 |    901.848824 |    591.186696 | Chase Brownstein                                                                                                                                                      |
| 351 |    923.583288 |    638.182382 | Gareth Monger                                                                                                                                                         |
| 352 |     24.045382 |    610.387688 | T. Michael Keesey                                                                                                                                                     |
| 353 |    787.329907 |     12.470331 | Birgit Lang                                                                                                                                                           |
| 354 |    479.769515 |    779.346148 | Dmitry Bogdanov                                                                                                                                                       |
| 355 |    519.554851 |    633.716477 | Diana Pomeroy                                                                                                                                                         |
| 356 |    279.327935 |    729.150305 | Sam Droege (photography) and T. Michael Keesey (vectorization)                                                                                                        |
| 357 |    288.731888 |    762.133747 | Armin Reindl                                                                                                                                                          |
| 358 |    181.605195 |     25.516710 | Margot Michaud                                                                                                                                                        |
| 359 |    661.240874 |    178.612773 | SauropodomorphMonarch                                                                                                                                                 |
| 360 |    921.730930 |    709.138058 | NA                                                                                                                                                                    |
| 361 |    314.980886 |    490.270311 | NA                                                                                                                                                                    |
| 362 |     22.932522 |    479.976781 | Dr. Thomas G. Barnes, USFWS                                                                                                                                           |
| 363 |    921.634754 |     69.249187 | Smokeybjb                                                                                                                                                             |
| 364 |    858.661212 |     98.595452 | Tasman Dixon                                                                                                                                                          |
| 365 |    528.967175 |    559.390815 | James Neenan                                                                                                                                                          |
| 366 |    490.916714 |     63.035397 | T. Michael Keesey                                                                                                                                                     |
| 367 |    782.049047 |    272.088242 | Zimices                                                                                                                                                               |
| 368 |    926.568185 |    221.814292 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 369 |    603.723506 |    407.293992 | Margot Michaud                                                                                                                                                        |
| 370 |     16.708782 |    666.635806 | Steven Traver                                                                                                                                                         |
| 371 |    868.584980 |    518.853026 | T. Michael Keesey                                                                                                                                                     |
| 372 |   1010.174583 |    708.416921 | Gareth Monger                                                                                                                                                         |
| 373 |    882.676290 |    770.117987 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                               |
| 374 |    586.698736 |    133.974455 | T. Michael Keesey                                                                                                                                                     |
| 375 |    212.357222 |    649.445037 | James R. Spotila and Ray Chatterji                                                                                                                                    |
| 376 |    675.087182 |    767.807467 | T. Michael Keesey (after Kukalová)                                                                                                                                    |
| 377 |    811.476497 |    136.691274 | Tyler McCraney                                                                                                                                                        |
| 378 |    873.465790 |    381.101962 | C. Camilo Julián-Caballero                                                                                                                                            |
| 379 |    776.633399 |    536.885096 | Kai R. Caspar                                                                                                                                                         |
| 380 |    551.730017 |    583.686891 | Duane Raver (vectorized by T. Michael Keesey)                                                                                                                         |
| 381 |   1013.639259 |    274.144820 | Steven Traver                                                                                                                                                         |
| 382 |    625.145585 |    103.703946 | NA                                                                                                                                                                    |
| 383 |    157.432571 |    122.822616 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 384 |    213.706764 |      4.825580 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                          |
| 385 |    925.633036 |    605.175264 | Scott Hartman                                                                                                                                                         |
| 386 |    475.091524 |    162.456673 | T. Michael Keesey                                                                                                                                                     |
| 387 |    833.620444 |    110.387254 | Margot Michaud                                                                                                                                                        |
| 388 |    923.156237 |    174.081212 | Andy Wilson                                                                                                                                                           |
| 389 |    754.458670 |    113.983348 | Zimices                                                                                                                                                               |
| 390 |    760.585479 |      7.567767 | Chris huh                                                                                                                                                             |
| 391 |    439.830182 |    203.453661 | Frank Förster (based on a picture by Jerry Kirkhart; modified by T. Michael Keesey)                                                                                   |
| 392 |     29.812908 |     36.443439 | Antonov (vectorized by T. Michael Keesey)                                                                                                                             |
| 393 |    608.208850 |    623.403836 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 394 |    549.596303 |    270.367620 | L.M. Davalos                                                                                                                                                          |
| 395 |      7.848476 |     46.411024 | Beth Reinke                                                                                                                                                           |
| 396 |    833.408664 |    715.053673 | NA                                                                                                                                                                    |
| 397 |    326.550283 |    598.525862 | Smokeybjb                                                                                                                                                             |
| 398 |    226.652167 |    678.134962 | Gareth Monger                                                                                                                                                         |
| 399 |    139.229690 |     46.992678 | Matt Crook                                                                                                                                                            |
| 400 |    644.648018 |    682.934402 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 401 |    948.042854 |    422.561304 | Mali’o Kodis, photograph by G. Giribet                                                                                                                                |
| 402 |    682.534344 |    576.127391 | T. Tischler                                                                                                                                                           |
| 403 |    709.225762 |    490.527216 | David Orr                                                                                                                                                             |
| 404 |    843.107747 |     81.063279 | Scott Hartman                                                                                                                                                         |
| 405 |    415.761198 |    317.872988 | Juan Carlos Jerí                                                                                                                                                      |
| 406 |     43.322547 |    363.516981 | Crystal Maier                                                                                                                                                         |
| 407 |    828.694912 |    310.287169 | Dmitry Bogdanov and FunkMonk (vectorized by T. Michael Keesey)                                                                                                        |
| 408 |     56.396077 |    705.334443 | Jennifer Trimble                                                                                                                                                      |
| 409 |    419.528898 |     39.065427 | Matt Crook                                                                                                                                                            |
| 410 |     14.219090 |    683.129109 | Margot Michaud                                                                                                                                                        |
| 411 |    508.853198 |    730.532890 | Chris huh                                                                                                                                                             |
| 412 |    880.569473 |    563.791771 | Lafage                                                                                                                                                                |
| 413 |    153.156742 |    369.377078 | Mali’o Kodis, photograph by “Wildcat Dunny” (<http://www.flickr.com/people/wildcat_dunny/>)                                                                           |
| 414 |    431.573720 |    448.844727 | NA                                                                                                                                                                    |
| 415 |    497.747500 |    497.056930 | Gareth Monger                                                                                                                                                         |
| 416 |    836.474185 |    574.593674 | Jagged Fang Designs                                                                                                                                                   |
| 417 |    233.323860 |    374.315588 | Katie S. Collins                                                                                                                                                      |
| 418 |    666.893829 |    793.585036 | Zimices                                                                                                                                                               |
| 419 |    841.513914 |    441.503240 | Thea Boodhoo (photograph) and T. Michael Keesey (vectorization)                                                                                                       |
| 420 |     93.995585 |    750.560294 | Dean Schnabel                                                                                                                                                         |
| 421 |   1004.393371 |    206.330376 | Theodore W. Pietsch (photography) and T. Michael Keesey (vectorization)                                                                                               |
| 422 |    985.056795 |    770.568299 | Jay Matternes (vectorized by T. Michael Keesey)                                                                                                                       |
| 423 |    244.657239 |    431.630929 | Maxime Dahirel                                                                                                                                                        |
| 424 |    125.272337 |    767.564917 | Anthony Caravaggi                                                                                                                                                     |
| 425 |    138.784312 |    754.439726 | Iain Reid                                                                                                                                                             |
| 426 |    806.733892 |    644.376183 | T. Michael Keesey                                                                                                                                                     |
| 427 |    588.373883 |     80.274656 | FunkMonk (Michael B. H.)                                                                                                                                              |
| 428 |    414.440348 |     70.347645 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 429 |    345.063691 |    493.753547 | Ferran Sayol                                                                                                                                                          |
| 430 |    354.948843 |    445.129854 | Matt Crook                                                                                                                                                            |
| 431 |     25.089641 |    335.108019 | Andy Wilson                                                                                                                                                           |
| 432 |    489.676587 |    473.507853 | Steven Traver                                                                                                                                                         |
| 433 |   1015.802241 |      7.937178 | Andy Wilson                                                                                                                                                           |
| 434 |    232.656444 |    240.639886 | Ignacio Contreras                                                                                                                                                     |
| 435 |    605.859403 |    667.314304 | Dave Angelini                                                                                                                                                         |
| 436 |    400.024658 |    164.770968 | L. Shyamal                                                                                                                                                            |
| 437 |    737.732275 |    556.264072 | Gareth Monger                                                                                                                                                         |
| 438 |    120.487532 |    338.853280 | Ignacio Contreras                                                                                                                                                     |
| 439 |    431.478849 |     30.777669 | Maija Karala                                                                                                                                                          |
| 440 |    312.570567 |    373.362966 | Yan Wong                                                                                                                                                              |
| 441 |    933.128365 |    736.653889 | Steven Haddock • Jellywatch.org                                                                                                                                       |
| 442 |     87.122112 |    687.748819 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 443 |    390.899863 |    477.676140 | Steven Traver                                                                                                                                                         |
| 444 |    475.972255 |    714.362940 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 445 |    982.455713 |    661.922123 | Zimices                                                                                                                                                               |
| 446 |    138.574693 |    797.507910 | Gareth Monger                                                                                                                                                         |
| 447 |     91.340491 |    662.677689 | Lukasiniho                                                                                                                                                            |
| 448 |    357.390496 |     13.827423 | NA                                                                                                                                                                    |
| 449 |    151.972074 |    140.597546 | Chris huh                                                                                                                                                             |
| 450 |    410.185620 |    547.202595 | Andy Wilson                                                                                                                                                           |
| 451 |     92.431959 |    279.949625 | Tracy A. Heath                                                                                                                                                        |
| 452 |    647.098142 |     75.479016 | Melissa Ingala                                                                                                                                                        |
| 453 |    288.765735 |    657.128152 | FunkMonk                                                                                                                                                              |
| 454 |    320.416409 |    168.691211 | Zimices                                                                                                                                                               |
| 455 |    793.372844 |    697.478841 | Ingo Braasch                                                                                                                                                          |
| 456 |    511.998480 |    227.976179 | Michelle Site                                                                                                                                                         |
| 457 |     78.470913 |    787.174536 | NA                                                                                                                                                                    |
| 458 |   1016.437266 |    393.500837 | Zimices                                                                                                                                                               |
| 459 |    583.445198 |    559.521362 | Armin Reindl                                                                                                                                                          |
| 460 |    566.095209 |    781.251704 | Gareth Monger                                                                                                                                                         |
| 461 |    223.923545 |     17.622803 | Matt Crook                                                                                                                                                            |
| 462 |    349.079389 |     66.921045 | Chris huh                                                                                                                                                             |
| 463 |    295.238541 |    783.498880 | NA                                                                                                                                                                    |
| 464 |    519.138334 |    263.007198 | Isaure Scavezzoni                                                                                                                                                     |
| 465 |    112.403374 |    237.116864 | Jagged Fang Designs                                                                                                                                                   |
| 466 |    728.453510 |    174.874910 | Zimices                                                                                                                                                               |
| 467 |    999.067223 |    237.364225 | Chris Jennings (Risiatto)                                                                                                                                             |
| 468 |    933.539978 |    526.192161 | Julio Garza                                                                                                                                                           |
| 469 |     23.811238 |    302.381826 | Jack Mayer Wood                                                                                                                                                       |
| 470 |     21.696943 |    714.285506 | Kent Elson Sorgon                                                                                                                                                     |
| 471 |    424.192633 |    118.977918 | Jagged Fang Designs                                                                                                                                                   |
| 472 |      9.096661 |    334.007843 | Scott Hartman                                                                                                                                                         |
| 473 |    328.134825 |    788.676465 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 474 |    529.704617 |     55.000456 | Markus A. Grohme                                                                                                                                                      |
| 475 |    354.585883 |    794.875241 | Michelle Site                                                                                                                                                         |
| 476 |    876.533058 |    791.526790 | L. Shyamal                                                                                                                                                            |
| 477 |    927.836763 |    717.082227 | Scott Hartman                                                                                                                                                         |
| 478 |    849.324382 |    424.446147 | Collin Gross                                                                                                                                                          |
| 479 |    769.788959 |    702.510148 | Manabu Sakamoto                                                                                                                                                       |
| 480 |     99.577649 |    598.590896 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 481 |    879.542080 |    151.075509 | Noah Schlottman, photo from Casey Dunn                                                                                                                                |
| 482 |    951.607034 |    201.211392 | Margot Michaud                                                                                                                                                        |
| 483 |    643.669446 |     86.229276 | Kamil S. Jaron                                                                                                                                                        |
| 484 |    479.096438 |    137.349349 | Gareth Monger                                                                                                                                                         |
| 485 |    347.056403 |     96.408627 | Matt Crook                                                                                                                                                            |
| 486 |     27.084639 |    502.825572 | T. Michael Keesey (vectorization) and Larry Loos (photography)                                                                                                        |
| 487 |   1005.672631 |    663.367112 | Steven Traver                                                                                                                                                         |
| 488 |     51.588166 |    415.943971 | Matt Crook                                                                                                                                                            |
| 489 |    929.525539 |    138.056789 | Dean Schnabel                                                                                                                                                         |
| 490 |    806.358772 |    296.110415 | Matt Crook                                                                                                                                                            |
| 491 |     35.179221 |    777.031644 | Gareth Monger                                                                                                                                                         |
| 492 |    600.537114 |    298.850306 | Tasman Dixon                                                                                                                                                          |
| 493 |     44.172348 |    392.476850 | Steven Traver                                                                                                                                                         |
| 494 |    703.707473 |    468.411452 | Lisa Byrne                                                                                                                                                            |
| 495 |    837.098853 |    651.588130 | Zimices                                                                                                                                                               |
| 496 |    417.351990 |    428.919923 | Renato Santos                                                                                                                                                         |
| 497 |    855.220647 |     73.304472 | Christoph Schomburg                                                                                                                                                   |
| 498 |    150.236296 |    237.516034 | Gareth Monger                                                                                                                                                         |
| 499 |    326.433069 |    653.459411 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 500 |   1005.558722 |    324.210239 | Margot Michaud                                                                                                                                                        |
| 501 |    985.454310 |     32.801411 | Markus A. Grohme                                                                                                                                                      |
| 502 |    277.795209 |    338.919868 | T. Michael Keesey                                                                                                                                                     |
| 503 |    241.345073 |    638.171099 | Ignacio Contreras                                                                                                                                                     |
| 504 |    680.369873 |    454.957212 | Caleb M. Gordon                                                                                                                                                       |
| 505 |    423.491105 |    713.228903 | Tracy A. Heath                                                                                                                                                        |
| 506 |    495.041646 |    512.596715 | Jon Hill (Photo by DickDaniels: <http://en.wikipedia.org/wiki/File:Green_Woodhoopoe_RWD7.jpg>)                                                                        |
| 507 |     86.040953 |     72.903723 | E. Lear, 1819 (vectorization by Yan Wong)                                                                                                                             |
| 508 |    122.175645 |     84.481911 | Dean Schnabel                                                                                                                                                         |
| 509 |    101.305147 |     47.122054 | Scott Hartman                                                                                                                                                         |
| 510 |    742.227478 |    703.537661 | Michelle Site                                                                                                                                                         |
| 511 |    514.296785 |    658.805155 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                                           |
| 512 |    586.548738 |    387.946338 | Elisabeth Östman                                                                                                                                                      |
| 513 |    185.926066 |    140.873617 | Ferran Sayol                                                                                                                                                          |
| 514 |    881.627190 |    217.737694 | Catherine Yasuda                                                                                                                                                      |
| 515 |    853.055548 |    123.949493 | Matt Crook                                                                                                                                                            |
| 516 |    758.000527 |    783.849129 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 517 |    949.944195 |    710.239450 | Griensteidl and T. Michael Keesey                                                                                                                                     |
| 518 |    648.787480 |    565.798608 | Gareth Monger                                                                                                                                                         |
| 519 |    924.397755 |    380.379357 | David Tana                                                                                                                                                            |
| 520 |    497.736781 |    157.072628 | Lily Hughes                                                                                                                                                           |
| 521 |    332.053004 |    353.044531 | Kai R. Caspar                                                                                                                                                         |
| 522 |    888.256959 |    370.318169 | Matt Martyniuk                                                                                                                                                        |
| 523 |    601.310076 |    481.961665 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 524 |    280.675559 |    743.516889 | Steven Traver                                                                                                                                                         |
| 525 |    443.984863 |    543.203932 | T. Michael Keesey (photo by Bc999 \[Black crow\])                                                                                                                     |
| 526 |    489.407157 |    386.872098 | Steven Traver                                                                                                                                                         |
| 527 |    170.569802 |    394.757239 | Christine Axon                                                                                                                                                        |
| 528 |     23.550679 |    378.686178 | Marmelad                                                                                                                                                              |
| 529 |    998.588570 |    484.302256 | NA                                                                                                                                                                    |
| 530 |   1011.448588 |    359.109721 | Matt Crook                                                                                                                                                            |
| 531 |    464.317905 |    588.967595 | Zimices                                                                                                                                                               |
| 532 |    891.156179 |    544.019215 | NA                                                                                                                                                                    |
| 533 |    610.038197 |    547.758384 | Steven Traver                                                                                                                                                         |
| 534 |    971.453802 |    379.456627 | Gareth Monger                                                                                                                                                         |
| 535 |    734.078083 |    663.039884 | Lily Hughes                                                                                                                                                           |
| 536 |    668.798529 |    748.393516 | Gareth Monger                                                                                                                                                         |
| 537 |    829.980814 |    326.588089 | Jagged Fang Designs                                                                                                                                                   |
| 538 |    128.978543 |     14.626478 | C. Camilo Julián-Caballero                                                                                                                                            |
| 539 |    145.063143 |    122.422380 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 540 |    596.310390 |    578.471502 | \[unknown\]                                                                                                                                                           |
| 541 |    827.238791 |    783.780648 | Matt Crook                                                                                                                                                            |
| 542 |    446.781982 |    506.203432 | T. Michael Keesey                                                                                                                                                     |
| 543 |    478.917223 |    399.426022 | Birgit Lang                                                                                                                                                           |
| 544 |    931.992883 |    782.539165 | Zimices                                                                                                                                                               |
| 545 |    353.145279 |    710.102428 | Ieuan Jones                                                                                                                                                           |
| 546 |    542.609318 |    230.104758 | Paul O. Lewis                                                                                                                                                         |
| 547 |    521.857321 |    694.311595 | Jagged Fang Designs                                                                                                                                                   |
| 548 |     99.133554 |    331.555785 | Margot Michaud                                                                                                                                                        |
| 549 |    422.121387 |    571.860122 | Steven Traver                                                                                                                                                         |
| 550 |    483.314054 |    655.097026 | Tasman Dixon                                                                                                                                                          |
| 551 |    409.789777 |    151.664742 | Margot Michaud                                                                                                                                                        |
| 552 |    350.588591 |    718.758823 | Roberto Díaz Sibaja                                                                                                                                                   |
| 553 |    645.478520 |    259.165787 | Timothy Knepp of the U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                |
| 554 |    475.246495 |    542.955604 | Margot Michaud                                                                                                                                                        |
| 555 |    402.550301 |    709.146677 | Jagged Fang Designs                                                                                                                                                   |
| 556 |    134.256843 |    167.854001 | Margot Michaud                                                                                                                                                        |
| 557 |    694.893476 |    168.154064 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                        |
| 558 |    167.145375 |    319.918041 | Meliponicultor Itaymbere                                                                                                                                              |
| 559 |    723.330373 |    313.321233 | terngirl                                                                                                                                                              |
| 560 |    426.500491 |     74.894001 | Zimices                                                                                                                                                               |
| 561 |    544.479217 |    778.875343 | Ignacio Contreras                                                                                                                                                     |
| 562 |    629.756720 |    683.633341 | T. Michael Keesey                                                                                                                                                     |
| 563 |    583.526489 |    541.880954 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 564 |    815.914671 |    692.608205 | Jiekun He                                                                                                                                                             |
| 565 |   1019.921729 |    637.848175 | Yan Wong (vectorization) from 1873 illustration                                                                                                                       |
| 566 |    811.535441 |    727.044896 | Zimices                                                                                                                                                               |
| 567 |    133.093258 |    735.561049 | Markus A. Grohme                                                                                                                                                      |
| 568 |     82.309691 |    421.735275 | Matt Crook                                                                                                                                                            |
| 569 |    342.953996 |    667.948200 | Gareth Monger                                                                                                                                                         |
| 570 |    318.770270 |      6.446713 | Beth Reinke                                                                                                                                                           |
| 571 |      9.342610 |    407.557354 | Margot Michaud                                                                                                                                                        |
| 572 |    557.068741 |    198.967888 | Chris huh                                                                                                                                                             |
| 573 |    370.484553 |    718.262341 | Matt Crook                                                                                                                                                            |
| 574 |     56.214656 |    763.215667 | Baheerathan Murugavel                                                                                                                                                 |
| 575 |    337.851991 |    293.790251 | T. Michael Keesey                                                                                                                                                     |
| 576 |    179.840458 |    644.237613 | Ville Koistinen and T. Michael Keesey                                                                                                                                 |
| 577 |    963.111742 |    787.801940 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 578 |    216.539321 |    214.091211 | Zimices                                                                                                                                                               |
| 579 |    907.884929 |    536.770189 | Matt Crook                                                                                                                                                            |
| 580 |    231.417995 |    545.697584 | Tracy A. Heath                                                                                                                                                        |
| 581 |    706.666895 |    173.193446 | Matt Crook                                                                                                                                                            |
| 582 |    367.728329 |    663.729155 | Derek Bakken (photograph) and T. Michael Keesey (vectorization)                                                                                                       |
| 583 |    197.793637 |     26.168514 | Jakovche                                                                                                                                                              |
| 584 |    632.698345 |    175.638042 | Martin R. Smith, from photo by Jürgen Schoner                                                                                                                         |
| 585 |     14.041134 |    559.263161 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 586 |     49.499198 |    125.098956 | Maxime Dahirel (digitisation), Kees van Achterberg et al (doi: 10.3897/BDJ.8.e49017)(original publication)                                                            |
| 587 |    539.999465 |    784.997176 | Scott Hartman                                                                                                                                                         |
| 588 |    825.274083 |    565.465772 | Jagged Fang Designs                                                                                                                                                   |
| 589 |    580.609675 |    185.781309 | Chloé Schmidt                                                                                                                                                         |
| 590 |    892.278035 |    793.327357 | Margot Michaud                                                                                                                                                        |
| 591 |    561.799942 |    244.428324 | Matt Crook                                                                                                                                                            |
| 592 |    134.737777 |    573.536146 | Ben Liebeskind                                                                                                                                                        |
| 593 |    496.376565 |    398.801800 | Margot Michaud                                                                                                                                                        |
| 594 |    258.168566 |    216.341952 | Kamil S. Jaron                                                                                                                                                        |
| 595 |    277.965120 |    668.655326 | Matt Crook                                                                                                                                                            |
| 596 |    724.567748 |    342.590940 | Ingo Braasch                                                                                                                                                          |
| 597 |    493.212615 |    139.567793 | Agnello Picorelli                                                                                                                                                     |
| 598 |     43.273836 |    203.436253 | Yan Wong                                                                                                                                                              |
| 599 |    920.371334 |    418.629714 | Dean Schnabel                                                                                                                                                         |
| 600 |    426.141894 |    246.653213 | NA                                                                                                                                                                    |
| 601 |    504.170104 |    280.100032 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 602 |    530.644751 |     42.671516 | NA                                                                                                                                                                    |
| 603 |    337.095041 |     72.654970 | C. Camilo Julián-Caballero                                                                                                                                            |
| 604 |    252.192650 |    781.550589 | Manabu Sakamoto                                                                                                                                                       |
| 605 |    706.356807 |      8.774695 | Ignacio Contreras                                                                                                                                                     |
| 606 |    796.927109 |    121.314979 | Scott Hartman                                                                                                                                                         |
| 607 |     24.800712 |    703.438563 | Martin Kevil                                                                                                                                                          |
| 608 |    755.086721 |    687.029102 | Collin Gross                                                                                                                                                          |
| 609 |    632.958125 |    289.952065 | xgirouxb                                                                                                                                                              |
| 610 |    501.468490 |    677.024970 | Birgit Lang                                                                                                                                                           |
| 611 |    364.625456 |    145.905910 | CNZdenek                                                                                                                                                              |
| 612 |    956.492003 |    772.047735 | Chris huh                                                                                                                                                             |
| 613 |    883.311048 |    207.092229 | Christoph Schomburg                                                                                                                                                   |
| 614 |    885.382422 |     74.562154 | Matt Crook                                                                                                                                                            |
| 615 |    486.479743 |    121.208888 | Chris huh                                                                                                                                                             |
| 616 |    190.918454 |    635.353030 | Amanda Katzer                                                                                                                                                         |
| 617 |   1007.625584 |    452.136653 | Smokeybjb, vectorized by Zimices                                                                                                                                      |
| 618 |    533.411950 |    717.801292 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 619 |    690.862898 |     96.810305 | Ferran Sayol                                                                                                                                                          |
| 620 |    158.152314 |    443.856513 | Margot Michaud                                                                                                                                                        |
| 621 |    985.800443 |     65.020213 | Margot Michaud                                                                                                                                                        |
| 622 |    455.793257 |    710.117791 | T. Michael Keesey                                                                                                                                                     |
| 623 |    641.339261 |      6.145669 | Margot Michaud                                                                                                                                                        |
| 624 |    672.796747 |    356.854331 | Steven Traver                                                                                                                                                         |
| 625 |    524.732453 |    176.886663 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 626 |     88.799838 |    675.222237 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
| 627 |     29.552178 |    542.182299 | Matt Crook                                                                                                                                                            |
| 628 |    979.666857 |    793.538486 | François Michonneau                                                                                                                                                   |
| 629 |    144.172020 |    452.996204 | Crystal Maier                                                                                                                                                         |
| 630 |    988.510997 |    612.027080 | Kamil S. Jaron                                                                                                                                                        |
| 631 |    627.293276 |    436.286674 | Thea Boodhoo (photograph) and T. Michael Keesey (vectorization)                                                                                                       |
| 632 |    582.554815 |    317.630946 | NA                                                                                                                                                                    |
| 633 |    607.093020 |    317.728539 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 634 |    574.237063 |    451.541137 | Alan Manson (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
| 635 |     28.610691 |    343.890929 | Jagged Fang Designs                                                                                                                                                   |
| 636 |   1014.456734 |    497.671130 | Andy Wilson                                                                                                                                                           |
| 637 |    197.743107 |    150.090836 | T. Michael Keesey                                                                                                                                                     |
| 638 |    258.510219 |    573.182929 | Andy Wilson                                                                                                                                                           |
| 639 |    697.925823 |     89.990683 | Scott Hartman                                                                                                                                                         |
| 640 |    998.436328 |    791.448956 | Beth Reinke                                                                                                                                                           |
| 641 |    410.169048 |    194.236821 | Matt Crook                                                                                                                                                            |
| 642 |    827.363279 |    376.766391 | Duane Raver/USFWS                                                                                                                                                     |
| 643 |    503.737011 |    229.738697 | Martin R. Smith, after Skovsted et al 2015                                                                                                                            |
| 644 |    187.378252 |    667.194902 | Emily Willoughby                                                                                                                                                      |
| 645 |     76.798078 |    756.594036 | Kai R. Caspar                                                                                                                                                         |
| 646 |    842.743119 |     58.874070 | NA                                                                                                                                                                    |
| 647 |   1005.143837 |     37.545874 | Zimices                                                                                                                                                               |
| 648 |    462.980498 |    792.559040 | Caio Bernardes, vectorized by Zimices                                                                                                                                 |
| 649 |    475.981243 |    686.641299 | Beth Reinke                                                                                                                                                           |
| 650 |    152.615380 |    627.514769 | Maija Karala                                                                                                                                                          |
| 651 |    276.141917 |    529.778828 | Matt Crook                                                                                                                                                            |
| 652 |    840.939497 |    371.250538 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 653 |    665.051232 |    755.936691 | Margot Michaud                                                                                                                                                        |
| 654 |    693.813966 |    247.786794 | Chris huh                                                                                                                                                             |
| 655 |     23.122344 |    723.530089 | Mattia Menchetti                                                                                                                                                      |
| 656 |    725.214799 |    248.390890 | Ignacio Contreras                                                                                                                                                     |
| 657 |    695.029734 |    111.756766 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 658 |    762.089989 |    660.049644 | NA                                                                                                                                                                    |
| 659 |    451.487916 |    443.434378 | Kai R. Caspar                                                                                                                                                         |
| 660 |    183.100500 |    409.030504 | Ignacio Contreras                                                                                                                                                     |
| 661 |    607.113404 |    461.545365 | Gareth Monger                                                                                                                                                         |
| 662 |    627.329110 |     33.200618 | T. Michael Keesey                                                                                                                                                     |
| 663 |    783.218911 |    111.725388 | NA                                                                                                                                                                    |
| 664 |    612.082658 |    114.229945 | Jaime Headden                                                                                                                                                         |
| 665 |    932.198399 |    689.591023 | Jon Hill                                                                                                                                                              |
| 666 |     97.712139 |     85.934823 | Ferran Sayol                                                                                                                                                          |
| 667 |    180.038162 |    425.730318 | Steven Traver                                                                                                                                                         |
| 668 |    372.200375 |    701.783180 | Ferran Sayol                                                                                                                                                          |
| 669 |    597.254968 |     69.248019 | Cesar Julian                                                                                                                                                          |
| 670 |    634.698820 |    727.326585 | Maija Karala                                                                                                                                                          |
| 671 |     90.885888 |     38.277103 | NA                                                                                                                                                                    |
| 672 |    843.043713 |    591.022865 | Michael Day                                                                                                                                                           |
| 673 |    493.619592 |    584.591943 | NA                                                                                                                                                                    |
| 674 |    721.671451 |    235.784354 | T. Michael Keesey                                                                                                                                                     |
| 675 |    930.168051 |    196.848445 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 676 |    667.458050 |    169.556462 | Matt Crook                                                                                                                                                            |
| 677 |    401.255681 |     59.961585 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 678 |    852.372846 |    602.697061 | NA                                                                                                                                                                    |
| 679 |    620.717358 |    759.443537 | Matt Crook                                                                                                                                                            |
| 680 |   1011.817162 |    681.553701 | NA                                                                                                                                                                    |
| 681 |    234.430136 |    306.223670 | Zimices                                                                                                                                                               |
| 682 |    261.283232 |    327.945264 | Mo Hassan                                                                                                                                                             |
| 683 |    383.632678 |    380.556092 | Christoph Schomburg                                                                                                                                                   |
| 684 |    804.841693 |    710.439945 | Juan Carlos Jerí                                                                                                                                                      |
| 685 |    694.818606 |    432.843063 | Leon P. A. M. Claessens, Patrick M. O’Connor, David M. Unwin                                                                                                          |
| 686 |    607.765014 |     43.488551 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
| 687 |    988.262623 |     50.898132 | Smokeybjb                                                                                                                                                             |
| 688 |    711.465884 |    445.341995 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 689 |    422.718334 |    183.829250 | Jack Mayer Wood                                                                                                                                                       |
| 690 |    438.153549 |    426.332390 | Zimices                                                                                                                                                               |
| 691 |    566.767658 |    229.154349 | Matt Martyniuk                                                                                                                                                        |
| 692 |    970.428111 |     25.677647 | Steven Traver                                                                                                                                                         |
| 693 |    313.016016 |    121.283703 | Steven Traver                                                                                                                                                         |
| 694 |    409.145218 |      7.990143 | Zimices                                                                                                                                                               |
| 695 |    427.852843 |      4.747873 | Markus A. Grohme                                                                                                                                                      |
| 696 |    128.844930 |    462.570132 | annaleeblysse                                                                                                                                                         |
| 697 |    924.989710 |    792.246369 | Scott Hartman                                                                                                                                                         |
| 698 |    560.665431 |     48.516389 | Kanchi Nanjo                                                                                                                                                          |
| 699 |    242.856814 |    763.388036 | Yan Wong                                                                                                                                                              |
| 700 |    430.595142 |    234.273277 | Zimices                                                                                                                                                               |
| 701 |    497.069479 |    616.862662 | Ingo Braasch                                                                                                                                                          |
| 702 |     18.640811 |    401.946398 | Steven Coombs                                                                                                                                                         |
| 703 |    383.271124 |     45.765379 | Benjamin Monod-Broca                                                                                                                                                  |
| 704 |     16.623276 |    226.164630 | \[unknown\]                                                                                                                                                           |
| 705 |    124.008117 |    114.223572 | Beth Reinke                                                                                                                                                           |
| 706 |     79.592486 |    250.921548 | Margot Michaud                                                                                                                                                        |
| 707 |    263.695069 |    706.846049 | Zimices                                                                                                                                                               |
| 708 |    273.625586 |    555.796445 | Gareth Monger                                                                                                                                                         |
| 709 |    673.435766 |    499.336437 | Steven Traver                                                                                                                                                         |
| 710 |    834.968784 |    255.817814 | Margot Michaud                                                                                                                                                        |
| 711 |    238.227087 |    794.862235 | Beth Reinke                                                                                                                                                           |
| 712 |      5.638387 |    389.162693 | Mali’o Kodis, photograph by P. Funch and R.M. Kristensen                                                                                                              |
| 713 |    808.633915 |      8.196537 | T. Michael Keesey                                                                                                                                                     |
| 714 |    394.381935 |     92.626043 | Matt Crook                                                                                                                                                            |
| 715 |   1008.966421 |     61.084031 | NA                                                                                                                                                                    |
| 716 |    984.668771 |     14.126371 | Sarah Werning                                                                                                                                                         |
| 717 |     36.858057 |    271.014632 | Tracy A. Heath                                                                                                                                                        |
| 718 |    288.690222 |    686.792880 | FJDegrange                                                                                                                                                            |
| 719 |    962.508372 |    694.554068 | T. Michael Keesey                                                                                                                                                     |
| 720 |    382.876630 |    458.470111 | Mathew Wedel                                                                                                                                                          |
| 721 |    899.733285 |    362.620868 | Margot Michaud                                                                                                                                                        |
| 722 |    234.274932 |    137.906132 | Oscar Sanisidro                                                                                                                                                       |
| 723 |    368.994908 |    691.419189 | Y. de Hoev. (vectorized by T. Michael Keesey)                                                                                                                         |
| 724 |     68.834080 |    709.057406 | Lisa M. “Pixxl” (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey       |
| 725 |    932.104426 |    623.999825 | Ferran Sayol                                                                                                                                                          |
| 726 |    311.183476 |    534.467456 | Gareth Monger                                                                                                                                                         |
| 727 |    227.949140 |    538.820287 | Margot Michaud                                                                                                                                                        |
| 728 |    152.851944 |    587.943311 | Scott Hartman                                                                                                                                                         |
| 729 |    839.526601 |    315.719541 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 730 |    623.796185 |    775.280407 | NA                                                                                                                                                                    |
| 731 |    360.900746 |     88.571788 | Chris huh                                                                                                                                                             |
| 732 |    781.309782 |    620.069863 | Scott Reid                                                                                                                                                            |
| 733 |    492.706078 |     15.918266 | Margot Michaud                                                                                                                                                        |
| 734 |    745.754082 |    733.551772 | Tasman Dixon                                                                                                                                                          |
| 735 |    644.699086 |    189.358607 | Jagged Fang Designs                                                                                                                                                   |
| 736 |    960.355354 |    762.486533 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 737 |    237.328497 |    680.122176 | NA                                                                                                                                                                    |
| 738 |     49.618252 |    581.673596 | Jessica Anne Miller                                                                                                                                                   |
| 739 |    704.451608 |    215.701070 | Ferran Sayol                                                                                                                                                          |
| 740 |    229.586587 |    782.262445 | Steven Traver                                                                                                                                                         |
| 741 |    952.469185 |    654.822853 | Tyler McCraney                                                                                                                                                        |
| 742 |    919.212323 |    615.510433 | Scott Hartman                                                                                                                                                         |
| 743 |    627.643030 |    548.688813 | Zimices                                                                                                                                                               |
| 744 |    601.926315 |    358.246486 | Michelle Site                                                                                                                                                         |
| 745 |    256.407615 |    587.929991 | Matt Crook                                                                                                                                                            |
| 746 |    859.817825 |    368.163688 | Lukasiniho                                                                                                                                                            |
| 747 |    650.065456 |    263.994614 | Birgit Lang                                                                                                                                                           |
| 748 |   1013.098318 |    414.874675 | Emma Hughes                                                                                                                                                           |
| 749 |    120.603244 |    301.166328 | Kai R. Caspar                                                                                                                                                         |
| 750 |    329.387020 |    387.960872 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 751 |    167.775751 |    659.482301 | Zimices                                                                                                                                                               |
| 752 |     46.807783 |    376.418580 | Joanna Wolfe                                                                                                                                                          |
| 753 |    741.644561 |    199.402515 | Zimices                                                                                                                                                               |
| 754 |    577.975304 |    484.965015 | Qiang Ou                                                                                                                                                              |
| 755 |    846.185450 |    228.666680 | Chloé Schmidt                                                                                                                                                         |
| 756 |    202.842789 |    213.710194 | Jagged Fang Designs                                                                                                                                                   |
| 757 |    637.276482 |    635.834071 | Margot Michaud                                                                                                                                                        |
| 758 |    667.857884 |     11.936524 | Jagged Fang Designs                                                                                                                                                   |
| 759 |    374.244838 |    466.182740 | Terpsichores                                                                                                                                                          |
| 760 |    237.745611 |    200.540145 | Markus A. Grohme                                                                                                                                                      |
| 761 |    979.531237 |    182.565196 | DW Bapst (Modified from photograph taken by Charles Mitchell)                                                                                                         |
| 762 |    658.371101 |    366.443596 | NA                                                                                                                                                                    |
| 763 |    766.010525 |    615.809329 | Matt Crook                                                                                                                                                            |
| 764 |    258.998120 |    528.554239 | Zimices                                                                                                                                                               |
| 765 |     55.045891 |    797.038600 | NA                                                                                                                                                                    |
| 766 |    239.474747 |    472.321145 | Yusan Yang                                                                                                                                                            |
| 767 |    829.942757 |    406.337187 | Tasman Dixon                                                                                                                                                          |
| 768 |    997.363265 |     58.352642 | Mette Aumala                                                                                                                                                          |
| 769 |    607.404619 |     82.835421 | T. Michael Keesey                                                                                                                                                     |
| 770 |    317.537501 |    249.385971 | Chuanixn Yu                                                                                                                                                           |
| 771 |     19.913807 |    781.864054 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 772 |    991.069922 |    338.417700 | Scott Hartman                                                                                                                                                         |
| 773 |     29.456722 |     91.288621 | Markus A. Grohme                                                                                                                                                      |
| 774 |    326.774788 |    532.504708 | T. Michael Keesey                                                                                                                                                     |
| 775 |    734.883444 |    509.778315 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 776 |    290.590452 |    135.130784 | NA                                                                                                                                                                    |
| 777 |    523.101994 |    681.470202 | Scott Hartman                                                                                                                                                         |
| 778 |    230.731983 |    692.761768 | NA                                                                                                                                                                    |
| 779 |    545.483635 |    179.623203 | Ferran Sayol                                                                                                                                                          |
| 780 |    305.435653 |    795.358617 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                              |
| 781 |     29.283927 |    200.981069 | Margot Michaud                                                                                                                                                        |
| 782 |    224.204874 |    531.868362 | Steven Traver                                                                                                                                                         |
| 783 |    699.429736 |    186.367119 | Jagged Fang Designs                                                                                                                                                   |
| 784 |    556.101083 |    323.267529 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 785 |    394.311060 |    466.361035 | Melissa Broussard                                                                                                                                                     |
| 786 |    868.395649 |    776.140125 | Matt Crook                                                                                                                                                            |
| 787 |    977.324578 |    495.695271 | Zimices                                                                                                                                                               |
| 788 |    954.887727 |    777.506657 | Ignacio Contreras                                                                                                                                                     |
| 789 |     78.370864 |    554.510145 | Sharon Wegner-Larsen                                                                                                                                                  |
| 790 |    297.344933 |     49.964234 | Gareth Monger                                                                                                                                                         |
| 791 |    101.313825 |    584.286683 | Ville Koistinen and T. Michael Keesey                                                                                                                                 |
| 792 |    940.042168 |    428.015474 | Farelli (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
| 793 |    618.685412 |    414.935861 | Joseph Smit (modified by T. Michael Keesey)                                                                                                                           |
| 794 |    861.253944 |    438.074859 | Margot Michaud                                                                                                                                                        |
| 795 |    950.230341 |    211.614233 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                        |
| 796 |    112.346013 |    197.128097 | Mareike C. Janiak                                                                                                                                                     |
| 797 |     92.069639 |    242.192883 | Zimices                                                                                                                                                               |
| 798 |    876.056569 |    437.893171 | Chloé Schmidt                                                                                                                                                         |
| 799 |      7.744482 |    621.221730 | Yan Wong                                                                                                                                                              |
| 800 |    470.522571 |    493.851572 | NA                                                                                                                                                                    |
| 801 |    483.197267 |    527.208296 | Scott Hartman                                                                                                                                                         |
| 802 |    783.762420 |    653.757407 | Jagged Fang Designs                                                                                                                                                   |
| 803 |     50.801961 |    787.884656 | Juan Carlos Jerí                                                                                                                                                      |
| 804 |    896.637553 |    195.036971 | Matt Crook                                                                                                                                                            |
| 805 |    315.832345 |    319.576051 | Scott Hartman                                                                                                                                                         |
| 806 |    694.422651 |     73.639794 | Andy Wilson                                                                                                                                                           |
| 807 |    908.586534 |    700.012480 | Nobu Tamura                                                                                                                                                           |
| 808 |    439.912519 |    167.919655 | Gareth Monger                                                                                                                                                         |
| 809 |    726.595673 |    653.378427 | Matt Crook                                                                                                                                                            |
| 810 |    571.165779 |    552.994293 | Alexis Simon                                                                                                                                                          |
| 811 |    552.010615 |    483.384020 | Matt Crook                                                                                                                                                            |
| 812 |     20.821192 |    316.373273 | Margot Michaud                                                                                                                                                        |
| 813 |    577.992812 |    620.944379 | Matt Crook                                                                                                                                                            |
| 814 |    199.504623 |      8.119718 | NA                                                                                                                                                                    |
| 815 |    916.510841 |    148.449379 | Steven Traver                                                                                                                                                         |
| 816 |    872.609867 |    317.675731 | L. Shyamal                                                                                                                                                            |
| 817 |    669.353228 |     20.890387 | Maha Ghazal                                                                                                                                                           |
| 818 |    185.043261 |    317.435023 | L. Shyamal                                                                                                                                                            |
| 819 |    878.926602 |    600.787855 | Matt Crook                                                                                                                                                            |
| 820 |    813.954712 |    270.504789 | T. Michael Keesey                                                                                                                                                     |
| 821 |    118.424139 |    461.127021 | Emily Willoughby                                                                                                                                                      |
| 822 |    673.663452 |    440.776914 | Zimices                                                                                                                                                               |
| 823 |    201.954871 |    344.476713 | Jon Hill (Photo by DickDaniels: <http://en.wikipedia.org/wiki/File:Green_Woodhoopoe_RWD7.jpg>)                                                                        |
| 824 |    498.142957 |    483.226095 | Gareth Monger                                                                                                                                                         |
| 825 |    163.778436 |     46.624702 | MPF (vectorized by T. Michael Keesey)                                                                                                                                 |
| 826 |    736.954389 |    352.651374 | Almandine (vectorized by T. Michael Keesey)                                                                                                                           |
| 827 |   1006.561972 |    244.385794 | Kamil S. Jaron                                                                                                                                                        |
| 828 |    911.607628 |    581.846441 | Noah Schlottman, photo from Casey Dunn                                                                                                                                |
| 829 |   1002.714413 |     69.600686 | Zimices                                                                                                                                                               |
| 830 |    311.016253 |    673.548741 | Markus A. Grohme                                                                                                                                                      |
| 831 |     28.986348 |    585.083830 | Matt Crook                                                                                                                                                            |
| 832 |    146.609867 |    330.394864 | Margot Michaud                                                                                                                                                        |
| 833 |    295.757351 |    513.476607 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 834 |    893.863809 |    327.060776 | Andrew A. Farke                                                                                                                                                       |
| 835 |     26.647459 |    661.419089 | T. Michael Keesey                                                                                                                                                     |
| 836 |    698.748135 |    451.516146 | CNZdenek                                                                                                                                                              |
| 837 |    454.971934 |    720.380095 | Tasman Dixon                                                                                                                                                          |
| 838 |    655.713840 |    743.725637 | Felix Vaux                                                                                                                                                            |
| 839 |    463.423568 |    428.243909 | Kai R. Caspar                                                                                                                                                         |
| 840 |    979.681889 |    366.102011 | Christoph Schomburg                                                                                                                                                   |
| 841 |    367.639460 |    261.723431 | Rebecca Groom                                                                                                                                                         |
| 842 |    348.473709 |    468.513898 | Sean McCann                                                                                                                                                           |
| 843 |    982.285462 |    349.893805 | Tracy A. Heath                                                                                                                                                        |
| 844 |    710.967715 |    796.490998 | M Kolmann                                                                                                                                                             |
| 845 |    137.490659 |    713.116692 | Matt Crook                                                                                                                                                            |
| 846 |     10.880143 |    463.657487 | Zimices                                                                                                                                                               |
| 847 |    464.595061 |    694.908948 | Yan Wong                                                                                                                                                              |
| 848 |    286.350746 |    224.094886 | Mali’o Kodis, photograph by Cordell Expeditions at Cal Academy                                                                                                        |
| 849 |    690.142637 |    422.227773 | T. Michael Keesey                                                                                                                                                     |
| 850 |    583.286919 |    163.499316 | Kamil S. Jaron                                                                                                                                                        |
| 851 |    878.132082 |    353.169401 | Archaeodontosaurus (vectorized by T. Michael Keesey)                                                                                                                  |
| 852 |    632.646690 |    214.653635 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 853 |    143.833993 |     80.628020 | Matt Crook                                                                                                                                                            |
| 854 |    263.435137 |    509.741579 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 855 |    155.811115 |    342.390583 | FunkMonk                                                                                                                                                              |
| 856 |    526.009628 |    357.721745 | Tracy A. Heath                                                                                                                                                        |
| 857 |    368.691957 |    540.872800 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 858 |    984.661324 |    241.294394 | Emily Willoughby                                                                                                                                                      |
| 859 |    399.498138 |    453.816934 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 860 |    779.313706 |    516.947551 | Robbie Cada (vectorized by T. Michael Keesey)                                                                                                                         |
| 861 |    642.666476 |    791.824754 | Robert Gay                                                                                                                                                            |
| 862 |    242.283083 |    616.635950 | Zimices                                                                                                                                                               |
| 863 |    387.197033 |    397.598658 | Steven Traver                                                                                                                                                         |
| 864 |     76.541257 |    379.382535 | Ferran Sayol                                                                                                                                                          |
| 865 |    423.663647 |     56.440606 | Ignacio Contreras                                                                                                                                                     |
| 866 |    445.785801 |     14.023750 | C. Camilo Julián-Caballero                                                                                                                                            |
| 867 |    594.035921 |    792.984949 | Matt Crook                                                                                                                                                            |
| 868 |    452.695635 |    280.298039 | Esme Ashe-Jepson                                                                                                                                                      |
| 869 |    343.743480 |     10.919264 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 870 |    528.449237 |    186.395658 | Beth Reinke                                                                                                                                                           |
| 871 |    434.517042 |    289.943665 | Stacy Spensley (Modified)                                                                                                                                             |
| 872 |    322.992027 |    615.285790 | T. Michael Keesey                                                                                                                                                     |
| 873 |    720.028956 |    385.042504 | Michelle Site                                                                                                                                                         |
| 874 |     77.656120 |    261.918121 | Douglas Brown (modified by T. Michael Keesey)                                                                                                                         |
| 875 |    333.946527 |    174.630728 | Jimmy Bernot                                                                                                                                                          |
| 876 |    187.169387 |    384.002172 | Sean McCann                                                                                                                                                           |
| 877 |    481.349075 |    508.022649 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                  |
| 878 |    768.482529 |    203.483243 | Zachary Quigley                                                                                                                                                       |
| 879 |    469.429031 |    291.696648 | Markus A. Grohme                                                                                                                                                      |
| 880 |     24.873813 |    628.454879 | Benjamin Monod-Broca                                                                                                                                                  |
| 881 |    385.766946 |    712.273740 | NA                                                                                                                                                                    |
| 882 |     80.408006 |    538.442479 | Steven Traver                                                                                                                                                         |
| 883 |    536.849703 |    371.209544 | T. Michael Keesey                                                                                                                                                     |
| 884 |    299.888509 |    322.554775 | Kamil S. Jaron                                                                                                                                                        |
| 885 |    192.587648 |    371.041153 | Meliponicultor Itaymbere                                                                                                                                              |
| 886 |    936.820438 |    131.736785 | Chris huh                                                                                                                                                             |
| 887 |    622.058441 |    567.541424 | T. Michael Keesey                                                                                                                                                     |
| 888 |    271.489921 |    191.580360 | Tommaso Cancellario                                                                                                                                                   |
| 889 |    750.593272 |     14.743271 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 890 |    188.160531 |    536.674188 | Zimices                                                                                                                                                               |
| 891 |     73.579161 |    587.338082 | Andrew A. Farke                                                                                                                                                       |
| 892 |    499.482424 |    791.275777 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                        |
| 893 |    442.555511 |    240.152609 | Jean-Raphaël Guillaumin (photography) and T. Michael Keesey (vectorization)                                                                                           |
| 894 |    526.974329 |    761.489199 | Metalhead64 (vectorized by T. Michael Keesey)                                                                                                                         |
| 895 |    519.811253 |    164.230179 | Mathew Wedel                                                                                                                                                          |
| 896 |    847.709625 |    377.586199 | Scott Hartman                                                                                                                                                         |
| 897 |    332.556837 |    140.797256 | Scott Hartman                                                                                                                                                         |
| 898 |    197.954899 |    656.334501 | Rebecca Groom                                                                                                                                                         |
| 899 |    317.484541 |    358.967669 | T. Michael Keesey                                                                                                                                                     |
| 900 |    676.943692 |    787.634485 | Matt Dempsey                                                                                                                                                          |
| 901 |    898.961409 |    611.398154 | Antonov (vectorized by T. Michael Keesey)                                                                                                                             |
| 902 |   1009.937658 |    260.137896 | Xavier Giroux-Bougard                                                                                                                                                 |
| 903 |    701.458034 |    721.523514 | Leon P. A. M. Claessens, Patrick M. O’Connor, David M. Unwin                                                                                                          |
| 904 |    117.662102 |    584.881462 | Chris huh                                                                                                                                                             |
| 905 |    753.528989 |     98.707654 | Lukasiniho                                                                                                                                                            |
| 906 |    946.423730 |     88.607222 | Mali’o Kodis, photograph by G. Giribet                                                                                                                                |
| 907 |    476.143840 |    703.632521 | NA                                                                                                                                                                    |
| 908 |   1015.202017 |    423.561260 | Skye M                                                                                                                                                                |
| 909 |    301.037537 |    163.867893 | Steven Traver                                                                                                                                                         |

    #> Your tweet has been posted!
