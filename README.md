
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

Margot Michaud, Tony Ayling (vectorized by T. Michael Keesey), Jaime
Headden, T. Michael Keesey, Jake Warner, Mathew Wedel, Andy Wilson,
Mattia Menchetti, Erika Schumacher, Robert Hering, Juan Carlos Jerí,
Pete Buchholz, Zimices, Kanako Bessho-Uehara, Matt Crook, Felix Vaux,
Darren Naish (vectorize by T. Michael Keesey), Markus A. Grohme, Emily
Willoughby, Rebecca Groom, Jagged Fang Designs, Steven Traver, Dmitry
Bogdanov (vectorized by T. Michael Keesey), Nobu Tamura (vectorized by
T. Michael Keesey), Jack Mayer Wood, Almandine (vectorized by T. Michael
Keesey), Katie S. Collins, FJDegrange, Chris huh, Ingo Braasch,
Christoph Schomburg, Michelle Site, Josefine Bohr Brask, Caleb M. Brown,
Myriam\_Ramirez, Rene Martin, Nobu Tamura, vectorized by Zimices,
Gabriela Palomo-Munoz, Michael Ströck (vectorized by T. Michael Keesey),
Kamil S. Jaron, Ignacio Contreras, Scott Hartman, Steven Coombs, Tony
Ayling, Javiera Constanzo, Tasman Dixon, White Wolf, Falconaumanni and
T. Michael Keesey, Gareth Monger, Conty (vectorized by T. Michael
Keesey), Verisimilus, Dexter R. Mardis, Xavier A. Jenkins, Gabriel
Ugueto, Stanton F. Fink, vectorized by Zimices, Birgit Lang, Robbie N.
Cada (modified by T. Michael Keesey), Anthony Caravaggi, C. Camilo
Julián-Caballero, Sergio A. Muñoz-Gómez, Michael P. Taylor, Sharon
Wegner-Larsen, Allison Pease, Ghedoghedo (vectorized by T. Michael
Keesey), Michael Scroggie, David Tana, Diego Fontaneto, Elisabeth A.
Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia
Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey),
SecretJellyMan, Iain Reid, Robbie N. Cada (vectorized by T. Michael
Keesey), T. Michael Keesey (after Tillyard), Cesar Julian, Noah
Schlottman, photo by Museum of Geology, University of Tartu, Ferran
Sayol, Robert Bruce Horsfall (vectorized by T. Michael Keesey), Yan Wong
(vectorization) from 1873 illustration, Matt Martyniuk, Marie Russell,
Matt Martyniuk (modified by T. Michael Keesey), Adam Stuart Smith
(vectorized by T. Michael Keesey), Aviceda (photo) & T. Michael Keesey,
Sam Droege (photo) and T. Michael Keesey (vectorization), Mariana Ruiz
Villarreal (modified by T. Michael Keesey), Lukasiniho, T. Michael
Keesey (after Mauricio Antón), CNZdenek, Jaime A. Headden (vectorized by
T. Michael Keesey), M Kolmann, Jessica Anne Miller, Paul Baker (photo),
John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G.
Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Jaime
Headden (vectorized by T. Michael Keesey), Skye McDavid, Maija Karala,
Arthur S. Brum, Alexandre Vong, Catherine Yasuda, Tyler Greenfield,
Jiekun He, Renato Santos, Kanchi Nanjo, Andrew R. Gehrke, Jaime Headden,
modified by T. Michael Keesey, Alyssa Bell & Luis Chiappe 2015,
dx.doi.org/10.1371/journal.pone.0141690, Dave Souza (vectorized by T.
Michael Keesey), Beth Reinke, Manabu Sakamoto, Martin Kevil, Sean
McCann, Yan Wong from photo by Gyik Toma, Darren Naish (vectorized by T.
Michael Keesey), Armin Reindl, Tauana J. Cunha, Unknown (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, G. M. Woodward,
Carlos Cano-Barbacil, T. Michael Keesey (vectorization) and Nadiatalent
(photography), T. Michael Keesey (after MPF), Matthias Buschmann
(vectorized by T. Michael Keesey), Kent Elson Sorgon, Crystal Maier,
Haplochromis (vectorized by T. Michael Keesey), M. A. Broussard, Matt
Wilkins, Tyler Greenfield and Dean Schnabel, Sarah Alewijnse, Heinrich
Harder (vectorized by William Gearty), Neil Kelley, L. Shyamal,
S.Martini, Christine Axon, FunkMonk, Collin Gross, Nobu Tamura, Kai R.
Caspar, Kailah Thorn & Mark Hutchinson, Greg Schechter (original photo),
Renato Santos (vector silhouette), Noah Schlottman, Becky Barnes,
Liftarn, Lafage, Mark Hofstetter (vectorized by T. Michael Keesey),
Peileppe, Mathieu Pélissié, Smokeybjb (vectorized by T. Michael Keesey),
Alex Slavenko, Estelle Bourdon, Andrew A. Farke, Gopal Murali, Jon Hill,
T. Michael Keesey (vectorization); Thorsten Assmann, Jörn Buse, Claudia
Drees, Ariel-Leib-Leonid Friedman, Tal Levanony, Andrea Matern, Anika
Timm, and David W. Wrase (photography), Kimberly Haddrell, Matthew Hooge
(vectorized by T. Michael Keesey), Scott Reid, Isaure Scavezzoni, Dean
Schnabel, Cagri Cevrim, Filip em, John Conway, Xavier Giroux-Bougard,
Kailah Thorn & Ben King, Alan Manson (photo), John E. McCormack, Michael
G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn,
Robb T. Brumfield & T. Michael Keesey, Martin R. Smith, Walter Vladimir,
Maxwell Lefroy (vectorized by T. Michael Keesey), Mathilde Cordellier,
Tyler Greenfield and Scott Hartman, Chris A. Hamilton, Scott Hartman
(modified by T. Michael Keesey), Martin R. Smith, from photo by Jürgen
Schoner, Mali’o Kodis, photograph by G. Giribet, Siobhon Egan, Joanna
Wolfe, Nobu Tamura (modified by T. Michael Keesey), ДиБгд (vectorized by
T. Michael Keesey), Nobu Tamura, modified by Andrew A. Farke, Alexander
Schmidt-Lebuhn, Smokeybjb, Apokryltaros (vectorized by T. Michael
Keesey), Vijay Cavale (photo), John E. McCormack, Michael G. Harvey,
Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T.
Brumfield & T. Michael Keesey, Geoff Shaw, Ewald Rübsamen, Farelli
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Mercedes Yrayzoz (vectorized by T. Michael Keesey)

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                               |
| --: | ------------: | ------------: | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |     462.05475 |    575.057438 | Margot Michaud                                                                                                                                                                       |
|   2 |     286.99798 |    683.254029 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                                        |
|   3 |     124.28331 |    352.208167 | Jaime Headden                                                                                                                                                                        |
|   4 |     913.32558 |    316.017844 | T. Michael Keesey                                                                                                                                                                    |
|   5 |      72.74463 |    153.833451 | Jake Warner                                                                                                                                                                          |
|   6 |     928.70693 |    679.708609 | Mathew Wedel                                                                                                                                                                         |
|   7 |     492.64875 |    306.475699 | T. Michael Keesey                                                                                                                                                                    |
|   8 |     690.80049 |    282.767488 | Andy Wilson                                                                                                                                                                          |
|   9 |     876.33601 |    110.890401 | Mattia Menchetti                                                                                                                                                                     |
|  10 |     443.22062 |    747.821050 | Erika Schumacher                                                                                                                                                                     |
|  11 |     828.58590 |    463.137633 | Margot Michaud                                                                                                                                                                       |
|  12 |     798.98540 |    238.048957 | Robert Hering                                                                                                                                                                        |
|  13 |     639.10000 |    113.737794 | Margot Michaud                                                                                                                                                                       |
|  14 |     807.98992 |    716.330611 | Juan Carlos Jerí                                                                                                                                                                     |
|  15 |     231.08247 |    510.086482 | Pete Buchholz                                                                                                                                                                        |
|  16 |     250.60431 |    445.269638 | Zimices                                                                                                                                                                              |
|  17 |     563.51264 |    657.117596 | Kanako Bessho-Uehara                                                                                                                                                                 |
|  18 |     203.05978 |    230.101117 | Margot Michaud                                                                                                                                                                       |
|  19 |      70.57565 |    592.633517 | Zimices                                                                                                                                                                              |
|  20 |     272.53524 |    307.662795 | Matt Crook                                                                                                                                                                           |
|  21 |     689.73971 |    584.976007 | Felix Vaux                                                                                                                                                                           |
|  22 |      67.14227 |    263.146358 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                                        |
|  23 |     316.83325 |     68.712606 | Markus A. Grohme                                                                                                                                                                     |
|  24 |     117.40191 |    473.616087 | Zimices                                                                                                                                                                              |
|  25 |     435.53394 |     29.769731 | Emily Willoughby                                                                                                                                                                     |
|  26 |     229.67323 |    155.276673 | Rebecca Groom                                                                                                                                                                        |
|  27 |     807.65307 |    614.753348 | Matt Crook                                                                                                                                                                           |
|  28 |     171.15474 |    749.651038 | Jagged Fang Designs                                                                                                                                                                  |
|  29 |     176.45030 |     47.097578 | Steven Traver                                                                                                                                                                        |
|  30 |     565.11552 |    441.568238 | Andy Wilson                                                                                                                                                                          |
|  31 |     162.37186 |    562.352149 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
|  32 |     670.88098 |    495.760879 | T. Michael Keesey                                                                                                                                                                    |
|  33 |     924.38068 |    541.487729 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
|  34 |     922.47014 |    448.492166 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
|  35 |     955.30260 |    641.652898 | Jack Mayer Wood                                                                                                                                                                      |
|  36 |      66.86667 |    677.083738 | Almandine (vectorized by T. Michael Keesey)                                                                                                                                          |
|  37 |     520.16631 |    124.784146 | Katie S. Collins                                                                                                                                                                     |
|  38 |     327.69989 |    567.097725 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
|  39 |     802.40016 |    378.870856 | FJDegrange                                                                                                                                                                           |
|  40 |     414.35370 |     92.471286 | Chris huh                                                                                                                                                                            |
|  41 |     675.04677 |    768.433011 | Zimices                                                                                                                                                                              |
|  42 |     330.87853 |    737.789222 | Matt Crook                                                                                                                                                                           |
|  43 |     483.89501 |    518.019269 | Ingo Braasch                                                                                                                                                                         |
|  44 |      16.50090 |    464.355678 | T. Michael Keesey                                                                                                                                                                    |
|  45 |     951.71642 |    749.511079 | Margot Michaud                                                                                                                                                                       |
|  46 |     400.75747 |    630.010829 | Christoph Schomburg                                                                                                                                                                  |
|  47 |     980.20277 |    271.678988 | Michelle Site                                                                                                                                                                        |
|  48 |     584.54629 |    182.125648 | Josefine Bohr Brask                                                                                                                                                                  |
|  49 |     866.24826 |    200.584092 | T. Michael Keesey                                                                                                                                                                    |
|  50 |     137.40299 |    417.784978 | Caleb M. Brown                                                                                                                                                                       |
|  51 |     250.66700 |    203.904892 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
|  52 |     748.09613 |    134.482901 | Myriam\_Ramirez                                                                                                                                                                      |
|  53 |     639.70520 |     45.665315 | Rene Martin                                                                                                                                                                          |
|  54 |     714.61574 |     18.217799 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
|  55 |     700.95989 |    681.410489 | Gabriela Palomo-Munoz                                                                                                                                                                |
|  56 |     205.80938 |    704.396636 | Michael Ströck (vectorized by T. Michael Keesey)                                                                                                                                     |
|  57 |     543.73339 |    768.626842 | Kamil S. Jaron                                                                                                                                                                       |
|  58 |     191.47188 |    642.064941 | Ignacio Contreras                                                                                                                                                                    |
|  59 |     853.58108 |    521.315099 | Scott Hartman                                                                                                                                                                        |
|  60 |     746.53259 |    407.267763 | Markus A. Grohme                                                                                                                                                                     |
|  61 |     504.46862 |     65.890651 | Steven Coombs                                                                                                                                                                        |
|  62 |     770.06858 |    556.480720 | Tony Ayling                                                                                                                                                                          |
|  63 |     561.39470 |    514.486506 | T. Michael Keesey                                                                                                                                                                    |
|  64 |     888.24049 |    602.214583 | Felix Vaux                                                                                                                                                                           |
|  65 |     687.44978 |    427.284871 | Javiera Constanzo                                                                                                                                                                    |
|  66 |     193.09978 |    289.415294 | Zimices                                                                                                                                                                              |
|  67 |      64.87598 |    398.761712 | Tasman Dixon                                                                                                                                                                         |
|  68 |     377.19055 |    522.362431 | White Wolf                                                                                                                                                                           |
|  69 |     543.26864 |     35.184732 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
|  70 |      96.78351 |    731.131037 | Falconaumanni and T. Michael Keesey                                                                                                                                                  |
|  71 |     573.39784 |    237.106876 | Zimices                                                                                                                                                                              |
|  72 |     307.03291 |     30.607876 | Andy Wilson                                                                                                                                                                          |
|  73 |     196.50112 |    109.951557 | Gareth Monger                                                                                                                                                                        |
|  74 |     177.93812 |    608.217115 | Conty (vectorized by T. Michael Keesey)                                                                                                                                              |
|  75 |     931.12830 |    499.988784 | Verisimilus                                                                                                                                                                          |
|  76 |     248.41769 |    615.689162 | Dexter R. Mardis                                                                                                                                                                     |
|  77 |     170.11633 |    781.635784 | Gabriela Palomo-Munoz                                                                                                                                                                |
|  78 |     150.96365 |    173.037798 | Xavier A. Jenkins, Gabriel Ugueto                                                                                                                                                    |
|  79 |     431.58582 |    623.826217 | Stanton F. Fink, vectorized by Zimices                                                                                                                                               |
|  80 |     325.04777 |    431.948753 | Birgit Lang                                                                                                                                                                          |
|  81 |     320.94230 |    492.727914 | Jagged Fang Designs                                                                                                                                                                  |
|  82 |     642.66588 |    570.660995 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                                                       |
|  83 |     323.22786 |    376.972546 | Anthony Caravaggi                                                                                                                                                                    |
|  84 |     700.37362 |    640.841961 | C. Camilo Julián-Caballero                                                                                                                                                           |
|  85 |     782.80592 |    761.319144 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
|  86 |    1001.92574 |    545.265523 | Sergio A. Muñoz-Gómez                                                                                                                                                                |
|  87 |     335.49754 |    272.096694 | Matt Crook                                                                                                                                                                           |
|  88 |     308.46354 |    129.382293 | Gareth Monger                                                                                                                                                                        |
|  89 |     857.94970 |    761.017016 | Michael P. Taylor                                                                                                                                                                    |
|  90 |      34.43685 |     21.495430 | Zimices                                                                                                                                                                              |
|  91 |     546.10283 |    380.304157 | Sharon Wegner-Larsen                                                                                                                                                                 |
|  92 |     908.86619 |     13.143505 | Allison Pease                                                                                                                                                                        |
|  93 |     811.88916 |     11.376680 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                                         |
|  94 |     993.26433 |     49.961336 | Michael Scroggie                                                                                                                                                                     |
|  95 |     945.67983 |    237.981754 | Andy Wilson                                                                                                                                                                          |
|  96 |     992.70389 |    137.021028 | Gabriela Palomo-Munoz                                                                                                                                                                |
|  97 |      84.69920 |    433.604458 | David Tana                                                                                                                                                                           |
|  98 |     707.16540 |    488.526119 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey)                |
|  99 |     423.40709 |    688.619604 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                                        |
| 100 |      85.06095 |     31.279839 | SecretJellyMan                                                                                                                                                                       |
| 101 |     361.15140 |    682.786092 | Matt Crook                                                                                                                                                                           |
| 102 |     173.50537 |    670.763528 | Iain Reid                                                                                                                                                                            |
| 103 |     807.72000 |    668.086043 | Zimices                                                                                                                                                                              |
| 104 |      31.68630 |    171.703786 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 105 |     508.74270 |    473.240814 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                                     |
| 106 |     588.04681 |     15.676046 | Ignacio Contreras                                                                                                                                                                    |
| 107 |     268.84132 |     90.373275 | Michael Scroggie                                                                                                                                                                     |
| 108 |     492.61232 |    711.166947 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 109 |     262.95632 |    173.969572 | Zimices                                                                                                                                                                              |
| 110 |     863.31740 |    229.345837 | Gareth Monger                                                                                                                                                                        |
| 111 |     147.85017 |    714.845627 | Erika Schumacher                                                                                                                                                                     |
| 112 |     971.39238 |    113.257927 | T. Michael Keesey (after Tillyard)                                                                                                                                                   |
| 113 |     873.54901 |    178.057760 | Cesar Julian                                                                                                                                                                         |
| 114 |     672.08832 |    154.628316 | Noah Schlottman, photo by Museum of Geology, University of Tartu                                                                                                                     |
| 115 |     622.06703 |    514.353389 | Ferran Sayol                                                                                                                                                                         |
| 116 |     705.82661 |    133.543788 | Robert Bruce Horsfall (vectorized by T. Michael Keesey)                                                                                                                              |
| 117 |     326.76824 |    630.654463 | Steven Traver                                                                                                                                                                        |
| 118 |     876.90792 |    635.601996 | Yan Wong (vectorization) from 1873 illustration                                                                                                                                      |
| 119 |     996.63792 |    408.884763 | Matt Martyniuk                                                                                                                                                                       |
| 120 |     298.85727 |      7.397330 | Chris huh                                                                                                                                                                            |
| 121 |     117.79430 |    143.027926 | NA                                                                                                                                                                                   |
| 122 |     729.06714 |     73.978403 | Marie Russell                                                                                                                                                                        |
| 123 |      42.42380 |    744.291410 | Gareth Monger                                                                                                                                                                        |
| 124 |     802.39387 |    316.015466 | Gareth Monger                                                                                                                                                                        |
| 125 |     995.53725 |    587.825406 | Ferran Sayol                                                                                                                                                                         |
| 126 |     917.99769 |    577.717424 | Andy Wilson                                                                                                                                                                          |
| 127 |     353.25720 |    356.335297 | Rebecca Groom                                                                                                                                                                        |
| 128 |      42.21183 |     94.567261 | Steven Traver                                                                                                                                                                        |
| 129 |     558.40942 |    203.008465 | Zimices                                                                                                                                                                              |
| 130 |     621.01523 |    735.278930 | Matt Crook                                                                                                                                                                           |
| 131 |     628.05082 |    210.432469 | Matt Martyniuk (modified by T. Michael Keesey)                                                                                                                                       |
| 132 |     172.18914 |    523.245688 | Ingo Braasch                                                                                                                                                                         |
| 133 |     743.39169 |    626.416968 | Adam Stuart Smith (vectorized by T. Michael Keesey)                                                                                                                                  |
| 134 |      43.80300 |    482.539461 | Aviceda (photo) & T. Michael Keesey                                                                                                                                                  |
| 135 |     730.67996 |    446.244180 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 136 |     182.59523 |    320.266571 | Gareth Monger                                                                                                                                                                        |
| 137 |     975.78499 |    361.422480 | Sam Droege (photo) and T. Michael Keesey (vectorization)                                                                                                                             |
| 138 |     902.24242 |    758.871768 | Steven Traver                                                                                                                                                                        |
| 139 |    1012.23742 |    709.234817 | NA                                                                                                                                                                                   |
| 140 |      30.90873 |    314.882670 | Mariana Ruiz Villarreal (modified by T. Michael Keesey)                                                                                                                              |
| 141 |      46.63294 |    370.211334 | Lukasiniho                                                                                                                                                                           |
| 142 |      92.69484 |     70.957538 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 143 |     639.94109 |    409.997202 | NA                                                                                                                                                                                   |
| 144 |     371.97855 |    647.064360 | Chris huh                                                                                                                                                                            |
| 145 |     512.88757 |    185.731522 | T. Michael Keesey (after Mauricio Antón)                                                                                                                                             |
| 146 |     140.45173 |    519.180651 | Chris huh                                                                                                                                                                            |
| 147 |     902.56650 |    649.359556 | CNZdenek                                                                                                                                                                             |
| 148 |     671.66754 |    417.948573 | Jaime A. Headden (vectorized by T. Michael Keesey)                                                                                                                                   |
| 149 |     428.27660 |    782.440383 | Chris huh                                                                                                                                                                            |
| 150 |     834.01245 |    783.005890 | Jagged Fang Designs                                                                                                                                                                  |
| 151 |     140.04223 |    129.612485 | Pete Buchholz                                                                                                                                                                        |
| 152 |     771.16580 |    707.421341 | M Kolmann                                                                                                                                                                            |
| 153 |      76.60273 |    542.861075 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 154 |     299.55399 |    373.439563 | Jessica Anne Miller                                                                                                                                                                  |
| 155 |     656.25364 |    185.195968 | Ferran Sayol                                                                                                                                                                         |
| 156 |      22.71928 |    292.041697 | Jagged Fang Designs                                                                                                                                                                  |
| 157 |      95.92541 |    627.694298 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 158 |     877.23671 |    683.075505 | Paul Baker (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                           |
| 159 |     592.25535 |    588.932178 | Jaime Headden (vectorized by T. Michael Keesey)                                                                                                                                      |
| 160 |     603.96232 |     75.836891 | Skye McDavid                                                                                                                                                                         |
| 161 |     337.39255 |    191.687420 | Maija Karala                                                                                                                                                                         |
| 162 |     636.34851 |    619.459396 | Gareth Monger                                                                                                                                                                        |
| 163 |    1002.60494 |     95.960840 | Margot Michaud                                                                                                                                                                       |
| 164 |     232.24349 |    271.151552 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 165 |     252.49627 |    739.603108 | Matt Martyniuk                                                                                                                                                                       |
| 166 |     867.95251 |     39.908566 | Margot Michaud                                                                                                                                                                       |
| 167 |      94.27834 |    795.758233 | Arthur S. Brum                                                                                                                                                                       |
| 168 |     738.47261 |    750.974364 | Birgit Lang                                                                                                                                                                          |
| 169 |     756.94735 |    299.566619 | Alexandre Vong                                                                                                                                                                       |
| 170 |     385.00599 |     52.484657 | Scott Hartman                                                                                                                                                                        |
| 171 |     118.06989 |    776.864830 | Catherine Yasuda                                                                                                                                                                     |
| 172 |     228.89039 |    787.989454 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 173 |     779.93230 |    303.983527 | Matt Crook                                                                                                                                                                           |
| 174 |     384.24768 |    582.371440 | Caleb M. Brown                                                                                                                                                                       |
| 175 |     815.80392 |    623.634546 | NA                                                                                                                                                                                   |
| 176 |     740.13464 |    513.231596 | Andy Wilson                                                                                                                                                                          |
| 177 |     785.38543 |    354.313142 | Andy Wilson                                                                                                                                                                          |
| 178 |     304.03396 |    722.225905 | Tyler Greenfield                                                                                                                                                                     |
| 179 |     617.52512 |    140.338284 | NA                                                                                                                                                                                   |
| 180 |     201.57293 |    168.415840 | Jiekun He                                                                                                                                                                            |
| 181 |     855.91906 |    383.701884 | Gareth Monger                                                                                                                                                                        |
| 182 |     292.90646 |     47.193001 | Gareth Monger                                                                                                                                                                        |
| 183 |     111.48803 |     98.914518 | Renato Santos                                                                                                                                                                        |
| 184 |     249.56741 |    349.282232 | NA                                                                                                                                                                                   |
| 185 |     762.21259 |    594.822853 | Kanchi Nanjo                                                                                                                                                                         |
| 186 |      16.71725 |    609.485725 | Matt Crook                                                                                                                                                                           |
| 187 |     939.06603 |    564.116472 | Andrew R. Gehrke                                                                                                                                                                     |
| 188 |     463.19463 |    655.085387 | Mathew Wedel                                                                                                                                                                         |
| 189 |      73.79782 |     77.333487 | NA                                                                                                                                                                                   |
| 190 |      36.19605 |    771.905801 | Markus A. Grohme                                                                                                                                                                     |
| 191 |      42.67090 |    786.750117 | Ferran Sayol                                                                                                                                                                         |
| 192 |     171.54258 |    382.869670 | Margot Michaud                                                                                                                                                                       |
| 193 |     843.45081 |    504.470730 | Jagged Fang Designs                                                                                                                                                                  |
| 194 |     883.74754 |    789.227634 | Christoph Schomburg                                                                                                                                                                  |
| 195 |     639.73729 |     14.315319 | Maija Karala                                                                                                                                                                         |
| 196 |     461.47764 |     21.625876 | Ingo Braasch                                                                                                                                                                         |
| 197 |     861.07953 |    290.927603 | Jaime Headden, modified by T. Michael Keesey                                                                                                                                         |
| 198 |     528.76376 |    740.174889 | Alyssa Bell & Luis Chiappe 2015, dx.doi.org/10.1371/journal.pone.0141690                                                                                                             |
| 199 |     969.27703 |    613.295260 | Ingo Braasch                                                                                                                                                                         |
| 200 |     848.17235 |    743.894340 | Juan Carlos Jerí                                                                                                                                                                     |
| 201 |     813.63114 |    571.703513 | Dave Souza (vectorized by T. Michael Keesey)                                                                                                                                         |
| 202 |    1000.84314 |    614.514706 | Beth Reinke                                                                                                                                                                          |
| 203 |      85.07817 |    568.587867 | Scott Hartman                                                                                                                                                                        |
| 204 |     168.80624 |    492.351870 | NA                                                                                                                                                                                   |
| 205 |     191.42034 |    373.294429 | NA                                                                                                                                                                                   |
| 206 |     307.36218 |    658.680901 | Scott Hartman                                                                                                                                                                        |
| 207 |     757.79294 |    443.262653 | Manabu Sakamoto                                                                                                                                                                      |
| 208 |      17.64015 |     76.328151 | Martin Kevil                                                                                                                                                                         |
| 209 |     297.18025 |    181.391274 | Sean McCann                                                                                                                                                                          |
| 210 |      37.99781 |    204.866670 | Steven Traver                                                                                                                                                                        |
| 211 |    1007.70738 |    775.112176 | Matt Crook                                                                                                                                                                           |
| 212 |     972.05465 |    166.085452 | Yan Wong from photo by Gyik Toma                                                                                                                                                     |
| 213 |     265.40407 |    276.608108 | T. Michael Keesey                                                                                                                                                                    |
| 214 |     228.44368 |    577.426864 | Scott Hartman                                                                                                                                                                        |
| 215 |     521.39999 |    720.267456 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 216 |     358.37536 |    229.543449 | NA                                                                                                                                                                                   |
| 217 |      46.02272 |     55.224345 | Matt Crook                                                                                                                                                                           |
| 218 |     530.85342 |    411.998540 | Gareth Monger                                                                                                                                                                        |
| 219 |     878.16153 |    425.573210 | Manabu Sakamoto                                                                                                                                                                      |
| 220 |     986.37251 |    783.625587 | Andy Wilson                                                                                                                                                                          |
| 221 |     888.27123 |    713.489628 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                                       |
| 222 |     836.74193 |    621.310171 | Margot Michaud                                                                                                                                                                       |
| 223 |      35.09023 |    549.753598 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 224 |     844.47836 |    325.322570 | Margot Michaud                                                                                                                                                                       |
| 225 |     775.14480 |    177.843624 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 226 |     224.33265 |     94.539161 | Armin Reindl                                                                                                                                                                         |
| 227 |     632.61665 |    552.860790 | Chris huh                                                                                                                                                                            |
| 228 |     973.91664 |    549.507578 | Matt Crook                                                                                                                                                                           |
| 229 |     961.71427 |    339.922072 | Tauana J. Cunha                                                                                                                                                                      |
| 230 |     752.98261 |     56.138245 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                              |
| 231 |     558.57837 |    266.951892 | Zimices                                                                                                                                                                              |
| 232 |     705.07822 |    573.157472 | G. M. Woodward                                                                                                                                                                       |
| 233 |     310.84606 |    164.154473 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 234 |     255.68286 |    230.076212 | Margot Michaud                                                                                                                                                                       |
| 235 |     113.57012 |    206.257620 | T. Michael Keesey (vectorization) and Nadiatalent (photography)                                                                                                                      |
| 236 |    1005.46126 |    312.404198 | Jake Warner                                                                                                                                                                          |
| 237 |     329.46297 |    272.506290 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 238 |     993.14957 |    189.601152 | T. Michael Keesey (after MPF)                                                                                                                                                        |
| 239 |     299.64785 |    633.565098 | Matthias Buschmann (vectorized by T. Michael Keesey)                                                                                                                                 |
| 240 |     583.64218 |    725.328585 | Scott Hartman                                                                                                                                                                        |
| 241 |     878.19496 |     26.412565 | Beth Reinke                                                                                                                                                                          |
| 242 |     584.53826 |    477.211016 | NA                                                                                                                                                                                   |
| 243 |      43.09745 |    515.063926 | Scott Hartman                                                                                                                                                                        |
| 244 |     117.24304 |    321.389558 | Steven Traver                                                                                                                                                                        |
| 245 |      15.60803 |    101.498081 | Beth Reinke                                                                                                                                                                          |
| 246 |     355.89176 |    388.984149 | T. Michael Keesey                                                                                                                                                                    |
| 247 |     284.38679 |    327.250587 | Kent Elson Sorgon                                                                                                                                                                    |
| 248 |      81.13319 |    769.700688 | Crystal Maier                                                                                                                                                                        |
| 249 |     457.14281 |      8.267023 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                                       |
| 250 |     728.99075 |    730.408521 | Tasman Dixon                                                                                                                                                                         |
| 251 |     854.47298 |    644.041682 | NA                                                                                                                                                                                   |
| 252 |     763.47558 |    148.263026 | Matt Crook                                                                                                                                                                           |
| 253 |     224.86375 |    315.299310 | Felix Vaux                                                                                                                                                                           |
| 254 |     251.59915 |    765.746679 | M. A. Broussard                                                                                                                                                                      |
| 255 |     813.53705 |    283.368741 | Gareth Monger                                                                                                                                                                        |
| 256 |     518.39489 |    217.383820 | Matt Wilkins                                                                                                                                                                         |
| 257 |     763.82472 |    779.751491 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 258 |      20.80512 |    343.424873 | NA                                                                                                                                                                                   |
| 259 |     686.30752 |    734.239270 | Markus A. Grohme                                                                                                                                                                     |
| 260 |     720.02502 |     45.758611 | Zimices                                                                                                                                                                              |
| 261 |    1003.57941 |    669.710896 | Gareth Monger                                                                                                                                                                        |
| 262 |     871.32488 |    276.441874 | Margot Michaud                                                                                                                                                                       |
| 263 |      45.33509 |    329.465093 | Maija Karala                                                                                                                                                                         |
| 264 |    1008.46653 |    442.123668 | Matt Wilkins                                                                                                                                                                         |
| 265 |     980.23584 |    411.568242 | Gareth Monger                                                                                                                                                                        |
| 266 |     774.39219 |     51.017407 | Tyler Greenfield and Dean Schnabel                                                                                                                                                   |
| 267 |     711.39319 |    107.362319 | Ferran Sayol                                                                                                                                                                         |
| 268 |     280.23848 |    652.884205 | Scott Hartman                                                                                                                                                                        |
| 269 |     529.32918 |    201.585555 | Sarah Alewijnse                                                                                                                                                                      |
| 270 |     666.62524 |    605.337248 | Heinrich Harder (vectorized by William Gearty)                                                                                                                                       |
| 271 |     238.18758 |    404.875013 | Scott Hartman                                                                                                                                                                        |
| 272 |     524.69039 |    552.962739 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                                       |
| 273 |     202.81232 |    764.744651 | Neil Kelley                                                                                                                                                                          |
| 274 |     632.38788 |    459.785565 | L. Shyamal                                                                                                                                                                           |
| 275 |     568.10172 |    739.091211 | Chris huh                                                                                                                                                                            |
| 276 |    1007.89681 |    365.324662 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 277 |     136.85836 |    206.612989 | Ferran Sayol                                                                                                                                                                         |
| 278 |    1002.65788 |    683.888507 | S.Martini                                                                                                                                                                            |
| 279 |     782.98652 |    395.079091 | Neil Kelley                                                                                                                                                                          |
| 280 |     854.82515 |     27.492031 | Tasman Dixon                                                                                                                                                                         |
| 281 |     259.61860 |     48.545509 | Zimices                                                                                                                                                                              |
| 282 |     791.49157 |    779.240230 | Steven Traver                                                                                                                                                                        |
| 283 |     109.38750 |    172.699105 | NA                                                                                                                                                                                   |
| 284 |     844.55262 |    445.259038 | Markus A. Grohme                                                                                                                                                                     |
| 285 |     926.95155 |    384.609523 | Christine Axon                                                                                                                                                                       |
| 286 |     538.08699 |     17.596978 | Scott Hartman                                                                                                                                                                        |
| 287 |     602.46599 |    385.700510 | Zimices                                                                                                                                                                              |
| 288 |     874.76380 |    303.754918 | Tasman Dixon                                                                                                                                                                         |
| 289 |     365.69147 |    664.455871 | Zimices                                                                                                                                                                              |
| 290 |     669.25294 |    363.586410 | Falconaumanni and T. Michael Keesey                                                                                                                                                  |
| 291 |     739.61273 |     87.324205 | NA                                                                                                                                                                                   |
| 292 |     582.09688 |    105.836156 | Iain Reid                                                                                                                                                                            |
| 293 |      84.94239 |    317.734427 | FunkMonk                                                                                                                                                                             |
| 294 |     955.46307 |    314.515822 | Gareth Monger                                                                                                                                                                        |
| 295 |     697.56362 |    617.915424 | Birgit Lang                                                                                                                                                                          |
| 296 |     398.64375 |    777.114923 | Andy Wilson                                                                                                                                                                          |
| 297 |     357.07593 |     21.678522 | Collin Gross                                                                                                                                                                         |
| 298 |     651.03581 |    330.531278 | Jagged Fang Designs                                                                                                                                                                  |
| 299 |     539.48379 |    279.909345 | Nobu Tamura                                                                                                                                                                          |
| 300 |     287.93255 |    463.315611 | Lukasiniho                                                                                                                                                                           |
| 301 |      34.99083 |    293.542864 | Scott Hartman                                                                                                                                                                        |
| 302 |     353.25054 |    418.870819 | Collin Gross                                                                                                                                                                         |
| 303 |     821.42829 |    647.278867 | NA                                                                                                                                                                                   |
| 304 |      18.24377 |    274.767687 | Caleb M. Brown                                                                                                                                                                       |
| 305 |      43.42163 |    433.660260 | NA                                                                                                                                                                                   |
| 306 |     730.47989 |    204.502208 | Birgit Lang                                                                                                                                                                          |
| 307 |     984.57836 |    391.086163 | Manabu Sakamoto                                                                                                                                                                      |
| 308 |      77.58242 |    552.392815 | Nobu Tamura                                                                                                                                                                          |
| 309 |      61.71885 |    628.909014 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 310 |     286.49305 |     89.711251 | Kai R. Caspar                                                                                                                                                                        |
| 311 |     963.67677 |    588.480320 | Ferran Sayol                                                                                                                                                                         |
| 312 |     929.16568 |    781.527138 | Kailah Thorn & Mark Hutchinson                                                                                                                                                       |
| 313 |     187.35112 |    464.613803 | Greg Schechter (original photo), Renato Santos (vector silhouette)                                                                                                                   |
| 314 |     180.00772 |    156.452660 | Noah Schlottman                                                                                                                                                                      |
| 315 |     700.84114 |    377.442202 | Steven Traver                                                                                                                                                                        |
| 316 |     149.25163 |    242.128595 | NA                                                                                                                                                                                   |
| 317 |     716.18676 |    540.071262 | Becky Barnes                                                                                                                                                                         |
| 318 |    1005.71484 |    282.258596 | Liftarn                                                                                                                                                                              |
| 319 |     675.14733 |     60.552335 | NA                                                                                                                                                                                   |
| 320 |     976.21178 |    697.064355 | Emily Willoughby                                                                                                                                                                     |
| 321 |     302.21270 |    101.023216 | Kamil S. Jaron                                                                                                                                                                       |
| 322 |     116.23708 |    293.660845 | Lafage                                                                                                                                                                               |
| 323 |      76.76985 |    522.432443 | Gareth Monger                                                                                                                                                                        |
| 324 |     299.68280 |    530.736381 | Mathew Wedel                                                                                                                                                                         |
| 325 |     322.28082 |     89.183987 | Kent Elson Sorgon                                                                                                                                                                    |
| 326 |     138.33941 |    311.017556 | Mark Hofstetter (vectorized by T. Michael Keesey)                                                                                                                                    |
| 327 |     160.46206 |    322.410434 | Peileppe                                                                                                                                                                             |
| 328 |     758.88014 |    484.340800 | Mathieu Pélissié                                                                                                                                                                     |
| 329 |     643.11041 |    157.550546 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                                          |
| 330 |     314.19068 |    331.336409 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 331 |     505.60082 |    734.715512 | Margot Michaud                                                                                                                                                                       |
| 332 |     137.93724 |    632.704784 | Michelle Site                                                                                                                                                                        |
| 333 |     328.04237 |    538.655960 | Alex Slavenko                                                                                                                                                                        |
| 334 |    1002.36530 |    469.814669 | Kai R. Caspar                                                                                                                                                                        |
| 335 |     742.99456 |    222.363989 | Kamil S. Jaron                                                                                                                                                                       |
| 336 |     991.32384 |    337.867978 | Estelle Bourdon                                                                                                                                                                      |
| 337 |      39.99286 |    267.441394 | Chris huh                                                                                                                                                                            |
| 338 |     314.12781 |     36.490997 | Andrew A. Farke                                                                                                                                                                      |
| 339 |     372.43002 |    272.083907 | Andy Wilson                                                                                                                                                                          |
| 340 |     201.78775 |    517.020883 | Gopal Murali                                                                                                                                                                         |
| 341 |     467.75297 |    643.744418 | Conty (vectorized by T. Michael Keesey)                                                                                                                                              |
| 342 |     137.52508 |    373.558604 | Tasman Dixon                                                                                                                                                                         |
| 343 |     278.95123 |    550.871770 | Mattia Menchetti                                                                                                                                                                     |
| 344 |     623.28621 |    274.845448 | Jon Hill                                                                                                                                                                             |
| 345 |     474.42732 |    615.452814 | Mathew Wedel                                                                                                                                                                         |
| 346 |      54.98544 |    710.819468 | Scott Hartman                                                                                                                                                                        |
| 347 |     543.98484 |    466.602954 | Felix Vaux                                                                                                                                                                           |
| 348 |     140.65584 |    666.450916 | Gareth Monger                                                                                                                                                                        |
| 349 |     342.13667 |     98.185557 | Scott Hartman                                                                                                                                                                        |
| 350 |      51.80644 |    560.074373 | Zimices                                                                                                                                                                              |
| 351 |     648.50369 |    531.692624 | T. Michael Keesey (vectorization); Thorsten Assmann, Jörn Buse, Claudia Drees, Ariel-Leib-Leonid Friedman, Tal Levanony, Andrea Matern, Anika Timm, and David W. Wrase (photography) |
| 352 |     365.51677 |    783.464877 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 353 |     970.68658 |    578.998097 | Jagged Fang Designs                                                                                                                                                                  |
| 354 |     537.64149 |    292.590658 | Jagged Fang Designs                                                                                                                                                                  |
| 355 |     632.17361 |    479.056540 | Scott Hartman                                                                                                                                                                        |
| 356 |     399.20503 |    649.772355 | Kimberly Haddrell                                                                                                                                                                    |
| 357 |     464.65442 |    775.475968 | Birgit Lang                                                                                                                                                                          |
| 358 |     602.08437 |    687.366473 | Matthew Hooge (vectorized by T. Michael Keesey)                                                                                                                                      |
| 359 |     957.11184 |     10.608119 | Scott Hartman                                                                                                                                                                        |
| 360 |     736.91274 |    478.123637 | Ferran Sayol                                                                                                                                                                         |
| 361 |     587.21991 |    785.019587 | Margot Michaud                                                                                                                                                                       |
| 362 |     440.35986 |    626.976205 | Jagged Fang Designs                                                                                                                                                                  |
| 363 |     564.74936 |     93.096147 | Scott Hartman                                                                                                                                                                        |
| 364 |     214.45317 |    669.041954 | Gareth Monger                                                                                                                                                                        |
| 365 |     341.36292 |    652.674896 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 366 |     749.99608 |    527.500436 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 367 |      95.83902 |    398.548816 | Markus A. Grohme                                                                                                                                                                     |
| 368 |    1006.43045 |    506.563688 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 369 |     517.54035 |      4.424454 | M Kolmann                                                                                                                                                                            |
| 370 |     445.51531 |    704.415471 | Iain Reid                                                                                                                                                                            |
| 371 |     793.91959 |    530.759727 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 372 |     954.23290 |    284.498498 | Ferran Sayol                                                                                                                                                                         |
| 373 |     654.42955 |    781.063540 | Tasman Dixon                                                                                                                                                                         |
| 374 |     792.03900 |    151.718467 | Chris huh                                                                                                                                                                            |
| 375 |    1006.67043 |    651.115202 | Scott Reid                                                                                                                                                                           |
| 376 |     161.46335 |    351.007179 | Isaure Scavezzoni                                                                                                                                                                    |
| 377 |     281.38052 |    709.046534 | T. Michael Keesey                                                                                                                                                                    |
| 378 |      90.10402 |    177.244934 | Gareth Monger                                                                                                                                                                        |
| 379 |     863.01824 |    158.215553 | Matt Crook                                                                                                                                                                           |
| 380 |     289.05485 |    347.987017 | Dean Schnabel                                                                                                                                                                        |
| 381 |     281.05352 |    255.606546 | Cagri Cevrim                                                                                                                                                                         |
| 382 |     582.22816 |    271.674409 | Sergio A. Muñoz-Gómez                                                                                                                                                                |
| 383 |     887.63814 |     51.333215 | Tasman Dixon                                                                                                                                                                         |
| 384 |     406.07900 |    717.175213 | Filip em                                                                                                                                                                             |
| 385 |     787.31609 |    591.459130 | John Conway                                                                                                                                                                          |
| 386 |     848.79755 |    437.616533 | Birgit Lang                                                                                                                                                                          |
| 387 |     528.26995 |     84.989476 | Markus A. Grohme                                                                                                                                                                     |
| 388 |     502.56000 |    162.639270 | Xavier Giroux-Bougard                                                                                                                                                                |
| 389 |      15.00993 |    137.853937 | Kailah Thorn & Ben King                                                                                                                                                              |
| 390 |     284.98414 |    754.498731 | Jagged Fang Designs                                                                                                                                                                  |
| 391 |     888.74026 |    721.942257 | Juan Carlos Jerí                                                                                                                                                                     |
| 392 |     875.88060 |     62.859130 | Scott Hartman                                                                                                                                                                        |
| 393 |      31.72172 |    628.099373 | Tasman Dixon                                                                                                                                                                         |
| 394 |     523.04117 |    662.450049 | Jaime Headden                                                                                                                                                                        |
| 395 |     697.31938 |    714.763416 | Zimices                                                                                                                                                                              |
| 396 |     906.17347 |    566.921462 | Alan Manson (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                          |
| 397 |     707.58407 |    176.613944 | Martin R. Smith                                                                                                                                                                      |
| 398 |     735.33711 |    653.014593 | Walter Vladimir                                                                                                                                                                      |
| 399 |     946.03373 |    790.700602 | Erika Schumacher                                                                                                                                                                     |
| 400 |     288.43319 |    601.735993 | NA                                                                                                                                                                                   |
| 401 |     148.33327 |    531.857418 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                                     |
| 402 |     960.73099 |     91.200819 | Mathilde Cordellier                                                                                                                                                                  |
| 403 |     547.42840 |    590.045799 | Rebecca Groom                                                                                                                                                                        |
| 404 |     284.05835 |     37.516800 | Scott Hartman                                                                                                                                                                        |
| 405 |     784.24463 |    580.151277 | Katie S. Collins                                                                                                                                                                     |
| 406 |     986.21816 |    432.371067 | Scott Hartman                                                                                                                                                                        |
| 407 |     885.16015 |    569.265202 | Margot Michaud                                                                                                                                                                       |
| 408 |     439.35425 |    114.868219 | Zimices                                                                                                                                                                              |
| 409 |     423.44275 |    708.723943 | Gareth Monger                                                                                                                                                                        |
| 410 |    1006.41410 |    219.658226 | Beth Reinke                                                                                                                                                                          |
| 411 |     779.49009 |    163.622432 | Gareth Monger                                                                                                                                                                        |
| 412 |     330.11051 |     12.167085 | Tyler Greenfield and Scott Hartman                                                                                                                                                   |
| 413 |     864.81282 |    344.636028 | NA                                                                                                                                                                                   |
| 414 |      80.29215 |    738.970001 | Felix Vaux                                                                                                                                                                           |
| 415 |     626.56685 |    707.989399 | Ignacio Contreras                                                                                                                                                                    |
| 416 |     270.13073 |    216.220721 | Andrew A. Farke                                                                                                                                                                      |
| 417 |     762.30953 |    792.482419 | Zimices                                                                                                                                                                              |
| 418 |     394.19927 |    600.934485 | Jagged Fang Designs                                                                                                                                                                  |
| 419 |     322.05017 |    155.508053 | Steven Traver                                                                                                                                                                        |
| 420 |     295.60342 |    410.779051 | Matt Crook                                                                                                                                                                           |
| 421 |     994.39759 |    378.326451 | NA                                                                                                                                                                                   |
| 422 |     731.99311 |    382.835105 | Jagged Fang Designs                                                                                                                                                                  |
| 423 |      48.96152 |    457.588201 | Margot Michaud                                                                                                                                                                       |
| 424 |      16.58851 |     45.905433 | Matt Crook                                                                                                                                                                           |
| 425 |     195.68221 |    794.549088 | Markus A. Grohme                                                                                                                                                                     |
| 426 |      43.88441 |    347.802086 | Chris A. Hamilton                                                                                                                                                                    |
| 427 |     563.39692 |      5.984833 | Conty (vectorized by T. Michael Keesey)                                                                                                                                              |
| 428 |     115.09360 |    729.437251 | Beth Reinke                                                                                                                                                                          |
| 429 |     675.16752 |     10.487994 | T. Michael Keesey                                                                                                                                                                    |
| 430 |     337.58407 |    542.633838 | Armin Reindl                                                                                                                                                                         |
| 431 |     838.58869 |    550.026587 | Martin R. Smith                                                                                                                                                                      |
| 432 |     399.93264 |     66.744217 | Jagged Fang Designs                                                                                                                                                                  |
| 433 |     195.57461 |    678.199681 | Ingo Braasch                                                                                                                                                                         |
| 434 |     901.82990 |    165.111513 | Ignacio Contreras                                                                                                                                                                    |
| 435 |     647.79396 |    446.083084 | FunkMonk                                                                                                                                                                             |
| 436 |     899.60050 |     39.904315 | Michelle Site                                                                                                                                                                        |
| 437 |     135.07164 |    442.676157 | Scott Hartman (modified by T. Michael Keesey)                                                                                                                                        |
| 438 |     453.92565 |    506.367375 | Gareth Monger                                                                                                                                                                        |
| 439 |     653.97638 |    732.145883 | Martin R. Smith, from photo by Jürgen Schoner                                                                                                                                        |
| 440 |     565.79335 |    707.768318 | Margot Michaud                                                                                                                                                                       |
| 441 |     122.42761 |    639.006263 | Mali’o Kodis, photograph by G. Giribet                                                                                                                                               |
| 442 |     593.33712 |    280.414823 | Matt Crook                                                                                                                                                                           |
| 443 |     330.67567 |    472.629104 | Gareth Monger                                                                                                                                                                        |
| 444 |     583.43843 |    578.077210 | Siobhon Egan                                                                                                                                                                         |
| 445 |     436.19807 |    646.683200 | Scott Hartman                                                                                                                                                                        |
| 446 |     838.10914 |    301.988376 | Zimices                                                                                                                                                                              |
| 447 |     916.90268 |    720.055590 | Jagged Fang Designs                                                                                                                                                                  |
| 448 |     119.61215 |    511.087949 | NA                                                                                                                                                                                   |
| 449 |     472.41778 |    683.825471 | Scott Hartman                                                                                                                                                                        |
| 450 |     678.17196 |    558.041540 | Jagged Fang Designs                                                                                                                                                                  |
| 451 |     245.74700 |    123.474227 | Joanna Wolfe                                                                                                                                                                         |
| 452 |      98.08983 |    376.319505 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                                          |
| 453 |     231.17243 |    366.583989 | Becky Barnes                                                                                                                                                                         |
| 454 |     844.74180 |    796.637761 | NA                                                                                                                                                                                   |
| 455 |     682.19807 |    392.482983 | Birgit Lang                                                                                                                                                                          |
| 456 |     564.25429 |    695.799502 | CNZdenek                                                                                                                                                                             |
| 457 |     826.33758 |    500.552414 | ДиБгд (vectorized by T. Michael Keesey)                                                                                                                                              |
| 458 |      45.29561 |    286.045727 | Nobu Tamura, modified by Andrew A. Farke                                                                                                                                             |
| 459 |     524.36985 |    487.788209 | Siobhon Egan                                                                                                                                                                         |
| 460 |     949.75494 |    198.637769 | Jagged Fang Designs                                                                                                                                                                  |
| 461 |     782.82598 |    343.447757 | Iain Reid                                                                                                                                                                            |
| 462 |     703.60273 |     70.033950 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 463 |     723.70316 |    231.792061 | Zimices                                                                                                                                                                              |
| 464 |     592.39645 |    537.625244 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 465 |     796.11133 |    693.392499 | Ingo Braasch                                                                                                                                                                         |
| 466 |      60.71292 |     33.100308 | Tasman Dixon                                                                                                                                                                         |
| 467 |     567.25674 |    160.702083 | Smokeybjb                                                                                                                                                                            |
| 468 |     165.12825 |    656.507243 | Ignacio Contreras                                                                                                                                                                    |
| 469 |     854.29783 |    490.123948 | NA                                                                                                                                                                                   |
| 470 |     980.64331 |    771.351190 | Ignacio Contreras                                                                                                                                                                    |
| 471 |     411.77754 |    511.339446 | T. Michael Keesey                                                                                                                                                                    |
| 472 |     305.82467 |    287.226949 | Cagri Cevrim                                                                                                                                                                         |
| 473 |     761.11058 |    504.346687 | Matt Martyniuk                                                                                                                                                                       |
| 474 |     318.58057 |    600.174185 | Maija Karala                                                                                                                                                                         |
| 475 |     760.35638 |    389.567879 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 476 |     701.09044 |    533.787518 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                                       |
| 477 |     846.72197 |    453.330659 | Steven Traver                                                                                                                                                                        |
| 478 |     571.29847 |     55.600369 | Gareth Monger                                                                                                                                                                        |
| 479 |     635.12412 |    311.936392 | Scott Hartman                                                                                                                                                                        |
| 480 |      82.99011 |    515.507614 | Verisimilus                                                                                                                                                                          |
| 481 |     304.08713 |    515.961907 | Vijay Cavale (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                         |
| 482 |     380.53063 |     37.735851 | Markus A. Grohme                                                                                                                                                                     |
| 483 |     155.52774 |    147.412830 | Zimices                                                                                                                                                                              |
| 484 |      98.53210 |    639.241229 | Andy Wilson                                                                                                                                                                          |
| 485 |     693.51735 |      8.001689 | Chris huh                                                                                                                                                                            |
| 486 |     160.45208 |    158.174387 | Scott Hartman                                                                                                                                                                        |
| 487 |     685.22340 |    174.745308 | Geoff Shaw                                                                                                                                                                           |
| 488 |     313.62558 |    110.461260 | Michael P. Taylor                                                                                                                                                                    |
| 489 |     967.22972 |    669.691421 | Jagged Fang Designs                                                                                                                                                                  |
| 490 |     553.74515 |    286.760003 | Ewald Rübsamen                                                                                                                                                                       |
| 491 |     546.49441 |    729.336707 | NA                                                                                                                                                                                   |
| 492 |    1003.18314 |    234.262257 | Margot Michaud                                                                                                                                                                       |
| 493 |     434.30965 |    600.925741 | Mathieu Pélissié                                                                                                                                                                     |
| 494 |     875.14280 |    381.807792 | NA                                                                                                                                                                                   |
| 495 |     270.41343 |    126.617278 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 496 |       9.80637 |    223.923888 | Gareth Monger                                                                                                                                                                        |
| 497 |     880.12985 |    228.080778 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 498 |     269.24490 |    793.712222 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 499 |     869.99915 |    744.472497 | Zimices                                                                                                                                                                              |
| 500 |     643.46087 |    304.667920 | Scott Hartman                                                                                                                                                                        |
| 501 |     957.09690 |    479.518533 | Margot Michaud                                                                                                                                                                       |
| 502 |     926.22651 |    659.988460 | Scott Hartman                                                                                                                                                                        |
| 503 |     997.55916 |    264.268063 | Matt Crook                                                                                                                                                                           |
| 504 |     270.35034 |    741.479784 | Farelli (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                              |
| 505 |     475.09629 |    794.373129 | Mercedes Yrayzoz (vectorized by T. Michael Keesey)                                                                                                                                   |
| 506 |    1016.46902 |    586.217636 | Michael Scroggie                                                                                                                                                                     |
| 507 |     379.98563 |    251.139046 | Zimices                                                                                                                                                                              |
| 508 |     966.75190 |    297.512267 | Michelle Site                                                                                                                                                                        |

    #> Your tweet has been posted!
