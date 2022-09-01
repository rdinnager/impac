
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

Beth Reinke, Pollyanna von Knorring and T. Michael Keesey, Mike Hanson,
Matt Crook, Zimices, Markus A. Grohme, Eric Moody, Noah Schlottman,
photo by Antonio Guillén, Ignacio Contreras, T. Michael Keesey, Andrew
A. Farke, Gareth Monger, Margot Michaud, Matt Martyniuk, Chris huh,
Baheerathan Murugavel, Ewald Rübsamen, Gabriela Palomo-Munoz, Scott
Reid, Mathieu Basille, Steven Traver, Mathilde Cordellier, Dmitry
Bogdanov, Smokeybjb, Dmitry Bogdanov (vectorized by T. Michael Keesey),
Iain Reid, Kanchi Nanjo, Robbie N. Cada (vectorized by T. Michael
Keesey), Chase Brownstein, Yan Wong, Martien Brand (original photo),
Renato Santos (vector silhouette), Yan Wong from drawing by Joseph Smit,
Jose Carlos Arenas-Monroy, Noah Schlottman, photo by Casey Dunn, Maxime
Dahirel, Tauana J. Cunha, CNZdenek, Steven Blackwood, Conty (vectorized
by T. Michael Keesey), Michelle Site, Jagged Fang Designs, Nobu Tamura,
vectorized by Zimices, T. Michael Keesey (after A. Y. Ivantsov), Tod
Robbins, John Conway, Tony Ayling (vectorized by T. Michael Keesey),
Scott Hartman, Tracy A. Heath, kotik, Noah Schlottman, photo by Adam G.
Clause, Nobu Tamura (vectorized by T. Michael Keesey), Apokryltaros
(vectorized by T. Michael Keesey), Jon M Laurent, Mali’o Kodis,
photograph by Aqua-Photos
(<http://www.flickr.com/people/undervannsfotografen/>), Brad McFeeters
(vectorized by T. Michael Keesey), Kamil S. Jaron, Sharon Wegner-Larsen,
Taenadoman, Archaeodontosaurus (vectorized by T. Michael Keesey), Ieuan
Jones, Melissa Broussard, L. Shyamal, Emily Willoughby, Kai R. Caspar,
Mattia Menchetti, Alexander Schmidt-Lebuhn, Jaime Headden, Curtis Clark
and T. Michael Keesey, Ferran Sayol, Tyler Greenfield, Anthony
Caravaggi, B. Duygu Özpolat, Hugo Gruson, Dean Schnabel, Christoph
Schomburg, M Kolmann, Jack Mayer Wood, Ingo Braasch, Matt Celeskey,
Birgit Lang, Renata F. Martins, Katie S. Collins, Harold N Eyster,
Tasman Dixon, Andy Wilson, T. Michael Keesey (after Marek Velechovský),
zoosnow, Becky Barnes, Duane Raver (vectorized by T. Michael Keesey),
George Edward Lodge (vectorized by T. Michael Keesey), Sergio A.
Muñoz-Gómez, Taro Maeda, Henry Fairfield Osborn, vectorized by
Zimices, Sarah Werning, Verisimilus, FunkMonk (Michael B. H.), Matthew
E. Clapham, Erika Schumacher, Sean McCann, Carlos Cano-Barbacil, Mathieu
Pélissié, Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael
Keesey), kreidefossilien.de, Dennis C. Murphy, after
<https://commons.wikimedia.org/wiki/File:Queensland_State_Archives_2981_Cane_toads_at_the_Meringa_Sugar_Experiment_Station_North_Queensland_c_1935.png>,
Lafage, Peileppe, Mathew Wedel, Konsta Happonen, from a CC-BY-NC image
by sokolkov2002 on iNaturalist, Scarlet23 (vectorized by T. Michael
Keesey), Benjamin Monod-Broca, Stephen O’Connor (vectorized by T.
Michael Keesey), Walter Vladimir, Zimices, based in Mauricio Antón
skeletal, T. Michael Keesey (after C. De Muizon), White Wolf, Smokeybjb
(vectorized by T. Michael Keesey), Roberto Díaz Sibaja, Birgit Lang;
based on a drawing by C.L. Koch, Sam Fraser-Smith (vectorized by T.
Michael Keesey), Neil Kelley, Jordan Mallon (vectorized by T. Michael
Keesey), Yusan Yang, terngirl, Enoch Joseph Wetsy (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Pete Buchholz,
Collin Gross, James R. Spotila and Ray Chatterji, Alex Slavenko, Zachary
Quigley, Nicholas J. Czaplewski, vectorized by Zimices, Qiang Ou, Juan
Carlos Jerí, Jessica Rick, Matt Martyniuk (modified by T. Michael
Keesey), Yan Wong from photo by Gyik Toma, NOAA Great Lakes
Environmental Research Laboratory (illustration) and Timothy J. Bartley
(silhouette), Jakovche, Terpsichores, Estelle Bourdon, Ghedoghedo
(vectorized by T. Michael Keesey), David Orr, Geoff Shaw, Noah
Schlottman, Obsidian Soul (vectorized by T. Michael Keesey), Yan Wong
from illustration by Jules Richard (1907), Lauren Anderson, Mali’o
Kodis, photograph by Derek Keats
(<http://www.flickr.com/photos/dkeats/>), Margret Flinsch, vectorized by
Zimices, Chris Jennings (Risiatto), Michael Scroggie, Auckland Museum,
Tony Ayling, Steven Coombs (vectorized by T. Michael Keesey), Gabriel
Lio, vectorized by Zimices, Jennifer Trimble, NASA, Jonathan Wells,
xgirouxb, C. Camilo Julián-Caballero, Jerry Oldenettel (vectorized by T.
Michael Keesey), Rebecca Groom, Smokeybjb, vectorized by Zimices, Sidney
Frederic Harmer, Arthur Everett Shipley (vectorized by Maxime Dahirel),
E. R. Waite & H. M. Hale (vectorized by T. Michael Keesey), Caleb M.
Brown, T. Michael Keesey (after Kukalová), DW Bapst (modified from
Bulman, 1970), Pranav Iyer (grey ideas), Noah Schlottman, photo by
Museum of Geology, University of Tartu, Stuart Humphries, Didier
Descouens (vectorized by T. Michael Keesey), Nobu Tamura (vectorized by
A. Verrière), Michael Scroggie, from original photograph by Gary M.
Stolz, USFWS (original photograph in public domain)., T. Michael Keesey
(vectorization) and HuttyMcphoo (photography), Lukas Panzarin, James
Neenan, Pedro de Siracusa, Ralf Janssen, Nikola-Michael Prpic & Wim G.
M. Damen (vectorized by T. Michael Keesey), Christopher Laumer
(vectorized by T. Michael Keesey), Alexandre Vong, Johan Lindgren,
Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe, Rachel Shoop,
Joanna Wolfe, Nobu Tamura, Felix Vaux, Ludwik Gąsiorowski, FunkMonk,
Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela
Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough
(vectorized by T. Michael Keesey), Cesar Julian, Adam Stuart Smith
(vectorized by T. Michael Keesey), Pearson Scott Foresman (vectorized by
T. Michael Keesey), Lani Mohan, Mali’o Kodis, photograph by G. Giribet,
Maija Karala, Nina Skinner, S.Martini, Lee Harding (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Matt Dempsey,
Anna Willoughby, Nobu Tamura, modified by Andrew A. Farke, Rafael Maia,
Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow
(vectorized by T. Michael Keesey), Martin R. Smith, Emma Hughes, Matt
Wilkins (photo by Patrick Kavanagh), Matt Wilkins, Lukasiniho, Kimberly
Haddrell, Jaime Chirinos (vectorized by T. Michael Keesey), Josefine
Bohr Brask, T. Michael Keesey (vectorization) and Tony Hisgett
(photography), Stanton F. Fink (vectorized by T. Michael Keesey),
(unknown), Вальдимар (vectorized by T. Michael Keesey), LeonardoG
(photography) and T. Michael Keesey (vectorization), T. K. Robinson,
FJDegrange, Steven Haddock • Jellywatch.org, Chuanixn Yu, Haplochromis
(vectorized by T. Michael Keesey), Cristian Osorio & Paula Carrera,
Proyecto Carnivoros Australes (www.carnivorosaustrales.org), Tony Ayling
(vectorized by Milton Tan), M. A. Broussard, Javier Luque, Peter
Coxhead, Karina Garcia, John Gould (vectorized by T. Michael Keesey),
George Edward Lodge (modified by T. Michael Keesey), Crystal Maier,
Elisabeth Östman, SecretJellyMan, Tambja (vectorized by T. Michael
Keesey), Conty, Emily Jane McTavish, from
<http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>,
Lankester Edwin Ray (vectorized by T. Michael Keesey), Caio Bernardes,
vectorized by Zimices, Michael P. Taylor, Andreas Hejnol, Xavier A.
Jenkins, Gabriel Ugueto, Campbell Fleming, Scott Hartman (modified by T.
Michael Keesey), Falconaumanni and T. Michael Keesey, Shyamal, Hans
Hillewaert, Darren Naish (vectorized by T. Michael Keesey), Steven
Coombs, Xavier Giroux-Bougard, Armin Reindl, Robbie Cada (vectorized by
T. Michael Keesey), JCGiron, Hans Hillewaert (vectorized by T. Michael
Keesey), Matt Martyniuk (modified by Serenchia), Timothy Knepp
(vectorized by T. Michael Keesey), Griensteidl and T. Michael Keesey,
Inessa Voet, Gregor Bucher, Max Farnworth, Remes K, Ortega F, Fierro I,
Joger U, Kosma R, et al., Jiekun He, Mary Harrsch (modified by T.
Michael Keesey), Florian Pfaff, Maxime Dahirel (digitisation), Kees van
Achterberg et al (doi: 10.3897/BDJ.8.e49017)(original publication),
Ville Koistinen and T. Michael Keesey

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                          |
| --: | ------------: | ------------: | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
|   1 |    705.908865 |    304.096777 | Beth Reinke                                                                                                                                                                     |
|   2 |    182.924727 |    111.973887 | Pollyanna von Knorring and T. Michael Keesey                                                                                                                                    |
|   3 |    580.207877 |    709.063252 | Mike Hanson                                                                                                                                                                     |
|   4 |    882.808535 |    673.342905 | Matt Crook                                                                                                                                                                      |
|   5 |    113.483100 |    674.768255 | Zimices                                                                                                                                                                         |
|   6 |    383.095121 |    329.073540 | Markus A. Grohme                                                                                                                                                                |
|   7 |    112.106017 |    519.188482 | Eric Moody                                                                                                                                                                      |
|   8 |    579.354464 |    769.195529 | Noah Schlottman, photo by Antonio Guillén                                                                                                                                       |
|   9 |    516.438900 |    516.719802 | Ignacio Contreras                                                                                                                                                               |
|  10 |    114.584773 |    350.051768 | T. Michael Keesey                                                                                                                                                               |
|  11 |    145.177307 |    257.678400 | Andrew A. Farke                                                                                                                                                                 |
|  12 |    972.980963 |    361.697021 | Gareth Monger                                                                                                                                                                   |
|  13 |    318.766666 |    707.348554 | NA                                                                                                                                                                              |
|  14 |    273.413526 |    333.624906 | Margot Michaud                                                                                                                                                                  |
|  15 |    744.838972 |     43.824592 | Matt Martyniuk                                                                                                                                                                  |
|  16 |    212.583732 |    577.081187 | Chris huh                                                                                                                                                                       |
|  17 |    934.203392 |     75.126299 | Baheerathan Murugavel                                                                                                                                                           |
|  18 |    732.619625 |    636.336491 | Markus A. Grohme                                                                                                                                                                |
|  19 |    366.796202 |    101.450150 | Ewald Rübsamen                                                                                                                                                                  |
|  20 |    423.248774 |    224.332104 | Gabriela Palomo-Munoz                                                                                                                                                           |
|  21 |    430.020137 |    395.968571 | Scott Reid                                                                                                                                                                      |
|  22 |    486.018259 |     96.896728 | NA                                                                                                                                                                              |
|  23 |    431.268702 |    605.008797 | NA                                                                                                                                                                              |
|  24 |    582.718393 |    446.980311 | Mathieu Basille                                                                                                                                                                 |
|  25 |    710.572837 |    475.061678 | Steven Traver                                                                                                                                                                   |
|  26 |    282.389689 |    487.390110 | Mathieu Basille                                                                                                                                                                 |
|  27 |    225.713088 |    681.035166 | Mathilde Cordellier                                                                                                                                                             |
|  28 |    313.474803 |    433.273864 | Dmitry Bogdanov                                                                                                                                                                 |
|  29 |    672.139236 |     17.239555 | Smokeybjb                                                                                                                                                                       |
|  30 |    885.581186 |    536.565979 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
|  31 |    915.185951 |    753.372313 | Iain Reid                                                                                                                                                                       |
|  32 |    657.646998 |    567.852901 | Kanchi Nanjo                                                                                                                                                                    |
|  33 |    222.910789 |    301.769155 | Matt Crook                                                                                                                                                                      |
|  34 |    747.748882 |     98.768948 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                                |
|  35 |     87.131151 |    149.462826 | Gareth Monger                                                                                                                                                                   |
|  36 |    591.338748 |    110.715618 | Chase Brownstein                                                                                                                                                                |
|  37 |    706.778718 |    735.361071 | Yan Wong                                                                                                                                                                        |
|  38 |    234.818948 |    190.214104 | Martien Brand (original photo), Renato Santos (vector silhouette)                                                                                                               |
|  39 |     87.965268 |     69.657218 | Yan Wong from drawing by Joseph Smit                                                                                                                                            |
|  40 |    937.869283 |    262.712223 | Jose Carlos Arenas-Monroy                                                                                                                                                       |
|  41 |    242.809567 |    769.024500 | Margot Michaud                                                                                                                                                                  |
|  42 |     83.036518 |    482.082344 | Chris huh                                                                                                                                                                       |
|  43 |    200.020701 |    456.104635 | Noah Schlottman, photo by Casey Dunn                                                                                                                                            |
|  44 |    962.870904 |    162.900703 | Maxime Dahirel                                                                                                                                                                  |
|  45 |    863.155580 |    136.190215 | Tauana J. Cunha                                                                                                                                                                 |
|  46 |    341.810899 |    598.743650 | CNZdenek                                                                                                                                                                        |
|  47 |    572.790927 |    623.054059 | Zimices                                                                                                                                                                         |
|  48 |     43.824470 |    276.061645 | Gareth Monger                                                                                                                                                                   |
|  49 |    423.615598 |    736.655818 | Steven Blackwood                                                                                                                                                                |
|  50 |    347.782140 |    551.172587 | Conty (vectorized by T. Michael Keesey)                                                                                                                                         |
|  51 |    797.794836 |    568.287314 | Michelle Site                                                                                                                                                                   |
|  52 |    473.380535 |    177.497261 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
|  53 |    367.401241 |     28.649610 | Steven Traver                                                                                                                                                                   |
|  54 |    608.880069 |    397.795302 | Zimices                                                                                                                                                                         |
|  55 |    261.270119 |     65.782964 | Jagged Fang Designs                                                                                                                                                             |
|  56 |    908.184523 |    595.579267 | Nobu Tamura, vectorized by Zimices                                                                                                                                              |
|  57 |     67.158213 |    191.529921 | T. Michael Keesey (after A. Y. Ivantsov)                                                                                                                                        |
|  58 |     73.153681 |    435.932546 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
|  59 |    230.191026 |     22.618963 | Margot Michaud                                                                                                                                                                  |
|  60 |    285.531343 |    130.833112 | NA                                                                                                                                                                              |
|  61 |    791.796188 |    775.064907 | Tod Robbins                                                                                                                                                                     |
|  62 |    235.231446 |    744.022415 | Markus A. Grohme                                                                                                                                                                |
|  63 |    767.308922 |    153.615311 | Gabriela Palomo-Munoz                                                                                                                                                           |
|  64 |    758.172167 |    690.769552 | John Conway                                                                                                                                                                     |
|  65 |    370.925151 |    296.259098 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                                   |
|  66 |     82.873314 |    564.815317 | Scott Hartman                                                                                                                                                                   |
|  67 |    245.776241 |    615.675471 | Tracy A. Heath                                                                                                                                                                  |
|  68 |    319.210918 |    240.216806 | Matt Crook                                                                                                                                                                      |
|  69 |    610.072065 |    671.592865 | Jagged Fang Designs                                                                                                                                                             |
|  70 |    460.860490 |    771.879530 | Gabriela Palomo-Munoz                                                                                                                                                           |
|  71 |    943.192598 |    472.566701 | NA                                                                                                                                                                              |
|  72 |    413.114118 |    668.138579 | Margot Michaud                                                                                                                                                                  |
|  73 |    820.947278 |    741.763184 | NA                                                                                                                                                                              |
|  74 |    974.946222 |    703.278177 | kotik                                                                                                                                                                           |
|  75 |    810.581887 |     21.889165 | Scott Hartman                                                                                                                                                                   |
|  76 |     41.391232 |    107.248468 | Matt Crook                                                                                                                                                                      |
|  77 |    959.506059 |    648.831524 | Matt Martyniuk                                                                                                                                                                  |
|  78 |    302.322155 |    738.333153 | Noah Schlottman, photo by Adam G. Clause                                                                                                                                        |
|  79 |    564.638691 |    564.088462 | Gabriela Palomo-Munoz                                                                                                                                                           |
|  80 |     33.972734 |    528.657962 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
|  81 |    313.168285 |    570.673456 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                                  |
|  82 |    607.829499 |     20.014731 | Jon M Laurent                                                                                                                                                                   |
|  83 |     52.540538 |    676.772247 | T. Michael Keesey                                                                                                                                                               |
|  84 |    146.045895 |    448.496446 | Mali’o Kodis, photograph by Aqua-Photos (<http://www.flickr.com/people/undervannsfotografen/>)                                                                                  |
|  85 |    576.265168 |     37.969729 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                                |
|  86 |    452.378485 |    708.344389 | Jon M Laurent                                                                                                                                                                   |
|  87 |     30.100328 |    693.143807 | Zimices                                                                                                                                                                         |
|  88 |    474.257500 |    612.824619 | Kamil S. Jaron                                                                                                                                                                  |
|  89 |    938.743030 |    381.823718 | Sharon Wegner-Larsen                                                                                                                                                            |
|  90 |    171.663325 |    198.916025 | Taenadoman                                                                                                                                                                      |
|  91 |    452.870952 |     52.732920 | Archaeodontosaurus (vectorized by T. Michael Keesey)                                                                                                                            |
|  92 |    847.117643 |    460.618636 | Ewald Rübsamen                                                                                                                                                                  |
|  93 |    821.200014 |     61.773297 | Ieuan Jones                                                                                                                                                                     |
|  94 |    768.039504 |     63.392059 | Melissa Broussard                                                                                                                                                               |
|  95 |     48.100801 |    778.064666 | NA                                                                                                                                                                              |
|  96 |    154.378957 |    776.576792 | Nobu Tamura, vectorized by Zimices                                                                                                                                              |
|  97 |    152.947294 |     26.263819 | Beth Reinke                                                                                                                                                                     |
|  98 |    345.591466 |    203.230629 | Chris huh                                                                                                                                                                       |
|  99 |    604.087791 |    527.298495 | L. Shyamal                                                                                                                                                                      |
| 100 |    499.487780 |     17.830703 | Emily Willoughby                                                                                                                                                                |
| 101 |    340.516152 |    423.202313 | NA                                                                                                                                                                              |
| 102 |    999.726282 |    226.406709 | CNZdenek                                                                                                                                                                        |
| 103 |    427.515387 |    494.985181 | Yan Wong                                                                                                                                                                        |
| 104 |    963.917420 |    200.868557 | Kai R. Caspar                                                                                                                                                                   |
| 105 |    492.470484 |    315.055166 | Steven Traver                                                                                                                                                                   |
| 106 |    799.936418 |    669.880627 | Mattia Menchetti                                                                                                                                                                |
| 107 |    450.198345 |    453.538945 | Scott Hartman                                                                                                                                                                   |
| 108 |    517.405734 |    591.033780 | Jagged Fang Designs                                                                                                                                                             |
| 109 |     15.311594 |    397.474643 | Alexander Schmidt-Lebuhn                                                                                                                                                        |
| 110 |    555.449423 |    374.385017 | Jaime Headden                                                                                                                                                                   |
| 111 |    354.165753 |    628.814381 | Zimices                                                                                                                                                                         |
| 112 |    360.501346 |    779.014810 | Curtis Clark and T. Michael Keesey                                                                                                                                              |
| 113 |    958.909352 |     34.193150 | Matt Crook                                                                                                                                                                      |
| 114 |    349.763576 |    149.753973 | Matt Crook                                                                                                                                                                      |
| 115 |    180.074818 |    376.469147 | Ferran Sayol                                                                                                                                                                    |
| 116 |    249.451404 |    545.412676 | T. Michael Keesey                                                                                                                                                               |
| 117 |    445.994658 |    301.490902 | Matt Crook                                                                                                                                                                      |
| 118 |    245.292989 |    450.761362 | Tyler Greenfield                                                                                                                                                                |
| 119 |    871.715339 |     19.164508 | Anthony Caravaggi                                                                                                                                                               |
| 120 |    465.260524 |    335.163774 | NA                                                                                                                                                                              |
| 121 |    392.117673 |    454.239920 | Matt Crook                                                                                                                                                                      |
| 122 |     11.493177 |    637.806318 | Melissa Broussard                                                                                                                                                               |
| 123 |     80.905057 |    782.695252 | Zimices                                                                                                                                                                         |
| 124 |    734.588115 |    560.270137 | Emily Willoughby                                                                                                                                                                |
| 125 |    501.751450 |    569.660207 | Zimices                                                                                                                                                                         |
| 126 |    575.379878 |     20.209185 | Gareth Monger                                                                                                                                                                   |
| 127 |    246.159434 |    436.677870 | B. Duygu Özpolat                                                                                                                                                                |
| 128 |    774.012104 |    592.973745 | Hugo Gruson                                                                                                                                                                     |
| 129 |    201.978309 |    544.665119 | Dean Schnabel                                                                                                                                                                   |
| 130 |    162.450846 |    447.231279 | Margot Michaud                                                                                                                                                                  |
| 131 |    191.531159 |    140.554713 | Ferran Sayol                                                                                                                                                                    |
| 132 |    985.242589 |     13.492808 | Matt Crook                                                                                                                                                                      |
| 133 |    111.598876 |      5.403820 | Christoph Schomburg                                                                                                                                                             |
| 134 |    504.368645 |    396.409169 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 135 |    238.191161 |    115.388698 | CNZdenek                                                                                                                                                                        |
| 136 |    383.415423 |    524.003785 | M Kolmann                                                                                                                                                                       |
| 137 |    841.325033 |    545.779137 | Jack Mayer Wood                                                                                                                                                                 |
| 138 |    525.803028 |    386.657633 | Jagged Fang Designs                                                                                                                                                             |
| 139 |    473.894363 |    794.268295 | Ingo Braasch                                                                                                                                                                    |
| 140 |    607.377512 |    481.211057 | Matt Celeskey                                                                                                                                                                   |
| 141 |   1001.227481 |    589.915784 | Gareth Monger                                                                                                                                                                   |
| 142 |    854.631135 |    263.407631 | Dean Schnabel                                                                                                                                                                   |
| 143 |    108.098538 |    454.459262 | Birgit Lang                                                                                                                                                                     |
| 144 |     31.683699 |    652.573056 | Renata F. Martins                                                                                                                                                               |
| 145 |    155.708706 |    403.069531 | Katie S. Collins                                                                                                                                                                |
| 146 |    215.950953 |    530.931985 | Jaime Headden                                                                                                                                                                   |
| 147 |    154.545522 |    296.447976 | Matt Crook                                                                                                                                                                      |
| 148 |    315.498914 |    177.793749 | Harold N Eyster                                                                                                                                                                 |
| 149 |    150.744732 |    566.600301 | Jagged Fang Designs                                                                                                                                                             |
| 150 |    443.825508 |    463.578616 | T. Michael Keesey                                                                                                                                                               |
| 151 |    516.522642 |    151.708112 | Margot Michaud                                                                                                                                                                  |
| 152 |    403.897525 |    356.295043 | Tasman Dixon                                                                                                                                                                    |
| 153 |     14.494945 |     49.393297 | NA                                                                                                                                                                              |
| 154 |    818.000668 |     99.252593 | NA                                                                                                                                                                              |
| 155 |    377.079191 |     43.591624 | Markus A. Grohme                                                                                                                                                                |
| 156 |    602.422375 |     43.670397 | Markus A. Grohme                                                                                                                                                                |
| 157 |    912.478809 |    135.443116 | Dean Schnabel                                                                                                                                                                   |
| 158 |    524.464222 |    657.220221 | Andy Wilson                                                                                                                                                                     |
| 159 |    485.406000 |    227.740928 | Ferran Sayol                                                                                                                                                                    |
| 160 |     91.987230 |    738.675703 | Ferran Sayol                                                                                                                                                                    |
| 161 |    993.608829 |    289.784313 | T. Michael Keesey (after Marek Velechovský)                                                                                                                                     |
| 162 |    499.713698 |    369.779904 | Ignacio Contreras                                                                                                                                                               |
| 163 |    968.488721 |    748.297001 | zoosnow                                                                                                                                                                         |
| 164 |    647.478788 |    436.043656 | Becky Barnes                                                                                                                                                                    |
| 165 |      8.589269 |    350.213468 | Zimices                                                                                                                                                                         |
| 166 |    263.959292 |    658.711579 | Matt Crook                                                                                                                                                                      |
| 167 |    415.868742 |    479.621317 | Duane Raver (vectorized by T. Michael Keesey)                                                                                                                                   |
| 168 |   1007.116157 |    314.202516 | George Edward Lodge (vectorized by T. Michael Keesey)                                                                                                                           |
| 169 |    321.706326 |    520.400539 | Andrew A. Farke                                                                                                                                                                 |
| 170 |    338.772253 |    191.067959 | Nobu Tamura, vectorized by Zimices                                                                                                                                              |
| 171 |    496.264497 |    249.412786 | NA                                                                                                                                                                              |
| 172 |    913.977715 |    379.868229 | Chris huh                                                                                                                                                                       |
| 173 |    671.726672 |     79.747019 | Matt Crook                                                                                                                                                                      |
| 174 |    384.009208 |    612.085752 | Sergio A. Muñoz-Gómez                                                                                                                                                           |
| 175 |     79.364807 |    414.743267 | Sharon Wegner-Larsen                                                                                                                                                            |
| 176 |    514.234276 |    199.485391 | Taro Maeda                                                                                                                                                                      |
| 177 |     29.252205 |    764.857667 | Birgit Lang                                                                                                                                                                     |
| 178 |    860.529151 |    525.308640 | Steven Traver                                                                                                                                                                   |
| 179 |    622.546516 |    151.982942 | Steven Traver                                                                                                                                                                   |
| 180 |      7.993332 |    792.483134 | Tracy A. Heath                                                                                                                                                                  |
| 181 |     72.263765 |    172.629883 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 182 |   1012.941549 |    192.121161 | Iain Reid                                                                                                                                                                       |
| 183 |    655.811647 |    764.177576 | Gareth Monger                                                                                                                                                                   |
| 184 |    455.339297 |    357.959155 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 185 |    957.400570 |    678.525919 | Ferran Sayol                                                                                                                                                                    |
| 186 |    874.946830 |    285.580650 | Andy Wilson                                                                                                                                                                     |
| 187 |     52.722062 |    379.390056 | T. Michael Keesey                                                                                                                                                               |
| 188 |    490.516465 |    592.850971 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                                                   |
| 189 |    836.671876 |     79.034459 | Sarah Werning                                                                                                                                                                   |
| 190 |    520.241587 |    108.671399 | Tasman Dixon                                                                                                                                                                    |
| 191 |    169.119151 |    774.642635 | Verisimilus                                                                                                                                                                     |
| 192 |    939.949460 |    788.804559 | Steven Traver                                                                                                                                                                   |
| 193 |    251.799978 |    639.312506 | FunkMonk (Michael B. H.)                                                                                                                                                        |
| 194 |    711.092141 |    764.832158 | Margot Michaud                                                                                                                                                                  |
| 195 |    985.844177 |     96.438085 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 196 |    270.759148 |    301.874151 | Ferran Sayol                                                                                                                                                                    |
| 197 |    563.619476 |    581.147804 | Zimices                                                                                                                                                                         |
| 198 |    536.539029 |    401.283695 | Matthew E. Clapham                                                                                                                                                              |
| 199 |    701.018414 |    142.843529 | T. Michael Keesey                                                                                                                                                               |
| 200 |   1000.182894 |     86.393136 | Erika Schumacher                                                                                                                                                                |
| 201 |    408.186493 |    169.898036 | Tracy A. Heath                                                                                                                                                                  |
| 202 |    800.068761 |    462.948741 | Andrew A. Farke                                                                                                                                                                 |
| 203 |     54.378234 |    409.100402 | Sean McCann                                                                                                                                                                     |
| 204 |     90.635346 |    404.045847 | Carlos Cano-Barbacil                                                                                                                                                            |
| 205 |    679.878698 |    664.242171 | Mathieu Pélissié                                                                                                                                                                |
| 206 |    203.075895 |    253.702377 | Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey)                                                                                                                |
| 207 |    914.609196 |    333.791629 | kreidefossilien.de                                                                                                                                                              |
| 208 |    241.200901 |    460.061877 | NA                                                                                                                                                                              |
| 209 |    665.109944 |     49.352697 | Matt Crook                                                                                                                                                                      |
| 210 |    635.965030 |    718.877223 | Sarah Werning                                                                                                                                                                   |
| 211 |    200.813496 |    194.697534 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 212 |    204.170281 |    723.426613 | Dennis C. Murphy, after <https://commons.wikimedia.org/wiki/File:Queensland_State_Archives_2981_Cane_toads_at_the_Meringa_Sugar_Experiment_Station_North_Queensland_c_1935.png> |
| 213 |   1007.479156 |    269.647095 | Ferran Sayol                                                                                                                                                                    |
| 214 |    928.763492 |    466.994736 | B. Duygu Özpolat                                                                                                                                                                |
| 215 |   1015.511051 |    670.430689 | Lafage                                                                                                                                                                          |
| 216 |    120.047527 |    615.938185 | Matt Crook                                                                                                                                                                      |
| 217 |     32.120111 |    349.320880 | Peileppe                                                                                                                                                                        |
| 218 |   1013.283251 |    374.052845 | Mathew Wedel                                                                                                                                                                    |
| 219 |    286.956942 |    580.992459 | Konsta Happonen, from a CC-BY-NC image by sokolkov2002 on iNaturalist                                                                                                           |
| 220 |    510.908798 |    742.475524 | Ferran Sayol                                                                                                                                                                    |
| 221 |    139.375031 |    485.997823 | Chase Brownstein                                                                                                                                                                |
| 222 |    285.944658 |    452.236007 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                                                     |
| 223 |    781.469366 |    520.605084 | Margot Michaud                                                                                                                                                                  |
| 224 |     13.170592 |    345.289284 | Chris huh                                                                                                                                                                       |
| 225 |    519.978184 |    212.304810 | Benjamin Monod-Broca                                                                                                                                                            |
| 226 |    362.639751 |    411.399887 | Gareth Monger                                                                                                                                                                   |
| 227 |    820.510625 |    712.698940 | Mathieu Pélissié                                                                                                                                                                |
| 228 |     67.893948 |    330.802574 | Stephen O’Connor (vectorized by T. Michael Keesey)                                                                                                                              |
| 229 |    291.944164 |    703.162926 | Jaime Headden                                                                                                                                                                   |
| 230 |    798.474076 |    727.183967 | Walter Vladimir                                                                                                                                                                 |
| 231 |    223.000020 |    101.247530 | Zimices, based in Mauricio Antón skeletal                                                                                                                                       |
| 232 |    529.640050 |     29.527708 | T. Michael Keesey (after C. De Muizon)                                                                                                                                          |
| 233 |    383.815116 |    489.541003 | T. Michael Keesey                                                                                                                                                               |
| 234 |    273.176541 |    426.166594 | White Wolf                                                                                                                                                                      |
| 235 |    995.419545 |    536.341519 | Markus A. Grohme                                                                                                                                                                |
| 236 |    620.422048 |    732.086680 | Zimices                                                                                                                                                                         |
| 237 |    312.227616 |     68.908485 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                                     |
| 238 |    840.169011 |    530.425964 | NA                                                                                                                                                                              |
| 239 |    642.609668 |    675.486548 | NA                                                                                                                                                                              |
| 240 |    559.058946 |    489.290041 | Margot Michaud                                                                                                                                                                  |
| 241 |    718.347971 |    584.713534 | Matt Crook                                                                                                                                                                      |
| 242 |    996.640825 |    116.371602 | Michelle Site                                                                                                                                                                   |
| 243 |    678.440126 |    787.432303 | Roberto Díaz Sibaja                                                                                                                                                             |
| 244 |    509.921829 |    351.527836 | NA                                                                                                                                                                              |
| 245 |    341.431437 |     18.872923 | Matt Crook                                                                                                                                                                      |
| 246 |    383.181025 |    769.152671 | Zimices                                                                                                                                                                         |
| 247 |    152.469855 |    556.889343 | Chris huh                                                                                                                                                                       |
| 248 |    600.008385 |    616.829530 | Birgit Lang; based on a drawing by C.L. Koch                                                                                                                                    |
| 249 |    591.533675 |    716.280969 | Sam Fraser-Smith (vectorized by T. Michael Keesey)                                                                                                                              |
| 250 |    292.939507 |    548.593119 | Neil Kelley                                                                                                                                                                     |
| 251 |    363.524345 |    527.802736 | Jordan Mallon (vectorized by T. Michael Keesey)                                                                                                                                 |
| 252 |    663.546258 |    751.589575 | Yusan Yang                                                                                                                                                                      |
| 253 |    641.737648 |     52.465035 | Matt Crook                                                                                                                                                                      |
| 254 |    902.732941 |    772.348293 | T. Michael Keesey                                                                                                                                                               |
| 255 |    482.343641 |    465.400917 | Birgit Lang                                                                                                                                                                     |
| 256 |    948.330334 |    473.174489 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 257 |    176.078335 |    689.347164 | Gareth Monger                                                                                                                                                                   |
| 258 |    689.212516 |    686.875088 | terngirl                                                                                                                                                                        |
| 259 |    352.585278 |    513.549293 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 260 |    687.265711 |    771.368440 | Zimices                                                                                                                                                                         |
| 261 |     63.431385 |     86.642587 | Ferran Sayol                                                                                                                                                                    |
| 262 |    248.555578 |    224.449846 | Gareth Monger                                                                                                                                                                   |
| 263 |    503.896850 |    385.069696 | Enoch Joseph Wetsy (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey              |
| 264 |    807.195909 |     37.903945 | Pete Buchholz                                                                                                                                                                   |
| 265 |    394.770712 |    153.315113 | Collin Gross                                                                                                                                                                    |
| 266 |    643.119133 |    371.609198 | Smokeybjb                                                                                                                                                                       |
| 267 |    248.218814 |    341.097995 | Matt Crook                                                                                                                                                                      |
| 268 |   1005.534814 |    776.755148 | James R. Spotila and Ray Chatterji                                                                                                                                              |
| 269 |    705.355167 |    698.413271 | Michelle Site                                                                                                                                                                   |
| 270 |    346.823231 |    135.634721 | Steven Traver                                                                                                                                                                   |
| 271 |    959.372864 |    278.459280 | Jagged Fang Designs                                                                                                                                                             |
| 272 |    194.955502 |    551.619447 | Birgit Lang                                                                                                                                                                     |
| 273 |    865.855620 |    559.959337 | Scott Hartman                                                                                                                                                                   |
| 274 |    588.322980 |    532.344087 | Alex Slavenko                                                                                                                                                                   |
| 275 |    701.576398 |    593.717086 | T. Michael Keesey                                                                                                                                                               |
| 276 |    431.251930 |     85.876103 | Tauana J. Cunha                                                                                                                                                                 |
| 277 |    355.855522 |    476.125402 | Zimices                                                                                                                                                                         |
| 278 |    423.025155 |    242.525859 | Ferran Sayol                                                                                                                                                                    |
| 279 |    267.468187 |    717.671550 | Gareth Monger                                                                                                                                                                   |
| 280 |     65.046245 |    103.915608 | Matt Martyniuk                                                                                                                                                                  |
| 281 |    155.327454 |    223.935733 | NA                                                                                                                                                                              |
| 282 |    785.265012 |     84.764668 | Ferran Sayol                                                                                                                                                                    |
| 283 |    446.386051 |    478.174734 | Zachary Quigley                                                                                                                                                                 |
| 284 |    721.529438 |    618.057212 | Mathew Wedel                                                                                                                                                                    |
| 285 |    301.664918 |    793.618771 | Nicholas J. Czaplewski, vectorized by Zimices                                                                                                                                   |
| 286 |   1009.504638 |    400.832664 | Scott Reid                                                                                                                                                                      |
| 287 |    361.439100 |    448.243672 | Chris huh                                                                                                                                                                       |
| 288 |    559.582926 |     29.457565 | Michelle Site                                                                                                                                                                   |
| 289 |    254.956602 |    529.464622 | Qiang Ou                                                                                                                                                                        |
| 290 |    662.660144 |    118.415299 | CNZdenek                                                                                                                                                                        |
| 291 |    572.692730 |    727.432256 | Matt Crook                                                                                                                                                                      |
| 292 |    428.550444 |    277.592177 | Juan Carlos Jerí                                                                                                                                                                |
| 293 |    619.092888 |    370.254026 | Steven Blackwood                                                                                                                                                                |
| 294 |    808.136511 |    631.343076 | Anthony Caravaggi                                                                                                                                                               |
| 295 |    456.489248 |     11.487701 | Jaime Headden                                                                                                                                                                   |
| 296 |    378.182048 |    552.324165 | Matt Crook                                                                                                                                                                      |
| 297 |     63.179358 |    712.997960 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 298 |    508.541437 |     37.200100 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 299 |     23.947959 |    459.953054 | Margot Michaud                                                                                                                                                                  |
| 300 |    649.837866 |    630.582523 | Ferran Sayol                                                                                                                                                                    |
| 301 |    533.684006 |    252.989089 | Jessica Rick                                                                                                                                                                    |
| 302 |   1013.787427 |    504.728196 | L. Shyamal                                                                                                                                                                      |
| 303 |    190.314620 |     33.660957 | Matt Martyniuk (modified by T. Michael Keesey)                                                                                                                                  |
| 304 |    456.718086 |    484.625420 | Neil Kelley                                                                                                                                                                     |
| 305 |    845.685986 |     12.491985 | Gareth Monger                                                                                                                                                                   |
| 306 |    804.543746 |    195.384767 | Mathieu Pélissié                                                                                                                                                                |
| 307 |    932.957353 |    712.676260 | Alexander Schmidt-Lebuhn                                                                                                                                                        |
| 308 |    672.466001 |    681.672433 | Yan Wong from photo by Gyik Toma                                                                                                                                                |
| 309 |    391.895042 |    541.422594 | Emily Willoughby                                                                                                                                                                |
| 310 |    280.438005 |    280.640691 | Steven Traver                                                                                                                                                                   |
| 311 |    370.231276 |    744.551005 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                           |
| 312 |    635.919386 |    426.488443 | Matt Crook                                                                                                                                                                      |
| 313 |    168.946851 |    731.981959 | T. Michael Keesey                                                                                                                                                               |
| 314 |    525.266573 |     63.036818 | Tracy A. Heath                                                                                                                                                                  |
| 315 |    744.954737 |    613.890041 | Gareth Monger                                                                                                                                                                   |
| 316 |    607.545727 |    710.917391 | NA                                                                                                                                                                              |
| 317 |    427.910016 |     47.620674 | Jakovche                                                                                                                                                                        |
| 318 |     21.503040 |     95.999919 | Andrew A. Farke                                                                                                                                                                 |
| 319 |    332.599077 |    400.862751 | L. Shyamal                                                                                                                                                                      |
| 320 |    496.216525 |    456.956280 | Ignacio Contreras                                                                                                                                                               |
| 321 |    768.400291 |    611.305819 | Terpsichores                                                                                                                                                                    |
| 322 |     42.865074 |    183.093241 | Ingo Braasch                                                                                                                                                                    |
| 323 |    718.994350 |    126.455767 | Estelle Bourdon                                                                                                                                                                 |
| 324 |    519.439344 |    690.415513 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                                    |
| 325 |    409.725650 |    702.302916 | Steven Traver                                                                                                                                                                   |
| 326 |    201.404168 |    111.340791 | T. Michael Keesey                                                                                                                                                               |
| 327 |    546.580496 |    159.389474 | Ferran Sayol                                                                                                                                                                    |
| 328 |    818.064768 |    655.350216 | David Orr                                                                                                                                                                       |
| 329 |    174.115729 |    387.081482 | Smokeybjb                                                                                                                                                                       |
| 330 |    172.230279 |    495.819142 | Margot Michaud                                                                                                                                                                  |
| 331 |    964.924354 |    285.974428 | Ferran Sayol                                                                                                                                                                    |
| 332 |    614.641393 |    158.248246 | Scott Hartman                                                                                                                                                                   |
| 333 |    544.732536 |    258.918484 | Geoff Shaw                                                                                                                                                                      |
| 334 |    833.741778 |    193.894122 | Steven Traver                                                                                                                                                                   |
| 335 |    379.763436 |    273.681577 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 336 |    216.180840 |    387.845663 | T. Michael Keesey                                                                                                                                                               |
| 337 |    242.959956 |    420.391177 | Scott Hartman                                                                                                                                                                   |
| 338 |   1004.910650 |    200.237171 | Zimices                                                                                                                                                                         |
| 339 |    187.664961 |    238.478449 | Nobu Tamura, vectorized by Zimices                                                                                                                                              |
| 340 |    757.045279 |    583.493050 | Noah Schlottman                                                                                                                                                                 |
| 341 |    443.940535 |    131.597639 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                                 |
| 342 |    949.558458 |    361.293075 | Gareth Monger                                                                                                                                                                   |
| 343 |    501.694424 |    670.718748 | Steven Traver                                                                                                                                                                   |
| 344 |    770.730114 |    715.396655 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 345 |    964.124869 |     47.952776 | Yan Wong from illustration by Jules Richard (1907)                                                                                                                              |
| 346 |    842.880231 |    230.280353 | NA                                                                                                                                                                              |
| 347 |    399.885713 |    629.339124 | Dean Schnabel                                                                                                                                                                   |
| 348 |    568.707225 |     58.434916 | Carlos Cano-Barbacil                                                                                                                                                            |
| 349 |    869.565162 |    209.673812 | Nobu Tamura, vectorized by Zimices                                                                                                                                              |
| 350 |    427.803372 |    133.960076 | Ingo Braasch                                                                                                                                                                    |
| 351 |    893.459965 |    280.578844 | Kamil S. Jaron                                                                                                                                                                  |
| 352 |    383.453714 |    438.565234 | T. Michael Keesey                                                                                                                                                               |
| 353 |    312.314351 |    154.224515 | Lauren Anderson                                                                                                                                                                 |
| 354 |    285.806129 |    522.763822 | Mali’o Kodis, photograph by Derek Keats (<http://www.flickr.com/photos/dkeats/>)                                                                                                |
| 355 |    213.567337 |    797.236740 | Noah Schlottman, photo by Antonio Guillén                                                                                                                                       |
| 356 |     17.982981 |     77.996842 | Margot Michaud                                                                                                                                                                  |
| 357 |    181.489768 |    706.423069 | Margot Michaud                                                                                                                                                                  |
| 358 |    775.398991 |    113.765519 | Zimices                                                                                                                                                                         |
| 359 |    148.461663 |    625.365037 | Margret Flinsch, vectorized by Zimices                                                                                                                                          |
| 360 |    634.123214 |    475.566616 | Chris Jennings (Risiatto)                                                                                                                                                       |
| 361 |     14.889174 |    614.611364 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 362 |    454.466049 |     24.602359 | Steven Traver                                                                                                                                                                   |
| 363 |     27.126019 |    370.897009 | Zimices                                                                                                                                                                         |
| 364 |    724.348820 |    535.747452 | Michael Scroggie                                                                                                                                                                |
| 365 |    729.791712 |    597.944788 | Juan Carlos Jerí                                                                                                                                                                |
| 366 |   1016.792142 |    341.383613 | Margot Michaud                                                                                                                                                                  |
| 367 |    988.882558 |    763.529062 | Auckland Museum                                                                                                                                                                 |
| 368 |    498.879410 |    627.640225 | T. Michael Keesey                                                                                                                                                               |
| 369 |    325.589331 |    204.325535 | Margot Michaud                                                                                                                                                                  |
| 370 |     29.341639 |    158.902820 | Jagged Fang Designs                                                                                                                                                             |
| 371 |    415.574759 |    250.883355 | Mike Hanson                                                                                                                                                                     |
| 372 |    712.810994 |    662.525149 | Gareth Monger                                                                                                                                                                   |
| 373 |    320.215488 |    169.020348 | Tony Ayling                                                                                                                                                                     |
| 374 |    900.616997 |    541.090322 | Steven Coombs (vectorized by T. Michael Keesey)                                                                                                                                 |
| 375 |   1014.965353 |    392.351644 | Sarah Werning                                                                                                                                                                   |
| 376 |   1015.418485 |    763.804217 | NA                                                                                                                                                                              |
| 377 |    732.620403 |    663.304756 | Matt Crook                                                                                                                                                                      |
| 378 |    160.995084 |    465.921880 | Matt Martyniuk                                                                                                                                                                  |
| 379 |    290.371180 |     48.871207 | Steven Traver                                                                                                                                                                   |
| 380 |     46.043210 |    496.824106 | Gabriel Lio, vectorized by Zimices                                                                                                                                              |
| 381 |    271.558541 |    434.178165 | Margot Michaud                                                                                                                                                                  |
| 382 |    515.493436 |    162.642652 | Margot Michaud                                                                                                                                                                  |
| 383 |    942.479175 |    294.644151 | Ignacio Contreras                                                                                                                                                               |
| 384 |    440.304240 |     36.464244 | Andy Wilson                                                                                                                                                                     |
| 385 |     84.909829 |    452.396295 | Jagged Fang Designs                                                                                                                                                             |
| 386 |    261.638642 |    131.460260 | Gareth Monger                                                                                                                                                                   |
| 387 |    987.897491 |    658.153655 | Jennifer Trimble                                                                                                                                                                |
| 388 |    218.559606 |    506.986423 | Zimices                                                                                                                                                                         |
| 389 |    245.892983 |    400.524085 | Nobu Tamura, vectorized by Zimices                                                                                                                                              |
| 390 |    618.001416 |    520.994538 | NASA                                                                                                                                                                            |
| 391 |    259.581439 |     88.394719 | Jonathan Wells                                                                                                                                                                  |
| 392 |    665.113275 |    428.986121 | Andy Wilson                                                                                                                                                                     |
| 393 |    409.552064 |    429.173124 | xgirouxb                                                                                                                                                                        |
| 394 |    377.749749 |     60.206729 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                                 |
| 395 |   1005.169197 |    188.787825 | C. Camilo Julián-Caballero                                                                                                                                                      |
| 396 |    291.308325 |    209.320976 | Emily Willoughby                                                                                                                                                                |
| 397 |    322.297048 |    219.030875 | Margot Michaud                                                                                                                                                                  |
| 398 |    154.774576 |     42.442358 | Jerry Oldenettel (vectorized by T. Michael Keesey)                                                                                                                              |
| 399 |    627.190299 |    511.586753 | Ferran Sayol                                                                                                                                                                    |
| 400 |   1010.336914 |    383.116998 | Matt Celeskey                                                                                                                                                                   |
| 401 |    169.042678 |    178.685128 | Markus A. Grohme                                                                                                                                                                |
| 402 |    888.097373 |    785.413040 | Carlos Cano-Barbacil                                                                                                                                                            |
| 403 |    698.623912 |    387.899604 | Rebecca Groom                                                                                                                                                                   |
| 404 |    920.632491 |    353.847690 | Matt Crook                                                                                                                                                                      |
| 405 |     51.120746 |    726.311182 | Gareth Monger                                                                                                                                                                   |
| 406 |     89.495544 |    772.363622 | NA                                                                                                                                                                              |
| 407 |     14.770972 |    720.717547 | Smokeybjb, vectorized by Zimices                                                                                                                                                |
| 408 |    959.632622 |     17.624954 | Sidney Frederic Harmer, Arthur Everett Shipley (vectorized by Maxime Dahirel)                                                                                                   |
| 409 |    811.145095 |    788.864060 | E. R. Waite & H. M. Hale (vectorized by T. Michael Keesey)                                                                                                                      |
| 410 |    870.354760 |     30.518051 | Scott Hartman                                                                                                                                                                   |
| 411 |    248.735963 |    687.417139 | NA                                                                                                                                                                              |
| 412 |    457.547914 |    462.733197 | NA                                                                                                                                                                              |
| 413 |    466.647453 |    218.697172 | Jagged Fang Designs                                                                                                                                                             |
| 414 |    582.816334 |    593.144512 | Christoph Schomburg                                                                                                                                                             |
| 415 |    416.252492 |    462.102017 | Matt Crook                                                                                                                                                                      |
| 416 |     84.202852 |    162.955932 | Scott Hartman                                                                                                                                                                   |
| 417 |    998.613129 |     48.976796 | NA                                                                                                                                                                              |
| 418 |    808.174348 |    643.136729 | Alexander Schmidt-Lebuhn                                                                                                                                                        |
| 419 |    216.258976 |    476.769269 | Caleb M. Brown                                                                                                                                                                  |
| 420 |    201.036845 |    168.260033 | Zimices                                                                                                                                                                         |
| 421 |    304.579159 |    757.177403 | T. Michael Keesey (after Kukalová)                                                                                                                                              |
| 422 |    465.749710 |    133.909399 | DW Bapst (modified from Bulman, 1970)                                                                                                                                           |
| 423 |   1012.122743 |     50.077245 | Steven Traver                                                                                                                                                                   |
| 424 |    175.226508 |    267.203413 | Pranav Iyer (grey ideas)                                                                                                                                                        |
| 425 |    703.556110 |     19.752029 | T. Michael Keesey                                                                                                                                                               |
| 426 |    337.283825 |    644.217018 | Qiang Ou                                                                                                                                                                        |
| 427 |     44.250836 |    734.959823 | C. Camilo Julián-Caballero                                                                                                                                                      |
| 428 |    656.521516 |    140.445024 | Kai R. Caspar                                                                                                                                                                   |
| 429 |    485.898185 |    568.245875 | Jagged Fang Designs                                                                                                                                                             |
| 430 |    268.564533 |     76.148443 | Rebecca Groom                                                                                                                                                                   |
| 431 |     25.673349 |    753.641436 | Noah Schlottman, photo by Museum of Geology, University of Tartu                                                                                                                |
| 432 |    121.421007 |    409.455602 | Stuart Humphries                                                                                                                                                                |
| 433 |    320.867035 |    380.452639 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                              |
| 434 |    628.943430 |    530.595529 | Markus A. Grohme                                                                                                                                                                |
| 435 |    784.097965 |    693.004223 | Markus A. Grohme                                                                                                                                                                |
| 436 |    160.840009 |    745.076420 | NA                                                                                                                                                                              |
| 437 |    561.896303 |    532.692050 | NA                                                                                                                                                                              |
| 438 |    931.750170 |    201.415721 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                                         |
| 439 |    675.126095 |    100.501964 | Scott Hartman                                                                                                                                                                   |
| 440 |    781.424583 |    502.678713 | Matt Crook                                                                                                                                                                      |
| 441 |    400.773597 |    272.500234 | Ignacio Contreras                                                                                                                                                               |
| 442 |     58.284174 |    542.866973 | Michael Scroggie, from original photograph by Gary M. Stolz, USFWS (original photograph in public domain).                                                                      |
| 443 |    323.470254 |    460.422177 | NA                                                                                                                                                                              |
| 444 |    111.060557 |    441.292910 | Ignacio Contreras                                                                                                                                                               |
| 445 |    193.818655 |    534.447030 | Katie S. Collins                                                                                                                                                                |
| 446 |     71.351566 |    349.655256 | NA                                                                                                                                                                              |
| 447 |    116.806744 |    774.731412 | NA                                                                                                                                                                              |
| 448 |    435.827426 |    356.661170 | Christoph Schomburg                                                                                                                                                             |
| 449 |    961.423587 |    188.376444 | Jagged Fang Designs                                                                                                                                                             |
| 450 |    559.175422 |     13.784309 | T. Michael Keesey (vectorization) and HuttyMcphoo (photography)                                                                                                                 |
| 451 |    509.499302 |    614.048250 | T. Michael Keesey                                                                                                                                                               |
| 452 |     61.459534 |    493.519730 | Zimices                                                                                                                                                                         |
| 453 |     93.331917 |    439.330549 | Scott Hartman                                                                                                                                                                   |
| 454 |   1011.783150 |    415.232414 | Ignacio Contreras                                                                                                                                                               |
| 455 |    590.102580 |    490.876017 | Tasman Dixon                                                                                                                                                                    |
| 456 |    765.063340 |    694.910986 | Zimices                                                                                                                                                                         |
| 457 |    943.473510 |    210.975053 | Carlos Cano-Barbacil                                                                                                                                                            |
| 458 |    490.782949 |    715.598726 | Gareth Monger                                                                                                                                                                   |
| 459 |   1012.908405 |    543.314826 | Steven Traver                                                                                                                                                                   |
| 460 |     80.884753 |    382.150820 | Harold N Eyster                                                                                                                                                                 |
| 461 |      8.062622 |    566.389338 | Lukas Panzarin                                                                                                                                                                  |
| 462 |    987.140706 |    630.856591 | James Neenan                                                                                                                                                                    |
| 463 |     92.584315 |    281.644911 | Michelle Site                                                                                                                                                                   |
| 464 |    303.726215 |    211.312089 | Pedro de Siracusa                                                                                                                                                               |
| 465 |    274.809725 |    557.868842 | Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael Keesey)                                                                                          |
| 466 |    526.550229 |    575.668860 | NA                                                                                                                                                                              |
| 467 |    437.477687 |    113.578890 | Melissa Broussard                                                                                                                                                               |
| 468 |   1001.655428 |    783.318317 | Christopher Laumer (vectorized by T. Michael Keesey)                                                                                                                            |
| 469 |    898.722784 |    110.442337 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 470 |     87.079255 |    235.172227 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 471 |    663.760597 |    795.725124 | Margot Michaud                                                                                                                                                                  |
| 472 |    998.229156 |    208.107963 | Erika Schumacher                                                                                                                                                                |
| 473 |   1014.306653 |    713.510669 | Scott Hartman                                                                                                                                                                   |
| 474 |    205.858729 |    202.019842 | Alexandre Vong                                                                                                                                                                  |
| 475 |    959.020307 |    517.836464 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 476 |    515.069979 |     51.182004 | Matt Crook                                                                                                                                                                      |
| 477 |    679.996561 |    140.775640 | Steven Traver                                                                                                                                                                   |
| 478 |    655.807958 |    780.083092 | Ferran Sayol                                                                                                                                                                    |
| 479 |    656.715949 |    672.749787 | Matt Crook                                                                                                                                                                      |
| 480 |    142.983468 |     15.090421 | Juan Carlos Jerí                                                                                                                                                                |
| 481 |    587.831850 |    792.523588 | Johan Lindgren, Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe                                                                                                            |
| 482 |     41.183575 |    757.352313 | Sarah Werning                                                                                                                                                                   |
| 483 |    945.028711 |    279.511680 | Mathieu Basille                                                                                                                                                                 |
| 484 |    379.020533 |    348.362218 | Renata F. Martins                                                                                                                                                               |
| 485 |    148.959585 |    389.782821 | Rachel Shoop                                                                                                                                                                    |
| 486 |   1008.680732 |    473.274099 | Sidney Frederic Harmer, Arthur Everett Shipley (vectorized by Maxime Dahirel)                                                                                                   |
| 487 |      6.263345 |    663.186567 | Christoph Schomburg                                                                                                                                                             |
| 488 |    853.837843 |     36.384009 | Joanna Wolfe                                                                                                                                                                    |
| 489 |    142.107582 |    508.159605 | Emily Willoughby                                                                                                                                                                |
| 490 |    388.099382 |    572.962891 | Nobu Tamura                                                                                                                                                                     |
| 491 |    504.954031 |    768.474557 | Felix Vaux                                                                                                                                                                      |
| 492 |     96.817203 |    761.413905 | Erika Schumacher                                                                                                                                                                |
| 493 |     85.887368 |    111.211258 | Matt Crook                                                                                                                                                                      |
| 494 |    862.594430 |     49.806062 | Zimices                                                                                                                                                                         |
| 495 |    634.330890 |    518.673096 | Matt Crook                                                                                                                                                                      |
| 496 |    961.703055 |    764.138583 | Ludwik Gąsiorowski                                                                                                                                                              |
| 497 |    807.520188 |    109.252448 | FunkMonk                                                                                                                                                                        |
| 498 |    619.007638 |    342.493886 | Scott Hartman                                                                                                                                                                   |
| 499 |    854.078853 |    217.576299 | Alexander Schmidt-Lebuhn                                                                                                                                                        |
| 500 |    319.563463 |    126.404678 | Zimices                                                                                                                                                                         |
| 501 |    660.514210 |    149.911294 | Roberto Díaz Sibaja                                                                                                                                                             |
| 502 |    782.966526 |    731.242797 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey)           |
| 503 |    617.924506 |    690.063427 | Zimices                                                                                                                                                                         |
| 504 |    435.227872 |    532.009813 | Zimices                                                                                                                                                                         |
| 505 |    851.539655 |     64.772870 | Cesar Julian                                                                                                                                                                    |
| 506 |    721.018244 |    517.794626 | Michelle Site                                                                                                                                                                   |
| 507 |    275.253695 |    322.640153 | Adam Stuart Smith (vectorized by T. Michael Keesey)                                                                                                                             |
| 508 |    986.667679 |     80.221742 | T. Michael Keesey (after Marek Velechovský)                                                                                                                                     |
| 509 |    896.231517 |    209.653276 | Matt Crook                                                                                                                                                                      |
| 510 |    676.885637 |    372.684403 | Steven Traver                                                                                                                                                                   |
| 511 |     46.982302 |     63.945238 | Kai R. Caspar                                                                                                                                                                   |
| 512 |    892.173043 |    459.482513 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                                        |
| 513 |    876.485739 |    525.971370 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 514 |    883.552247 |     53.199033 | Zimices                                                                                                                                                                         |
| 515 |    866.292746 |    775.824868 | NA                                                                                                                                                                              |
| 516 |    858.303931 |    547.082266 | Tauana J. Cunha                                                                                                                                                                 |
| 517 |    447.635784 |    508.004363 | Ferran Sayol                                                                                                                                                                    |
| 518 |    901.694699 |    399.715954 | Lani Mohan                                                                                                                                                                      |
| 519 |    207.761491 |    373.374789 | Margot Michaud                                                                                                                                                                  |
| 520 |    662.326292 |    106.105244 | Yan Wong                                                                                                                                                                        |
| 521 |    994.928319 |    432.701082 | Erika Schumacher                                                                                                                                                                |
| 522 |    155.368861 |    419.819752 | Mali’o Kodis, photograph by G. Giribet                                                                                                                                          |
| 523 |    137.241091 |    774.735072 | Margot Michaud                                                                                                                                                                  |
| 524 |    252.771955 |    102.796578 | Markus A. Grohme                                                                                                                                                                |
| 525 |    323.350651 |    643.622169 | Zimices                                                                                                                                                                         |
| 526 |     14.221788 |    215.246468 | Chris huh                                                                                                                                                                       |
| 527 |    180.777327 |    762.688286 | Matt Crook                                                                                                                                                                      |
| 528 |    198.860937 |     51.991909 | FunkMonk                                                                                                                                                                        |
| 529 |    474.464116 |    366.298889 | Maija Karala                                                                                                                                                                    |
| 530 |    270.037896 |     99.999713 | Matt Crook                                                                                                                                                                      |
| 531 |   1001.904065 |     90.622433 | Nina Skinner                                                                                                                                                                    |
| 532 |    617.954253 |    361.996456 | S.Martini                                                                                                                                                                       |
| 533 |    496.504067 |    737.980496 | David Orr                                                                                                                                                                       |
| 534 |    770.022506 |    433.894117 | L. Shyamal                                                                                                                                                                      |
| 535 |    402.090429 |     51.045367 | Zimices                                                                                                                                                                         |
| 536 |    237.756654 |    556.255005 | Gareth Monger                                                                                                                                                                   |
| 537 |    466.875168 |    161.669127 | Zimices                                                                                                                                                                         |
| 538 |    505.457705 |    715.165603 | Ferran Sayol                                                                                                                                                                    |
| 539 |    513.314696 |    255.906996 | T. Michael Keesey                                                                                                                                                               |
| 540 |    953.380081 |    400.939644 | Carlos Cano-Barbacil                                                                                                                                                            |
| 541 |    665.726886 |    505.903756 | Ignacio Contreras                                                                                                                                                               |
| 542 |    360.317812 |    421.805905 | Kai R. Caspar                                                                                                                                                                   |
| 543 |    909.921992 |    303.366667 | Joanna Wolfe                                                                                                                                                                    |
| 544 |     18.806866 |    570.746416 | Scott Hartman                                                                                                                                                                   |
| 545 |    410.173582 |     56.451608 | Matt Crook                                                                                                                                                                      |
| 546 |    580.651555 |     56.171215 | NA                                                                                                                                                                              |
| 547 |    679.199796 |    153.198716 | Chris huh                                                                                                                                                                       |
| 548 |    130.552377 |    422.413221 | Matt Crook                                                                                                                                                                      |
| 549 |    607.774215 |    348.864724 | Dean Schnabel                                                                                                                                                                   |
| 550 |    877.357867 |    463.901054 | Katie S. Collins                                                                                                                                                                |
| 551 |    877.351165 |     78.854071 | Lee Harding (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                     |
| 552 |    862.511549 |    535.704266 | Zimices                                                                                                                                                                         |
| 553 |    134.229290 |    458.279038 | Chris Jennings (Risiatto)                                                                                                                                                       |
| 554 |    927.288151 |    410.046575 | Ignacio Contreras                                                                                                                                                               |
| 555 |    506.829631 |    318.100683 | Chris huh                                                                                                                                                                       |
| 556 |    155.183258 |    498.139801 | Ferran Sayol                                                                                                                                                                    |
| 557 |   1004.515952 |    451.265708 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 558 |    753.764777 |    592.197100 | Gareth Monger                                                                                                                                                                   |
| 559 |    419.454527 |    713.382598 | Kamil S. Jaron                                                                                                                                                                  |
| 560 |    662.224058 |    638.413695 | Benjamin Monod-Broca                                                                                                                                                            |
| 561 |    712.230886 |    791.676506 | NA                                                                                                                                                                              |
| 562 |    125.861283 |    556.485630 | NA                                                                                                                                                                              |
| 563 |    424.670362 |    514.118203 | Matt Dempsey                                                                                                                                                                    |
| 564 |    530.858827 |    137.791771 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 565 |    672.187781 |    652.850036 | Matt Crook                                                                                                                                                                      |
| 566 |     13.018317 |    114.528500 | Collin Gross                                                                                                                                                                    |
| 567 |    729.221477 |    653.147575 | Anna Willoughby                                                                                                                                                                 |
| 568 |     29.760822 |    581.404809 | Nobu Tamura, modified by Andrew A. Farke                                                                                                                                        |
| 569 |    212.633661 |    645.053719 | Zimices                                                                                                                                                                         |
| 570 |    525.490977 |    265.506802 | Rafael Maia                                                                                                                                                                     |
| 571 |    352.051401 |    501.327969 | Michael Scroggie, from original photograph by Gary M. Stolz, USFWS (original photograph in public domain).                                                                      |
| 572 |    939.418968 |     14.727933 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                             |
| 573 |     40.722876 |    670.618094 | Yan Wong                                                                                                                                                                        |
| 574 |    144.718766 |     50.088978 | Martin R. Smith                                                                                                                                                                 |
| 575 |    479.619368 |    663.808011 | Matt Crook                                                                                                                                                                      |
| 576 |    537.721122 |     53.207605 | Dean Schnabel                                                                                                                                                                   |
| 577 |     33.959307 |    130.616286 | Smokeybjb, vectorized by Zimices                                                                                                                                                |
| 578 |    700.495715 |    375.863171 | Felix Vaux                                                                                                                                                                      |
| 579 |    997.483667 |    269.286178 | Dean Schnabel                                                                                                                                                                   |
| 580 |     10.206725 |    553.690983 | Zimices                                                                                                                                                                         |
| 581 |    272.417227 |    599.479911 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 582 |    435.876718 |     66.441449 | Gareth Monger                                                                                                                                                                   |
| 583 |     30.338622 |    729.599235 | Emma Hughes                                                                                                                                                                     |
| 584 |    602.818589 |    461.000055 | Zimices                                                                                                                                                                         |
| 585 |    901.276668 |    257.414796 | Chris huh                                                                                                                                                                       |
| 586 |    133.892070 |    787.437381 | Dean Schnabel                                                                                                                                                                   |
| 587 |    647.070957 |    498.026460 | Matt Wilkins (photo by Patrick Kavanagh)                                                                                                                                        |
| 588 |    709.858218 |    574.936192 | Jagged Fang Designs                                                                                                                                                             |
| 589 |    822.630622 |      5.493017 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 590 |    544.424614 |    686.189502 | Markus A. Grohme                                                                                                                                                                |
| 591 |    353.748554 |      6.258904 | Margot Michaud                                                                                                                                                                  |
| 592 |    615.690622 |    716.769423 | Mathilde Cordellier                                                                                                                                                             |
| 593 |    705.305912 |    172.093796 | Jack Mayer Wood                                                                                                                                                                 |
| 594 |    691.060736 |    652.602206 | Matt Crook                                                                                                                                                                      |
| 595 |    453.966075 |    582.913192 | Ferran Sayol                                                                                                                                                                    |
| 596 |    229.140602 |    235.214706 | Matt Wilkins                                                                                                                                                                    |
| 597 |    510.073836 |    705.637059 | Markus A. Grohme                                                                                                                                                                |
| 598 |    644.575259 |    449.367352 | Margot Michaud                                                                                                                                                                  |
| 599 |    136.509954 |    394.627637 | NA                                                                                                                                                                              |
| 600 |    169.075529 |    782.405613 | Scott Hartman                                                                                                                                                                   |
| 601 |    523.729471 |    372.274047 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 602 |    781.877867 |     56.187782 | Lukasiniho                                                                                                                                                                      |
| 603 |    212.782923 |    156.076255 | Kimberly Haddrell                                                                                                                                                               |
| 604 |     20.425730 |    148.388749 | Gareth Monger                                                                                                                                                                   |
| 605 |     70.187221 |    393.891672 | Jaime Chirinos (vectorized by T. Michael Keesey)                                                                                                                                |
| 606 |    174.991566 |    359.362515 | Josefine Bohr Brask                                                                                                                                                             |
| 607 |    952.722146 |     54.768592 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 608 |    975.213021 |    268.816267 | Sarah Werning                                                                                                                                                                   |
| 609 |    896.723120 |    520.080201 | Tasman Dixon                                                                                                                                                                    |
| 610 |    173.452658 |    628.956807 | Gareth Monger                                                                                                                                                                   |
| 611 |    413.645042 |    191.156808 | T. Michael Keesey (vectorization) and Tony Hisgett (photography)                                                                                                                |
| 612 |    912.683385 |    397.159114 | Dean Schnabel                                                                                                                                                                   |
| 613 |    241.139757 |    788.497132 | Felix Vaux                                                                                                                                                                      |
| 614 |    294.560931 |     20.427753 | Gareth Monger                                                                                                                                                                   |
| 615 |    415.415049 |     19.000138 | Scott Hartman                                                                                                                                                                   |
| 616 |    222.187150 |    363.345178 | Steven Traver                                                                                                                                                                   |
| 617 |    283.739742 |    200.974231 | Markus A. Grohme                                                                                                                                                                |
| 618 |    483.390554 |    278.826217 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 619 |    588.605048 |    580.868312 | Matt Crook                                                                                                                                                                      |
| 620 |    474.997462 |    660.286188 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                               |
| 621 |    347.777309 |    179.776799 | Andy Wilson                                                                                                                                                                     |
| 622 |     22.578982 |    509.346362 | Jagged Fang Designs                                                                                                                                                             |
| 623 |   1005.775949 |    440.291560 | (unknown)                                                                                                                                                                       |
| 624 |    877.277553 |    541.101787 | Ferran Sayol                                                                                                                                                                    |
| 625 |    790.902493 |    706.030232 | Вальдимар (vectorized by T. Michael Keesey)                                                                                                                                     |
| 626 |    442.976519 |    517.498951 | Ferran Sayol                                                                                                                                                                    |
| 627 |    548.146421 |    584.476567 | LeonardoG (photography) and T. Michael Keesey (vectorization)                                                                                                                   |
| 628 |    906.070794 |    202.183407 | Zimices                                                                                                                                                                         |
| 629 |    489.889927 |    652.220432 | NA                                                                                                                                                                              |
| 630 |    768.924809 |    672.719422 | Scott Hartman                                                                                                                                                                   |
| 631 |    262.895873 |    706.625357 | T. K. Robinson                                                                                                                                                                  |
| 632 |    289.793598 |    717.059431 | Birgit Lang; based on a drawing by C.L. Koch                                                                                                                                    |
| 633 |    212.833105 |    129.793501 | FunkMonk                                                                                                                                                                        |
| 634 |    476.135075 |    148.694443 | Margot Michaud                                                                                                                                                                  |
| 635 |     40.196346 |    506.221044 | Scott Hartman                                                                                                                                                                   |
| 636 |     34.333014 |    794.053648 | Geoff Shaw                                                                                                                                                                      |
| 637 |     97.113836 |    176.038051 | Tasman Dixon                                                                                                                                                                    |
| 638 |    322.086716 |    781.045728 | Matt Crook                                                                                                                                                                      |
| 639 |    241.867266 |    518.143738 | Andrew A. Farke                                                                                                                                                                 |
| 640 |     43.716722 |    515.860262 | Dean Schnabel                                                                                                                                                                   |
| 641 |    681.897000 |    521.536166 | Steven Traver                                                                                                                                                                   |
| 642 |    484.986361 |    640.012418 | Gareth Monger                                                                                                                                                                   |
| 643 |    297.638692 |    691.180990 | Zimices                                                                                                                                                                         |
| 644 |    359.953843 |    436.027396 | FJDegrange                                                                                                                                                                      |
| 645 |    278.383467 |    651.276756 | Вальдимар (vectorized by T. Michael Keesey)                                                                                                                                     |
| 646 |    269.774294 |    540.231432 | Matt Crook                                                                                                                                                                      |
| 647 |    880.878797 |    445.187143 | Steven Haddock • Jellywatch.org                                                                                                                                                 |
| 648 |      6.880804 |    499.217465 | B. Duygu Özpolat                                                                                                                                                                |
| 649 |     99.028523 |    718.830998 | NA                                                                                                                                                                              |
| 650 |    821.081357 |    723.095572 | Lukasiniho                                                                                                                                                                      |
| 651 |    995.952119 |    744.331697 | Ferran Sayol                                                                                                                                                                    |
| 652 |    464.493367 |    597.289627 | Emma Hughes                                                                                                                                                                     |
| 653 |     47.802674 |    455.165149 | Matt Crook                                                                                                                                                                      |
| 654 |    558.802027 |    350.921487 | L. Shyamal                                                                                                                                                                      |
| 655 |    815.827508 |    206.899885 | Chuanixn Yu                                                                                                                                                                     |
| 656 |    417.264010 |    747.110160 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                                  |
| 657 |     27.474123 |    742.516296 | Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org)                                                                                    |
| 658 |    155.902897 |    361.048705 | Zimices                                                                                                                                                                         |
| 659 |    612.949352 |    153.948190 | Tony Ayling (vectorized by Milton Tan)                                                                                                                                          |
| 660 |    237.783843 |     98.844240 | Zimices                                                                                                                                                                         |
| 661 |    422.848584 |    430.554991 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 662 |    855.861172 |    777.434914 | NA                                                                                                                                                                              |
| 663 |    623.028323 |    536.443826 | Andrew A. Farke                                                                                                                                                                 |
| 664 |    837.341443 |     53.182525 | Chris huh                                                                                                                                                                       |
| 665 |    932.525224 |    728.130943 | Carlos Cano-Barbacil                                                                                                                                                            |
| 666 |    127.178567 |    215.797521 | Ignacio Contreras                                                                                                                                                               |
| 667 |    123.993355 |     18.531824 | Gareth Monger                                                                                                                                                                   |
| 668 |    221.388658 |    754.822873 | Chris huh                                                                                                                                                                       |
| 669 |    359.743983 |    707.448920 | M. A. Broussard                                                                                                                                                                 |
| 670 |    506.924233 |    284.973829 | Emily Willoughby                                                                                                                                                                |
| 671 |    499.847876 |    790.681640 | Javier Luque                                                                                                                                                                    |
| 672 |   1014.137022 |    247.204804 | T. Michael Keesey                                                                                                                                                               |
| 673 |      7.706925 |    146.633413 | Anthony Caravaggi                                                                                                                                                               |
| 674 |    518.431926 |    324.677427 | Zimices                                                                                                                                                                         |
| 675 |     12.736947 |    364.720118 | Dmitry Bogdanov                                                                                                                                                                 |
| 676 |    994.219187 |    375.211428 | Mathieu Pélissié                                                                                                                                                                |
| 677 |     85.270997 |    443.494617 | Margret Flinsch, vectorized by Zimices                                                                                                                                          |
| 678 |    605.000514 |    313.400515 | Ferran Sayol                                                                                                                                                                    |
| 679 |    425.331335 |     57.097728 | Scott Hartman                                                                                                                                                                   |
| 680 |     38.210681 |    160.043478 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 681 |    986.814501 |    738.275765 | Peter Coxhead                                                                                                                                                                   |
| 682 |    681.109307 |    426.231595 | Hugo Gruson                                                                                                                                                                     |
| 683 |    633.984509 |    354.631327 | Tasman Dixon                                                                                                                                                                    |
| 684 |     44.476320 |    388.208197 | Carlos Cano-Barbacil                                                                                                                                                            |
| 685 |    960.670713 |    122.339277 | Zimices                                                                                                                                                                         |
| 686 |    330.468329 |    158.390920 | Juan Carlos Jerí                                                                                                                                                                |
| 687 |    370.002018 |    239.346913 | Chris huh                                                                                                                                                                       |
| 688 |    247.209698 |    237.303221 | Katie S. Collins                                                                                                                                                                |
| 689 |    112.279393 |    123.388537 | Ferran Sayol                                                                                                                                                                    |
| 690 |    573.175608 |    647.460131 | Matt Crook                                                                                                                                                                      |
| 691 |     29.644304 |    608.874385 | Karina Garcia                                                                                                                                                                   |
| 692 |    486.029110 |    582.126448 | Margot Michaud                                                                                                                                                                  |
| 693 |    101.396362 |    733.392646 | Rebecca Groom                                                                                                                                                                   |
| 694 |    397.189553 |    709.513978 | John Gould (vectorized by T. Michael Keesey)                                                                                                                                    |
| 695 |    906.548538 |    271.874832 | Erika Schumacher                                                                                                                                                                |
| 696 |    272.333139 |    398.957419 | Tracy A. Heath                                                                                                                                                                  |
| 697 |    827.806625 |    479.078433 | Margot Michaud                                                                                                                                                                  |
| 698 |    165.577237 |    763.221523 | Ferran Sayol                                                                                                                                                                    |
| 699 |    613.525249 |    468.554757 | Gareth Monger                                                                                                                                                                   |
| 700 |    211.949321 |    516.590881 | Andy Wilson                                                                                                                                                                     |
| 701 |    893.111031 |     90.732190 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 702 |    138.468396 |    203.587915 | NA                                                                                                                                                                              |
| 703 |    287.828111 |    262.857125 | Matt Crook                                                                                                                                                                      |
| 704 |    373.645146 |    759.126620 | Jagged Fang Designs                                                                                                                                                             |
| 705 |    667.222235 |     59.674215 | Andy Wilson                                                                                                                                                                     |
| 706 |    566.314503 |    386.647670 | Michael Scroggie                                                                                                                                                                |
| 707 |    413.173781 |    473.770895 | Gareth Monger                                                                                                                                                                   |
| 708 |      6.603579 |     22.796782 | Steven Traver                                                                                                                                                                   |
| 709 |     17.130309 |    495.472750 | Estelle Bourdon                                                                                                                                                                 |
| 710 |    527.387675 |     11.668621 | Steven Traver                                                                                                                                                                   |
| 711 |    707.859277 |    123.806381 | DW Bapst (modified from Bulman, 1970)                                                                                                                                           |
| 712 |    328.692385 |    259.915712 | Ewald Rübsamen                                                                                                                                                                  |
| 713 |    537.788685 |     68.453746 | T. Michael Keesey                                                                                                                                                               |
| 714 |     77.035662 |    124.534489 | Markus A. Grohme                                                                                                                                                                |
| 715 |    434.565837 |    365.023380 | Kai R. Caspar                                                                                                                                                                   |
| 716 |    421.263585 |    146.823581 | T. Michael Keesey                                                                                                                                                               |
| 717 |    738.177688 |    581.976422 | NA                                                                                                                                                                              |
| 718 |    701.489269 |     71.696513 | FunkMonk                                                                                                                                                                        |
| 719 |    377.990616 |    795.415157 | Kamil S. Jaron                                                                                                                                                                  |
| 720 |    869.584302 |    272.769201 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 721 |    121.506693 |    157.548091 | Jennifer Trimble                                                                                                                                                                |
| 722 |    344.521446 |    170.277833 | Steven Traver                                                                                                                                                                   |
| 723 |    783.000329 |      7.115536 | George Edward Lodge (modified by T. Michael Keesey)                                                                                                                             |
| 724 |    198.477057 |    208.649003 | Gareth Monger                                                                                                                                                                   |
| 725 |    795.266922 |    479.824574 | Scott Hartman                                                                                                                                                                   |
| 726 |    634.242823 |    755.479752 | Andy Wilson                                                                                                                                                                     |
| 727 |    232.125931 |    546.100032 | Crystal Maier                                                                                                                                                                   |
| 728 |    498.625895 |    688.641190 | Matt Crook                                                                                                                                                                      |
| 729 |    463.434938 |    669.499250 | Steven Traver                                                                                                                                                                   |
| 730 |    168.925047 |    215.124536 | Elisabeth Östman                                                                                                                                                                |
| 731 |    705.038914 |    520.840143 | Matt Crook                                                                                                                                                                      |
| 732 |     31.789947 |    710.053057 | SecretJellyMan                                                                                                                                                                  |
| 733 |    827.797571 |    565.003569 | Tambja (vectorized by T. Michael Keesey)                                                                                                                                        |
| 734 |    599.627926 |    371.478288 | Zimices                                                                                                                                                                         |
| 735 |    830.047225 |    551.032977 | Rafael Maia                                                                                                                                                                     |
| 736 |    315.395122 |     16.607840 | Zimices                                                                                                                                                                         |
| 737 |    186.030225 |    639.881653 | Erika Schumacher                                                                                                                                                                |
| 738 |    803.209380 |     59.596584 | Gareth Monger                                                                                                                                                                   |
| 739 |    768.047820 |     85.547921 | Margot Michaud                                                                                                                                                                  |
| 740 |    428.005353 |    185.703041 | Jagged Fang Designs                                                                                                                                                             |
| 741 |     63.774407 |    163.885385 | Jaime Headden                                                                                                                                                                   |
| 742 |    809.974999 |    396.060475 | Gareth Monger                                                                                                                                                                   |
| 743 |    475.416349 |    564.197808 | Conty                                                                                                                                                                           |
| 744 |    878.123394 |    172.439006 | NA                                                                                                                                                                              |
| 745 |    975.714865 |    539.352894 | Michelle Site                                                                                                                                                                   |
| 746 |    632.457952 |    444.762057 | Scott Hartman                                                                                                                                                                   |
| 747 |   1013.629240 |     68.546284 | Emily Jane McTavish, from <http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>                                                                     |
| 748 |    967.207920 |    532.834303 | Felix Vaux                                                                                                                                                                      |
| 749 |    619.962678 |     59.730082 | NA                                                                                                                                                                              |
| 750 |    926.257695 |    780.340655 | Scott Hartman                                                                                                                                                                   |
| 751 |    939.926396 |    330.771832 | S.Martini                                                                                                                                                                       |
| 752 |    675.292048 |    691.708340 | Steven Traver                                                                                                                                                                   |
| 753 |   1002.419323 |    739.383574 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                                           |
| 754 |     32.628122 |    638.358842 | Steven Traver                                                                                                                                                                   |
| 755 |    544.876813 |     20.111412 | Yan Wong                                                                                                                                                                        |
| 756 |   1002.896773 |    521.244641 | Steven Traver                                                                                                                                                                   |
| 757 |    374.290621 |    509.290049 | Matt Crook                                                                                                                                                                      |
| 758 |    430.252886 |    103.121702 | T. Michael Keesey                                                                                                                                                               |
| 759 |    333.526950 |    479.895535 | Margot Michaud                                                                                                                                                                  |
| 760 |    589.763029 |    369.736831 | Alexander Schmidt-Lebuhn                                                                                                                                                        |
| 761 |    577.971155 |    553.266081 | Emily Willoughby                                                                                                                                                                |
| 762 |    674.533292 |    378.884862 | Anna Willoughby                                                                                                                                                                 |
| 763 |    490.363801 |    368.858603 | Ludwik Gąsiorowski                                                                                                                                                              |
| 764 |    787.080189 |     47.949796 | Tony Ayling (vectorized by Milton Tan)                                                                                                                                          |
| 765 |    374.504725 |    219.231097 | L. Shyamal                                                                                                                                                                      |
| 766 |    491.263684 |    753.152993 | Tauana J. Cunha                                                                                                                                                                 |
| 767 |    301.698942 |    405.974076 | Curtis Clark and T. Michael Keesey                                                                                                                                              |
| 768 |    552.601805 |    477.522619 | NA                                                                                                                                                                              |
| 769 |    868.848280 |     69.496069 | Ferran Sayol                                                                                                                                                                    |
| 770 |     63.318082 |    729.914091 | Matt Crook                                                                                                                                                                      |
| 771 |    180.122661 |    652.360134 | C. Camilo Julián-Caballero                                                                                                                                                      |
| 772 |     41.297590 |    537.020065 | Maija Karala                                                                                                                                                                    |
| 773 |    600.355421 |    357.889867 | Steven Traver                                                                                                                                                                   |
| 774 |    257.765712 |     40.154238 | Andy Wilson                                                                                                                                                                     |
| 775 |    645.610172 |    137.769883 | Caio Bernardes, vectorized by Zimices                                                                                                                                           |
| 776 |    192.994567 |    616.162368 | Yan Wong                                                                                                                                                                        |
| 777 |    170.439247 |    299.728507 | Zimices                                                                                                                                                                         |
| 778 |    778.239769 |    489.502253 | Alexandre Vong                                                                                                                                                                  |
| 779 |    648.939328 |    689.725965 | Nobu Tamura, vectorized by Zimices                                                                                                                                              |
| 780 |   1015.864789 |    479.866049 | Michael P. Taylor                                                                                                                                                               |
| 781 |    414.284245 |    180.882758 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 782 |    803.146999 |    183.003922 | Scott Hartman                                                                                                                                                                   |
| 783 |    661.393095 |    420.022087 | Andreas Hejnol                                                                                                                                                                  |
| 784 |    861.638667 |    753.553525 | NA                                                                                                                                                                              |
| 785 |    836.571383 |    215.269324 | Margot Michaud                                                                                                                                                                  |
| 786 |    238.952874 |    214.687028 | Chris huh                                                                                                                                                                       |
| 787 |    662.097702 |    366.179142 | Xavier A. Jenkins, Gabriel Ugueto                                                                                                                                               |
| 788 |    513.100093 |    472.238408 | Gareth Monger                                                                                                                                                                   |
| 789 |    108.657594 |    727.978974 | Campbell Fleming                                                                                                                                                                |
| 790 |    474.934863 |    206.632229 | Scott Hartman (modified by T. Michael Keesey)                                                                                                                                   |
| 791 |   1012.346787 |     22.789447 | Margot Michaud                                                                                                                                                                  |
| 792 |    381.929360 |    141.853525 | Scott Hartman                                                                                                                                                                   |
| 793 |    482.447603 |    237.513162 | Steven Traver                                                                                                                                                                   |
| 794 |    328.931631 |    388.210554 | Gareth Monger                                                                                                                                                                   |
| 795 |    693.565834 |    151.677783 | Maxime Dahirel                                                                                                                                                                  |
| 796 |    962.339235 |    472.073878 | Chris huh                                                                                                                                                                       |
| 797 |    823.426952 |     79.144111 | Hugo Gruson                                                                                                                                                                     |
| 798 |    274.388905 |    732.141042 | Anthony Caravaggi                                                                                                                                                               |
| 799 |    204.179496 |    186.436410 | Becky Barnes                                                                                                                                                                    |
| 800 |     93.599216 |      8.981314 | Scott Hartman                                                                                                                                                                   |
| 801 |    681.188992 |    388.157286 | Steven Traver                                                                                                                                                                   |
| 802 |    767.919103 |    170.222107 | Pete Buchholz                                                                                                                                                                   |
| 803 |     29.684087 |     68.338559 | Falconaumanni and T. Michael Keesey                                                                                                                                             |
| 804 |    155.343215 |    486.945506 | Scott Hartman                                                                                                                                                                   |
| 805 |    319.693628 |    761.530867 | Zimices                                                                                                                                                                         |
| 806 |    638.072360 |    705.376130 | Chuanixn Yu                                                                                                                                                                     |
| 807 |    997.351624 |     26.035141 | Harold N Eyster                                                                                                                                                                 |
| 808 |    730.598932 |      5.667769 | Alexander Schmidt-Lebuhn                                                                                                                                                        |
| 809 |    340.833771 |    216.150184 | Anthony Caravaggi                                                                                                                                                               |
| 810 |    717.406104 |    391.647906 | Matt Crook                                                                                                                                                                      |
| 811 |   1003.259607 |    336.041284 | T. Michael Keesey                                                                                                                                                               |
| 812 |     71.237889 |    291.732092 | Matt Crook                                                                                                                                                                      |
| 813 |    355.302153 |    399.092671 | Shyamal                                                                                                                                                                         |
| 814 |    513.718984 |    249.771238 | Hans Hillewaert                                                                                                                                                                 |
| 815 |    857.755763 |    793.441745 | Jessica Rick                                                                                                                                                                    |
| 816 |   1006.789754 |    425.123394 | Scott Hartman                                                                                                                                                                   |
| 817 |    284.734990 |    640.211066 | S.Martini                                                                                                                                                                       |
| 818 |    967.217819 |    453.006749 | NA                                                                                                                                                                              |
| 819 |    725.220894 |    787.687357 | Gareth Monger                                                                                                                                                                   |
| 820 |    780.190895 |    188.019206 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                                  |
| 821 |    840.002397 |    583.778881 | Matt Crook                                                                                                                                                                      |
| 822 |    628.900933 |    678.993936 | Zimices                                                                                                                                                                         |
| 823 |    328.107597 |     64.084317 | terngirl                                                                                                                                                                        |
| 824 |     14.309871 |    764.570702 | Matt Crook                                                                                                                                                                      |
| 825 |    600.356648 |     56.382498 | T. Michael Keesey                                                                                                                                                               |
| 826 |    100.222955 |    770.614758 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 827 |     68.381366 |    488.944031 | Scott Hartman                                                                                                                                                                   |
| 828 |    524.040821 |     73.858399 | NA                                                                                                                                                                              |
| 829 |    192.918643 |    691.946995 | Zimices                                                                                                                                                                         |
| 830 |    219.901030 |    540.694066 | Steven Coombs                                                                                                                                                                   |
| 831 |    352.243737 |    795.928635 | Andrew A. Farke                                                                                                                                                                 |
| 832 |    998.130688 |    543.474277 | Jagged Fang Designs                                                                                                                                                             |
| 833 |    532.951766 |    287.971494 | Steven Traver                                                                                                                                                                   |
| 834 |     68.613090 |    312.441336 | Steven Traver                                                                                                                                                                   |
| 835 |    500.687852 |    721.868802 | Nina Skinner                                                                                                                                                                    |
| 836 |    605.646275 |    594.371016 | Xavier Giroux-Bougard                                                                                                                                                           |
| 837 |    603.818035 |    579.631824 | Chris huh                                                                                                                                                                       |
| 838 |    398.785886 |    174.477819 | Andy Wilson                                                                                                                                                                     |
| 839 |     22.459959 |    305.120825 | Armin Reindl                                                                                                                                                                    |
| 840 |    994.842481 |    404.152358 | Markus A. Grohme                                                                                                                                                                |
| 841 |    841.668307 |     42.431398 | Christoph Schomburg                                                                                                                                                             |
| 842 |    543.716842 |    673.229953 | Robbie Cada (vectorized by T. Michael Keesey)                                                                                                                                   |
| 843 |    200.026874 |    156.878017 | Margot Michaud                                                                                                                                                                  |
| 844 |    334.188723 |    770.519056 | JCGiron                                                                                                                                                                         |
| 845 |    376.258865 |    628.045008 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                               |
| 846 |    299.228815 |    119.747738 | Gareth Monger                                                                                                                                                                   |
| 847 |    958.287412 |    498.786333 | NA                                                                                                                                                                              |
| 848 |    527.474815 |    741.133084 | Scott Hartman                                                                                                                                                                   |
| 849 |    402.719404 |    602.150498 | Zimices                                                                                                                                                                         |
| 850 |    312.480732 |    269.763424 | Kai R. Caspar                                                                                                                                                                   |
| 851 |    342.611051 |    441.579073 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 852 |    583.079662 |    683.432666 | Steven Traver                                                                                                                                                                   |
| 853 |    592.521810 |    547.855795 | Matt Dempsey                                                                                                                                                                    |
| 854 |    782.942419 |    515.208829 | Matt Martyniuk (modified by Serenchia)                                                                                                                                          |
| 855 |    695.251380 |    703.638381 | Steven Haddock • Jellywatch.org                                                                                                                                                 |
| 856 |    688.106421 |    399.162953 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 857 |     82.088097 |    491.158564 | Matt Crook                                                                                                                                                                      |
| 858 |     37.587624 |    683.904831 | Joanna Wolfe                                                                                                                                                                    |
| 859 |    402.573982 |    497.305064 | Zimices                                                                                                                                                                         |
| 860 |    731.873109 |    503.205659 | Timothy Knepp (vectorized by T. Michael Keesey)                                                                                                                                 |
| 861 |    462.147759 |    278.777358 | Griensteidl and T. Michael Keesey                                                                                                                                               |
| 862 |    534.121691 |    749.804461 | Tasman Dixon                                                                                                                                                                    |
| 863 |    790.871276 |    731.718461 | Jaime Headden                                                                                                                                                                   |
| 864 |    472.351593 |    585.749971 | Sean McCann                                                                                                                                                                     |
| 865 |    439.011962 |    350.207637 | Noah Schlottman, photo by Antonio Guillén                                                                                                                                       |
| 866 |    733.204579 |     73.918497 | Smokeybjb                                                                                                                                                                       |
| 867 |    316.984500 |    632.651668 | Carlos Cano-Barbacil                                                                                                                                                            |
| 868 |    448.928318 |    533.226562 | Sean McCann                                                                                                                                                                     |
| 869 |    784.576773 |    526.986574 | Inessa Voet                                                                                                                                                                     |
| 870 |    514.147415 |    725.030432 | NA                                                                                                                                                                              |
| 871 |    406.068637 |    616.244108 | Kamil S. Jaron                                                                                                                                                                  |
| 872 |     42.173375 |     41.437552 | Ieuan Jones                                                                                                                                                                     |
| 873 |    497.451341 |    220.226133 | Nina Skinner                                                                                                                                                                    |
| 874 |     62.735783 |    741.096943 | Nobu Tamura, vectorized by Zimices                                                                                                                                              |
| 875 |    470.290521 |    698.375013 | Rebecca Groom                                                                                                                                                                   |
| 876 |    141.278304 |    723.733021 | Gareth Monger                                                                                                                                                                   |
| 877 |    168.019415 |    710.223123 | Gregor Bucher, Max Farnworth                                                                                                                                                    |
| 878 |   1000.133359 |    361.996567 | NA                                                                                                                                                                              |
| 879 |    590.208408 |    513.106060 | Steven Traver                                                                                                                                                                   |
| 880 |    443.984258 |    542.601142 | Margot Michaud                                                                                                                                                                  |
| 881 |     65.626718 |    794.497660 | Remes K, Ortega F, Fierro I, Joger U, Kosma R, et al.                                                                                                                           |
| 882 |    806.943265 |    716.020931 | Tasman Dixon                                                                                                                                                                    |
| 883 |     75.983205 |     67.673153 | Jiekun He                                                                                                                                                                       |
| 884 |    678.993753 |    121.335142 | T. Michael Keesey                                                                                                                                                               |
| 885 |    178.461759 |    546.269277 | Becky Barnes                                                                                                                                                                    |
| 886 |     17.840921 |     25.226865 | NA                                                                                                                                                                              |
| 887 |    629.522061 |    339.798248 | Collin Gross                                                                                                                                                                    |
| 888 |    358.889493 |    758.116288 | Steven Traver                                                                                                                                                                   |
| 889 |    870.020364 |    267.798343 | Margot Michaud                                                                                                                                                                  |
| 890 |     18.478662 |    201.198333 | Geoff Shaw                                                                                                                                                                      |
| 891 |     78.296393 |    501.375839 | Scott Hartman                                                                                                                                                                   |
| 892 |    827.865547 |    625.468618 | Steven Traver                                                                                                                                                                   |
| 893 |   1014.404148 |    742.014171 | Andy Wilson                                                                                                                                                                     |
| 894 |    186.194462 |    787.079963 | Mary Harrsch (modified by T. Michael Keesey)                                                                                                                                    |
| 895 |    552.000621 |    738.289646 | Scott Hartman                                                                                                                                                                   |
| 896 |    981.504731 |    194.931648 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 897 |    704.192391 |    436.875026 | Maija Karala                                                                                                                                                                    |
| 898 |    377.506042 |    166.433354 | T. Michael Keesey                                                                                                                                                               |
| 899 |      4.916825 |    586.981485 | T. Michael Keesey                                                                                                                                                               |
| 900 |    438.813500 |     19.996389 | Matt Martyniuk                                                                                                                                                                  |
| 901 |    423.496673 |    263.452001 | Chuanixn Yu                                                                                                                                                                     |
| 902 |    426.390256 |    346.111193 | Scott Hartman                                                                                                                                                                   |
| 903 |    168.012799 |    475.166127 | Chris huh                                                                                                                                                                       |
| 904 |    509.646283 |    643.984568 | Andy Wilson                                                                                                                                                                     |
| 905 |     18.996082 |    126.167285 | Gareth Monger                                                                                                                                                                   |
| 906 |    448.364177 |    150.375802 | Matt Crook                                                                                                                                                                      |
| 907 |    623.261236 |     42.041567 | Jagged Fang Designs                                                                                                                                                             |
| 908 |    101.444821 |    614.004080 | Florian Pfaff                                                                                                                                                                   |
| 909 |     51.700787 |     87.915493 | Gareth Monger                                                                                                                                                                   |
| 910 |    476.128565 |    744.336393 | Zimices                                                                                                                                                                         |
| 911 |     51.522630 |    170.808909 | Matt Crook                                                                                                                                                                      |
| 912 |    712.624714 |    133.850751 | Maxime Dahirel (digitisation), Kees van Achterberg et al (doi: 10.3897/BDJ.8.e49017)(original publication)                                                                      |
| 913 |    994.552314 |    411.781822 | Steven Coombs                                                                                                                                                                   |
| 914 |    276.392403 |    781.050366 | Ville Koistinen and T. Michael Keesey                                                                                                                                           |
| 915 |    275.043488 |    583.783965 | Nobu Tamura, vectorized by Zimices                                                                                                                                              |

    #> Your tweet has been posted!
