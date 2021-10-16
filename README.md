
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

Tasman Dixon, Darren Naish (vectorize by T. Michael Keesey), Espen Horn
(model; vectorized by T. Michael Keesey from a photo by H. Zell), Matt
Crook, T. Michael Keesey, Beth Reinke, Lukasiniho, Steven Traver,
Nicolas Mongiardino Koch, Ville Koistinen (vectorized by T. Michael
Keesey), Tracy A. Heath, Gabriela Palomo-Munoz, Dmitry Bogdanov
(vectorized by T. Michael Keesey), Tauana J. Cunha, Gareth Monger, Sean
McCann, Stanton F. Fink, vectorized by Zimices, Antonov (vectorized by
T. Michael Keesey), Chris huh, Ferran Sayol, Zimices, C. Camilo
Julián-Caballero, Yan Wong, Steven Blackwood, Rebecca Groom, Noah
Schlottman, photo by Carol Cummings, Chase Brownstein, Evan-Amos
(vectorized by T. Michael Keesey), Scott Hartman, Jan A. Venter, Herbert
H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael
Keesey), Lankester Edwin Ray (vectorized by T. Michael Keesey), Yan Wong
from wikipedia drawing (PD: Pearson Scott Foresman), Joanna Wolfe,
Margot Michaud, Milton Tan, Mathilde Cordellier, John Gould (vectorized
by T. Michael Keesey), Mattia Menchetti / Yan Wong, Tyler Greenfield and
Scott Hartman, Jagged Fang Designs, Nobu Tamura (vectorized by T.
Michael Keesey), Pearson Scott Foresman (vectorized by T. Michael
Keesey), Lukas Panzarin, Ludwik Gasiorowski, Ghedoghedo (vectorized by
T. Michael Keesey), Cathy, kreidefossilien.de, Nancy Wyman (photo), John
E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G.
Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey,
xgirouxb, Emily Willoughby, Michael Scroggie, from original photograph
by John Bettaso, USFWS (original photograph in public domain)., Martin
R. Smith, after Skovsted et al 2015, Kamil S. Jaron, Shyamal,
SecretJellyMan, Sarah Werning, Plukenet, Collin Gross, Michael Scroggie,
Darius Nau, Becky Barnes, Daniel Jaron, Sam Fraser-Smith (vectorized by
T. Michael Keesey), Birgit Lang, Matt Dempsey, Jaime Headden, Anthony
Caravaggi, Christoph Schomburg, (after Spotila 2004), T. Michael Keesey
(photo by Sean Mack), Jessica Anne Miller, T. Michael Keesey
(vectorization); Thorsten Assmann, Jörn Buse, Claudia Drees,
Ariel-Leib-Leonid Friedman, Tal Levanony, Andrea Matern, Anika Timm, and
David W. Wrase (photography), Melissa Broussard, Cesar Julian, Christian
A. Masnaghetti, Madeleine Price Ball, Iain Reid, Roberto Díaz Sibaja,
Matt Martyniuk, Yan Wong (vectorization) from 1873 illustration, Martin
R. Smith, Acrocynus (vectorized by T. Michael Keesey), Maija Karala,
FunkMonk, John Conway, Walter Vladimir, Steve Hillebrand/U. S. Fish and
Wildlife Service (source photo), T. Michael Keesey (vectorization),
Steven Haddock • Jellywatch.org, Nobu Tamura, Mali’o Kodis, photograph
by “Wildcat Dunny” (<http://www.flickr.com/people/wildcat_dunny/>),
Young and Zhao (1972:figure 4), modified by Michael P. Taylor, Lauren
Sumner-Rooney, Andrew A. Farke, Kai R. Caspar, T. Michael Keesey (photo
by Darren Swim), Cristopher Silva, Andrew Farke and Joseph Sertich,
Bennet McComish, photo by Avenue, Didier Descouens (vectorized by T.
Michael Keesey), Lisa M. “Pixxl” (photo), John E. McCormack, Michael G.
Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb
T. Brumfield & T. Michael Keesey, DW Bapst, modified from Figure 1 of
Belanger (2011, PALAIOS)., Lauren Anderson, Charles R. Knight,
vectorized by Zimices, Andrew A. Farke, shell lines added by Yan Wong,
DW Bapst (modified from Bulman, 1970), Duane Raver (vectorized by T.
Michael Keesey), Greg Schechter (original photo), Renato Santos (vector
silhouette), Matt Martyniuk (modified by T. Michael Keesey), Xavier
Giroux-Bougard, Harold N Eyster, Rene Martin, Kent Elson Sorgon, Steven
Coombs, Katie S. Collins, Darren Naish (vectorized by T. Michael
Keesey), Kailah Thorn & Mark Hutchinson, Robert Bruce Horsfall,
vectorized by Zimices, wsnaccad, Maxwell Lefroy (vectorized by T.
Michael Keesey), Maxime Dahirel, NOAA Great Lakes Environmental Research
Laboratory (illustration) and Timothy J. Bartley (silhouette), G. M.
Woodward, Rebecca Groom (Based on Photo by Andreas Trepte), Gabriel Lio,
vectorized by Zimices, Thea Boodhoo (photograph) and T. Michael Keesey
(vectorization), Alexis Simon, Mario Quevedo, Stanton F. Fink
(vectorized by T. Michael Keesey), Jose Carlos Arenas-Monroy, Jonathan
Wells, Jerry Oldenettel (vectorized by T. Michael Keesey), Ryan Cupo,
Noah Schlottman, Neil Kelley, Jack Mayer Wood, T. Michael Keesey (after
Kukalová), Michele M Tobias, Bill Bouton (source photo) & T. Michael
Keesey (vectorization), L. Shyamal, Andreas Hejnol, Nicolas Huet le
Jeune and Jean-Gabriel Prêtre (vectorized by T. Michael Keesey), Noah
Schlottman, photo by Martin V. Sørensen, Ville Koistinen and T. Michael
Keesey, Manabu Bessho-Uehara, Martin Kevil, Daniel Stadtmauer,
Dr. Thomas G. Barnes, USFWS, Benchill, Kanako Bessho-Uehara, Gopal
Murali, Caleb M. Brown, Rainer Schoch, Fritz Geller-Grimm (vectorized by
T. Michael Keesey), Sherman F. Denton via rawpixel.com (illustration)
and Timothy J. Bartley (silhouette), Alex Slavenko, \[unknown\], Andrés
Sánchez, Francisco Gascó (modified by Michael P. Taylor),
Fir0002/Flagstaffotos (photo), John E. McCormack, Michael G. Harvey,
Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T.
Brumfield & T. Michael Keesey, Amanda Katzer, Eduard Solà Vázquez,
vectorised by Yan Wong, B. Duygu Özpolat, Carlos Cano-Barbacil, Michelle
Site, Obsidian Soul (vectorized by T. Michael Keesey), Almandine
(vectorized by T. Michael Keesey), Jaime Chirinos (vectorized by T.
Michael Keesey), Trond R. Oskars, DW Bapst (Modified from photograph
taken by Charles Mitchell), Mercedes Yrayzoz (vectorized by T. Michael
Keesey), Chris Jennings (Risiatto), Alexander Schmidt-Lebuhn, Vijay
Cavale (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, M Kolmann, Matus Valach, Dmitry Bogdanov and FunkMonk
(vectorized by T. Michael Keesey), George Edward Lodge (vectorized by T.
Michael Keesey), Sergio A. Muñoz-Gómez, Dean Schnabel, Tony Ayling
(vectorized by T. Michael Keesey), Adam Stuart Smith (vectorized by T.
Michael Keesey), James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo
Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael
Keesey), Saguaro Pictures (source photo) and T. Michael Keesey,
Smokeybjb, DFoidl (vectorized by T. Michael Keesey), Philip Chalmers
(vectorized by T. Michael Keesey), Richard Lampitt, Jeremy Young / NHM
(vectorization by Yan Wong), Yusan Yang, M Hutchinson, Tess Linden, V.
Deepak, Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M.
Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus, Doug
Backlund (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Mo Hassan, Alexandre Vong, NASA, Julio Garza, Nobu
Tamura, vectorized by Zimices, Emily Jane McTavish, Original drawing by
Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja, Cristina Guijarro,
\<U+0412\>\<U+0430\>\<U+043B\>\<U+044C\>\<U+0434\>\<U+0438\>\<U+043C\>\<U+0430\>\<U+0440\>
(vectorized by T. Michael Keesey), Felix Vaux, Konsta Happonen, from a
CC-BY-NC image by pelhonen on iNaturalist, James R. Spotila and Ray
Chatterji, Zachary Quigley, Mathew Wedel, Michael Wolf (photo), Hans
Hillewaert (editing), T. Michael Keesey (vectorization), Prathyush
Thomas, T. Michael Keesey (after A. Y. Ivantsov), Smokeybjb, vectorized
by Zimices, Maxime Dahirel (digitisation), Kees van Achterberg et al
(doi: 10.3897/BDJ.8.e49017)(original publication), E. R. Waite & H. M.
Hale (vectorized by T. Michael Keesey), Mali’o Kodis, photograph from
Jersabek et al, 2003, Mali’o Kodis, image from the Smithsonian
Institution, Henry Lydecker, Inessa Voet, Mathieu Basille, Yan Wong from
drawing in The Century Dictionary (1911), Mariana Ruiz (vectorized by T.
Michael Keesey), Ingo Braasch, Armin Reindl, Ellen Edmonson and Hugh
Chrisp (vectorized by T. Michael Keesey), Jean-Raphaël Guillaumin
(photography) and T. Michael Keesey (vectorization), Emily Jane
McTavish, from
<http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>,
Joedison Rocha, Ghedoghedo, vectorized by Zimices, CNZdenek, T. Michael
Keesey (after Joseph Wolf), david maas / dave hone, Bryan Carstens,
Scott Hartman (modified by T. Michael Keesey), T. Michael Keesey (after
Heinrich Harder), Nicholas J. Czaplewski, vectorized by Zimices, Oscar
Sanisidro, Joris van der Ham (vectorized by T. Michael Keesey), Emil
Schmidt (vectorized by Maxime Dahirel), Smokeybjb (modified by Mike
Keesey), Renato de Carvalho Ferreira, Tony Ayling, Matthew E. Clapham,
Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael
Keesey., FJDegrange, Danielle Alba, Martien Brand (original photo),
Renato Santos (vector silhouette), Javier Luque & Sarah Gerken, Frank
Förster (based on a picture by Jerry Kirkhart; modified by T. Michael
Keesey), Lisa Byrne, Frank Denota, Roderic Page and Lois Page, Sharon
Wegner-Larsen, Gordon E. Robertson, Melissa Ingala, Kimberly Haddrell,
Hans Hillewaert (vectorized by T. Michael Keesey), AnAgnosticGod
(vectorized by T. Michael Keesey), Ewald Rübsamen, Ernst Haeckel
(vectorized by T. Michael Keesey), Michael Scroggie, from original
photograph by Gary M. Stolz, USFWS (original photograph in public
domain)., Keith Murdock (photo), John E. McCormack, Michael G. Harvey,
Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T.
Brumfield & T. Michael Keesey, Sherman Foote Denton (illustration, 1897)
and Timothy J. Bartley (silhouette)

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                               |
| --: | ------------: | ------------: | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |     95.565444 |    725.921133 | Tasman Dixon                                                                                                                                                                         |
|   2 |    594.070252 |    556.531143 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                                        |
|   3 |    767.447567 |    730.980882 | Espen Horn (model; vectorized by T. Michael Keesey from a photo by H. Zell)                                                                                                          |
|   4 |    321.616874 |    333.728913 | Matt Crook                                                                                                                                                                           |
|   5 |    548.534181 |    123.909254 | T. Michael Keesey                                                                                                                                                                    |
|   6 |    746.903950 |     65.152139 | Beth Reinke                                                                                                                                                                          |
|   7 |    310.862494 |     85.817310 | NA                                                                                                                                                                                   |
|   8 |    214.910804 |    539.422512 | Lukasiniho                                                                                                                                                                           |
|   9 |     96.463109 |    358.674692 | Steven Traver                                                                                                                                                                        |
|  10 |    679.981952 |    388.602862 | Matt Crook                                                                                                                                                                           |
|  11 |    857.440301 |    398.277055 | Nicolas Mongiardino Koch                                                                                                                                                             |
|  12 |    602.855046 |    230.543532 | Steven Traver                                                                                                                                                                        |
|  13 |    573.620285 |    321.766215 | Ville Koistinen (vectorized by T. Michael Keesey)                                                                                                                                    |
|  14 |    581.124980 |    777.165218 | NA                                                                                                                                                                                   |
|  15 |    139.954833 |     79.595756 | Tracy A. Heath                                                                                                                                                                       |
|  16 |    935.344413 |    494.838414 | NA                                                                                                                                                                                   |
|  17 |    892.120703 |    128.498840 | Matt Crook                                                                                                                                                                           |
|  18 |     91.664269 |    630.441176 | Matt Crook                                                                                                                                                                           |
|  19 |    343.229075 |    649.529060 | Gabriela Palomo-Munoz                                                                                                                                                                |
|  20 |    297.545489 |    729.381215 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
|  21 |    516.781709 |    674.054005 | Tauana J. Cunha                                                                                                                                                                      |
|  22 |    425.702583 |    195.371969 | Gareth Monger                                                                                                                                                                        |
|  23 |    391.998794 |    566.680773 | NA                                                                                                                                                                                   |
|  24 |    776.582342 |    262.142450 | Tracy A. Heath                                                                                                                                                                       |
|  25 |    346.597006 |    498.913270 | Sean McCann                                                                                                                                                                          |
|  26 |    506.342883 |     33.628448 | Stanton F. Fink, vectorized by Zimices                                                                                                                                               |
|  27 |    796.927681 |    563.866519 | Gareth Monger                                                                                                                                                                        |
|  28 |    960.808414 |    273.785345 | Antonov (vectorized by T. Michael Keesey)                                                                                                                                            |
|  29 |    943.857482 |     35.784476 | Chris huh                                                                                                                                                                            |
|  30 |    899.652478 |    686.773886 | NA                                                                                                                                                                                   |
|  31 |    434.226441 |    728.574604 | Gareth Monger                                                                                                                                                                        |
|  32 |    195.099500 |    183.230840 | Ferran Sayol                                                                                                                                                                         |
|  33 |    744.447061 |    165.465952 | Zimices                                                                                                                                                                              |
|  34 |    164.156320 |    686.343392 | C. Camilo Julián-Caballero                                                                                                                                                           |
|  35 |    159.655110 |    779.180314 | NA                                                                                                                                                                                   |
|  36 |    134.875076 |    247.579499 | Yan Wong                                                                                                                                                                             |
|  37 |    294.944367 |    458.147736 | Steven Blackwood                                                                                                                                                                     |
|  38 |    857.929382 |    645.723092 | Rebecca Groom                                                                                                                                                                        |
|  39 |    469.367203 |    267.786297 | Matt Crook                                                                                                                                                                           |
|  40 |    987.843919 |    161.414723 | Gareth Monger                                                                                                                                                                        |
|  41 |    112.052204 |    479.310378 | Noah Schlottman, photo by Carol Cummings                                                                                                                                             |
|  42 |    635.197617 |     50.591991 | Chase Brownstein                                                                                                                                                                     |
|  43 |    931.551079 |    727.386895 | Evan-Amos (vectorized by T. Michael Keesey)                                                                                                                                          |
|  44 |     73.759654 |    135.148326 | Chris huh                                                                                                                                                                            |
|  45 |    947.462205 |    329.842278 | Scott Hartman                                                                                                                                                                        |
|  46 |    230.182820 |    611.527585 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                                  |
|  47 |    294.341963 |    204.205279 | Matt Crook                                                                                                                                                                           |
|  48 |    753.485966 |    653.531756 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
|  49 |    436.502639 |    464.661011 | Zimices                                                                                                                                                                              |
|  50 |    605.169063 |    473.994072 | NA                                                                                                                                                                                   |
|  51 |    507.735753 |    293.616228 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                                                |
|  52 |    943.457002 |    566.473857 | Yan Wong from wikipedia drawing (PD: Pearson Scott Foresman)                                                                                                                         |
|  53 |    775.740445 |    483.884853 | Joanna Wolfe                                                                                                                                                                         |
|  54 |    457.533727 |    613.596617 | Margot Michaud                                                                                                                                                                       |
|  55 |    129.371209 |    292.999181 | Milton Tan                                                                                                                                                                           |
|  56 |    835.661393 |    335.443313 | C. Camilo Julián-Caballero                                                                                                                                                           |
|  57 |    117.071899 |     25.074067 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
|  58 |    656.050359 |    176.961997 | Mathilde Cordellier                                                                                                                                                                  |
|  59 |    975.747237 |    443.798567 | NA                                                                                                                                                                                   |
|  60 |    835.041442 |    244.170412 | John Gould (vectorized by T. Michael Keesey)                                                                                                                                         |
|  61 |     76.016838 |    199.807217 | Mattia Menchetti / Yan Wong                                                                                                                                                          |
|  62 |    835.380534 |     27.783025 | Tyler Greenfield and Scott Hartman                                                                                                                                                   |
|  63 |    729.130348 |    223.803895 | Jagged Fang Designs                                                                                                                                                                  |
|  64 |    770.414585 |    782.876820 | Scott Hartman                                                                                                                                                                        |
|  65 |    663.295862 |     18.350615 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
|  66 |    919.035032 |    601.270672 | Chris huh                                                                                                                                                                            |
|  67 |     39.418833 |    433.971109 | Zimices                                                                                                                                                                              |
|  68 |    681.534363 |    293.913593 | Scott Hartman                                                                                                                                                                        |
|  69 |    477.586214 |    153.597891 | Gareth Monger                                                                                                                                                                        |
|  70 |    192.371117 |    746.599222 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                                             |
|  71 |    919.341856 |    210.680374 | Ferran Sayol                                                                                                                                                                         |
|  72 |    754.834500 |    421.875407 | Lukas Panzarin                                                                                                                                                                       |
|  73 |    572.810650 |    419.676260 | Ludwik Gasiorowski                                                                                                                                                                   |
|  74 |    700.401386 |    267.797779 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                                         |
|  75 |    625.836750 |    456.243323 | Matt Crook                                                                                                                                                                           |
|  76 |    704.248231 |    316.920468 | Matt Crook                                                                                                                                                                           |
|  77 |    960.484435 |    585.694131 | Cathy                                                                                                                                                                                |
|  78 |    974.749369 |    792.657451 | T. Michael Keesey                                                                                                                                                                    |
|  79 |   1012.835449 |    725.790129 | kreidefossilien.de                                                                                                                                                                   |
|  80 |    423.968080 |    538.446334 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                                        |
|  81 |    671.800770 |    612.998478 | Ferran Sayol                                                                                                                                                                         |
|  82 |    557.444059 |    621.850987 | Ferran Sayol                                                                                                                                                                         |
|  83 |    298.606593 |    669.028213 | Nancy Wyman (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                          |
|  84 |    354.505550 |    525.016377 | Chris huh                                                                                                                                                                            |
|  85 |    921.457808 |    398.710339 | Matt Crook                                                                                                                                                                           |
|  86 |    687.375850 |    689.624999 | Gareth Monger                                                                                                                                                                        |
|  87 |    376.842776 |    609.178559 | Matt Crook                                                                                                                                                                           |
|  88 |    359.683186 |    429.330138 | Scott Hartman                                                                                                                                                                        |
|  89 |     46.922342 |    279.930936 | Chris huh                                                                                                                                                                            |
|  90 |    562.614392 |    765.124402 | T. Michael Keesey                                                                                                                                                                    |
|  91 |     56.001758 |    116.995341 | xgirouxb                                                                                                                                                                             |
|  92 |    634.205188 |    267.731591 | T. Michael Keesey                                                                                                                                                                    |
|  93 |    188.007808 |    389.724363 | Steven Traver                                                                                                                                                                        |
|  94 |    535.185808 |    416.426315 | Emily Willoughby                                                                                                                                                                     |
|  95 |    374.203820 |    210.181076 | Michael Scroggie, from original photograph by John Bettaso, USFWS (original photograph in public domain).                                                                            |
|  96 |    771.415511 |    131.024799 | Margot Michaud                                                                                                                                                                       |
|  97 |     63.537219 |    758.065303 | Martin R. Smith, after Skovsted et al 2015                                                                                                                                           |
|  98 |    534.380984 |    448.125099 | Chris huh                                                                                                                                                                            |
|  99 |    129.870508 |    572.875445 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 100 |    975.773108 |     10.462969 | Scott Hartman                                                                                                                                                                        |
| 101 |    205.136145 |    568.844507 | Kamil S. Jaron                                                                                                                                                                       |
| 102 |    918.470436 |    337.703575 | Scott Hartman                                                                                                                                                                        |
| 103 |    212.670823 |    470.312957 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 104 |    243.336514 |    680.124643 | Scott Hartman                                                                                                                                                                        |
| 105 |    230.594003 |     14.643419 | Shyamal                                                                                                                                                                              |
| 106 |    779.195102 |    402.854469 | SecretJellyMan                                                                                                                                                                       |
| 107 |    215.899606 |    364.774892 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 108 |     79.314945 |    699.324811 | Margot Michaud                                                                                                                                                                       |
| 109 |    360.734897 |    347.673837 | xgirouxb                                                                                                                                                                             |
| 110 |    503.663213 |    569.068268 | Scott Hartman                                                                                                                                                                        |
| 111 |    378.569655 |     23.472127 | T. Michael Keesey                                                                                                                                                                    |
| 112 |    102.185478 |    162.001232 | Jagged Fang Designs                                                                                                                                                                  |
| 113 |    601.530943 |    323.285945 | NA                                                                                                                                                                                   |
| 114 |    606.360600 |    196.613363 | Ferran Sayol                                                                                                                                                                         |
| 115 |    477.565186 |    780.158740 | Kamil S. Jaron                                                                                                                                                                       |
| 116 |    814.043725 |    530.387696 | Sarah Werning                                                                                                                                                                        |
| 117 |    329.142712 |    511.866499 | Zimices                                                                                                                                                                              |
| 118 |    176.974023 |      7.568594 | Plukenet                                                                                                                                                                             |
| 119 |    147.072658 |    498.600803 | Collin Gross                                                                                                                                                                         |
| 120 |     16.862467 |    104.247998 | Zimices                                                                                                                                                                              |
| 121 |    377.484415 |    415.696155 | Michael Scroggie                                                                                                                                                                     |
| 122 |    623.800811 |    217.775114 | Darius Nau                                                                                                                                                                           |
| 123 |     23.000941 |    776.088135 | Becky Barnes                                                                                                                                                                         |
| 124 |    978.393648 |    628.552167 | Steven Traver                                                                                                                                                                        |
| 125 |    999.217631 |    789.722404 | Daniel Jaron                                                                                                                                                                         |
| 126 |    826.324223 |    336.386703 | Zimices                                                                                                                                                                              |
| 127 |    197.213154 |    323.416050 | Becky Barnes                                                                                                                                                                         |
| 128 |     10.052881 |    762.077562 | Tasman Dixon                                                                                                                                                                         |
| 129 |     36.708837 |     74.051485 | Gareth Monger                                                                                                                                                                        |
| 130 |    437.193807 |     82.741251 | NA                                                                                                                                                                                   |
| 131 |     20.943196 |     28.966718 | Sam Fraser-Smith (vectorized by T. Michael Keesey)                                                                                                                                   |
| 132 |    839.822648 |    562.191582 | Birgit Lang                                                                                                                                                                          |
| 133 |    426.397694 |    317.464577 | Gareth Monger                                                                                                                                                                        |
| 134 |    824.261703 |    130.166111 | Matt Dempsey                                                                                                                                                                         |
| 135 |    107.656063 |    420.101190 | NA                                                                                                                                                                                   |
| 136 |    585.912034 |    687.558135 | Rebecca Groom                                                                                                                                                                        |
| 137 |     86.338476 |     83.934339 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 138 |     20.641192 |    492.512647 | Zimices                                                                                                                                                                              |
| 139 |    366.076214 |    595.154127 | Jaime Headden                                                                                                                                                                        |
| 140 |    340.180307 |    741.787292 | Anthony Caravaggi                                                                                                                                                                    |
| 141 |    577.103837 |    146.523663 | Christoph Schomburg                                                                                                                                                                  |
| 142 |    462.659426 |    132.490007 | Jagged Fang Designs                                                                                                                                                                  |
| 143 |    384.194446 |    453.088897 | (after Spotila 2004)                                                                                                                                                                 |
| 144 |    341.264261 |    221.294447 | Margot Michaud                                                                                                                                                                       |
| 145 |    875.282851 |    263.810289 | Zimices                                                                                                                                                                              |
| 146 |    764.687237 |     38.240166 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 147 |    135.821944 |    133.999111 | Margot Michaud                                                                                                                                                                       |
| 148 |    714.860773 |    298.370802 | T. Michael Keesey (photo by Sean Mack)                                                                                                                                               |
| 149 |    266.943030 |    258.820578 | NA                                                                                                                                                                                   |
| 150 |    186.379868 |     11.399510 | Jaime Headden                                                                                                                                                                        |
| 151 |    610.207139 |    344.950284 | Matt Crook                                                                                                                                                                           |
| 152 |    966.548494 |     92.458065 | Jessica Anne Miller                                                                                                                                                                  |
| 153 |     46.846084 |    160.521820 | Tracy A. Heath                                                                                                                                                                       |
| 154 |    717.950888 |    543.957363 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 155 |    191.449860 |     22.602456 | NA                                                                                                                                                                                   |
| 156 |    164.292356 |    647.649141 | Zimices                                                                                                                                                                              |
| 157 |    114.923164 |    199.857247 | Christoph Schomburg                                                                                                                                                                  |
| 158 |    972.926288 |    597.204135 | Zimices                                                                                                                                                                              |
| 159 |    179.606135 |    347.586093 | Matt Crook                                                                                                                                                                           |
| 160 |    839.922754 |    707.565051 | Tasman Dixon                                                                                                                                                                         |
| 161 |    660.162327 |    735.967028 | Rebecca Groom                                                                                                                                                                        |
| 162 |    164.763617 |    312.527824 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 163 |     37.336646 |    275.713396 | T. Michael Keesey (vectorization); Thorsten Assmann, Jörn Buse, Claudia Drees, Ariel-Leib-Leonid Friedman, Tal Levanony, Andrea Matern, Anika Timm, and David W. Wrase (photography) |
| 164 |    453.781459 |    678.995207 | Melissa Broussard                                                                                                                                                                    |
| 165 |    524.070058 |    367.856509 | Ferran Sayol                                                                                                                                                                         |
| 166 |    466.605958 |     74.885241 | Margot Michaud                                                                                                                                                                       |
| 167 |    639.408819 |    222.353846 | Margot Michaud                                                                                                                                                                       |
| 168 |     84.246415 |    154.302341 | Chase Brownstein                                                                                                                                                                     |
| 169 |    304.536449 |      2.880172 | Cesar Julian                                                                                                                                                                         |
| 170 |    766.354579 |    325.416124 | Christian A. Masnaghetti                                                                                                                                                             |
| 171 |    655.713096 |    394.938612 | Tasman Dixon                                                                                                                                                                         |
| 172 |    591.478205 |     23.822281 | Becky Barnes                                                                                                                                                                         |
| 173 |    809.623593 |    119.878958 | Madeleine Price Ball                                                                                                                                                                 |
| 174 |    785.232537 |    221.463039 | Iain Reid                                                                                                                                                                            |
| 175 |     89.805043 |    386.073231 | Michael Scroggie                                                                                                                                                                     |
| 176 |    128.338184 |    217.031648 | Margot Michaud                                                                                                                                                                       |
| 177 |    138.347120 |    453.171081 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 178 |    747.966536 |    622.865512 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                                         |
| 179 |    507.521717 |    554.522146 | Ferran Sayol                                                                                                                                                                         |
| 180 |    921.875284 |    374.454709 | Zimices                                                                                                                                                                              |
| 181 |    686.004478 |    678.499749 | Matt Martyniuk                                                                                                                                                                       |
| 182 |    556.013856 |    353.579172 | NA                                                                                                                                                                                   |
| 183 |    309.696384 |    583.817124 | Gareth Monger                                                                                                                                                                        |
| 184 |    989.855537 |    374.309715 | Steven Traver                                                                                                                                                                        |
| 185 |    801.076416 |      9.274138 | Yan Wong (vectorization) from 1873 illustration                                                                                                                                      |
| 186 |    746.161692 |    702.093781 | Anthony Caravaggi                                                                                                                                                                    |
| 187 |    151.927530 |     97.024490 | NA                                                                                                                                                                                   |
| 188 |     78.936970 |    105.710813 | Gareth Monger                                                                                                                                                                        |
| 189 |    791.979892 |     27.432963 | Martin R. Smith                                                                                                                                                                      |
| 190 |   1000.053897 |    509.947922 | Chris huh                                                                                                                                                                            |
| 191 |     45.663697 |    551.984043 | Acrocynus (vectorized by T. Michael Keesey)                                                                                                                                          |
| 192 |    814.560303 |    492.522573 | Gareth Monger                                                                                                                                                                        |
| 193 |    723.809793 |    196.139667 | Maija Karala                                                                                                                                                                         |
| 194 |   1017.140126 |    691.837872 | Ferran Sayol                                                                                                                                                                         |
| 195 |    875.025166 |     14.420452 | Birgit Lang                                                                                                                                                                          |
| 196 |    618.829125 |     91.894447 | Matt Crook                                                                                                                                                                           |
| 197 |    994.877584 |    393.328953 | Zimices                                                                                                                                                                              |
| 198 |    447.516569 |     84.984284 | FunkMonk                                                                                                                                                                             |
| 199 |    197.616842 |    641.611291 | John Conway                                                                                                                                                                          |
| 200 |   1016.008771 |    533.922898 | Walter Vladimir                                                                                                                                                                      |
| 201 |    132.119297 |    173.304944 | Steve Hillebrand/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                                                   |
| 202 |    402.574716 |     17.928329 | Steven Haddock • Jellywatch.org                                                                                                                                                      |
| 203 |     33.506426 |    306.349485 | Matt Crook                                                                                                                                                                           |
| 204 |    930.484576 |    366.203609 | Nobu Tamura                                                                                                                                                                          |
| 205 |    322.571501 |    540.344390 | Margot Michaud                                                                                                                                                                       |
| 206 |    834.754221 |    783.770869 | Margot Michaud                                                                                                                                                                       |
| 207 |    678.009280 |    677.749292 | Mali’o Kodis, photograph by “Wildcat Dunny” (<http://www.flickr.com/people/wildcat_dunny/>)                                                                                          |
| 208 |    289.539825 |    484.487899 | Matt Crook                                                                                                                                                                           |
| 209 |    888.326670 |    201.992158 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 210 |    365.181978 |    683.107053 | Young and Zhao (1972:figure 4), modified by Michael P. Taylor                                                                                                                        |
| 211 |     94.625778 |    514.680974 | Lauren Sumner-Rooney                                                                                                                                                                 |
| 212 |    743.207547 |    447.068922 | Gareth Monger                                                                                                                                                                        |
| 213 |    828.369082 |    688.164876 | Steven Traver                                                                                                                                                                        |
| 214 |     38.694708 |    796.379014 | Maija Karala                                                                                                                                                                         |
| 215 |    881.125987 |      8.371802 | Matt Crook                                                                                                                                                                           |
| 216 |    359.406325 |    184.161705 | Matt Crook                                                                                                                                                                           |
| 217 |    218.333168 |    134.610371 | Andrew A. Farke                                                                                                                                                                      |
| 218 |    276.972412 |    720.909039 | Kai R. Caspar                                                                                                                                                                        |
| 219 |    130.866604 |    407.985156 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 220 |    869.257199 |    477.587029 | T. Michael Keesey (photo by Darren Swim)                                                                                                                                             |
| 221 |    932.597182 |    590.356724 | Margot Michaud                                                                                                                                                                       |
| 222 |    523.993476 |    599.168214 | Michael Scroggie, from original photograph by John Bettaso, USFWS (original photograph in public domain).                                                                            |
| 223 |    398.412317 |    721.999991 | Collin Gross                                                                                                                                                                         |
| 224 |    358.781790 |    358.890486 | SecretJellyMan                                                                                                                                                                       |
| 225 |    249.075814 |    418.926543 | Margot Michaud                                                                                                                                                                       |
| 226 |    447.133145 |    362.429505 | Matt Crook                                                                                                                                                                           |
| 227 |    730.429420 |    316.883283 | NA                                                                                                                                                                                   |
| 228 |    761.119608 |    611.642514 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 229 |      9.704069 |    313.941088 | T. Michael Keesey                                                                                                                                                                    |
| 230 |    251.772747 |    733.331019 | Cristopher Silva                                                                                                                                                                     |
| 231 |    549.811284 |    730.171250 | Zimices                                                                                                                                                                              |
| 232 |   1001.507810 |    616.968210 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 233 |    495.534723 |    155.273970 | Andrew Farke and Joseph Sertich                                                                                                                                                      |
| 234 |      5.340353 |    406.901835 | Steven Traver                                                                                                                                                                        |
| 235 |    415.338991 |     63.582470 | NA                                                                                                                                                                                   |
| 236 |    560.482468 |    401.602177 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 237 |    903.099117 |     61.826664 | Matt Crook                                                                                                                                                                           |
| 238 |    268.866540 |    782.186067 | Tasman Dixon                                                                                                                                                                         |
| 239 |    484.736372 |    277.359614 | Jagged Fang Designs                                                                                                                                                                  |
| 240 |    853.803028 |     76.707543 | Gareth Monger                                                                                                                                                                        |
| 241 |    880.653259 |    244.471334 | Ferran Sayol                                                                                                                                                                         |
| 242 |    527.131851 |    615.972804 | Gareth Monger                                                                                                                                                                        |
| 243 |    356.168756 |    734.784450 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                                  |
| 244 |     51.729129 |    221.093760 | Zimices                                                                                                                                                                              |
| 245 |    291.861755 |    679.393980 | Matt Crook                                                                                                                                                                           |
| 246 |    309.535005 |    549.171163 | Bennet McComish, photo by Avenue                                                                                                                                                     |
| 247 |    474.331631 |    733.664881 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                                   |
| 248 |    705.489277 |    304.996099 | Zimices                                                                                                                                                                              |
| 249 |   1020.374896 |    165.851523 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 250 |      1.917159 |    367.676632 | Lisa M. “Pixxl” (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                      |
| 251 |    234.169130 |     21.544566 | Lukasiniho                                                                                                                                                                           |
| 252 |    808.869479 |    775.127372 | Steven Traver                                                                                                                                                                        |
| 253 |    552.405117 |    369.025241 | DW Bapst, modified from Figure 1 of Belanger (2011, PALAIOS).                                                                                                                        |
| 254 |    738.652372 |    438.367397 | NA                                                                                                                                                                                   |
| 255 |    607.828703 |     98.246137 | Steven Traver                                                                                                                                                                        |
| 256 |     11.843607 |    788.165003 | Margot Michaud                                                                                                                                                                       |
| 257 |   1007.980789 |     81.107984 | Lauren Anderson                                                                                                                                                                      |
| 258 |    957.385392 |    372.998655 | Charles R. Knight, vectorized by Zimices                                                                                                                                             |
| 259 |    581.354718 |      5.666791 | Margot Michaud                                                                                                                                                                       |
| 260 |     17.122787 |    163.351111 | Scott Hartman                                                                                                                                                                        |
| 261 |    579.957696 |    756.852513 | Andrew A. Farke, shell lines added by Yan Wong                                                                                                                                       |
| 262 |    298.833498 |    508.799687 | Chris huh                                                                                                                                                                            |
| 263 |    910.137197 |    236.878138 | T. Michael Keesey                                                                                                                                                                    |
| 264 |    270.275970 |    431.210631 | DW Bapst (modified from Bulman, 1970)                                                                                                                                                |
| 265 |    283.509319 |    697.431541 | Duane Raver (vectorized by T. Michael Keesey)                                                                                                                                        |
| 266 |    924.406356 |     14.353677 | Tasman Dixon                                                                                                                                                                         |
| 267 |    828.718546 |    164.441841 | Ferran Sayol                                                                                                                                                                         |
| 268 |    567.928369 |     33.658831 | Lukasiniho                                                                                                                                                                           |
| 269 |    759.913654 |     44.346248 | FunkMonk                                                                                                                                                                             |
| 270 |    475.702495 |    461.985550 | T. Michael Keesey                                                                                                                                                                    |
| 271 |    997.971371 |     81.127885 | Yan Wong                                                                                                                                                                             |
| 272 |    827.379775 |    705.305856 | Anthony Caravaggi                                                                                                                                                                    |
| 273 |    811.759022 |    163.685583 | Greg Schechter (original photo), Renato Santos (vector silhouette)                                                                                                                   |
| 274 |    402.006308 |    736.485834 | Matt Martyniuk (modified by T. Michael Keesey)                                                                                                                                       |
| 275 |    998.785048 |    797.681111 | Chris huh                                                                                                                                                                            |
| 276 |    341.537317 |    235.322479 | Gareth Monger                                                                                                                                                                        |
| 277 |    390.788219 |     14.687113 | Sarah Werning                                                                                                                                                                        |
| 278 |    661.677841 |    774.141135 | Xavier Giroux-Bougard                                                                                                                                                                |
| 279 |      7.691166 |    143.959084 | NA                                                                                                                                                                                   |
| 280 |    462.235013 |    750.856481 | NA                                                                                                                                                                                   |
| 281 |    712.565723 |    125.711108 | Steven Traver                                                                                                                                                                        |
| 282 |    143.480662 |     43.124132 | Scott Hartman                                                                                                                                                                        |
| 283 |     16.180320 |    702.792166 | Gareth Monger                                                                                                                                                                        |
| 284 |    291.367316 |    737.608607 | Margot Michaud                                                                                                                                                                       |
| 285 |    691.935643 |    483.823547 | Harold N Eyster                                                                                                                                                                      |
| 286 |    631.851804 |    795.223048 | Rene Martin                                                                                                                                                                          |
| 287 |    277.777928 |    678.254589 | Kent Elson Sorgon                                                                                                                                                                    |
| 288 |    823.095038 |     92.905527 | Steven Coombs                                                                                                                                                                        |
| 289 |    401.354260 |    772.911737 | Collin Gross                                                                                                                                                                         |
| 290 |    475.453783 |    326.403582 | NA                                                                                                                                                                                   |
| 291 |    680.409573 |    655.277672 | Maija Karala                                                                                                                                                                         |
| 292 |    871.540265 |    460.988230 | T. Michael Keesey                                                                                                                                                                    |
| 293 |    470.925162 |     84.742157 | SecretJellyMan                                                                                                                                                                       |
| 294 |    830.804470 |    185.609679 | Katie S. Collins                                                                                                                                                                     |
| 295 |    674.664686 |    622.605070 | Zimices                                                                                                                                                                              |
| 296 |    119.635607 |    770.348229 | T. Michael Keesey                                                                                                                                                                    |
| 297 |    679.629678 |    785.225070 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                                       |
| 298 |    989.244880 |     60.601135 | Steven Traver                                                                                                                                                                        |
| 299 |    885.738923 |    282.091989 | Katie S. Collins                                                                                                                                                                     |
| 300 |     47.271510 |    691.647800 | NA                                                                                                                                                                                   |
| 301 |    822.909862 |    112.148505 | Kailah Thorn & Mark Hutchinson                                                                                                                                                       |
| 302 |    235.085113 |    337.078774 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                                         |
| 303 |    333.381804 |    790.409437 | wsnaccad                                                                                                                                                                             |
| 304 |    902.798656 |    784.625520 | Gareth Monger                                                                                                                                                                        |
| 305 |    437.324595 |    386.748193 | Zimices                                                                                                                                                                              |
| 306 |    632.833562 |    420.795194 | Anthony Caravaggi                                                                                                                                                                    |
| 307 |    309.283314 |    591.686384 | Margot Michaud                                                                                                                                                                       |
| 308 |    173.595188 |    645.354123 | NA                                                                                                                                                                                   |
| 309 |    258.626523 |    691.909194 | NA                                                                                                                                                                                   |
| 310 |     87.998186 |    117.139217 | Steven Traver                                                                                                                                                                        |
| 311 |    736.461542 |    551.554811 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                                     |
| 312 |    198.123180 |     63.513155 | T. Michael Keesey                                                                                                                                                                    |
| 313 |    358.347981 |    536.991481 | Maxime Dahirel                                                                                                                                                                       |
| 314 |     87.126659 |    390.688569 | Harold N Eyster                                                                                                                                                                      |
| 315 |    793.973060 |    544.168736 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                                |
| 316 |    731.790771 |    192.797984 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 317 |    687.617591 |    383.717021 | G. M. Woodward                                                                                                                                                                       |
| 318 |    685.501649 |    484.010989 | T. Michael Keesey                                                                                                                                                                    |
| 319 |    866.924907 |    545.364636 | Rebecca Groom (Based on Photo by Andreas Trepte)                                                                                                                                     |
| 320 |    165.622969 |    623.773613 | Tauana J. Cunha                                                                                                                                                                      |
| 321 |    645.792645 |    414.702787 | Ferran Sayol                                                                                                                                                                         |
| 322 |    462.466682 |    229.191520 | Gabriel Lio, vectorized by Zimices                                                                                                                                                   |
| 323 |    596.572070 |    371.900597 | T. Michael Keesey                                                                                                                                                                    |
| 324 |     57.476630 |    215.338871 | Thea Boodhoo (photograph) and T. Michael Keesey (vectorization)                                                                                                                      |
| 325 |    508.294580 |    766.716586 | T. Michael Keesey                                                                                                                                                                    |
| 326 |    914.991833 |    231.609433 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 327 |    934.176532 |    178.953067 | NA                                                                                                                                                                                   |
| 328 |    679.820484 |    189.172882 | Matt Crook                                                                                                                                                                           |
| 329 |     93.574439 |    533.804542 | Alexis Simon                                                                                                                                                                         |
| 330 |    527.248561 |    184.774553 | Chris huh                                                                                                                                                                            |
| 331 |    615.314189 |    157.358642 | NA                                                                                                                                                                                   |
| 332 |    698.538393 |    477.299571 | Chris huh                                                                                                                                                                            |
| 333 |    583.514977 |    620.121136 | Ferran Sayol                                                                                                                                                                         |
| 334 |    855.202744 |    510.309444 | Chris huh                                                                                                                                                                            |
| 335 |    863.290263 |    281.286406 | Mario Quevedo                                                                                                                                                                        |
| 336 |    670.100994 |    144.986659 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                                    |
| 337 |    675.161083 |    141.425205 | Gareth Monger                                                                                                                                                                        |
| 338 |    300.220726 |    653.981775 | Jose Carlos Arenas-Monroy                                                                                                                                                            |
| 339 |    822.858965 |    603.163265 | Chris huh                                                                                                                                                                            |
| 340 |    682.738302 |    149.566675 | NA                                                                                                                                                                                   |
| 341 |    914.656363 |    741.531691 | Jaime Headden                                                                                                                                                                        |
| 342 |    863.134167 |    675.711922 | Matt Crook                                                                                                                                                                           |
| 343 |    442.284997 |    306.194320 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 344 |    394.370585 |    780.641923 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 345 |    725.183822 |    452.384748 | Zimices                                                                                                                                                                              |
| 346 |    414.304491 |    121.666703 | Jonathan Wells                                                                                                                                                                       |
| 347 |    847.253550 |    534.309332 | Jerry Oldenettel (vectorized by T. Michael Keesey)                                                                                                                                   |
| 348 |    840.577117 |     97.513904 | Ryan Cupo                                                                                                                                                                            |
| 349 |    240.246442 |    438.559039 | Steven Coombs                                                                                                                                                                        |
| 350 |     51.833516 |    337.724910 | Zimices                                                                                                                                                                              |
| 351 |    746.427590 |    134.162439 | Noah Schlottman                                                                                                                                                                      |
| 352 |    627.880334 |     83.479780 | Tracy A. Heath                                                                                                                                                                       |
| 353 |    208.662745 |    106.826827 | Matt Crook                                                                                                                                                                           |
| 354 |    544.208344 |    391.302113 | SecretJellyMan                                                                                                                                                                       |
| 355 |    209.088572 |    225.368530 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 356 |    814.945396 |    521.502671 | Ferran Sayol                                                                                                                                                                         |
| 357 |    928.054368 |    254.080155 | T. Michael Keesey                                                                                                                                                                    |
| 358 |    665.563172 |    789.269115 | Mali’o Kodis, photograph by “Wildcat Dunny” (<http://www.flickr.com/people/wildcat_dunny/>)                                                                                          |
| 359 |    512.767375 |     93.976438 | Neil Kelley                                                                                                                                                                          |
| 360 |    409.759148 |    790.927687 | Gareth Monger                                                                                                                                                                        |
| 361 |    298.964150 |    520.311958 | Birgit Lang                                                                                                                                                                          |
| 362 |      6.068881 |    208.876161 | Jack Mayer Wood                                                                                                                                                                      |
| 363 |     48.525440 |    675.134432 | T. Michael Keesey (after Kukalová)                                                                                                                                                   |
| 364 |    874.536986 |    591.336062 | NA                                                                                                                                                                                   |
| 365 |    525.793231 |     33.417649 | Zimices                                                                                                                                                                              |
| 366 |    939.071005 |    781.940442 | Margot Michaud                                                                                                                                                                       |
| 367 |    268.240641 |    652.521387 | Lukasiniho                                                                                                                                                                           |
| 368 |    333.458724 |    601.313629 | Michele M Tobias                                                                                                                                                                     |
| 369 |     90.359461 |    223.633955 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                                         |
| 370 |    137.884733 |     13.551374 | T. Michael Keesey                                                                                                                                                                    |
| 371 |    167.901319 |    487.633680 | Birgit Lang                                                                                                                                                                          |
| 372 |    981.022982 |    774.043229 | Bill Bouton (source photo) & T. Michael Keesey (vectorization)                                                                                                                       |
| 373 |    904.419936 |     27.880645 | Chris huh                                                                                                                                                                            |
| 374 |    213.066808 |    197.693785 | Margot Michaud                                                                                                                                                                       |
| 375 |    696.647108 |    779.203182 | Gareth Monger                                                                                                                                                                        |
| 376 |    217.917004 |    251.645883 | Scott Hartman                                                                                                                                                                        |
| 377 |    365.931143 |    728.141932 | L. Shyamal                                                                                                                                                                           |
| 378 |     30.408815 |    354.220096 | Andreas Hejnol                                                                                                                                                                       |
| 379 |    353.742592 |    713.244432 | T. Michael Keesey                                                                                                                                                                    |
| 380 |    965.575582 |    213.701247 | Kamil S. Jaron                                                                                                                                                                       |
| 381 |    744.190025 |    320.459820 | Nicolas Huet le Jeune and Jean-Gabriel Prêtre (vectorized by T. Michael Keesey)                                                                                                      |
| 382 |    862.764418 |    224.641229 | T. Michael Keesey                                                                                                                                                                    |
| 383 |      6.753374 |    782.274135 | Rebecca Groom                                                                                                                                                                        |
| 384 |    102.074955 |    228.772273 | Zimices                                                                                                                                                                              |
| 385 |    770.157983 |    707.362322 | Noah Schlottman, photo by Martin V. Sørensen                                                                                                                                         |
| 386 |    110.575137 |     18.828628 | Ville Koistinen and T. Michael Keesey                                                                                                                                                |
| 387 |    162.764520 |    395.433667 | Margot Michaud                                                                                                                                                                       |
| 388 |    212.750564 |    717.905489 | Matt Crook                                                                                                                                                                           |
| 389 |   1008.818119 |    596.098129 | NA                                                                                                                                                                                   |
| 390 |     30.609366 |     12.624662 | Manabu Bessho-Uehara                                                                                                                                                                 |
| 391 |   1016.943807 |    595.274780 | NA                                                                                                                                                                                   |
| 392 |    750.684745 |    684.671839 | Martin Kevil                                                                                                                                                                         |
| 393 |     10.051505 |    584.256499 | Margot Michaud                                                                                                                                                                       |
| 394 |    855.115423 |    407.855209 | Christoph Schomburg                                                                                                                                                                  |
| 395 |    973.040717 |     17.827669 | Daniel Stadtmauer                                                                                                                                                                    |
| 396 |    107.419604 |    409.335906 | Beth Reinke                                                                                                                                                                          |
| 397 |    947.269084 |    673.760254 | T. Michael Keesey                                                                                                                                                                    |
| 398 |    237.574510 |    640.151969 | NA                                                                                                                                                                                   |
| 399 |    243.326441 |    120.910809 | Steven Traver                                                                                                                                                                        |
| 400 |    285.578087 |    711.332599 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 401 |    941.823585 |    160.659556 | Dr. Thomas G. Barnes, USFWS                                                                                                                                                          |
| 402 |    612.544326 |    376.423095 | Cesar Julian                                                                                                                                                                         |
| 403 |    217.350574 |    735.697948 | Matt Crook                                                                                                                                                                           |
| 404 |    810.018654 |    593.047847 | NA                                                                                                                                                                                   |
| 405 |    541.409834 |    169.872846 | Benchill                                                                                                                                                                             |
| 406 |    725.316220 |    498.759827 | Tasman Dixon                                                                                                                                                                         |
| 407 |    568.533515 |    442.308646 | Scott Hartman                                                                                                                                                                        |
| 408 |    385.578506 |    437.116592 | Kanako Bessho-Uehara                                                                                                                                                                 |
| 409 |    359.402596 |    696.013448 | Dr. Thomas G. Barnes, USFWS                                                                                                                                                          |
| 410 |    514.093729 |    149.952237 | Chris huh                                                                                                                                                                            |
| 411 |    365.822436 |     13.742790 | Matt Crook                                                                                                                                                                           |
| 412 |   1011.512529 |    758.253939 | Gopal Murali                                                                                                                                                                         |
| 413 |    923.380714 |    787.616952 | Zimices                                                                                                                                                                              |
| 414 |    382.668450 |    737.415789 | Steven Traver                                                                                                                                                                        |
| 415 |    351.522672 |    761.439281 | Rebecca Groom                                                                                                                                                                        |
| 416 |    873.773389 |    304.999505 | Caleb M. Brown                                                                                                                                                                       |
| 417 |   1005.787100 |     62.715222 | Rainer Schoch                                                                                                                                                                        |
| 418 |    129.394359 |    161.863551 | Duane Raver (vectorized by T. Michael Keesey)                                                                                                                                        |
| 419 |    469.643843 |    634.445440 | Margot Michaud                                                                                                                                                                       |
| 420 |    200.211235 |    668.232834 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 421 |    626.764551 |    769.753976 | Fritz Geller-Grimm (vectorized by T. Michael Keesey)                                                                                                                                 |
| 422 |    873.272263 |     63.172658 | Margot Michaud                                                                                                                                                                       |
| 423 |   1012.907582 |    369.013657 | Matt Crook                                                                                                                                                                           |
| 424 |    275.838859 |    152.735016 | Sherman F. Denton via rawpixel.com (illustration) and Timothy J. Bartley (silhouette)                                                                                                |
| 425 |    650.496250 |    102.602290 | (after Spotila 2004)                                                                                                                                                                 |
| 426 |    457.544550 |    693.726937 | Cristopher Silva                                                                                                                                                                     |
| 427 |    463.841799 |    642.405098 | Margot Michaud                                                                                                                                                                       |
| 428 |    480.049461 |    413.174927 | Scott Hartman                                                                                                                                                                        |
| 429 |    206.905364 |    654.638324 | Alex Slavenko                                                                                                                                                                        |
| 430 |    888.530514 |    192.250506 | \[unknown\]                                                                                                                                                                          |
| 431 |    525.084161 |    140.006744 | Andrés Sánchez                                                                                                                                                                       |
| 432 |    903.727570 |    729.376962 | T. Michael Keesey                                                                                                                                                                    |
| 433 |    832.157330 |    615.096618 | Gopal Murali                                                                                                                                                                         |
| 434 |    449.710946 |    237.252032 | Zimices                                                                                                                                                                              |
| 435 |   1004.001035 |     36.915352 | Francisco Gascó (modified by Michael P. Taylor)                                                                                                                                      |
| 436 |    955.587564 |    690.112279 | Fir0002/Flagstaffotos (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                |
| 437 |    739.324898 |    304.979446 | Amanda Katzer                                                                                                                                                                        |
| 438 |     57.989798 |    250.190091 | T. Michael Keesey                                                                                                                                                                    |
| 439 |    391.291720 |    126.146376 | Scott Hartman                                                                                                                                                                        |
| 440 |    116.588686 |    187.682000 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 441 |    158.302204 |    566.882136 | Eduard Solà Vázquez, vectorised by Yan Wong                                                                                                                                          |
| 442 |    373.452906 |    705.597408 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 443 |    824.678856 |    678.144579 | Scott Hartman                                                                                                                                                                        |
| 444 |    981.073179 |    757.819786 | Matt Crook                                                                                                                                                                           |
| 445 |    594.593757 |    654.853410 | T. Michael Keesey                                                                                                                                                                    |
| 446 |    380.608086 |    666.231776 | Chris huh                                                                                                                                                                            |
| 447 |    732.818699 |    104.239335 | Tauana J. Cunha                                                                                                                                                                      |
| 448 |     97.634748 |    305.502726 | Noah Schlottman                                                                                                                                                                      |
| 449 |    206.561064 |    556.194039 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 450 |    616.370071 |    309.065005 | Iain Reid                                                                                                                                                                            |
| 451 |    423.154693 |    370.411589 | Anthony Caravaggi                                                                                                                                                                    |
| 452 |   1014.991789 |    377.585335 | Melissa Broussard                                                                                                                                                                    |
| 453 |    247.989425 |    467.983313 | B. Duygu Özpolat                                                                                                                                                                     |
| 454 |    541.290803 |    353.763059 | Kamil S. Jaron                                                                                                                                                                       |
| 455 |     52.620141 |    403.474495 | Gareth Monger                                                                                                                                                                        |
| 456 |    430.665502 |    665.098010 | Margot Michaud                                                                                                                                                                       |
| 457 |     82.213612 |    706.932320 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 458 |    624.217406 |    776.992852 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 459 |    341.339424 |    196.340106 | Beth Reinke                                                                                                                                                                          |
| 460 |    645.111174 |    115.263964 | Martin Kevil                                                                                                                                                                         |
| 461 |    993.522881 |    584.922075 | Zimices                                                                                                                                                                              |
| 462 |    991.003496 |    768.782819 | NA                                                                                                                                                                                   |
| 463 |    863.886662 |    211.883842 | Gareth Monger                                                                                                                                                                        |
| 464 |    442.221694 |    378.549067 | Zimices                                                                                                                                                                              |
| 465 |     19.551913 |    212.075766 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 466 |    255.831311 |    743.361345 | Zimices                                                                                                                                                                              |
| 467 |    429.748106 |    778.394056 | Maija Karala                                                                                                                                                                         |
| 468 |    114.826731 |    567.790319 | Michelle Site                                                                                                                                                                        |
| 469 |    854.561878 |    745.366389 | NA                                                                                                                                                                                   |
| 470 |    218.383696 |    335.639289 | Margot Michaud                                                                                                                                                                       |
| 471 |    383.386191 |    376.789619 | Tasman Dixon                                                                                                                                                                         |
| 472 |    682.970308 |    633.587830 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                                      |
| 473 |    857.772495 |    561.948662 | Jagged Fang Designs                                                                                                                                                                  |
| 474 |    384.900548 |    714.123031 | Tauana J. Cunha                                                                                                                                                                      |
| 475 |    840.430562 |    389.741617 | Tasman Dixon                                                                                                                                                                         |
| 476 |    674.686845 |    254.692899 | Almandine (vectorized by T. Michael Keesey)                                                                                                                                          |
| 477 |    277.543996 |    795.541187 | Jaime Chirinos (vectorized by T. Michael Keesey)                                                                                                                                     |
| 478 |     79.343632 |    686.285541 | Chris huh                                                                                                                                                                            |
| 479 |     42.950038 |     97.990346 | Margot Michaud                                                                                                                                                                       |
| 480 |    361.317581 |    171.489319 | Gareth Monger                                                                                                                                                                        |
| 481 |     10.693029 |    220.620070 | Trond R. Oskars                                                                                                                                                                      |
| 482 |     21.343878 |    465.523731 | DW Bapst (Modified from photograph taken by Charles Mitchell)                                                                                                                        |
| 483 |    944.953910 |    423.514096 | Scott Hartman                                                                                                                                                                        |
| 484 |     72.340080 |     13.749947 | Mercedes Yrayzoz (vectorized by T. Michael Keesey)                                                                                                                                   |
| 485 |    189.519309 |    344.839629 | Matt Crook                                                                                                                                                                           |
| 486 |   1016.375950 |    772.922519 | Scott Hartman                                                                                                                                                                        |
| 487 |   1009.686015 |     49.381270 | Noah Schlottman                                                                                                                                                                      |
| 488 |   1003.460955 |    379.201489 | Noah Schlottman                                                                                                                                                                      |
| 489 |     88.517485 |    576.500186 | Ferran Sayol                                                                                                                                                                         |
| 490 |    499.212195 |    579.935548 | Chris Jennings (Risiatto)                                                                                                                                                            |
| 491 |     56.910319 |     48.081982 | NA                                                                                                                                                                                   |
| 492 |    146.420019 |    558.797664 | Zimices                                                                                                                                                                              |
| 493 |    721.470455 |    459.718126 | Espen Horn (model; vectorized by T. Michael Keesey from a photo by H. Zell)                                                                                                          |
| 494 |    263.424409 |    493.640130 | Tauana J. Cunha                                                                                                                                                                      |
| 495 |    868.211553 |     50.130576 | Jaime Headden                                                                                                                                                                        |
| 496 |    858.418494 |    492.960937 | Tasman Dixon                                                                                                                                                                         |
| 497 |    930.760690 |    417.970865 | Chris huh                                                                                                                                                                            |
| 498 |    149.234219 |    466.402622 | NA                                                                                                                                                                                   |
| 499 |     62.473683 |    357.020016 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 500 |    798.774868 |    626.994328 | Benchill                                                                                                                                                                             |
| 501 |    654.537948 |    764.367440 | Zimices                                                                                                                                                                              |
| 502 |    284.906502 |    668.587188 | Chris huh                                                                                                                                                                            |
| 503 |    411.335942 |    755.771552 | Vijay Cavale (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                         |
| 504 |    857.876913 |    530.504570 | Jagged Fang Designs                                                                                                                                                                  |
| 505 |    767.151800 |    534.715061 | M Kolmann                                                                                                                                                                            |
| 506 |    732.037106 |    372.017776 | Tauana J. Cunha                                                                                                                                                                      |
| 507 |     44.074944 |    776.831749 | Matus Valach                                                                                                                                                                         |
| 508 |    447.188530 |    543.808857 | Tasman Dixon                                                                                                                                                                         |
| 509 |    796.883686 |    409.512253 | Dmitry Bogdanov and FunkMonk (vectorized by T. Michael Keesey)                                                                                                                       |
| 510 |    173.624796 |    320.409155 | Margot Michaud                                                                                                                                                                       |
| 511 |    195.394331 |     48.897398 | Jagged Fang Designs                                                                                                                                                                  |
| 512 |    510.897459 |     56.555973 | Milton Tan                                                                                                                                                                           |
| 513 |    569.831260 |    643.538332 | George Edward Lodge (vectorized by T. Michael Keesey)                                                                                                                                |
| 514 |    219.778694 |    449.557070 | Steven Traver                                                                                                                                                                        |
| 515 |    189.875204 |    199.733525 | Sergio A. Muñoz-Gómez                                                                                                                                                                |
| 516 |    113.896174 |    557.951230 | Steven Traver                                                                                                                                                                        |
| 517 |   1003.654385 |    740.289333 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                                      |
| 518 |     40.157972 |    595.690636 | Dean Schnabel                                                                                                                                                                        |
| 519 |    608.700350 |    669.693159 | Matt Crook                                                                                                                                                                           |
| 520 |    612.574706 |    330.883744 | NA                                                                                                                                                                                   |
| 521 |    285.677011 |    179.606996 | Zimices                                                                                                                                                                              |
| 522 |     61.963580 |    173.942085 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 523 |    365.204359 |    754.536254 | Chris huh                                                                                                                                                                            |
| 524 |    533.371151 |    458.506431 | Tracy A. Heath                                                                                                                                                                       |
| 525 |    700.517355 |    634.122824 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 526 |    872.746365 |    370.205820 | Matt Crook                                                                                                                                                                           |
| 527 |    447.172514 |    205.654857 | NA                                                                                                                                                                                   |
| 528 |    909.078992 |    669.000168 | Zimices                                                                                                                                                                              |
| 529 |    768.241420 |    188.796608 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                                        |
| 530 |    182.233754 |    143.110761 | Steven Coombs                                                                                                                                                                        |
| 531 |    603.792480 |    318.035609 | Adam Stuart Smith (vectorized by T. Michael Keesey)                                                                                                                                  |
| 532 |    330.169519 |    580.261033 | NA                                                                                                                                                                                   |
| 533 |    838.240126 |     63.949261 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 534 |    954.687544 |      9.589098 | Ferran Sayol                                                                                                                                                                         |
| 535 |    581.659203 |    182.793817 | T. Michael Keesey                                                                                                                                                                    |
| 536 |    299.316108 |    772.086583 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                                 |
| 537 |    415.974734 |     30.479090 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 538 |    166.768540 |    466.458533 | Saguaro Pictures (source photo) and T. Michael Keesey                                                                                                                                |
| 539 |     65.186134 |    231.622313 | Smokeybjb                                                                                                                                                                            |
| 540 |    181.879628 |    402.794781 | Beth Reinke                                                                                                                                                                          |
| 541 |    246.323889 |    144.348240 | DFoidl (vectorized by T. Michael Keesey)                                                                                                                                             |
| 542 |    745.596475 |    406.538879 | Shyamal                                                                                                                                                                              |
| 543 |   1007.105250 |    656.222220 | Philip Chalmers (vectorized by T. Michael Keesey)                                                                                                                                    |
| 544 |      8.045028 |    654.714020 | Richard Lampitt, Jeremy Young / NHM (vectorization by Yan Wong)                                                                                                                      |
| 545 |    185.621105 |    309.161409 | Matt Crook                                                                                                                                                                           |
| 546 |    489.383072 |    550.674161 | NA                                                                                                                                                                                   |
| 547 |    348.394535 |     13.265041 | Matt Crook                                                                                                                                                                           |
| 548 |    851.808865 |    474.890377 | NA                                                                                                                                                                                   |
| 549 |    682.934984 |    407.934998 | Yusan Yang                                                                                                                                                                           |
| 550 |    509.237099 |    196.667488 | M Hutchinson                                                                                                                                                                         |
| 551 |    475.567925 |     67.736473 | Tess Linden                                                                                                                                                                          |
| 552 |    454.113788 |    394.503391 | Kanako Bessho-Uehara                                                                                                                                                                 |
| 553 |    844.205956 |    204.191612 | Zimices                                                                                                                                                                              |
| 554 |    211.326292 |    332.133699 | Margot Michaud                                                                                                                                                                       |
| 555 |    522.071391 |    749.987394 | NA                                                                                                                                                                                   |
| 556 |    196.299100 |    273.883255 | Matt Crook                                                                                                                                                                           |
| 557 |    661.708102 |    794.209391 | T. Michael Keesey                                                                                                                                                                    |
| 558 |    286.192789 |    472.204416 | Margot Michaud                                                                                                                                                                       |
| 559 |     68.929850 |    758.054914 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 560 |    173.202898 |    354.167329 | Steven Traver                                                                                                                                                                        |
| 561 |    107.740173 |     11.292209 | Sergio A. Muñoz-Gómez                                                                                                                                                                |
| 562 |    619.745740 |    353.065366 | Duane Raver (vectorized by T. Michael Keesey)                                                                                                                                        |
| 563 |    425.567721 |    344.222544 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 564 |    819.137829 |     80.079627 | Iain Reid                                                                                                                                                                            |
| 565 |    768.509951 |    434.288626 | NA                                                                                                                                                                                   |
| 566 |    874.841881 |    614.043526 | V. Deepak                                                                                                                                                                            |
| 567 |    243.735533 |    484.154859 | Anthony Caravaggi                                                                                                                                                                    |
| 568 |     95.410616 |     93.774780 | Chase Brownstein                                                                                                                                                                     |
| 569 |     28.994919 |    676.848396 | Matt Crook                                                                                                                                                                           |
| 570 |    158.434014 |    614.222895 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                                 |
| 571 |    275.050857 |    295.624973 | Margot Michaud                                                                                                                                                                       |
| 572 |    602.719483 |    363.966434 | Zimices                                                                                                                                                                              |
| 573 |    877.316656 |    503.733788 | Xavier Giroux-Bougard                                                                                                                                                                |
| 574 |    995.220762 |    352.209304 | Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus                                                             |
| 575 |    710.294965 |    686.417216 | Sarah Werning                                                                                                                                                                        |
| 576 |    256.429249 |    354.204373 | Doug Backlund (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                        |
| 577 |    324.590233 |    737.529114 | Ferran Sayol                                                                                                                                                                         |
| 578 |     76.191684 |    547.970851 | Jagged Fang Designs                                                                                                                                                                  |
| 579 |    269.189216 |    786.700573 | Tasman Dixon                                                                                                                                                                         |
| 580 |    312.945924 |    282.674919 | Michael Scroggie                                                                                                                                                                     |
| 581 |    381.909657 |    756.185330 | T. Michael Keesey                                                                                                                                                                    |
| 582 |    973.501860 |    445.887809 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 583 |    171.579788 |    377.964170 | Nobu Tamura                                                                                                                                                                          |
| 584 |    762.737671 |    402.347346 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                                       |
| 585 |    119.093921 |    408.927597 | Zimices                                                                                                                                                                              |
| 586 |    250.698909 |    238.210686 | Scott Hartman                                                                                                                                                                        |
| 587 |     47.521812 |    716.608261 | Katie S. Collins                                                                                                                                                                     |
| 588 |    119.994419 |    485.163837 | Andrew A. Farke                                                                                                                                                                      |
| 589 |    733.183492 |     12.091032 | Mo Hassan                                                                                                                                                                            |
| 590 |    224.287828 |      3.747437 | Alexandre Vong                                                                                                                                                                       |
| 591 |    949.326764 |    542.627493 | T. Michael Keesey                                                                                                                                                                    |
| 592 |    189.940284 |    128.957360 | Margot Michaud                                                                                                                                                                       |
| 593 |    793.846529 |    532.314143 | Zimices                                                                                                                                                                              |
| 594 |    155.535274 |    334.374924 | Jaime Headden                                                                                                                                                                        |
| 595 |    946.880070 |    204.316995 | NASA                                                                                                                                                                                 |
| 596 |    548.514638 |    235.682630 | Zimices                                                                                                                                                                              |
| 597 |    231.237298 |    126.963619 | Chris huh                                                                                                                                                                            |
| 598 |    314.229108 |    483.435242 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 599 |    841.751102 |    464.313815 | Julio Garza                                                                                                                                                                          |
| 600 |    780.625584 |    330.087823 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 601 |    407.736219 |    731.242244 | Gareth Monger                                                                                                                                                                        |
| 602 |    252.580969 |    703.130303 | Emily Jane McTavish                                                                                                                                                                  |
| 603 |    526.662993 |    349.218438 | Amanda Katzer                                                                                                                                                                        |
| 604 |   1005.313597 |    670.012102 | Matt Crook                                                                                                                                                                           |
| 605 |    337.746110 |      9.899951 | Michael Scroggie                                                                                                                                                                     |
| 606 |    947.053842 |    637.189745 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                                               |
| 607 |    789.065074 |    419.064268 | Cristina Guijarro                                                                                                                                                                    |
| 608 |    750.716824 |    118.554423 | Matt Crook                                                                                                                                                                           |
| 609 |    490.312552 |    773.487692 | Gopal Murali                                                                                                                                                                         |
| 610 |    489.292518 |    423.869876 | \<U+0412\>\<U+0430\>\<U+043B\>\<U+044C\>\<U+0434\>\<U+0438\>\<U+043C\>\<U+0430\>\<U+0440\> (vectorized by T. Michael Keesey)                                                         |
| 611 |    120.889104 |    796.442196 | T. Michael Keesey                                                                                                                                                                    |
| 612 |   1014.502675 |    314.502260 | NA                                                                                                                                                                                   |
| 613 |    640.211805 |    348.434756 | Felix Vaux                                                                                                                                                                           |
| 614 |    483.890571 |     83.139165 | Gareth Monger                                                                                                                                                                        |
| 615 |    339.687609 |    735.916500 | Jagged Fang Designs                                                                                                                                                                  |
| 616 |     77.764218 |     37.862151 | Mercedes Yrayzoz (vectorized by T. Michael Keesey)                                                                                                                                   |
| 617 |    783.301165 |    598.045836 | Chris huh                                                                                                                                                                            |
| 618 |    849.017210 |    616.536154 | Tasman Dixon                                                                                                                                                                         |
| 619 |    877.768878 |    208.765661 | Konsta Happonen, from a CC-BY-NC image by pelhonen on iNaturalist                                                                                                                    |
| 620 |    696.322697 |    760.641424 | James R. Spotila and Ray Chatterji                                                                                                                                                   |
| 621 |    733.222596 |    394.294266 | Jagged Fang Designs                                                                                                                                                                  |
| 622 |    945.712633 |    434.973106 | NA                                                                                                                                                                                   |
| 623 |    899.840276 |    346.767099 | Michael Scroggie                                                                                                                                                                     |
| 624 |    218.680642 |    118.487071 | T. Michael Keesey                                                                                                                                                                    |
| 625 |    670.402522 |    642.204781 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 626 |    557.035744 |    253.765700 | Joanna Wolfe                                                                                                                                                                         |
| 627 |    571.345831 |     17.721982 | Zachary Quigley                                                                                                                                                                      |
| 628 |    270.304875 |     14.605988 | Steven Coombs                                                                                                                                                                        |
| 629 |    754.125569 |    606.081620 | Mathew Wedel                                                                                                                                                                         |
| 630 |    737.171250 |    422.630048 | Tauana J. Cunha                                                                                                                                                                      |
| 631 |    216.919523 |     89.266545 | Ferran Sayol                                                                                                                                                                         |
| 632 |    831.652365 |    625.343051 | Jagged Fang Designs                                                                                                                                                                  |
| 633 |    672.927837 |    222.850379 | Gareth Monger                                                                                                                                                                        |
| 634 |    783.691085 |    771.431837 | Steven Traver                                                                                                                                                                        |
| 635 |    243.056711 |    665.121693 | Steven Traver                                                                                                                                                                        |
| 636 |    104.587575 |    756.159211 | Margot Michaud                                                                                                                                                                       |
| 637 |     42.293078 |    576.866675 | Michael Wolf (photo), Hans Hillewaert (editing), T. Michael Keesey (vectorization)                                                                                                   |
| 638 |    745.565942 |    524.938977 | Margot Michaud                                                                                                                                                                       |
| 639 |   1018.708837 |     27.259102 | Tracy A. Heath                                                                                                                                                                       |
| 640 |    340.713695 |    436.417751 | Prathyush Thomas                                                                                                                                                                     |
| 641 |    899.753976 |    318.563218 | T. Michael Keesey (after A. Y. Ivantsov)                                                                                                                                             |
| 642 |    561.267881 |    761.783630 | Zimices                                                                                                                                                                              |
| 643 |    407.310466 |    375.023674 | Smokeybjb                                                                                                                                                                            |
| 644 |    170.176262 |    717.418100 | Harold N Eyster                                                                                                                                                                      |
| 645 |    728.164396 |    795.500544 | Christoph Schomburg                                                                                                                                                                  |
| 646 |    404.053159 |    659.839063 | Smokeybjb, vectorized by Zimices                                                                                                                                                     |
| 647 |    420.316674 |    641.514734 | Maxime Dahirel (digitisation), Kees van Achterberg et al (doi: 10.3897/BDJ.8.e49017)(original publication)                                                                           |
| 648 |    123.600485 |    751.831674 | T. Michael Keesey                                                                                                                                                                    |
| 649 |    169.580996 |    130.901930 | NA                                                                                                                                                                                   |
| 650 |    666.165765 |    464.192508 | Chris huh                                                                                                                                                                            |
| 651 |    528.976847 |    741.203129 | Margot Michaud                                                                                                                                                                       |
| 652 |    675.650928 |    109.872797 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 653 |    283.682813 |    686.398589 | E. R. Waite & H. M. Hale (vectorized by T. Michael Keesey)                                                                                                                           |
| 654 |     41.459927 |    257.461221 | Mali’o Kodis, photograph from Jersabek et al, 2003                                                                                                                                   |
| 655 |     39.911340 |    745.313135 | Zimices                                                                                                                                                                              |
| 656 |    210.009887 |     78.558207 | Margot Michaud                                                                                                                                                                       |
| 657 |    314.642096 |    513.546310 | Zimices                                                                                                                                                                              |
| 658 |    684.340627 |    607.449221 | Mali’o Kodis, image from the Smithsonian Institution                                                                                                                                 |
| 659 |    593.674627 |     84.664773 | Henry Lydecker                                                                                                                                                                       |
| 660 |    689.771916 |    194.932494 | Inessa Voet                                                                                                                                                                          |
| 661 |     23.810437 |    571.715992 | T. Michael Keesey                                                                                                                                                                    |
| 662 |    225.597897 |    633.371802 | Anthony Caravaggi                                                                                                                                                                    |
| 663 |    280.679817 |     14.293155 | Dmitry Bogdanov and FunkMonk (vectorized by T. Michael Keesey)                                                                                                                       |
| 664 |    365.241205 |    464.396041 | Beth Reinke                                                                                                                                                                          |
| 665 |    850.478349 |    379.118259 | Michael Scroggie                                                                                                                                                                     |
| 666 |     37.214667 |    720.881129 | Chris huh                                                                                                                                                                            |
| 667 |    402.396991 |    464.972460 | Mathieu Basille                                                                                                                                                                      |
| 668 |    498.679443 |    171.521606 | Yan Wong from drawing in The Century Dictionary (1911)                                                                                                                               |
| 669 |    460.285426 |    430.640248 | Matt Crook                                                                                                                                                                           |
| 670 |    406.120108 |    229.210178 | Felix Vaux                                                                                                                                                                           |
| 671 |     55.365403 |    257.661632 | Christoph Schomburg                                                                                                                                                                  |
| 672 |     91.659671 |    753.046535 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                                               |
| 673 |    904.514174 |    794.912341 | FunkMonk                                                                                                                                                                             |
| 674 |     11.355171 |    770.956436 | Matt Crook                                                                                                                                                                           |
| 675 |    105.055180 |    545.365314 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 676 |    413.468930 |     71.833529 | Mariana Ruiz (vectorized by T. Michael Keesey)                                                                                                                                       |
| 677 |    705.548074 |    758.047834 | Zimices                                                                                                                                                                              |
| 678 |    698.830322 |    108.777261 | Zimices                                                                                                                                                                              |
| 679 |    366.850339 |     33.076711 | T. Michael Keesey                                                                                                                                                                    |
| 680 |    992.808617 |    551.598647 | Joanna Wolfe                                                                                                                                                                         |
| 681 |    884.994129 |    719.287072 | Steven Traver                                                                                                                                                                        |
| 682 |    118.322217 |    183.848373 | Cristopher Silva                                                                                                                                                                     |
| 683 |    534.532213 |    294.695252 | Xavier Giroux-Bougard                                                                                                                                                                |
| 684 |    355.627193 |    151.793434 | Xavier Giroux-Bougard                                                                                                                                                                |
| 685 |    438.526877 |    124.627140 | Beth Reinke                                                                                                                                                                          |
| 686 |    854.353713 |    239.706466 | Melissa Broussard                                                                                                                                                                    |
| 687 |    813.273474 |     69.346762 | Ingo Braasch                                                                                                                                                                         |
| 688 |    682.075163 |    102.523809 | Scott Hartman                                                                                                                                                                        |
| 689 |    228.922666 |    704.361641 | Birgit Lang                                                                                                                                                                          |
| 690 |    189.674274 |    262.394882 | Emily Willoughby                                                                                                                                                                     |
| 691 |    343.107428 |    711.270635 | Jaime Headden                                                                                                                                                                        |
| 692 |    791.933719 |    204.298531 | Michele M Tobias                                                                                                                                                                     |
| 693 |    963.142343 |    628.978238 | T. Michael Keesey                                                                                                                                                                    |
| 694 |    360.513913 |    227.462684 | Collin Gross                                                                                                                                                                         |
| 695 |    220.980717 |    384.380085 | Zimices                                                                                                                                                                              |
| 696 |    398.156332 |    235.138476 | Gareth Monger                                                                                                                                                                        |
| 697 |    391.288455 |    195.891016 | Yan Wong                                                                                                                                                                             |
| 698 |    835.639173 |    532.277339 | Steven Traver                                                                                                                                                                        |
| 699 |    528.074990 |    305.462162 | Andrew A. Farke                                                                                                                                                                      |
| 700 |    464.129369 |     99.890507 | Zimices                                                                                                                                                                              |
| 701 |    422.419375 |    699.936577 | Armin Reindl                                                                                                                                                                         |
| 702 |    859.057162 |     57.989354 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                                   |
| 703 |    197.822980 |     16.977208 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 704 |    447.446253 |    551.514924 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 705 |    399.904464 |     37.850972 | Melissa Broussard                                                                                                                                                                    |
| 706 |    241.784076 |     81.620494 | Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey)                                                                                                                     |
| 707 |    652.770020 |     96.860205 | T. Michael Keesey                                                                                                                                                                    |
| 708 |    553.292455 |    171.795193 | Matt Crook                                                                                                                                                                           |
| 709 |     67.495242 |    110.722793 | Jean-Raphaël Guillaumin (photography) and T. Michael Keesey (vectorization)                                                                                                          |
| 710 |     96.994398 |    766.808782 | Zimices                                                                                                                                                                              |
| 711 |    855.648461 |     94.012126 | Scott Hartman                                                                                                                                                                        |
| 712 |    407.159132 |    127.896936 | Emily Jane McTavish, from <http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>                                                                          |
| 713 |    230.403845 |    303.554897 | Gareth Monger                                                                                                                                                                        |
| 714 |    360.357104 |    718.438068 | Yan Wong                                                                                                                                                                             |
| 715 |    961.275994 |    379.968107 | Ferran Sayol                                                                                                                                                                         |
| 716 |     31.491481 |    790.747309 | Joedison Rocha                                                                                                                                                                       |
| 717 |      5.741671 |    565.429065 | Mathieu Basille                                                                                                                                                                      |
| 718 |    921.553947 |    639.917966 | Dean Schnabel                                                                                                                                                                        |
| 719 |    805.388317 |    679.886078 | Tasman Dixon                                                                                                                                                                         |
| 720 |    775.373866 |      6.320754 | Ghedoghedo, vectorized by Zimices                                                                                                                                                    |
| 721 |    266.914942 |    427.941191 | CNZdenek                                                                                                                                                                             |
| 722 |     93.034097 |    546.020165 | Matt Crook                                                                                                                                                                           |
| 723 |    785.448105 |    662.520033 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 724 |    291.637848 |    219.134511 | Milton Tan                                                                                                                                                                           |
| 725 |    353.166927 |    532.100858 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 726 |     27.182869 |    127.820379 | Kai R. Caspar                                                                                                                                                                        |
| 727 |    428.582886 |    690.332520 | T. Michael Keesey (after Joseph Wolf)                                                                                                                                                |
| 728 |     34.059133 |    730.026266 | Scott Hartman                                                                                                                                                                        |
| 729 |    196.419346 |    676.366482 | Matt Martyniuk                                                                                                                                                                       |
| 730 |     85.776195 |     48.820218 | NA                                                                                                                                                                                   |
| 731 |    166.015768 |    361.813715 | david maas / dave hone                                                                                                                                                               |
| 732 |    755.433873 |    553.592569 | Bryan Carstens                                                                                                                                                                       |
| 733 |    508.981950 |     98.948455 | Kai R. Caspar                                                                                                                                                                        |
| 734 |     18.628748 |    700.275607 | Sarah Werning                                                                                                                                                                        |
| 735 |    728.417361 |    311.266840 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 736 |    573.305177 |    674.095610 | Emily Willoughby                                                                                                                                                                     |
| 737 |    931.613914 |    646.702742 | Michael Scroggie                                                                                                                                                                     |
| 738 |    338.953363 |    523.619384 | Margot Michaud                                                                                                                                                                       |
| 739 |     20.253589 |    620.115333 | Christoph Schomburg                                                                                                                                                                  |
| 740 |    849.565967 |    351.572699 | Zimices                                                                                                                                                                              |
| 741 |    253.983398 |    775.321630 | Matt Crook                                                                                                                                                                           |
| 742 |    832.165395 |     46.526543 | L. Shyamal                                                                                                                                                                           |
| 743 |    930.124453 |      5.379732 | Collin Gross                                                                                                                                                                         |
| 744 |    627.331888 |    335.543820 | Margot Michaud                                                                                                                                                                       |
| 745 |     27.751732 |    504.263783 | Zimices                                                                                                                                                                              |
| 746 |    282.005226 |    411.851139 | T. Michael Keesey                                                                                                                                                                    |
| 747 |    223.742514 |    142.048223 | Scott Hartman                                                                                                                                                                        |
| 748 |    813.328221 |    537.462123 | Scott Hartman (modified by T. Michael Keesey)                                                                                                                                        |
| 749 |    978.478639 |      1.903442 | Gareth Monger                                                                                                                                                                        |
| 750 |    559.277672 |    437.381710 | M Kolmann                                                                                                                                                                            |
| 751 |    127.815957 |    383.097956 | Jose Carlos Arenas-Monroy                                                                                                                                                            |
| 752 |    265.097459 |    705.778691 | Alex Slavenko                                                                                                                                                                        |
| 753 |    463.843945 |    360.004041 | xgirouxb                                                                                                                                                                             |
| 754 |    494.589591 |     99.621597 | T. Michael Keesey (after Heinrich Harder)                                                                                                                                            |
| 755 |     97.324771 |    154.416649 | Sarah Werning                                                                                                                                                                        |
| 756 |    386.808132 |    467.145027 | Zachary Quigley                                                                                                                                                                      |
| 757 |    778.694935 |     32.038199 | Zimices                                                                                                                                                                              |
| 758 |    725.384850 |    538.401725 | Ferran Sayol                                                                                                                                                                         |
| 759 |    990.108434 |    645.310857 | NA                                                                                                                                                                                   |
| 760 |    864.416913 |    486.261331 | NA                                                                                                                                                                                   |
| 761 |    589.565990 |    421.261641 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 762 |    325.927707 |    225.873905 | Nicholas J. Czaplewski, vectorized by Zimices                                                                                                                                        |
| 763 |    957.935938 |    189.150535 | Oscar Sanisidro                                                                                                                                                                      |
| 764 |    541.904903 |    697.970812 | Mariana Ruiz (vectorized by T. Michael Keesey)                                                                                                                                       |
| 765 |    702.261709 |    381.319201 | Gareth Monger                                                                                                                                                                        |
| 766 |    713.722848 |    787.755496 | Scott Hartman                                                                                                                                                                        |
| 767 |     43.627541 |    264.235550 | Steven Traver                                                                                                                                                                        |
| 768 |    208.532165 |    342.425464 | Joris van der Ham (vectorized by T. Michael Keesey)                                                                                                                                  |
| 769 |    595.262534 |    432.946841 | Sarah Werning                                                                                                                                                                        |
| 770 |    754.478943 |    599.972769 | NA                                                                                                                                                                                   |
| 771 |    720.198563 |    442.985376 | Tasman Dixon                                                                                                                                                                         |
| 772 |    213.766225 |    379.791454 | Jagged Fang Designs                                                                                                                                                                  |
| 773 |    228.721420 |    486.744262 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 774 |   1010.229826 |    324.837366 | Jagged Fang Designs                                                                                                                                                                  |
| 775 |    167.699430 |    711.507879 | Xavier Giroux-Bougard                                                                                                                                                                |
| 776 |    131.683060 |    153.031670 | Zimices                                                                                                                                                                              |
| 777 |    541.458334 |     54.528490 | NA                                                                                                                                                                                   |
| 778 |    576.432997 |    457.895408 | T. Michael Keesey                                                                                                                                                                    |
| 779 |    200.057015 |    708.077729 | Ferran Sayol                                                                                                                                                                         |
| 780 |    654.193192 |    406.235860 | Steven Coombs                                                                                                                                                                        |
| 781 |    146.379482 |     30.465255 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                                      |
| 782 |    486.082397 |    330.610356 | Sergio A. Muñoz-Gómez                                                                                                                                                                |
| 783 |    654.696378 |    267.753939 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 784 |     97.557442 |    793.512272 | Sarah Werning                                                                                                                                                                        |
| 785 |    435.373317 |    401.442496 | Emil Schmidt (vectorized by Maxime Dahirel)                                                                                                                                          |
| 786 |     19.694049 |    649.797619 | NA                                                                                                                                                                                   |
| 787 |    178.856602 |    588.006127 | Gareth Monger                                                                                                                                                                        |
| 788 |    188.100382 |    351.937941 | Tracy A. Heath                                                                                                                                                                       |
| 789 |     76.356414 |     76.419516 | Scott Hartman (modified by T. Michael Keesey)                                                                                                                                        |
| 790 |    223.011136 |    576.513069 | Maija Karala                                                                                                                                                                         |
| 791 |     63.418940 |    166.789793 | Smokeybjb (modified by Mike Keesey)                                                                                                                                                  |
| 792 |    752.245622 |     52.674885 | Matt Crook                                                                                                                                                                           |
| 793 |    343.729499 |    261.544153 | Steven Traver                                                                                                                                                                        |
| 794 |    748.113469 |    564.756780 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 795 |    748.394295 |      5.513327 | Scott Hartman                                                                                                                                                                        |
| 796 |    346.145910 |    589.232512 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 797 |     54.511945 |    708.304385 | Andrew A. Farke                                                                                                                                                                      |
| 798 |     36.294502 |     37.892449 | T. Michael Keesey                                                                                                                                                                    |
| 799 |    988.352497 |    789.823702 | Zimices                                                                                                                                                                              |
| 800 |    605.791688 |    183.208924 | L. Shyamal                                                                                                                                                                           |
| 801 |    503.726939 |    794.141607 | Scott Hartman                                                                                                                                                                        |
| 802 |    886.795571 |     68.302076 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                                       |
| 803 |    598.454770 |    133.103888 | Zimices                                                                                                                                                                              |
| 804 |    731.963398 |    125.474907 | Matt Crook                                                                                                                                                                           |
| 805 |    714.228124 |     34.546182 | Matt Crook                                                                                                                                                                           |
| 806 |    127.327004 |    706.162914 | Yan Wong (vectorization) from 1873 illustration                                                                                                                                      |
| 807 |    834.691317 |    500.055964 | Maija Karala                                                                                                                                                                         |
| 808 |    235.607009 |    722.190076 | Margot Michaud                                                                                                                                                                       |
| 809 |    238.330586 |    301.280827 | Birgit Lang                                                                                                                                                                          |
| 810 |    553.376315 |    455.495673 | Renato de Carvalho Ferreira                                                                                                                                                          |
| 811 |    214.937650 |    269.565716 | John Gould (vectorized by T. Michael Keesey)                                                                                                                                         |
| 812 |    358.121245 |    766.284849 | Shyamal                                                                                                                                                                              |
| 813 |    444.667416 |    221.578755 | Ferran Sayol                                                                                                                                                                         |
| 814 |    418.045721 |    341.266616 | Neil Kelley                                                                                                                                                                          |
| 815 |     40.376033 |    115.339319 | Gareth Monger                                                                                                                                                                        |
| 816 |    796.097096 |    619.185297 | Tony Ayling                                                                                                                                                                          |
| 817 |     70.017002 |     51.241722 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 818 |    716.751716 |    312.784435 | Michael Scroggie                                                                                                                                                                     |
| 819 |    587.668758 |     89.569077 | Matthew E. Clapham                                                                                                                                                                   |
| 820 |    408.833506 |    477.156916 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                                             |
| 821 |    560.761471 |    367.799982 | Matt Crook                                                                                                                                                                           |
| 822 |    995.738918 |    320.214652 | Jose Carlos Arenas-Monroy                                                                                                                                                            |
| 823 |    169.649804 |    618.479503 | NA                                                                                                                                                                                   |
| 824 |     92.453642 |    166.795764 | Neil Kelley                                                                                                                                                                          |
| 825 |    195.996358 |    251.222254 | Matt Crook                                                                                                                                                                           |
| 826 |    336.991242 |    613.424913 | Maxime Dahirel                                                                                                                                                                       |
| 827 |    652.777362 |     88.211729 | Ville Koistinen and T. Michael Keesey                                                                                                                                                |
| 828 |    601.374447 |     19.128690 | FJDegrange                                                                                                                                                                           |
| 829 |    670.423550 |    701.888986 | Matt Crook                                                                                                                                                                           |
| 830 |    233.868693 |    387.964457 | NA                                                                                                                                                                                   |
| 831 |    420.004858 |    277.087060 | Michelle Site                                                                                                                                                                        |
| 832 |    902.270240 |    716.553764 | Danielle Alba                                                                                                                                                                        |
| 833 |    640.500119 |    198.813921 | Jagged Fang Designs                                                                                                                                                                  |
| 834 |    783.514445 |    381.097154 | Zimices                                                                                                                                                                              |
| 835 |    170.360208 |    270.396865 | Zimices                                                                                                                                                                              |
| 836 |    496.954883 |    720.665120 | Gareth Monger                                                                                                                                                                        |
| 837 |    874.946290 |    568.812230 | Gareth Monger                                                                                                                                                                        |
| 838 |    153.295530 |    607.697398 | Matt Crook                                                                                                                                                                           |
| 839 |      5.242083 |      6.210773 | Andrew A. Farke, shell lines added by Yan Wong                                                                                                                                       |
| 840 |    530.408681 |    594.426988 | Chris huh                                                                                                                                                                            |
| 841 |    812.624285 |      5.862058 | Matt Crook                                                                                                                                                                           |
| 842 |     48.325430 |    289.615160 | NA                                                                                                                                                                                   |
| 843 |    601.926813 |    736.653497 | Michele M Tobias                                                                                                                                                                     |
| 844 |    683.253027 |    692.518236 | Martien Brand (original photo), Renato Santos (vector silhouette)                                                                                                                    |
| 845 |    588.171329 |    145.828717 | Margot Michaud                                                                                                                                                                       |
| 846 |    991.859446 |    694.960475 | NA                                                                                                                                                                                   |
| 847 |   1018.714890 |     54.256725 | Tasman Dixon                                                                                                                                                                         |
| 848 |   1002.681696 |    127.940816 | Gareth Monger                                                                                                                                                                        |
| 849 |    541.462083 |    309.508043 | Ingo Braasch                                                                                                                                                                         |
| 850 |    413.462467 |    470.365216 | FunkMonk                                                                                                                                                                             |
| 851 |    519.752243 |    206.190095 | Steven Traver                                                                                                                                                                        |
| 852 |    152.075188 |    414.908545 | Javier Luque & Sarah Gerken                                                                                                                                                          |
| 853 |    669.768196 |     61.811106 | Noah Schlottman                                                                                                                                                                      |
| 854 |     90.876748 |    275.371279 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 855 |    649.100686 |     31.471880 | Frank Förster (based on a picture by Jerry Kirkhart; modified by T. Michael Keesey)                                                                                                  |
| 856 |    862.977150 |    522.400336 | T. Michael Keesey                                                                                                                                                                    |
| 857 |    796.771225 |    609.393316 | Lisa Byrne                                                                                                                                                                           |
| 858 |    994.146941 |     25.718220 | Frank Denota                                                                                                                                                                         |
| 859 |    224.710365 |    234.827890 | Collin Gross                                                                                                                                                                         |
| 860 |    239.046571 |    706.273402 | Matt Crook                                                                                                                                                                           |
| 861 |    228.724423 |    218.078933 | Roderic Page and Lois Page                                                                                                                                                           |
| 862 |    598.204166 |    445.555365 | Margot Michaud                                                                                                                                                                       |
| 863 |    477.430096 |    396.221048 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 864 |    710.325226 |    507.468827 | DW Bapst (Modified from photograph taken by Charles Mitchell)                                                                                                                        |
| 865 |    747.880701 |    411.876077 | Mathew Wedel                                                                                                                                                                         |
| 866 |    820.060497 |    541.941341 | Sharon Wegner-Larsen                                                                                                                                                                 |
| 867 |    120.238766 |    100.961491 | Emil Schmidt (vectorized by Maxime Dahirel)                                                                                                                                          |
| 868 |    200.610115 |    219.186110 | Gordon E. Robertson                                                                                                                                                                  |
| 869 |    967.138305 |    127.841338 | Zimices                                                                                                                                                                              |
| 870 |     58.385505 |      6.119114 | Andrew A. Farke                                                                                                                                                                      |
| 871 |    142.160005 |    150.261864 | T. Michael Keesey                                                                                                                                                                    |
| 872 |     14.556077 |    295.478081 | Scott Hartman                                                                                                                                                                        |
| 873 |     15.011120 |    338.169442 | Nancy Wyman (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                          |
| 874 |    211.466226 |     16.688999 | NA                                                                                                                                                                                   |
| 875 |    489.261650 |    709.483766 | Matt Crook                                                                                                                                                                           |
| 876 |    368.135697 |    771.133905 | Margot Michaud                                                                                                                                                                       |
| 877 |    291.701335 |    537.968671 | Melissa Ingala                                                                                                                                                                       |
| 878 |    222.820145 |    412.684829 | Kimberly Haddrell                                                                                                                                                                    |
| 879 |    643.080279 |    311.792895 | Chris huh                                                                                                                                                                            |
| 880 |    230.436618 |     73.127246 | Zimices                                                                                                                                                                              |
| 881 |    212.883108 |    393.897420 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                                        |
| 882 |    960.295439 |    781.174449 | Zimices                                                                                                                                                                              |
| 883 |    816.995990 |    134.462276 | Gareth Monger                                                                                                                                                                        |
| 884 |    673.741924 |    120.732405 | Sarah Werning                                                                                                                                                                        |
| 885 |    199.153367 |    492.536148 | Steven Traver                                                                                                                                                                        |
| 886 |    452.367693 |    193.382443 | Caleb M. Brown                                                                                                                                                                       |
| 887 |    459.710911 |     58.075931 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                                    |
| 888 |     89.559159 |    706.710656 | NA                                                                                                                                                                                   |
| 889 |    977.866288 |    665.883023 | Matt Crook                                                                                                                                                                           |
| 890 |    138.801116 |    194.316146 | Matt Crook                                                                                                                                                                           |
| 891 |    544.746131 |    605.517939 | T. Michael Keesey                                                                                                                                                                    |
| 892 |    848.281614 |    700.011486 | AnAgnosticGod (vectorized by T. Michael Keesey)                                                                                                                                      |
| 893 |    896.048348 |    547.989131 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 894 |    191.995956 |     38.120175 | Emily Willoughby                                                                                                                                                                     |
| 895 |    123.679157 |    760.714534 | Gareth Monger                                                                                                                                                                        |
| 896 |    697.696209 |    113.811878 | Margot Michaud                                                                                                                                                                       |
| 897 |    949.561748 |    366.133568 | Margot Michaud                                                                                                                                                                       |
| 898 |    177.671108 |    392.053276 | Scott Hartman                                                                                                                                                                        |
| 899 |    220.641840 |    479.193175 | Ewald Rübsamen                                                                                                                                                                       |
| 900 |    693.398951 |    252.146641 | Melissa Broussard                                                                                                                                                                    |
| 901 |    218.360035 |    463.977478 | Margot Michaud                                                                                                                                                                       |
| 902 |    960.716185 |     23.609205 | Jagged Fang Designs                                                                                                                                                                  |
| 903 |    378.155554 |    182.123833 | Tasman Dixon                                                                                                                                                                         |
| 904 |    626.030553 |    344.693073 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                                    |
| 905 |    776.366812 |    792.018676 | Birgit Lang                                                                                                                                                                          |
| 906 |    187.919542 |    723.040808 | Jagged Fang Designs                                                                                                                                                                  |
| 907 |    561.838115 |    380.494241 | Steven Traver                                                                                                                                                                        |
| 908 |     84.903012 |    564.092959 | T. Michael Keesey                                                                                                                                                                    |
| 909 |    552.130150 |    321.610859 | Ferran Sayol                                                                                                                                                                         |
| 910 |    330.479681 |    482.196979 | Jagged Fang Designs                                                                                                                                                                  |
| 911 |    533.756580 |    330.719238 | Michael Scroggie                                                                                                                                                                     |
| 912 |    465.633073 |    275.355788 | NA                                                                                                                                                                                   |
| 913 |    184.000373 |    664.966408 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                                      |
| 914 |     88.080631 |    408.273464 | Michael Scroggie                                                                                                                                                                     |
| 915 |    195.327790 |      7.624425 | Matt Crook                                                                                                                                                                           |
| 916 |    582.959495 |    746.368615 | Michael Scroggie, from original photograph by Gary M. Stolz, USFWS (original photograph in public domain).                                                                           |
| 917 |    326.584832 |    489.844931 | Matt Crook                                                                                                                                                                           |
| 918 |     79.759001 |    168.746303 | Keith Murdock (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                        |
| 919 |    718.471065 |     45.286253 | Chris huh                                                                                                                                                                            |
| 920 |    405.019974 |    173.577936 | Margot Michaud                                                                                                                                                                       |
| 921 |    904.096963 |    199.735932 | Sherman Foote Denton (illustration, 1897) and Timothy J. Bartley (silhouette)                                                                                                        |
| 922 |    862.030295 |    616.652068 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 923 |     88.807705 |    101.788811 | Tauana J. Cunha                                                                                                                                                                      |
| 924 |    598.752677 |    685.953991 | Melissa Broussard                                                                                                                                                                    |
| 925 |    438.178235 |    765.588877 | Matt Crook                                                                                                                                                                           |
| 926 |    795.134994 |    300.420446 | Rebecca Groom                                                                                                                                                                        |
| 927 |    773.090462 |    701.547879 | Jagged Fang Designs                                                                                                                                                                  |

    #> Your tweet has been posted!
