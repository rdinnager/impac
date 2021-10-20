
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

Joanna Wolfe, Terpsichores, Lukasiniho, Matt Crook, Lukas Panzarin,
Steven Haddock • Jellywatch.org, Robert Gay, Michael Wolf (photo), Hans
Hillewaert (editing), T. Michael Keesey (vectorization), Luis Cunha,
Gareth Monger, T. Michael Keesey, FunkMonk, Original drawing by Antonov,
vectorized by Roberto Díaz Sibaja, Steven Traver, Dmitry Bogdanov
(vectorized by T. Michael Keesey), Becky Barnes, Tony Ayling (vectorized
by T. Michael Keesey), Carlos Cano-Barbacil, Zimices, based in Mauricio
Antón skeletal, Dean Schnabel, Michele M Tobias, Xavier Giroux-Bougard,
Michelle Site, Margot Michaud, Scott Hartman, Mali’o Kodis, image by
Rebecca Ritger, Jan A. Venter, Herbert H. T. Prins, David A. Balfour &
Rob Slotow (vectorized by T. Michael Keesey), Zimices, xgirouxb, Michael
B. H. (vectorized by T. Michael Keesey), Chris huh, Jagged Fang Designs,
Shyamal, Sharon Wegner-Larsen, Ferran Sayol, Eduard Solà (vectorized by
T. Michael Keesey), Martin R. Smith, Luc Viatour (source photo) and
Andreas Plank, T. Michael Keesey (after C. De Muizon), Noah Schlottman,
U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley
(silhouette), Christoph Schomburg, Ghedo and T. Michael Keesey, Joseph
J. W. Sertich, Mark A. Loewen, Jaime Headden, L. Shyamal, Nobu Tamura
(vectorized by T. Michael Keesey), Tasman Dixon, Kimberly Haddrell,
Caleb M. Brown, Stuart Humphries, Matt Martyniuk, Alex Slavenko,
Fernando Carezzano, Craig Dylke, DW Bapst (modified from Bates et al.,
2005), Tracy A. Heath, James R. Spotila and Ray Chatterji, Brad
McFeeters (vectorized by T. Michael Keesey), John Gould (vectorized by
T. Michael Keesey), Christine Axon, Birgit Lang, Rafael Maia, Harold N
Eyster, Sarah Werning, Mathilde Cordellier, Maxime Dahirel, Pete
Buchholz, Caleb Brown, Samanta Orellana, Alexander Schmidt-Lebuhn, I.
Geoffroy Saint-Hilaire (vectorized by T. Michael Keesey), Julio Garza,
Scott Reid, Blair Perry, Jakovche, Zachary Quigley, Tim Bertelink
(modified by T. Michael Keesey), Jose Carlos Arenas-Monroy, Stanton F.
Fink, vectorized by Zimices, Lisa M. “Pixxl” (photo), John E. McCormack,
Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C.
Glenn, Robb T. Brumfield & T. Michael Keesey, Ray Simpson (vectorized by
T. Michael Keesey), Kailah Thorn & Mark Hutchinson, Gabriela
Palomo-Munoz, Maija Karala, Beth Reinke, Jon M Laurent, Roberto Díaz
Sibaja, Madeleine Price Ball, Michael Scroggie, from original photograph
by Gary M. Stolz, USFWS (original photograph in public domain)., Nobu
Tamura, Sergio A. Muñoz-Gómez, Mark Hannaford (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Mark Witton,
Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette), Enoch
Joseph Wetsy (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Chloé Schmidt, Peileppe, Noah Schlottman, photo by Casey
Dunn, terngirl, Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti,
Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G.
Barraclough (vectorized by T. Michael Keesey), Smokeybjb, vectorized by
Zimices, Mark Miller, Noah Schlottman, photo by Hans De Blauwe, Dmitry
Bogdanov, Mathew Wedel, Duane Raver/USFWS, Emma Kissling, Noah
Schlottman, photo from National Science Foundation - Turbellarian
Taxonomic Database, T. Michael Keesey (after Marek Velechovský), Chris
A. Hamilton, (after Spotila 2004), Florian Pfaff, Jim Bendon
(photography) and T. Michael Keesey (vectorization), Trond R. Oskars,
Nobu Tamura and T. Michael Keesey, FJDegrange, Iain Reid, Tyler
Greenfield, Crystal Maier, Yan Wong, Marie Russell, Inessa Voet,
Metalhead64 (vectorized by T. Michael Keesey), T. Michael Keesey
(vectorization) and HuttyMcphoo (photography), David Liao, Martin R.
Smith, from photo by Jürgen Schoner, Manabu Sakamoto, Margret Flinsch,
vectorized by Zimices, B. Duygu Özpolat, Francesco “Architetto”
Rollandin, Anthony Caravaggi, Javier Luque, Rainer Schoch, Andrew A.
Farke, modified from original by Robert Bruce Horsfall, from Scott 1912,
Hans Hillewaert, Nina Skinner, Katie S. Collins, Abraão Leite, Nobu
Tamura, vectorized by Zimices, T. Michael Keesey (vectorization) and
Tony Hisgett (photography), Alexandre Vong, Renato Santos, Lauren
Anderson, Mattia Menchetti, Noah Schlottman, photo from Moorea Biocode,
Emily Willoughby, Cesar Julian, Lafage, Christopher Chávez, (after
McCulloch 1908), Noah Schlottman, photo from Casey Dunn, C. Camilo
Julián-Caballero, Mariana Ruiz (vectorized by T. Michael Keesey),
Robert Bruce Horsfall, vectorized by Zimices, C. W. Nash (illustration)
and Timothy J. Bartley (silhouette), Raven Amos, Rebecca Groom, Andrew
A. Farke, Amanda Katzer, E. D. Cope (modified by T. Michael Keesey,
Michael P. Taylor & Matthew J. Wedel), Meliponicultor Itaymbere, Henry
Fairfield Osborn, vectorized by Zimices, Yusan Yang, DW Bapst, modified
from Figure 1 of Belanger (2011, PALAIOS)., Gopal Murali, Karla
Martinez, Felix Vaux, Andreas Hejnol, Richard Ruggiero, vectorized by
Zimices, CNZdenek, Sam Droege (photo) and T. Michael Keesey
(vectorization), John Curtis (vectorized by T. Michael Keesey), Berivan
Temiz, Geoff Shaw, Tommaso Cancellario, Kai R. Caspar, Ludwik
Gasiorowski, Mihai Dragos (vectorized by T. Michael Keesey), Mali’o
Kodis, photograph by John Slapcinsky, Elizabeth Parker, Michael P.
Taylor, Kamil S. Jaron, Robert Gay, modified from FunkMonk (Michael
B.H.) and T. Michael Keesey., Cristopher Silva, Collin Gross, Lee
Harding (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, T. Michael Keesey (after Tillyard), David Tana, Henry
Lydecker, T. Michael Keesey (after Ponomarenko), Apokryltaros
(vectorized by T. Michael Keesey), Mattia Menchetti / Yan Wong, T.
Michael Keesey (photo by Sean Mack), Matt Martyniuk (vectorized by T.
Michael Keesey), Jonathan Wells, Don Armstrong, T. Michael Keesey (after
Joseph Wolf), Tauana J. Cunha, David Orr, Maxime Dahirel (digitisation),
Kees van Achterberg et al (doi: 10.3897/BDJ.8.e49017)(original
publication), Hans Hillewaert (vectorized by T. Michael Keesey),
Brockhaus and Efron, Darius Nau, Saguaro Pictures (source photo) and T.
Michael Keesey, Daniel Stadtmauer, Birgit Lang, based on a photo by D.
Sikes, Martin R. Smith, after Skovsted et al 2015, Gabriel Lio,
vectorized by Zimices, T. Tischler, T. Michael Keesey (after James &
al.), Anilocra (vectorization by Yan Wong), Kenneth Lacovara (vectorized
by T. Michael Keesey), Sean McCann, M Kolmann, Mason McNair, Michael
Scroggie, Conty (vectorized by T. Michael Keesey), Melissa Broussard, M.
Antonio Todaro, Tobias Kånneby, Matteo Dal Zotto, and Ulf Jondelius
(vectorized by T. Michael Keesey), Esme Ashe-Jepson, Antonov (vectorized
by T. Michael Keesey), C. Abraczinskas, Oliver Griffith, Plukenet,
Kailah Thorn & Ben King, Milton Tan, T. Michael Keesey (after Kukalová),
Maxwell Lefroy (vectorized by T. Michael Keesey), Matt Celeskey, Remes
K, Ortega F, Fierro I, Joger U, Kosma R, et al., Danielle Alba, Obsidian
Soul (vectorized by T. Michael Keesey), Matus Valach, mystica, Xavier A.
Jenkins, Gabriel Ugueto, Robbie Cada (vectorized by T. Michael Keesey),
Meyers Konversations-Lexikon 1897 (vectorized: Yan Wong), Manabu
Bessho-Uehara, Sam Droege (photography) and T. Michael Keesey
(vectorization), Abraão B. Leite, Benjamint444, Mali’o Kodis, photograph
by Derek Keats (<http://www.flickr.com/photos/dkeats/>), T. Michael
Keesey and Tanetahi, Francesco Veronesi (vectorized by T. Michael
Keesey), Charles R. Knight (vectorized by T. Michael Keesey), Bill
Bouton (source photo) & T. Michael Keesey (vectorization), Catherine
Yasuda, Matt Wilkins (photo by Patrick Kavanagh), Allison Pease, Jake
Warner, Armin Reindl, Natasha Vitek, Campbell Fleming, Michael Scroggie,
from original photograph by John Bettaso, USFWS (original photograph in
public domain)., Michele M Tobias from an image By Dcrjsr - Own work, CC
BY 3.0, <https://commons.wikimedia.org/w/index.php?curid=18059686>, V.
Deepak, NASA, FunkMonk \[Michael B.H.\] (modified by T. Michael Keesey),
Taro Maeda, Caroline Harding, MAF (vectorized by T. Michael Keesey),
Tyler Greenfield and Scott Hartman, Didier Descouens (vectorized by T.
Michael Keesey), T. Michael Keesey (from a photo by Maximilian Paradiz),
Kent Elson Sorgon, Matthias Buschmann (vectorized by T. Michael Keesey),
Jennifer Trimble, Mike Hanson, Mateus Zica (modified by T. Michael
Keesey), Derek Bakken (photograph) and T. Michael Keesey
(vectorization), Mali’o Kodis, photograph by G. Giribet, Julia B McHugh,
Mathew Callaghan, Joedison Rocha

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    763.648289 |    289.018446 | Joanna Wolfe                                                                                                                                                          |
|   2 |    736.751524 |    621.297236 | Terpsichores                                                                                                                                                          |
|   3 |    666.601927 |    693.719755 | Lukasiniho                                                                                                                                                            |
|   4 |    265.477818 |    455.981501 | Matt Crook                                                                                                                                                            |
|   5 |    755.528561 |    450.235576 | Lukas Panzarin                                                                                                                                                        |
|   6 |    382.920837 |    670.284454 | Steven Haddock • Jellywatch.org                                                                                                                                       |
|   7 |    443.577909 |    550.540461 | Matt Crook                                                                                                                                                            |
|   8 |    177.372821 |    157.207409 | NA                                                                                                                                                                    |
|   9 |    694.740710 |    172.106073 | Matt Crook                                                                                                                                                            |
|  10 |    368.022437 |    176.673059 | Robert Gay                                                                                                                                                            |
|  11 |    459.588454 |     52.421370 | Michael Wolf (photo), Hans Hillewaert (editing), T. Michael Keesey (vectorization)                                                                                    |
|  12 |     85.228839 |    660.496157 | Luis Cunha                                                                                                                                                            |
|  13 |    321.036411 |     58.011678 | Gareth Monger                                                                                                                                                         |
|  14 |    873.209001 |    622.438072 | T. Michael Keesey                                                                                                                                                     |
|  15 |     80.811650 |    209.170825 | FunkMonk                                                                                                                                                              |
|  16 |    594.536651 |    501.803186 | Original drawing by Antonov, vectorized by Roberto Díaz Sibaja                                                                                                        |
|  17 |    963.619602 |     77.280881 | Steven Traver                                                                                                                                                         |
|  18 |    230.536274 |    312.481027 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  19 |    710.879671 |     41.670555 | T. Michael Keesey                                                                                                                                                     |
|  20 |    179.128343 |    398.747639 | Becky Barnes                                                                                                                                                          |
|  21 |    925.892847 |    287.132791 | Matt Crook                                                                                                                                                            |
|  22 |    446.533893 |    758.463255 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
|  23 |    871.925902 |    141.241956 | Carlos Cano-Barbacil                                                                                                                                                  |
|  24 |     77.796127 |    289.268814 | Zimices, based in Mauricio Antón skeletal                                                                                                                             |
|  25 |     69.346092 |    506.569166 | Dean Schnabel                                                                                                                                                         |
|  26 |    408.831892 |    387.849932 | Michele M Tobias                                                                                                                                                      |
|  27 |    509.856598 |    232.837584 | Xavier Giroux-Bougard                                                                                                                                                 |
|  28 |    323.807183 |    348.679147 | Michelle Site                                                                                                                                                         |
|  29 |    556.631501 |    101.673033 | Margot Michaud                                                                                                                                                        |
|  30 |    747.139806 |    358.303605 | Scott Hartman                                                                                                                                                         |
|  31 |    207.288916 |    579.295460 | Mali’o Kodis, image by Rebecca Ritger                                                                                                                                 |
|  32 |    484.264907 |    419.067116 | Matt Crook                                                                                                                                                            |
|  33 |    391.530731 |    491.726971 | NA                                                                                                                                                                    |
|  34 |    583.918269 |    327.536065 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
|  35 |    961.489440 |    396.693262 | Zimices                                                                                                                                                               |
|  36 |    188.762844 |    663.362527 | xgirouxb                                                                                                                                                              |
|  37 |    270.252725 |    176.290342 | Margot Michaud                                                                                                                                                        |
|  38 |    672.743965 |    104.992552 | Michael B. H. (vectorized by T. Michael Keesey)                                                                                                                       |
|  39 |    676.937314 |    766.473312 | Chris huh                                                                                                                                                             |
|  40 |    197.114718 |     43.981867 | Steven Traver                                                                                                                                                         |
|  41 |    927.401741 |    469.099344 | Margot Michaud                                                                                                                                                        |
|  42 |    618.283833 |    627.066749 | Jagged Fang Designs                                                                                                                                                   |
|  43 |    496.110244 |    691.410797 | Shyamal                                                                                                                                                               |
|  44 |    248.277225 |    765.860356 | Sharon Wegner-Larsen                                                                                                                                                  |
|  45 |    309.582046 |    546.263184 | Ferran Sayol                                                                                                                                                          |
|  46 |    820.701688 |    769.753174 | Eduard Solà (vectorized by T. Michael Keesey)                                                                                                                         |
|  47 |     36.744586 |    413.790949 | Gareth Monger                                                                                                                                                         |
|  48 |    996.914123 |    734.996410 | Martin R. Smith                                                                                                                                                       |
|  49 |    890.343331 |    225.405422 | Chris huh                                                                                                                                                             |
|  50 |    839.769391 |     58.645145 | Luc Viatour (source photo) and Andreas Plank                                                                                                                          |
|  51 |    786.925169 |    549.270047 | T. Michael Keesey (after C. De Muizon)                                                                                                                                |
|  52 |    433.349757 |    268.318191 | Noah Schlottman                                                                                                                                                       |
|  53 |     80.497637 |     33.344403 | Steven Traver                                                                                                                                                         |
|  54 |    331.608911 |    237.530275 | Jagged Fang Designs                                                                                                                                                   |
|  55 |    806.621574 |    183.636360 | U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                                     |
|  56 |    220.262302 |    704.370386 | Shyamal                                                                                                                                                               |
|  57 |    953.424756 |    594.946234 | Christoph Schomburg                                                                                                                                                   |
|  58 |    625.260702 |    570.086686 | Zimices                                                                                                                                                               |
|  59 |    906.074875 |    162.782890 | Dean Schnabel                                                                                                                                                         |
|  60 |     61.861189 |     98.483536 | Ghedo and T. Michael Keesey                                                                                                                                           |
|  61 |    927.037446 |    768.256300 | Joseph J. W. Sertich, Mark A. Loewen                                                                                                                                  |
|  62 |    825.870207 |    471.485260 | Scott Hartman                                                                                                                                                         |
|  63 |    392.274128 |     85.125661 | Jaime Headden                                                                                                                                                         |
|  64 |    512.662611 |    155.276383 | L. Shyamal                                                                                                                                                            |
|  65 |    846.772858 |    735.465729 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  66 |    673.301871 |    244.150818 | Tasman Dixon                                                                                                                                                          |
|  67 |    175.748956 |    259.082407 | Tasman Dixon                                                                                                                                                          |
|  68 |    140.001054 |    460.843725 | Steven Traver                                                                                                                                                         |
|  69 |    854.931172 |    359.357334 | Kimberly Haddrell                                                                                                                                                     |
|  70 |   1007.147467 |    248.764927 | Gareth Monger                                                                                                                                                         |
|  71 |    540.059446 |    735.242103 | Chris huh                                                                                                                                                             |
|  72 |    782.880247 |    235.094777 | Caleb M. Brown                                                                                                                                                        |
|  73 |    124.424808 |    573.359882 | Ferran Sayol                                                                                                                                                          |
|  74 |    457.570433 |    636.607719 | Stuart Humphries                                                                                                                                                      |
|  75 |    953.497924 |    491.301922 | Matt Martyniuk                                                                                                                                                        |
|  76 |    539.197590 |    776.157530 | Jagged Fang Designs                                                                                                                                                   |
|  77 |    478.909034 |    319.917577 | Zimices                                                                                                                                                               |
|  78 |    106.987426 |    357.731191 | Alex Slavenko                                                                                                                                                         |
|  79 |    997.688850 |    604.300101 | Fernando Carezzano                                                                                                                                                    |
|  80 |     62.662361 |    154.537782 | Craig Dylke                                                                                                                                                           |
|  81 |    910.224842 |    595.541707 | DW Bapst (modified from Bates et al., 2005)                                                                                                                           |
|  82 |    255.970190 |    109.799630 | Jagged Fang Designs                                                                                                                                                   |
|  83 |     69.970182 |    248.446171 | NA                                                                                                                                                                    |
|  84 |    202.492694 |    514.016836 | Scott Hartman                                                                                                                                                         |
|  85 |    444.092432 |    173.317183 | Margot Michaud                                                                                                                                                        |
|  86 |    363.098904 |    767.111420 | Ferran Sayol                                                                                                                                                          |
|  87 |    813.997693 |    603.861596 | Tracy A. Heath                                                                                                                                                        |
|  88 |    152.762779 |    778.939602 | James R. Spotila and Ray Chatterji                                                                                                                                    |
|  89 |    971.674154 |    533.731830 | NA                                                                                                                                                                    |
|  90 |    252.058143 |    389.074980 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
|  91 |    817.624936 |     25.463236 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  92 |    356.615632 |    216.792483 | John Gould (vectorized by T. Michael Keesey)                                                                                                                          |
|  93 |    978.002037 |     23.990209 | Christine Axon                                                                                                                                                        |
|  94 |    210.563054 |    426.341866 | NA                                                                                                                                                                    |
|  95 |    851.750963 |    383.927300 | Birgit Lang                                                                                                                                                           |
|  96 |    619.893157 |    460.846695 | Zimices                                                                                                                                                               |
|  97 |     37.659869 |    528.210214 | Ferran Sayol                                                                                                                                                          |
|  98 |    272.174766 |    267.824565 | Rafael Maia                                                                                                                                                           |
|  99 |    186.281213 |    499.045139 | Scott Hartman                                                                                                                                                         |
| 100 |    949.207327 |    260.955185 | Harold N Eyster                                                                                                                                                       |
| 101 |    337.754887 |    619.707527 | Sarah Werning                                                                                                                                                         |
| 102 |    501.198336 |    609.656263 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 103 |    157.623834 |    740.669502 | Zimices                                                                                                                                                               |
| 104 |    929.009539 |    713.891108 | NA                                                                                                                                                                    |
| 105 |    890.176369 |    279.348218 | Mathilde Cordellier                                                                                                                                                   |
| 106 |    508.327603 |    377.204136 | Jagged Fang Designs                                                                                                                                                   |
| 107 |    674.841965 |    351.114823 | Margot Michaud                                                                                                                                                        |
| 108 |    592.079945 |     41.915740 | Maxime Dahirel                                                                                                                                                        |
| 109 |    448.051227 |     16.444791 | Pete Buchholz                                                                                                                                                         |
| 110 |     57.001957 |      6.623571 | Caleb Brown                                                                                                                                                           |
| 111 |    110.152042 |    415.459867 | Ferran Sayol                                                                                                                                                          |
| 112 |    481.686090 |    456.311741 | Matt Crook                                                                                                                                                            |
| 113 |    979.705542 |    182.345207 | Samanta Orellana                                                                                                                                                      |
| 114 |    772.356108 |    617.552648 | Gareth Monger                                                                                                                                                         |
| 115 |    789.992869 |    114.052808 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 116 |    908.821517 |    449.043984 | I. Geoffroy Saint-Hilaire (vectorized by T. Michael Keesey)                                                                                                           |
| 117 |    753.953908 |    328.110882 | Xavier Giroux-Bougard                                                                                                                                                 |
| 118 |    191.605215 |    460.252699 | Julio Garza                                                                                                                                                           |
| 119 |    478.438213 |    194.474827 | Zimices                                                                                                                                                               |
| 120 |    209.068856 |    565.842611 | NA                                                                                                                                                                    |
| 121 |    426.478075 |      4.725433 | NA                                                                                                                                                                    |
| 122 |    590.784869 |     73.543486 | Scott Reid                                                                                                                                                            |
| 123 |    755.264420 |    202.550234 | T. Michael Keesey                                                                                                                                                     |
| 124 |    183.134113 |    420.924893 | Blair Perry                                                                                                                                                           |
| 125 |    976.799520 |    733.581657 | Jakovche                                                                                                                                                              |
| 126 |    136.763429 |     12.760143 | Zachary Quigley                                                                                                                                                       |
| 127 |    989.673804 |    443.782847 | Tim Bertelink (modified by T. Michael Keesey)                                                                                                                         |
| 128 |    391.838322 |    780.658722 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 129 |    289.246837 |     12.941163 | Steven Traver                                                                                                                                                         |
| 130 |    223.613065 |    788.829469 | T. Michael Keesey                                                                                                                                                     |
| 131 |    504.027538 |    446.829894 | Scott Hartman                                                                                                                                                         |
| 132 |    162.356463 |    382.790887 | Stanton F. Fink, vectorized by Zimices                                                                                                                                |
| 133 |    811.148983 |    682.992061 | Michele M Tobias                                                                                                                                                      |
| 134 |    255.137148 |    150.716497 | Scott Hartman                                                                                                                                                         |
| 135 |     93.608600 |    603.624625 | Lisa M. “Pixxl” (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey       |
| 136 |    671.455601 |    615.967065 | Matt Crook                                                                                                                                                            |
| 137 |    752.726015 |    757.027998 | Gareth Monger                                                                                                                                                         |
| 138 |    944.151487 |    519.846914 | Ray Simpson (vectorized by T. Michael Keesey)                                                                                                                         |
| 139 |    382.924896 |    661.263812 | Shyamal                                                                                                                                                               |
| 140 |    958.407100 |    333.351185 | Kailah Thorn & Mark Hutchinson                                                                                                                                        |
| 141 |    666.264284 |    484.644060 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 142 |    340.944178 |    442.444863 | Maija Karala                                                                                                                                                          |
| 143 |    815.357688 |    506.307884 | Ferran Sayol                                                                                                                                                          |
| 144 |    390.254425 |     10.719441 | Beth Reinke                                                                                                                                                           |
| 145 |    908.274940 |    172.811212 | Gareth Monger                                                                                                                                                         |
| 146 |    890.142016 |    319.872190 | Jon M Laurent                                                                                                                                                         |
| 147 |    879.892694 |     90.799330 | Steven Traver                                                                                                                                                         |
| 148 |    533.718900 |    578.984110 | Roberto Díaz Sibaja                                                                                                                                                   |
| 149 |    523.753186 |    437.782599 | Madeleine Price Ball                                                                                                                                                  |
| 150 |     10.518883 |    700.752510 | Michael Scroggie, from original photograph by Gary M. Stolz, USFWS (original photograph in public domain).                                                            |
| 151 |    396.379004 |    727.868196 | Scott Reid                                                                                                                                                            |
| 152 |    824.156751 |     13.109763 | Matt Crook                                                                                                                                                            |
| 153 |    424.003896 |    210.265384 | Dean Schnabel                                                                                                                                                         |
| 154 |    569.636131 |     31.012367 | Nobu Tamura                                                                                                                                                           |
| 155 |    612.179816 |    497.624329 | Ferran Sayol                                                                                                                                                          |
| 156 |    135.821587 |     75.697959 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 157 |     43.562552 |    325.797285 | Martin R. Smith                                                                                                                                                       |
| 158 |     75.894545 |     62.522396 | Mark Hannaford (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey        |
| 159 |    533.207106 |      8.211142 | Mark Witton                                                                                                                                                           |
| 160 |    691.714084 |    141.377697 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                                     |
| 161 |     15.382169 |    345.246407 | NA                                                                                                                                                                    |
| 162 |    198.344076 |    412.973756 | Shyamal                                                                                                                                                               |
| 163 |    715.032569 |    362.989562 | Enoch Joseph Wetsy (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey    |
| 164 |    263.624517 |    659.908254 | Zimices                                                                                                                                                               |
| 165 |    843.584038 |    680.453516 | Gareth Monger                                                                                                                                                         |
| 166 |    114.122488 |    188.990372 | Chloé Schmidt                                                                                                                                                         |
| 167 |      9.414663 |    582.083074 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 168 |    205.503613 |    596.840261 | Margot Michaud                                                                                                                                                        |
| 169 |    722.150306 |    518.059582 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 170 |    662.952339 |    787.778119 | Martin R. Smith                                                                                                                                                       |
| 171 |    601.956974 |     11.457469 | Peileppe                                                                                                                                                              |
| 172 |    415.028575 |    322.794044 | James R. Spotila and Ray Chatterji                                                                                                                                    |
| 173 |    838.824256 |    669.343258 | Matt Crook                                                                                                                                                            |
| 174 |     78.444825 |    580.644365 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
| 175 |     91.919187 |    653.248130 | T. Michael Keesey                                                                                                                                                     |
| 176 |    542.346222 |    645.638206 | terngirl                                                                                                                                                              |
| 177 |    382.305060 |    699.475384 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 178 |    474.959186 |    711.729395 | Smokeybjb, vectorized by Zimices                                                                                                                                      |
| 179 |    586.469854 |    206.731284 | Zimices                                                                                                                                                               |
| 180 |    446.674327 |    146.674468 | Margot Michaud                                                                                                                                                        |
| 181 |    779.320564 |     17.590575 | James R. Spotila and Ray Chatterji                                                                                                                                    |
| 182 |    302.427945 |    413.388588 | Christine Axon                                                                                                                                                        |
| 183 |    460.368799 |    377.278198 | NA                                                                                                                                                                    |
| 184 |    842.388262 |    539.879317 | Mark Miller                                                                                                                                                           |
| 185 |    392.243880 |     29.147411 | Zimices                                                                                                                                                               |
| 186 |    647.915784 |     45.767665 | Noah Schlottman, photo by Hans De Blauwe                                                                                                                              |
| 187 |    574.656980 |    440.891451 | Matt Crook                                                                                                                                                            |
| 188 |     27.398654 |    573.267811 | Steven Traver                                                                                                                                                         |
| 189 |    132.013520 |    127.932544 | Dmitry Bogdanov                                                                                                                                                       |
| 190 |    819.107711 |    582.704308 | Gareth Monger                                                                                                                                                         |
| 191 |    718.645889 |    548.293690 | Mathew Wedel                                                                                                                                                          |
| 192 |    370.574271 |    459.318396 | T. Michael Keesey                                                                                                                                                     |
| 193 |     41.758378 |    158.412974 | Tasman Dixon                                                                                                                                                          |
| 194 |    807.186655 |    161.208721 | Duane Raver/USFWS                                                                                                                                                     |
| 195 |    414.897514 |    617.791967 | Zimices                                                                                                                                                               |
| 196 |    917.125721 |    406.408965 | NA                                                                                                                                                                    |
| 197 |    756.687647 |     14.480522 | NA                                                                                                                                                                    |
| 198 |    926.521963 |    290.586583 | Matt Crook                                                                                                                                                            |
| 199 |     83.034619 |    732.944947 | Emma Kissling                                                                                                                                                         |
| 200 |    213.650343 |    486.461645 | Noah Schlottman, photo from National Science Foundation - Turbellarian Taxonomic Database                                                                             |
| 201 |    271.716983 |    395.375825 | Tasman Dixon                                                                                                                                                          |
| 202 |    691.818302 |    240.429598 | Birgit Lang                                                                                                                                                           |
| 203 |    377.009911 |    329.325279 | Gareth Monger                                                                                                                                                         |
| 204 |    143.871684 |    209.766183 | Zimices                                                                                                                                                               |
| 205 |    599.330575 |    163.377924 | T. Michael Keesey (after Marek Velechovský)                                                                                                                           |
| 206 |    642.885351 |    521.607314 | Chris A. Hamilton                                                                                                                                                     |
| 207 |    631.704063 |    141.294432 | Zimices                                                                                                                                                               |
| 208 |    277.819449 |    132.069739 | (after Spotila 2004)                                                                                                                                                  |
| 209 |    249.125572 |    446.190715 | Florian Pfaff                                                                                                                                                         |
| 210 |     44.475493 |    591.510850 | Gareth Monger                                                                                                                                                         |
| 211 |    587.306670 |     98.914800 | Margot Michaud                                                                                                                                                        |
| 212 |     45.085907 |    125.883653 | NA                                                                                                                                                                    |
| 213 |    311.471466 |    478.314672 | Jim Bendon (photography) and T. Michael Keesey (vectorization)                                                                                                        |
| 214 |    268.831565 |    731.598049 | Margot Michaud                                                                                                                                                        |
| 215 |    223.930264 |    580.777674 | Ferran Sayol                                                                                                                                                          |
| 216 |    948.879374 |     15.000998 | Zimices                                                                                                                                                               |
| 217 |    785.718065 |    696.911194 | Trond R. Oskars                                                                                                                                                       |
| 218 |     89.783495 |    316.347201 | Ferran Sayol                                                                                                                                                          |
| 219 |    368.967776 |    751.654427 | Zimices                                                                                                                                                               |
| 220 |    831.721411 |    660.057964 | Nobu Tamura and T. Michael Keesey                                                                                                                                     |
| 221 |    695.236515 |    650.173935 | Margot Michaud                                                                                                                                                        |
| 222 |    815.381698 |    654.668211 | FJDegrange                                                                                                                                                            |
| 223 |    931.596860 |    403.266846 | Iain Reid                                                                                                                                                             |
| 224 |    787.597928 |    301.362385 | Matt Crook                                                                                                                                                            |
| 225 |     88.713061 |    390.118438 | Zimices                                                                                                                                                               |
| 226 |    370.324666 |    288.204865 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 227 |    618.069471 |    291.733126 | Xavier Giroux-Bougard                                                                                                                                                 |
| 228 |    269.031399 |    615.336230 | Steven Traver                                                                                                                                                         |
| 229 |    157.981335 |     94.834741 | Pete Buchholz                                                                                                                                                         |
| 230 |    573.749626 |     86.773700 | Tyler Greenfield                                                                                                                                                      |
| 231 |    364.780483 |    374.063588 | Crystal Maier                                                                                                                                                         |
| 232 |   1003.877315 |    310.738616 | Chris huh                                                                                                                                                             |
| 233 |     10.902119 |    604.908798 | Zimices                                                                                                                                                               |
| 234 |    601.634021 |    368.732931 | Sarah Werning                                                                                                                                                         |
| 235 |    694.502437 |      4.464461 | Scott Hartman                                                                                                                                                         |
| 236 |    796.202286 |    387.404722 | Yan Wong                                                                                                                                                              |
| 237 |    202.702936 |    555.823913 | Marie Russell                                                                                                                                                         |
| 238 |    829.762599 |     93.125584 | Matt Crook                                                                                                                                                            |
| 239 |    891.028349 |    308.290227 | Inessa Voet                                                                                                                                                           |
| 240 |     89.956540 |     74.476874 | Metalhead64 (vectorized by T. Michael Keesey)                                                                                                                         |
| 241 |    198.324176 |      2.671722 | Chris huh                                                                                                                                                             |
| 242 |    668.236353 |    548.373752 | Scott Hartman                                                                                                                                                         |
| 243 |    651.357236 |      6.936342 | T. Michael Keesey                                                                                                                                                     |
| 244 |    981.458387 |    756.287935 | Margot Michaud                                                                                                                                                        |
| 245 |    732.388377 |    781.474387 | Margot Michaud                                                                                                                                                        |
| 246 |    217.617224 |    128.054868 | Matt Crook                                                                                                                                                            |
| 247 |    614.873700 |    286.329505 | Jagged Fang Designs                                                                                                                                                   |
| 248 |     78.567787 |    678.049521 | Kailah Thorn & Mark Hutchinson                                                                                                                                        |
| 249 |    791.929331 |    656.412675 | Zimices                                                                                                                                                               |
| 250 |    703.512125 |    592.611339 | Steven Traver                                                                                                                                                         |
| 251 |     20.631606 |    615.400816 | Matt Crook                                                                                                                                                            |
| 252 |    643.340797 |     61.235362 | NA                                                                                                                                                                    |
| 253 |    958.402446 |    219.127849 | T. Michael Keesey (vectorization) and HuttyMcphoo (photography)                                                                                                       |
| 254 |    367.647903 |    254.391194 | Steven Traver                                                                                                                                                         |
| 255 |    941.676023 |    646.756652 | Margot Michaud                                                                                                                                                        |
| 256 |    570.081535 |    593.674700 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 257 |    469.393645 |    494.161873 | Ferran Sayol                                                                                                                                                          |
| 258 |     43.495462 |    771.476261 | David Liao                                                                                                                                                            |
| 259 |    977.875589 |      1.660988 | Scott Hartman                                                                                                                                                         |
| 260 |    409.928284 |    786.141562 | Martin R. Smith, from photo by Jürgen Schoner                                                                                                                         |
| 261 |    712.505767 |    193.665766 | Manabu Sakamoto                                                                                                                                                       |
| 262 |    240.386190 |    582.466127 | Margret Flinsch, vectorized by Zimices                                                                                                                                |
| 263 |    443.139675 |    118.630097 | B. Duygu Özpolat                                                                                                                                                      |
| 264 |    831.149371 |    570.125714 | Beth Reinke                                                                                                                                                           |
| 265 |    550.555906 |    425.374699 | Matt Crook                                                                                                                                                            |
| 266 |    299.382082 |    123.897523 | Gareth Monger                                                                                                                                                         |
| 267 |    273.677926 |    788.986840 | Zimices                                                                                                                                                               |
| 268 |    714.459852 |    565.955298 | NA                                                                                                                                                                    |
| 269 |    505.445535 |    428.577290 | Zimices                                                                                                                                                               |
| 270 |    908.681645 |      9.118406 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 271 |    104.158944 |    639.142632 | Tasman Dixon                                                                                                                                                          |
| 272 |    186.568876 |     93.082419 | Francesco “Architetto” Rollandin                                                                                                                                      |
| 273 |    600.850604 |    448.211551 | Michelle Site                                                                                                                                                         |
| 274 |    593.459994 |    703.856393 | Birgit Lang                                                                                                                                                           |
| 275 |    256.976418 |    525.795420 | Jim Bendon (photography) and T. Michael Keesey (vectorization)                                                                                                        |
| 276 |    732.545773 |    729.413847 | Matt Crook                                                                                                                                                            |
| 277 |    395.901783 |    686.311309 | Anthony Caravaggi                                                                                                                                                     |
| 278 |    522.164046 |    358.372015 | NA                                                                                                                                                                    |
| 279 |    105.614922 |    670.140989 | Margot Michaud                                                                                                                                                        |
| 280 |    396.543521 |    314.618071 | Steven Traver                                                                                                                                                         |
| 281 |    956.802533 |    744.772360 | Ferran Sayol                                                                                                                                                          |
| 282 |    632.951553 |    165.551871 | Joanna Wolfe                                                                                                                                                          |
| 283 |     12.417396 |    459.875747 | Birgit Lang                                                                                                                                                           |
| 284 |     63.181875 |    752.143728 | Tasman Dixon                                                                                                                                                          |
| 285 |    627.623489 |    523.121274 | Gareth Monger                                                                                                                                                         |
| 286 |    127.896686 |    378.886639 | Steven Traver                                                                                                                                                         |
| 287 |    457.187020 |    152.726936 | NA                                                                                                                                                                    |
| 288 |    181.883297 |    300.493990 | T. Michael Keesey                                                                                                                                                     |
| 289 |    234.973294 |     26.088355 | Zimices                                                                                                                                                               |
| 290 |    333.504886 |    572.955357 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 291 |    497.589912 |    654.838964 | Javier Luque                                                                                                                                                          |
| 292 |    649.938416 |    735.131195 | Rainer Schoch                                                                                                                                                         |
| 293 |     62.398260 |    363.910905 | Margot Michaud                                                                                                                                                        |
| 294 |    898.944750 |    112.217908 | Fernando Carezzano                                                                                                                                                    |
| 295 |    464.943303 |    484.744144 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 296 |    190.050067 |    720.252293 | Margot Michaud                                                                                                                                                        |
| 297 |    713.568295 |    653.255941 | Andrew A. Farke, modified from original by Robert Bruce Horsfall, from Scott 1912                                                                                     |
| 298 |     27.387208 |    335.581229 | Hans Hillewaert                                                                                                                                                       |
| 299 |   1015.977860 |    493.928062 | NA                                                                                                                                                                    |
| 300 |    525.741739 |    445.650778 | Margot Michaud                                                                                                                                                        |
| 301 |    343.069761 |    414.868090 | Steven Traver                                                                                                                                                         |
| 302 |    130.221755 |    430.971823 | Matt Crook                                                                                                                                                            |
| 303 |    157.581893 |    640.105092 | Nina Skinner                                                                                                                                                          |
| 304 |    458.777325 |    106.770289 | Katie S. Collins                                                                                                                                                      |
| 305 |     29.597602 |    114.694417 | Harold N Eyster                                                                                                                                                       |
| 306 |    428.559916 |    768.587979 | Margot Michaud                                                                                                                                                        |
| 307 |     20.701552 |    233.817840 | T. Michael Keesey                                                                                                                                                     |
| 308 |    534.972983 |     53.454811 | Dean Schnabel                                                                                                                                                         |
| 309 |    275.025505 |    652.219358 | Abraão Leite                                                                                                                                                          |
| 310 |     19.205642 |    299.252746 | T. Michael Keesey                                                                                                                                                     |
| 311 |    121.943275 |    673.764408 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 312 |    963.274586 |    141.273470 | Steven Traver                                                                                                                                                         |
| 313 |     63.455840 |    421.135336 | Dean Schnabel                                                                                                                                                         |
| 314 |    601.197263 |     75.979008 | L. Shyamal                                                                                                                                                            |
| 315 |    172.565400 |    509.860883 | T. Michael Keesey (vectorization) and Tony Hisgett (photography)                                                                                                      |
| 316 |    692.709065 |    116.440176 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 317 |    458.153423 |    356.662780 | T. Michael Keesey                                                                                                                                                     |
| 318 |    800.267232 |    453.291857 | Beth Reinke                                                                                                                                                           |
| 319 |    839.102025 |     30.678054 | Marie Russell                                                                                                                                                         |
| 320 |    624.717970 |    755.176543 | Carlos Cano-Barbacil                                                                                                                                                  |
| 321 |    472.561702 |    199.998359 | NA                                                                                                                                                                    |
| 322 |    484.434940 |    586.612144 | Zimices                                                                                                                                                               |
| 323 |    768.308699 |     68.724234 | Alexandre Vong                                                                                                                                                        |
| 324 |    216.033325 |    406.471610 | Steven Haddock • Jellywatch.org                                                                                                                                       |
| 325 |     62.493778 |    410.705918 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 326 |    398.843447 |    530.050269 | Matt Martyniuk                                                                                                                                                        |
| 327 |    273.652534 |    599.569212 | L. Shyamal                                                                                                                                                            |
| 328 |    758.554306 |    313.656550 | Matt Crook                                                                                                                                                            |
| 329 |    395.054154 |    701.012027 | Ferran Sayol                                                                                                                                                          |
| 330 |    177.450069 |    343.313987 | T. Michael Keesey                                                                                                                                                     |
| 331 |    265.194364 |    315.261570 | Renato Santos                                                                                                                                                         |
| 332 |    956.860403 |    712.385762 | Shyamal                                                                                                                                                               |
| 333 |    610.822304 |    188.973258 | Scott Hartman                                                                                                                                                         |
| 334 |    153.812405 |    325.127585 | Tasman Dixon                                                                                                                                                          |
| 335 |    341.514667 |    738.828638 | Scott Hartman                                                                                                                                                         |
| 336 |    715.570771 |    314.058267 | Shyamal                                                                                                                                                               |
| 337 |    425.917992 |     68.695473 | I. Geoffroy Saint-Hilaire (vectorized by T. Michael Keesey)                                                                                                           |
| 338 |    477.473616 |     71.640679 | T. Michael Keesey                                                                                                                                                     |
| 339 |    783.400351 |    444.304486 | Lauren Anderson                                                                                                                                                       |
| 340 |    559.374715 |    349.385793 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 341 |    112.088064 |     91.292831 | Mathew Wedel                                                                                                                                                          |
| 342 |    473.551418 |     86.795230 | Mattia Menchetti                                                                                                                                                      |
| 343 |    330.286948 |      9.952295 | Harold N Eyster                                                                                                                                                       |
| 344 |    747.906675 |    376.840346 | Noah Schlottman, photo from Moorea Biocode                                                                                                                            |
| 345 |    791.173825 |    596.890952 | Zimices                                                                                                                                                               |
| 346 |    226.285533 |    565.880835 | NA                                                                                                                                                                    |
| 347 |    597.078862 |    748.811178 | Emily Willoughby                                                                                                                                                      |
| 348 |    294.420008 |    608.076854 | Cesar Julian                                                                                                                                                          |
| 349 |    273.837108 |    240.964955 | FJDegrange                                                                                                                                                            |
| 350 |    824.694678 |    299.727556 | Chloé Schmidt                                                                                                                                                         |
| 351 |    353.267271 |    576.604474 | Gareth Monger                                                                                                                                                         |
| 352 |    365.283542 |    537.684541 | Emily Willoughby                                                                                                                                                      |
| 353 |    825.550505 |    642.794370 | Lafage                                                                                                                                                                |
| 354 |    300.930951 |    204.056140 | Christopher Chávez                                                                                                                                                    |
| 355 |     55.112344 |     72.686082 | Noah Schlottman                                                                                                                                                       |
| 356 |    547.324456 |    367.854954 | (after McCulloch 1908)                                                                                                                                                |
| 357 |    608.131754 |    113.683375 | Noah Schlottman, photo from Casey Dunn                                                                                                                                |
| 358 |    917.956015 |    737.864870 | Hans Hillewaert                                                                                                                                                       |
| 359 |    747.966920 |    786.499136 | Scott Hartman                                                                                                                                                         |
| 360 |    806.736629 |    321.584409 | Kimberly Haddrell                                                                                                                                                     |
| 361 |    861.638932 |    200.462679 | C. Camilo Julián-Caballero                                                                                                                                            |
| 362 |    345.048799 |    774.393914 | NA                                                                                                                                                                    |
| 363 |    351.643346 |    470.508989 | Mariana Ruiz (vectorized by T. Michael Keesey)                                                                                                                        |
| 364 |    361.886211 |    787.223123 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                          |
| 365 |    202.489401 |    725.264293 | Matt Crook                                                                                                                                                            |
| 366 |    229.133646 |      4.210674 | C. W. Nash (illustration) and Timothy J. Bartley (silhouette)                                                                                                         |
| 367 |    132.738987 |    139.745386 | Raven Amos                                                                                                                                                            |
| 368 |    964.510542 |    715.062267 | Chris huh                                                                                                                                                             |
| 369 |    484.698510 |    616.867422 | NA                                                                                                                                                                    |
| 370 |    773.774790 |    721.581403 | Rebecca Groom                                                                                                                                                         |
| 371 |    905.896321 |    329.075424 | Andrew A. Farke                                                                                                                                                       |
| 372 |    523.786380 |    425.349158 | Amanda Katzer                                                                                                                                                         |
| 373 |    168.672497 |    366.662234 | Christoph Schomburg                                                                                                                                                   |
| 374 |    346.682971 |    789.549848 | Scott Reid                                                                                                                                                            |
| 375 |    518.707639 |    651.199670 | Michele M Tobias                                                                                                                                                      |
| 376 |    170.788459 |    221.309311 | Zimices                                                                                                                                                               |
| 377 |    842.901018 |    254.552065 | E. D. Cope (modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel)                                                                                      |
| 378 |    825.928685 |    101.569814 | Mark Witton                                                                                                                                                           |
| 379 |    760.624899 |    781.480965 | Gareth Monger                                                                                                                                                         |
| 380 |    131.512669 |    170.182016 | FunkMonk                                                                                                                                                              |
| 381 |    648.077604 |    786.790176 | Matt Crook                                                                                                                                                            |
| 382 |    385.226025 |    566.503238 | Meliponicultor Itaymbere                                                                                                                                              |
| 383 |    788.341673 |    741.635228 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                                         |
| 384 |     24.595474 |    670.603670 | Ferran Sayol                                                                                                                                                          |
| 385 |    146.362716 |    693.677145 | Yusan Yang                                                                                                                                                            |
| 386 |    297.137791 |    292.306898 | Jagged Fang Designs                                                                                                                                                   |
| 387 |    590.851937 |    120.262704 | Steven Traver                                                                                                                                                         |
| 388 |   1015.630714 |    461.095034 | DW Bapst, modified from Figure 1 of Belanger (2011, PALAIOS).                                                                                                         |
| 389 |    821.418431 |    709.052327 | Matt Crook                                                                                                                                                            |
| 390 |    735.772662 |    769.867977 | Margot Michaud                                                                                                                                                        |
| 391 |    395.524390 |    116.110769 | Yan Wong                                                                                                                                                              |
| 392 |    786.926307 |    322.090639 | Gopal Murali                                                                                                                                                          |
| 393 |    527.471652 |     74.610202 | Karla Martinez                                                                                                                                                        |
| 394 |    152.520268 |    506.173571 | Felix Vaux                                                                                                                                                            |
| 395 |    297.559823 |    621.162913 | Dean Schnabel                                                                                                                                                         |
| 396 |    273.366758 |    250.511476 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 397 |    473.140041 |    661.133211 | Tasman Dixon                                                                                                                                                          |
| 398 |    825.422103 |    789.378118 | Steven Traver                                                                                                                                                         |
| 399 |    645.521398 |    162.150043 | Birgit Lang                                                                                                                                                           |
| 400 |    902.746052 |    297.903396 | Alex Slavenko                                                                                                                                                         |
| 401 |    614.911057 |    252.702145 | Zimices                                                                                                                                                               |
| 402 |   1000.970824 |    142.807411 | Jakovche                                                                                                                                                              |
| 403 |    463.384224 |     71.082448 | Tasman Dixon                                                                                                                                                          |
| 404 |    247.934689 |    629.984870 | Matt Crook                                                                                                                                                            |
| 405 |    130.634363 |    632.598217 | Andreas Hejnol                                                                                                                                                        |
| 406 |    145.681965 |    641.116467 | Matt Crook                                                                                                                                                            |
| 407 |    824.010512 |    200.894047 | Richard Ruggiero, vectorized by Zimices                                                                                                                               |
| 408 |    786.307752 |    133.550258 | Zimices                                                                                                                                                               |
| 409 |    204.752456 |     87.845014 | Matt Crook                                                                                                                                                            |
| 410 |    543.405595 |     34.264341 | Ferran Sayol                                                                                                                                                          |
| 411 |    242.298128 |    557.044039 | Dmitry Bogdanov                                                                                                                                                       |
| 412 |    323.630749 |    460.017620 | CNZdenek                                                                                                                                                              |
| 413 |    525.798657 |    705.594597 | Steven Traver                                                                                                                                                         |
| 414 |    987.406378 |    355.001486 | Chris huh                                                                                                                                                             |
| 415 |    924.696423 |    393.116717 | Margot Michaud                                                                                                                                                        |
| 416 |    239.413497 |    339.581146 | Sam Droege (photo) and T. Michael Keesey (vectorization)                                                                                                              |
| 417 |    244.378212 |     86.857213 | John Curtis (vectorized by T. Michael Keesey)                                                                                                                         |
| 418 |    819.153272 |    110.403885 | Steven Traver                                                                                                                                                         |
| 419 |    719.207351 |    496.920572 | Berivan Temiz                                                                                                                                                         |
| 420 |     55.491713 |    139.566924 | Matt Crook                                                                                                                                                            |
| 421 |    621.713712 |    271.787982 | Jagged Fang Designs                                                                                                                                                   |
| 422 |    477.694828 |     52.269054 | Geoff Shaw                                                                                                                                                            |
| 423 |    956.944134 |    694.578438 | Tommaso Cancellario                                                                                                                                                   |
| 424 |    291.470816 |    787.759657 | Kai R. Caspar                                                                                                                                                         |
| 425 |    618.993720 |     10.400304 | Ludwik Gasiorowski                                                                                                                                                    |
| 426 |    877.520853 |    449.650936 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 427 |    390.663301 |    767.330630 | Julio Garza                                                                                                                                                           |
| 428 |    881.769451 |    416.130522 | Noah Schlottman, photo from Casey Dunn                                                                                                                                |
| 429 |    985.146206 |    330.943651 | Birgit Lang                                                                                                                                                           |
| 430 |      7.884925 |    282.230211 | Steven Traver                                                                                                                                                         |
| 431 |    821.570928 |    326.304711 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 432 |    903.448631 |    412.752845 | Gareth Monger                                                                                                                                                         |
| 433 |    587.475445 |    264.482728 | Margot Michaud                                                                                                                                                        |
| 434 |    221.863798 |    161.958349 | NA                                                                                                                                                                    |
| 435 |    754.308164 |    684.548535 | Matt Martyniuk                                                                                                                                                        |
| 436 |    254.631052 |     14.436804 | Mihai Dragos (vectorized by T. Michael Keesey)                                                                                                                        |
| 437 |    530.248044 |    599.108434 | Matt Crook                                                                                                                                                            |
| 438 |    617.414314 |    398.441830 | NA                                                                                                                                                                    |
| 439 |    689.549096 |    371.607350 | Steven Traver                                                                                                                                                         |
| 440 |     71.934853 |    648.922538 | Mali’o Kodis, photograph by John Slapcinsky                                                                                                                           |
| 441 |    833.519101 |    511.274523 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 442 |    600.469381 |    286.348014 | Matt Martyniuk                                                                                                                                                        |
| 443 |    838.104560 |    321.529116 | Margot Michaud                                                                                                                                                        |
| 444 |   1006.338497 |    534.439255 | Jagged Fang Designs                                                                                                                                                   |
| 445 |    492.246695 |    336.506104 | Elizabeth Parker                                                                                                                                                      |
| 446 |    914.583970 |    677.812345 | Yusan Yang                                                                                                                                                            |
| 447 |    590.497178 |    588.155746 | Yan Wong                                                                                                                                                              |
| 448 |    106.251098 |    259.493523 | Steven Traver                                                                                                                                                         |
| 449 |     65.006598 |    745.756735 | Maija Karala                                                                                                                                                          |
| 450 |    944.330308 |    174.230084 | Scott Hartman                                                                                                                                                         |
| 451 |    134.567482 |    333.680665 | Michael P. Taylor                                                                                                                                                     |
| 452 |    830.908845 |    401.589656 | Kamil S. Jaron                                                                                                                                                        |
| 453 |    709.434426 |    732.285535 | Chris huh                                                                                                                                                             |
| 454 |    436.139221 |    192.868267 | Emily Willoughby                                                                                                                                                      |
| 455 |    864.550457 |    211.156197 | Zimices                                                                                                                                                               |
| 456 |    699.248371 |    786.244036 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                              |
| 457 |    290.914896 |    380.662892 | NA                                                                                                                                                                    |
| 458 |    661.911298 |    237.272320 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 459 |    326.498819 |    266.918982 | Steven Traver                                                                                                                                                         |
| 460 |     39.650521 |    296.466690 | Mathilde Cordellier                                                                                                                                                   |
| 461 |    240.712131 |    424.599621 | Matt Crook                                                                                                                                                            |
| 462 |    914.948894 |    569.130688 | Cristopher Silva                                                                                                                                                      |
| 463 |    101.108923 |    776.030141 | Zimices                                                                                                                                                               |
| 464 |    611.356440 |    767.764332 | Collin Gross                                                                                                                                                          |
| 465 |    835.979685 |     17.771587 | Lee Harding (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
| 466 |    965.764480 |    460.197059 | Sharon Wegner-Larsen                                                                                                                                                  |
| 467 |    568.532004 |    587.980720 | Steven Traver                                                                                                                                                         |
| 468 |    420.712357 |    472.971905 | T. Michael Keesey (after Tillyard)                                                                                                                                    |
| 469 |    517.821305 |    749.754377 | NA                                                                                                                                                                    |
| 470 |    102.858548 |    717.432529 | Cesar Julian                                                                                                                                                          |
| 471 |    317.331711 |    786.990011 | Zimices                                                                                                                                                               |
| 472 |    923.074853 |    201.868018 | David Tana                                                                                                                                                            |
| 473 |    398.071684 |    133.088212 | Tasman Dixon                                                                                                                                                          |
| 474 |    656.242566 |    714.488959 | Scott Hartman                                                                                                                                                         |
| 475 |    714.732346 |     98.151079 | Margot Michaud                                                                                                                                                        |
| 476 |    189.666824 |    731.422623 | NA                                                                                                                                                                    |
| 477 |    466.577827 |    289.616651 | Pete Buchholz                                                                                                                                                         |
| 478 |    930.131509 |    353.436531 | Gareth Monger                                                                                                                                                         |
| 479 |    458.540502 |    609.826564 | T. Michael Keesey                                                                                                                                                     |
| 480 |    786.899669 |    203.387327 | Jaime Headden                                                                                                                                                         |
| 481 |    261.097226 |    113.370538 | NA                                                                                                                                                                    |
| 482 |    462.357024 |     93.673314 | T. Michael Keesey                                                                                                                                                     |
| 483 |    423.773534 |    199.072764 | Matt Crook                                                                                                                                                            |
| 484 |    775.676779 |    165.206693 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 485 |     98.280261 |    133.107493 | Jagged Fang Designs                                                                                                                                                   |
| 486 |     67.301092 |    663.793099 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 487 |    817.871738 |    695.149964 | NA                                                                                                                                                                    |
| 488 |    750.013323 |    739.868777 | Henry Lydecker                                                                                                                                                        |
| 489 |    680.942143 |    332.286118 | Matt Crook                                                                                                                                                            |
| 490 |    187.926074 |    196.211851 | T. Michael Keesey (after Ponomarenko)                                                                                                                                 |
| 491 |    852.169208 |    335.320529 | Christoph Schomburg                                                                                                                                                   |
| 492 |    144.691089 |    718.871025 | Zimices                                                                                                                                                               |
| 493 |    420.845134 |    186.839947 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                        |
| 494 |    458.735095 |     82.342015 | Zimices                                                                                                                                                               |
| 495 |    825.853218 |    394.032685 | Chris huh                                                                                                                                                             |
| 496 |    433.567156 |    784.159033 | Margot Michaud                                                                                                                                                        |
| 497 |    114.024506 |     57.114388 | Mattia Menchetti                                                                                                                                                      |
| 498 |   1013.738622 |    633.843038 | Jagged Fang Designs                                                                                                                                                   |
| 499 |    993.679518 |     13.705665 | T. Michael Keesey                                                                                                                                                     |
| 500 |    451.289808 |    782.747389 | Zimices                                                                                                                                                               |
| 501 |     92.898163 |    551.607536 | Dean Schnabel                                                                                                                                                         |
| 502 |     33.887436 |    735.601321 | Chris huh                                                                                                                                                             |
| 503 |    439.624283 |    133.153606 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 504 |    191.037457 |    339.527256 | NA                                                                                                                                                                    |
| 505 |    289.243109 |    323.437711 | Margot Michaud                                                                                                                                                        |
| 506 |    147.440193 |    568.299656 | Margot Michaud                                                                                                                                                        |
| 507 |    775.423006 |    211.183526 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 508 |    217.650425 |    245.835321 | Sarah Werning                                                                                                                                                         |
| 509 |    385.567325 |     43.133388 | Zimices                                                                                                                                                               |
| 510 |    901.579006 |    358.544587 | Mattia Menchetti / Yan Wong                                                                                                                                           |
| 511 |    859.614662 |    410.304475 | Ray Simpson (vectorized by T. Michael Keesey)                                                                                                                         |
| 512 |    339.582143 |    467.609980 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 513 |    954.089692 |    311.394068 | Tasman Dixon                                                                                                                                                          |
| 514 |   1014.599659 |    706.689044 | Kamil S. Jaron                                                                                                                                                        |
| 515 |    285.826812 |    365.098042 | T. Michael Keesey (photo by Sean Mack)                                                                                                                                |
| 516 |    369.082904 |    138.988522 | Margot Michaud                                                                                                                                                        |
| 517 |    483.771962 |    380.586754 | Rebecca Groom                                                                                                                                                         |
| 518 |    735.951628 |    326.950268 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                      |
| 519 |    842.545494 |    590.285968 | T. Michael Keesey                                                                                                                                                     |
| 520 |    836.651226 |    126.246994 | Gareth Monger                                                                                                                                                         |
| 521 |    775.281404 |    586.686629 | Margot Michaud                                                                                                                                                        |
| 522 |    319.350965 |    749.035163 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 523 |    906.932332 |    521.972086 | Yan Wong                                                                                                                                                              |
| 524 |    612.921901 |    357.243449 | Chris huh                                                                                                                                                             |
| 525 |    367.358984 |    550.637320 | Jonathan Wells                                                                                                                                                        |
| 526 |    565.410551 |    198.414865 | Dean Schnabel                                                                                                                                                         |
| 527 |   1003.274120 |    505.294556 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 528 |    815.178251 |    261.261984 | Lukas Panzarin                                                                                                                                                        |
| 529 |    132.259979 |     93.616424 | Zimices                                                                                                                                                               |
| 530 |     31.876049 |    754.909471 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 531 |    349.322250 |    129.221552 | Anthony Caravaggi                                                                                                                                                     |
| 532 |    128.053226 |    745.568023 | Marie Russell                                                                                                                                                         |
| 533 |    123.942671 |    397.141527 | Don Armstrong                                                                                                                                                         |
| 534 |    137.125971 |    195.249849 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 535 |   1014.717777 |    730.924377 | Lukasiniho                                                                                                                                                            |
| 536 |    690.486527 |    173.070494 | Matt Crook                                                                                                                                                            |
| 537 |    243.999507 |    541.937426 | Matt Crook                                                                                                                                                            |
| 538 |    575.536602 |     68.996701 | Margot Michaud                                                                                                                                                        |
| 539 |   1013.827730 |    102.917503 | Maxime Dahirel                                                                                                                                                        |
| 540 |    673.649147 |    302.246159 | T. Michael Keesey (after Joseph Wolf)                                                                                                                                 |
| 541 |    517.109111 |    579.712751 | B. Duygu Özpolat                                                                                                                                                      |
| 542 |    940.991740 |    418.411007 | Tauana J. Cunha                                                                                                                                                       |
| 543 |    755.874464 |    147.965064 | Harold N Eyster                                                                                                                                                       |
| 544 |    651.822627 |    605.610760 | Jagged Fang Designs                                                                                                                                                   |
| 545 |    263.461113 |     74.202005 | Mali’o Kodis, photograph by John Slapcinsky                                                                                                                           |
| 546 |    570.222773 |     76.935104 | David Orr                                                                                                                                                             |
| 547 |   1012.688978 |      7.248005 | James R. Spotila and Ray Chatterji                                                                                                                                    |
| 548 |     41.548361 |    719.157191 | Kai R. Caspar                                                                                                                                                         |
| 549 |    515.490006 |    568.099148 | Ferran Sayol                                                                                                                                                          |
| 550 |    147.571911 |     44.393438 | Gareth Monger                                                                                                                                                         |
| 551 |   1015.738348 |    358.229112 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 552 |    435.279289 |    523.076647 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 553 |    780.064573 |    622.314350 | Maxime Dahirel (digitisation), Kees van Achterberg et al (doi: 10.3897/BDJ.8.e49017)(original publication)                                                            |
| 554 |    803.305344 |    640.506017 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 555 |    562.186550 |    705.012653 | Zimices                                                                                                                                                               |
| 556 |    589.406317 |    759.665630 | NA                                                                                                                                                                    |
| 557 |    534.875675 |    197.522072 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 558 |    852.596113 |    289.870713 | Ferran Sayol                                                                                                                                                          |
| 559 |    344.710268 |     10.907897 | Brockhaus and Efron                                                                                                                                                   |
| 560 |    737.953910 |     67.588080 | L. Shyamal                                                                                                                                                            |
| 561 |    539.335767 |     23.542195 | Matt Crook                                                                                                                                                            |
| 562 |    183.713098 |    438.180061 | Andrew A. Farke                                                                                                                                                       |
| 563 |    916.798179 |    558.682184 | Christoph Schomburg                                                                                                                                                   |
| 564 |     56.752533 |    399.286436 | Darius Nau                                                                                                                                                            |
| 565 |    928.916075 |    688.361815 | Meliponicultor Itaymbere                                                                                                                                              |
| 566 |    236.230645 |    243.601331 | Matt Crook                                                                                                                                                            |
| 567 |    982.270461 |    671.768593 | Andrew A. Farke                                                                                                                                                       |
| 568 |    351.709094 |      8.922561 | Saguaro Pictures (source photo) and T. Michael Keesey                                                                                                                 |
| 569 |    701.555817 |    529.409382 | Felix Vaux                                                                                                                                                            |
| 570 |     10.788800 |    785.553313 | Daniel Stadtmauer                                                                                                                                                     |
| 571 |    459.570586 |    203.343966 | NA                                                                                                                                                                    |
| 572 |    491.844997 |    433.846153 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 573 |   1009.581740 |    177.832531 | Matt Crook                                                                                                                                                            |
| 574 |    255.013162 |    248.237045 | Chris huh                                                                                                                                                             |
| 575 |    223.400195 |    547.770322 | Steven Traver                                                                                                                                                         |
| 576 |    638.780983 |    584.778541 | T. Michael Keesey                                                                                                                                                     |
| 577 |    598.635838 |    428.851445 | Andrew A. Farke                                                                                                                                                       |
| 578 |    882.619818 |    779.684170 | T. Michael Keesey                                                                                                                                                     |
| 579 |    358.447663 |    353.272885 | Gareth Monger                                                                                                                                                         |
| 580 |    957.721315 |    342.382644 | Mark Witton                                                                                                                                                           |
| 581 |    838.683098 |    444.989448 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 582 |    529.066920 |    276.918339 | Birgit Lang, based on a photo by D. Sikes                                                                                                                             |
| 583 |    922.265089 |    182.958518 | Alexandre Vong                                                                                                                                                        |
| 584 |    508.033082 |    201.374325 | Martin R. Smith, after Skovsted et al 2015                                                                                                                            |
| 585 |    429.261636 |    318.271748 | Dean Schnabel                                                                                                                                                         |
| 586 |     63.416502 |    550.691337 | Gabriel Lio, vectorized by Zimices                                                                                                                                    |
| 587 |    154.578275 |    554.730919 | T. Tischler                                                                                                                                                           |
| 588 |    755.895994 |    503.488118 | Margot Michaud                                                                                                                                                        |
| 589 |    108.783749 |    764.954182 | Scott Hartman                                                                                                                                                         |
| 590 |    690.975626 |    730.983693 | Felix Vaux                                                                                                                                                            |
| 591 |    763.705417 |    675.206717 | Tasman Dixon                                                                                                                                                          |
| 592 |    134.734021 |    610.915678 | Felix Vaux                                                                                                                                                            |
| 593 |     55.334480 |    487.122081 | NA                                                                                                                                                                    |
| 594 |    618.993877 |    164.635644 | Margot Michaud                                                                                                                                                        |
| 595 |      9.348376 |     36.056344 | NA                                                                                                                                                                    |
| 596 |     16.138121 |    475.664577 | Matt Crook                                                                                                                                                            |
| 597 |    290.406014 |    735.688700 | T. Michael Keesey                                                                                                                                                     |
| 598 |    805.037316 |    309.095669 | Margot Michaud                                                                                                                                                        |
| 599 |    352.769617 |    597.146841 | Michelle Site                                                                                                                                                         |
| 600 |    643.163609 |    120.605071 | T. Michael Keesey (after James & al.)                                                                                                                                 |
| 601 |    747.590871 |     79.499742 | Anilocra (vectorization by Yan Wong)                                                                                                                                  |
| 602 |    612.527256 |    482.690516 | Martin R. Smith, from photo by Jürgen Schoner                                                                                                                         |
| 603 |    297.364168 |    134.246592 | Beth Reinke                                                                                                                                                           |
| 604 |    315.156529 |    605.560584 | Kenneth Lacovara (vectorized by T. Michael Keesey)                                                                                                                    |
| 605 |    363.990575 |     65.157198 | Sean McCann                                                                                                                                                           |
| 606 |    611.363843 |     55.417713 | Matt Crook                                                                                                                                                            |
| 607 |    366.710306 |    526.607124 | NA                                                                                                                                                                    |
| 608 |     48.806051 |    614.756199 | Felix Vaux                                                                                                                                                            |
| 609 |    732.700153 |    316.819656 | NA                                                                                                                                                                    |
| 610 |    927.532734 |    792.188283 | Zimices                                                                                                                                                               |
| 611 |    650.748981 |    329.442124 | NA                                                                                                                                                                    |
| 612 |     76.368699 |    658.828147 | T. Michael Keesey                                                                                                                                                     |
| 613 |    774.630469 |    653.238832 | M Kolmann                                                                                                                                                             |
| 614 |     84.624237 |    643.319598 | Samanta Orellana                                                                                                                                                      |
| 615 |    160.602928 |    577.991318 | Mason McNair                                                                                                                                                          |
| 616 |     28.200481 |     44.085353 | Michael Scroggie                                                                                                                                                      |
| 617 |    452.722440 |    516.203856 | Matt Crook                                                                                                                                                            |
| 618 |    386.389998 |    132.996647 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 619 |    631.098636 |    484.255029 | Melissa Broussard                                                                                                                                                     |
| 620 |    940.307287 |    662.700744 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 621 |    137.923461 |    176.437657 | M. Antonio Todaro, Tobias Kånneby, Matteo Dal Zotto, and Ulf Jondelius (vectorized by T. Michael Keesey)                                                              |
| 622 |     93.641509 |    257.786433 | Christoph Schomburg                                                                                                                                                   |
| 623 |    422.305076 |    776.562150 | Zimices                                                                                                                                                               |
| 624 |    920.269118 |    346.306198 | Esme Ashe-Jepson                                                                                                                                                      |
| 625 |    711.376761 |    130.476635 | Zimices                                                                                                                                                               |
| 626 |     10.337289 |    559.860768 | Tauana J. Cunha                                                                                                                                                       |
| 627 |    502.328215 |    588.698293 | NA                                                                                                                                                                    |
| 628 |    546.631697 |    796.917213 | Zimices                                                                                                                                                               |
| 629 |     18.162290 |    191.200671 | Michelle Site                                                                                                                                                         |
| 630 |      7.580615 |    198.401961 | Chris huh                                                                                                                                                             |
| 631 |     65.858868 |    682.405913 | Chris huh                                                                                                                                                             |
| 632 |    297.481145 |    196.416273 | Antonov (vectorized by T. Michael Keesey)                                                                                                                             |
| 633 |    240.036001 |    255.015187 | Kailah Thorn & Mark Hutchinson                                                                                                                                        |
| 634 |     60.182094 |    339.612655 | Matt Crook                                                                                                                                                            |
| 635 |    352.265624 |    647.165954 | Peileppe                                                                                                                                                              |
| 636 |    789.458082 |    719.628221 | Matt Crook                                                                                                                                                            |
| 637 |    358.697804 |    285.281428 | T. Michael Keesey                                                                                                                                                     |
| 638 |    943.027675 |    508.785570 | Scott Hartman                                                                                                                                                         |
| 639 |    293.430934 |    256.092111 | Margot Michaud                                                                                                                                                        |
| 640 |    870.118284 |    507.416799 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 641 |      6.470476 |    296.029561 | Birgit Lang                                                                                                                                                           |
| 642 |   1012.356193 |    655.144805 | Birgit Lang                                                                                                                                                           |
| 643 |    523.450746 |    473.990982 | Margot Michaud                                                                                                                                                        |
| 644 |    619.397939 |    207.688876 | Zimices                                                                                                                                                               |
| 645 |     68.928582 |    331.993824 | Gareth Monger                                                                                                                                                         |
| 646 |    962.379138 |    789.356278 | Steven Traver                                                                                                                                                         |
| 647 |     70.944901 |    773.926593 | Trond R. Oskars                                                                                                                                                       |
| 648 |    386.020644 |    651.596832 | Xavier Giroux-Bougard                                                                                                                                                 |
| 649 |    488.172614 |    791.580628 | C. Abraczinskas                                                                                                                                                       |
| 650 |     81.691703 |    479.936508 | Zimices                                                                                                                                                               |
| 651 |    238.920560 |    434.279352 | Oliver Griffith                                                                                                                                                       |
| 652 |    560.579798 |    443.602744 | Plukenet                                                                                                                                                              |
| 653 |    819.814233 |    127.850670 | Zimices                                                                                                                                                               |
| 654 |    962.216251 |    671.041471 | Kailah Thorn & Ben King                                                                                                                                               |
| 655 |    398.062888 |    224.563449 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 656 |    368.907356 |    583.021022 | Jagged Fang Designs                                                                                                                                                   |
| 657 |    545.599321 |    442.625180 | Ferran Sayol                                                                                                                                                          |
| 658 |    172.427146 |    157.871666 | Zimices                                                                                                                                                               |
| 659 |    939.895092 |    735.268257 | Nina Skinner                                                                                                                                                          |
| 660 |      7.649050 |    255.145183 | Milton Tan                                                                                                                                                            |
| 661 |    359.657716 |    105.763235 | Tasman Dixon                                                                                                                                                          |
| 662 |    845.256921 |    495.465368 | Kamil S. Jaron                                                                                                                                                        |
| 663 |    551.662849 |    565.244862 | Zimices                                                                                                                                                               |
| 664 |    722.735652 |    487.737688 | Jagged Fang Designs                                                                                                                                                   |
| 665 |    264.752711 |     20.771339 | Margot Michaud                                                                                                                                                        |
| 666 |    116.125943 |    652.060678 | T. Michael Keesey (after Kukalová)                                                                                                                                    |
| 667 |    868.991268 |    398.739021 | Zimices                                                                                                                                                               |
| 668 |    166.090358 |    525.066515 | Scott Hartman                                                                                                                                                         |
| 669 |    928.602017 |    676.763684 | Zimices                                                                                                                                                               |
| 670 |    898.034379 |    543.934078 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                      |
| 671 |     74.929535 |    455.461635 | T. Michael Keesey (after Joseph Wolf)                                                                                                                                 |
| 672 |    576.266509 |    757.685369 | Michelle Site                                                                                                                                                         |
| 673 |    874.520464 |    116.273612 | Matt Crook                                                                                                                                                            |
| 674 |    643.977064 |    474.935198 | Scott Hartman                                                                                                                                                         |
| 675 |    908.995326 |     52.382075 | Yan Wong                                                                                                                                                              |
| 676 |    591.285578 |    711.853822 | Birgit Lang                                                                                                                                                           |
| 677 |    482.344689 |    787.160916 | Jagged Fang Designs                                                                                                                                                   |
| 678 |    866.189341 |     16.993770 | Ferran Sayol                                                                                                                                                          |
| 679 |    820.877983 |     31.782125 | Matt Crook                                                                                                                                                            |
| 680 |    785.948803 |    334.629693 | Dean Schnabel                                                                                                                                                         |
| 681 |    148.021709 |    371.557061 | Matt Crook                                                                                                                                                            |
| 682 |    252.307164 |    319.795486 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 683 |    602.995112 |    259.856949 | Joanna Wolfe                                                                                                                                                          |
| 684 |    526.513929 |    130.160130 | Mathilde Cordellier                                                                                                                                                   |
| 685 |    209.789931 |    114.190434 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 686 |    404.063755 |    301.317517 | Margot Michaud                                                                                                                                                        |
| 687 |    980.374707 |    431.344340 | Zimices                                                                                                                                                               |
| 688 |     94.036456 |     55.648782 | Jaime Headden                                                                                                                                                         |
| 689 |    596.086353 |    136.437697 | Gareth Monger                                                                                                                                                         |
| 690 |    905.147366 |    183.983030 | Gareth Monger                                                                                                                                                         |
| 691 |    839.021723 |    708.783928 | Matt Celeskey                                                                                                                                                         |
| 692 |    659.079996 |    507.384166 | NA                                                                                                                                                                    |
| 693 |    850.864821 |     10.273051 | Alex Slavenko                                                                                                                                                         |
| 694 |    741.653269 |    217.722765 | Remes K, Ortega F, Fierro I, Joger U, Kosma R, et al.                                                                                                                 |
| 695 |   1013.480121 |    526.217845 | Katie S. Collins                                                                                                                                                      |
| 696 |    276.016844 |    353.902696 | Crystal Maier                                                                                                                                                         |
| 697 |    345.797474 |    231.783263 | Mathew Wedel                                                                                                                                                          |
| 698 |    984.556240 |    218.329438 | Margot Michaud                                                                                                                                                        |
| 699 |    980.961295 |    210.338275 | Matt Crook                                                                                                                                                            |
| 700 |    100.367164 |    797.469994 | Jagged Fang Designs                                                                                                                                                   |
| 701 |     91.680711 |    623.658015 | Lauren Anderson                                                                                                                                                       |
| 702 |    765.475468 |    793.848557 | Matt Crook                                                                                                                                                            |
| 703 |    508.286638 |     76.566471 | xgirouxb                                                                                                                                                              |
| 704 |    550.716621 |    411.592324 | Danielle Alba                                                                                                                                                         |
| 705 |    572.734650 |    169.099793 | Katie S. Collins                                                                                                                                                      |
| 706 |    836.298443 |    617.510950 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 707 |    207.653180 |    231.482354 | Trond R. Oskars                                                                                                                                                       |
| 708 |    337.606368 |    752.684235 | Iain Reid                                                                                                                                                             |
| 709 |    138.648044 |    598.310388 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 710 |    654.702663 |    379.924104 | Matt Crook                                                                                                                                                            |
| 711 |    740.146509 |    515.086252 | Matus Valach                                                                                                                                                          |
| 712 |    259.821973 |    300.243333 | mystica                                                                                                                                                               |
| 713 |    877.747682 |    702.967882 | Michelle Site                                                                                                                                                         |
| 714 |    621.627996 |     72.056128 | Xavier A. Jenkins, Gabriel Ugueto                                                                                                                                     |
| 715 |    214.388035 |    452.406322 | Robbie Cada (vectorized by T. Michael Keesey)                                                                                                                         |
| 716 |    648.870715 |    492.309912 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 717 |    933.181756 |    280.774059 | NA                                                                                                                                                                    |
| 718 |    924.294653 |    168.957324 | Steven Traver                                                                                                                                                         |
| 719 |    862.785429 |    789.622242 | Scott Hartman                                                                                                                                                         |
| 720 |    233.867479 |    139.951237 | Meyers Konversations-Lexikon 1897 (vectorized: Yan Wong)                                                                                                              |
| 721 |    669.297456 |    600.016994 | Manabu Bessho-Uehara                                                                                                                                                  |
| 722 |    765.253627 |    335.137505 | Sarah Werning                                                                                                                                                         |
| 723 |   1012.612773 |     30.362315 | Sam Droege (photography) and T. Michael Keesey (vectorization)                                                                                                        |
| 724 |    841.098242 |    792.171284 | Abraão B. Leite                                                                                                                                                       |
| 725 |    404.344650 |    202.777930 | Martin R. Smith, from photo by Jürgen Schoner                                                                                                                         |
| 726 |    626.939392 |    741.774630 | Lukasiniho                                                                                                                                                            |
| 727 |    682.069287 |    361.024364 | Kai R. Caspar                                                                                                                                                         |
| 728 |    361.671581 |    719.959640 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 729 |     63.241609 |    349.647801 | Zimices                                                                                                                                                               |
| 730 |    706.444291 |    186.368439 | Matt Crook                                                                                                                                                            |
| 731 |    485.685771 |    178.732727 | Margot Michaud                                                                                                                                                        |
| 732 |    150.476022 |    226.984088 | Maija Karala                                                                                                                                                          |
| 733 |    814.474113 |    312.174240 | Birgit Lang                                                                                                                                                           |
| 734 |    478.667308 |    389.566403 | Katie S. Collins                                                                                                                                                      |
| 735 |     33.541696 |    327.491270 | Zimices                                                                                                                                                               |
| 736 |    717.636627 |     83.423748 | Birgit Lang                                                                                                                                                           |
| 737 |    772.245669 |    738.310441 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 738 |    291.536123 |    113.451329 | Shyamal                                                                                                                                                               |
| 739 |    178.284477 |    409.748592 | Steven Traver                                                                                                                                                         |
| 740 |    945.466405 |    210.808129 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 741 |    632.287586 |    598.522071 | Margot Michaud                                                                                                                                                        |
| 742 |   1004.979238 |    129.479743 | Zimices                                                                                                                                                               |
| 743 |    919.388993 |      7.424924 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 744 |    982.506081 |    321.371641 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                        |
| 745 |     19.207863 |    514.472799 | Matt Crook                                                                                                                                                            |
| 746 |    891.829516 |    100.964160 | Matt Crook                                                                                                                                                            |
| 747 |    718.558247 |    626.074618 | Michael Scroggie                                                                                                                                                      |
| 748 |    250.483656 |    685.113117 | Dmitry Bogdanov                                                                                                                                                       |
| 749 |    279.845791 |    772.723299 | Zimices                                                                                                                                                               |
| 750 |    739.048075 |    490.471925 | Benjamint444                                                                                                                                                          |
| 751 |    764.787003 |    453.335041 | Mali’o Kodis, photograph by Derek Keats (<http://www.flickr.com/photos/dkeats/>)                                                                                      |
| 752 |    794.147698 |    612.876367 | Jaime Headden                                                                                                                                                         |
| 753 |    988.553482 |    719.229842 | Steven Traver                                                                                                                                                         |
| 754 |    639.463224 |    134.627178 | Scott Hartman                                                                                                                                                         |
| 755 |    741.751446 |    167.732527 | Matt Crook                                                                                                                                                            |
| 756 |     91.510151 |    419.884210 | Zimices                                                                                                                                                               |
| 757 |    985.831581 |    524.048787 | Chris huh                                                                                                                                                             |
| 758 |    964.948301 |    506.599883 | T. Michael Keesey and Tanetahi                                                                                                                                        |
| 759 |    466.367320 |    794.484443 | Chris huh                                                                                                                                                             |
| 760 |     63.097390 |    385.892835 | Emily Willoughby                                                                                                                                                      |
| 761 |    311.450640 |    425.762119 | Lukasiniho                                                                                                                                                            |
| 762 |    804.088671 |    747.411324 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 763 |    157.831843 |    313.264973 | Francesco Veronesi (vectorized by T. Michael Keesey)                                                                                                                  |
| 764 |    419.485005 |    133.561791 | Gareth Monger                                                                                                                                                         |
| 765 |    653.764920 |    148.727578 | Charles R. Knight (vectorized by T. Michael Keesey)                                                                                                                   |
| 766 |    456.632119 |    600.203280 | T. Michael Keesey (after Kukalová)                                                                                                                                    |
| 767 |    604.912027 |    771.559725 | Bill Bouton (source photo) & T. Michael Keesey (vectorization)                                                                                                        |
| 768 |    831.041266 |    118.501483 | Catherine Yasuda                                                                                                                                                      |
| 769 |    191.600360 |    541.955435 | Matt Wilkins (photo by Patrick Kavanagh)                                                                                                                              |
| 770 |    365.490467 |     11.885363 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 771 |    252.371543 |    266.595666 | Scott Hartman                                                                                                                                                         |
| 772 |    413.435623 |    523.867033 | Allison Pease                                                                                                                                                         |
| 773 |    709.992811 |    171.668111 | Michelle Site                                                                                                                                                         |
| 774 |    200.032758 |    570.899566 | Sarah Werning                                                                                                                                                         |
| 775 |     21.733695 |    765.282173 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 776 |    478.544443 |    401.640576 | Zimices                                                                                                                                                               |
| 777 |    895.078502 |     47.952284 | Birgit Lang                                                                                                                                                           |
| 778 |    553.352057 |    713.000407 | Margot Michaud                                                                                                                                                        |
| 779 |    307.212376 |    215.534498 | Michelle Site                                                                                                                                                         |
| 780 |    860.012169 |    276.386425 | Gareth Monger                                                                                                                                                         |
| 781 |    898.644569 |    539.260364 | Chris huh                                                                                                                                                             |
| 782 |    818.524152 |    490.953126 | Gareth Monger                                                                                                                                                         |
| 783 |    901.406281 |    784.625812 | Birgit Lang                                                                                                                                                           |
| 784 |    187.822970 |     74.075981 | Mattia Menchetti                                                                                                                                                      |
| 785 |    683.548023 |    200.517803 | Beth Reinke                                                                                                                                                           |
| 786 |    585.640652 |     83.298047 | NA                                                                                                                                                                    |
| 787 |    713.523748 |    531.896968 | CNZdenek                                                                                                                                                              |
| 788 |    317.714932 |    639.178678 | Andrew A. Farke                                                                                                                                                       |
| 789 |   1007.480074 |    441.538414 | Harold N Eyster                                                                                                                                                       |
| 790 |    148.398153 |    706.411152 | Zimices                                                                                                                                                               |
| 791 |    109.303670 |    387.761019 | T. Michael Keesey                                                                                                                                                     |
| 792 |    881.999090 |    247.844074 | Jake Warner                                                                                                                                                           |
| 793 |    581.650123 |     10.326401 | Armin Reindl                                                                                                                                                          |
| 794 |    438.230707 |    668.895080 | Zimices                                                                                                                                                               |
| 795 |     15.404770 |    652.158764 | Crystal Maier                                                                                                                                                         |
| 796 |    495.046850 |    287.367850 | Natasha Vitek                                                                                                                                                         |
| 797 |    739.571362 |    188.847961 | Margot Michaud                                                                                                                                                        |
| 798 |    769.997662 |    149.512440 | T. Michael Keesey                                                                                                                                                     |
| 799 |    275.738288 |    121.156917 | Margot Michaud                                                                                                                                                        |
| 800 |     50.654268 |    117.506184 | Joanna Wolfe                                                                                                                                                          |
| 801 |    498.261764 |    366.010421 | Campbell Fleming                                                                                                                                                      |
| 802 |    881.545442 |    392.818237 | Gareth Monger                                                                                                                                                         |
| 803 |    659.088705 |    524.597644 | Kai R. Caspar                                                                                                                                                         |
| 804 |    129.360671 |     55.318873 | Sarah Werning                                                                                                                                                         |
| 805 |    253.703129 |     47.028288 | NA                                                                                                                                                                    |
| 806 |    353.916440 |    206.052178 | Zimices                                                                                                                                                               |
| 807 |    448.524414 |    504.348260 | Matt Crook                                                                                                                                                            |
| 808 |    985.434396 |    306.423859 | Steven Traver                                                                                                                                                         |
| 809 |    322.377094 |    608.536084 | Margot Michaud                                                                                                                                                        |
| 810 |    667.085317 |    340.270833 | DW Bapst, modified from Figure 1 of Belanger (2011, PALAIOS).                                                                                                         |
| 811 |    635.909518 |    153.438873 | Tasman Dixon                                                                                                                                                          |
| 812 |    299.493486 |     70.454978 | Michael Scroggie, from original photograph by John Bettaso, USFWS (original photograph in public domain).                                                             |
| 813 |     62.670127 |    536.711468 | Margot Michaud                                                                                                                                                        |
| 814 |    942.722217 |    143.511078 | NA                                                                                                                                                                    |
| 815 |    961.029250 |    439.099170 | Tauana J. Cunha                                                                                                                                                       |
| 816 |    325.521653 |    453.101915 | C. Camilo Julián-Caballero                                                                                                                                            |
| 817 |    973.042790 |    746.774165 | Tasman Dixon                                                                                                                                                          |
| 818 |    989.816137 |    253.065698 | Michele M Tobias from an image By Dcrjsr - Own work, CC BY 3.0, <https://commons.wikimedia.org/w/index.php?curid=18059686>                                            |
| 819 |    780.503327 |    789.718266 | T. Michael Keesey                                                                                                                                                     |
| 820 |    941.627735 |    330.612398 | Jagged Fang Designs                                                                                                                                                   |
| 821 |    420.718147 |    108.480788 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
| 822 |    578.886381 |    457.092112 | V. Deepak                                                                                                                                                             |
| 823 |    474.989043 |    701.181360 | NASA                                                                                                                                                                  |
| 824 |     21.261657 |    212.529074 | FunkMonk \[Michael B.H.\] (modified by T. Michael Keesey)                                                                                                             |
| 825 |    130.444206 |    684.254490 | Taro Maeda                                                                                                                                                            |
| 826 |    644.461711 |    508.689329 | Tauana J. Cunha                                                                                                                                                       |
| 827 |    875.264630 |    187.429147 | Mariana Ruiz (vectorized by T. Michael Keesey)                                                                                                                        |
| 828 |     97.828523 |    246.585907 | Margot Michaud                                                                                                                                                        |
| 829 |     69.563390 |    136.305651 | Caroline Harding, MAF (vectorized by T. Michael Keesey)                                                                                                               |
| 830 |    266.509710 |    402.643661 | NA                                                                                                                                                                    |
| 831 |    802.407280 |    782.538401 | Milton Tan                                                                                                                                                            |
| 832 |    700.562267 |    714.904911 | NA                                                                                                                                                                    |
| 833 |     13.062741 |     14.277144 | Rebecca Groom                                                                                                                                                         |
| 834 |    138.478771 |    305.057143 | Steven Traver                                                                                                                                                         |
| 835 |    382.174692 |     63.105524 | Margot Michaud                                                                                                                                                        |
| 836 |    677.356635 |    261.524224 | Gareth Monger                                                                                                                                                         |
| 837 |    669.801204 |    644.040550 | Trond R. Oskars                                                                                                                                                       |
| 838 |    484.486190 |    494.561176 | Ferran Sayol                                                                                                                                                          |
| 839 |    765.485199 |    134.286053 | Joanna Wolfe                                                                                                                                                          |
| 840 |    774.062960 |    342.511834 | Gareth Monger                                                                                                                                                         |
| 841 |    670.149331 |    362.017734 | Harold N Eyster                                                                                                                                                       |
| 842 |    207.371340 |     15.460394 | Ferran Sayol                                                                                                                                                          |
| 843 |    851.100072 |    517.730200 | Emily Willoughby                                                                                                                                                      |
| 844 |    136.250791 |      3.294965 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 845 |    956.527030 |    525.446629 | NA                                                                                                                                                                    |
| 846 |    911.428246 |    460.098193 | Zimices                                                                                                                                                               |
| 847 |    253.031797 |    793.455319 | NA                                                                                                                                                                    |
| 848 |    731.861250 |    664.245341 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 849 |    950.113590 |    750.689948 | Geoff Shaw                                                                                                                                                            |
| 850 |    111.372760 |    791.935659 | Ferran Sayol                                                                                                                                                          |
| 851 |     39.235514 |     53.685450 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 852 |     92.403903 |    165.526507 | Zimices                                                                                                                                                               |
| 853 |    427.736456 |    536.008676 | V. Deepak                                                                                                                                                             |
| 854 |     80.939047 |    595.461058 | Steven Traver                                                                                                                                                         |
| 855 |    817.581717 |    444.483441 | Iain Reid                                                                                                                                                             |
| 856 |    668.591270 |    605.249372 | Tyler Greenfield and Scott Hartman                                                                                                                                    |
| 857 |    112.838027 |    246.275562 | Ferran Sayol                                                                                                                                                          |
| 858 |    110.330226 |    339.855224 | T. Michael Keesey (after Kukalová)                                                                                                                                    |
| 859 |    617.061231 |    474.190411 | Scott Hartman                                                                                                                                                         |
| 860 |    861.557164 |    312.211677 | Michelle Site                                                                                                                                                         |
| 861 |    679.942887 |    502.487802 | T. Michael Keesey (after C. De Muizon)                                                                                                                                |
| 862 |    958.142242 |    203.380447 | Melissa Broussard                                                                                                                                                     |
| 863 |    566.943698 |    785.699143 | Steven Traver                                                                                                                                                         |
| 864 |    722.725787 |    738.249522 | C. Camilo Julián-Caballero                                                                                                                                            |
| 865 |    613.267218 |     41.094971 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 866 |    913.552138 |    663.354224 | T. Michael Keesey (from a photo by Maximilian Paradiz)                                                                                                                |
| 867 |    349.308445 |    107.033867 | Rebecca Groom                                                                                                                                                         |
| 868 |    172.823275 |     11.134301 | Margot Michaud                                                                                                                                                        |
| 869 |    687.102992 |    553.628090 | Kent Elson Sorgon                                                                                                                                                     |
| 870 |    324.567664 |    767.617305 | Manabu Sakamoto                                                                                                                                                       |
| 871 |     97.374353 |    679.456540 | Matthias Buschmann (vectorized by T. Michael Keesey)                                                                                                                  |
| 872 |    838.792644 |    311.515040 | Jennifer Trimble                                                                                                                                                      |
| 873 |    240.265718 |    150.647060 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 874 |    432.689979 |    744.470671 | Gareth Monger                                                                                                                                                         |
| 875 |    985.545750 |    159.250652 | Gareth Monger                                                                                                                                                         |
| 876 |    969.494294 |    128.524726 | Ferran Sayol                                                                                                                                                          |
| 877 |    708.778586 |    609.093021 | NA                                                                                                                                                                    |
| 878 |    820.109698 |    523.867942 | Harold N Eyster                                                                                                                                                       |
| 879 |    863.188301 |    261.407623 | Beth Reinke                                                                                                                                                           |
| 880 |    820.458917 |    286.772121 | Tyler Greenfield                                                                                                                                                      |
| 881 |    732.908973 |    160.443229 | Katie S. Collins                                                                                                                                                      |
| 882 |    512.326458 |    539.086637 | Mike Hanson                                                                                                                                                           |
| 883 |    331.660762 |    224.128561 | Eduard Solà (vectorized by T. Michael Keesey)                                                                                                                         |
| 884 |    889.397271 |    794.987503 | NA                                                                                                                                                                    |
| 885 |    399.420089 |    541.990623 | Mateus Zica (modified by T. Michael Keesey)                                                                                                                           |
| 886 |    262.477297 |    569.544083 | Zimices                                                                                                                                                               |
| 887 |     24.949851 |    132.551455 | Ferran Sayol                                                                                                                                                          |
| 888 |    803.306060 |    494.106801 | Matt Crook                                                                                                                                                            |
| 889 |    651.358278 |    595.160253 | Antonov (vectorized by T. Michael Keesey)                                                                                                                             |
| 890 |    887.105332 |    715.939939 | Derek Bakken (photograph) and T. Michael Keesey (vectorization)                                                                                                       |
| 891 |    912.777218 |    124.393686 | Mali’o Kodis, photograph by G. Giribet                                                                                                                                |
| 892 |    375.011956 |    517.494828 | Katie S. Collins                                                                                                                                                      |
| 893 |    725.413981 |    242.743694 | Michael Scroggie                                                                                                                                                      |
| 894 |    520.850445 |    276.894661 | Kai R. Caspar                                                                                                                                                         |
| 895 |     47.856589 |     53.808243 | Trond R. Oskars                                                                                                                                                       |
| 896 |    985.526475 |    666.656732 | Julia B McHugh                                                                                                                                                        |
| 897 |    836.723235 |    488.041734 | T. Michael Keesey                                                                                                                                                     |
| 898 |    354.430817 |    734.014160 | Zimices                                                                                                                                                               |
| 899 |    332.506858 |    636.715023 | Gareth Monger                                                                                                                                                         |
| 900 |     73.693062 |    379.862498 | Zimices                                                                                                                                                               |
| 901 |    953.363377 |    121.708274 | T. Michael Keesey                                                                                                                                                     |
| 902 |     24.860134 |    589.286687 | Steven Traver                                                                                                                                                         |
| 903 |     33.791422 |    660.248153 | Gareth Monger                                                                                                                                                         |
| 904 |    943.278745 |     32.095067 | Mathew Callaghan                                                                                                                                                      |
| 905 |    260.805797 |    781.978839 | Joedison Rocha                                                                                                                                                        |
| 906 |    916.851431 |    116.225459 | Scott Hartman                                                                                                                                                         |
| 907 |    978.231475 |    282.387639 | Zimices                                                                                                                                                               |
| 908 |    751.769744 |    730.578200 | NA                                                                                                                                                                    |
| 909 |    335.364937 |    104.288160 | Steven Traver                                                                                                                                                         |
| 910 |     59.651823 |     67.534861 | C. Camilo Julián-Caballero                                                                                                                                            |
| 911 |    879.021835 |    498.021180 | Iain Reid                                                                                                                                                             |
| 912 |     25.298580 |    243.216345 | Chris huh                                                                                                                                                             |
| 913 |    615.523026 |    385.426195 | Scott Hartman                                                                                                                                                         |

    #> Your tweet has been posted!
