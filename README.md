
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

Michele M Tobias, Nobu Tamura (vectorized by T. Michael Keesey), Jack
Mayer Wood, Neil Kelley, Zimices, Gareth Monger, Matt Crook, Dmitry
Bogdanov (vectorized by T. Michael Keesey), Tauana J. Cunha, Marie
Russell, Pete Buchholz, Gabriela Palomo-Munoz, Tracy A. Heath, Margot
Michaud, Tasman Dixon, MPF (vectorized by T. Michael Keesey), Xavier
Giroux-Bougard, Ferran Sayol, James R. Spotila and Ray Chatterji, Hans
Hillewaert (vectorized by T. Michael Keesey), Emily Jane McTavish, from
Haeckel, E. H. P. A. (1904).Kunstformen der Natur. Bibliographisches,
SauropodomorphMonarch, Andrew A. Farke, Sharon Wegner-Larsen, Ignacio
Contreras, Birgit Lang, T. Michael Keesey (after MPF), Scott Hartman,
Iain Reid, Skye M, J Levin W (illustration) and T. Michael Keesey
(vectorization), T. Michael Keesey, Michelle Site, Chris huh, Collin
Gross, Cesar Julian, Felix Vaux, (unknown), Julio Garza, Chris A.
Hamilton, Scott Hartman (vectorized by T. Michael Keesey), Jagged Fang
Designs, U.S. National Park Service (vectorized by William Gearty), Tim
Bertelink (modified by T. Michael Keesey), Luis Cunha, Alexander
Schmidt-Lebuhn, Markus A. Grohme, Scott Hartman (modified by T. Michael
Keesey), Alex Slavenko, Ghedoghedo (vectorized by T. Michael Keesey),
Steven Coombs (vectorized by T. Michael Keesey), Zachary Quigley, Skye
McDavid, Manabu Sakamoto, Nobu Tamura (modified by T. Michael Keesey),
George Edward Lodge (vectorized by T. Michael Keesey), Nobu Tamura,
modified by Andrew A. Farke, Lukasiniho, Martin R. Smith, Sergio A.
Muñoz-Gómez, C. Camilo Julián-Caballero, Sean McCann, Jose Carlos
Arenas-Monroy, Mattia Menchetti, Steven Traver, Original drawing by
Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja, Joanna Wolfe, Manabu
Bessho-Uehara, Matt Martyniuk (vectorized by T. Michael Keesey), Noah
Schlottman, Melissa Broussard, Martin Kevil, Joedison Rocha, Kamil S.
Jaron, Henry Lydecker, FunkMonk, Armin Reindl, Dean Schnabel, Filip em,
CNZdenek, Nobu Tamura, vectorized by Zimices, B Kimmel, Jaime Headden,
Mathilde Cordellier, Matt Dempsey, T. Michael Keesey (photo by Sean
Mack), Brad McFeeters (vectorized by T. Michael Keesey), Matt Martyniuk,
Rebecca Groom, xgirouxb, Vanessa Guerra, Sarah Werning, Luc Viatour
(source photo) and Andreas Plank, Michael Scroggie, Jiekun He, Maija
Karala, Siobhon Egan, Giant Blue Anteater (vectorized by T. Michael
Keesey), Mr E? (vectorized by T. Michael Keesey), Mario Quevedo, DW
Bapst, modified from Ishitani et al. 2016, Mathieu Pélissié, Beth
Reinke, Xavier A. Jenkins, Gabriel Ugueto, Theodore W. Pietsch
(photography) and T. Michael Keesey (vectorization), Noah Schlottman,
photo from Casey Dunn, Mali’o Kodis, photograph by P. Funch and R.M.
Kristensen, White Wolf, Noah Schlottman, photo by Martin V. Sørensen,
Jonathan Wells, Hanyong Pu, Yoshitsugu Kobayashi, Junchang Lü, Li Xu,
Yanhua Wu, Huali Chang, Jiming Zhang, Songhai Jia & T. Michael Keesey,
L. Shyamal, Benchill, Noah Schlottman, photo by Carlos Sánchez-Ortiz,
Sherman F. Denton via rawpixel.com (illustration) and Timothy J. Bartley
(silhouette), Lani Mohan, Andy Wilson, Harold N Eyster, Karla Martinez,
LeonardoG (photography) and T. Michael Keesey (vectorization), Mercedes
Yrayzoz (vectorized by T. Michael Keesey), Emily Willoughby, Caleb M.
Brown, T. Michael Keesey (after Mauricio Antón), Baheerathan Murugavel,
Shyamal, T. Tischler, terngirl, Mette Aumala, Gopal Murali,
Terpsichores, Nobu Tamura, Obsidian Soul (vectorized by T. Michael
Keesey), Javier Luque, Jan A. Venter, Herbert H. T. Prins, David A.
Balfour & Rob Slotow (vectorized by T. Michael Keesey), Ville-Veikko
Sinkkonen, (after Spotila 2004), Nina Skinner, Michael Scroggie, from
original photograph by Gary M. Stolz, USFWS (original photograph in
public domain)., Jimmy Bernot, Frederick William Frohawk (vectorized by
T. Michael Keesey), Mathieu Basille, Mathew Callaghan, Antonov
(vectorized by T. Michael Keesey), Trond R. Oskars, Matt Celeskey, Emily
Jane McTavish, from
<http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>,
Matt Hayes, Christoph Schomburg, Mason McNair, Hugo Gruson,
Myriam\_Ramirez, Maxime Dahirel, Tony Ayling (vectorized by T. Michael
Keesey), Robert Bruce Horsfall (vectorized by William Gearty), Tyler
Greenfield, Steven Coombs, Alexandre Vong, Fritz Geller-Grimm
(vectorized by T. Michael Keesey), Lily Hughes, Chuanixn Yu, Carlos
Cano-Barbacil, Juan Carlos Jerí, NOAA Great Lakes Environmental Research
Laboratory (illustration) and Timothy J. Bartley (silhouette), Burton
Robert, USFWS, Erika Schumacher, Yan Wong, Tess Linden, Dmitry Bogdanov,
C. Abraczinskas, Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric
M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus, Espen
Horn (model; vectorized by T. Michael Keesey from a photo by H. Zell),
Steven Haddock • Jellywatch.org, Fernando Campos De Domenico, Oscar
Sanisidro, 于川云, Lukas Panzarin (vectorized by T. Michael Keesey), H.
Filhol (vectorized by T. Michael Keesey), Christine Axon, New York
Zoological Society, Inessa Voet, Nancy Wyman (photo), John E. McCormack,
Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C.
Glenn, Robb T. Brumfield & T. Michael Keesey, Ellen Edmonson and Hugh
Chrisp (illustration) and Timothy J. Bartley (silhouette), Jessica Rick,
Matthew E. Clapham, Eric Moody, Stanton F. Fink (vectorized by T.
Michael Keesey), T. Michael Keesey (after James & al.), T. Michael
Keesey (vector) and Stuart Halliday (photograph), Sam Droege
(photography) and T. Michael Keesey (vectorization), T. Michael Keesey
(after Monika Betley), Mali’o Kodis, image from the Smithsonian
Institution, Robert Hering, Meyer-Wachsmuth I, Curini Galletti M,
Jondelius U (<doi:10.1371/journal.pone.0107688>). Vectorization by Y.
Wong, James Neenan, Matthew Hooge (vectorized by T. Michael Keesey),
Mariana Ruiz Villarreal (modified by T. Michael Keesey), Anthony
Caravaggi, Lisa Byrne, Kristina Gagalova, Maxime Dahirel (digitisation),
Kees van Achterberg et al (doi: 10.3897/BDJ.8.e49017)(original
publication), André Karwath (vectorized by T. Michael Keesey),
AnAgnosticGod (vectorized by T. Michael Keesey), Marie-Aimée Allard,
Walter Vladimir, Renato Santos, Jakovche, Chloé Schmidt, Вальдимар
(vectorized by T. Michael Keesey), Jake Warner, George Edward Lodge,
Daniel Jaron, Didier Descouens (vectorized by T. Michael Keesey), John
Gould (vectorized by T. Michael Keesey), Steve Hillebrand/U. S. Fish and
Wildlife Service (source photo), T. Michael Keesey (vectorization), M
Kolmann, Aviceda (photo) & T. Michael Keesey, Michael “FunkMonk” B. H.
(vectorized by T. Michael Keesey), Ghedoghedo, Michael B. H. (vectorized
by T. Michael Keesey), Mali’o Kodis, photograph by Aqua-Photos
(<http://www.flickr.com/people/undervannsfotografen/>), Noah Schlottman,
photo by Casey Dunn, Yan Wong (vectorization) from 1873 illustration,
Dann Pigdon, Kimberly Haddrell, Joe Schneid (vectorized by T. Michael
Keesey), Kai R. Caspar, Haplochromis (vectorized by T. Michael Keesey),
DW Bapst (modified from Mitchell 1990), Unknown (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Paul O. Lewis,
Martin R. Smith, after Skovsted et al 2015, Chris Jennings (vectorized
by A. Verrière), V. Deepak, Konsta Happonen, from a CC-BY-NC image by
sokolkov2002 on iNaturalist, Jon M Laurent, Andreas Hejnol, Apokryltaros
(vectorized by T. Michael Keesey), Milton Tan, Mateus Zica (modified by
T. Michael Keesey), Yan Wong from drawing by T. F. Zimmermann,
Smokeybjb, S.Martini, Mali’o Kodis, photograph by “Wildcat Dunny”
(<http://www.flickr.com/people/wildcat_dunny/>), Chris Jennings
(Risiatto), Mali’o Kodis, photograph by Jim Vargo, Air Kebir NRG, Tod
Robbins, David Orr, Amanda Katzer, Original drawing by Nobu Tamura,
vectorized by Roberto Díaz Sibaja, Don Armstrong, Mariana Ruiz
Villarreal, Samanta Orellana, L.M. Davalos, Julie Blommaert based on
photo by Sofdrakou, Ieuan Jones, Philip Chalmers (vectorized by T.
Michael Keesey), NASA, Tim H. Heupink, Leon Huynen, and David M. Lambert
(vectorized by T. Michael Keesey), TaraTaylorDesign, Evan-Amos
(vectorized by T. Michael Keesey), Cristopher Silva, Jessica Anne
Miller, T. Michael Keesey (after Ponomarenko), Tomas Willems (vectorized
by T. Michael Keesey)

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                      |
| --: | ------------: | ------------: | :---------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    758.144338 |    636.937620 | Michele M Tobias                                                                                                                                            |
|   2 |    363.783440 |     67.387137 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                               |
|   3 |    938.539241 |    626.197051 | Jack Mayer Wood                                                                                                                                             |
|   4 |    258.198872 |    333.028303 | Neil Kelley                                                                                                                                                 |
|   5 |    709.179766 |    411.274385 | Zimices                                                                                                                                                     |
|   6 |    604.881452 |    217.854852 | Gareth Monger                                                                                                                                               |
|   7 |    472.835926 |    312.583301 | Gareth Monger                                                                                                                                               |
|   8 |    917.127837 |    165.896871 | Zimices                                                                                                                                                     |
|   9 |    425.461178 |    711.483941 | Matt Crook                                                                                                                                                  |
|  10 |    406.819525 |    556.428666 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                           |
|  11 |    216.291727 |    664.243844 | Tauana J. Cunha                                                                                                                                             |
|  12 |     81.178926 |    250.845585 | Marie Russell                                                                                                                                               |
|  13 |    105.859065 |    512.460789 | Pete Buchholz                                                                                                                                               |
|  14 |    375.336501 |    481.891673 | Gabriela Palomo-Munoz                                                                                                                                       |
|  15 |    914.808628 |    744.987444 | Tracy A. Heath                                                                                                                                              |
|  16 |    471.651149 |    397.255462 | Margot Michaud                                                                                                                                              |
|  17 |    444.297718 |    464.282838 | Tasman Dixon                                                                                                                                                |
|  18 |    670.627929 |    503.716086 | MPF (vectorized by T. Michael Keesey)                                                                                                                       |
|  19 |    624.626440 |    347.946345 | Matt Crook                                                                                                                                                  |
|  20 |    874.345536 |     30.345495 | Xavier Giroux-Bougard                                                                                                                                       |
|  21 |    102.157829 |    610.365246 | Matt Crook                                                                                                                                                  |
|  22 |    201.617698 |     43.585956 | Margot Michaud                                                                                                                                              |
|  23 |    220.150552 |    224.149817 | Ferran Sayol                                                                                                                                                |
|  24 |    913.905502 |    292.105258 | James R. Spotila and Ray Chatterji                                                                                                                          |
|  25 |    403.052459 |    192.076632 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                           |
|  26 |    731.115330 |    186.483205 | Emily Jane McTavish, from Haeckel, E. H. P. A. (1904).Kunstformen der Natur. Bibliographisches                                                              |
|  27 |    542.248041 |     64.497412 | SauropodomorphMonarch                                                                                                                                       |
|  28 |    907.074610 |    389.178125 | Andrew A. Farke                                                                                                                                             |
|  29 |    266.201472 |    539.761404 | Sharon Wegner-Larsen                                                                                                                                        |
|  30 |    694.998607 |    742.171293 | Ignacio Contreras                                                                                                                                           |
|  31 |    256.390589 |    429.688417 | Birgit Lang                                                                                                                                                 |
|  32 |    562.570271 |    518.571105 | T. Michael Keesey (after MPF)                                                                                                                               |
|  33 |    963.604937 |    484.059830 | Scott Hartman                                                                                                                                               |
|  34 |    240.713379 |    124.779714 | Iain Reid                                                                                                                                                   |
|  35 |    751.650234 |    267.497180 | Matt Crook                                                                                                                                                  |
|  36 |    719.336207 |     75.127478 | Skye M                                                                                                                                                      |
|  37 |    798.153111 |    528.905836 | J Levin W (illustration) and T. Michael Keesey (vectorization)                                                                                              |
|  38 |     81.888874 |    396.109364 | T. Michael Keesey                                                                                                                                           |
|  39 |    366.103067 |    372.529412 | Michelle Site                                                                                                                                               |
|  40 |    781.766882 |    707.063979 | Chris huh                                                                                                                                                   |
|  41 |    534.072465 |    757.667431 | Tasman Dixon                                                                                                                                                |
|  42 |    614.330852 |    122.869904 | Collin Gross                                                                                                                                                |
|  43 |    627.080974 |    784.448726 | Scott Hartman                                                                                                                                               |
|  44 |    346.369014 |    688.094813 | Matt Crook                                                                                                                                                  |
|  45 |    308.774664 |    285.866065 | Cesar Julian                                                                                                                                                |
|  46 |     80.333195 |    100.168183 | Felix Vaux                                                                                                                                                  |
|  47 |     79.764656 |    749.673142 | Gareth Monger                                                                                                                                               |
|  48 |    921.969713 |     79.247281 | Scott Hartman                                                                                                                                               |
|  49 |    912.579607 |    432.357394 | (unknown)                                                                                                                                                   |
|  50 |    614.313672 |    696.556677 | Gareth Monger                                                                                                                                               |
|  51 |    148.631521 |    314.220903 | Julio Garza                                                                                                                                                 |
|  52 |    600.701657 |    616.456041 | Zimices                                                                                                                                                     |
|  53 |    564.470790 |    272.476528 | Gareth Monger                                                                                                                                               |
|  54 |    962.544864 |    564.927792 | Chris A. Hamilton                                                                                                                                           |
|  55 |    369.123662 |    605.265598 | Matt Crook                                                                                                                                                  |
|  56 |    236.725280 |    772.120267 | Scott Hartman (vectorized by T. Michael Keesey)                                                                                                             |
|  57 |    247.337098 |    156.650140 | Jagged Fang Designs                                                                                                                                         |
|  58 |    819.358997 |    761.022698 | U.S. National Park Service (vectorized by William Gearty)                                                                                                   |
|  59 |    781.831311 |    358.527246 | Tim Bertelink (modified by T. Michael Keesey)                                                                                                               |
|  60 |    885.071111 |    635.396482 | Luis Cunha                                                                                                                                                  |
|  61 |    600.376929 |    491.204583 | Alexander Schmidt-Lebuhn                                                                                                                                    |
|  62 |    221.341836 |    576.687445 | Markus A. Grohme                                                                                                                                            |
|  63 |    321.430233 |    233.078873 | Scott Hartman                                                                                                                                               |
|  64 |    629.323379 |     33.146154 | Scott Hartman (modified by T. Michael Keesey)                                                                                                               |
|  65 |    542.844568 |     32.769399 | Alex Slavenko                                                                                                                                               |
|  66 |    428.879013 |     54.971976 | Gareth Monger                                                                                                                                               |
|  67 |     78.332226 |    455.027585 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                |
|  68 |    991.958786 |    244.734298 | Gareth Monger                                                                                                                                               |
|  69 |    508.458013 |    180.753664 | Margot Michaud                                                                                                                                              |
|  70 |    674.433436 |    768.684077 | Iain Reid                                                                                                                                                   |
|  71 |    731.046953 |    322.553306 | Steven Coombs (vectorized by T. Michael Keesey)                                                                                                             |
|  72 |    909.787182 |    361.729841 | Alex Slavenko                                                                                                                                               |
|  73 |     62.876114 |    563.858260 | Markus A. Grohme                                                                                                                                            |
|  74 |    936.686888 |    498.978102 | Scott Hartman                                                                                                                                               |
|  75 |    208.637264 |    724.188544 | Zachary Quigley                                                                                                                                             |
|  76 |     83.001213 |    665.108983 | Skye McDavid                                                                                                                                                |
|  77 |    977.249397 |     51.554393 | Matt Crook                                                                                                                                                  |
|  78 |    808.207385 |    212.405486 | Gareth Monger                                                                                                                                               |
|  79 |    536.135119 |    697.329203 | Matt Crook                                                                                                                                                  |
|  80 |   1005.937793 |    681.311225 | Manabu Sakamoto                                                                                                                                             |
|  81 |    173.318474 |    133.792989 | Margot Michaud                                                                                                                                              |
|  82 |    529.571060 |    355.791149 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                 |
|  83 |    544.563021 |    303.176255 | George Edward Lodge (vectorized by T. Michael Keesey)                                                                                                       |
|  84 |    611.446704 |    745.582249 | NA                                                                                                                                                          |
|  85 |    700.787554 |    718.897847 | Nobu Tamura, modified by Andrew A. Farke                                                                                                                    |
|  86 |    312.975008 |     21.423849 | Lukasiniho                                                                                                                                                  |
|  87 |    865.708549 |    218.651230 | Gareth Monger                                                                                                                                               |
|  88 |    940.242475 |     48.677272 | Martin R. Smith                                                                                                                                             |
|  89 |    630.302733 |    427.567895 | Gabriela Palomo-Munoz                                                                                                                                       |
|  90 |    142.682408 |    197.659574 | Zimices                                                                                                                                                     |
|  91 |    437.448329 |    278.430314 | Sergio A. Muñoz-Gómez                                                                                                                                       |
|  92 |    286.262668 |    372.014281 | Gareth Monger                                                                                                                                               |
|  93 |     64.576605 |    316.153182 | Margot Michaud                                                                                                                                              |
|  94 |     32.453472 |    684.792864 | Tracy A. Heath                                                                                                                                              |
|  95 |    897.488970 |    454.515068 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                               |
|  96 |    977.542629 |    647.326662 | Matt Crook                                                                                                                                                  |
|  97 |    143.210800 |    246.794876 | T. Michael Keesey                                                                                                                                           |
|  98 |    987.415595 |    169.230413 | C. Camilo Julián-Caballero                                                                                                                                  |
|  99 |    857.364219 |    690.622156 | Sean McCann                                                                                                                                                 |
| 100 |    892.896649 |    544.030944 | Jose Carlos Arenas-Monroy                                                                                                                                   |
| 101 |   1003.864778 |     27.770503 | Mattia Menchetti                                                                                                                                            |
| 102 |    506.385624 |    539.882826 | Steven Traver                                                                                                                                               |
| 103 |    284.576252 |     73.873284 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                      |
| 104 |    852.421866 |    241.451801 | Joanna Wolfe                                                                                                                                                |
| 105 |    709.059802 |    781.877359 | Manabu Bessho-Uehara                                                                                                                                        |
| 106 |    512.235935 |    472.201582 | Andrew A. Farke                                                                                                                                             |
| 107 |    333.022914 |    156.687719 | Zimices                                                                                                                                                     |
| 108 |    951.201403 |    419.681315 | Gabriela Palomo-Munoz                                                                                                                                       |
| 109 |    824.259821 |    379.137030 | Collin Gross                                                                                                                                                |
| 110 |    556.632930 |    452.377676 | Scott Hartman                                                                                                                                               |
| 111 |    130.606140 |    119.320716 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                            |
| 112 |    432.171473 |    604.761979 | Zimices                                                                                                                                                     |
| 113 |    308.412142 |    135.081219 | Birgit Lang                                                                                                                                                 |
| 114 |    717.578481 |    620.584563 | Margot Michaud                                                                                                                                              |
| 115 |    190.603176 |    545.921113 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                           |
| 116 |    163.889279 |    445.473341 | Martin R. Smith                                                                                                                                             |
| 117 |    794.410169 |    434.561207 | Matt Crook                                                                                                                                                  |
| 118 |    470.694594 |     29.356314 | Noah Schlottman                                                                                                                                             |
| 119 |    411.760912 |    499.170205 | Melissa Broussard                                                                                                                                           |
| 120 |    813.163208 |    400.060960 | Martin Kevil                                                                                                                                                |
| 121 |     58.193306 |     27.593191 | Matt Crook                                                                                                                                                  |
| 122 |    994.332435 |    325.324103 | Sharon Wegner-Larsen                                                                                                                                        |
| 123 |    704.674432 |    245.879406 | Matt Crook                                                                                                                                                  |
| 124 |    848.551149 |    455.570178 | Joedison Rocha                                                                                                                                              |
| 125 |    640.333858 |    240.793279 | Gabriela Palomo-Munoz                                                                                                                                       |
| 126 |    781.476939 |    120.771092 | Matt Crook                                                                                                                                                  |
| 127 |    972.219874 |    697.658586 | Andrew A. Farke                                                                                                                                             |
| 128 |     46.768017 |    345.970574 | Kamil S. Jaron                                                                                                                                              |
| 129 |    342.502502 |    508.229350 | NA                                                                                                                                                          |
| 130 |    827.973158 |    100.120844 | Henry Lydecker                                                                                                                                              |
| 131 |    416.730773 |    100.478406 | FunkMonk                                                                                                                                                    |
| 132 |    577.252402 |    353.792457 | T. Michael Keesey                                                                                                                                           |
| 133 |    631.315458 |     65.342181 | Zimices                                                                                                                                                     |
| 134 |    211.848283 |    370.462903 | Armin Reindl                                                                                                                                                |
| 135 |    764.146379 |     34.476383 | Dean Schnabel                                                                                                                                               |
| 136 |    510.206142 |    318.971212 | Gareth Monger                                                                                                                                               |
| 137 |    254.868289 |    304.634721 | Kamil S. Jaron                                                                                                                                              |
| 138 |    111.011899 |     35.743193 | Zimices                                                                                                                                                     |
| 139 |     50.027632 |    187.496713 | Matt Crook                                                                                                                                                  |
| 140 |    503.548389 |    349.378683 | Matt Crook                                                                                                                                                  |
| 141 |   1010.581304 |    420.932848 | Matt Crook                                                                                                                                                  |
| 142 |    766.032691 |    729.895142 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                               |
| 143 |    875.870199 |    493.198572 | Ferran Sayol                                                                                                                                                |
| 144 |     18.411295 |     72.558777 | Filip em                                                                                                                                                    |
| 145 |    363.361985 |    255.694637 | Scott Hartman                                                                                                                                               |
| 146 |    658.407163 |    644.843480 | CNZdenek                                                                                                                                                    |
| 147 |    448.401580 |    241.079023 | Nobu Tamura, vectorized by Zimices                                                                                                                          |
| 148 |    758.199339 |    485.585370 | NA                                                                                                                                                          |
| 149 |    932.484988 |    652.143169 | B Kimmel                                                                                                                                                    |
| 150 |    223.448451 |    511.791826 | NA                                                                                                                                                          |
| 151 |    142.065223 |    403.262646 | Jagged Fang Designs                                                                                                                                         |
| 152 |    111.701253 |    695.281804 | Jaime Headden                                                                                                                                               |
| 153 |    148.905026 |    653.507095 | Mathilde Cordellier                                                                                                                                         |
| 154 |    988.397028 |    761.227014 | Matt Dempsey                                                                                                                                                |
| 155 |    240.435595 |    355.334553 | T. Michael Keesey (photo by Sean Mack)                                                                                                                      |
| 156 |    419.824469 |     14.909629 | Jagged Fang Designs                                                                                                                                         |
| 157 |    809.209465 |    626.236487 | Gareth Monger                                                                                                                                               |
| 158 |    917.656085 |    707.102063 | Zimices                                                                                                                                                     |
| 159 |    179.757810 |    514.281109 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                            |
| 160 |    715.821727 |    492.481744 | NA                                                                                                                                                          |
| 161 |    549.342153 |    109.118038 | Steven Traver                                                                                                                                               |
| 162 |    987.904674 |    710.862024 | Matt Martyniuk                                                                                                                                              |
| 163 |    277.271735 |    243.513757 | Matt Crook                                                                                                                                                  |
| 164 |    511.278397 |    244.103195 | Zimices                                                                                                                                                     |
| 165 |    811.952477 |    640.679800 | Gareth Monger                                                                                                                                               |
| 166 |    526.202839 |    693.455981 | Rebecca Groom                                                                                                                                               |
| 167 |    587.904517 |    660.616633 | Gareth Monger                                                                                                                                               |
| 168 |    718.336676 |    441.125419 | Steven Traver                                                                                                                                               |
| 169 |    367.422617 |     84.650024 | Iain Reid                                                                                                                                                   |
| 170 |     10.652744 |    336.393680 | T. Michael Keesey                                                                                                                                           |
| 171 |    816.936334 |    654.558718 | Margot Michaud                                                                                                                                              |
| 172 |    190.960344 |     94.601737 | xgirouxb                                                                                                                                                    |
| 173 |    165.562336 |    105.568761 | Zimices                                                                                                                                                     |
| 174 |    823.306411 |    279.950992 | T. Michael Keesey                                                                                                                                           |
| 175 |    679.137769 |    659.364328 | Vanessa Guerra                                                                                                                                              |
| 176 |    986.654468 |    357.492268 | Matt Martyniuk                                                                                                                                              |
| 177 |    799.647829 |    148.956090 | Sarah Werning                                                                                                                                               |
| 178 |    740.394079 |    486.542266 | Lukasiniho                                                                                                                                                  |
| 179 |    423.572552 |    248.989797 | Melissa Broussard                                                                                                                                           |
| 180 |    818.740320 |    228.629501 | Luc Viatour (source photo) and Andreas Plank                                                                                                                |
| 181 |    643.804155 |    791.177720 | Margot Michaud                                                                                                                                              |
| 182 |    405.156078 |    325.768408 | T. Michael Keesey                                                                                                                                           |
| 183 |    989.646348 |    625.352970 | Michael Scroggie                                                                                                                                            |
| 184 |    728.881590 |    702.461256 | Jiekun He                                                                                                                                                   |
| 185 |    286.043285 |     53.334187 | Zimices                                                                                                                                                     |
| 186 |    496.340356 |    303.431164 | Maija Karala                                                                                                                                                |
| 187 |    479.627554 |    507.183659 | Michael Scroggie                                                                                                                                            |
| 188 |    328.660728 |    605.463264 | Jagged Fang Designs                                                                                                                                         |
| 189 |    796.379406 |     34.510650 | NA                                                                                                                                                          |
| 190 |    389.890347 |    121.211278 | Margot Michaud                                                                                                                                              |
| 191 |     23.387027 |    211.702655 | Matt Crook                                                                                                                                                  |
| 192 |    801.005968 |     24.672751 | Iain Reid                                                                                                                                                   |
| 193 |    743.901878 |    748.580469 | Siobhon Egan                                                                                                                                                |
| 194 |    314.169449 |    265.352510 | Giant Blue Anteater (vectorized by T. Michael Keesey)                                                                                                       |
| 195 |    304.359094 |    390.062830 | NA                                                                                                                                                          |
| 196 |     75.091017 |    344.005894 | Mr E? (vectorized by T. Michael Keesey)                                                                                                                     |
| 197 |    950.086681 |    660.559770 | xgirouxb                                                                                                                                                    |
| 198 |    432.285838 |    629.862397 | Zimices                                                                                                                                                     |
| 199 |    582.467395 |    643.654813 | T. Michael Keesey                                                                                                                                           |
| 200 |    974.383619 |    581.504965 | NA                                                                                                                                                          |
| 201 |     43.802256 |    162.343615 | Mario Quevedo                                                                                                                                               |
| 202 |    985.541733 |    458.134095 | Dean Schnabel                                                                                                                                               |
| 203 |    278.738017 |    159.746081 | DW Bapst, modified from Ishitani et al. 2016                                                                                                                |
| 204 |    560.552143 |    330.862841 | Margot Michaud                                                                                                                                              |
| 205 |    142.807371 |    180.226859 | FunkMonk                                                                                                                                                    |
| 206 |    181.106165 |     90.392930 | Jagged Fang Designs                                                                                                                                         |
| 207 |    103.973531 |    217.449012 | Sarah Werning                                                                                                                                               |
| 208 |    752.611561 |    776.312942 | Mathieu Pélissié                                                                                                                                            |
| 209 |    869.507278 |    452.783160 | Beth Reinke                                                                                                                                                 |
| 210 |    959.927298 |     19.288061 | Margot Michaud                                                                                                                                              |
| 211 |    491.694612 |    133.485391 | FunkMonk                                                                                                                                                    |
| 212 |    516.054481 |    263.952879 | Xavier A. Jenkins, Gabriel Ugueto                                                                                                                           |
| 213 |    805.048351 |     14.935643 | Ferran Sayol                                                                                                                                                |
| 214 |    432.407193 |    111.273428 | Margot Michaud                                                                                                                                              |
| 215 |    184.595066 |    611.272517 | Matt Crook                                                                                                                                                  |
| 216 |    990.359392 |    437.266772 | Theodore W. Pietsch (photography) and T. Michael Keesey (vectorization)                                                                                     |
| 217 |    761.270475 |    384.264652 | Ignacio Contreras                                                                                                                                           |
| 218 |    694.696755 |    381.506195 | Noah Schlottman, photo from Casey Dunn                                                                                                                      |
| 219 |    301.954842 |    670.727038 | Beth Reinke                                                                                                                                                 |
| 220 |    417.030387 |    262.873205 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                           |
| 221 |    475.275093 |    575.569080 | Rebecca Groom                                                                                                                                               |
| 222 |    542.638290 |    405.615123 | Zimices                                                                                                                                                     |
| 223 |    574.886392 |    754.534423 | Mali’o Kodis, photograph by P. Funch and R.M. Kristensen                                                                                                    |
| 224 |     14.183923 |    120.873279 | Ferran Sayol                                                                                                                                                |
| 225 |    952.816606 |     33.512655 | NA                                                                                                                                                          |
| 226 |    811.575849 |    301.029209 | White Wolf                                                                                                                                                  |
| 227 |    665.040244 |    427.568155 | Margot Michaud                                                                                                                                              |
| 228 |    171.089842 |    211.790369 | Ferran Sayol                                                                                                                                                |
| 229 |    316.537378 |     95.479905 | NA                                                                                                                                                          |
| 230 |     50.800854 |    700.356251 | Noah Schlottman, photo by Martin V. Sørensen                                                                                                                |
| 231 |   1010.958985 |    786.804662 | Jonathan Wells                                                                                                                                              |
| 232 |    588.965432 |    170.513155 | Gareth Monger                                                                                                                                               |
| 233 |    631.327116 |    573.248639 | Chris huh                                                                                                                                                   |
| 234 |    742.357039 |    249.725717 | Gareth Monger                                                                                                                                               |
| 235 |    779.313674 |    601.858763 | T. Michael Keesey                                                                                                                                           |
| 236 |    668.092858 |    178.104027 | Steven Traver                                                                                                                                               |
| 237 |    961.205801 |    398.994169 | Hanyong Pu, Yoshitsugu Kobayashi, Junchang Lü, Li Xu, Yanhua Wu, Huali Chang, Jiming Zhang, Songhai Jia & T. Michael Keesey                                 |
| 238 |    331.730651 |    268.612942 | L. Shyamal                                                                                                                                                  |
| 239 |    966.142376 |    189.154537 | NA                                                                                                                                                          |
| 240 |    619.554353 |    402.047806 | Tasman Dixon                                                                                                                                                |
| 241 |    670.621591 |    723.063497 | NA                                                                                                                                                          |
| 242 |    700.785461 |    349.061526 | Steven Traver                                                                                                                                               |
| 243 |    315.935856 |    400.141488 | Benchill                                                                                                                                                    |
| 244 |    467.277935 |    528.532949 | Noah Schlottman, photo by Carlos Sánchez-Ortiz                                                                                                              |
| 245 |    680.834266 |    150.269284 | Sherman F. Denton via rawpixel.com (illustration) and Timothy J. Bartley (silhouette)                                                                       |
| 246 |    301.343645 |    486.214064 | Lani Mohan                                                                                                                                                  |
| 247 |     15.747010 |    251.859209 | Andy Wilson                                                                                                                                                 |
| 248 |    453.046278 |     29.323201 | NA                                                                                                                                                          |
| 249 |    658.123007 |     91.123932 | Harold N Eyster                                                                                                                                             |
| 250 |    838.710378 |    435.999262 | Gabriela Palomo-Munoz                                                                                                                                       |
| 251 |    932.135299 |    186.809447 | Karla Martinez                                                                                                                                              |
| 252 |    310.686749 |    515.468460 | Melissa Broussard                                                                                                                                           |
| 253 |    725.459437 |    547.052277 | LeonardoG (photography) and T. Michael Keesey (vectorization)                                                                                               |
| 254 |    259.238727 |     67.392257 | NA                                                                                                                                                          |
| 255 |     22.518280 |    596.154066 | Mercedes Yrayzoz (vectorized by T. Michael Keesey)                                                                                                          |
| 256 |    507.182740 |    732.749046 | Emily Willoughby                                                                                                                                            |
| 257 |     18.774617 |    191.531254 | NA                                                                                                                                                          |
| 258 |    844.541527 |    280.607998 | NA                                                                                                                                                          |
| 259 |    822.122205 |    118.391004 | Matt Crook                                                                                                                                                  |
| 260 |    658.937530 |    590.741404 | Caleb M. Brown                                                                                                                                              |
| 261 |    669.036820 |    341.925524 | Nobu Tamura, vectorized by Zimices                                                                                                                          |
| 262 |    335.629381 |    213.449837 | T. Michael Keesey (after Mauricio Antón)                                                                                                                    |
| 263 |    473.709029 |    142.412641 | Baheerathan Murugavel                                                                                                                                       |
| 264 |    562.955988 |    311.465964 | NA                                                                                                                                                          |
| 265 |    435.655861 |    359.711989 | Scott Hartman                                                                                                                                               |
| 266 |    171.673009 |    253.293835 | Matt Martyniuk                                                                                                                                              |
| 267 |    720.337863 |    573.927162 | Shyamal                                                                                                                                                     |
| 268 |    524.993796 |    106.268964 | Matt Martyniuk                                                                                                                                              |
| 269 |    627.025585 |     82.747845 | Scott Hartman                                                                                                                                               |
| 270 |    313.990229 |    779.134618 | Kamil S. Jaron                                                                                                                                              |
| 271 |    467.346031 |    428.877489 | T. Tischler                                                                                                                                                 |
| 272 |    757.557165 |    117.906889 | Matt Crook                                                                                                                                                  |
| 273 |    283.084322 |    355.305584 | Rebecca Groom                                                                                                                                               |
| 274 |    198.504843 |    258.672272 | Xavier Giroux-Bougard                                                                                                                                       |
| 275 |   1008.674245 |    520.537963 | terngirl                                                                                                                                                    |
| 276 |    447.589306 |    142.629269 | Gabriela Palomo-Munoz                                                                                                                                       |
| 277 |    109.068736 |    674.773438 | Mette Aumala                                                                                                                                                |
| 278 |    840.452367 |    792.556743 | Margot Michaud                                                                                                                                              |
| 279 |    100.105825 |    173.754935 | Gopal Murali                                                                                                                                                |
| 280 |     33.406298 |     52.537790 | Terpsichores                                                                                                                                                |
| 281 |    376.638895 |    637.963094 | Ferran Sayol                                                                                                                                                |
| 282 |    734.693870 |    120.361024 | Nobu Tamura                                                                                                                                                 |
| 283 |   1000.694220 |    590.442578 | Margot Michaud                                                                                                                                              |
| 284 |    112.319094 |     17.638738 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                             |
| 285 |    778.024760 |    298.249019 | Xavier Giroux-Bougard                                                                                                                                       |
| 286 |    370.204966 |    127.787271 | B Kimmel                                                                                                                                                    |
| 287 |    233.673666 |    180.836288 | Javier Luque                                                                                                                                                |
| 288 |    670.137058 |    303.833220 | Nobu Tamura, vectorized by Zimices                                                                                                                          |
| 289 |    865.308979 |    767.194700 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                         |
| 290 |     63.996107 |    441.013104 | Ville-Veikko Sinkkonen                                                                                                                                      |
| 291 |    120.233406 |    139.961969 | Mercedes Yrayzoz (vectorized by T. Michael Keesey)                                                                                                          |
| 292 |   1006.572842 |    432.069452 | (after Spotila 2004)                                                                                                                                        |
| 293 |    715.864605 |    669.414205 | Nina Skinner                                                                                                                                                |
| 294 |    297.318512 |    169.714926 | Michael Scroggie, from original photograph by Gary M. Stolz, USFWS (original photograph in public domain).                                                  |
| 295 |    284.983521 |    662.968756 | Jimmy Bernot                                                                                                                                                |
| 296 |    616.454983 |    653.134516 | Jagged Fang Designs                                                                                                                                         |
| 297 |    121.844403 |    221.966814 | Frederick William Frohawk (vectorized by T. Michael Keesey)                                                                                                 |
| 298 |    639.348396 |    207.302739 | Emily Willoughby                                                                                                                                            |
| 299 |    440.257228 |    315.584464 | Scott Hartman                                                                                                                                               |
| 300 |     17.782823 |     90.847679 | Zimices                                                                                                                                                     |
| 301 |    589.788339 |    759.624933 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                               |
| 302 |    135.664327 |    168.156553 | Scott Hartman                                                                                                                                               |
| 303 |    256.113813 |    703.031728 | Beth Reinke                                                                                                                                                 |
| 304 |    322.550905 |    608.849009 | Chris huh                                                                                                                                                   |
| 305 |    294.220460 |     24.083590 | Steven Traver                                                                                                                                               |
| 306 |    620.883973 |    673.082243 | Felix Vaux                                                                                                                                                  |
| 307 |    789.675377 |     86.306242 | Mathieu Basille                                                                                                                                             |
| 308 |     57.669524 |    581.778936 | Mathew Callaghan                                                                                                                                            |
| 309 |   1001.003113 |    314.355112 | Sarah Werning                                                                                                                                               |
| 310 |    666.689307 |    151.640232 | Andrew A. Farke                                                                                                                                             |
| 311 |    859.546519 |    489.892942 | Gareth Monger                                                                                                                                               |
| 312 |     58.707427 |    690.559186 | Matt Crook                                                                                                                                                  |
| 313 |    161.557986 |    266.628702 | NA                                                                                                                                                          |
| 314 |    511.593099 |    615.579886 | Antonov (vectorized by T. Michael Keesey)                                                                                                                   |
| 315 |     19.974118 |    313.552062 | Chris huh                                                                                                                                                   |
| 316 |    987.073410 |    744.249686 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                         |
| 317 |    625.549437 |    641.250685 | Trond R. Oskars                                                                                                                                             |
| 318 |    201.039727 |    156.133870 | Gareth Monger                                                                                                                                               |
| 319 |     21.661251 |    224.635339 | Gareth Monger                                                                                                                                               |
| 320 |    260.646044 |    627.000104 | Iain Reid                                                                                                                                                   |
| 321 |    398.027602 |    254.008544 | Chris huh                                                                                                                                                   |
| 322 |    181.911984 |    368.028343 | Chris huh                                                                                                                                                   |
| 323 |    178.875436 |    417.792301 | NA                                                                                                                                                          |
| 324 |    369.469393 |     13.851042 | Zimices                                                                                                                                                     |
| 325 |    858.903408 |    473.596184 | Gareth Monger                                                                                                                                               |
| 326 |    203.764741 |    383.700622 | Zimices                                                                                                                                                     |
| 327 |    186.001066 |    255.056817 | Alex Slavenko                                                                                                                                               |
| 328 |    285.971392 |     93.439801 | Iain Reid                                                                                                                                                   |
| 329 |    425.215998 |    298.317043 | Ignacio Contreras                                                                                                                                           |
| 330 |     89.554286 |     25.845792 | Matt Celeskey                                                                                                                                               |
| 331 |    530.281081 |    649.978952 | Emily Jane McTavish, from <http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>                                                 |
| 332 |    573.334169 |    158.940336 | Tasman Dixon                                                                                                                                                |
| 333 |    366.782880 |    572.407658 | Margot Michaud                                                                                                                                              |
| 334 |     15.229044 |    776.613799 | Zimices                                                                                                                                                     |
| 335 |    122.915880 |     74.072572 | Matt Hayes                                                                                                                                                  |
| 336 |    726.917949 |    693.659611 | Jagged Fang Designs                                                                                                                                         |
| 337 |    798.804378 |    414.894512 | Christoph Schomburg                                                                                                                                         |
| 338 |    276.264393 |    205.660361 | Steven Traver                                                                                                                                               |
| 339 |     71.940982 |    184.941898 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                            |
| 340 |    563.433444 |     97.600400 | Lukasiniho                                                                                                                                                  |
| 341 |    660.769443 |    348.394019 | Alex Slavenko                                                                                                                                               |
| 342 |    484.908115 |    460.326400 | Zimices                                                                                                                                                     |
| 343 |    117.025321 |    157.646453 | Margot Michaud                                                                                                                                              |
| 344 |    841.280494 |    672.776205 | Margot Michaud                                                                                                                                              |
| 345 |    447.608539 |    128.130424 | Zimices                                                                                                                                                     |
| 346 |    707.748799 |     35.939215 | Matt Crook                                                                                                                                                  |
| 347 |    716.727251 |      9.206634 | Mason McNair                                                                                                                                                |
| 348 |    838.384803 |    302.045134 | Hugo Gruson                                                                                                                                                 |
| 349 |     30.810395 |    365.702285 | Steven Traver                                                                                                                                               |
| 350 |    149.065029 |    765.412587 | Ferran Sayol                                                                                                                                                |
| 351 |    256.326085 |    604.868498 | Noah Schlottman, photo from Casey Dunn                                                                                                                      |
| 352 |    406.315546 |    404.283708 | CNZdenek                                                                                                                                                    |
| 353 |   1016.472229 |    302.067695 | Myriam\_Ramirez                                                                                                                                             |
| 354 |    679.286237 |    567.206359 | Maxime Dahirel                                                                                                                                              |
| 355 |    443.222990 |    580.727222 | Ferran Sayol                                                                                                                                                |
| 356 |    395.584739 |      3.111303 | Steven Traver                                                                                                                                               |
| 357 |   1007.074362 |    146.011631 | Matt Crook                                                                                                                                                  |
| 358 |    858.264487 |    352.030253 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                               |
| 359 |    220.714306 |    606.424877 | Robert Bruce Horsfall (vectorized by William Gearty)                                                                                                        |
| 360 |    246.625150 |    272.821069 | Andy Wilson                                                                                                                                                 |
| 361 |    482.843259 |    592.234828 | NA                                                                                                                                                          |
| 362 |    709.976766 |    564.891600 | Myriam\_Ramirez                                                                                                                                             |
| 363 |    530.544931 |    258.511099 | NA                                                                                                                                                          |
| 364 |    165.401348 |    650.994822 | Sarah Werning                                                                                                                                               |
| 365 |    117.266555 |    461.029299 | Margot Michaud                                                                                                                                              |
| 366 |   1015.414437 |    370.872997 | Gabriela Palomo-Munoz                                                                                                                                       |
| 367 |    344.525005 |    112.633358 | Tyler Greenfield                                                                                                                                            |
| 368 |    123.712738 |     40.697830 | Steven Coombs                                                                                                                                               |
| 369 |    253.747043 |    365.710009 | Markus A. Grohme                                                                                                                                            |
| 370 |    595.367875 |    422.541071 | Emily Willoughby                                                                                                                                            |
| 371 |    938.621695 |    679.932319 | Jose Carlos Arenas-Monroy                                                                                                                                   |
| 372 |    671.966940 |    612.384254 | Alexandre Vong                                                                                                                                              |
| 373 |    143.235655 |    515.713250 | Fritz Geller-Grimm (vectorized by T. Michael Keesey)                                                                                                        |
| 374 |    549.243118 |    792.777314 | Zimices                                                                                                                                                     |
| 375 |    949.773284 |    188.251006 | Michael Scroggie                                                                                                                                            |
| 376 |    440.333766 |    788.040024 | Ferran Sayol                                                                                                                                                |
| 377 |   1011.205985 |     48.313678 | Lily Hughes                                                                                                                                                 |
| 378 |    736.505518 |    769.219159 | Margot Michaud                                                                                                                                              |
| 379 |   1002.094158 |    795.855612 | Chuanixn Yu                                                                                                                                                 |
| 380 |    695.396147 |    363.894378 | Carlos Cano-Barbacil                                                                                                                                        |
| 381 |    541.989438 |    758.451831 | Julio Garza                                                                                                                                                 |
| 382 |    163.770540 |    381.269457 | Juan Carlos Jerí                                                                                                                                            |
| 383 |     10.992824 |    707.920186 | Zimices                                                                                                                                                     |
| 384 |    359.957364 |    543.301961 | Michelle Site                                                                                                                                               |
| 385 |    834.948710 |    596.542727 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                       |
| 386 |    465.078805 |    109.798550 | Jaime Headden                                                                                                                                               |
| 387 |    870.694866 |    675.550440 | Gareth Monger                                                                                                                                               |
| 388 |    539.046060 |    215.431516 | Margot Michaud                                                                                                                                              |
| 389 |    387.903317 |    436.759787 | Matt Martyniuk                                                                                                                                              |
| 390 |    419.512857 |    148.368730 | Margot Michaud                                                                                                                                              |
| 391 |   1012.983610 |    616.110835 | T. Michael Keesey (photo by Sean Mack)                                                                                                                      |
| 392 |    550.094463 |    700.597825 | Alex Slavenko                                                                                                                                               |
| 393 |    220.308380 |    307.972573 | Zimices                                                                                                                                                     |
| 394 |    880.996358 |    113.207908 | Zimices                                                                                                                                                     |
| 395 |    833.342060 |    631.020970 | Steven Traver                                                                                                                                               |
| 396 |    553.469567 |    172.074209 | Scott Hartman                                                                                                                                               |
| 397 |     30.948007 |    130.206777 | Scott Hartman                                                                                                                                               |
| 398 |    120.926517 |    469.212606 | Michael Scroggie, from original photograph by Gary M. Stolz, USFWS (original photograph in public domain).                                                  |
| 399 |    221.978668 |    100.434495 | Mathieu Pélissié                                                                                                                                            |
| 400 |    297.225276 |    255.534642 | Burton Robert, USFWS                                                                                                                                        |
| 401 |    879.295622 |    209.940663 | FunkMonk                                                                                                                                                    |
| 402 |    659.656994 |    210.347170 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                               |
| 403 |    413.976307 |    630.841801 | Michelle Site                                                                                                                                               |
| 404 |     28.354560 |     66.396895 | Zimices                                                                                                                                                     |
| 405 |    499.184415 |    562.274460 | Erika Schumacher                                                                                                                                            |
| 406 |     75.175510 |    589.586820 | Gareth Monger                                                                                                                                               |
| 407 |    424.293157 |    348.612701 | Zimices                                                                                                                                                     |
| 408 |    158.463167 |    204.886023 | Ferran Sayol                                                                                                                                                |
| 409 |    791.151028 |    647.462185 | Frederick William Frohawk (vectorized by T. Michael Keesey)                                                                                                 |
| 410 |     91.244260 |    316.935151 | Zimices                                                                                                                                                     |
| 411 |    735.161173 |    663.254170 | NA                                                                                                                                                          |
| 412 |    546.055483 |    139.345488 | Yan Wong                                                                                                                                                    |
| 413 |    954.783906 |    644.131988 | Steven Traver                                                                                                                                               |
| 414 |    822.104331 |    672.584356 | Ferran Sayol                                                                                                                                                |
| 415 |    704.009678 |    114.638099 | Tess Linden                                                                                                                                                 |
| 416 |     12.736052 |    454.448719 | NA                                                                                                                                                          |
| 417 |    820.943659 |    690.608014 | Alexandre Vong                                                                                                                                              |
| 418 |    129.854255 |    754.110730 | Dmitry Bogdanov                                                                                                                                             |
| 419 |    838.288822 |     50.457861 | Joanna Wolfe                                                                                                                                                |
| 420 |    517.078517 |    514.410879 | Jagged Fang Designs                                                                                                                                         |
| 421 |    943.584463 |    327.358594 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                           |
| 422 |    141.365640 |     23.158040 | Dmitry Bogdanov                                                                                                                                             |
| 423 |    731.109338 |    794.942532 | C. Abraczinskas                                                                                                                                             |
| 424 |    742.223158 |    520.191226 | Sharon Wegner-Larsen                                                                                                                                        |
| 425 |    842.523017 |    419.552951 | Steven Traver                                                                                                                                               |
| 426 |    288.817561 |    335.321271 | Zimices                                                                                                                                                     |
| 427 |   1000.127614 |    487.363125 | Tasman Dixon                                                                                                                                                |
| 428 |    466.243903 |    220.749335 | Steven Traver                                                                                                                                               |
| 429 |    823.712071 |      4.621350 | CNZdenek                                                                                                                                                    |
| 430 |    333.939704 |     76.182501 | Jagged Fang Designs                                                                                                                                         |
| 431 |    398.249970 |    382.638602 | Steven Traver                                                                                                                                               |
| 432 |    510.999592 |    329.827875 | Steven Traver                                                                                                                                               |
| 433 |    466.934602 |    780.871500 | Mathieu Pélissié                                                                                                                                            |
| 434 |    902.870986 |    211.132495 | Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus                                    |
| 435 |    685.536983 |    631.595536 | Espen Horn (model; vectorized by T. Michael Keesey from a photo by H. Zell)                                                                                 |
| 436 |   1013.444620 |    758.675528 | Matt Crook                                                                                                                                                  |
| 437 |    299.518173 |    605.950057 | Steven Haddock • Jellywatch.org                                                                                                                             |
| 438 |    734.325507 |    234.937368 | Fernando Campos De Domenico                                                                                                                                 |
| 439 |    470.805714 |    606.764566 | Zimices                                                                                                                                                     |
| 440 |     30.755585 |     99.875158 | Oscar Sanisidro                                                                                                                                             |
| 441 |    552.706345 |     59.278232 | 于川云                                                                                                                                                         |
| 442 |    900.967743 |    505.532824 | Lukas Panzarin (vectorized by T. Michael Keesey)                                                                                                            |
| 443 |    846.990742 |    361.410538 | H. Filhol (vectorized by T. Michael Keesey)                                                                                                                 |
| 444 |    112.635607 |    398.854936 | Sean McCann                                                                                                                                                 |
| 445 |    648.752639 |    435.446128 | Matt Crook                                                                                                                                                  |
| 446 |    919.789533 |    102.675648 | Chris huh                                                                                                                                                   |
| 447 |    645.963119 |    654.102087 | Christine Axon                                                                                                                                              |
| 448 |      7.908646 |     62.314939 | Rebecca Groom                                                                                                                                               |
| 449 |    212.167383 |    500.784331 | Michelle Site                                                                                                                                               |
| 450 |    858.815759 |     59.001623 | Ignacio Contreras                                                                                                                                           |
| 451 |    437.652458 |    771.455755 | Margot Michaud                                                                                                                                              |
| 452 |      8.105728 |    471.071572 | Gabriela Palomo-Munoz                                                                                                                                       |
| 453 |    397.706242 |    273.642631 | Ferran Sayol                                                                                                                                                |
| 454 |    410.449800 |    652.863843 | Jagged Fang Designs                                                                                                                                         |
| 455 |    817.357172 |     56.270344 | Joanna Wolfe                                                                                                                                                |
| 456 |    447.684900 |    349.480006 | New York Zoological Society                                                                                                                                 |
| 457 |    550.112186 |    246.788020 | Cesar Julian                                                                                                                                                |
| 458 |    776.739786 |    129.277114 | Martin R. Smith                                                                                                                                             |
| 459 |    540.619373 |    152.476547 | Beth Reinke                                                                                                                                                 |
| 460 |    941.900548 |    247.080129 | Gareth Monger                                                                                                                                               |
| 461 |    858.257619 |    113.792411 | Gareth Monger                                                                                                                                               |
| 462 |    844.796681 |     87.022544 | L. Shyamal                                                                                                                                                  |
| 463 |    473.933291 |    232.870372 | NA                                                                                                                                                          |
| 464 |    466.505916 |    206.876664 | Gareth Monger                                                                                                                                               |
| 465 |     32.465458 |    788.328872 | Scott Hartman                                                                                                                                               |
| 466 |    147.248509 |    142.862143 | Gareth Monger                                                                                                                                               |
| 467 |    185.029012 |    744.676623 | Collin Gross                                                                                                                                                |
| 468 |    456.335530 |    364.820371 | Andy Wilson                                                                                                                                                 |
| 469 |    162.645242 |    781.548075 | Inessa Voet                                                                                                                                                 |
| 470 |    952.518115 |    263.492779 | Ignacio Contreras                                                                                                                                           |
| 471 |    284.344142 |    710.024428 | Sarah Werning                                                                                                                                               |
| 472 |     29.414693 |    664.529029 | Gabriela Palomo-Munoz                                                                                                                                       |
| 473 |    822.720288 |    256.632643 | Margot Michaud                                                                                                                                              |
| 474 |    784.385166 |     23.845980 | Nancy Wyman (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
| 475 |     59.444982 |    285.413532 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                           |
| 476 |    131.729734 |    423.111647 | James R. Spotila and Ray Chatterji                                                                                                                          |
| 477 |    891.335376 |    570.750707 | Margot Michaud                                                                                                                                              |
| 478 |    577.388419 |     74.876993 | Sarah Werning                                                                                                                                               |
| 479 |    709.806014 |    453.404343 | Jessica Rick                                                                                                                                                |
| 480 |    187.463386 |     15.525503 | Andy Wilson                                                                                                                                                 |
| 481 |    321.085494 |    588.505498 | Margot Michaud                                                                                                                                              |
| 482 |    605.254264 |    711.851349 | FunkMonk                                                                                                                                                    |
| 483 |    144.403120 |    267.190067 | Terpsichores                                                                                                                                                |
| 484 |    130.979549 |    788.486667 | Margot Michaud                                                                                                                                              |
| 485 |    232.154406 |    472.137342 | Zimices                                                                                                                                                     |
| 486 |    930.011559 |    398.433679 | Matt Crook                                                                                                                                                  |
| 487 |    907.470386 |    531.824234 | Andy Wilson                                                                                                                                                 |
| 488 |    687.802069 |    689.954614 | Scott Hartman                                                                                                                                               |
| 489 |    559.195721 |    361.205300 | Gabriela Palomo-Munoz                                                                                                                                       |
| 490 |    932.637226 |    456.753828 | Matthew E. Clapham                                                                                                                                          |
| 491 |    439.741090 |     32.204371 | Margot Michaud                                                                                                                                              |
| 492 |    652.215295 |    216.038055 | Margot Michaud                                                                                                                                              |
| 493 |    521.372764 |    524.040051 | Eric Moody                                                                                                                                                  |
| 494 |    612.210754 |     60.923964 | Armin Reindl                                                                                                                                                |
| 495 |    747.931813 |    465.621697 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                               |
| 496 |    162.615615 |    735.803599 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                           |
| 497 |    287.831162 |    783.047200 | Ignacio Contreras                                                                                                                                           |
| 498 |    138.915733 |    474.148097 | Zimices                                                                                                                                                     |
| 499 |    479.640382 |    784.870594 | Kamil S. Jaron                                                                                                                                              |
| 500 |    261.640372 |    794.714891 | Margot Michaud                                                                                                                                              |
| 501 |    588.041858 |    676.567247 | Chris huh                                                                                                                                                   |
| 502 |    960.677613 |    670.993281 | Jaime Headden                                                                                                                                               |
| 503 |    670.426356 |    239.025934 | Steven Traver                                                                                                                                               |
| 504 |    902.959443 |    420.793494 | Margot Michaud                                                                                                                                              |
| 505 |     19.058735 |    434.684630 | T. Michael Keesey (after James & al.)                                                                                                                       |
| 506 |    966.406593 |    352.888206 | Ignacio Contreras                                                                                                                                           |
| 507 |    530.687995 |    133.768871 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                           |
| 508 |    575.034202 |    425.146737 | Joanna Wolfe                                                                                                                                                |
| 509 |    468.070320 |    466.402203 | Ferran Sayol                                                                                                                                                |
| 510 |    819.950553 |    324.416295 | T. Michael Keesey (vector) and Stuart Halliday (photograph)                                                                                                 |
| 511 |    194.830185 |    559.340674 | Tauana J. Cunha                                                                                                                                             |
| 512 |    323.103627 |    381.653387 | NA                                                                                                                                                          |
| 513 |    465.513000 |    125.906312 | Matt Crook                                                                                                                                                  |
| 514 |    499.735676 |    712.659616 | Margot Michaud                                                                                                                                              |
| 515 |    590.413483 |    670.083098 | Sam Droege (photography) and T. Michael Keesey (vectorization)                                                                                              |
| 516 |    368.012471 |    263.480949 | Dmitry Bogdanov                                                                                                                                             |
| 517 |    341.921152 |    646.741211 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                           |
| 518 |    179.824629 |    453.703435 | Chris huh                                                                                                                                                   |
| 519 |     96.190244 |    585.658741 | Steven Traver                                                                                                                                               |
| 520 |    357.743364 |    316.305719 | Birgit Lang                                                                                                                                                 |
| 521 |    597.730958 |    296.098972 | T. Michael Keesey (after Monika Betley)                                                                                                                     |
| 522 |    342.467143 |    655.949719 | Mathilde Cordellier                                                                                                                                         |
| 523 |    252.917906 |    482.920166 | Mali’o Kodis, image from the Smithsonian Institution                                                                                                        |
| 524 |     13.145382 |    625.520725 | Andrew A. Farke                                                                                                                                             |
| 525 |    571.945595 |     93.020342 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                            |
| 526 |    141.828332 |    718.767001 | Robert Hering                                                                                                                                               |
| 527 |    456.803268 |    626.060868 | Margot Michaud                                                                                                                                              |
| 528 |    363.083981 |    505.756426 | Markus A. Grohme                                                                                                                                            |
| 529 |    852.643033 |    522.029005 | Meyer-Wachsmuth I, Curini Galletti M, Jondelius U (<doi:10.1371/journal.pone.0107688>). Vectorization by Y. Wong                                            |
| 530 |    176.022636 |    339.177445 | NA                                                                                                                                                          |
| 531 |    142.881195 |     57.747772 | Tauana J. Cunha                                                                                                                                             |
| 532 |    104.685451 |    790.807293 | Michelle Site                                                                                                                                               |
| 533 |    504.675500 |    259.597077 | Michael Scroggie                                                                                                                                            |
| 534 |    504.167790 |    278.594798 | T. Michael Keesey                                                                                                                                           |
| 535 |    409.591498 |    284.665149 | James Neenan                                                                                                                                                |
| 536 |    653.408239 |     76.077936 | Margot Michaud                                                                                                                                              |
| 537 |    688.989486 |     25.403879 | Margot Michaud                                                                                                                                              |
| 538 |   1018.664955 |    177.016188 | Zimices                                                                                                                                                     |
| 539 |    708.121107 |    529.624322 | T. Michael Keesey                                                                                                                                           |
| 540 |    164.239872 |     13.862355 | Jiekun He                                                                                                                                                   |
| 541 |    516.901575 |    723.683442 | T. Michael Keesey                                                                                                                                           |
| 542 |    402.438145 |    667.714802 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                           |
| 543 |    407.515071 |    341.243474 | Gareth Monger                                                                                                                                               |
| 544 |    773.587956 |    665.008719 | NA                                                                                                                                                          |
| 545 |    756.512976 |    724.357187 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                |
| 546 |    207.725546 |    297.181352 | Gareth Monger                                                                                                                                               |
| 547 |    116.704400 |    355.087060 | Zimices                                                                                                                                                     |
| 548 |    895.823054 |    632.359728 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                            |
| 549 |    347.140276 |    176.344455 | Matthew Hooge (vectorized by T. Michael Keesey)                                                                                                             |
| 550 |    166.800220 |    758.647331 | Christoph Schomburg                                                                                                                                         |
| 551 |    284.291054 |    646.277711 | Ferran Sayol                                                                                                                                                |
| 552 |    632.782602 |    668.996710 | Margot Michaud                                                                                                                                              |
| 553 |    220.623426 |    484.102516 | Mariana Ruiz Villarreal (modified by T. Michael Keesey)                                                                                                     |
| 554 |    567.189042 |    365.865300 | Andy Wilson                                                                                                                                                 |
| 555 |    726.417992 |    591.286646 | Javier Luque                                                                                                                                                |
| 556 |    506.781016 |    792.342898 | Anthony Caravaggi                                                                                                                                           |
| 557 |     33.156963 |    601.525103 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                |
| 558 |    412.193148 |    268.448196 | Scott Hartman                                                                                                                                               |
| 559 |    739.590696 |    506.993732 | Sean McCann                                                                                                                                                 |
| 560 |    517.097335 |    500.875632 | Jonathan Wells                                                                                                                                              |
| 561 |    702.993129 |    790.363440 | Lisa Byrne                                                                                                                                                  |
| 562 |    504.961389 |    291.975775 | NA                                                                                                                                                          |
| 563 |    996.021723 |    710.597838 | Matt Crook                                                                                                                                                  |
| 564 |   1012.988291 |    162.562966 | Zimices                                                                                                                                                     |
| 565 |    159.398959 |    547.823127 | Erika Schumacher                                                                                                                                            |
| 566 |    287.621031 |    514.153943 | Steven Traver                                                                                                                                               |
| 567 |    676.224644 |    372.966084 | Yan Wong                                                                                                                                                    |
| 568 |    268.485422 |     87.858712 | Kristina Gagalova                                                                                                                                           |
| 569 |    537.368807 |    122.454822 | Gabriela Palomo-Munoz                                                                                                                                       |
| 570 |     18.720558 |    264.911645 | Jagged Fang Designs                                                                                                                                         |
| 571 |    335.111843 |    186.965660 | Maxime Dahirel (digitisation), Kees van Achterberg et al (doi: 10.3897/BDJ.8.e49017)(original publication)                                                  |
| 572 |     92.113547 |      8.914526 | Birgit Lang                                                                                                                                                 |
| 573 |    855.214812 |    615.741704 | Scott Hartman                                                                                                                                               |
| 574 |     37.642971 |     86.761908 | André Karwath (vectorized by T. Michael Keesey)                                                                                                             |
| 575 |    113.027370 |    664.792940 | Ferran Sayol                                                                                                                                                |
| 576 |    458.614860 |    497.804490 | Maija Karala                                                                                                                                                |
| 577 |    282.251608 |    602.411825 | Margot Michaud                                                                                                                                              |
| 578 |    151.357971 |     36.193823 | Zimices                                                                                                                                                     |
| 579 |    974.785348 |    319.925217 | AnAgnosticGod (vectorized by T. Michael Keesey)                                                                                                             |
| 580 |    115.182375 |     59.317726 | Ferran Sayol                                                                                                                                                |
| 581 |    643.995444 |    286.760056 | NA                                                                                                                                                          |
| 582 |    244.676402 |    301.878116 | Steven Coombs                                                                                                                                               |
| 583 |    187.006805 |    388.393048 | Nobu Tamura                                                                                                                                                 |
| 584 |    869.172552 |    562.206857 | Matt Crook                                                                                                                                                  |
| 585 |     41.329514 |    299.612968 | Anthony Caravaggi                                                                                                                                           |
| 586 |    436.657147 |     79.891467 | Marie-Aimée Allard                                                                                                                                          |
| 587 |    379.388793 |    556.402949 | T. Michael Keesey                                                                                                                                           |
| 588 |    152.054710 |    422.697007 | T. Michael Keesey                                                                                                                                           |
| 589 |    958.551251 |    633.819205 | Matt Crook                                                                                                                                                  |
| 590 |    566.705628 |    194.405882 | Zimices                                                                                                                                                     |
| 591 |    275.353514 |    618.174788 | Steven Traver                                                                                                                                               |
| 592 |    451.949484 |     16.140919 | Tasman Dixon                                                                                                                                                |
| 593 |    637.017328 |    749.974042 | Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus                                    |
| 594 |    692.812978 |    308.662435 | Ferran Sayol                                                                                                                                                |
| 595 |    486.336151 |     85.051699 | Tasman Dixon                                                                                                                                                |
| 596 |    689.671168 |    371.347768 | Walter Vladimir                                                                                                                                             |
| 597 |    865.461384 |     50.867391 | Renato Santos                                                                                                                                               |
| 598 |    771.288041 |    468.430557 | Sean McCann                                                                                                                                                 |
| 599 |    774.287537 |    587.819787 | Kamil S. Jaron                                                                                                                                              |
| 600 |    584.913598 |    451.714280 | Michael Scroggie                                                                                                                                            |
| 601 |    418.255634 |    360.191385 | Rebecca Groom                                                                                                                                               |
| 602 |    499.702504 |    437.413164 | Jakovche                                                                                                                                                    |
| 603 |    994.075762 |    415.680749 | Michelle Site                                                                                                                                               |
| 604 |    838.940946 |    317.929204 | Zimices                                                                                                                                                     |
| 605 |    539.187831 |    166.910498 | Emily Willoughby                                                                                                                                            |
| 606 |    569.856771 |    711.905061 | Ignacio Contreras                                                                                                                                           |
| 607 |    877.379996 |    248.019756 | Tauana J. Cunha                                                                                                                                             |
| 608 |    536.113604 |    239.150966 | Zimices                                                                                                                                                     |
| 609 |    965.861086 |    449.996540 | Mathieu Pélissié                                                                                                                                            |
| 610 |    921.085323 |    695.213213 | Chloé Schmidt                                                                                                                                               |
| 611 |    827.729500 |    458.737456 | Вальдимар (vectorized by T. Michael Keesey)                                                                                                                 |
| 612 |     29.314611 |    324.703719 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                       |
| 613 |    276.294167 |    683.568541 | Andrew A. Farke                                                                                                                                             |
| 614 |     12.941124 |    545.444664 | Jake Warner                                                                                                                                                 |
| 615 |    327.707911 |    114.997943 | Ferran Sayol                                                                                                                                                |
| 616 |    127.872133 |     85.414556 | Mattia Menchetti                                                                                                                                            |
| 617 |    528.402348 |    534.784112 | Ferran Sayol                                                                                                                                                |
| 618 |    983.198334 |    791.322081 | Chris huh                                                                                                                                                   |
| 619 |    810.085485 |    453.907010 | Andy Wilson                                                                                                                                                 |
| 620 |    728.993505 |    455.550324 | George Edward Lodge                                                                                                                                         |
| 621 |    440.835481 |    365.535978 | Daniel Jaron                                                                                                                                                |
| 622 |    746.870003 |    679.803395 | Noah Schlottman                                                                                                                                             |
| 623 |    215.647523 |    541.786687 | Chuanixn Yu                                                                                                                                                 |
| 624 |    603.906582 |      3.636264 | Zimices                                                                                                                                                     |
| 625 |   1010.120362 |    504.590398 | Matt Crook                                                                                                                                                  |
| 626 |    622.383091 |    517.749522 | Ferran Sayol                                                                                                                                                |
| 627 |    275.564875 |    590.637890 | Scott Hartman                                                                                                                                               |
| 628 |     62.335765 |    193.528371 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                          |
| 629 |    742.624916 |     17.444067 | Margot Michaud                                                                                                                                              |
| 630 |    497.001866 |    255.981559 | John Gould (vectorized by T. Michael Keesey)                                                                                                                |
| 631 |    661.933881 |    145.075809 | Christoph Schomburg                                                                                                                                         |
| 632 |   1000.489627 |    636.519933 | FunkMonk                                                                                                                                                    |
| 633 |    367.430933 |    440.747208 | Ferran Sayol                                                                                                                                                |
| 634 |    640.087255 |    152.114880 | Theodore W. Pietsch (photography) and T. Michael Keesey (vectorization)                                                                                     |
| 635 |    321.551214 |     71.590427 | Markus A. Grohme                                                                                                                                            |
| 636 |     88.901059 |    213.793704 | Steve Hillebrand/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                          |
| 637 |    704.563785 |    127.588083 | Chloé Schmidt                                                                                                                                               |
| 638 |    456.364360 |    229.777923 | Chris huh                                                                                                                                                   |
| 639 |    864.144361 |    535.137992 | T. Michael Keesey                                                                                                                                           |
| 640 |    136.560424 |     30.100380 | Andy Wilson                                                                                                                                                 |
| 641 |    779.130583 |    675.076292 | Terpsichores                                                                                                                                                |
| 642 |    542.434751 |    329.161940 | Yan Wong                                                                                                                                                    |
| 643 |     30.651669 |    143.528285 | C. Camilo Julián-Caballero                                                                                                                                  |
| 644 |    964.707822 |    439.378352 | Emily Willoughby                                                                                                                                            |
| 645 |    615.242669 |    297.816756 | Matt Crook                                                                                                                                                  |
| 646 |    898.496930 |    243.519331 | Markus A. Grohme                                                                                                                                            |
| 647 |    511.771044 |    431.061922 | Chris huh                                                                                                                                                   |
| 648 |    404.068985 |    639.634756 | Juan Carlos Jerí                                                                                                                                            |
| 649 |    559.428459 |    176.187160 | M Kolmann                                                                                                                                                   |
| 650 |    995.920850 |     68.010003 | Aviceda (photo) & T. Michael Keesey                                                                                                                         |
| 651 |    305.777477 |    739.129963 | Sean McCann                                                                                                                                                 |
| 652 |    284.253169 |    629.661810 | Dean Schnabel                                                                                                                                               |
| 653 |    868.102555 |    259.575831 | Margot Michaud                                                                                                                                              |
| 654 |    484.234350 |    483.305302 | Sarah Werning                                                                                                                                               |
| 655 |    266.386480 |    666.965278 | Tasman Dixon                                                                                                                                                |
| 656 |    832.924953 |    404.476656 | NA                                                                                                                                                          |
| 657 |    356.573860 |    102.736707 | Andy Wilson                                                                                                                                                 |
| 658 |    166.429107 |    745.722938 | Alex Slavenko                                                                                                                                               |
| 659 |    173.176828 |    238.369942 | Collin Gross                                                                                                                                                |
| 660 |    716.521116 |    373.300613 | Matt Martyniuk                                                                                                                                              |
| 661 |    260.098386 |    268.543174 | Margot Michaud                                                                                                                                              |
| 662 |    236.037637 |    697.301765 | Michael “FunkMonk” B. H. (vectorized by T. Michael Keesey)                                                                                                  |
| 663 |     15.374717 |    792.326947 | Tauana J. Cunha                                                                                                                                             |
| 664 |    797.024172 |    186.768423 | Steven Traver                                                                                                                                               |
| 665 |    687.724286 |    612.765118 | Gabriela Palomo-Munoz                                                                                                                                       |
| 666 |     12.397624 |    380.567452 | Sharon Wegner-Larsen                                                                                                                                        |
| 667 |    815.914949 |    135.471070 | NA                                                                                                                                                          |
| 668 |    848.892447 |    305.276648 | NA                                                                                                                                                          |
| 669 |     44.590762 |    785.683403 | Sarah Werning                                                                                                                                               |
| 670 |    997.130354 |     96.251895 | NA                                                                                                                                                          |
| 671 |    189.854336 |    439.232606 | Ferran Sayol                                                                                                                                                |
| 672 |     11.943618 |    642.446742 | Steven Traver                                                                                                                                               |
| 673 |    270.947501 |    480.967907 | Margot Michaud                                                                                                                                              |
| 674 |    876.020688 |    102.984109 | Jose Carlos Arenas-Monroy                                                                                                                                   |
| 675 |    140.469104 |    648.865089 | Gareth Monger                                                                                                                                               |
| 676 |    430.914105 |    433.162753 | Ghedoghedo                                                                                                                                                  |
| 677 |    624.826930 |    711.680526 | Gareth Monger                                                                                                                                               |
| 678 |    682.252153 |    264.853851 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                            |
| 679 |    621.012770 |    481.285204 | Scott Hartman                                                                                                                                               |
| 680 |    839.003830 |    774.807791 | Jagged Fang Designs                                                                                                                                         |
| 681 |    290.758686 |    703.694632 | Dean Schnabel                                                                                                                                               |
| 682 |    843.792163 |    340.304793 | Rebecca Groom                                                                                                                                               |
| 683 |    114.018697 |    364.803305 | Michael B. H. (vectorized by T. Michael Keesey)                                                                                                             |
| 684 |     97.027750 |     54.891414 | Andy Wilson                                                                                                                                                 |
| 685 |    793.064347 |    619.239640 | Ferran Sayol                                                                                                                                                |
| 686 |    779.069570 |    400.211015 | Mali’o Kodis, photograph by Aqua-Photos (<http://www.flickr.com/people/undervannsfotografen/>)                                                              |
| 687 |    572.959634 |    315.620892 | Gareth Monger                                                                                                                                               |
| 688 |    410.542634 |    364.072012 | Noah Schlottman, photo by Casey Dunn                                                                                                                        |
| 689 |    167.146283 |    155.565541 | Yan Wong (vectorization) from 1873 illustration                                                                                                             |
| 690 |    597.207317 |    722.756974 | Matt Crook                                                                                                                                                  |
| 691 |    430.556678 |    506.710782 | Steven Traver                                                                                                                                               |
| 692 |    233.378512 |    273.434520 | Gareth Monger                                                                                                                                               |
| 693 |    777.870109 |    431.949446 | Matt Crook                                                                                                                                                  |
| 694 |    533.663483 |    679.576190 | Dann Pigdon                                                                                                                                                 |
| 695 |    923.636259 |    678.114546 | NA                                                                                                                                                          |
| 696 |    655.064920 |    169.138849 | Gabriela Palomo-Munoz                                                                                                                                       |
| 697 |    874.928376 |     14.625153 | Kimberly Haddrell                                                                                                                                           |
| 698 |    299.183942 |    755.811177 | Joe Schneid (vectorized by T. Michael Keesey)                                                                                                               |
| 699 |    725.903766 |    336.139727 | NA                                                                                                                                                          |
| 700 |    949.496896 |    346.503763 | Zimices                                                                                                                                                     |
| 701 |    351.596205 |    304.952772 | Mathieu Basille                                                                                                                                             |
| 702 |   1000.256862 |    736.126023 | Maija Karala                                                                                                                                                |
| 703 |    352.777519 |     33.220392 | Scott Hartman                                                                                                                                               |
| 704 |    394.570686 |     72.152672 | NA                                                                                                                                                          |
| 705 |    498.573126 |    366.359885 | Scott Hartman                                                                                                                                               |
| 706 |    986.696413 |    495.662177 | Birgit Lang                                                                                                                                                 |
| 707 |    735.433210 |     30.572501 | Matt Crook                                                                                                                                                  |
| 708 |    111.895321 |    335.055231 | Jagged Fang Designs                                                                                                                                         |
| 709 |    670.101407 |    314.303455 | Steven Traver                                                                                                                                               |
| 710 |    378.994277 |    300.381101 | Birgit Lang                                                                                                                                                 |
| 711 |    459.312182 |    180.682429 | Chris A. Hamilton                                                                                                                                           |
| 712 |     16.930163 |    277.957243 | Matt Crook                                                                                                                                                  |
| 713 |    202.601944 |    288.661281 | Kai R. Caspar                                                                                                                                               |
| 714 |    810.340590 |    161.810154 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                           |
| 715 |    151.286004 |    228.148548 | Dean Schnabel                                                                                                                                               |
| 716 |    297.479789 |    639.012991 | Gareth Monger                                                                                                                                               |
| 717 |    501.254409 |    148.141096 | Gareth Monger                                                                                                                                               |
| 718 |    805.519519 |     50.653594 | Xavier Giroux-Bougard                                                                                                                                       |
| 719 |    792.608912 |     95.875184 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                              |
| 720 |    556.017200 |    284.441202 | Matt Crook                                                                                                                                                  |
| 721 |    164.202321 |    361.951672 | DW Bapst (modified from Mitchell 1990)                                                                                                                      |
| 722 |    852.480813 |    582.641432 | Emily Jane McTavish, from <http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>                                                 |
| 723 |    101.455877 |    466.563908 | Jagged Fang Designs                                                                                                                                         |
| 724 |    216.816660 |    530.193709 | Ferran Sayol                                                                                                                                                |
| 725 |    888.096779 |    604.902069 | Chris huh                                                                                                                                                   |
| 726 |    703.926426 |     23.542890 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey     |
| 727 |    675.783664 |    224.597508 | Michelle Site                                                                                                                                               |
| 728 |   1000.409700 |    352.125442 | Birgit Lang                                                                                                                                                 |
| 729 |    907.186334 |      9.329553 | Dmitry Bogdanov                                                                                                                                             |
| 730 |    244.163001 |    374.605448 | Chris huh                                                                                                                                                   |
| 731 |    420.388628 |    783.516786 | Steven Coombs                                                                                                                                               |
| 732 |    182.874156 |    597.828998 | Matt Crook                                                                                                                                                  |
| 733 |    620.500270 |    455.051905 | Mario Quevedo                                                                                                                                               |
| 734 |    526.295357 |    297.548492 | Julio Garza                                                                                                                                                 |
| 735 |    792.721468 |    383.200437 | Paul O. Lewis                                                                                                                                               |
| 736 |    882.324683 |    363.274979 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                               |
| 737 |    421.780946 |    789.507046 | Martin R. Smith, after Skovsted et al 2015                                                                                                                  |
| 738 |    531.956518 |    431.620697 | Matt Crook                                                                                                                                                  |
| 739 |    402.466749 |     19.449869 | Andy Wilson                                                                                                                                                 |
| 740 |    851.135412 |    428.049105 | Matt Martyniuk                                                                                                                                              |
| 741 |    601.826758 |    290.164212 | Markus A. Grohme                                                                                                                                            |
| 742 |    351.668930 |    232.753581 | Markus A. Grohme                                                                                                                                            |
| 743 |    885.776337 |     13.170243 | FunkMonk                                                                                                                                                    |
| 744 |     30.570781 |     28.756129 | Chris Jennings (vectorized by A. Verrière)                                                                                                                  |
| 745 |     41.767291 |    586.496194 | Lukasiniho                                                                                                                                                  |
| 746 |    359.419569 |    581.962713 | Birgit Lang                                                                                                                                                 |
| 747 |    826.733632 |    683.242849 | Margot Michaud                                                                                                                                              |
| 748 |    348.735895 |    259.706080 | Maija Karala                                                                                                                                                |
| 749 |     84.374299 |    196.240709 | Tauana J. Cunha                                                                                                                                             |
| 750 |    864.418165 |    400.107745 | V. Deepak                                                                                                                                                   |
| 751 |    991.769687 |     10.141909 | Zimices                                                                                                                                                     |
| 752 |    461.627392 |    545.224546 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                               |
| 753 |    746.956927 |    292.408350 | Zimices                                                                                                                                                     |
| 754 |    341.863587 |    446.232627 | Matt Crook                                                                                                                                                  |
| 755 |    408.096242 |    430.322214 | Chris huh                                                                                                                                                   |
| 756 |    817.210901 |    390.943673 | Jaime Headden                                                                                                                                               |
| 757 |    161.093789 |     90.022101 | Ferran Sayol                                                                                                                                                |
| 758 |    943.142024 |    404.943261 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                               |
| 759 |    574.895299 |    286.987283 | Konsta Happonen, from a CC-BY-NC image by sokolkov2002 on iNaturalist                                                                                       |
| 760 |    530.031430 |    777.122618 | Matt Crook                                                                                                                                                  |
| 761 |    809.190742 |    315.369675 | Margot Michaud                                                                                                                                              |
| 762 |     60.995097 |    171.994904 | Dmitry Bogdanov                                                                                                                                             |
| 763 |    317.249845 |    190.592211 | Jon M Laurent                                                                                                                                               |
| 764 |    348.584832 |    125.206757 | Andreas Hejnol                                                                                                                                              |
| 765 |    813.537750 |    178.618982 | Melissa Broussard                                                                                                                                           |
| 766 |    784.970254 |    463.479231 | Andy Wilson                                                                                                                                                 |
| 767 |    597.412622 |    480.475824 | Andreas Hejnol                                                                                                                                              |
| 768 |    319.687505 |    480.065245 | Sarah Werning                                                                                                                                               |
| 769 |    212.111531 |     96.976241 | FunkMonk                                                                                                                                                    |
| 770 |    807.497904 |    606.205696 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                              |
| 771 |    328.467501 |     10.306994 | Milton Tan                                                                                                                                                  |
| 772 |    574.126132 |    410.715861 | Mateus Zica (modified by T. Michael Keesey)                                                                                                                 |
| 773 |    733.592189 |    565.047738 | Yan Wong from drawing by T. F. Zimmermann                                                                                                                   |
| 774 |    518.306498 |    378.604603 | Aviceda (photo) & T. Michael Keesey                                                                                                                         |
| 775 |    469.067257 |      3.721997 | Gareth Monger                                                                                                                                               |
| 776 |    453.941637 |    492.516104 | Yan Wong                                                                                                                                                    |
| 777 |    673.621938 |    364.642245 | Smokeybjb                                                                                                                                                   |
| 778 |    304.895800 |     69.404630 | Andy Wilson                                                                                                                                                 |
| 779 |    346.623440 |     18.323125 | Nobu Tamura, vectorized by Zimices                                                                                                                          |
| 780 |    217.206686 |    186.167331 | T. Michael Keesey (after MPF)                                                                                                                               |
| 781 |    451.703618 |    349.186730 | Gareth Monger                                                                                                                                               |
| 782 |    158.403037 |    512.845673 | Matt Crook                                                                                                                                                  |
| 783 |    952.932455 |    654.842087 | S.Martini                                                                                                                                                   |
| 784 |    753.237098 |    244.137779 | Zimices                                                                                                                                                     |
| 785 |    678.567991 |    349.056300 | Steven Traver                                                                                                                                               |
| 786 |    253.218080 |    156.053643 | Tim Bertelink (modified by T. Michael Keesey)                                                                                                               |
| 787 |    272.862447 |     18.417941 | Matt Crook                                                                                                                                                  |
| 788 |    996.811472 |    370.358350 | Mali’o Kodis, photograph by “Wildcat Dunny” (<http://www.flickr.com/people/wildcat_dunny/>)                                                                 |
| 789 |     21.544139 |    442.819021 | Chris Jennings (Risiatto)                                                                                                                                   |
| 790 |    409.080178 |    117.219239 | Yan Wong                                                                                                                                                    |
| 791 |    524.937873 |    593.904686 | Mali’o Kodis, photograph by Jim Vargo                                                                                                                       |
| 792 |     77.665319 |    298.324027 | NA                                                                                                                                                          |
| 793 |    777.511582 |      7.936617 | Harold N Eyster                                                                                                                                             |
| 794 |    152.165392 |    159.696135 | Zimices                                                                                                                                                     |
| 795 |    490.602964 |    493.571618 | Air Kebir NRG                                                                                                                                               |
| 796 |    287.599997 |    400.721244 | Tod Robbins                                                                                                                                                 |
| 797 |    893.675900 |    521.969757 | Yan Wong                                                                                                                                                    |
| 798 |    129.843122 |    260.506329 | Mathilde Cordellier                                                                                                                                         |
| 799 |    705.765068 |    700.131811 | NA                                                                                                                                                          |
| 800 |    318.146970 |    685.113391 | Tasman Dixon                                                                                                                                                |
| 801 |     69.683547 |    203.748608 | Alex Slavenko                                                                                                                                               |
| 802 |    341.325448 |    587.712183 | Rebecca Groom                                                                                                                                               |
| 803 |    949.043796 |    219.121961 | T. Michael Keesey                                                                                                                                           |
| 804 |    428.016322 |    621.542345 | Kai R. Caspar                                                                                                                                               |
| 805 |    360.341867 |    587.829486 | Jagged Fang Designs                                                                                                                                         |
| 806 |    705.614268 |    797.979515 | Jack Mayer Wood                                                                                                                                             |
| 807 |    595.977253 |    493.645139 | Sarah Werning                                                                                                                                               |
| 808 |    553.606205 |    773.733692 | NA                                                                                                                                                          |
| 809 |    343.770447 |    105.919883 | Caleb M. Brown                                                                                                                                              |
| 810 |    283.989260 |     39.527836 | David Orr                                                                                                                                                   |
| 811 |    514.545077 |    559.308651 | Rebecca Groom                                                                                                                                               |
| 812 |    167.552321 |    222.705068 | Amanda Katzer                                                                                                                                               |
| 813 |    826.258790 |     19.942662 | Original drawing by Nobu Tamura, vectorized by Roberto Díaz Sibaja                                                                                          |
| 814 |      8.544381 |    108.894275 | Tasman Dixon                                                                                                                                                |
| 815 |    473.954913 |    741.011796 | T. Michael Keesey                                                                                                                                           |
| 816 |     18.988857 |    337.507235 | Beth Reinke                                                                                                                                                 |
| 817 |    308.116896 |    155.894475 | Don Armstrong                                                                                                                                               |
| 818 |    239.570253 |      7.783019 | FunkMonk                                                                                                                                                    |
| 819 |    846.697402 |    406.025688 | Steven Traver                                                                                                                                               |
| 820 |    391.333425 |    570.040428 | Zimices                                                                                                                                                     |
| 821 |    668.226694 |    194.790155 | Margot Michaud                                                                                                                                              |
| 822 |    667.816970 |    270.483187 | Mariana Ruiz Villarreal                                                                                                                                     |
| 823 |    536.071487 |     52.041625 | André Karwath (vectorized by T. Michael Keesey)                                                                                                             |
| 824 |    321.587705 |    659.001378 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                          |
| 825 |    835.442456 |     12.244642 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                               |
| 826 |    452.434732 |    323.617022 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                           |
| 827 |     19.243230 |     14.167254 | Samanta Orellana                                                                                                                                            |
| 828 |    552.476517 |    158.438686 | Andy Wilson                                                                                                                                                 |
| 829 |    841.943650 |    588.077840 | Kamil S. Jaron                                                                                                                                              |
| 830 |    319.377634 |    175.747087 | Margot Michaud                                                                                                                                              |
| 831 |    326.161527 |     85.900952 | Zimices                                                                                                                                                     |
| 832 |    971.922687 |    674.961645 | L.M. Davalos                                                                                                                                                |
| 833 |    713.871033 |    264.142195 | Chris A. Hamilton                                                                                                                                           |
| 834 |    511.444928 |    454.194064 | Julie Blommaert based on photo by Sofdrakou                                                                                                                 |
| 835 |    608.255929 |    156.673286 | Gabriela Palomo-Munoz                                                                                                                                       |
| 836 |    595.052720 |    398.593355 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                             |
| 837 |    945.712132 |    392.483033 | Manabu Sakamoto                                                                                                                                             |
| 838 |    398.715029 |    624.926079 | Matt Martyniuk                                                                                                                                              |
| 839 |    158.477634 |    635.861666 | Zimices                                                                                                                                                     |
| 840 |    262.319981 |    596.147607 | Ignacio Contreras                                                                                                                                           |
| 841 |    796.039120 |    598.508371 | Ieuan Jones                                                                                                                                                 |
| 842 |    441.340496 |    561.403592 | Zimices                                                                                                                                                     |
| 843 |    688.169842 |      7.802059 | Scott Hartman                                                                                                                                               |
| 844 |     50.651401 |     72.423119 | Dean Schnabel                                                                                                                                               |
| 845 |    493.455903 |    239.494747 | Jaime Headden                                                                                                                                               |
| 846 |    341.265516 |    552.934913 | Philip Chalmers (vectorized by T. Michael Keesey)                                                                                                           |
| 847 |    200.745070 |     26.441012 | NASA                                                                                                                                                        |
| 848 |    857.428127 |     87.132797 | Armin Reindl                                                                                                                                                |
| 849 |    563.568685 |    791.043940 | Gabriela Palomo-Munoz                                                                                                                                       |
| 850 |    293.249418 |    686.637195 | C. Camilo Julián-Caballero                                                                                                                                  |
| 851 |    616.755672 |    146.566578 | Lukasiniho                                                                                                                                                  |
| 852 |    591.109306 |    444.393175 | Erika Schumacher                                                                                                                                            |
| 853 |    472.131635 |    622.119325 | Jagged Fang Designs                                                                                                                                         |
| 854 |    202.545844 |    477.659234 | Steven Traver                                                                                                                                               |
| 855 |    559.461756 |    754.223286 | Ignacio Contreras                                                                                                                                           |
| 856 |    511.602556 |    285.662978 | Jagged Fang Designs                                                                                                                                         |
| 857 |    679.515300 |    605.025934 | C. Camilo Julián-Caballero                                                                                                                                  |
| 858 |    848.507355 |    600.969586 | terngirl                                                                                                                                                    |
| 859 |    829.789068 |    638.759779 | Yan Wong                                                                                                                                                    |
| 860 |    403.890225 |    312.410187 | Margot Michaud                                                                                                                                              |
| 861 |    562.994772 |    685.602749 | Jagged Fang Designs                                                                                                                                         |
| 862 |    572.890913 |    138.408949 | Zimices                                                                                                                                                     |
| 863 |    144.361600 |    463.335930 | Margot Michaud                                                                                                                                              |
| 864 |     11.831786 |    735.318689 | Steven Traver                                                                                                                                               |
| 865 |    969.485136 |    220.750891 | Tim H. Heupink, Leon Huynen, and David M. Lambert (vectorized by T. Michael Keesey)                                                                         |
| 866 |    529.317271 |    374.848568 | Matt Crook                                                                                                                                                  |
| 867 |    418.130234 |    646.929653 | Armin Reindl                                                                                                                                                |
| 868 |    670.880031 |     91.197445 | Sharon Wegner-Larsen                                                                                                                                        |
| 869 |    240.024280 |    213.274759 | NA                                                                                                                                                          |
| 870 |    794.770840 |    726.060258 | Joe Schneid (vectorized by T. Michael Keesey)                                                                                                               |
| 871 |    738.669820 |    611.043845 | Harold N Eyster                                                                                                                                             |
| 872 |    565.280913 |    146.440097 | Luis Cunha                                                                                                                                                  |
| 873 |    169.220918 |    628.416123 | Gareth Monger                                                                                                                                               |
| 874 |    337.435494 |    672.818138 | Collin Gross                                                                                                                                                |
| 875 |    878.949448 |    794.967466 | Chris huh                                                                                                                                                   |
| 876 |    200.077044 |    117.181944 | Chris huh                                                                                                                                                   |
| 877 |    854.540856 |    786.457393 | TaraTaylorDesign                                                                                                                                            |
| 878 |      8.112538 |    614.065381 | Gabriela Palomo-Munoz                                                                                                                                       |
| 879 |    778.874188 |    419.766295 | Carlos Cano-Barbacil                                                                                                                                        |
| 880 |    100.400025 |    670.428283 | James R. Spotila and Ray Chatterji                                                                                                                          |
| 881 |    855.176663 |      9.098825 | Evan-Amos (vectorized by T. Michael Keesey)                                                                                                                 |
| 882 |    150.683531 |    749.233781 | Benchill                                                                                                                                                    |
| 883 |    956.150276 |    626.632822 | Zimices                                                                                                                                                     |
| 884 |    785.562632 |    449.413548 | Jagged Fang Designs                                                                                                                                         |
| 885 |    303.471309 |    616.191597 | T. Michael Keesey                                                                                                                                           |
| 886 |    653.409254 |    250.002821 | Steven Traver                                                                                                                                               |
| 887 |    328.205276 |    788.937248 | NA                                                                                                                                                          |
| 888 |     16.606570 |     76.370919 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                               |
| 889 |    453.311201 |    751.027224 | Tasman Dixon                                                                                                                                                |
| 890 |    664.905278 |    570.564898 | Ignacio Contreras                                                                                                                                           |
| 891 |    346.009607 |      5.840796 | Margot Michaud                                                                                                                                              |
| 892 |    418.146523 |    332.422467 | Joanna Wolfe                                                                                                                                                |
| 893 |    667.818868 |    119.051868 | NA                                                                                                                                                          |
| 894 |    165.874259 |    243.390882 | Andy Wilson                                                                                                                                                 |
| 895 |    748.313889 |    479.356222 | Mali’o Kodis, image from the Smithsonian Institution                                                                                                        |
| 896 |    164.487398 |    464.668795 | Jaime Headden                                                                                                                                               |
| 897 |    356.712521 |    648.174369 | NA                                                                                                                                                          |
| 898 |    482.030530 |    565.318794 | Steven Traver                                                                                                                                               |
| 899 |    463.727038 |    515.304509 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey     |
| 900 |     19.699691 |    232.982114 | Cristopher Silva                                                                                                                                            |
| 901 |    940.610691 |     21.484952 | Tracy A. Heath                                                                                                                                              |
| 902 |   1011.596351 |    668.217751 | Jessica Anne Miller                                                                                                                                         |
| 903 |    236.552170 |     83.463813 | Mathilde Cordellier                                                                                                                                         |
| 904 |   1009.072981 |    570.594149 | Scott Hartman                                                                                                                                               |
| 905 |    810.443281 |    224.430563 | Gareth Monger                                                                                                                                               |
| 906 |    971.453709 |     24.195075 | T. Michael Keesey (after Ponomarenko)                                                                                                                       |
| 907 |   1001.996068 |     39.964458 | Tomas Willems (vectorized by T. Michael Keesey)                                                                                                             |
| 908 |   1010.828363 |    364.985236 | NA                                                                                                                                                          |
| 909 |    762.152581 |    139.426402 | NA                                                                                                                                                          |
| 910 |    399.034074 |    137.730515 | NA                                                                                                                                                          |
| 911 |     41.203559 |    618.961573 | Iain Reid                                                                                                                                                   |
| 912 |    800.396829 |    202.578565 | Andy Wilson                                                                                                                                                 |
| 913 |    177.656718 |    504.270070 | Scott Hartman                                                                                                                                               |
| 914 |    338.747261 |     27.033300 | Jagged Fang Designs                                                                                                                                         |
| 915 |    138.065376 |    394.660503 | NA                                                                                                                                                          |

    #> Your tweet has been posted!
