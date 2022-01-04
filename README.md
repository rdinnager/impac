
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

Ingo Braasch, Gabriela Palomo-Munoz, Sibi (vectorized by T. Michael
Keesey), T. Michael Keesey, Alexander Schmidt-Lebuhn, Birgit Lang,
FunkMonk (Michael B.H.; vectorized by T. Michael Keesey), Rebecca Groom,
L. Shyamal, Dean Schnabel, Ferran Sayol, Tony Ayling (vectorized by T.
Michael Keesey), Zimices, Carlos Cano-Barbacil, Steven Traver, Sarah
Werning, Jagged Fang Designs, Emily Willoughby, Markus A. Grohme,
zoosnow, T. Michael Keesey (vectorization); Yves Bousquet (photography),
Gareth Monger, Scott Hartman, Mo Hassan, Matt Crook, Iain Reid, Chuanixn
Yu, NASA, James Neenan, Steven Coombs, Anthony Caravaggi, Katie S.
Collins, M Kolmann, Francisco Gascó (modified by Michael P. Taylor),
Evan Swigart (photography) and T. Michael Keesey (vectorization), Chris
huh, Maxwell Lefroy (vectorized by T. Michael Keesey), Campbell Fleming,
Maija Karala, Crystal Maier, Julio Garza, Michael Scroggie, Dmitry
Bogdanov (vectorized by T. Michael Keesey), Christoph Schomburg, Sean
McCann, Kenneth Lacovara (vectorized by T. Michael Keesey), FunkMonk,
Jakovche, Agnello Picorelli, Noah Schlottman, photo from National
Science Foundation - Turbellarian Taxonomic Database, Mathew Wedel,
Margot Michaud, Nobu Tamura (vectorized by T. Michael Keesey), Yan Wong,
Martin R. Smith, after Skovsted et al 2015, Smokeybjb, vectorized by
Zimices, Tasman Dixon, Juan Carlos Jerí, Karla Martinez, Smokeybjb,
Henry Lydecker, David Sim (photograph) and T. Michael Keesey
(vectorization), Joanna Wolfe, Matt Hayes, T. Michael Keesey, from a
photograph by Thea Boodhoo, Alexandra van der Geer, Pete Buchholz,
Sharon Wegner-Larsen, Didier Descouens (vectorized by T. Michael
Keesey), Emil Schmidt (vectorized by Maxime Dahirel), A. R. McCulloch
(vectorized by T. Michael Keesey), Ricardo N. Martinez & Oscar A.
Alcober, SecretJellyMan - from Mason McNair, Theodore W. Pietsch
(photography) and T. Michael Keesey (vectorization), Maxime Dahirel,
Michael Day, Jake Warner, Jaime Headden, Terpsichores, Christina N.
Hodson, Nobu Tamura, vectorized by Zimices, Michelle Site, Ghedoghedo
(vectorized by T. Michael Keesey), Kai R. Caspar, Natalie Claunch, Alex
Slavenko, Chris A. Hamilton, Collin Gross, Fernando Carezzano, Ludwik
Gasiorowski, Paul O. Lewis, Noah Schlottman, photo by Casey Dunn, Tracy
A. Heath, C. Camilo Julián-Caballero, Felix Vaux, Beth Reinke, David
Orr, Matt Martyniuk, Chase Brownstein, Noah Schlottman, photo from
Moorea Biocode, Heinrich Harder (vectorized by T. Michael Keesey), T.
Michael Keesey (after Marek Velechovský), Andrew A. Farke, modified from
original by Robert Bruce Horsfall, from Scott 1912, Armin Reindl, Tom
Tarrant (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Cesar Julian, Neil Kelley, Renata F. Martins, DW Bapst
(Modified from photograph taken by Charles Mitchell), Brian Swartz
(vectorized by T. Michael Keesey), Kamil S. Jaron, Almandine (vectorized
by T. Michael Keesey), Caleb M. Brown, Brian Gratwicke (photo) and T.
Michael Keesey (vectorization), Manabu Sakamoto, DW Bapst (modified from
Mitchell 1990), Smokeybjb (modified by T. Michael Keesey), Tauana J.
Cunha, Scott Reid, Robert Gay, modified from FunkMonk (Michael B.H.) and
T. Michael Keesey., Blair Perry, Jim Bendon (photography) and T. Michael
Keesey (vectorization), NOAA Great Lakes Environmental Research
Laboratory (illustration) and Timothy J. Bartley (silhouette), Shyamal,
Chris Jennings (vectorized by A. Verrière), Jose Carlos Arenas-Monroy,
Félix Landry Yuan, Jay Matternes (vectorized by T. Michael Keesey),
Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts,
Catherine A. Forster, Joshua A. Smith, Alan L. Titus, Luc Viatour
(source photo) and Andreas Plank, Jordan Mallon (vectorized by T.
Michael Keesey), Farelli (photo), John E. McCormack, Michael G. Harvey,
Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T.
Brumfield & T. Michael Keesey, Owen Jones, Dmitry Bogdanov, Arthur S.
Brum, Milton Tan, Birgit Szabo, Tyler Greenfield, JCGiron, Nobu Tamura,
Darren Naish, Nemo, and T. Michael Keesey, Haplochromis (vectorized by
T. Michael Keesey), Kanako Bessho-Uehara, S.Martini, Mali’o Kodis,
photograph by “Wildcat Dunny”
(<http://www.flickr.com/people/wildcat_dunny/>), Stuart Humphries, Noah
Schlottman, Nobu Tamura (modified by T. Michael Keesey), Ville-Veikko
Sinkkonen, Mariana Ruiz (vectorized by T. Michael Keesey), Tomas Willems
(vectorized by T. Michael Keesey), Chloé Schmidt, Natasha Vitek, Becky
Barnes, Matt Dempsey, Martin R. Smith, Jerry Oldenettel (vectorized by
T. Michael Keesey), Mattia Menchetti, Geoff Shaw, Robbie N. Cada
(modified by T. Michael Keesey), Oscar Sanisidro, Obsidian Soul
(vectorized by T. Michael Keesey), Ignacio Contreras, Lauren Anderson,
Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow
(vectorized by T. Michael Keesey), Roberto Díaz Sibaja, Sergio A.
Muñoz-Gómez, Rachel Shoop, Mali’o Kodis, image from the Smithsonian
Institution, Mathieu Basille, Diego Fontaneto, Elisabeth A. Herniou,
Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and
Timothy G. Barraclough (vectorized by T. Michael Keesey), Baheerathan
Murugavel, Duane Raver (vectorized by T. Michael Keesey), Original
drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja, Jessica
Anne Miller, Mathilde Cordellier, T. Michael Keesey (after Tillyard),
Smith609 and T. Michael Keesey, T. Michael Keesey (photo by Sean Mack),
Stephen O’Connor (vectorized by T. Michael Keesey), Robert Bruce
Horsfall, vectorized by Zimices, Ellen Edmonson and Hugh Chrisp
(illustration) and Timothy J. Bartley (silhouette), Kent Elson Sorgon, M
Hutchinson, Noah Schlottman, photo by Martin V. Sørensen, Peter Coxhead,
Sherman F. Denton via rawpixel.com (illustration) and Timothy J. Bartley
(silhouette), Rebecca Groom (Based on Photo by Andreas Trepte), Antonov
(vectorized by T. Michael Keesey), Kimberly Haddrell, nicubunu, V.
Deepak, Andrew A. Farke, shell lines added by Yan Wong, Lukasiniho,
Dmitry Bogdanov (modified by T. Michael Keesey), Xavier Giroux-Bougard,
Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette), Maha
Ghazal, kotik, Mario Quevedo, Roberto Diaz Sibaja, based on Domser,
Frank Förster (based on a picture by Hans Hillewaert), Hans Hillewaert
(vectorized by T. Michael Keesey), Inessa Voet, Brad McFeeters
(vectorized by T. Michael Keesey), Harold N Eyster, Kailah Thorn & Ben
King, Mark Witton, Javier Luque, Michele M Tobias from an image By
Dcrjsr - Own work, CC BY 3.0,
<https://commons.wikimedia.org/w/index.php?curid=18059686>, Melissa
Broussard, Arthur Weasley (vectorized by T. Michael Keesey), Burton
Robert, USFWS, Noah Schlottman, photo by Carol Cummings, Andrew A.
Farke, Dori <dori@merr.info> (source photo) and Nevit Dilmen, Siobhon
Egan, Isaure Scavezzoni, Mali’o Kodis, photograph by Aqua-Photos
(<http://www.flickr.com/people/undervannsfotografen/>), Christine Axon,
Alexandre Vong, Mike Hanson, Michael Scroggie, from original photograph
by Gary M. Stolz, USFWS (original photograph in public domain).,
Catherine Yasuda, Lindberg (vectorized by T. Michael Keesey), Davidson
Sodré, Ieuan Jones, Peileppe, Kailah Thorn & Mark Hutchinson, Kosta
Mumcuoglu (vectorized by T. Michael Keesey), Renato de Carvalho
Ferreira, Jack Mayer Wood, xgirouxb, Joseph Smit (modified by T. Michael
Keesey), Michael Ströck (vectorized by T. Michael Keesey), Ellen
Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey), Robbie Cada
(vectorized by T. Michael Keesey), Jimmy Bernot, Julie Blommaert based
on photo by Sofdrakou, Jebulon (vectorized by T. Michael Keesey), T.
Michael Keesey (vector) and Stuart Halliday (photograph), Pedro de
Siracusa, J. J. Harrison (photo) & T. Michael Keesey, Matt Martyniuk
(vectorized by T. Michael Keesey), Warren H (photography), T. Michael
Keesey (vectorization), Josefine Bohr Brask, CNZdenek, Sarefo
(vectorized by T. Michael Keesey), Michele M Tobias, Cristopher Silva,
James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis
Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey), Douglas
Brown (modified by T. Michael Keesey), T. Michael Keesey (after MPF),
Cristina Guijarro, T. Michael Keesey (vectorization) and HuttyMcphoo
(photography), Ryan Cupo, Jon Hill (Photo by Benjamint444:
<http://en.wikipedia.org/wiki/File:Blue-footed-booby.jpg>), Prin
Pattawaro (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Aviceda (photo) & T. Michael Keesey, Charles Doolittle
Walcott (vectorized by T. Michael Keesey), Joe Schneid (vectorized by T.
Michael Keesey), Yan Wong from SEM by Arnau Sebé-Pedrós (PD agreed by
Iñaki Ruiz-Trillo), NOAA (vectorized by T. Michael Keesey), Ville
Koistinen and T. Michael Keesey, Abraão B. Leite, Liftarn

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    390.478029 |    414.036181 | Ingo Braasch                                                                                                                                                          |
|   2 |    460.383002 |    568.575418 | Gabriela Palomo-Munoz                                                                                                                                                 |
|   3 |    480.570375 |    105.560624 | Sibi (vectorized by T. Michael Keesey)                                                                                                                                |
|   4 |    205.860627 |    471.072946 | Gabriela Palomo-Munoz                                                                                                                                                 |
|   5 |    831.154583 |    619.049346 | T. Michael Keesey                                                                                                                                                     |
|   6 |    559.286229 |    292.082023 | Alexander Schmidt-Lebuhn                                                                                                                                              |
|   7 |    386.809982 |    539.051743 | Birgit Lang                                                                                                                                                           |
|   8 |    668.016512 |    335.906833 | FunkMonk (Michael B.H.; vectorized by T. Michael Keesey)                                                                                                              |
|   9 |    189.868445 |    179.157317 | Rebecca Groom                                                                                                                                                         |
|  10 |    149.190658 |    374.692948 | L. Shyamal                                                                                                                                                            |
|  11 |     46.958067 |    115.311420 | Dean Schnabel                                                                                                                                                         |
|  12 |    842.111660 |    227.993955 | Ferran Sayol                                                                                                                                                          |
|  13 |    322.099313 |    156.401994 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
|  14 |    188.704407 |    567.541381 | Zimices                                                                                                                                                               |
|  15 |    583.609239 |    731.081875 | Carlos Cano-Barbacil                                                                                                                                                  |
|  16 |     87.424413 |    565.690585 | Steven Traver                                                                                                                                                         |
|  17 |    422.735372 |    279.587661 | Sarah Werning                                                                                                                                                         |
|  18 |    923.687484 |    690.887494 | T. Michael Keesey                                                                                                                                                     |
|  19 |    905.919684 |    466.371797 | Jagged Fang Designs                                                                                                                                                   |
|  20 |    670.748188 |    198.767595 | Emily Willoughby                                                                                                                                                      |
|  21 |    809.450697 |    447.179782 | Jagged Fang Designs                                                                                                                                                   |
|  22 |    501.354110 |    625.664311 | Markus A. Grohme                                                                                                                                                      |
|  23 |    342.569733 |    650.197029 | zoosnow                                                                                                                                                               |
|  24 |    196.985270 |    708.024418 | T. Michael Keesey (vectorization); Yves Bousquet (photography)                                                                                                        |
|  25 |    723.577984 |    584.982996 | Gareth Monger                                                                                                                                                         |
|  26 |    311.142280 |    627.773676 | Scott Hartman                                                                                                                                                         |
|  27 |    497.673451 |    467.957225 | Mo Hassan                                                                                                                                                             |
|  28 |    652.471203 |    462.235002 | Matt Crook                                                                                                                                                            |
|  29 |    425.155061 |    177.150272 | Iain Reid                                                                                                                                                             |
|  30 |    873.558184 |     95.685166 | Jagged Fang Designs                                                                                                                                                   |
|  31 |    765.311249 |    128.825158 | Zimices                                                                                                                                                               |
|  32 |    528.623657 |    403.675990 | Steven Traver                                                                                                                                                         |
|  33 |    259.508322 |     73.835266 | NA                                                                                                                                                                    |
|  34 |    591.323689 |     42.573009 | Chuanixn Yu                                                                                                                                                           |
|  35 |    673.195060 |    391.922464 | Carlos Cano-Barbacil                                                                                                                                                  |
|  36 |    790.839435 |    291.649166 | NASA                                                                                                                                                                  |
|  37 |    912.055900 |    344.670274 | James Neenan                                                                                                                                                          |
|  38 |    641.912911 |    662.180723 | NA                                                                                                                                                                    |
|  39 |     64.859977 |    719.843400 | Ferran Sayol                                                                                                                                                          |
|  40 |     79.234839 |    238.634867 | Steven Coombs                                                                                                                                                         |
|  41 |    744.076908 |    734.102317 | T. Michael Keesey                                                                                                                                                     |
|  42 |    945.153632 |    765.506652 | Anthony Caravaggi                                                                                                                                                     |
|  43 |    911.544176 |    560.323574 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  44 |    358.622044 |    117.873694 | Scott Hartman                                                                                                                                                         |
|  45 |    377.178463 |    728.698024 | Katie S. Collins                                                                                                                                                      |
|  46 |     80.214358 |    321.152564 | M Kolmann                                                                                                                                                             |
|  47 |    290.252792 |    251.306014 | Francisco Gascó (modified by Michael P. Taylor)                                                                                                                       |
|  48 |    130.615358 |     63.036271 | NA                                                                                                                                                                    |
|  49 |    926.330061 |    106.300878 | Scott Hartman                                                                                                                                                         |
|  50 |    954.770468 |    143.531321 | Matt Crook                                                                                                                                                            |
|  51 |    387.922574 |     36.010340 | Jagged Fang Designs                                                                                                                                                   |
|  52 |    464.811849 |    677.259173 | Steven Traver                                                                                                                                                         |
|  53 |    972.033412 |    195.189557 | Evan Swigart (photography) and T. Michael Keesey (vectorization)                                                                                                      |
|  54 |    449.942302 |    512.318307 | Chris huh                                                                                                                                                             |
|  55 |     58.434531 |    390.307306 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                      |
|  56 |    688.345231 |    268.489055 | Campbell Fleming                                                                                                                                                      |
|  57 |    263.722730 |    779.700880 | Zimices                                                                                                                                                               |
|  58 |    588.167300 |    151.430899 | Gareth Monger                                                                                                                                                         |
|  59 |    581.232454 |    535.959992 | Maija Karala                                                                                                                                                          |
|  60 |    296.577416 |    404.681977 | Crystal Maier                                                                                                                                                         |
|  61 |    277.206837 |    528.543038 | Julio Garza                                                                                                                                                           |
|  62 |    873.325272 |    411.981191 | Michael Scroggie                                                                                                                                                      |
|  63 |    786.917725 |     39.820575 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  64 |    951.916665 |    507.399383 | NA                                                                                                                                                                    |
|  65 |    714.707365 |     96.338499 | Christoph Schomburg                                                                                                                                                   |
|  66 |    539.440291 |    782.818813 | Jagged Fang Designs                                                                                                                                                   |
|  67 |     73.086804 |    629.488318 | Sean McCann                                                                                                                                                           |
|  68 |    801.111523 |    715.222385 | Matt Crook                                                                                                                                                            |
|  69 |    930.499989 |     40.315395 | Zimices                                                                                                                                                               |
|  70 |    104.763523 |    205.678137 | Scott Hartman                                                                                                                                                         |
|  71 |    669.770386 |    775.134717 | NA                                                                                                                                                                    |
|  72 |    331.317560 |    210.677211 | Julio Garza                                                                                                                                                           |
|  73 |    467.922685 |    358.186870 | Ferran Sayol                                                                                                                                                          |
|  74 |    600.984701 |    592.325318 | Zimices                                                                                                                                                               |
|  75 |    726.383723 |    632.967852 | Kenneth Lacovara (vectorized by T. Michael Keesey)                                                                                                                    |
|  76 |    704.280739 |    530.417984 | Scott Hartman                                                                                                                                                         |
|  77 |     98.863277 |    286.170005 | FunkMonk                                                                                                                                                              |
|  78 |    244.115846 |    294.366792 | Jakovche                                                                                                                                                              |
|  79 |    142.260899 |    733.698162 | Agnello Picorelli                                                                                                                                                     |
|  80 |    991.000757 |    402.742601 | Noah Schlottman, photo from National Science Foundation - Turbellarian Taxonomic Database                                                                             |
|  81 |    517.134284 |     30.213121 | Mathew Wedel                                                                                                                                                          |
|  82 |    388.522276 |     74.744102 | Chris huh                                                                                                                                                             |
|  83 |    285.598764 |    739.991045 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  84 |    412.273754 |    478.748024 | Margot Michaud                                                                                                                                                        |
|  85 |    781.718977 |    378.725239 | Jagged Fang Designs                                                                                                                                                   |
|  86 |    835.418543 |    147.445032 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  87 |    114.005473 |    179.055793 | Matt Crook                                                                                                                                                            |
|  88 |    791.045776 |    436.135989 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  89 |    798.352672 |    365.465713 | Zimices                                                                                                                                                               |
|  90 |    659.426753 |     99.284541 | Markus A. Grohme                                                                                                                                                      |
|  91 |    425.419487 |    656.173719 | Matt Crook                                                                                                                                                            |
|  92 |    781.724463 |     18.244432 | Steven Traver                                                                                                                                                         |
|  93 |    799.184924 |    653.190336 | Yan Wong                                                                                                                                                              |
|  94 |    331.541699 |    588.811136 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  95 |    456.622896 |    728.501629 | Martin R. Smith, after Skovsted et al 2015                                                                                                                            |
|  96 |    915.657084 |    287.689512 | Smokeybjb, vectorized by Zimices                                                                                                                                      |
|  97 |    129.856603 |    522.705700 | Margot Michaud                                                                                                                                                        |
|  98 |    750.301438 |    222.296574 | Margot Michaud                                                                                                                                                        |
|  99 |    690.993995 |    593.590201 | Tasman Dixon                                                                                                                                                          |
| 100 |    643.550757 |    180.247552 | Juan Carlos Jerí                                                                                                                                                      |
| 101 |    584.342310 |    209.849839 | Margot Michaud                                                                                                                                                        |
| 102 |    598.636366 |    341.368460 | Tasman Dixon                                                                                                                                                          |
| 103 |    829.188721 |    783.764343 | Birgit Lang                                                                                                                                                           |
| 104 |     48.087009 |    213.759115 | Markus A. Grohme                                                                                                                                                      |
| 105 |   1005.047089 |     21.020023 | Karla Martinez                                                                                                                                                        |
| 106 |    373.694923 |    469.934461 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 107 |    397.183701 |    772.257141 | Smokeybjb                                                                                                                                                             |
| 108 |    304.493664 |    600.474015 | Sarah Werning                                                                                                                                                         |
| 109 |    792.478128 |    412.188172 | Gareth Monger                                                                                                                                                         |
| 110 |    152.739119 |    639.009631 | T. Michael Keesey                                                                                                                                                     |
| 111 |    541.033566 |     42.501488 | Carlos Cano-Barbacil                                                                                                                                                  |
| 112 |    462.150833 |    536.258819 | Ferran Sayol                                                                                                                                                          |
| 113 |     19.282162 |    463.280658 | Henry Lydecker                                                                                                                                                        |
| 114 |    321.584312 |     45.602796 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 115 |    571.279432 |     93.588389 | T. Michael Keesey                                                                                                                                                     |
| 116 |     39.752877 |     41.781458 | Ferran Sayol                                                                                                                                                          |
| 117 |    173.647269 |    516.840161 | Birgit Lang                                                                                                                                                           |
| 118 |    618.094187 |    346.186849 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 119 |     44.242922 |    184.566162 | Ferran Sayol                                                                                                                                                          |
| 120 |    400.659568 |    372.563623 | David Sim (photograph) and T. Michael Keesey (vectorization)                                                                                                          |
| 121 |     88.768367 |    769.881934 | Gareth Monger                                                                                                                                                         |
| 122 |    743.792800 |     61.254696 | Dean Schnabel                                                                                                                                                         |
| 123 |    544.934280 |     97.537705 | Matt Crook                                                                                                                                                            |
| 124 |     22.367918 |    135.390777 | Joanna Wolfe                                                                                                                                                          |
| 125 |    528.512203 |    482.867651 | Chris huh                                                                                                                                                             |
| 126 |    843.767705 |    745.309113 | T. Michael Keesey                                                                                                                                                     |
| 127 |     82.638614 |    780.743620 | Zimices                                                                                                                                                               |
| 128 |    886.462513 |    632.400702 | Ferran Sayol                                                                                                                                                          |
| 129 |    400.280659 |    319.307609 | Matt Hayes                                                                                                                                                            |
| 130 |    866.212086 |    642.916039 | T. Michael Keesey, from a photograph by Thea Boodhoo                                                                                                                  |
| 131 |    224.495206 |    768.726599 | Matt Crook                                                                                                                                                            |
| 132 |    444.517889 |    591.785727 | Scott Hartman                                                                                                                                                         |
| 133 |    616.315071 |     95.997118 | Zimices                                                                                                                                                               |
| 134 |    449.289439 |    152.958068 | Margot Michaud                                                                                                                                                        |
| 135 |      9.856890 |    219.010398 | Scott Hartman                                                                                                                                                         |
| 136 |   1011.533462 |    260.885210 | Gareth Monger                                                                                                                                                         |
| 137 |    814.024355 |    447.889347 | Scott Hartman                                                                                                                                                         |
| 138 |    417.257424 |    442.435626 | Ferran Sayol                                                                                                                                                          |
| 139 |    359.380040 |     72.193162 | Chris huh                                                                                                                                                             |
| 140 |    220.436667 |    397.462264 | Alexandra van der Geer                                                                                                                                                |
| 141 |   1015.421468 |    170.724223 | Steven Traver                                                                                                                                                         |
| 142 |     29.925546 |      9.754679 | Pete Buchholz                                                                                                                                                         |
| 143 |    888.263079 |    109.215803 | Yan Wong                                                                                                                                                              |
| 144 |    625.983602 |    146.171949 | Steven Traver                                                                                                                                                         |
| 145 |    564.490178 |    677.825783 | Margot Michaud                                                                                                                                                        |
| 146 |    224.629459 |    411.053570 | Sharon Wegner-Larsen                                                                                                                                                  |
| 147 |    335.326894 |     78.681977 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 148 |    116.481396 |     34.261917 | Jagged Fang Designs                                                                                                                                                   |
| 149 |    975.037757 |    644.221120 | T. Michael Keesey                                                                                                                                                     |
| 150 |     82.139369 |    480.026412 | Chuanixn Yu                                                                                                                                                           |
| 151 |    997.804852 |    764.773957 | Margot Michaud                                                                                                                                                        |
| 152 |     18.220398 |    537.691145 | Emil Schmidt (vectorized by Maxime Dahirel)                                                                                                                           |
| 153 |     11.587347 |    483.055578 | A. R. McCulloch (vectorized by T. Michael Keesey)                                                                                                                     |
| 154 |    898.268070 |    269.783522 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 155 |    531.352283 |    572.024044 | Ricardo N. Martinez & Oscar A. Alcober                                                                                                                                |
| 156 |    393.467888 |     17.052830 | Ferran Sayol                                                                                                                                                          |
| 157 |    388.491848 |    681.279624 | SecretJellyMan - from Mason McNair                                                                                                                                    |
| 158 |    301.519718 |    467.835495 | Michael Scroggie                                                                                                                                                      |
| 159 |    729.411009 |    207.112220 | Scott Hartman                                                                                                                                                         |
| 160 |    220.946021 |    137.683277 | Theodore W. Pietsch (photography) and T. Michael Keesey (vectorization)                                                                                               |
| 161 |    862.568138 |    787.221308 | Maxime Dahirel                                                                                                                                                        |
| 162 |    694.085566 |    179.020856 | Michael Day                                                                                                                                                           |
| 163 |    329.854734 |    393.983742 | Ferran Sayol                                                                                                                                                          |
| 164 |    126.820129 |    711.001713 | Chris huh                                                                                                                                                             |
| 165 |    704.904407 |    742.222731 | Jake Warner                                                                                                                                                           |
| 166 |    853.294149 |    478.303918 | Tasman Dixon                                                                                                                                                          |
| 167 |    243.751379 |    345.485701 | Jaime Headden                                                                                                                                                         |
| 168 |    861.500425 |    304.944614 | Ferran Sayol                                                                                                                                                          |
| 169 |    184.767297 |    520.899442 | Terpsichores                                                                                                                                                          |
| 170 |    949.246038 |    268.407644 | Christina N. Hodson                                                                                                                                                   |
| 171 |    320.007403 |     93.061053 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 172 |    280.778990 |    604.966243 | Matt Crook                                                                                                                                                            |
| 173 |    521.347106 |    561.544196 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 174 |    346.323173 |    367.411270 | Tasman Dixon                                                                                                                                                          |
| 175 |    961.843922 |    494.658641 | Jagged Fang Designs                                                                                                                                                   |
| 176 |    903.730464 |    150.272295 | Zimices                                                                                                                                                               |
| 177 |    348.582239 |    785.124809 | Michelle Site                                                                                                                                                         |
| 178 |    876.297748 |    301.303990 | Emily Willoughby                                                                                                                                                      |
| 179 |    728.817919 |    136.768123 | Katie S. Collins                                                                                                                                                      |
| 180 |    592.528156 |    772.156300 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 181 |    211.745418 |    310.280005 | Birgit Lang                                                                                                                                                           |
| 182 |    618.381818 |    487.169727 | Dean Schnabel                                                                                                                                                         |
| 183 |    483.320814 |    253.677914 | Ferran Sayol                                                                                                                                                          |
| 184 |    759.481896 |    254.352272 | Kai R. Caspar                                                                                                                                                         |
| 185 |    138.921965 |    756.988249 | Natalie Claunch                                                                                                                                                       |
| 186 |    703.503467 |     22.170740 | Rebecca Groom                                                                                                                                                         |
| 187 |    531.935192 |    495.840148 | Zimices                                                                                                                                                               |
| 188 |    217.944484 |    345.667655 | Alex Slavenko                                                                                                                                                         |
| 189 |    701.197944 |    495.867781 | Chris A. Hamilton                                                                                                                                                     |
| 190 |    584.749768 |    503.389733 | Chris huh                                                                                                                                                             |
| 191 |    115.069597 |    150.486721 | Collin Gross                                                                                                                                                          |
| 192 |    223.805746 |    251.341351 | Jagged Fang Designs                                                                                                                                                   |
| 193 |    800.901113 |    160.554288 | T. Michael Keesey                                                                                                                                                     |
| 194 |    904.693842 |    603.522404 | NA                                                                                                                                                                    |
| 195 |    141.523833 |    189.851993 | Matt Crook                                                                                                                                                            |
| 196 |    313.020241 |    478.261087 | Jagged Fang Designs                                                                                                                                                   |
| 197 |    886.446204 |    772.628121 | Steven Traver                                                                                                                                                         |
| 198 |    902.776955 |    527.824832 | Fernando Carezzano                                                                                                                                                    |
| 199 |    865.809960 |    138.555407 | Margot Michaud                                                                                                                                                        |
| 200 |    530.987460 |    324.481520 | Gareth Monger                                                                                                                                                         |
| 201 |     49.203454 |    490.199623 | Maxime Dahirel                                                                                                                                                        |
| 202 |    122.255102 |    732.517694 | Matt Crook                                                                                                                                                            |
| 203 |    503.095899 |     75.399061 | NA                                                                                                                                                                    |
| 204 |    934.748692 |    259.647633 | Ludwik Gasiorowski                                                                                                                                                    |
| 205 |    897.588993 |    714.535123 | Ferran Sayol                                                                                                                                                          |
| 206 |    475.882200 |    297.516735 | Ferran Sayol                                                                                                                                                          |
| 207 |    613.685764 |    240.120423 | NA                                                                                                                                                                    |
| 208 |    517.673117 |    356.402015 | Paul O. Lewis                                                                                                                                                         |
| 209 |    833.191704 |    366.387182 | Kai R. Caspar                                                                                                                                                         |
| 210 |    487.962810 |    148.986044 | Kai R. Caspar                                                                                                                                                         |
| 211 |    509.995061 |     95.940286 | NA                                                                                                                                                                    |
| 212 |    563.646944 |    125.702195 | Gareth Monger                                                                                                                                                         |
| 213 |    588.234872 |    513.654041 | Gareth Monger                                                                                                                                                         |
| 214 |    841.114513 |      4.171402 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
| 215 |    540.096259 |    445.344170 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 216 |    367.023598 |    362.265577 | Tracy A. Heath                                                                                                                                                        |
| 217 |    970.805312 |    269.475881 | Zimices                                                                                                                                                               |
| 218 |    121.276327 |    118.430148 | C. Camilo Julián-Caballero                                                                                                                                            |
| 219 |    990.612201 |    580.135257 | NA                                                                                                                                                                    |
| 220 |    228.145684 |    356.597459 | Scott Hartman                                                                                                                                                         |
| 221 |    305.398232 |     96.176423 | Ferran Sayol                                                                                                                                                          |
| 222 |    995.359207 |    306.646026 | Jagged Fang Designs                                                                                                                                                   |
| 223 |    156.584101 |    701.828952 | Zimices                                                                                                                                                               |
| 224 |    644.697106 |    368.676594 | NA                                                                                                                                                                    |
| 225 |    995.348135 |    727.758596 | Felix Vaux                                                                                                                                                            |
| 226 |    399.374865 |    452.695203 | Ferran Sayol                                                                                                                                                          |
| 227 |    430.848628 |    351.463574 | Juan Carlos Jerí                                                                                                                                                      |
| 228 |    342.335692 |    470.195891 | Jagged Fang Designs                                                                                                                                                   |
| 229 |    747.812467 |     32.415059 | Chris huh                                                                                                                                                             |
| 230 |    442.550039 |    773.070625 | Beth Reinke                                                                                                                                                           |
| 231 |      7.921272 |    352.512747 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 232 |     55.379597 |    765.586491 | Margot Michaud                                                                                                                                                        |
| 233 |    289.357666 |    793.578265 | Jagged Fang Designs                                                                                                                                                   |
| 234 |    179.935010 |    624.472060 | Markus A. Grohme                                                                                                                                                      |
| 235 |    910.791390 |    257.908168 | Scott Hartman                                                                                                                                                         |
| 236 |     18.481051 |    109.205221 | Margot Michaud                                                                                                                                                        |
| 237 |    345.947408 |     58.944775 | David Orr                                                                                                                                                             |
| 238 |     43.044215 |    662.509258 | Zimices                                                                                                                                                               |
| 239 |   1001.294220 |    150.585105 | Matt Martyniuk                                                                                                                                                        |
| 240 |      8.594033 |      8.422892 | Chase Brownstein                                                                                                                                                      |
| 241 |    252.632833 |    647.827012 | Ricardo N. Martinez & Oscar A. Alcober                                                                                                                                |
| 242 |    196.248905 |     46.119873 | NA                                                                                                                                                                    |
| 243 |     41.373450 |    572.182518 | Noah Schlottman, photo from Moorea Biocode                                                                                                                            |
| 244 |    391.691088 |      5.368459 | Heinrich Harder (vectorized by T. Michael Keesey)                                                                                                                     |
| 245 |    274.019712 |    482.443613 | Christoph Schomburg                                                                                                                                                   |
| 246 |    916.737385 |    245.145840 | Beth Reinke                                                                                                                                                           |
| 247 |    666.247545 |    697.569344 | Chuanixn Yu                                                                                                                                                           |
| 248 |    837.279836 |    457.758857 | T. Michael Keesey (after Marek Velechovský)                                                                                                                           |
| 249 |    672.779731 |    313.168385 | Tasman Dixon                                                                                                                                                          |
| 250 |     13.803310 |    170.543455 | Andrew A. Farke, modified from original by Robert Bruce Horsfall, from Scott 1912                                                                                     |
| 251 |    977.194868 |    580.058067 | Steven Traver                                                                                                                                                         |
| 252 |    876.690038 |    163.085480 | Zimices                                                                                                                                                               |
| 253 |     15.456388 |    406.141093 | Armin Reindl                                                                                                                                                          |
| 254 |    138.042347 |    499.081749 | Tom Tarrant (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
| 255 |    777.972624 |    229.258553 | Margot Michaud                                                                                                                                                        |
| 256 |    525.791181 |    702.880163 | Matt Crook                                                                                                                                                            |
| 257 |    605.672111 |    357.152443 | Cesar Julian                                                                                                                                                          |
| 258 |    679.769491 |    130.548437 | Neil Kelley                                                                                                                                                           |
| 259 |    489.415294 |    745.149758 | Birgit Lang                                                                                                                                                           |
| 260 |    232.424819 |    595.624717 | Renata F. Martins                                                                                                                                                     |
| 261 |    532.406683 |    207.522527 | NA                                                                                                                                                                    |
| 262 |    116.839188 |    263.359920 | Zimices                                                                                                                                                               |
| 263 |    478.874914 |    733.400025 | Zimices                                                                                                                                                               |
| 264 |    767.157028 |    686.921689 | DW Bapst (Modified from photograph taken by Charles Mitchell)                                                                                                         |
| 265 |    255.931635 |    171.843791 | Brian Swartz (vectorized by T. Michael Keesey)                                                                                                                        |
| 266 |    437.422705 |    616.650284 | Markus A. Grohme                                                                                                                                                      |
| 267 |      9.411097 |     76.728620 | Steven Traver                                                                                                                                                         |
| 268 |     74.426413 |     20.241059 | Kamil S. Jaron                                                                                                                                                        |
| 269 |    701.717069 |    350.317260 | Steven Traver                                                                                                                                                         |
| 270 |    251.072024 |    756.058692 | Almandine (vectorized by T. Michael Keesey)                                                                                                                           |
| 271 |    804.054024 |    378.172687 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 272 |    274.691538 |    687.978578 | Rebecca Groom                                                                                                                                                         |
| 273 |    253.269793 |    681.077759 | Caleb M. Brown                                                                                                                                                        |
| 274 |      7.720889 |    591.995945 | NA                                                                                                                                                                    |
| 275 |    711.675985 |    477.107495 | Tasman Dixon                                                                                                                                                          |
| 276 |    385.694444 |    135.619941 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 277 |    140.550004 |    749.884217 | Gareth Monger                                                                                                                                                         |
| 278 |    842.294157 |    159.529778 | Jagged Fang Designs                                                                                                                                                   |
| 279 |    561.517485 |    785.360443 | Brian Gratwicke (photo) and T. Michael Keesey (vectorization)                                                                                                         |
| 280 |    661.102367 |    111.137081 | Manabu Sakamoto                                                                                                                                                       |
| 281 |    944.375685 |    393.552018 | Ferran Sayol                                                                                                                                                          |
| 282 |    190.181546 |    108.001358 | Collin Gross                                                                                                                                                          |
| 283 |    293.509117 |    714.828813 | DW Bapst (modified from Mitchell 1990)                                                                                                                                |
| 284 |    720.347979 |    312.677791 | NA                                                                                                                                                                    |
| 285 |    117.654140 |    312.135515 | Chris huh                                                                                                                                                             |
| 286 |    709.598448 |    788.833073 | Smokeybjb (modified by T. Michael Keesey)                                                                                                                             |
| 287 |   1003.148754 |    273.231830 | Tauana J. Cunha                                                                                                                                                       |
| 288 |    737.201920 |    445.964749 | Jagged Fang Designs                                                                                                                                                   |
| 289 |    626.336261 |    171.468681 | Steven Traver                                                                                                                                                         |
| 290 |    663.667490 |    736.269698 | NA                                                                                                                                                                    |
| 291 |     32.661866 |    413.560973 | T. Michael Keesey                                                                                                                                                     |
| 292 |    759.919907 |     14.292736 | Manabu Sakamoto                                                                                                                                                       |
| 293 |    751.331559 |    131.615666 | Scott Reid                                                                                                                                                            |
| 294 |    131.186435 |    298.905933 | Margot Michaud                                                                                                                                                        |
| 295 |    107.863838 |    360.098383 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                              |
| 296 |    814.687218 |    172.548679 | Blair Perry                                                                                                                                                           |
| 297 |    527.346483 |     86.188730 | Armin Reindl                                                                                                                                                          |
| 298 |    759.613637 |    361.975169 | Matt Crook                                                                                                                                                            |
| 299 |    236.558641 |    706.355485 | Maija Karala                                                                                                                                                          |
| 300 |    607.517198 |    267.775172 | Matt Crook                                                                                                                                                            |
| 301 |     59.628452 |    451.429719 | Margot Michaud                                                                                                                                                        |
| 302 |    278.279736 |    673.821888 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 303 |    245.301510 |    449.422457 | Matt Crook                                                                                                                                                            |
| 304 |    336.884699 |    450.398815 | Jim Bendon (photography) and T. Michael Keesey (vectorization)                                                                                                        |
| 305 |    444.432048 |    600.456566 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
| 306 |    664.002168 |    725.647593 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 307 |    880.107570 |    721.796859 | Scott Hartman                                                                                                                                                         |
| 308 |    249.870328 |    412.503084 | Zimices                                                                                                                                                               |
| 309 |    194.129518 |    659.669220 | Scott Hartman                                                                                                                                                         |
| 310 |   1016.272332 |    700.311732 | Scott Hartman                                                                                                                                                         |
| 311 |    731.137169 |    489.954376 | Margot Michaud                                                                                                                                                        |
| 312 |    780.175746 |    204.956119 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 313 |    868.585841 |    170.777947 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 314 |    727.573565 |    529.972785 | Shyamal                                                                                                                                                               |
| 315 |    759.193898 |    388.261802 | Chris Jennings (vectorized by A. Verrière)                                                                                                                            |
| 316 |    668.153054 |    749.910302 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 317 |    581.149554 |    460.123941 | Margot Michaud                                                                                                                                                        |
| 318 |     69.704737 |    330.290633 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
| 319 |     57.673489 |     18.621441 | Matt Crook                                                                                                                                                            |
| 320 |    484.480913 |     87.192136 | M Kolmann                                                                                                                                                             |
| 321 |    320.951769 |    301.227457 | Gareth Monger                                                                                                                                                         |
| 322 |    415.744828 |    588.654682 | Michael Scroggie                                                                                                                                                      |
| 323 |    335.117283 |    383.083041 | T. Michael Keesey                                                                                                                                                     |
| 324 |    763.563830 |    406.715834 | Félix Landry Yuan                                                                                                                                                     |
| 325 |     51.934340 |    545.144875 | Zimices                                                                                                                                                               |
| 326 |     39.975247 |    700.065536 | Gareth Monger                                                                                                                                                         |
| 327 |    133.791775 |    479.540967 | Zimices                                                                                                                                                               |
| 328 |    602.553975 |    407.215892 | Sarah Werning                                                                                                                                                         |
| 329 |    244.936682 |    609.982206 | Emily Willoughby                                                                                                                                                      |
| 330 |    646.636233 |    104.744642 | Jay Matternes (vectorized by T. Michael Keesey)                                                                                                                       |
| 331 |    221.807244 |    221.152412 | Kai R. Caspar                                                                                                                                                         |
| 332 |    724.147776 |    734.578688 | Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus                                              |
| 333 |    193.643753 |    648.282583 | Michelle Site                                                                                                                                                         |
| 334 |    168.538572 |    254.683388 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 335 |    238.192934 |    581.620800 | Michael Scroggie                                                                                                                                                      |
| 336 |    230.394967 |    572.417586 | T. Michael Keesey                                                                                                                                                     |
| 337 |    808.217729 |    463.425640 | Luc Viatour (source photo) and Andreas Plank                                                                                                                          |
| 338 |    740.274356 |    470.399983 | Jordan Mallon (vectorized by T. Michael Keesey)                                                                                                                       |
| 339 |    541.758183 |    352.995453 | Matt Crook                                                                                                                                                            |
| 340 |    845.675906 |    763.293152 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 341 |    254.821930 |    656.735611 | Steven Traver                                                                                                                                                         |
| 342 |    457.484125 |    674.369716 | Birgit Lang                                                                                                                                                           |
| 343 |     72.458281 |    784.528358 | Jaime Headden                                                                                                                                                         |
| 344 |    842.726101 |    289.324771 | Emily Willoughby                                                                                                                                                      |
| 345 |    278.066771 |    651.886812 | Farelli (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
| 346 |    251.519426 |    163.714098 | Owen Jones                                                                                                                                                            |
| 347 |    441.291701 |    440.481567 | Jagged Fang Designs                                                                                                                                                   |
| 348 |    320.743330 |    259.114030 | Shyamal                                                                                                                                                               |
| 349 |    624.475781 |    156.787825 | Chris huh                                                                                                                                                             |
| 350 |    774.841655 |    717.408156 | Dmitry Bogdanov                                                                                                                                                       |
| 351 |    681.833250 |    796.072224 | T. Michael Keesey                                                                                                                                                     |
| 352 |    306.562748 |     50.885617 | Anthony Caravaggi                                                                                                                                                     |
| 353 |    957.500672 |    414.366304 | Iain Reid                                                                                                                                                             |
| 354 |    203.228709 |    444.132500 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 355 |     15.594334 |    265.237510 | Scott Hartman                                                                                                                                                         |
| 356 |    259.863605 |    210.941630 | Arthur S. Brum                                                                                                                                                        |
| 357 |    192.266512 |     86.678686 | NA                                                                                                                                                                    |
| 358 |    722.183056 |     35.789210 | Matt Crook                                                                                                                                                            |
| 359 |   1013.878173 |    768.932471 | T. Michael Keesey                                                                                                                                                     |
| 360 |    691.476349 |    723.193573 | Milton Tan                                                                                                                                                            |
| 361 |    725.572893 |    186.644134 | Birgit Szabo                                                                                                                                                          |
| 362 |    457.415380 |    747.646875 | Tasman Dixon                                                                                                                                                          |
| 363 |    927.440966 |    518.403632 | Tyler Greenfield                                                                                                                                                      |
| 364 |     21.298663 |    635.125648 | JCGiron                                                                                                                                                               |
| 365 |     41.935693 |    759.228197 | Zimices                                                                                                                                                               |
| 366 |     52.664679 |    686.114773 | Nobu Tamura                                                                                                                                                           |
| 367 |    501.180682 |    542.020848 | Gareth Monger                                                                                                                                                         |
| 368 |    477.917114 |    707.240676 | Darren Naish, Nemo, and T. Michael Keesey                                                                                                                             |
| 369 |     46.181444 |    111.235112 | Markus A. Grohme                                                                                                                                                      |
| 370 |    609.298041 |    152.104323 | Tasman Dixon                                                                                                                                                          |
| 371 |    597.212678 |    371.939905 | T. Michael Keesey                                                                                                                                                     |
| 372 |    354.663533 |    527.290550 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                        |
| 373 |    248.166224 |     26.672130 | Steven Traver                                                                                                                                                         |
| 374 |    298.246304 |    759.784153 | Kanako Bessho-Uehara                                                                                                                                                  |
| 375 |    360.264541 |    685.695782 | S.Martini                                                                                                                                                             |
| 376 |    828.325565 |     60.166506 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 377 |    365.552396 |    344.923487 | Mali’o Kodis, photograph by “Wildcat Dunny” (<http://www.flickr.com/people/wildcat_dunny/>)                                                                           |
| 378 |    106.387736 |    495.857138 | Stuart Humphries                                                                                                                                                      |
| 379 |    643.961199 |    757.561704 | Margot Michaud                                                                                                                                                        |
| 380 |    629.614703 |    288.094221 | Noah Schlottman                                                                                                                                                       |
| 381 |    559.340455 |    752.762890 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                           |
| 382 |    568.223473 |    425.935846 | Gareth Monger                                                                                                                                                         |
| 383 |   1014.896513 |    612.546215 | Ferran Sayol                                                                                                                                                          |
| 384 |    880.603792 |    129.191239 | Ville-Veikko Sinkkonen                                                                                                                                                |
| 385 |    884.055587 |    255.849846 | NA                                                                                                                                                                    |
| 386 |    795.409623 |    581.263246 | Mariana Ruiz (vectorized by T. Michael Keesey)                                                                                                                        |
| 387 |    364.384527 |    562.489233 | Tomas Willems (vectorized by T. Michael Keesey)                                                                                                                       |
| 388 |    589.698991 |    399.229257 | Chloé Schmidt                                                                                                                                                         |
| 389 |    198.854742 |    641.611877 | Steven Traver                                                                                                                                                         |
| 390 |     27.533778 |    385.891238 | NA                                                                                                                                                                    |
| 391 |    996.832483 |     74.295360 | Ferran Sayol                                                                                                                                                          |
| 392 |    606.243294 |    196.794063 | Natasha Vitek                                                                                                                                                         |
| 393 |    969.436228 |      6.924198 | T. Michael Keesey                                                                                                                                                     |
| 394 |    675.155286 |    739.865754 | Becky Barnes                                                                                                                                                          |
| 395 |    622.008998 |     79.968414 | Margot Michaud                                                                                                                                                        |
| 396 |    987.116955 |    530.319910 | Steven Traver                                                                                                                                                         |
| 397 |   1005.725066 |    556.543068 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 398 |    731.781665 |    330.797539 | Margot Michaud                                                                                                                                                        |
| 399 |    781.639214 |    598.778752 | Katie S. Collins                                                                                                                                                      |
| 400 |    505.855113 |    197.378578 | Matt Crook                                                                                                                                                            |
| 401 |    553.894956 |    506.992151 | NA                                                                                                                                                                    |
| 402 |    220.579238 |    639.034732 | NA                                                                                                                                                                    |
| 403 |     80.966181 |    413.564607 | Matt Dempsey                                                                                                                                                          |
| 404 |    731.803368 |    252.651535 | Scott Hartman                                                                                                                                                         |
| 405 |    718.605046 |    194.816725 | Martin R. Smith                                                                                                                                                       |
| 406 |    868.538638 |    724.044244 | NA                                                                                                                                                                    |
| 407 |    933.098702 |    732.272703 | Zimices                                                                                                                                                               |
| 408 |    290.661705 |    578.550093 | Matt Crook                                                                                                                                                            |
| 409 |    530.885131 |    647.636985 | Zimices                                                                                                                                                               |
| 410 |    999.834087 |    326.561450 | Margot Michaud                                                                                                                                                        |
| 411 |    975.219241 |    476.759269 | FunkMonk                                                                                                                                                              |
| 412 |    773.099070 |    171.522517 | Christoph Schomburg                                                                                                                                                   |
| 413 |    481.647000 |    647.043688 | T. Michael Keesey                                                                                                                                                     |
| 414 |    931.353723 |    474.711737 | Tyler Greenfield                                                                                                                                                      |
| 415 |     25.161339 |    343.776866 | Chuanixn Yu                                                                                                                                                           |
| 416 |     18.202852 |    260.675553 | Joanna Wolfe                                                                                                                                                          |
| 417 |    159.846088 |    505.881769 | Jerry Oldenettel (vectorized by T. Michael Keesey)                                                                                                                    |
| 418 |    580.051154 |    792.128785 | Matt Crook                                                                                                                                                            |
| 419 |    741.782468 |    550.587886 | Michelle Site                                                                                                                                                         |
| 420 |    757.233976 |    191.964542 | Mattia Menchetti                                                                                                                                                      |
| 421 |    250.638310 |    252.959593 | NA                                                                                                                                                                    |
| 422 |     18.257678 |    578.651131 | Kanako Bessho-Uehara                                                                                                                                                  |
| 423 |    784.418039 |    157.602012 | Geoff Shaw                                                                                                                                                            |
| 424 |    884.044693 |    503.130192 | Zimices                                                                                                                                                               |
| 425 |    149.447130 |    538.756225 | Gareth Monger                                                                                                                                                         |
| 426 |    508.011793 |    169.051050 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                                        |
| 427 |    299.734743 |    337.760659 | Milton Tan                                                                                                                                                            |
| 428 |    657.815224 |    125.682004 | Oscar Sanisidro                                                                                                                                                       |
| 429 |    231.273505 |    173.454421 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 430 |    507.806783 |    319.404794 | Ignacio Contreras                                                                                                                                                     |
| 431 |    498.805407 |    756.206270 | Gareth Monger                                                                                                                                                         |
| 432 |    847.469620 |    711.585900 | Lauren Anderson                                                                                                                                                       |
| 433 |     25.836250 |    433.483631 | L. Shyamal                                                                                                                                                            |
| 434 |    230.247761 |    793.386586 | Matt Hayes                                                                                                                                                            |
| 435 |    997.115322 |    697.300455 | Gareth Monger                                                                                                                                                         |
| 436 |      8.602739 |    707.292245 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 437 |    430.142196 |    492.282155 | Roberto Díaz Sibaja                                                                                                                                                   |
| 438 |    533.660060 |      7.072841 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 439 |    960.523449 |    425.014902 | Emily Willoughby                                                                                                                                                      |
| 440 |    793.112118 |    783.169398 | Rachel Shoop                                                                                                                                                          |
| 441 |    432.955837 |    373.591518 | Mali’o Kodis, image from the Smithsonian Institution                                                                                                                  |
| 442 |    627.290420 |    760.893713 | Matt Crook                                                                                                                                                            |
| 443 |    381.492739 |    101.919432 | NA                                                                                                                                                                    |
| 444 |    639.451319 |    707.824737 | Ferran Sayol                                                                                                                                                          |
| 445 |    398.011242 |     39.622082 | Gareth Monger                                                                                                                                                         |
| 446 |     47.354242 |    628.693884 | Mathieu Basille                                                                                                                                                       |
| 447 |    967.309484 |    525.348554 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 448 |    205.526908 |     96.818449 | Sharon Wegner-Larsen                                                                                                                                                  |
| 449 |    139.727141 |    215.225820 | Scott Hartman                                                                                                                                                         |
| 450 |   1007.691843 |    485.821152 | Gareth Monger                                                                                                                                                         |
| 451 |    719.177256 |    716.811532 | Gareth Monger                                                                                                                                                         |
| 452 |    363.183650 |     58.356317 | Rebecca Groom                                                                                                                                                         |
| 453 |    246.583116 |    795.047780 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 454 |    717.322034 |     65.550121 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 455 |    420.015737 |    321.966566 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 456 |    995.812681 |    298.487303 | Michelle Site                                                                                                                                                         |
| 457 |    601.642428 |    765.074875 | Chris huh                                                                                                                                                             |
| 458 |    427.710082 |    390.041106 | Baheerathan Murugavel                                                                                                                                                 |
| 459 |    609.595685 |    509.124107 | Duane Raver (vectorized by T. Michael Keesey)                                                                                                                         |
| 460 |   1017.229006 |    599.635098 | Michael Scroggie                                                                                                                                                      |
| 461 |    638.952596 |    248.407243 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                                |
| 462 |    791.518572 |    454.548079 | L. Shyamal                                                                                                                                                            |
| 463 |    725.906669 |    279.485165 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 464 |    237.468401 |    647.704180 | Michelle Site                                                                                                                                                         |
| 465 |    555.251978 |    119.784567 | Yan Wong                                                                                                                                                              |
| 466 |    183.335615 |    583.774141 | NA                                                                                                                                                                    |
| 467 |    807.410272 |    640.638094 | Matt Crook                                                                                                                                                            |
| 468 |     45.697397 |     18.985025 | Dean Schnabel                                                                                                                                                         |
| 469 |    735.718963 |    267.764137 | Gareth Monger                                                                                                                                                         |
| 470 |    503.732333 |    611.034067 | Matt Crook                                                                                                                                                            |
| 471 |   1015.848736 |    526.590800 | Steven Traver                                                                                                                                                         |
| 472 |    575.781856 |    705.426369 | Gareth Monger                                                                                                                                                         |
| 473 |    575.376379 |    643.153608 | Matt Crook                                                                                                                                                            |
| 474 |    598.731068 |    162.429095 | NA                                                                                                                                                                    |
| 475 |    119.927196 |    134.409146 | Tracy A. Heath                                                                                                                                                        |
| 476 |    456.046011 |    289.210693 | Matt Crook                                                                                                                                                            |
| 477 |     11.219375 |    499.609926 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 478 |    150.895138 |    786.248602 | Yan Wong                                                                                                                                                              |
| 479 |    936.096096 |    312.321202 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 480 |    535.275731 |    680.253164 | Jessica Anne Miller                                                                                                                                                   |
| 481 |    539.569095 |    139.225974 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 482 |    582.738610 |    375.814942 | Mathilde Cordellier                                                                                                                                                   |
| 483 |    631.720429 |    487.425697 | T. Michael Keesey                                                                                                                                                     |
| 484 |    110.907617 |    487.261297 | Mathilde Cordellier                                                                                                                                                   |
| 485 |    466.960295 |     31.259515 | Zimices                                                                                                                                                               |
| 486 |     70.632866 |      4.078380 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 487 |    943.712379 |    344.289838 | T. Michael Keesey (after Tillyard)                                                                                                                                    |
| 488 |    101.865519 |    126.308232 | Jaime Headden                                                                                                                                                         |
| 489 |    525.746269 |    232.005600 | Smith609 and T. Michael Keesey                                                                                                                                        |
| 490 |    462.646588 |     48.006070 | Tracy A. Heath                                                                                                                                                        |
| 491 |    785.880806 |    631.213703 | T. Michael Keesey (photo by Sean Mack)                                                                                                                                |
| 492 |    290.178660 |     65.365206 | Stephen O’Connor (vectorized by T. Michael Keesey)                                                                                                                    |
| 493 |    974.609981 |    757.730490 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                          |
| 494 |   1000.679017 |    530.411508 | NA                                                                                                                                                                    |
| 495 |    991.988852 |     60.660950 | Matt Crook                                                                                                                                                            |
| 496 |    867.547314 |    760.246819 | Steven Traver                                                                                                                                                         |
| 497 |    119.023685 |    159.638835 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                                     |
| 498 |    146.638341 |      4.946315 | Shyamal                                                                                                                                                               |
| 499 |    971.720880 |    560.519956 | FunkMonk                                                                                                                                                              |
| 500 |    107.931944 |    336.492923 | Kent Elson Sorgon                                                                                                                                                     |
| 501 |    223.052459 |     94.999275 | NA                                                                                                                                                                    |
| 502 |    792.691776 |     64.626431 | L. Shyamal                                                                                                                                                            |
| 503 |    329.054632 |     12.655283 | Beth Reinke                                                                                                                                                           |
| 504 |    266.908943 |    772.379126 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 505 |     74.479098 |     27.845009 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 506 |    824.543249 |     10.445595 | Chris huh                                                                                                                                                             |
| 507 |    260.799721 |    380.199218 | Steven Traver                                                                                                                                                         |
| 508 |     12.985304 |    699.194139 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 509 |    125.347452 |    511.046736 | Ignacio Contreras                                                                                                                                                     |
| 510 |    413.169752 |      9.872717 | Michael Scroggie                                                                                                                                                      |
| 511 |    431.230267 |    290.309978 | NASA                                                                                                                                                                  |
| 512 |    589.110898 |    494.630906 | M Hutchinson                                                                                                                                                          |
| 513 |    604.107373 |    700.561776 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 514 |    742.037818 |    538.860146 | Noah Schlottman, photo by Martin V. Sørensen                                                                                                                          |
| 515 |    755.634863 |    499.895604 | Michelle Site                                                                                                                                                         |
| 516 |    899.697688 |    617.229708 | Matt Crook                                                                                                                                                            |
| 517 |    801.969310 |    619.710269 | Matt Crook                                                                                                                                                            |
| 518 |    524.594424 |    157.126817 | Peter Coxhead                                                                                                                                                         |
| 519 |    106.321671 |    651.696430 | Michael Scroggie                                                                                                                                                      |
| 520 |    257.588404 |    643.422988 | Sherman F. Denton via rawpixel.com (illustration) and Timothy J. Bartley (silhouette)                                                                                 |
| 521 |     39.624489 |    510.879544 | NA                                                                                                                                                                    |
| 522 |    848.840994 |     61.072711 | Gareth Monger                                                                                                                                                         |
| 523 |    405.155275 |    327.275059 | Ferran Sayol                                                                                                                                                          |
| 524 |    474.062841 |      3.947527 | Tasman Dixon                                                                                                                                                          |
| 525 |    611.365276 |    373.212184 | Birgit Lang                                                                                                                                                           |
| 526 |    612.056355 |     83.636668 | Smokeybjb (modified by T. Michael Keesey)                                                                                                                             |
| 527 |    982.126834 |    607.384643 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 528 |    289.547362 |    194.700401 | Rebecca Groom (Based on Photo by Andreas Trepte)                                                                                                                      |
| 529 |    382.398864 |    147.591914 | Jagged Fang Designs                                                                                                                                                   |
| 530 |    751.534901 |     73.208079 | Zimices                                                                                                                                                               |
| 531 |    131.279437 |    535.512044 | Sarah Werning                                                                                                                                                         |
| 532 |    637.477419 |    404.256350 | Chris huh                                                                                                                                                             |
| 533 |    862.246581 |    621.689394 | NA                                                                                                                                                                    |
| 534 |    130.835906 |    240.467854 | Antonov (vectorized by T. Michael Keesey)                                                                                                                             |
| 535 |    532.512317 |    168.661712 | Joanna Wolfe                                                                                                                                                          |
| 536 |    991.679025 |    484.474101 | T. Michael Keesey                                                                                                                                                     |
| 537 |    546.521050 |    649.136934 | Michael Scroggie                                                                                                                                                      |
| 538 |    422.533306 |    303.956489 | Margot Michaud                                                                                                                                                        |
| 539 |    140.465462 |     16.690389 | NA                                                                                                                                                                    |
| 540 |    962.066221 |    613.029894 | Matt Crook                                                                                                                                                            |
| 541 |    681.976447 |    702.784665 | Kimberly Haddrell                                                                                                                                                     |
| 542 |    637.827323 |    253.580907 | nicubunu                                                                                                                                                              |
| 543 |    419.933063 |    454.162690 | V. Deepak                                                                                                                                                             |
| 544 |    762.105756 |    322.449085 | nicubunu                                                                                                                                                              |
| 545 |    364.884269 |    673.499288 | Gareth Monger                                                                                                                                                         |
| 546 |    936.675632 |    607.942974 | Andrew A. Farke, shell lines added by Yan Wong                                                                                                                        |
| 547 |    355.979662 |    789.320812 | Sharon Wegner-Larsen                                                                                                                                                  |
| 548 |    999.766509 |    737.872528 | Ferran Sayol                                                                                                                                                          |
| 549 |    286.300169 |    471.272823 | Steven Traver                                                                                                                                                         |
| 550 |    876.877608 |    178.807592 | Gareth Monger                                                                                                                                                         |
| 551 |    851.420701 |    164.370955 | Lukasiniho                                                                                                                                                            |
| 552 |    346.390383 |    559.856986 | Mattia Menchetti                                                                                                                                                      |
| 553 |    906.946527 |    586.701820 | Dmitry Bogdanov (modified by T. Michael Keesey)                                                                                                                       |
| 554 |    325.920877 |    291.004152 | Xavier Giroux-Bougard                                                                                                                                                 |
| 555 |    233.959451 |    390.175187 | Martin R. Smith, after Skovsted et al 2015                                                                                                                            |
| 556 |    892.220023 |    282.628241 | Collin Gross                                                                                                                                                          |
| 557 |     46.716249 |    591.953899 | Zimices                                                                                                                                                               |
| 558 |    105.414647 |    388.466858 | Christoph Schomburg                                                                                                                                                   |
| 559 |    365.478510 |    355.179182 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                                     |
| 560 |    109.321016 |    784.947307 | T. Michael Keesey                                                                                                                                                     |
| 561 |    746.416280 |    463.288777 | NA                                                                                                                                                                    |
| 562 |    660.844756 |    582.520879 | Tauana J. Cunha                                                                                                                                                       |
| 563 |    737.454161 |     10.672171 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 564 |    117.686421 |    758.911978 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 565 |    221.263367 |     43.450258 | Maha Ghazal                                                                                                                                                           |
| 566 |    142.166926 |    220.690602 | kotik                                                                                                                                                                 |
| 567 |    242.591967 |    734.608434 | Zimices                                                                                                                                                               |
| 568 |    247.621828 |    333.770181 | Anthony Caravaggi                                                                                                                                                     |
| 569 |    787.489280 |    393.097495 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 570 |    167.188147 |    757.678856 | Mario Quevedo                                                                                                                                                         |
| 571 |    585.512974 |    186.361877 | Roberto Diaz Sibaja, based on Domser                                                                                                                                  |
| 572 |    513.886730 |    737.494382 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 573 |    419.672579 |    466.168612 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 574 |    641.494132 |    205.242448 | Matt Crook                                                                                                                                                            |
| 575 |    807.527970 |    605.627091 | Yan Wong                                                                                                                                                              |
| 576 |    929.509436 |    268.866365 | Mathew Wedel                                                                                                                                                          |
| 577 |    949.719388 |    356.857070 | Matt Crook                                                                                                                                                            |
| 578 |    509.776150 |    751.271444 | T. Michael Keesey                                                                                                                                                     |
| 579 |    429.957865 |     97.900175 | Pete Buchholz                                                                                                                                                         |
| 580 |    641.885794 |    513.585896 | Shyamal                                                                                                                                                               |
| 581 |    959.153664 |     56.121487 | Gareth Monger                                                                                                                                                         |
| 582 |    409.420917 |    147.669031 | Margot Michaud                                                                                                                                                        |
| 583 |    751.261249 |    340.735274 | Kai R. Caspar                                                                                                                                                         |
| 584 |    722.173751 |    481.086393 | T. Michael Keesey                                                                                                                                                     |
| 585 |    212.804442 |    119.104124 | Mathew Wedel                                                                                                                                                          |
| 586 |    669.301667 |    554.221288 | Frank Förster (based on a picture by Hans Hillewaert)                                                                                                                 |
| 587 |    277.485389 |     82.396851 | V. Deepak                                                                                                                                                             |
| 588 |    332.040352 |    496.465318 | T. Michael Keesey                                                                                                                                                     |
| 589 |    454.399947 |     63.863031 | Gareth Monger                                                                                                                                                         |
| 590 |    619.818494 |    165.529290 | Margot Michaud                                                                                                                                                        |
| 591 |    535.959232 |    198.891949 | Steven Traver                                                                                                                                                         |
| 592 |    823.502402 |    252.974600 | Ferran Sayol                                                                                                                                                          |
| 593 |    670.840020 |    364.823140 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 594 |    126.701765 |    529.188972 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 595 |    658.501739 |    712.394645 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 596 |    954.161032 |    627.464295 | Matt Crook                                                                                                                                                            |
| 597 |    761.804040 |    280.328891 | Kenneth Lacovara (vectorized by T. Michael Keesey)                                                                                                                    |
| 598 |    428.735645 |    431.987959 | NA                                                                                                                                                                    |
| 599 |    841.394124 |    357.977183 | Jagged Fang Designs                                                                                                                                                   |
| 600 |    868.643167 |    692.035383 | Chloé Schmidt                                                                                                                                                         |
| 601 |    639.972628 |    124.282351 | Margot Michaud                                                                                                                                                        |
| 602 |    246.158583 |    630.498221 | Zimices                                                                                                                                                               |
| 603 |     38.715673 |    298.113262 | Michelle Site                                                                                                                                                         |
| 604 |    343.097384 |    378.925840 | Felix Vaux                                                                                                                                                            |
| 605 |    682.231392 |    141.944426 | Inessa Voet                                                                                                                                                           |
| 606 |    213.038527 |     30.925875 | Zimices                                                                                                                                                               |
| 607 |    582.161952 |    483.348675 | Margot Michaud                                                                                                                                                        |
| 608 |    397.760969 |    355.289359 | Matt Hayes                                                                                                                                                            |
| 609 |    976.346328 |    338.056949 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 610 |    772.759311 |    216.864538 | Arthur S. Brum                                                                                                                                                        |
| 611 |    516.163306 |    588.222503 | Ferran Sayol                                                                                                                                                          |
| 612 |    988.443160 |    283.262214 | Crystal Maier                                                                                                                                                         |
| 613 |     57.963606 |    471.896919 | Margot Michaud                                                                                                                                                        |
| 614 |    942.115507 |    424.531107 | Harold N Eyster                                                                                                                                                       |
| 615 |     12.045016 |    197.402527 | NA                                                                                                                                                                    |
| 616 |    647.345555 |    301.296380 | Kailah Thorn & Ben King                                                                                                                                               |
| 617 |    111.707086 |    669.152019 | Mark Witton                                                                                                                                                           |
| 618 |    503.955319 |    265.259840 | Beth Reinke                                                                                                                                                           |
| 619 |    532.135033 |    348.460861 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 620 |    780.343824 |    790.019047 | V. Deepak                                                                                                                                                             |
| 621 |    267.569521 |    223.788857 | Javier Luque                                                                                                                                                          |
| 622 |    270.442307 |     28.780118 | NA                                                                                                                                                                    |
| 623 |    190.895548 |     69.539669 | Crystal Maier                                                                                                                                                         |
| 624 |    502.833168 |    663.973921 | Zimices                                                                                                                                                               |
| 625 |    355.989209 |    568.487348 | Sarah Werning                                                                                                                                                         |
| 626 |    398.759639 |    583.266189 | Michele M Tobias from an image By Dcrjsr - Own work, CC BY 3.0, <https://commons.wikimedia.org/w/index.php?curid=18059686>                                            |
| 627 |    934.244340 |    467.332225 | Melissa Broussard                                                                                                                                                     |
| 628 |    480.535856 |    286.167187 | NA                                                                                                                                                                    |
| 629 |    715.575783 |    463.307366 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 630 |    434.676707 |    278.272348 | Arthur Weasley (vectorized by T. Michael Keesey)                                                                                                                      |
| 631 |    719.118582 |     76.618813 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 632 |    588.017273 |    346.959115 | Steven Traver                                                                                                                                                         |
| 633 |    134.243052 |     28.612422 | Stephen O’Connor (vectorized by T. Michael Keesey)                                                                                                                    |
| 634 |    141.378243 |    173.597155 | T. Michael Keesey                                                                                                                                                     |
| 635 |    934.326963 |      3.764309 | Mathieu Basille                                                                                                                                                       |
| 636 |    177.545250 |    136.806090 | Tracy A. Heath                                                                                                                                                        |
| 637 |    635.994191 |    357.972154 | Gareth Monger                                                                                                                                                         |
| 638 |    387.675232 |    552.579307 | Rebecca Groom                                                                                                                                                         |
| 639 |    957.266084 |    297.031896 | Felix Vaux                                                                                                                                                            |
| 640 |    648.912911 |    738.639666 | Ferran Sayol                                                                                                                                                          |
| 641 |    451.609831 |    394.303426 | Ferran Sayol                                                                                                                                                          |
| 642 |    304.123823 |    361.129928 | Burton Robert, USFWS                                                                                                                                                  |
| 643 |    608.685491 |    493.930804 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 644 |    786.534699 |    542.465854 | Zimices                                                                                                                                                               |
| 645 |    463.512272 |    650.976122 | Noah Schlottman, photo by Carol Cummings                                                                                                                              |
| 646 |    346.753601 |    576.370226 | Michael Scroggie                                                                                                                                                      |
| 647 |    288.621503 |    348.309018 | Matt Crook                                                                                                                                                            |
| 648 |    864.785297 |    130.811503 | Andrew A. Farke                                                                                                                                                       |
| 649 |    104.265594 |     14.423888 | Becky Barnes                                                                                                                                                          |
| 650 |    736.779716 |    615.540380 | Dori <dori@merr.info> (source photo) and Nevit Dilmen                                                                                                                 |
| 651 |     63.310656 |    597.549530 | Siobhon Egan                                                                                                                                                          |
| 652 |   1015.065868 |     34.620161 | Isaure Scavezzoni                                                                                                                                                     |
| 653 |      6.853967 |    413.924667 | Gareth Monger                                                                                                                                                         |
| 654 |     78.690515 |     45.267808 | NA                                                                                                                                                                    |
| 655 |    642.602174 |    221.083882 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 656 |    851.981867 |    443.761158 | Zimices                                                                                                                                                               |
| 657 |    359.404454 |    499.036346 | Michelle Site                                                                                                                                                         |
| 658 |      9.071725 |    303.278721 | Zimices                                                                                                                                                               |
| 659 |    948.513075 |    283.898580 | Kamil S. Jaron                                                                                                                                                        |
| 660 |    762.346456 |    273.977754 | Emily Willoughby                                                                                                                                                      |
| 661 |    844.085342 |    794.599143 | Maija Karala                                                                                                                                                          |
| 662 |    696.300906 |    477.641225 | Matt Crook                                                                                                                                                            |
| 663 |    597.959177 |    230.459131 | Margot Michaud                                                                                                                                                        |
| 664 |    569.258538 |    452.964995 | Matt Crook                                                                                                                                                            |
| 665 |    341.487479 |    604.546869 | Chris huh                                                                                                                                                             |
| 666 |    351.681211 |    187.406387 | Ingo Braasch                                                                                                                                                          |
| 667 |    585.807177 |    681.875015 | Chuanixn Yu                                                                                                                                                           |
| 668 |     27.490862 |    473.796350 | Shyamal                                                                                                                                                               |
| 669 |    976.641402 |    291.083318 | T. Michael Keesey                                                                                                                                                     |
| 670 |    822.327913 |    273.471431 | Scott Hartman                                                                                                                                                         |
| 671 |    512.841580 |    147.884978 | Matt Crook                                                                                                                                                            |
| 672 |   1015.985068 |    512.804814 | Jagged Fang Designs                                                                                                                                                   |
| 673 |    696.891907 |    705.771218 | Gareth Monger                                                                                                                                                         |
| 674 |    499.396011 |    285.273866 | Mali’o Kodis, photograph by Aqua-Photos (<http://www.flickr.com/people/undervannsfotografen/>)                                                                        |
| 675 |    632.416822 |    240.467546 | Matt Crook                                                                                                                                                            |
| 676 |     19.253558 |     90.184631 | Christine Axon                                                                                                                                                        |
| 677 |     32.928843 |    453.427195 | Alexandre Vong                                                                                                                                                        |
| 678 |    423.475533 |    614.675216 | Mike Hanson                                                                                                                                                           |
| 679 |    695.275572 |     73.609439 | Chris huh                                                                                                                                                             |
| 680 |    715.676228 |    264.463787 | Zimices                                                                                                                                                               |
| 681 |    181.767168 |    424.571855 | Margot Michaud                                                                                                                                                        |
| 682 |     74.499435 |    698.550990 | Chuanixn Yu                                                                                                                                                           |
| 683 |      4.452312 |    378.644085 | Armin Reindl                                                                                                                                                          |
| 684 |    164.167655 |    235.362543 | Ignacio Contreras                                                                                                                                                     |
| 685 |    224.453277 |    369.155667 | Anthony Caravaggi                                                                                                                                                     |
| 686 |    245.321747 |    438.963754 | Michael Scroggie, from original photograph by Gary M. Stolz, USFWS (original photograph in public domain).                                                            |
| 687 |    359.858879 |    450.646888 | Andrew A. Farke                                                                                                                                                       |
| 688 |    876.459452 |    110.073031 | Jagged Fang Designs                                                                                                                                                   |
| 689 |    211.144052 |    794.923331 | Margot Michaud                                                                                                                                                        |
| 690 |    848.260350 |    367.165216 | Catherine Yasuda                                                                                                                                                      |
| 691 |    362.373578 |    100.136253 | Dean Schnabel                                                                                                                                                         |
| 692 |    698.391986 |    150.451655 | Lindberg (vectorized by T. Michael Keesey)                                                                                                                            |
| 693 |    939.951983 |    723.201873 | Davidson Sodré                                                                                                                                                        |
| 694 |    811.306239 |    182.192561 | Scott Hartman                                                                                                                                                         |
| 695 |    450.001348 |    656.185579 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 696 |    169.753398 |     91.418513 | Matt Crook                                                                                                                                                            |
| 697 |    469.534849 |    149.696676 | Ieuan Jones                                                                                                                                                           |
| 698 |    954.709025 |    734.727862 | Jagged Fang Designs                                                                                                                                                   |
| 699 |    830.862812 |    548.181967 | Peileppe                                                                                                                                                              |
| 700 |    736.037541 |    664.668969 | Kailah Thorn & Mark Hutchinson                                                                                                                                        |
| 701 |    782.860226 |    609.940443 | NA                                                                                                                                                                    |
| 702 |    714.251330 |    412.820685 | Jagged Fang Designs                                                                                                                                                   |
| 703 |    728.841796 |    244.224953 | Margot Michaud                                                                                                                                                        |
| 704 |     14.094746 |    436.234540 | Margot Michaud                                                                                                                                                        |
| 705 |    773.871812 |     93.100794 | Sarah Werning                                                                                                                                                         |
| 706 |    735.197742 |    102.030167 | NA                                                                                                                                                                    |
| 707 |    930.624601 |    362.179887 | Julio Garza                                                                                                                                                           |
| 708 |    463.642493 |    758.105510 | Shyamal                                                                                                                                                               |
| 709 |    286.986584 |    646.452940 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 710 |    550.775669 |    223.022108 | Joanna Wolfe                                                                                                                                                          |
| 711 |    700.392482 |    468.662441 | Ieuan Jones                                                                                                                                                           |
| 712 |    179.480838 |    648.202420 | Kosta Mumcuoglu (vectorized by T. Michael Keesey)                                                                                                                     |
| 713 |    270.252011 |    572.064279 | T. Michael Keesey                                                                                                                                                     |
| 714 |    597.040579 |     73.781078 | Chase Brownstein                                                                                                                                                      |
| 715 |    256.279044 |    670.626357 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 716 |   1012.820840 |    129.622596 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                                |
| 717 |     35.454783 |    789.043396 | Karla Martinez                                                                                                                                                        |
| 718 |    552.438949 |    708.733727 | Renato de Carvalho Ferreira                                                                                                                                           |
| 719 |    380.801165 |    783.596191 | NA                                                                                                                                                                    |
| 720 |     80.117103 |    705.235589 | Matt Crook                                                                                                                                                            |
| 721 |    965.945847 |    637.633422 | Chris huh                                                                                                                                                             |
| 722 |    981.993003 |    626.715940 | Milton Tan                                                                                                                                                            |
| 723 |     14.948446 |    666.162717 | Steven Traver                                                                                                                                                         |
| 724 |    311.173420 |     82.395452 | Maija Karala                                                                                                                                                          |
| 725 |    398.550560 |    109.966173 | Michael Scroggie                                                                                                                                                      |
| 726 |    367.755001 |    181.037536 | Terpsichores                                                                                                                                                          |
| 727 |    195.732431 |    119.637177 | Jaime Headden                                                                                                                                                         |
| 728 |     48.133360 |    524.245749 | Gareth Monger                                                                                                                                                         |
| 729 |    228.832488 |    114.292444 | Margot Michaud                                                                                                                                                        |
| 730 |    968.592370 |    277.632223 | Scott Reid                                                                                                                                                            |
| 731 |     62.916330 |    503.825457 | Julio Garza                                                                                                                                                           |
| 732 |    879.825174 |    789.262096 | NA                                                                                                                                                                    |
| 733 |    412.094845 |     38.279693 | Jagged Fang Designs                                                                                                                                                   |
| 734 |    148.466816 |    249.612249 | Michael Scroggie                                                                                                                                                      |
| 735 |     91.670025 |    490.533310 | Chloé Schmidt                                                                                                                                                         |
| 736 |    902.828386 |    637.740614 | Zimices                                                                                                                                                               |
| 737 |     10.160835 |    450.371019 | Tasman Dixon                                                                                                                                                          |
| 738 |    577.515446 |    111.620373 | Sarah Werning                                                                                                                                                         |
| 739 |    904.375626 |    370.944646 | Jack Mayer Wood                                                                                                                                                       |
| 740 |    178.486057 |    118.883766 | Kanako Bessho-Uehara                                                                                                                                                  |
| 741 |    225.487695 |    755.294048 | Scott Hartman                                                                                                                                                         |
| 742 |    876.218976 |    643.981531 | Ferran Sayol                                                                                                                                                          |
| 743 |    850.314167 |    642.512624 | Gareth Monger                                                                                                                                                         |
| 744 |      9.028262 |    269.080459 | xgirouxb                                                                                                                                                              |
| 745 |     28.745962 |    484.024571 | NA                                                                                                                                                                    |
| 746 |    444.820147 |     44.860482 | Sarah Werning                                                                                                                                                         |
| 747 |    686.551752 |    759.865389 | Chris huh                                                                                                                                                             |
| 748 |    212.888869 |    445.366022 | Zimices                                                                                                                                                               |
| 749 |    652.875581 |    543.795399 | Ferran Sayol                                                                                                                                                          |
| 750 |    855.954929 |    470.811628 | T. Michael Keesey                                                                                                                                                     |
| 751 |    255.219793 |    395.350035 | Matt Crook                                                                                                                                                            |
| 752 |    320.699930 |    177.900948 | Dean Schnabel                                                                                                                                                         |
| 753 |   1015.276607 |     53.019945 | Gareth Monger                                                                                                                                                         |
| 754 |    696.128618 |    337.373867 | FunkMonk (Michael B.H.; vectorized by T. Michael Keesey)                                                                                                              |
| 755 |    997.774193 |    679.522739 | Emily Willoughby                                                                                                                                                      |
| 756 |     76.962983 |    464.674546 | Tauana J. Cunha                                                                                                                                                       |
| 757 |    759.774920 |     99.583913 | T. Michael Keesey                                                                                                                                                     |
| 758 |    522.895024 |    131.625844 | T. Michael Keesey                                                                                                                                                     |
| 759 |    961.399489 |    746.554212 | Matt Crook                                                                                                                                                            |
| 760 |    579.179355 |    764.149641 | Scott Reid                                                                                                                                                            |
| 761 |    441.459277 |    784.391492 | Matt Crook                                                                                                                                                            |
| 762 |    240.537887 |    365.279597 | Joseph Smit (modified by T. Michael Keesey)                                                                                                                           |
| 763 |    227.478524 |    693.860774 | NA                                                                                                                                                                    |
| 764 |    664.641860 |    598.647005 | Michael Ströck (vectorized by T. Michael Keesey)                                                                                                                      |
| 765 |     35.991230 |    177.842622 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 766 |     86.563729 |    403.251554 | Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey)                                                                                                      |
| 767 |    881.161759 |    147.921951 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 768 |    149.408763 |    272.256047 | Jagged Fang Designs                                                                                                                                                   |
| 769 |    608.925951 |    310.012661 | Robbie Cada (vectorized by T. Michael Keesey)                                                                                                                         |
| 770 |    486.365965 |    601.525633 | Gareth Monger                                                                                                                                                         |
| 771 |    712.695281 |    300.452394 | Jimmy Bernot                                                                                                                                                          |
| 772 |    495.398033 |    184.774942 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 773 |     24.818151 |    298.449850 | Matt Crook                                                                                                                                                            |
| 774 |    321.002157 |    279.207943 | Matt Crook                                                                                                                                                            |
| 775 |    150.795165 |     11.305533 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 776 |    722.152600 |    116.318156 | NA                                                                                                                                                                    |
| 777 |    288.765815 |     51.899074 | NA                                                                                                                                                                    |
| 778 |    493.619751 |    358.077563 | Julie Blommaert based on photo by Sofdrakou                                                                                                                           |
| 779 |    194.297710 |    369.680596 | Zimices                                                                                                                                                               |
| 780 |    474.462583 |    312.545741 | Margot Michaud                                                                                                                                                        |
| 781 |    993.772283 |    592.539014 | NA                                                                                                                                                                    |
| 782 |    140.377333 |    615.340311 | Jebulon (vectorized by T. Michael Keesey)                                                                                                                             |
| 783 |    161.411103 |    775.814393 | T. Michael Keesey (vector) and Stuart Halliday (photograph)                                                                                                           |
| 784 |    372.149669 |    791.900380 | Tracy A. Heath                                                                                                                                                        |
| 785 |    966.967265 |    385.338114 | Matt Crook                                                                                                                                                            |
| 786 |     96.429738 |    260.079041 | Pedro de Siracusa                                                                                                                                                     |
| 787 |    841.429697 |    531.311216 | Ignacio Contreras                                                                                                                                                     |
| 788 |    480.049826 |     53.042662 | Michael Scroggie                                                                                                                                                      |
| 789 |    597.023411 |    262.015793 | Nobu Tamura                                                                                                                                                           |
| 790 |     82.980073 |     19.978614 | L. Shyamal                                                                                                                                                            |
| 791 |    871.114129 |    364.946138 | J. J. Harrison (photo) & T. Michael Keesey                                                                                                                            |
| 792 |    472.086847 |    420.017189 | Matt Crook                                                                                                                                                            |
| 793 |     64.182421 |     85.078172 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                      |
| 794 |    574.718785 |    692.515243 | Michelle Site                                                                                                                                                         |
| 795 |    132.839109 |    342.419789 | Zimices                                                                                                                                                               |
| 796 |    299.689639 |     76.618113 | Scott Hartman                                                                                                                                                         |
| 797 |    676.440322 |    302.122981 | Matt Crook                                                                                                                                                            |
| 798 |    208.785267 |    533.472512 | Margot Michaud                                                                                                                                                        |
| 799 |    678.958903 |    715.663914 | T. Michael Keesey                                                                                                                                                     |
| 800 |    189.679747 |    437.960450 | Matt Crook                                                                                                                                                            |
| 801 |    279.479095 |    178.471690 | NA                                                                                                                                                                    |
| 802 |    860.677176 |     58.458051 | Alexandre Vong                                                                                                                                                        |
| 803 |    927.169024 |    443.414959 | Fernando Carezzano                                                                                                                                                    |
| 804 |     92.182983 |    419.501593 | Matt Crook                                                                                                                                                            |
| 805 |    203.747167 |     57.125644 | Cesar Julian                                                                                                                                                          |
| 806 |    417.109635 |     36.604895 | Steven Traver                                                                                                                                                         |
| 807 |    318.619406 |    469.899654 | Sarah Werning                                                                                                                                                         |
| 808 |    693.339406 |     77.277485 | Scott Hartman                                                                                                                                                         |
| 809 |    627.600428 |    717.447654 | Chris Jennings (vectorized by A. Verrière)                                                                                                                            |
| 810 |    309.013257 |    734.970289 | Maija Karala                                                                                                                                                          |
| 811 |    948.931920 |    377.834605 | Matt Crook                                                                                                                                                            |
| 812 |    395.411176 |    336.904205 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 813 |    604.162817 |    179.283483 | Warren H (photography), T. Michael Keesey (vectorization)                                                                                                             |
| 814 |     75.270134 |    792.716469 | Scott Hartman                                                                                                                                                         |
| 815 |    109.979159 |    305.863487 | Josefine Bohr Brask                                                                                                                                                   |
| 816 |    221.253888 |    166.191345 | Zimices                                                                                                                                                               |
| 817 |    800.811995 |     16.864629 | Karla Martinez                                                                                                                                                        |
| 818 |    657.237388 |    218.392191 | Tasman Dixon                                                                                                                                                          |
| 819 |    425.176097 |    538.935563 | Margot Michaud                                                                                                                                                        |
| 820 |    708.205201 |    177.446760 | Scott Hartman                                                                                                                                                         |
| 821 |     17.565553 |    327.924655 | CNZdenek                                                                                                                                                              |
| 822 |    510.651723 |    499.816996 | Ferran Sayol                                                                                                                                                          |
| 823 |    374.432552 |    683.643024 | Sarefo (vectorized by T. Michael Keesey)                                                                                                                              |
| 824 |     11.843073 |    310.885910 | Scott Hartman                                                                                                                                                         |
| 825 |    317.831965 |    318.611318 | Michele M Tobias                                                                                                                                                      |
| 826 |    518.171069 |    761.200261 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 827 |     55.779137 |    530.848967 | Rebecca Groom                                                                                                                                                         |
| 828 |    494.816457 |    712.450890 | Steven Traver                                                                                                                                                         |
| 829 |    596.902956 |     59.972082 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 830 |    464.724862 |    303.863850 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 831 |    601.013857 |    428.035102 | Cristopher Silva                                                                                                                                                      |
| 832 |    955.075410 |    380.932267 | Matt Crook                                                                                                                                                            |
| 833 |    532.308116 |    597.209853 | Margot Michaud                                                                                                                                                        |
| 834 |    799.708117 |    790.740021 | Kanako Bessho-Uehara                                                                                                                                                  |
| 835 |    493.118515 |     95.439947 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 836 |     96.419869 |     33.094701 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                  |
| 837 |    117.929219 |    104.694669 | Steven Traver                                                                                                                                                         |
| 838 |    401.500778 |    600.089805 | T. Michael Keesey                                                                                                                                                     |
| 839 |    413.044383 |    637.843030 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                        |
| 840 |     68.126601 |    183.261851 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
| 841 |    258.113215 |    689.351601 | Douglas Brown (modified by T. Michael Keesey)                                                                                                                         |
| 842 |    361.262728 |    486.912659 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                                     |
| 843 |    930.301310 |    124.826333 | T. Michael Keesey (after MPF)                                                                                                                                         |
| 844 |    234.103486 |    244.127681 | Zimices                                                                                                                                                               |
| 845 |    859.499635 |     30.874671 | NA                                                                                                                                                                    |
| 846 |    960.370764 |    317.873182 | Dmitry Bogdanov                                                                                                                                                       |
| 847 |    414.693629 |    642.506724 | Gareth Monger                                                                                                                                                         |
| 848 |    612.212516 |     65.631815 | Cristina Guijarro                                                                                                                                                     |
| 849 |    180.172812 |    782.808566 | Matt Crook                                                                                                                                                            |
| 850 |    858.093400 |    261.726434 | T. Michael Keesey (vectorization) and HuttyMcphoo (photography)                                                                                                       |
| 851 |    896.370590 |    784.089778 | Scott Reid                                                                                                                                                            |
| 852 |    579.404446 |    629.727590 | Matt Crook                                                                                                                                                            |
| 853 |   1014.700069 |    636.945558 | Matt Dempsey                                                                                                                                                          |
| 854 |    310.085654 |    553.189335 | Matt Dempsey                                                                                                                                                          |
| 855 |    194.673949 |    786.580407 | Davidson Sodré                                                                                                                                                        |
| 856 |    979.354293 |    521.119599 | Renata F. Martins                                                                                                                                                     |
| 857 |    731.056839 |    404.410923 | Jay Matternes (vectorized by T. Michael Keesey)                                                                                                                       |
| 858 |    210.374418 |    417.568892 | Matt Crook                                                                                                                                                            |
| 859 |    692.683572 |    247.401240 | Ferran Sayol                                                                                                                                                          |
| 860 |     75.035088 |    650.423244 | Margot Michaud                                                                                                                                                        |
| 861 |    914.138159 |    210.600580 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 862 |    861.691248 |    252.551340 | Ryan Cupo                                                                                                                                                             |
| 863 |    760.501277 |    171.069549 | Jon Hill (Photo by Benjamint444: <http://en.wikipedia.org/wiki/File:Blue-footed-booby.jpg>)                                                                           |
| 864 |    663.675042 |    610.832716 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 865 |    265.823184 |    176.555593 | Noah Schlottman                                                                                                                                                       |
| 866 |     37.399084 |    275.573109 | Jagged Fang Designs                                                                                                                                                   |
| 867 |     29.831698 |    706.611677 | Prin Pattawaro (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey        |
| 868 |    777.200681 |    333.775643 | Chloé Schmidt                                                                                                                                                         |
| 869 |    242.222375 |    617.811661 | NA                                                                                                                                                                    |
| 870 |    298.277783 |    697.713835 | NA                                                                                                                                                                    |
| 871 |    451.641497 |    435.061486 | Aviceda (photo) & T. Michael Keesey                                                                                                                                   |
| 872 |    613.811915 |    175.803168 | Charles Doolittle Walcott (vectorized by T. Michael Keesey)                                                                                                           |
| 873 |    796.625020 |    630.420791 | Ferran Sayol                                                                                                                                                          |
| 874 |    753.990243 |    300.238231 | Steven Traver                                                                                                                                                         |
| 875 |    263.232635 |    489.652008 | Joe Schneid (vectorized by T. Michael Keesey)                                                                                                                         |
| 876 |    986.224069 |    738.454890 | Sarefo (vectorized by T. Michael Keesey)                                                                                                                              |
| 877 |    813.603869 |    624.083185 | FunkMonk                                                                                                                                                              |
| 878 |    924.798359 |    347.035962 | Tasman Dixon                                                                                                                                                          |
| 879 |    160.842527 |    518.269619 | Margot Michaud                                                                                                                                                        |
| 880 |    195.739729 |    523.409779 | NA                                                                                                                                                                    |
| 881 |     48.961940 |    707.532691 | Cesar Julian                                                                                                                                                          |
| 882 |    477.539159 |    191.302671 | Yan Wong from SEM by Arnau Sebé-Pedrós (PD agreed by Iñaki Ruiz-Trillo)                                                                                               |
| 883 |    556.683280 |    214.760437 | NA                                                                                                                                                                    |
| 884 |    388.851445 |    585.896600 | Jaime Headden                                                                                                                                                         |
| 885 |    780.020540 |    175.300920 | Maija Karala                                                                                                                                                          |
| 886 |     57.848229 |    536.494530 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 887 |    847.717020 |    127.865497 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 888 |    331.065413 |    633.877796 | Terpsichores                                                                                                                                                          |
| 889 |    519.054232 |    341.472563 | Scott Hartman                                                                                                                                                         |
| 890 |    169.028600 |    436.957800 | NOAA (vectorized by T. Michael Keesey)                                                                                                                                |
| 891 |    233.247422 |    674.520975 | Ville Koistinen and T. Michael Keesey                                                                                                                                 |
| 892 |      9.673536 |    336.863509 | Matt Crook                                                                                                                                                            |
| 893 |    819.131723 |    136.595247 | Chris huh                                                                                                                                                             |
| 894 |    736.058303 |    359.575656 | Abraão B. Leite                                                                                                                                                       |
| 895 |    930.883995 |    630.752793 | Felix Vaux                                                                                                                                                            |
| 896 |    211.899476 |    513.971206 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
| 897 |   1018.930004 |    264.925693 | Tyler Greenfield                                                                                                                                                      |
| 898 |    442.070130 |    759.062699 | Matt Crook                                                                                                                                                            |
| 899 |    401.255754 |    650.420579 | Dean Schnabel                                                                                                                                                         |
| 900 |      7.899236 |     59.857706 | Liftarn                                                                                                                                                               |
| 901 |    840.243017 |    337.344661 | Gareth Monger                                                                                                                                                         |
| 902 |    312.695733 |    708.222334 | FunkMonk                                                                                                                                                              |
| 903 |    905.521637 |    217.304743 | Jagged Fang Designs                                                                                                                                                   |
| 904 |    298.325603 |     39.407018 | Melissa Broussard                                                                                                                                                     |
| 905 |    786.151216 |    213.341559 | Owen Jones                                                                                                                                                            |
| 906 |    257.555566 |    717.037507 | NA                                                                                                                                                                    |
| 907 |    990.475801 |    472.569168 | Maxime Dahirel                                                                                                                                                        |
| 908 |    351.941693 |    677.387359 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 909 |    975.775300 |     48.501706 | Anthony Caravaggi                                                                                                                                                     |
| 910 |    496.931099 |    792.913177 | Steven Traver                                                                                                                                                         |
| 911 |    986.635901 |    540.118973 | Steven Traver                                                                                                                                                         |
| 912 |    238.011170 |    433.266610 | Zimices                                                                                                                                                               |
| 913 |    861.172882 |    706.451348 | T. Michael Keesey                                                                                                                                                     |
| 914 |     38.902826 |    100.304244 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                                     |

    #> Your tweet has been posted!
