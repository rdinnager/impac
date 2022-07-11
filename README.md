
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

Darren Naish (vectorize by T. Michael Keesey), Tasman Dixon, Markus A.
Grohme, T. Michael Keesey, Matt Crook, Birgit Lang, Shyamal, Robert
Bruce Horsfall (vectorized by T. Michael Keesey), Roberto Díaz Sibaja,
Tyler McCraney, Oscar Sanisidro, Zimices, Skye McDavid, Scott Hartman,
Katie S. Collins, Chris huh, Ferran Sayol, Chris Jennings (Risiatto),
U.S. National Park Service (vectorized by William Gearty), Hans
Hillewaert (vectorized by T. Michael Keesey), Gareth Monger, Scott Reid,
Yan Wong, Rebecca Groom, Michael Scroggie, Maxime Dahirel, Smokeybjb,
vectorized by Zimices, Steven Traver, Cathy, Noah Schlottman, photo from
Moorea Biocode, Dmitry Bogdanov (vectorized by T. Michael Keesey), Matt
Martyniuk (modified by T. Michael Keesey), Bryan Carstens, Stanton F.
Fink (vectorized by T. Michael Keesey), Tracy A. Heath, Hanyong Pu,
Yoshitsugu Kobayashi, Junchang Lü, Li Xu, Yanhua Wu, Huali Chang, Jiming
Zhang, Songhai Jia & T. Michael Keesey, Maija Karala, Smokeybjb, Jordan
Mallon (vectorized by T. Michael Keesey), Sharon Wegner-Larsen, Margot
Michaud, Michelle Site, Jagged Fang Designs, Xavier Giroux-Bougard,
Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael
Keesey., James R. Spotila and Ray Chatterji, Harold N Eyster, Beth
Reinke, Iain Reid, Duane Raver (vectorized by T. Michael Keesey), Sarah
Werning, Martin R. Smith, after Skovsted et al 2015, Andrew A. Farke,
Kosta Mumcuoglu (vectorized by T. Michael Keesey), Richard Lampitt,
Jeremy Young / NHM (vectorization by Yan Wong), Eric Moody, Mathieu
Pélissié, CNZdenek, Aviceda (photo) & T. Michael Keesey, Gabriela
Palomo-Munoz, Michael Day, Dexter R. Mardis, kreidefossilien.de, Nobu
Tamura (vectorized by T. Michael Keesey), Zsoldos Márton (vectorized by
T. Michael Keesey), Christine Axon, FunkMonk (Michael B. H.), FunkMonk,
Ingo Braasch, T. Tischler, Darren Naish (vectorized by T. Michael
Keesey), Mateus Zica (modified by T. Michael Keesey), Andrew R. Gehrke,
Armin Reindl, Anthony Caravaggi, Falconaumanni and T. Michael Keesey,
Jaime Headden (vectorized by T. Michael Keesey), Felix Vaux, Craig
Dylke, Chuanixn Yu, Erika Schumacher, Catherine Yasuda, John Curtis
(vectorized by T. Michael Keesey), Tauana J. Cunha, Kai R. Caspar, Lukas
Panzarin, Daniel Jaron, Andy Wilson, Matt Martyniuk, Alexander
Schmidt-Lebuhn, Steven Haddock • Jellywatch.org, xgirouxb, Doug Backlund
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Ramona J Heim, Steven Coombs, Sean McCann, Joanna Wolfe, Andrew
A. Farke, modified from original by Robert Bruce Horsfall, from Scott
1912, Johan Lindgren, Michael W. Caldwell, Takuya Konishi, Luis M.
Chiappe, Gopal Murali, Didier Descouens (vectorized by T. Michael
Keesey), Arthur Weasley (vectorized by T. Michael Keesey), M Kolmann,
Oren Peles / vectorized by Yan Wong, Mali’o Kodis, image from Brockhaus
and Efron Encyclopedic Dictionary, Jaime Headden, Andrés Sánchez, Robert
Gay, Lee Harding (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, T. Michael Keesey (after Joseph Wolf), T. Michael
Keesey, from a photograph by Thea Boodhoo, Ville-Veikko Sinkkonen, T.
Michael Keesey (vector) and Stuart Halliday (photograph), DW Bapst
(modified from Mitchell 1990), Jose Carlos Arenas-Monroy, Ignacio
Contreras, John Gould (vectorized by T. Michael Keesey), Lankester Edwin
Ray (vectorized by T. Michael Keesey), SauropodomorphMonarch, Manabu
Sakamoto, Stanton F. Fink, vectorized by Zimices, Julio Garza, Mathew
Wedel, Robert Hering, Michele M Tobias, Mathieu Basille, Joseph J. W.
Sertich, Mark A. Loewen, Matt Dempsey, L. Shyamal, Mali’o Kodis, traced
image from the National Science Foundation’s Turbellarian Taxonomic
Database, Lily Hughes, Sherman Foote Denton (illustration, 1897) and
Timothy J. Bartley (silhouette), Tyler Greenfield, Christoph Schomburg,
Ricardo Araújo, Mette Aumala, Pranav Iyer (grey ideas), Brad McFeeters
(vectorized by T. Michael Keesey), Emily Jane McTavish, Nobu Tamura,
vectorized by Zimices, Crystal Maier, zoosnow, Lukasiniho, NOAA
(vectorized by T. Michael Keesey), Mali’o Kodis, photograph by Bruno
Vellutini, Abraão Leite, Jay Matternes (modified by T. Michael Keesey),
Jaime A. Headden (vectorized by T. Michael Keesey), FJDegrange,
Taenadoman, Jon Hill (Photo by Benjamint444:
<http://en.wikipedia.org/wiki/File:Blue-footed-booby.jpg>), Kanchi
Nanjo, C. Camilo Julián-Caballero, Chloé Schmidt, Benjamin Monod-Broca,
Julie Blommaert based on photo by Sofdrakou, Trond R. Oskars, Sarefo
(vectorized by T. Michael Keesey), Aleksey Nagovitsyn (vectorized by T.
Michael Keesey), Melissa Broussard, Geoff Shaw, Nina Skinner, Christian
A. Masnaghetti, Verisimilus, Leann Biancani, photo by Kenneth Clifton,
Verdilak, Вальдимар (vectorized by T. Michael Keesey), T. Michael Keesey
(vectorization) and Nadiatalent (photography), Kent Elson Sorgon, Mali’o
Kodis, photograph by “Wildcat Dunny”
(<http://www.flickr.com/people/wildcat_dunny/>), Dean Schnabel, Renata
F. Martins, Caleb M. Brown, Felix Vaux and Steven A. Trewick, Kamil S.
Jaron, T. Michael Keesey (vectorization) and Tony Hisgett (photography),
Ian Burt (original) and T. Michael Keesey (vectorization), LeonardoG
(photography) and T. Michael Keesey (vectorization), Vijay Cavale
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Wynston Cooper (photo) and Albertonykus (silhouette),
Terpsichores, Mason McNair, Almandine (vectorized by T. Michael Keesey),
Frank Förster, Emil Schmidt (vectorized by Maxime Dahirel), Dori
<dori@merr.info> (source photo) and Nevit Dilmen, Agnello Picorelli,
Collin Gross, Dave Angelini, George Edward Lodge, Natalie Claunch,
Audrey Ely, Sergio A. Muñoz-Gómez, Alexandre Vong, Chase Brownstein,
Martin Kevil, Jessica Anne Miller, Tyler Greenfield and Dean Schnabel,
Martin R. Smith, I. Geoffroy Saint-Hilaire (vectorized by T. Michael
Keesey), Frank Förster (based on a picture by Hans Hillewaert), Jan A.
Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized
by T. Michael Keesey), Keith Murdock (photo), John E. McCormack, Michael
G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn,
Robb T. Brumfield & T. Michael Keesey, M. Antonio Todaro, Tobias
Kånneby, Matteo Dal Zotto, and Ulf Jondelius (vectorized by T. Michael
Keesey), Jiekun He, Jonathan Wells, Emily Willoughby, Matthew Hooge
(vectorized by T. Michael Keesey), Diego Fontaneto, Elisabeth A.
Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia
Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey),
Rachel Shoop, Enoch Joseph Wetsy (photo), John E. McCormack, Michael G.
Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb
T. Brumfield & T. Michael Keesey, Mali’o Kodis, photograph by Melissa
Frey, Leon P. A. M. Claessens, Patrick M. O’Connor, David M. Unwin,
Charles Doolittle Walcott (vectorized by T. Michael Keesey), Original
drawing by Antonov, vectorized by Roberto Díaz Sibaja, Robert Bruce
Horsfall, vectorized by Zimices, Noah Schlottman, Ellen Edmonson and
Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette), Zimices,
based in Mauricio Antón skeletal, Isaure Scavezzoni, Ghedo and T.
Michael Keesey, Ludwik Gąsiorowski, Riccardo Percudani, T. Michael
Keesey (after Walker & al.), Tony Ayling (vectorized by T. Michael
Keesey), Kanako Bessho-Uehara, Alex Slavenko, Jon Hill, Roger Witter,
vectorized by Zimices, NOAA Great Lakes Environmental Research
Laboratory (illustration) and Timothy J. Bartley (silhouette), Joe
Schneid (vectorized by T. Michael Keesey), Thea Boodhoo (photograph) and
T. Michael Keesey (vectorization), Jack Mayer Wood, Inessa Voet,
S.Martini, Andrew A. Farke, shell lines added by Yan Wong, Auckland
Museum, Fernando Carezzano, Scott D. Sampson, Mark A. Loewen, Andrew A.
Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L.
Titus, Marmelad, Paul O. Lewis, Dantheman9758 (vectorized by T. Michael
Keesey), Nobu Tamura, Prin Pattawaro (photo), John E. McCormack, Michael
G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn,
Robb T. Brumfield & T. Michael Keesey, Myriam\_Ramirez, Carlos
Cano-Barbacil, Jaime Headden, modified by T. Michael Keesey, Estelle
Bourdon, Michele Tobias, Andrew A. Farke, modified from original by H.
Milne Edwards, Amanda Katzer, Becky Barnes, Michael “FunkMonk” B. H.
(vectorized by T. Michael Keesey), Dmitry Bogdanov, Mali’o Kodis,
photograph by John Slapcinsky, Y. de Hoev. (vectorized by T. Michael
Keesey), (after Spotila 2004), SecretJellyMan - from Mason McNair, Mike
Keesey (vectorization) and Vaibhavcho (photography), Pete Buchholz,
Brian Swartz (vectorized by T. Michael Keesey), Original scheme by
‘Haplochromis’, vectorized by Roberto Díaz Sibaja, Michael Scroggie,
from original photograph by Gary M. Stolz, USFWS (original photograph in
public domain)., E. Lear, 1819 (vectorization by Yan Wong), Juan Carlos
Jerí, Mali’o Kodis, photograph property of National Museums of Northern
Ireland, Noah Schlottman, photo by Casey Dunn, Chris A. Hamilton, Mihai
Dragos (vectorized by T. Michael Keesey), Ieuan Jones, Smokeybjb
(modified by Mike Keesey), Patrick Fisher (vectorized by T. Michael
Keesey), Nobu Tamura, modified by Andrew A. Farke, T. Michael Keesey
(after Tillyard), Louis Ranjard, Stemonitis (photography) and T. Michael
Keesey (vectorization), Robbie N. Cada (vectorized by T. Michael
Keesey), Maha Ghazal, Mali’o Kodis, image from Higgins and Kristensen,
1986, Neil Kelley, Chris Hay, Noah Schlottman, photo from Casey Dunn

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    606.212361 |    522.197971 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                         |
|   2 |    795.540264 |    681.190919 | Tasman Dixon                                                                                                                                                          |
|   3 |    125.835680 |    157.591355 | Markus A. Grohme                                                                                                                                                      |
|   4 |    523.915461 |    101.966573 | T. Michael Keesey                                                                                                                                                     |
|   5 |    774.430241 |     49.082032 | Matt Crook                                                                                                                                                            |
|   6 |    193.942725 |    575.915179 | Birgit Lang                                                                                                                                                           |
|   7 |    359.471278 |    684.849391 | Shyamal                                                                                                                                                               |
|   8 |    519.711837 |    435.909280 | Robert Bruce Horsfall (vectorized by T. Michael Keesey)                                                                                                               |
|   9 |    931.453215 |    296.143663 | Roberto Díaz Sibaja                                                                                                                                                   |
|  10 |    504.366935 |    258.171382 | Tyler McCraney                                                                                                                                                        |
|  11 |    266.633260 |    240.808808 | Oscar Sanisidro                                                                                                                                                       |
|  12 |    368.410694 |    133.957622 | Matt Crook                                                                                                                                                            |
|  13 |    895.691084 |    676.641658 | Zimices                                                                                                                                                               |
|  14 |    812.046884 |    209.284210 | Skye McDavid                                                                                                                                                          |
|  15 |    204.251682 |    409.282175 | Scott Hartman                                                                                                                                                         |
|  16 |    323.955012 |    533.251140 | Birgit Lang                                                                                                                                                           |
|  17 |    831.786575 |    370.372174 | T. Michael Keesey                                                                                                                                                     |
|  18 |    215.925419 |     98.496357 | Katie S. Collins                                                                                                                                                      |
|  19 |    920.784917 |    753.175102 | Chris huh                                                                                                                                                             |
|  20 |    917.874397 |    471.787775 | Ferran Sayol                                                                                                                                                          |
|  21 |    646.704002 |    312.773869 | Chris Jennings (Risiatto)                                                                                                                                             |
|  22 |    624.705659 |    142.639317 | Chris huh                                                                                                                                                             |
|  23 |    629.044599 |    615.685426 | U.S. National Park Service (vectorized by William Gearty)                                                                                                             |
|  24 |     75.008583 |    625.252416 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
|  25 |    885.686452 |    571.183467 | Zimices                                                                                                                                                               |
|  26 |     86.641531 |    539.200384 | Chris huh                                                                                                                                                             |
|  27 |    673.953264 |    234.415879 | Gareth Monger                                                                                                                                                         |
|  28 |    719.482987 |    316.801119 | Scott Reid                                                                                                                                                            |
|  29 |    306.320484 |     42.033097 | Yan Wong                                                                                                                                                              |
|  30 |    589.629857 |    682.454152 | Rebecca Groom                                                                                                                                                         |
|  31 |    956.469722 |    372.525028 | Michael Scroggie                                                                                                                                                      |
|  32 |    932.518892 |    194.878462 | Maxime Dahirel                                                                                                                                                        |
|  33 |    157.621368 |    750.273306 | Smokeybjb, vectorized by Zimices                                                                                                                                      |
|  34 |     72.907128 |     72.250553 | Ferran Sayol                                                                                                                                                          |
|  35 |    393.354141 |    335.545897 | Steven Traver                                                                                                                                                         |
|  36 |    440.823790 |    376.382341 | Matt Crook                                                                                                                                                            |
|  37 |    443.083487 |    536.928539 | Cathy                                                                                                                                                                 |
|  38 |    667.812928 |     94.164345 | Noah Schlottman, photo from Moorea Biocode                                                                                                                            |
|  39 |    729.171356 |    540.657144 | Steven Traver                                                                                                                                                         |
|  40 |    686.967729 |    444.244159 | NA                                                                                                                                                                    |
|  41 |    169.400456 |    670.567477 | Zimices                                                                                                                                                               |
|  42 |    116.901101 |    228.004101 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  43 |    167.775936 |    480.676795 | Matt Martyniuk (modified by T. Michael Keesey)                                                                                                                        |
|  44 |     44.994154 |    382.496254 | Bryan Carstens                                                                                                                                                        |
|  45 |    133.849007 |    404.710310 | Tasman Dixon                                                                                                                                                          |
|  46 |    550.399693 |    716.303554 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                     |
|  47 |    492.441797 |    777.565646 | Gareth Monger                                                                                                                                                         |
|  48 |    959.429309 |     51.508328 | Tasman Dixon                                                                                                                                                          |
|  49 |     91.996869 |    275.119401 | Tracy A. Heath                                                                                                                                                        |
|  50 |    508.397279 |    575.727365 | Ferran Sayol                                                                                                                                                          |
|  51 |    385.280137 |    776.216846 | Hanyong Pu, Yoshitsugu Kobayashi, Junchang Lü, Li Xu, Yanhua Wu, Huali Chang, Jiming Zhang, Songhai Jia & T. Michael Keesey                                           |
|  52 |    287.874022 |    305.147297 | Maija Karala                                                                                                                                                          |
|  53 |     61.348751 |    741.426376 | Matt Crook                                                                                                                                                            |
|  54 |    265.974587 |    759.743668 | Tasman Dixon                                                                                                                                                          |
|  55 |    700.097293 |    664.822302 | Matt Crook                                                                                                                                                            |
|  56 |    616.723902 |    187.972165 | Scott Hartman                                                                                                                                                         |
|  57 |    853.167010 |    110.780874 | Chris huh                                                                                                                                                             |
|  58 |    160.506096 |    317.542787 | NA                                                                                                                                                                    |
|  59 |    572.071461 |     16.106278 | Scott Hartman                                                                                                                                                         |
|  60 |    232.830783 |    188.253807 | Gareth Monger                                                                                                                                                         |
|  61 |    667.715852 |    754.682836 | Zimices                                                                                                                                                               |
|  62 |    465.042763 |    749.164918 | Smokeybjb                                                                                                                                                             |
|  63 |    444.677766 |    210.247842 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  64 |    404.081410 |    446.007359 | Jordan Mallon (vectorized by T. Michael Keesey)                                                                                                                       |
|  65 |     74.755465 |    506.011549 | Sharon Wegner-Larsen                                                                                                                                                  |
|  66 |    781.466417 |    750.646366 | Margot Michaud                                                                                                                                                        |
|  67 |    977.369378 |    621.809639 | Michelle Site                                                                                                                                                         |
|  68 |    490.366865 |    171.393619 | Roberto Díaz Sibaja                                                                                                                                                   |
|  69 |    627.069488 |    374.851619 | Jagged Fang Designs                                                                                                                                                   |
|  70 |    790.836270 |    447.860401 | Gareth Monger                                                                                                                                                         |
|  71 |    183.845334 |     16.715648 | Xavier Giroux-Bougard                                                                                                                                                 |
|  72 |    793.950670 |    788.766368 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                              |
|  73 |    321.762197 |    596.917519 | Scott Hartman                                                                                                                                                         |
|  74 |    538.762639 |    651.182640 | Chris huh                                                                                                                                                             |
|  75 |     30.234859 |    234.801373 | James R. Spotila and Ray Chatterji                                                                                                                                    |
|  76 |     40.298887 |    147.274675 | Harold N Eyster                                                                                                                                                       |
|  77 |   1001.804292 |    248.809363 | Beth Reinke                                                                                                                                                           |
|  78 |    179.725028 |    465.474362 | Iain Reid                                                                                                                                                             |
|  79 |    835.704651 |    147.784627 | Duane Raver (vectorized by T. Michael Keesey)                                                                                                                         |
|  80 |     94.357581 |     88.174472 | Maija Karala                                                                                                                                                          |
|  81 |    709.053027 |     20.811663 | Sarah Werning                                                                                                                                                         |
|  82 |    456.616799 |    613.250647 | Martin R. Smith, after Skovsted et al 2015                                                                                                                            |
|  83 |    964.708722 |    111.615855 | Zimices                                                                                                                                                               |
|  84 |    822.160261 |    483.982272 | Gareth Monger                                                                                                                                                         |
|  85 |    537.438548 |    196.217385 | Andrew A. Farke                                                                                                                                                       |
|  86 |    812.002370 |    171.663720 | Kosta Mumcuoglu (vectorized by T. Michael Keesey)                                                                                                                     |
|  87 |    990.931893 |    118.757455 | Richard Lampitt, Jeremy Young / NHM (vectorization by Yan Wong)                                                                                                       |
|  88 |    758.026928 |    385.997164 | Eric Moody                                                                                                                                                            |
|  89 |    258.172094 |    628.234291 | Mathieu Pélissié                                                                                                                                                      |
|  90 |    556.300567 |    754.397497 | NA                                                                                                                                                                    |
|  91 |    383.281639 |      7.595496 | CNZdenek                                                                                                                                                              |
|  92 |    422.811770 |     36.998020 | Margot Michaud                                                                                                                                                        |
|  93 |    169.792766 |    246.570887 | Aviceda (photo) & T. Michael Keesey                                                                                                                                   |
|  94 |    515.778882 |    391.111942 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  95 |    495.725154 |     36.594792 | Margot Michaud                                                                                                                                                        |
|  96 |     88.622215 |    787.944575 | Zimices                                                                                                                                                               |
|  97 |     89.752518 |    321.116933 | Michael Day                                                                                                                                                           |
|  98 |    145.716253 |    624.756959 | T. Michael Keesey                                                                                                                                                     |
|  99 |    871.669992 |      8.608578 | Tasman Dixon                                                                                                                                                          |
| 100 |    137.578246 |    104.924126 | Scott Hartman                                                                                                                                                         |
| 101 |    344.610195 |    203.547063 | T. Michael Keesey                                                                                                                                                     |
| 102 |    251.120400 |    729.384078 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 103 |    923.004300 |     96.677540 | Dexter R. Mardis                                                                                                                                                      |
| 104 |    729.468575 |    599.941218 | kreidefossilien.de                                                                                                                                                    |
| 105 |    507.027314 |    502.841320 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 106 |     72.941512 |    180.880876 | Zsoldos Márton (vectorized by T. Michael Keesey)                                                                                                                      |
| 107 |    499.500298 |    363.640643 | Matt Crook                                                                                                                                                            |
| 108 |     25.934373 |    686.907402 | Zimices                                                                                                                                                               |
| 109 |    484.735621 |    482.288306 | Christine Axon                                                                                                                                                        |
| 110 |    107.418229 |    754.281549 | Gareth Monger                                                                                                                                                         |
| 111 |    507.407674 |    671.212353 | FunkMonk (Michael B. H.)                                                                                                                                              |
| 112 |    453.245160 |    656.221707 | Steven Traver                                                                                                                                                         |
| 113 |    555.889128 |    324.258926 | Jagged Fang Designs                                                                                                                                                   |
| 114 |    543.955684 |    367.572689 | FunkMonk                                                                                                                                                              |
| 115 |    901.176686 |    770.227951 | Margot Michaud                                                                                                                                                        |
| 116 |    405.516714 |    515.358613 | Ingo Braasch                                                                                                                                                          |
| 117 |    889.443220 |     77.482374 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 118 |    501.314367 |    524.920107 | Margot Michaud                                                                                                                                                        |
| 119 |    173.667241 |    430.233623 | T. Tischler                                                                                                                                                           |
| 120 |    316.020504 |    470.515310 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                        |
| 121 |    372.192119 |    384.555652 | NA                                                                                                                                                                    |
| 122 |    874.729480 |    612.302326 | Mateus Zica (modified by T. Michael Keesey)                                                                                                                           |
| 123 |    928.419907 |     31.650589 | Andrew R. Gehrke                                                                                                                                                      |
| 124 |    362.495661 |    219.262860 | Armin Reindl                                                                                                                                                          |
| 125 |    152.066365 |    440.562162 | T. Michael Keesey                                                                                                                                                     |
| 126 |    908.848183 |    793.106423 | Anthony Caravaggi                                                                                                                                                     |
| 127 |     44.425748 |    703.077606 | Matt Crook                                                                                                                                                            |
| 128 |    570.897028 |    381.876061 | Falconaumanni and T. Michael Keesey                                                                                                                                   |
| 129 |    958.051986 |     25.153352 | Andrew R. Gehrke                                                                                                                                                      |
| 130 |     60.161455 |    563.655638 | Jaime Headden (vectorized by T. Michael Keesey)                                                                                                                       |
| 131 |    579.383965 |    791.390845 | Matt Crook                                                                                                                                                            |
| 132 |    553.661935 |    523.810855 | Matt Crook                                                                                                                                                            |
| 133 |    108.066935 |     72.905882 | Felix Vaux                                                                                                                                                            |
| 134 |     79.042367 |    761.623788 | Harold N Eyster                                                                                                                                                       |
| 135 |    964.989117 |    295.782628 | Tracy A. Heath                                                                                                                                                        |
| 136 |    532.902384 |    147.186949 | Craig Dylke                                                                                                                                                           |
| 137 |    735.425515 |    186.894128 | T. Michael Keesey                                                                                                                                                     |
| 138 |    594.454792 |    606.319810 | Chuanixn Yu                                                                                                                                                           |
| 139 |    862.787360 |    283.569653 | Erika Schumacher                                                                                                                                                      |
| 140 |    323.780688 |    778.574341 | Catherine Yasuda                                                                                                                                                      |
| 141 |    774.162967 |    634.107901 | John Curtis (vectorized by T. Michael Keesey)                                                                                                                         |
| 142 |    592.109776 |     65.474575 | NA                                                                                                                                                                    |
| 143 |   1015.196545 |     30.850256 | Gareth Monger                                                                                                                                                         |
| 144 |    995.490423 |    774.016819 | Ferran Sayol                                                                                                                                                          |
| 145 |    867.272298 |    785.974305 | Tauana J. Cunha                                                                                                                                                       |
| 146 |     56.318752 |    423.026650 | Kai R. Caspar                                                                                                                                                         |
| 147 |    521.069621 |    693.970352 | Zimices                                                                                                                                                               |
| 148 |     18.367693 |     28.408024 | Zimices                                                                                                                                                               |
| 149 |     38.328597 |     13.942030 | Chris huh                                                                                                                                                             |
| 150 |    723.999881 |    712.482157 | Lukas Panzarin                                                                                                                                                        |
| 151 |    764.530631 |    475.183855 | Gareth Monger                                                                                                                                                         |
| 152 |    777.624520 |    513.258611 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 153 |    822.171183 |    454.057454 | Daniel Jaron                                                                                                                                                          |
| 154 |    625.050588 |    220.287964 | Robert Bruce Horsfall (vectorized by T. Michael Keesey)                                                                                                               |
| 155 |    694.633876 |    775.313684 | Gareth Monger                                                                                                                                                         |
| 156 |    750.131036 |    493.029881 | Andy Wilson                                                                                                                                                           |
| 157 |    776.232354 |    647.946752 | Chris huh                                                                                                                                                             |
| 158 |    642.792533 |     99.461984 | Matt Martyniuk                                                                                                                                                        |
| 159 |    871.151282 |    422.135171 | Steven Traver                                                                                                                                                         |
| 160 |    388.607409 |    549.130375 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 161 |    709.605588 |    219.853591 | Steven Traver                                                                                                                                                         |
| 162 |    800.635344 |    418.830229 | Ingo Braasch                                                                                                                                                          |
| 163 |    162.279226 |    138.797469 | Maija Karala                                                                                                                                                          |
| 164 |    275.716206 |    154.659659 | Tauana J. Cunha                                                                                                                                                       |
| 165 |    878.072132 |    298.865454 | Andy Wilson                                                                                                                                                           |
| 166 |    905.808809 |    501.475788 | Matt Crook                                                                                                                                                            |
| 167 |    882.619572 |    197.268681 | Steven Haddock • Jellywatch.org                                                                                                                                       |
| 168 |    531.699418 |     58.210338 | xgirouxb                                                                                                                                                              |
| 169 |    781.810756 |     93.717645 | Scott Reid                                                                                                                                                            |
| 170 |    270.911934 |    621.643638 | Doug Backlund (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey         |
| 171 |    364.974640 |    276.853513 | Zimices                                                                                                                                                               |
| 172 |     90.205799 |     29.011229 | Ramona J Heim                                                                                                                                                         |
| 173 |    363.705412 |    239.836361 | Matt Crook                                                                                                                                                            |
| 174 |    592.210589 |    417.376646 | Steven Coombs                                                                                                                                                         |
| 175 |    355.003267 |     63.315431 | Markus A. Grohme                                                                                                                                                      |
| 176 |    645.556637 |    464.235429 | Sean McCann                                                                                                                                                           |
| 177 |    398.801447 |    224.730861 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 178 |    391.142314 |    259.922680 | Steven Traver                                                                                                                                                         |
| 179 |    640.918665 |     60.890902 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 180 |    755.514793 |    154.621045 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 181 |     51.489518 |    441.532054 | T. Michael Keesey                                                                                                                                                     |
| 182 |    653.317341 |    282.271466 | NA                                                                                                                                                                    |
| 183 |    926.914612 |    258.963178 | Gareth Monger                                                                                                                                                         |
| 184 |    647.569900 |    781.001592 | Joanna Wolfe                                                                                                                                                          |
| 185 |   1000.998953 |    463.420685 | Yan Wong                                                                                                                                                              |
| 186 |    550.049868 |    157.989329 | Scott Hartman                                                                                                                                                         |
| 187 |    181.017741 |    348.267006 | Margot Michaud                                                                                                                                                        |
| 188 |    184.244380 |    282.761380 | Joanna Wolfe                                                                                                                                                          |
| 189 |   1006.201487 |    193.908985 | Tasman Dixon                                                                                                                                                          |
| 190 |    822.307830 |      5.169050 | James R. Spotila and Ray Chatterji                                                                                                                                    |
| 191 |    804.260327 |    695.953957 | Andrew A. Farke, modified from original by Robert Bruce Horsfall, from Scott 1912                                                                                     |
| 192 |    783.377517 |    149.813673 | Margot Michaud                                                                                                                                                        |
| 193 |    283.720020 |    373.374218 | Gareth Monger                                                                                                                                                         |
| 194 |     90.243490 |    366.448220 | Zimices                                                                                                                                                               |
| 195 |    837.298866 |     84.656328 | Johan Lindgren, Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe                                                                                                  |
| 196 |    858.145653 |    418.437044 | FunkMonk                                                                                                                                                              |
| 197 |     80.719112 |     13.201837 | Harold N Eyster                                                                                                                                                       |
| 198 |     93.480877 |    452.029023 | Ferran Sayol                                                                                                                                                          |
| 199 |    781.983162 |    341.592133 | NA                                                                                                                                                                    |
| 200 |     11.575724 |    480.381256 | Daniel Jaron                                                                                                                                                          |
| 201 |     82.866019 |    378.563211 | Gopal Murali                                                                                                                                                          |
| 202 |    905.408512 |     72.179016 | Matt Crook                                                                                                                                                            |
| 203 |    604.275320 |    101.267515 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 204 |    184.174477 |    511.102801 | Arthur Weasley (vectorized by T. Michael Keesey)                                                                                                                      |
| 205 |    857.596089 |    635.842166 | Matt Crook                                                                                                                                                            |
| 206 |    288.479495 |     83.558994 | Andy Wilson                                                                                                                                                           |
| 207 |    118.601909 |     94.210497 | Zimices                                                                                                                                                               |
| 208 |     43.524479 |    780.605827 | Gareth Monger                                                                                                                                                         |
| 209 |    322.656128 |    705.485244 | Zimices                                                                                                                                                               |
| 210 |    354.995841 |    400.287222 | Steven Traver                                                                                                                                                         |
| 211 |    861.081171 |    400.634641 | Matt Martyniuk                                                                                                                                                        |
| 212 |     13.450017 |    175.218711 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 213 |    990.756992 |    660.985426 | Gareth Monger                                                                                                                                                         |
| 214 |    550.070206 |    604.322260 | Mathieu Pélissié                                                                                                                                                      |
| 215 |      6.197312 |    264.553841 | M Kolmann                                                                                                                                                             |
| 216 |    748.978430 |    602.150043 | Ferran Sayol                                                                                                                                                          |
| 217 |    214.276968 |    795.457517 | Scott Hartman                                                                                                                                                         |
| 218 |    781.966331 |    375.327474 | Oren Peles / vectorized by Yan Wong                                                                                                                                   |
| 219 |    276.724338 |    350.840260 | Beth Reinke                                                                                                                                                           |
| 220 |    332.652730 |    387.763425 | Scott Reid                                                                                                                                                            |
| 221 |    590.624363 |    749.681856 | Sarah Werning                                                                                                                                                         |
| 222 |    148.232414 |    448.355640 | Matt Crook                                                                                                                                                            |
| 223 |     42.955808 |    326.407038 | Mali’o Kodis, image from Brockhaus and Efron Encyclopedic Dictionary                                                                                                  |
| 224 |     46.357381 |     25.160030 | Ferran Sayol                                                                                                                                                          |
| 225 |    637.864843 |     90.341916 | Jaime Headden                                                                                                                                                         |
| 226 |    313.713838 |    351.801735 | Ferran Sayol                                                                                                                                                          |
| 227 |    934.317328 |    124.761576 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 228 |    179.751649 |    552.752904 | NA                                                                                                                                                                    |
| 229 |    904.293326 |     88.099652 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                         |
| 230 |    973.659004 |    734.077249 | Ferran Sayol                                                                                                                                                          |
| 231 |     12.509199 |    546.178518 | Andrés Sánchez                                                                                                                                                        |
| 232 |    705.625948 |    619.287960 | Robert Gay                                                                                                                                                            |
| 233 |   1010.286808 |    782.158482 | Zimices                                                                                                                                                               |
| 234 |     55.773154 |    796.214273 | Margot Michaud                                                                                                                                                        |
| 235 |    967.194221 |    709.364573 | Andrew A. Farke                                                                                                                                                       |
| 236 |    350.087848 |    376.251107 | Lee Harding (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
| 237 |    108.001617 |    564.414250 | T. Michael Keesey (after Joseph Wolf)                                                                                                                                 |
| 238 |   1011.323843 |     16.113249 | T. Michael Keesey, from a photograph by Thea Boodhoo                                                                                                                  |
| 239 |    462.212378 |    318.022814 | Ville-Veikko Sinkkonen                                                                                                                                                |
| 240 |    375.787418 |     30.594555 | Ville-Veikko Sinkkonen                                                                                                                                                |
| 241 |    793.013062 |    289.617149 | Scott Hartman                                                                                                                                                         |
| 242 |    464.721434 |    510.318402 | Steven Traver                                                                                                                                                         |
| 243 |     26.836433 |    200.462817 | Margot Michaud                                                                                                                                                        |
| 244 |     49.206574 |    433.777812 | T. Michael Keesey (vector) and Stuart Halliday (photograph)                                                                                                           |
| 245 |    281.384354 |    164.923953 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                        |
| 246 |    849.374983 |    479.601759 | DW Bapst (modified from Mitchell 1990)                                                                                                                                |
| 247 |    270.152759 |    672.712711 | Zimices                                                                                                                                                               |
| 248 |   1010.795938 |    499.046643 | Markus A. Grohme                                                                                                                                                      |
| 249 |    246.978113 |    290.045332 | Tauana J. Cunha                                                                                                                                                       |
| 250 |    591.048932 |    428.233590 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 251 |    556.599560 |    582.360936 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 252 |     83.891948 |    697.902526 | Ferran Sayol                                                                                                                                                          |
| 253 |    660.663869 |    537.193688 | Matt Crook                                                                                                                                                            |
| 254 |    793.129056 |    656.387633 | Andy Wilson                                                                                                                                                           |
| 255 |    418.514111 |    725.636728 | Ignacio Contreras                                                                                                                                                     |
| 256 |    650.486375 |     12.471285 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 257 |    302.837572 |    435.460467 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 258 |    558.077656 |    544.865513 | John Gould (vectorized by T. Michael Keesey)                                                                                                                          |
| 259 |    747.566978 |      2.652120 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                                 |
| 260 |    988.666963 |    494.751302 | Mathieu Pélissié                                                                                                                                                      |
| 261 |    252.403900 |    668.640711 | Scott Hartman                                                                                                                                                         |
| 262 |    843.266802 |    493.806754 | Erika Schumacher                                                                                                                                                      |
| 263 |    200.841431 |    248.520882 | Chris huh                                                                                                                                                             |
| 264 |    565.293686 |     55.719588 | SauropodomorphMonarch                                                                                                                                                 |
| 265 |    789.810910 |    470.949509 | Manabu Sakamoto                                                                                                                                                       |
| 266 |    802.059176 |    362.859664 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 267 |    474.313232 |    622.315444 | Sharon Wegner-Larsen                                                                                                                                                  |
| 268 |    294.036588 |    276.513524 | Gareth Monger                                                                                                                                                         |
| 269 |    691.611233 |     35.963310 | Ferran Sayol                                                                                                                                                          |
| 270 |    124.881003 |    190.902781 | Yan Wong                                                                                                                                                              |
| 271 |    659.200561 |    350.600290 | Stanton F. Fink, vectorized by Zimices                                                                                                                                |
| 272 |     42.441933 |    122.741649 | Julio Garza                                                                                                                                                           |
| 273 |   1008.955011 |    215.409574 | Gareth Monger                                                                                                                                                         |
| 274 |    431.172895 |     76.017072 | Matt Crook                                                                                                                                                            |
| 275 |    865.987213 |    510.374653 | Andrés Sánchez                                                                                                                                                        |
| 276 |    707.225141 |    784.197425 | Margot Michaud                                                                                                                                                        |
| 277 |    554.718926 |    590.894048 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 278 |    592.835546 |    570.010345 | Mathew Wedel                                                                                                                                                          |
| 279 |    589.510079 |    767.568916 | Ignacio Contreras                                                                                                                                                     |
| 280 |    666.851158 |    202.498404 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 281 |    346.435293 |    230.921643 | Robert Hering                                                                                                                                                         |
| 282 |     63.744062 |    149.954670 | Michele M Tobias                                                                                                                                                      |
| 283 |    694.151814 |    192.855389 | Joanna Wolfe                                                                                                                                                          |
| 284 |    670.720363 |     23.448068 | Xavier Giroux-Bougard                                                                                                                                                 |
| 285 |     14.029638 |      6.173951 | Mathieu Basille                                                                                                                                                       |
| 286 |    225.205390 |    634.965608 | NA                                                                                                                                                                    |
| 287 |    472.377261 |     24.403993 | NA                                                                                                                                                                    |
| 288 |    426.876677 |    604.591442 | Zimices                                                                                                                                                               |
| 289 |    649.031479 |    210.984036 | Joseph J. W. Sertich, Mark A. Loewen                                                                                                                                  |
| 290 |     21.192469 |    212.012445 | Ferran Sayol                                                                                                                                                          |
| 291 |    340.065904 |    261.191686 | Matt Crook                                                                                                                                                            |
| 292 |    102.515224 |    762.287124 | Matt Dempsey                                                                                                                                                          |
| 293 |    289.039917 |    765.153637 | L. Shyamal                                                                                                                                                            |
| 294 |    715.747185 |    433.542315 | Mali’o Kodis, traced image from the National Science Foundation’s Turbellarian Taxonomic Database                                                                     |
| 295 |    259.173631 |    561.327425 | T. Michael Keesey                                                                                                                                                     |
| 296 |     37.686219 |    187.091123 | NA                                                                                                                                                                    |
| 297 |    815.699921 |    310.605095 | Ferran Sayol                                                                                                                                                          |
| 298 |    548.868607 |    341.764036 | Lily Hughes                                                                                                                                                           |
| 299 |    943.000717 |    518.915722 | Sherman Foote Denton (illustration, 1897) and Timothy J. Bartley (silhouette)                                                                                         |
| 300 |    992.117266 |    729.585775 | Tyler Greenfield                                                                                                                                                      |
| 301 |    320.741221 |    358.957123 | Matt Crook                                                                                                                                                            |
| 302 |    388.202563 |    273.578823 | Andrew A. Farke, modified from original by Robert Bruce Horsfall, from Scott 1912                                                                                     |
| 303 |    492.097676 |    386.580427 | Tasman Dixon                                                                                                                                                          |
| 304 |    840.435303 |     36.365291 | Steven Traver                                                                                                                                                         |
| 305 |    521.720674 |    158.244214 | Ingo Braasch                                                                                                                                                          |
| 306 |    339.245515 |    485.810578 | Christoph Schomburg                                                                                                                                                   |
| 307 |    176.911069 |    714.932364 | Ricardo Araújo                                                                                                                                                        |
| 308 |    658.434933 |    100.192499 | Mette Aumala                                                                                                                                                          |
| 309 |     19.591975 |    576.544191 | Rebecca Groom                                                                                                                                                         |
| 310 |    462.947341 |    735.758377 | Jagged Fang Designs                                                                                                                                                   |
| 311 |    754.855556 |    118.264355 | Pranav Iyer (grey ideas)                                                                                                                                              |
| 312 |    232.709635 |    343.069000 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 313 |    432.803414 |    119.819969 | Emily Jane McTavish                                                                                                                                                   |
| 314 |    277.747523 |    728.011060 | Matt Crook                                                                                                                                                            |
| 315 |    547.553595 |    309.498523 | Gareth Monger                                                                                                                                                         |
| 316 |    813.374311 |    506.121467 | Michael Scroggie                                                                                                                                                      |
| 317 |    269.577718 |    597.752241 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 318 |      2.453465 |    126.523158 | Martin R. Smith, after Skovsted et al 2015                                                                                                                            |
| 319 |    353.581330 |     69.255463 | Tasman Dixon                                                                                                                                                          |
| 320 |    447.124430 |    462.247961 | Zimices                                                                                                                                                               |
| 321 |    299.098662 |    419.856606 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 322 |    173.474397 |    203.423060 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 323 |    493.197742 |     18.840318 | Andy Wilson                                                                                                                                                           |
| 324 |    786.703584 |    277.501318 | Tasman Dixon                                                                                                                                                          |
| 325 |    802.019146 |    338.618002 | Crystal Maier                                                                                                                                                         |
| 326 |    419.562410 |     58.356131 | Ignacio Contreras                                                                                                                                                     |
| 327 |    153.924755 |     33.662046 | Matt Crook                                                                                                                                                            |
| 328 |    956.593166 |    687.848247 | zoosnow                                                                                                                                                               |
| 329 |    478.966162 |    151.459465 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 330 |    866.475231 |     40.205631 | Steven Traver                                                                                                                                                         |
| 331 |     37.504739 |    534.559201 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 332 |    770.039951 |    140.914878 | Andy Wilson                                                                                                                                                           |
| 333 |   1000.069796 |    144.574946 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 334 |     49.802644 |    240.334555 | Matt Crook                                                                                                                                                            |
| 335 |    677.474673 |    174.660903 | Bryan Carstens                                                                                                                                                        |
| 336 |    990.565819 |    792.800281 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 337 |    203.643513 |    777.122991 | James R. Spotila and Ray Chatterji                                                                                                                                    |
| 338 |    997.026149 |    155.540695 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 339 |     43.606455 |    464.141196 | Lukasiniho                                                                                                                                                            |
| 340 |    163.502436 |    277.572392 | Gareth Monger                                                                                                                                                         |
| 341 |    603.246099 |    788.199674 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 342 |    538.681312 |     46.479769 | Andy Wilson                                                                                                                                                           |
| 343 |   1013.896528 |    673.725361 | Shyamal                                                                                                                                                               |
| 344 |   1009.005891 |    644.662632 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 345 |    196.832384 |    718.274119 | Steven Traver                                                                                                                                                         |
| 346 |    970.326626 |    458.556767 | NOAA (vectorized by T. Michael Keesey)                                                                                                                                |
| 347 |    235.598954 |    789.904531 | Mali’o Kodis, photograph by Bruno Vellutini                                                                                                                           |
| 348 |    328.080610 |      6.187543 | Shyamal                                                                                                                                                               |
| 349 |    892.779747 |     43.472521 | NA                                                                                                                                                                    |
| 350 |     34.991699 |    788.773522 | Abraão Leite                                                                                                                                                          |
| 351 |    493.708810 |    682.376751 | Scott Hartman                                                                                                                                                         |
| 352 |    872.799565 |    365.096794 | Jay Matternes (modified by T. Michael Keesey)                                                                                                                         |
| 353 |    341.340231 |    245.115254 | Zimices                                                                                                                                                               |
| 354 |    396.149804 |     17.187385 | Margot Michaud                                                                                                                                                        |
| 355 |    253.327093 |    422.140817 | Katie S. Collins                                                                                                                                                      |
| 356 |    436.306007 |    791.462162 | NA                                                                                                                                                                    |
| 357 |    148.990843 |    713.913144 | Michelle Site                                                                                                                                                         |
| 358 |    931.379622 |    635.897287 | Shyamal                                                                                                                                                               |
| 359 |    859.069390 |    425.959645 | Beth Reinke                                                                                                                                                           |
| 360 |    619.712475 |    661.145587 | Matt Crook                                                                                                                                                            |
| 361 |    678.468294 |    796.947386 | Jaime A. Headden (vectorized by T. Michael Keesey)                                                                                                                    |
| 362 |    611.006863 |    729.615108 | Margot Michaud                                                                                                                                                        |
| 363 |    156.965476 |     56.766242 | NA                                                                                                                                                                    |
| 364 |    569.014951 |     37.939751 | FJDegrange                                                                                                                                                            |
| 365 |    206.324504 |     39.587000 | Smokeybjb, vectorized by Zimices                                                                                                                                      |
| 366 |    574.364806 |    724.203672 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 367 |    807.319722 |    295.445879 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 368 |    174.620391 |    619.373020 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 369 |    901.798594 |    261.861154 | Taenadoman                                                                                                                                                            |
| 370 |     33.503353 |    302.259245 | Jon Hill (Photo by Benjamint444: <http://en.wikipedia.org/wiki/File:Blue-footed-booby.jpg>)                                                                           |
| 371 |    175.533077 |    269.683993 | Markus A. Grohme                                                                                                                                                      |
| 372 |    300.747797 |    332.423650 | FunkMonk                                                                                                                                                              |
| 373 |    300.227847 |    357.199418 | Tasman Dixon                                                                                                                                                          |
| 374 |    101.361803 |    115.242866 | Matt Martyniuk                                                                                                                                                        |
| 375 |    588.819017 |    226.110656 | Maija Karala                                                                                                                                                          |
| 376 |     28.458007 |    278.499475 | Kanchi Nanjo                                                                                                                                                          |
| 377 |    258.589393 |    651.509858 | Ignacio Contreras                                                                                                                                                     |
| 378 |    897.154759 |    717.761510 | Mathieu Basille                                                                                                                                                       |
| 379 |    663.082251 |    772.583455 | Gareth Monger                                                                                                                                                         |
| 380 |    147.913685 |     76.853790 | T. Michael Keesey                                                                                                                                                     |
| 381 |    736.364773 |     50.952113 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 382 |    611.054130 |    427.486518 | Kai R. Caspar                                                                                                                                                         |
| 383 |    886.674527 |    326.355589 | Tracy A. Heath                                                                                                                                                        |
| 384 |    481.305140 |    377.582273 | Michael Scroggie                                                                                                                                                      |
| 385 |     69.230765 |    454.152000 | Anthony Caravaggi                                                                                                                                                     |
| 386 |    980.034050 |    529.106431 | Ingo Braasch                                                                                                                                                          |
| 387 |    190.244939 |    450.788715 | C. Camilo Julián-Caballero                                                                                                                                            |
| 388 |    970.457499 |     42.775377 | Matt Crook                                                                                                                                                            |
| 389 |    271.208268 |    434.901121 | Margot Michaud                                                                                                                                                        |
| 390 |    117.180388 |    786.765362 | Tracy A. Heath                                                                                                                                                        |
| 391 |    124.692561 |    257.880570 | NA                                                                                                                                                                    |
| 392 |    965.386653 |    776.973035 | Chloé Schmidt                                                                                                                                                         |
| 393 |    603.369215 |    662.868728 | Benjamin Monod-Broca                                                                                                                                                  |
| 394 |     26.488470 |    652.389652 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 395 |    998.444496 |    556.382598 | Julie Blommaert based on photo by Sofdrakou                                                                                                                           |
| 396 |    657.888792 |    261.757434 | Tasman Dixon                                                                                                                                                          |
| 397 |    116.710090 |    438.948606 | Scott Hartman                                                                                                                                                         |
| 398 |    295.454350 |    782.235902 | Trond R. Oskars                                                                                                                                                       |
| 399 |    868.888320 |    205.038313 | Sarefo (vectorized by T. Michael Keesey)                                                                                                                              |
| 400 |    752.850230 |    132.143866 | Xavier Giroux-Bougard                                                                                                                                                 |
| 401 |    726.644045 |    128.299443 | Steven Traver                                                                                                                                                         |
| 402 |    603.795541 |     43.646763 | Maija Karala                                                                                                                                                          |
| 403 |     12.105794 |    277.158319 | Katie S. Collins                                                                                                                                                      |
| 404 |   1008.976360 |     43.443893 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 405 |    289.601350 |    619.693041 | NA                                                                                                                                                                    |
| 406 |    532.886493 |    628.072118 | Scott Hartman                                                                                                                                                         |
| 407 |    626.172073 |    163.546234 | Aleksey Nagovitsyn (vectorized by T. Michael Keesey)                                                                                                                  |
| 408 |    358.168361 |    438.671104 | Melissa Broussard                                                                                                                                                     |
| 409 |     70.477065 |     19.155708 | Geoff Shaw                                                                                                                                                            |
| 410 |    902.354630 |    136.298262 | Nina Skinner                                                                                                                                                          |
| 411 |    984.735584 |     72.684809 | Skye McDavid                                                                                                                                                          |
| 412 |    801.953205 |    394.307211 | Christian A. Masnaghetti                                                                                                                                              |
| 413 |    742.934392 |    366.046316 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 414 |    809.714511 |    108.346311 | Harold N Eyster                                                                                                                                                       |
| 415 |     87.523331 |    474.561144 | Verisimilus                                                                                                                                                           |
| 416 |    243.371587 |    483.857181 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 417 |    539.891383 |    381.699080 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 418 |    240.105277 |    509.684940 | T. Michael Keesey                                                                                                                                                     |
| 419 |    269.614347 |     16.479250 | Leann Biancani, photo by Kenneth Clifton                                                                                                                              |
| 420 |    144.723658 |    785.490518 | Verdilak                                                                                                                                                              |
| 421 |     21.056368 |    264.441252 | Вальдимар (vectorized by T. Michael Keesey)                                                                                                                           |
| 422 |    892.037866 |    362.867306 | Tracy A. Heath                                                                                                                                                        |
| 423 |    202.986514 |    539.171364 | Joanna Wolfe                                                                                                                                                          |
| 424 |    519.339509 |    349.561610 | Lukasiniho                                                                                                                                                            |
| 425 |     68.794499 |    304.331054 | Zimices                                                                                                                                                               |
| 426 |    729.698707 |     31.648602 | Chris huh                                                                                                                                                             |
| 427 |    982.464463 |     92.225949 | Steven Traver                                                                                                                                                         |
| 428 |    368.170680 |    446.054983 | Zimices                                                                                                                                                               |
| 429 |    535.617587 |    662.937180 | Margot Michaud                                                                                                                                                        |
| 430 |    698.300393 |    497.729026 | T. Michael Keesey                                                                                                                                                     |
| 431 |    276.031189 |    370.792164 | Gareth Monger                                                                                                                                                         |
| 432 |    797.030930 |    497.920159 | T. Michael Keesey                                                                                                                                                     |
| 433 |    298.823317 |    397.460188 | T. Michael Keesey (vectorization) and Nadiatalent (photography)                                                                                                       |
| 434 |    891.027919 |    704.047275 | Scott Reid                                                                                                                                                            |
| 435 |    996.854264 |    424.767207 | Zimices                                                                                                                                                               |
| 436 |    863.333592 |    730.473688 | Margot Michaud                                                                                                                                                        |
| 437 |    541.555212 |     37.305538 | Kanchi Nanjo                                                                                                                                                          |
| 438 |    938.325702 |    796.511750 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 439 |    863.828716 |    482.784986 | Matt Crook                                                                                                                                                            |
| 440 |    752.348117 |    739.160113 | Kent Elson Sorgon                                                                                                                                                     |
| 441 |    897.765557 |    627.470607 | Matt Crook                                                                                                                                                            |
| 442 |    612.919402 |    352.474945 | Zimices                                                                                                                                                               |
| 443 |    387.961829 |    494.795912 | Steven Traver                                                                                                                                                         |
| 444 |    248.999172 |    751.478517 | Scott Reid                                                                                                                                                            |
| 445 |    329.214341 |    213.895696 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 446 |    880.561085 |    243.348741 | Steven Traver                                                                                                                                                         |
| 447 |    483.865924 |    696.688925 | Matt Dempsey                                                                                                                                                          |
| 448 |    126.093962 |    684.802631 | Mali’o Kodis, photograph by “Wildcat Dunny” (<http://www.flickr.com/people/wildcat_dunny/>)                                                                           |
| 449 |    783.832119 |    178.226968 | Gareth Monger                                                                                                                                                         |
| 450 |    504.559677 |    542.861948 | Dean Schnabel                                                                                                                                                         |
| 451 |    715.144092 |    103.494480 | Renata F. Martins                                                                                                                                                     |
| 452 |    458.916286 |    334.330204 | Caleb M. Brown                                                                                                                                                        |
| 453 |    674.308676 |    476.551119 | Felix Vaux and Steven A. Trewick                                                                                                                                      |
| 454 |    993.360066 |    484.185005 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 455 |    521.887407 |    320.991142 | Margot Michaud                                                                                                                                                        |
| 456 |    300.837172 |     79.127847 | Steven Traver                                                                                                                                                         |
| 457 |    284.714218 |    404.277325 | Kamil S. Jaron                                                                                                                                                        |
| 458 |    455.550108 |    124.135626 | Steven Traver                                                                                                                                                         |
| 459 |    549.968328 |    569.688481 | T. Michael Keesey (vectorization) and Tony Hisgett (photography)                                                                                                      |
| 460 |    417.684396 |    740.168400 | CNZdenek                                                                                                                                                              |
| 461 |     15.436873 |    285.573832 | Scott Reid                                                                                                                                                            |
| 462 |    765.146407 |    168.801492 | Andy Wilson                                                                                                                                                           |
| 463 |    701.080796 |    592.722394 | Scott Hartman                                                                                                                                                         |
| 464 |    752.061210 |    666.907781 | Ferran Sayol                                                                                                                                                          |
| 465 |    639.426934 |     49.947658 | Ian Burt (original) and T. Michael Keesey (vectorization)                                                                                                             |
| 466 |    444.597213 |    486.422806 | Mathieu Basille                                                                                                                                                       |
| 467 |    125.863826 |    575.425161 | LeonardoG (photography) and T. Michael Keesey (vectorization)                                                                                                         |
| 468 |    993.005780 |    223.934000 | Gareth Monger                                                                                                                                                         |
| 469 |    562.435651 |    219.101669 | Margot Michaud                                                                                                                                                        |
| 470 |    783.978182 |    360.431286 | Steven Traver                                                                                                                                                         |
| 471 |    498.657391 |    203.578256 | Gareth Monger                                                                                                                                                         |
| 472 |     18.349448 |    160.878417 | Vijay Cavale (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey          |
| 473 |   1011.544133 |    742.802615 | Tasman Dixon                                                                                                                                                          |
| 474 |     18.293836 |    728.964005 | Wynston Cooper (photo) and Albertonykus (silhouette)                                                                                                                  |
| 475 |    990.854004 |    687.645069 | Steven Traver                                                                                                                                                         |
| 476 |    799.259304 |    134.693815 | Terpsichores                                                                                                                                                          |
| 477 |    823.053230 |    275.734956 | Sharon Wegner-Larsen                                                                                                                                                  |
| 478 |    332.228528 |    419.931939 | CNZdenek                                                                                                                                                              |
| 479 |     42.628710 |    209.105461 | Chris huh                                                                                                                                                             |
| 480 |    635.071246 |    714.672263 | Matt Crook                                                                                                                                                            |
| 481 |    308.517855 |    768.170877 | T. Michael Keesey                                                                                                                                                     |
| 482 |    227.505778 |    608.348039 | Melissa Broussard                                                                                                                                                     |
| 483 |    402.205110 |    186.125575 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 484 |    515.209759 |    191.752089 | Mason McNair                                                                                                                                                          |
| 485 |    301.233904 |    698.214435 | Matt Crook                                                                                                                                                            |
| 486 |    372.744696 |    491.787253 | Matt Crook                                                                                                                                                            |
| 487 |    825.217712 |    248.666483 | Almandine (vectorized by T. Michael Keesey)                                                                                                                           |
| 488 |    382.304410 |    505.820862 | Margot Michaud                                                                                                                                                        |
| 489 |    385.038381 |    703.180062 | Sarah Werning                                                                                                                                                         |
| 490 |    728.148074 |    120.628080 | Frank Förster                                                                                                                                                         |
| 491 |    408.088225 |    691.323741 | Emil Schmidt (vectorized by Maxime Dahirel)                                                                                                                           |
| 492 |    427.087776 |    287.608078 | Steven Haddock • Jellywatch.org                                                                                                                                       |
| 493 |    542.124193 |    331.686491 | Dori <dori@merr.info> (source photo) and Nevit Dilmen                                                                                                                 |
| 494 |     97.588269 |    675.386513 | Gareth Monger                                                                                                                                                         |
| 495 |    458.954732 |    727.445518 | Christoph Schomburg                                                                                                                                                   |
| 496 |     47.544753 |    224.860477 | Gareth Monger                                                                                                                                                         |
| 497 |    931.659254 |    773.101078 | NA                                                                                                                                                                    |
| 498 |    721.885634 |    255.853083 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 499 |    794.058281 |    641.157484 | Agnello Picorelli                                                                                                                                                     |
| 500 |    445.142026 |    614.843915 | NA                                                                                                                                                                    |
| 501 |    938.312951 |    505.408721 | NA                                                                                                                                                                    |
| 502 |     57.654797 |    381.864410 | Collin Gross                                                                                                                                                          |
| 503 |    424.301239 |    702.684056 | Dave Angelini                                                                                                                                                         |
| 504 |    834.257951 |    285.739660 | Tasman Dixon                                                                                                                                                          |
| 505 |    432.162955 |    645.925236 | George Edward Lodge                                                                                                                                                   |
| 506 |    676.502431 |    125.547101 | Ferran Sayol                                                                                                                                                          |
| 507 |    130.873492 |    244.637785 | Markus A. Grohme                                                                                                                                                      |
| 508 |    924.012487 |      4.588342 | Margot Michaud                                                                                                                                                        |
| 509 |    156.399730 |    548.480281 | Zimices                                                                                                                                                               |
| 510 |     27.680811 |    668.524551 | Natalie Claunch                                                                                                                                                       |
| 511 |    606.602101 |    684.814473 | Andy Wilson                                                                                                                                                           |
| 512 |    960.949849 |    303.563884 | Rebecca Groom                                                                                                                                                         |
| 513 |    892.846504 |     60.529636 | Zimices                                                                                                                                                               |
| 514 |    851.806405 |    613.627525 | Matt Crook                                                                                                                                                            |
| 515 |    499.601036 |    556.789909 | T. Michael Keesey                                                                                                                                                     |
| 516 |    581.137075 |    400.779407 | Michael Scroggie                                                                                                                                                      |
| 517 |    626.551321 |    540.405821 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 518 |    667.040018 |    108.959630 | Birgit Lang                                                                                                                                                           |
| 519 |     15.153517 |     92.108138 | Michelle Site                                                                                                                                                         |
| 520 |      6.471873 |    590.566721 | Audrey Ely                                                                                                                                                            |
| 521 |    888.837864 |    738.272248 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 522 |    710.781999 |    198.417413 | Michele M Tobias                                                                                                                                                      |
| 523 |    422.354576 |    554.628931 | Smokeybjb, vectorized by Zimices                                                                                                                                      |
| 524 |    698.776392 |    723.881387 | Andy Wilson                                                                                                                                                           |
| 525 |    815.599360 |    645.922825 | Margot Michaud                                                                                                                                                        |
| 526 |    400.305703 |    528.093059 | Andy Wilson                                                                                                                                                           |
| 527 |    237.949021 |    710.131441 | Matt Crook                                                                                                                                                            |
| 528 |    404.998976 |    711.816992 | Beth Reinke                                                                                                                                                           |
| 529 |    626.973449 |    344.901619 | NA                                                                                                                                                                    |
| 530 |    771.160051 |    405.067992 | Zimices                                                                                                                                                               |
| 531 |    506.757835 |    309.705976 | Alexandre Vong                                                                                                                                                        |
| 532 |    850.775625 |    444.260820 | Scott Hartman                                                                                                                                                         |
| 533 |    625.861966 |    435.941761 | Chase Brownstein                                                                                                                                                      |
| 534 |    866.240451 |     53.619754 | Martin Kevil                                                                                                                                                          |
| 535 |     31.037257 |    561.628785 | Margot Michaud                                                                                                                                                        |
| 536 |    546.428047 |    471.692519 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 537 |     23.431054 |    145.195892 | Gareth Monger                                                                                                                                                         |
| 538 |    368.695248 |    196.070940 | Gareth Monger                                                                                                                                                         |
| 539 |    283.459955 |    109.890332 | Maija Karala                                                                                                                                                          |
| 540 |    567.450443 |    311.837771 | Matt Crook                                                                                                                                                            |
| 541 |    222.799831 |     39.123641 | Jessica Anne Miller                                                                                                                                                   |
| 542 |    961.925229 |    422.974858 | Melissa Broussard                                                                                                                                                     |
| 543 |    461.050039 |    688.894870 | Steven Traver                                                                                                                                                         |
| 544 |    951.037028 |    778.558737 | Tyler Greenfield and Dean Schnabel                                                                                                                                    |
| 545 |    184.815870 |    255.210948 | Martin R. Smith                                                                                                                                                       |
| 546 |   1010.807882 |    301.399277 | NA                                                                                                                                                                    |
| 547 |    456.029930 |    474.222531 | Tauana J. Cunha                                                                                                                                                       |
| 548 |     43.050354 |    164.821608 | Scott Hartman                                                                                                                                                         |
| 549 |    380.764902 |    618.929848 | Zimices                                                                                                                                                               |
| 550 |    921.057457 |    135.346398 | NA                                                                                                                                                                    |
| 551 |    701.829915 |    208.396500 | M Kolmann                                                                                                                                                             |
| 552 |    648.268228 |    473.104692 | I. Geoffroy Saint-Hilaire (vectorized by T. Michael Keesey)                                                                                                           |
| 553 |     16.991900 |    639.724686 | Frank Förster (based on a picture by Hans Hillewaert)                                                                                                                 |
| 554 |    195.799092 |    337.862255 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 555 |    990.355483 |     46.357104 | Dean Schnabel                                                                                                                                                         |
| 556 |    260.758738 |    448.420409 | Keith Murdock (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey         |
| 557 |    385.405797 |    251.481287 | Chris huh                                                                                                                                                             |
| 558 |    225.936483 |    212.473535 | Melissa Broussard                                                                                                                                                     |
| 559 |    539.868324 |     52.724168 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                              |
| 560 |     99.753453 |    433.022538 | Felix Vaux                                                                                                                                                            |
| 561 |    554.063653 |    192.501715 | Felix Vaux                                                                                                                                                            |
| 562 |   1002.624708 |    449.180158 | Shyamal                                                                                                                                                               |
| 563 |    147.874136 |    116.633156 | Kanchi Nanjo                                                                                                                                                          |
| 564 |    790.038384 |    190.397751 | M. Antonio Todaro, Tobias Kånneby, Matteo Dal Zotto, and Ulf Jondelius (vectorized by T. Michael Keesey)                                                              |
| 565 |    164.882558 |    353.378539 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 566 |    178.048848 |    684.344277 | Ferran Sayol                                                                                                                                                          |
| 567 |    239.877467 |    645.669856 | Zimices                                                                                                                                                               |
| 568 |    286.232912 |    482.486013 | Jiekun He                                                                                                                                                             |
| 569 |    123.675659 |    135.292476 | Matt Crook                                                                                                                                                            |
| 570 |    112.095041 |    103.727125 | Chris huh                                                                                                                                                             |
| 571 |    627.175117 |    450.342939 | Jonathan Wells                                                                                                                                                        |
| 572 |     15.096669 |    621.354143 | T. Michael Keesey                                                                                                                                                     |
| 573 |     14.215079 |    196.374718 | Zimices                                                                                                                                                               |
| 574 |    309.671421 |    713.499062 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 575 |    335.969068 |    584.754534 | C. Camilo Julián-Caballero                                                                                                                                            |
| 576 |    620.372644 |    249.323407 | Emily Willoughby                                                                                                                                                      |
| 577 |    755.158262 |    226.779078 | Matthew Hooge (vectorized by T. Michael Keesey)                                                                                                                       |
| 578 |    945.994283 |    698.402590 | Sarah Werning                                                                                                                                                         |
| 579 |    706.401878 |     51.217950 | Chris huh                                                                                                                                                             |
| 580 |    649.861270 |    113.370567 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 581 |    697.556377 |    163.455131 | Matt Crook                                                                                                                                                            |
| 582 |    840.989336 |    630.895010 | NA                                                                                                                                                                    |
| 583 |    119.264658 |    265.553226 | Rachel Shoop                                                                                                                                                          |
| 584 |    549.805928 |    282.952747 | Zimices                                                                                                                                                               |
| 585 |    423.997451 |    367.900270 | Enoch Joseph Wetsy (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey    |
| 586 |    424.522222 |    582.701093 | NA                                                                                                                                                                    |
| 587 |    149.339346 |    136.010687 | Mali’o Kodis, photograph by Melissa Frey                                                                                                                              |
| 588 |    837.427085 |     72.850826 | Maxime Dahirel                                                                                                                                                        |
| 589 |    136.671325 |     63.734161 | Leon P. A. M. Claessens, Patrick M. O’Connor, David M. Unwin                                                                                                          |
| 590 |    749.840845 |    212.599542 | Charles Doolittle Walcott (vectorized by T. Michael Keesey)                                                                                                           |
| 591 |    631.211308 |    390.463774 | Original drawing by Antonov, vectorized by Roberto Díaz Sibaja                                                                                                        |
| 592 |     86.514644 |    107.480636 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                          |
| 593 |   1008.140179 |    760.511786 | Noah Schlottman                                                                                                                                                       |
| 594 |    931.002746 |    592.961733 | Joanna Wolfe                                                                                                                                                          |
| 595 |    746.111147 |    171.577653 | NA                                                                                                                                                                    |
| 596 |    285.810009 |     70.443338 | Julio Garza                                                                                                                                                           |
| 597 |   1018.838155 |    428.333220 | NA                                                                                                                                                                    |
| 598 |    154.335970 |    572.241753 | Renata F. Martins                                                                                                                                                     |
| 599 |    964.939211 |    671.018330 | Felix Vaux                                                                                                                                                            |
| 600 |    381.683747 |    476.615503 | Matt Crook                                                                                                                                                            |
| 601 |    761.590869 |    710.903654 | Gareth Monger                                                                                                                                                         |
| 602 |    283.629818 |    117.200170 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                                     |
| 603 |    828.846244 |    476.460945 | Scott Hartman                                                                                                                                                         |
| 604 |    534.864245 |    125.674863 | Zimices, based in Mauricio Antón skeletal                                                                                                                             |
| 605 |    810.884057 |    657.354722 | Zimices                                                                                                                                                               |
| 606 |    859.199636 |     88.281018 | Margot Michaud                                                                                                                                                        |
| 607 |    690.430352 |    183.140955 | Beth Reinke                                                                                                                                                           |
| 608 |    301.879148 |    793.237367 | Steven Traver                                                                                                                                                         |
| 609 |    279.894056 |    201.915201 | Isaure Scavezzoni                                                                                                                                                     |
| 610 |    873.171931 |    170.342722 | Shyamal                                                                                                                                                               |
| 611 |    836.813073 |    188.945758 | Matt Martyniuk (modified by T. Michael Keesey)                                                                                                                        |
| 612 |    421.699693 |    793.019408 | Jaime Headden                                                                                                                                                         |
| 613 |    902.657906 |      9.093532 | Zimices                                                                                                                                                               |
| 614 |    107.950262 |    377.542435 | Scott Hartman                                                                                                                                                         |
| 615 |     33.512155 |    174.814110 | Jagged Fang Designs                                                                                                                                                   |
| 616 |     30.436469 |    220.892182 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 617 |    191.581809 |    296.190294 | Michael Day                                                                                                                                                           |
| 618 |    628.507699 |    278.433334 | Joanna Wolfe                                                                                                                                                          |
| 619 |     74.353171 |     32.301081 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 620 |    459.091482 |    144.309489 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 621 |    769.925188 |    582.623566 | Ghedo and T. Michael Keesey                                                                                                                                           |
| 622 |    327.600541 |    242.494025 | NA                                                                                                                                                                    |
| 623 |    274.629723 |    136.731652 | Ludwik Gąsiorowski                                                                                                                                                    |
| 624 |    399.550753 |    293.996122 | Zimices                                                                                                                                                               |
| 625 |    772.209057 |     34.553344 | Steven Traver                                                                                                                                                         |
| 626 |    625.694876 |    696.291642 | Zimices                                                                                                                                                               |
| 627 |    775.459949 |    661.077935 | Gareth Monger                                                                                                                                                         |
| 628 |   1000.846887 |      6.884455 | Chris huh                                                                                                                                                             |
| 629 |    473.039532 |    673.435080 | Yan Wong                                                                                                                                                              |
| 630 |     87.913236 |    581.238540 | Gareth Monger                                                                                                                                                         |
| 631 |    289.255404 |    574.496536 | Jessica Anne Miller                                                                                                                                                   |
| 632 |    286.674920 |      7.469728 | Riccardo Percudani                                                                                                                                                    |
| 633 |    485.701334 |    131.298488 | Caleb M. Brown                                                                                                                                                        |
| 634 |    472.240776 |     28.891854 | Felix Vaux                                                                                                                                                            |
| 635 |     89.018474 |    519.101748 | Lukasiniho                                                                                                                                                            |
| 636 |    821.066740 |    707.092545 | NA                                                                                                                                                                    |
| 637 |    864.751189 |    319.757764 | T. Michael Keesey (after Walker & al.)                                                                                                                                |
| 638 |    412.046563 |    353.803557 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 639 |    496.502753 |    320.520332 | Kanako Bessho-Uehara                                                                                                                                                  |
| 640 |    481.462956 |    494.506875 | Alex Slavenko                                                                                                                                                         |
| 641 |    637.983657 |    253.792572 | Jagged Fang Designs                                                                                                                                                   |
| 642 |    248.682774 |    583.925266 | T. Michael Keesey                                                                                                                                                     |
| 643 |    998.195489 |    173.500315 | Jon Hill                                                                                                                                                              |
| 644 |    794.559307 |    108.331031 | Steven Traver                                                                                                                                                         |
| 645 |    606.206274 |    207.116577 | Smokeybjb                                                                                                                                                             |
| 646 |    127.129298 |     32.035922 | Ingo Braasch                                                                                                                                                          |
| 647 |    998.028416 |    526.360919 | Sarah Werning                                                                                                                                                         |
| 648 |    787.627857 |    526.360393 | Roberto Díaz Sibaja                                                                                                                                                   |
| 649 |    201.427066 |    692.621102 | Roger Witter, vectorized by Zimices                                                                                                                                   |
| 650 |    131.540091 |     79.174741 | Margot Michaud                                                                                                                                                        |
| 651 |    721.743917 |    729.315670 | CNZdenek                                                                                                                                                              |
| 652 |    494.203282 |    491.439282 | Steven Traver                                                                                                                                                         |
| 653 |    967.488229 |    495.870657 | Lily Hughes                                                                                                                                                           |
| 654 |    465.177561 |    158.254378 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
| 655 |    838.738844 |    293.282170 | Markus A. Grohme                                                                                                                                                      |
| 656 |    153.358761 |    263.764719 | Gareth Monger                                                                                                                                                         |
| 657 |    422.016142 |    760.209387 | Zimices                                                                                                                                                               |
| 658 |    210.286364 |    711.135199 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 659 |     69.640564 |    101.974368 | Tracy A. Heath                                                                                                                                                        |
| 660 |    214.592551 |    283.343086 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 661 |    667.772925 |    652.491428 | Zimices                                                                                                                                                               |
| 662 |    657.146780 |    486.345103 | Matt Crook                                                                                                                                                            |
| 663 |    242.871470 |    164.803191 | Ignacio Contreras                                                                                                                                                     |
| 664 |    921.676918 |    776.768841 | Gareth Monger                                                                                                                                                         |
| 665 |    303.973136 |    381.838200 | NA                                                                                                                                                                    |
| 666 |    215.909546 |    485.059485 | Margot Michaud                                                                                                                                                        |
| 667 |    306.760898 |    138.162657 | Joe Schneid (vectorized by T. Michael Keesey)                                                                                                                         |
| 668 |    239.518805 |    589.230341 | Thea Boodhoo (photograph) and T. Michael Keesey (vectorization)                                                                                                       |
| 669 |    275.456499 |    468.075276 | Shyamal                                                                                                                                                               |
| 670 |    390.324903 |    373.009750 | Jagged Fang Designs                                                                                                                                                   |
| 671 |    574.071783 |    539.648680 | Margot Michaud                                                                                                                                                        |
| 672 |   1008.999608 |    661.263586 | Zimices                                                                                                                                                               |
| 673 |    178.286502 |    531.920055 | Jack Mayer Wood                                                                                                                                                       |
| 674 |    387.498074 |    718.264861 | T. Michael Keesey                                                                                                                                                     |
| 675 |     23.302572 |    593.368748 | Inessa Voet                                                                                                                                                           |
| 676 |     12.864206 |    105.083275 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 677 |    575.886511 |    223.197513 | Mathieu Pélissié                                                                                                                                                      |
| 678 |      7.403354 |    244.283531 | S.Martini                                                                                                                                                             |
| 679 |    196.114401 |    228.688448 | Scott Hartman                                                                                                                                                         |
| 680 |    614.029856 |    407.989396 | Armin Reindl                                                                                                                                                          |
| 681 |    139.284990 |    337.110583 | Andrew A. Farke, shell lines added by Yan Wong                                                                                                                        |
| 682 |    437.159561 |    629.911154 | FunkMonk                                                                                                                                                              |
| 683 |    565.151028 |    399.998212 | Margot Michaud                                                                                                                                                        |
| 684 |    406.420058 |    552.580136 | Mathieu Pélissié                                                                                                                                                      |
| 685 |    295.565387 |    708.674733 | Markus A. Grohme                                                                                                                                                      |
| 686 |    103.356583 |    184.068200 | Auckland Museum                                                                                                                                                       |
| 687 |     25.084250 |     83.821851 | Steven Traver                                                                                                                                                         |
| 688 |   1009.325461 |    170.491234 | Ferran Sayol                                                                                                                                                          |
| 689 |    735.188841 |    468.172811 | Matt Crook                                                                                                                                                            |
| 690 |     21.410150 |    713.129137 | Zimices                                                                                                                                                               |
| 691 |    786.384259 |    267.544916 | Matt Crook                                                                                                                                                            |
| 692 |    991.481501 |    477.175415 | Chris huh                                                                                                                                                             |
| 693 |    845.449752 |     55.482118 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 694 |    702.309892 |    386.374369 | Margot Michaud                                                                                                                                                        |
| 695 |    327.082792 |    347.613050 | Kamil S. Jaron                                                                                                                                                        |
| 696 |    562.963018 |    607.709197 | T. Michael Keesey                                                                                                                                                     |
| 697 |    358.092477 |    457.795811 | Ferran Sayol                                                                                                                                                          |
| 698 |    131.144077 |     43.281594 | Cathy                                                                                                                                                                 |
| 699 |    982.037490 |     25.754501 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 700 |    656.054425 |    727.195623 | Sarah Werning                                                                                                                                                         |
| 701 |    384.790160 |     48.946800 | Fernando Carezzano                                                                                                                                                    |
| 702 |    390.249465 |    592.677213 | Steven Traver                                                                                                                                                         |
| 703 |    831.351825 |    639.608562 | Birgit Lang                                                                                                                                                           |
| 704 |    783.119756 |    579.948712 | Yan Wong                                                                                                                                                              |
| 705 |    448.253076 |    443.154544 | Markus A. Grohme                                                                                                                                                      |
| 706 |    688.608684 |      9.364959 | Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus                                              |
| 707 |    868.709926 |    379.259341 | NA                                                                                                                                                                    |
| 708 |     46.934837 |    786.850173 | Chris huh                                                                                                                                                             |
| 709 |    714.089796 |    453.399739 | Marmelad                                                                                                                                                              |
| 710 |    232.201007 |    259.308204 | Paul O. Lewis                                                                                                                                                         |
| 711 |     59.301651 |    690.715523 | Zimices                                                                                                                                                               |
| 712 |    169.415228 |    785.657056 | Gareth Monger                                                                                                                                                         |
| 713 |    772.210219 |    288.565674 | Dantheman9758 (vectorized by T. Michael Keesey)                                                                                                                       |
| 714 |    480.757246 |    199.562840 | CNZdenek                                                                                                                                                              |
| 715 |    711.385216 |    708.486040 | Zimices                                                                                                                                                               |
| 716 |    133.619405 |    456.530631 | Andy Wilson                                                                                                                                                           |
| 717 |    759.241117 |    367.031600 | Martin R. Smith, after Skovsted et al 2015                                                                                                                            |
| 718 |    678.087214 |    497.183486 | Matt Crook                                                                                                                                                            |
| 719 |    980.861325 |    203.169461 | Zimices                                                                                                                                                               |
| 720 |     50.760483 |    415.062715 | Matt Crook                                                                                                                                                            |
| 721 |    672.150851 |    681.512268 | Birgit Lang                                                                                                                                                           |
| 722 |    833.054638 |    169.623203 | Ferran Sayol                                                                                                                                                          |
| 723 |    287.597732 |    265.078732 | Gareth Monger                                                                                                                                                         |
| 724 |    860.284713 |     29.714655 | Nobu Tamura                                                                                                                                                           |
| 725 |    309.783898 |      5.893138 | Andrew A. Farke                                                                                                                                                       |
| 726 |    353.022702 |      8.969273 | Steven Traver                                                                                                                                                         |
| 727 |    585.409033 |    625.710820 | Ferran Sayol                                                                                                                                                          |
| 728 |    591.150231 |    443.910477 | Chris huh                                                                                                                                                             |
| 729 |    541.063756 |    388.559742 | Erika Schumacher                                                                                                                                                      |
| 730 |    534.532483 |    497.708531 | Crystal Maier                                                                                                                                                         |
| 731 |     67.936405 |    396.255585 | Collin Gross                                                                                                                                                          |
| 732 |    763.548820 |    428.727847 | Birgit Lang                                                                                                                                                           |
| 733 |    867.176844 |    149.416710 | Katie S. Collins                                                                                                                                                      |
| 734 |    880.680174 |    409.610178 | Zimices                                                                                                                                                               |
| 735 |     88.310111 |    126.273266 | Tauana J. Cunha                                                                                                                                                       |
| 736 |    267.620347 |    787.942246 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 737 |     59.754698 |     15.136096 | Sarah Werning                                                                                                                                                         |
| 738 |    146.908962 |    179.762011 | Prin Pattawaro (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey        |
| 739 |    630.747572 |    654.514002 | Xavier Giroux-Bougard                                                                                                                                                 |
| 740 |    818.476129 |     94.706004 | Tracy A. Heath                                                                                                                                                        |
| 741 |    343.330422 |    251.246392 | Chris huh                                                                                                                                                             |
| 742 |    302.409917 |    116.840388 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 743 |    698.509799 |    447.034474 | Sarah Werning                                                                                                                                                         |
| 744 |    528.901474 |    607.904140 | Andy Wilson                                                                                                                                                           |
| 745 |    123.363611 |    180.854269 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 746 |    675.396877 |     48.433974 | Steven Traver                                                                                                                                                         |
| 747 |    187.933584 |    634.772392 | NA                                                                                                                                                                    |
| 748 |    511.020638 |    685.715868 | NA                                                                                                                                                                    |
| 749 |     87.852913 |    303.203353 | Fernando Carezzano                                                                                                                                                    |
| 750 |    805.242737 |     89.470672 | Zimices                                                                                                                                                               |
| 751 |    795.669130 |    768.464809 | Andy Wilson                                                                                                                                                           |
| 752 |    815.168713 |    622.488250 | Kai R. Caspar                                                                                                                                                         |
| 753 |     42.055692 |    670.497801 | Melissa Broussard                                                                                                                                                     |
| 754 |    348.543940 |    456.381190 | FJDegrange                                                                                                                                                            |
| 755 |    921.766911 |    109.400306 | Matthew Hooge (vectorized by T. Michael Keesey)                                                                                                                       |
| 756 |    631.469345 |    680.662657 | Matt Crook                                                                                                                                                            |
| 757 |    166.240349 |    560.270254 | Zimices                                                                                                                                                               |
| 758 |    215.671547 |    433.378604 | Zimices                                                                                                                                                               |
| 759 |    142.432192 |    251.957217 | T. Michael Keesey                                                                                                                                                     |
| 760 |    595.756520 |    112.829064 | Collin Gross                                                                                                                                                          |
| 761 |    476.717983 |    109.197765 | Myriam\_Ramirez                                                                                                                                                       |
| 762 |    717.471998 |    769.639173 | Carlos Cano-Barbacil                                                                                                                                                  |
| 763 |    537.728114 |    511.889679 | Jaime Headden, modified by T. Michael Keesey                                                                                                                          |
| 764 |   1008.976867 |    105.723992 | Tauana J. Cunha                                                                                                                                                       |
| 765 |    741.596644 |    752.129373 | Estelle Bourdon                                                                                                                                                       |
| 766 |    675.805950 |     40.795110 | Scott Hartman                                                                                                                                                         |
| 767 |    244.680970 |    738.507537 | Margot Michaud                                                                                                                                                        |
| 768 |    525.958172 |    791.264364 | Lukasiniho                                                                                                                                                            |
| 769 |    192.173383 |    707.639216 | Michele Tobias                                                                                                                                                        |
| 770 |    873.083886 |    340.135845 | Michelle Site                                                                                                                                                         |
| 771 |    574.487051 |    294.188322 | Andy Wilson                                                                                                                                                           |
| 772 |    747.103321 |     68.911603 | Michael Scroggie                                                                                                                                                      |
| 773 |    674.416607 |    312.241326 | Gareth Monger                                                                                                                                                         |
| 774 |    933.198689 |    138.740234 | Andrew A. Farke, modified from original by H. Milne Edwards                                                                                                           |
| 775 |    257.302587 |    434.457799 | Andy Wilson                                                                                                                                                           |
| 776 |    760.257982 |    263.898207 | Michelle Site                                                                                                                                                         |
| 777 |    739.991065 |    229.404884 | Joanna Wolfe                                                                                                                                                          |
| 778 |    586.377872 |    332.120599 | Zimices                                                                                                                                                               |
| 779 |    675.501135 |    342.091099 | Jagged Fang Designs                                                                                                                                                   |
| 780 |    350.301037 |    277.781984 | Margot Michaud                                                                                                                                                        |
| 781 |    895.935118 |    101.945589 | Skye McDavid                                                                                                                                                          |
| 782 |   1015.243638 |    118.946978 | Steven Traver                                                                                                                                                         |
| 783 |    312.997938 |    453.581540 | Kamil S. Jaron                                                                                                                                                        |
| 784 |   1014.934322 |     86.617000 | C. Camilo Julián-Caballero                                                                                                                                            |
| 785 |    249.591478 |    153.128680 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                         |
| 786 |    966.692582 |    510.718660 | Steven Traver                                                                                                                                                         |
| 787 |    372.040481 |    460.949842 | Zimices                                                                                                                                                               |
| 788 |    515.565360 |    335.499113 | Amanda Katzer                                                                                                                                                         |
| 789 |    218.320759 |    420.002526 | Becky Barnes                                                                                                                                                          |
| 790 |    543.013209 |    616.975401 | Kai R. Caspar                                                                                                                                                         |
| 791 |    263.631303 |    644.884906 | Michael “FunkMonk” B. H. (vectorized by T. Michael Keesey)                                                                                                            |
| 792 |    879.473758 |    598.216443 | Scott Hartman                                                                                                                                                         |
| 793 |    640.299801 |    197.648807 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 794 |    323.829707 |    435.200571 | Steven Traver                                                                                                                                                         |
| 795 |    941.759968 |    424.003802 | Carlos Cano-Barbacil                                                                                                                                                  |
| 796 |    287.422499 |    141.499724 | NA                                                                                                                                                                    |
| 797 |    542.382749 |    321.738066 | FunkMonk                                                                                                                                                              |
| 798 |      7.933405 |    323.378985 | Dmitry Bogdanov                                                                                                                                                       |
| 799 |    124.905263 |    795.601549 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 800 |    347.313876 |    612.094673 | Steven Traver                                                                                                                                                         |
| 801 |    654.119906 |    769.124797 | Matt Crook                                                                                                                                                            |
| 802 |    411.885488 |    783.033837 | NA                                                                                                                                                                    |
| 803 |    289.017757 |    639.099141 | Zimices                                                                                                                                                               |
| 804 |    616.476060 |     72.408458 | FunkMonk                                                                                                                                                              |
| 805 |    323.245646 |    741.691453 | Ferran Sayol                                                                                                                                                          |
| 806 |    243.807429 |    203.376562 | Zimices                                                                                                                                                               |
| 807 |    884.311626 |     38.607493 | Kamil S. Jaron                                                                                                                                                        |
| 808 |    523.321021 |    475.324575 | Mali’o Kodis, photograph by John Slapcinsky                                                                                                                           |
| 809 |    640.631059 |    659.230373 | Tasman Dixon                                                                                                                                                          |
| 810 |    177.626982 |    500.642172 | Scott Reid                                                                                                                                                            |
| 811 |     50.248061 |    307.353600 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 812 |    946.218411 |      6.616586 | Margot Michaud                                                                                                                                                        |
| 813 |    818.229645 |    409.100371 | Jaime Headden                                                                                                                                                         |
| 814 |    891.935940 |    510.590616 | Matt Martyniuk                                                                                                                                                        |
| 815 |    732.763550 |    384.505267 | FJDegrange                                                                                                                                                            |
| 816 |    943.795945 |    728.791692 | Y. de Hoev. (vectorized by T. Michael Keesey)                                                                                                                         |
| 817 |    478.910298 |    712.377718 | Zimices                                                                                                                                                               |
| 818 |    455.877710 |    387.234525 | (after Spotila 2004)                                                                                                                                                  |
| 819 |     24.150274 |    798.418380 | NA                                                                                                                                                                    |
| 820 |    974.878447 |    520.091208 | Jagged Fang Designs                                                                                                                                                   |
| 821 |    143.420503 |    236.658349 | SecretJellyMan - from Mason McNair                                                                                                                                    |
| 822 |    917.002193 |    783.551546 | Markus A. Grohme                                                                                                                                                      |
| 823 |    843.033821 |    500.491200 | Zimices                                                                                                                                                               |
| 824 |    675.612542 |    196.370817 | Scott Hartman                                                                                                                                                         |
| 825 |    521.803253 |    379.098746 | Chris huh                                                                                                                                                             |
| 826 |    604.642570 |    221.332705 | Mike Keesey (vectorization) and Vaibhavcho (photography)                                                                                                              |
| 827 |    391.947898 |    686.668050 | Tasman Dixon                                                                                                                                                          |
| 828 |    667.577717 |      3.967363 | NA                                                                                                                                                                    |
| 829 |    640.801547 |     68.495772 | Pete Buchholz                                                                                                                                                         |
| 830 |    492.380528 |    764.956446 | Smokeybjb                                                                                                                                                             |
| 831 |    393.754270 |    574.464828 | Brian Swartz (vectorized by T. Michael Keesey)                                                                                                                        |
| 832 |   1004.682436 |    509.378327 | NA                                                                                                                                                                    |
| 833 |    145.247431 |     45.100029 | Zimices                                                                                                                                                               |
| 834 |    502.492277 |    333.944433 | Original scheme by ‘Haplochromis’, vectorized by Roberto Díaz Sibaja                                                                                                  |
| 835 |    304.186258 |    746.485427 | Katie S. Collins                                                                                                                                                      |
| 836 |    478.324676 |    651.378941 | Michael Scroggie, from original photograph by Gary M. Stolz, USFWS (original photograph in public domain).                                                            |
| 837 |    319.911017 |    280.079731 | Julio Garza                                                                                                                                                           |
| 838 |    827.063242 |    505.668830 | E. Lear, 1819 (vectorization by Yan Wong)                                                                                                                             |
| 839 |    591.508690 |     40.500120 | Charles Doolittle Walcott (vectorized by T. Michael Keesey)                                                                                                           |
| 840 |    618.649745 |    262.439253 | Scott Hartman                                                                                                                                                         |
| 841 |    603.004590 |    762.892366 | Juan Carlos Jerí                                                                                                                                                      |
| 842 |    361.025542 |    370.688168 | Kamil S. Jaron                                                                                                                                                        |
| 843 |    940.358691 |    790.468619 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 844 |    415.834708 |    612.620673 | NA                                                                                                                                                                    |
| 845 |    859.813582 |    355.326469 | Mali’o Kodis, photograph property of National Museums of Northern Ireland                                                                                             |
| 846 |    496.990452 |    159.051288 | Gareth Monger                                                                                                                                                         |
| 847 |    585.969546 |    316.708713 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
| 848 |    464.010264 |    457.038433 | Margot Michaud                                                                                                                                                        |
| 849 |    854.577988 |    594.586490 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 850 |    237.293706 |    674.063208 | Chris A. Hamilton                                                                                                                                                     |
| 851 |    487.309586 |    533.907702 | Mihai Dragos (vectorized by T. Michael Keesey)                                                                                                                        |
| 852 |    323.774083 |     78.349727 | Ieuan Jones                                                                                                                                                           |
| 853 |    948.613356 |    500.444331 | Iain Reid                                                                                                                                                             |
| 854 |    512.003538 |      7.457837 | Zimices                                                                                                                                                               |
| 855 |   1000.040365 |     85.717480 | Smokeybjb (modified by Mike Keesey)                                                                                                                                   |
| 856 |    842.766387 |    459.590526 | Jagged Fang Designs                                                                                                                                                   |
| 857 |    221.784294 |     50.718518 | Mathieu Basille                                                                                                                                                       |
| 858 |    258.908675 |    496.228960 | Kamil S. Jaron                                                                                                                                                        |
| 859 |    303.331075 |    102.768944 | NA                                                                                                                                                                    |
| 860 |    596.100473 |     26.647985 | Steven Traver                                                                                                                                                         |
| 861 |    153.349731 |    524.488166 | T. Michael Keesey (vectorization) and Nadiatalent (photography)                                                                                                       |
| 862 |   1014.380117 |    681.166915 | Patrick Fisher (vectorized by T. Michael Keesey)                                                                                                                      |
| 863 |    968.323202 |    649.955036 | Christoph Schomburg                                                                                                                                                   |
| 864 |    865.309862 |    751.993591 | Ferran Sayol                                                                                                                                                          |
| 865 |    238.741940 |    693.758106 | Michelle Site                                                                                                                                                         |
| 866 |    395.013029 |    610.168546 | Tauana J. Cunha                                                                                                                                                       |
| 867 |    770.780623 |    607.145787 | Ferran Sayol                                                                                                                                                          |
| 868 |    118.136812 |      6.042541 | Nobu Tamura, modified by Andrew A. Farke                                                                                                                              |
| 869 |     55.393618 |    117.577067 | Ferran Sayol                                                                                                                                                          |
| 870 |     67.940486 |    431.579603 | Sherman Foote Denton (illustration, 1897) and Timothy J. Bartley (silhouette)                                                                                         |
| 871 |    196.162435 |    153.008211 | Xavier Giroux-Bougard                                                                                                                                                 |
| 872 |    316.399119 |    584.068501 | T. Michael Keesey                                                                                                                                                     |
| 873 |    871.310271 |    187.569188 | Gareth Monger                                                                                                                                                         |
| 874 |    655.781911 |    554.471370 | T. Michael Keesey (after Tillyard)                                                                                                                                    |
| 875 |    371.094717 |     47.220656 | Louis Ranjard                                                                                                                                                         |
| 876 |    333.923550 |    368.739311 | Stemonitis (photography) and T. Michael Keesey (vectorization)                                                                                                        |
| 877 |    318.441047 |    275.282710 | Michelle Site                                                                                                                                                         |
| 878 |    407.654178 |    374.659294 | Matt Crook                                                                                                                                                            |
| 879 |    849.879621 |    263.779714 | C. Camilo Julián-Caballero                                                                                                                                            |
| 880 |    981.594018 |    262.936273 | Melissa Broussard                                                                                                                                                     |
| 881 |     71.267313 |     95.202070 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
| 882 |     71.822091 |    192.131579 | Zimices                                                                                                                                                               |
| 883 |    459.283227 |    636.614933 | Smokeybjb                                                                                                                                                             |
| 884 |    165.689471 |    634.107222 | Chloé Schmidt                                                                                                                                                         |
| 885 |    618.550111 |     95.382251 | Dmitry Bogdanov                                                                                                                                                       |
| 886 |    754.066926 |    478.688432 | NA                                                                                                                                                                    |
| 887 |    889.622160 |    789.451211 | NA                                                                                                                                                                    |
| 888 |    336.766896 |    794.845484 | Zimices                                                                                                                                                               |
| 889 |    530.661305 |    755.142615 | T. Michael Keesey                                                                                                                                                     |
| 890 |    651.372593 |     85.693427 | Kamil S. Jaron                                                                                                                                                        |
| 891 |    786.749690 |    490.193435 | Tauana J. Cunha                                                                                                                                                       |
| 892 |    378.292697 |    240.503898 | Ferran Sayol                                                                                                                                                          |
| 893 |    691.531281 |     76.513685 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
| 894 |    318.880510 |     91.897123 | Maha Ghazal                                                                                                                                                           |
| 895 |    211.715400 |    249.567456 | Gareth Monger                                                                                                                                                         |
| 896 |    431.809067 |    448.430567 | Scott Hartman                                                                                                                                                         |
| 897 |    225.769195 |    709.686635 | Margot Michaud                                                                                                                                                        |
| 898 |    819.301182 |    633.594492 | Gareth Monger                                                                                                                                                         |
| 899 |    397.545199 |    506.815165 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 900 |    978.266734 |      3.047521 | Scott Hartman                                                                                                                                                         |
| 901 |    829.914886 |    308.295634 | Chris huh                                                                                                                                                             |
| 902 |   1014.996991 |    576.998104 | Mali’o Kodis, image from Higgins and Kristensen, 1986                                                                                                                 |
| 903 |    730.155575 |    262.245555 | Gareth Monger                                                                                                                                                         |
| 904 |    940.337701 |    687.860145 | Lukasiniho                                                                                                                                                            |
| 905 |    627.109952 |    418.763427 | Dean Schnabel                                                                                                                                                         |
| 906 |    475.213192 |    789.486587 | Kamil S. Jaron                                                                                                                                                        |
| 907 |    229.273761 |    723.326695 | Zimices                                                                                                                                                               |
| 908 |    846.409329 |     16.579094 | xgirouxb                                                                                                                                                              |
| 909 |    267.324490 |    344.524229 | Yan Wong                                                                                                                                                              |
| 910 |     61.735784 |    169.156347 | Gareth Monger                                                                                                                                                         |
| 911 |    163.382311 |    718.049075 | Neil Kelley                                                                                                                                                           |
| 912 |    257.821903 |    339.463275 | Chris Hay                                                                                                                                                             |
| 913 |    816.079368 |    725.625919 | Matt Martyniuk                                                                                                                                                        |
| 914 |    148.878533 |    793.467115 | Michelle Site                                                                                                                                                         |
| 915 |    995.582262 |    278.897155 | Noah Schlottman, photo from Casey Dunn                                                                                                                                |
| 916 |    270.199291 |    359.677932 | Tasman Dixon                                                                                                                                                          |
| 917 |      9.895821 |    136.100284 | Christoph Schomburg                                                                                                                                                   |
| 918 |    801.724117 |    147.794830 | Margot Michaud                                                                                                                                                        |
| 919 |     93.334941 |     42.114868 | Michael Scroggie                                                                                                                                                      |

    #> Your tweet has been posted!
