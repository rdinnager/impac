
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

Steven Traver, Margot Michaud, Gabriela Palomo-Munoz, Jay Matternes
(vectorized by T. Michael Keesey), T. Michael Keesey, Lukasiniho, T.
Michael Keesey (photo by J. M. Garg), Noah Schlottman, photo from Casey
Dunn, Zimices, Mali’o Kodis, image from the “Proceedings of the
Zoological Society of London”, Jagged Fang Designs, Scott Hartman,
Gareth Monger, Dmitry Bogdanov (vectorized by T. Michael Keesey), Kanako
Bessho-Uehara, Martin R. Smith, Matt Crook, Leann Biancani, photo by
Kenneth Clifton, Jaime Headden, CNZdenek, Caleb M. Brown, Danielle Alba,
Iain Reid, Chris huh, Yan Wong, Tasman Dixon, Kamil S. Jaron, Nobu
Tamura (vectorized by T. Michael Keesey), M Kolmann, L. Shyamal, Andrew
A. Farke, shell lines added by Yan Wong, Kent Elson Sorgon, Diego
Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli,
Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by
T. Michael Keesey), Inessa Voet, NASA, S.Martini, T. Michael Keesey
(photo by Bc999 \[Black crow\]), Beth Reinke, Yan Wong from illustration
by Jules Richard (1907), Rebecca Groom, Christina N. Hodson, Henry
Lydecker, Jessica Anne Miller, Florian Pfaff, Caleb Brown, Ignacio
Contreras, Darren Naish (vectorized by T. Michael Keesey), Yusan Yang,
Melissa Ingala, Melissa Broussard, Filip em, Ben Liebeskind, Owen Jones,
Meliponicultor Itaymbere, Renata F. Martins, Evan-Amos (vectorized by T.
Michael Keesey), Ricardo N. Martinez & Oscar A. Alcober, T. Michael
Keesey (from a photograph by Frank Glaw, Jörn Köhler, Ted M. Townsend &
Miguel Vences), Kai R. Caspar, Nick Schooler, Zachary Quigley,
Apokryltaros (vectorized by T. Michael Keesey), Roberto Díaz Sibaja,
Michelle Site, Sarah Werning, Birgit Lang, Milton Tan, Zimices / Julián
Bayona, Emily Willoughby, Juan Carlos Jerí, Nobu Tamura (modified by T.
Michael Keesey), (after McCulloch 1908), Smokeybjb (vectorized by T.
Michael Keesey), Espen Horn (model; vectorized by T. Michael Keesey from
a photo by H. Zell), Armin Reindl, Jonathan Wells, T. Michael Keesey
(after Marek Velechovský), Fernando Carezzano, Terpsichores, Vijay
Cavale (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Unknown (photo), John E. McCormack, Michael G. Harvey,
Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T.
Brumfield & T. Michael Keesey, Jack Mayer Wood, Maija Karala, Kanchi
Nanjo, T. Michael Keesey (after Masteraah), Mathieu Basille,
Falconaumanni and T. Michael Keesey, nicubunu, Joanna Wolfe, Ghedo
(vectorized by T. Michael Keesey), C. Camilo Julián-Caballero, Thea
Boodhoo (photograph) and T. Michael Keesey (vectorization), Javier
Luque, Mali’o Kodis, photograph by G. Giribet, Becky Barnes, Katie S.
Collins, Berivan Temiz, DW Bapst (modified from Bulman, 1970), Oscar
Sanisidro, Julio Garza, Oliver Voigt, Martin R. Smith, after Skovsted et
al 2015, Matt Wilkins (photo by Patrick Kavanagh), Alexander
Schmidt-Lebuhn, Matt Martyniuk, Pete Buchholz, Dave Angelini, Ellen
Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley
(silhouette), Ferran Sayol, Collin Gross, Tess Linden, Pranav Iyer (grey
ideas), Felix Vaux, Cesar Julian, Christoph Schomburg, Obsidian Soul
(vectorized by T. Michael Keesey), Ghedoghedo (vectorized by T. Michael
Keesey), T. Michael Keesey (after Kukalová), Ellen Edmonson and Hugh
Chrisp (vectorized by T. Michael Keesey), Smokeybjb (modified by Mike
Keesey), John Curtis (vectorized by T. Michael Keesey), Scott Reid,
Dr. Thomas G. Barnes, USFWS, Noah Schlottman, photo by Gustav Paulay
for Moorea Biocode, Campbell Fleming, Markus A. Grohme, Hans Hillewaert
(vectorized by T. Michael Keesey), Nobu Tamura, Noah Schlottman, photo
by Casey Dunn, Dein Freund der Baum (vectorized by T. Michael Keesey),
Xavier A. Jenkins, Gabriel Ugueto, Manabu Sakamoto, Kosta Mumcuoglu
(vectorized by T. Michael Keesey), Sergio A. Muñoz-Gómez, Emily Jane
McTavish, from Haeckel, E. H. P. A. (1904).Kunstformen der Natur.
Bibliographisches, Kevin Sánchez, Andrew A. Farke, Christine Axon,
Harold N Eyster, Timothy Knepp of the U.S. Fish and Wildlife Service
(illustration) and Timothy J. Bartley (silhouette), Jebulon (vectorized
by T. Michael Keesey), Ernst Haeckel (vectorized by T. Michael Keesey),
Lily Hughes, Nancy Wyman (photo), John E. McCormack, Michael G. Harvey,
Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T.
Brumfield & T. Michael Keesey, Tambja (vectorized by T. Michael Keesey),
Ingo Braasch, Mathew Wedel, Michele M Tobias, Jaime Chirinos (vectorized
by T. Michael Keesey), Steve Hillebrand/U. S. Fish and Wildlife Service
(source photo), T. Michael Keesey (vectorization), Konsta Happonen, from
a CC-BY-NC image by pelhonen on iNaturalist, Mike Keesey (vectorization)
and Vaibhavcho (photography), Anthony Caravaggi, Gustav Mützel, Arthur
S. Brum, T. Michael Keesey (after Tillyard), Sean McCann, Dennis C.
Murphy, after
<https://commons.wikimedia.org/wiki/File:Queensland_State_Archives_2981_Cane_toads_at_the_Meringa_Sugar_Experiment_Station_North_Queensland_c_1935.png>,
Raven Amos, Ghedoghedo, Kailah Thorn & Mark Hutchinson, Cathy, xgirouxb,
Mathilde Cordellier, Renato Santos, Conty, Tony Ayling (vectorized by T.
Michael Keesey), John Conway, Rainer Schoch, FunkMonk, James R. Spotila
and Ray Chatterji, T. Michael Keesey (vectorization) and Larry Loos
(photography), Birgit Lang; based on a drawing by C.L. Koch, Sam
Fraser-Smith (vectorized by T. Michael Keesey), Mali’o Kodis, photograph
by John Slapcinsky, Benjamint444, Steven Coombs, Ghedo and T. Michael
Keesey, Chuanixn Yu, Jay Matternes, vectorized by Zimices, Cagri Cevrim,
Mike Hanson, Noah Schlottman, photo by Reinhard Jahn, David Orr, Tauana
J. Cunha, ArtFavor & annaleeblysse, David Tana, Dmitry Bogdanov,
Peileppe, U.S. Fish and Wildlife Service (illustration) and Timothy J.
Bartley (silhouette), Robert Gay, Stanton F. Fink, vectorized by
Zimices, Timothy Knepp (vectorized by T. Michael Keesey), Noah
Schlottman, photo by Museum of Geology, University of Tartu, Andrew
Farke and Joseph Sertich, B. Duygu Özpolat, Karla Martinez, C. W. Nash
(illustration) and Timothy J. Bartley (silhouette), NOAA Great Lakes
Environmental Research Laboratory (illustration) and Timothy J. Bartley
(silhouette), Roderic Page and Lois Page, \[unknown\],
kreidefossilien.de, Michael Scroggie, Michael B. H. (vectorized by T.
Michael Keesey), Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric
M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus,
Michael Ströck (vectorized by T. Michael Keesey), Robbie N. Cada
(vectorized by T. Michael Keesey), Richard J. Harris, Robert Bruce
Horsfall, vectorized by Zimices, H. F. O. March (modified by T. Michael
Keesey, Michael P. Taylor & Matthew J. Wedel), Charles Doolittle Walcott
(vectorized by T. Michael Keesey), Johan Lindgren, Michael W. Caldwell,
Takuya Konishi, Luis M. Chiappe, Scott Hartman (vectorized by T. Michael
Keesey), Auckland Museum, Smokeybjb, Liftarn, Frederick William Frohawk
(vectorized by T. Michael Keesey), Nicholas J. Czaplewski, vectorized by
Zimices, Robert Bruce Horsfall (vectorized by T. Michael Keesey),
Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes
(www.carnivorosaustrales.org), Margret Flinsch, vectorized by Zimices,
Manabu Bessho-Uehara, T. Michael Keesey (after Monika Betley),
FJDegrange, Dantheman9758 (vectorized by T. Michael Keesey), Sarah
Alewijnse, Abraão Leite, Caio Bernardes, vectorized by Zimices, Zsoldos
Márton (vectorized by T. Michael Keesey), Ville-Veikko Sinkkonen, Emma
Kissling, Yan Wong from photo by Gyik Toma, Y. de Hoev. (vectorized by
T. Michael Keesey), David Sim (photograph) and T. Michael Keesey
(vectorization), Matt Wilkins, Shyamal, Paul O. Lewis, Acrocynus
(vectorized by T. Michael Keesey), Dean Schnabel, Leon P. A. M.
Claessens, Patrick M. O’Connor, David M. Unwin, Brockhaus and Efron,
Maxime Dahirel (digitisation), Kees van Achterberg et al (doi:
10.3897/BDJ.8.e49017)(original publication), Mo Hassan, Mali’o Kodis,
photograph from Jersabek et al, 2003, Frank Förster (based on a picture
by Hans Hillewaert), Steven Haddock • Jellywatch.org, Verdilak,
terngirl, Jake Warner, Caroline Harding, MAF (vectorized by T. Michael
Keesey), Tyler Greenfield, B Kimmel, Servien (vectorized by T. Michael
Keesey), Sharon Wegner-Larsen, Brad McFeeters (vectorized by T. Michael
Keesey), Gopal Murali, Maxwell Lefroy (vectorized by T. Michael Keesey),
Tracy A. Heath, Noah Schlottman, Emily Jane McTavish, Sibi (vectorized
by T. Michael Keesey), Pollyanna von Knorring and T. Michael Keesey,
Mali’o Kodis, photograph by Aqua-Photos
(<http://www.flickr.com/people/undervannsfotografen/>), Bill Bouton
(source photo) & T. Michael Keesey (vectorization), Alexis Simon, Walter
Vladimir, Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob
Slotow (vectorized by T. Michael Keesey), Michael P. Taylor, Lisa Byrne,
Alex Slavenko, Yan Wong from drawing by Joseph Smit, Chase Brownstein,
T. Michael Keesey, from a photograph by Thea Boodhoo, Joseph Wolf, 1863
(vectorization by Dinah Challen), Jean-Raphaël Guillaumin (photography)
and T. Michael Keesey (vectorization), Chris Jennings (Risiatto), Noah
Schlottman, photo from National Science Foundation - Turbellarian
Taxonomic Database, Chloé Schmidt, Samanta Orellana

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                          |
| --: | ------------: | ------------: | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
|   1 |    801.851299 |    135.504128 | Steven Traver                                                                                                                                                                   |
|   2 |    873.567926 |    379.150247 | Margot Michaud                                                                                                                                                                  |
|   3 |    645.447926 |    286.179514 | Gabriela Palomo-Munoz                                                                                                                                                           |
|   4 |    137.608526 |    374.737966 | Jay Matternes (vectorized by T. Michael Keesey)                                                                                                                                 |
|   5 |    906.244987 |    666.303605 | T. Michael Keesey                                                                                                                                                               |
|   6 |     45.979939 |    652.652569 | Lukasiniho                                                                                                                                                                      |
|   7 |    410.092404 |    275.056022 | T. Michael Keesey (photo by J. M. Garg)                                                                                                                                         |
|   8 |    817.519585 |    536.738818 | Noah Schlottman, photo from Casey Dunn                                                                                                                                          |
|   9 |    275.562665 |    605.047360 | Zimices                                                                                                                                                                         |
|  10 |    712.392005 |    479.648912 | Mali’o Kodis, image from the “Proceedings of the Zoological Society of London”                                                                                                  |
|  11 |    621.134288 |    167.561845 | Margot Michaud                                                                                                                                                                  |
|  12 |    526.748061 |    116.812351 | Jagged Fang Designs                                                                                                                                                             |
|  13 |    699.361953 |    668.604539 | Scott Hartman                                                                                                                                                                   |
|  14 |    477.858244 |    535.848677 | T. Michael Keesey                                                                                                                                                               |
|  15 |    521.782468 |    745.472733 | NA                                                                                                                                                                              |
|  16 |    191.458102 |    718.364900 | Gareth Monger                                                                                                                                                                   |
|  17 |     95.484000 |    192.920948 | NA                                                                                                                                                                              |
|  18 |    300.440745 |    301.635779 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
|  19 |    431.408400 |    668.463640 | Kanako Bessho-Uehara                                                                                                                                                            |
|  20 |    985.666750 |    282.496178 | Martin R. Smith                                                                                                                                                                 |
|  21 |    335.568496 |    498.187113 | Matt Crook                                                                                                                                                                      |
|  22 |    181.190815 |    536.869160 | Leann Biancani, photo by Kenneth Clifton                                                                                                                                        |
|  23 |    653.118172 |    377.291724 | Jaime Headden                                                                                                                                                                   |
|  24 |    532.525689 |    225.235189 | CNZdenek                                                                                                                                                                        |
|  25 |    801.282941 |    290.410920 | Caleb M. Brown                                                                                                                                                                  |
|  26 |    611.949289 |    609.694507 | NA                                                                                                                                                                              |
|  27 |    947.101292 |    156.103551 | Danielle Alba                                                                                                                                                                   |
|  28 |    649.979453 |     64.781440 | Zimices                                                                                                                                                                         |
|  29 |    309.740660 |     33.568021 | Iain Reid                                                                                                                                                                       |
|  30 |    324.138276 |    722.896156 | Chris huh                                                                                                                                                                       |
|  31 |    942.704741 |    517.890210 | Yan Wong                                                                                                                                                                        |
|  32 |    597.187813 |    531.830605 | CNZdenek                                                                                                                                                                        |
|  33 |    234.234829 |    170.236780 | Tasman Dixon                                                                                                                                                                    |
|  34 |     93.170007 |    771.115401 | T. Michael Keesey                                                                                                                                                               |
|  35 |    187.152926 |     64.023652 | Kamil S. Jaron                                                                                                                                                                  |
|  36 |    697.092070 |    772.563904 | Jagged Fang Designs                                                                                                                                                             |
|  37 |    131.332444 |    298.836494 | Margot Michaud                                                                                                                                                                  |
|  38 |    927.172970 |    778.717042 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
|  39 |    505.429733 |    141.471326 | M Kolmann                                                                                                                                                                       |
|  40 |    107.564659 |    492.700161 | L. Shyamal                                                                                                                                                                      |
|  41 |     71.300825 |     65.947910 | Gareth Monger                                                                                                                                                                   |
|  42 |    333.222268 |    782.354038 | Gareth Monger                                                                                                                                                                   |
|  43 |    856.070399 |     75.369713 | Zimices                                                                                                                                                                         |
|  44 |    804.017752 |    755.978767 | Andrew A. Farke, shell lines added by Yan Wong                                                                                                                                  |
|  45 |    812.981676 |     22.237862 | Kent Elson Sorgon                                                                                                                                                               |
|  46 |    421.855541 |     60.815808 | Tasman Dixon                                                                                                                                                                    |
|  47 |    849.434379 |    227.220841 | Steven Traver                                                                                                                                                                   |
|  48 |     41.579251 |    308.667417 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey)           |
|  49 |    638.726088 |    475.653313 | Inessa Voet                                                                                                                                                                     |
|  50 |    868.407803 |    620.333757 | Yan Wong                                                                                                                                                                        |
|  51 |    241.762325 |    451.225540 | Chris huh                                                                                                                                                                       |
|  52 |    503.043471 |    179.472305 | Chris huh                                                                                                                                                                       |
|  53 |    888.937699 |    485.682187 | NASA                                                                                                                                                                            |
|  54 |    212.895665 |    509.369008 | S.Martini                                                                                                                                                                       |
|  55 |    120.350187 |    606.295764 | T. Michael Keesey (photo by Bc999 \[Black crow\])                                                                                                                               |
|  56 |    552.267571 |    657.393518 | Gabriela Palomo-Munoz                                                                                                                                                           |
|  57 |    716.010947 |    219.677319 | L. Shyamal                                                                                                                                                                      |
|  58 |    709.213442 |    593.637352 | Zimices                                                                                                                                                                         |
|  59 |    294.777389 |    384.604826 | Beth Reinke                                                                                                                                                                     |
|  60 |    945.319972 |    637.032217 | NA                                                                                                                                                                              |
|  61 |    119.656543 |    263.684501 | Yan Wong from illustration by Jules Richard (1907)                                                                                                                              |
|  62 |    254.919939 |    217.955522 | Rebecca Groom                                                                                                                                                                   |
|  63 |    665.953358 |    569.703415 | Scott Hartman                                                                                                                                                                   |
|  64 |    438.923275 |    451.931792 | Christina N. Hodson                                                                                                                                                             |
|  65 |    436.935144 |    102.362970 | Henry Lydecker                                                                                                                                                                  |
|  66 |   1006.131820 |    494.719231 | Gareth Monger                                                                                                                                                                   |
|  67 |    545.184863 |    504.938832 | Matt Crook                                                                                                                                                                      |
|  68 |    735.724578 |    356.396288 | Jessica Anne Miller                                                                                                                                                             |
|  69 |    122.629666 |     75.886822 | Florian Pfaff                                                                                                                                                                   |
|  70 |    894.014588 |    270.801560 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
|  71 |    763.659721 |    386.384355 | Steven Traver                                                                                                                                                                   |
|  72 |    918.405228 |    133.745418 | Inessa Voet                                                                                                                                                                     |
|  73 |     56.646471 |    594.553081 | Matt Crook                                                                                                                                                                      |
|  74 |    334.014675 |     47.225140 | T. Michael Keesey                                                                                                                                                               |
|  75 |    760.953844 |    433.217881 | NA                                                                                                                                                                              |
|  76 |    446.537839 |    791.277157 | Caleb Brown                                                                                                                                                                     |
|  77 |    820.720948 |     81.611482 | Gareth Monger                                                                                                                                                                   |
|  78 |   1006.983417 |    377.538305 | Margot Michaud                                                                                                                                                                  |
|  79 |    833.496333 |    312.871015 | Ignacio Contreras                                                                                                                                                               |
|  80 |    630.602175 |    240.466214 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                                  |
|  81 |    706.214008 |    445.582820 | Yusan Yang                                                                                                                                                                      |
|  82 |    315.227344 |    251.823714 | Melissa Ingala                                                                                                                                                                  |
|  83 |    508.894681 |     79.359545 | T. Michael Keesey                                                                                                                                                               |
|  84 |    660.925680 |    116.537433 | Matt Crook                                                                                                                                                                      |
|  85 |    824.934496 |    683.298995 | Melissa Broussard                                                                                                                                                               |
|  86 |    214.477969 |    267.612882 | Filip em                                                                                                                                                                        |
|  87 |    226.335162 |    142.616791 | Ben Liebeskind                                                                                                                                                                  |
|  88 |    160.565835 |    595.909913 | Tasman Dixon                                                                                                                                                                    |
|  89 |     19.874245 |    150.933078 | Matt Crook                                                                                                                                                                      |
|  90 |   1014.322469 |    617.294090 | Gareth Monger                                                                                                                                                                   |
|  91 |    777.240665 |    176.444982 | Owen Jones                                                                                                                                                                      |
|  92 |    909.261538 |    744.607026 | Scott Hartman                                                                                                                                                                   |
|  93 |    865.300204 |    319.837511 | Meliponicultor Itaymbere                                                                                                                                                        |
|  94 |     55.656153 |    415.955486 | Renata F. Martins                                                                                                                                                               |
|  95 |     28.560774 |    460.956786 | Margot Michaud                                                                                                                                                                  |
|  96 |    718.016953 |    155.167008 | Evan-Amos (vectorized by T. Michael Keesey)                                                                                                                                     |
|  97 |    583.269855 |    424.630041 | Zimices                                                                                                                                                                         |
|  98 |     37.776035 |    398.728167 | Steven Traver                                                                                                                                                                   |
|  99 |    404.047935 |    592.461305 | Margot Michaud                                                                                                                                                                  |
| 100 |    517.736675 |     38.070873 | Gareth Monger                                                                                                                                                                   |
| 101 |    846.882701 |    196.240642 | NA                                                                                                                                                                              |
| 102 |    256.900481 |    695.475604 | Ricardo N. Martinez & Oscar A. Alcober                                                                                                                                          |
| 103 |    605.007618 |    778.842970 | T. Michael Keesey (from a photograph by Frank Glaw, Jörn Köhler, Ted M. Townsend & Miguel Vences)                                                                               |
| 104 |    569.399560 |    318.893358 | Kai R. Caspar                                                                                                                                                                   |
| 105 |    592.642317 |    337.477190 | Nick Schooler                                                                                                                                                                   |
| 106 |     50.623588 |    138.650333 | Yan Wong                                                                                                                                                                        |
| 107 |   1003.541132 |    425.586952 | NA                                                                                                                                                                              |
| 108 |    412.799769 |      8.259655 | Zachary Quigley                                                                                                                                                                 |
| 109 |    791.649099 |    615.747429 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                                  |
| 110 |    244.166091 |    659.400750 | Roberto Díaz Sibaja                                                                                                                                                             |
| 111 |    972.881882 |     80.590087 | Chris huh                                                                                                                                                                       |
| 112 |    742.713486 |    558.225478 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 113 |    207.012177 |    312.501773 | Michelle Site                                                                                                                                                                   |
| 114 |    381.838948 |     79.742484 | Sarah Werning                                                                                                                                                                   |
| 115 |    853.671782 |    463.258868 | Jagged Fang Designs                                                                                                                                                             |
| 116 |    773.113455 |    211.017846 | Matt Crook                                                                                                                                                                      |
| 117 |    118.463031 |    677.992430 | NA                                                                                                                                                                              |
| 118 |     58.839830 |     20.712924 | NA                                                                                                                                                                              |
| 119 |     27.166866 |    737.065122 | Birgit Lang                                                                                                                                                                     |
| 120 |    677.553485 |    449.308169 | Margot Michaud                                                                                                                                                                  |
| 121 |    208.865933 |    420.642787 | Owen Jones                                                                                                                                                                      |
| 122 |    323.866792 |    570.861256 | Milton Tan                                                                                                                                                                      |
| 123 |    606.320020 |    587.624680 | Zimices                                                                                                                                                                         |
| 124 |    425.536067 |     24.261034 | Zimices / Julián Bayona                                                                                                                                                         |
| 125 |     25.157097 |    218.859713 | Emily Willoughby                                                                                                                                                                |
| 126 |    542.889420 |    266.804951 | Gareth Monger                                                                                                                                                                   |
| 127 |    162.675920 |    247.373006 | Zimices                                                                                                                                                                         |
| 128 |    911.022744 |    153.162110 | Juan Carlos Jerí                                                                                                                                                                |
| 129 |    121.047767 |    137.584101 | Chris huh                                                                                                                                                                       |
| 130 |    935.592584 |    457.792636 | Margot Michaud                                                                                                                                                                  |
| 131 |    940.119227 |    222.188242 | Zimices                                                                                                                                                                         |
| 132 |    929.825930 |    326.968923 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                                     |
| 133 |    708.247861 |    724.749312 | Steven Traver                                                                                                                                                                   |
| 134 |    816.768735 |    334.838364 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 135 |    119.514741 |    729.943041 | Margot Michaud                                                                                                                                                                  |
| 136 |   1006.409315 |    589.966390 | Steven Traver                                                                                                                                                                   |
| 137 |    166.858372 |    586.614641 | Margot Michaud                                                                                                                                                                  |
| 138 |    978.750229 |    738.012814 | (after McCulloch 1908)                                                                                                                                                          |
| 139 |    275.736880 |    137.193726 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                                     |
| 140 |     77.241192 |    409.839617 | Espen Horn (model; vectorized by T. Michael Keesey from a photo by H. Zell)                                                                                                     |
| 141 |    350.619675 |    680.596253 | Armin Reindl                                                                                                                                                                    |
| 142 |    954.590243 |    226.375635 | Zimices                                                                                                                                                                         |
| 143 |      8.296850 |     69.297167 | Jonathan Wells                                                                                                                                                                  |
| 144 |    839.243388 |    329.860832 | Jagged Fang Designs                                                                                                                                                             |
| 145 |    617.624244 |    633.991176 | Matt Crook                                                                                                                                                                      |
| 146 |    319.210131 |    452.469707 | T. Michael Keesey (after Marek Velechovský)                                                                                                                                     |
| 147 |      9.023429 |    758.714990 | T. Michael Keesey                                                                                                                                                               |
| 148 |    575.547009 |    253.536778 | Iain Reid                                                                                                                                                                       |
| 149 |    408.173588 |    123.059587 | Fernando Carezzano                                                                                                                                                              |
| 150 |    567.259010 |     12.202789 | Terpsichores                                                                                                                                                                    |
| 151 |    582.182852 |    572.154973 | Scott Hartman                                                                                                                                                                   |
| 152 |    187.588135 |    621.520043 | Vijay Cavale (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                    |
| 153 |    412.896187 |    678.366947 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                         |
| 154 |   1005.833018 |    638.121626 | CNZdenek                                                                                                                                                                        |
| 155 |     35.029285 |    564.464764 | Jack Mayer Wood                                                                                                                                                                 |
| 156 |    701.561358 |    118.838030 | Matt Crook                                                                                                                                                                      |
| 157 |    632.882497 |    313.226933 | Kai R. Caspar                                                                                                                                                                   |
| 158 |    925.165226 |     45.294506 | Maija Karala                                                                                                                                                                    |
| 159 |    358.663484 |    303.023116 | Kanchi Nanjo                                                                                                                                                                    |
| 160 |    934.145602 |    235.028228 | T. Michael Keesey (after Masteraah)                                                                                                                                             |
| 161 |    317.655135 |    482.646527 | NA                                                                                                                                                                              |
| 162 |    770.213724 |    238.104209 | Steven Traver                                                                                                                                                                   |
| 163 |    437.774873 |    166.637966 | Nick Schooler                                                                                                                                                                   |
| 164 |    440.041756 |    533.277851 | Sarah Werning                                                                                                                                                                   |
| 165 |    256.068014 |     29.400739 | Zimices                                                                                                                                                                         |
| 166 |    554.183188 |     96.942196 | Ignacio Contreras                                                                                                                                                               |
| 167 |    354.832431 |    608.807951 | NA                                                                                                                                                                              |
| 168 |    921.843329 |    261.731049 | Jagged Fang Designs                                                                                                                                                             |
| 169 |    780.267428 |     88.947167 | Mathieu Basille                                                                                                                                                                 |
| 170 |    415.577615 |    523.167635 | Falconaumanni and T. Michael Keesey                                                                                                                                             |
| 171 |    121.407572 |    442.558679 | nicubunu                                                                                                                                                                        |
| 172 |    832.985053 |    635.501325 | Joanna Wolfe                                                                                                                                                                    |
| 173 |    952.715396 |    700.111872 | Ghedo (vectorized by T. Michael Keesey)                                                                                                                                         |
| 174 |    450.560969 |    160.386694 | Zimices                                                                                                                                                                         |
| 175 |    865.301691 |    447.454725 | T. Michael Keesey                                                                                                                                                               |
| 176 |    581.301487 |    416.554268 | C. Camilo Julián-Caballero                                                                                                                                                      |
| 177 |    983.640487 |    613.824753 | T. Michael Keesey                                                                                                                                                               |
| 178 |     90.165967 |    697.704990 | Thea Boodhoo (photograph) and T. Michael Keesey (vectorization)                                                                                                                 |
| 179 |    724.922588 |    129.292042 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 180 |    957.436429 |    748.570328 | Javier Luque                                                                                                                                                                    |
| 181 |     18.735279 |    415.433252 | Mali’o Kodis, photograph by G. Giribet                                                                                                                                          |
| 182 |    841.530618 |    694.766283 | NA                                                                                                                                                                              |
| 183 |    519.797264 |    578.822514 | Becky Barnes                                                                                                                                                                    |
| 184 |    776.413694 |    310.453444 | Katie S. Collins                                                                                                                                                                |
| 185 |    487.281604 |     85.814188 | NA                                                                                                                                                                              |
| 186 |    925.504289 |    209.674565 | Zimices                                                                                                                                                                         |
| 187 |    300.576263 |    442.973050 | Matt Crook                                                                                                                                                                      |
| 188 |    291.990851 |    466.499847 | Matt Crook                                                                                                                                                                      |
| 189 |    598.217607 |    727.916759 | Berivan Temiz                                                                                                                                                                   |
| 190 |    803.370153 |    417.378002 | NA                                                                                                                                                                              |
| 191 |    129.226251 |    746.005143 | Zimices                                                                                                                                                                         |
| 192 |    366.790927 |    564.781337 | Margot Michaud                                                                                                                                                                  |
| 193 |    388.940947 |    693.783797 | Kamil S. Jaron                                                                                                                                                                  |
| 194 |    551.203926 |    506.789539 | Matt Crook                                                                                                                                                                      |
| 195 |    868.997085 |    755.815932 | Zimices                                                                                                                                                                         |
| 196 |    473.162442 |    466.270233 | DW Bapst (modified from Bulman, 1970)                                                                                                                                           |
| 197 |    284.328860 |     74.798859 | Oscar Sanisidro                                                                                                                                                                 |
| 198 |    100.416670 |    436.174436 | NA                                                                                                                                                                              |
| 199 |    148.233061 |    701.641607 | Matt Crook                                                                                                                                                                      |
| 200 |    442.189782 |    764.286034 | Julio Garza                                                                                                                                                                     |
| 201 |    403.447964 |    537.544046 | Oliver Voigt                                                                                                                                                                    |
| 202 |    439.719057 |    723.463874 | Henry Lydecker                                                                                                                                                                  |
| 203 |     19.748722 |    518.081209 | Martin R. Smith, after Skovsted et al 2015                                                                                                                                      |
| 204 |    521.255850 |     79.805493 | T. Michael Keesey                                                                                                                                                               |
| 205 |    895.851661 |    302.019237 | Jaime Headden                                                                                                                                                                   |
| 206 |     57.363205 |    403.363101 | Jagged Fang Designs                                                                                                                                                             |
| 207 |    613.306004 |    254.922978 | Matt Wilkins (photo by Patrick Kavanagh)                                                                                                                                        |
| 208 |     93.245578 |    638.873785 | T. Michael Keesey                                                                                                                                                               |
| 209 |    360.863111 |     14.649866 | Tasman Dixon                                                                                                                                                                    |
| 210 |    218.876675 |    111.716353 | Matt Crook                                                                                                                                                                      |
| 211 |    978.721366 |    205.757013 | Zimices                                                                                                                                                                         |
| 212 |    939.706292 |    289.241688 | NA                                                                                                                                                                              |
| 213 |    732.505239 |    779.127543 | Martin R. Smith                                                                                                                                                                 |
| 214 |    392.951915 |    476.986237 | NA                                                                                                                                                                              |
| 215 |    525.812250 |     96.213862 | Gareth Monger                                                                                                                                                                   |
| 216 |    419.892821 |    771.283148 | Matt Crook                                                                                                                                                                      |
| 217 |    745.404997 |    406.195481 | Zimices                                                                                                                                                                         |
| 218 |    429.654441 |    150.575206 | Alexander Schmidt-Lebuhn                                                                                                                                                        |
| 219 |    320.069476 |    368.134645 | Matt Martyniuk                                                                                                                                                                  |
| 220 |      8.228231 |    586.801488 | Zimices                                                                                                                                                                         |
| 221 |    656.997723 |    745.454409 | NA                                                                                                                                                                              |
| 222 |     89.994242 |    727.550677 | Alexander Schmidt-Lebuhn                                                                                                                                                        |
| 223 |    253.982391 |    685.049471 | T. Michael Keesey                                                                                                                                                               |
| 224 |    164.625609 |    195.425364 | L. Shyamal                                                                                                                                                                      |
| 225 |    585.553238 |    247.871827 | Scott Hartman                                                                                                                                                                   |
| 226 |    237.623017 |    283.896394 | Pete Buchholz                                                                                                                                                                   |
| 227 |    668.888150 |    254.097858 | T. Michael Keesey                                                                                                                                                               |
| 228 |    333.391835 |    642.268545 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 229 |    466.110100 |    609.828233 | Steven Traver                                                                                                                                                                   |
| 230 |     77.322321 |     95.130715 | Birgit Lang                                                                                                                                                                     |
| 231 |    869.661766 |    146.092875 | Dave Angelini                                                                                                                                                                   |
| 232 |    686.474605 |    106.634008 | Steven Traver                                                                                                                                                                   |
| 233 |    661.166976 |    504.418327 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                                               |
| 234 |    405.690286 |    554.868523 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 235 |    333.952841 |    293.508688 | T. Michael Keesey                                                                                                                                                               |
| 236 |    385.610607 |     30.926263 | Martin R. Smith                                                                                                                                                                 |
| 237 |     86.658460 |    415.414155 | Alexander Schmidt-Lebuhn                                                                                                                                                        |
| 238 |    998.775391 |    704.270226 | Beth Reinke                                                                                                                                                                     |
| 239 |    280.213990 |    483.312710 | Zimices                                                                                                                                                                         |
| 240 |    997.884938 |    103.048337 | Alexander Schmidt-Lebuhn                                                                                                                                                        |
| 241 |    955.161932 |    444.621943 | Matt Crook                                                                                                                                                                      |
| 242 |    746.962527 |     12.229442 | Zimices                                                                                                                                                                         |
| 243 |    560.351423 |    638.015954 | Gareth Monger                                                                                                                                                                   |
| 244 |     47.204594 |    503.758153 | Margot Michaud                                                                                                                                                                  |
| 245 |    158.063413 |    647.876707 | Ferran Sayol                                                                                                                                                                    |
| 246 |    564.609268 |    579.056644 | Jagged Fang Designs                                                                                                                                                             |
| 247 |    787.625638 |    589.672118 | Collin Gross                                                                                                                                                                    |
| 248 |    631.104270 |    792.031504 | Tess Linden                                                                                                                                                                     |
| 249 |    906.496349 |    216.110332 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 250 |    194.883530 |    518.264483 | Zimices                                                                                                                                                                         |
| 251 |    317.842056 |    757.494352 | Pranav Iyer (grey ideas)                                                                                                                                                        |
| 252 |    232.722651 |    335.171728 | NA                                                                                                                                                                              |
| 253 |     13.870315 |    555.426109 | Felix Vaux                                                                                                                                                                      |
| 254 |    175.266624 |    623.586319 | Cesar Julian                                                                                                                                                                    |
| 255 |    923.081502 |    431.914055 | Kai R. Caspar                                                                                                                                                                   |
| 256 |    565.704919 |    131.252274 | Matt Crook                                                                                                                                                                      |
| 257 |    275.251332 |    532.919184 | Christoph Schomburg                                                                                                                                                             |
| 258 |    150.028385 |     54.826078 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 259 |    777.383897 |    600.159416 | Gareth Monger                                                                                                                                                                   |
| 260 |    896.846455 |    584.304022 | Joanna Wolfe                                                                                                                                                                    |
| 261 |    426.190190 |    643.488284 | Zimices                                                                                                                                                                         |
| 262 |    974.884749 |    467.469533 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                                 |
| 263 |    969.140559 |    667.440199 | Tasman Dixon                                                                                                                                                                    |
| 264 |    358.204707 |    575.896685 | Zimices                                                                                                                                                                         |
| 265 |     18.527044 |    682.373181 | Chris huh                                                                                                                                                                       |
| 266 |    371.509610 |    629.438261 | NA                                                                                                                                                                              |
| 267 |    738.640410 |    533.143779 | Tasman Dixon                                                                                                                                                                    |
| 268 |    759.646322 |    699.271623 | NA                                                                                                                                                                              |
| 269 |    773.068810 |    486.471979 | NA                                                                                                                                                                              |
| 270 |    765.100979 |     37.469512 | Margot Michaud                                                                                                                                                                  |
| 271 |    912.231489 |    464.465539 | NA                                                                                                                                                                              |
| 272 |    406.758409 |    614.065023 | NA                                                                                                                                                                              |
| 273 |    712.527195 |    399.697520 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                                    |
| 274 |     13.924405 |    292.870840 | T. Michael Keesey (after Kukalová)                                                                                                                                              |
| 275 |    355.076514 |    352.284723 | Chris huh                                                                                                                                                                       |
| 276 |    571.063947 |    713.178196 | Melissa Broussard                                                                                                                                                               |
| 277 |    862.501280 |     32.788776 | Milton Tan                                                                                                                                                                      |
| 278 |   1014.106969 |     70.455220 | Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey)                                                                                                                |
| 279 |    272.538210 |    653.617789 | Smokeybjb (modified by Mike Keesey)                                                                                                                                             |
| 280 |    191.977379 |    435.603807 | T. Michael Keesey                                                                                                                                                               |
| 281 |    102.229531 |    736.313451 | Ferran Sayol                                                                                                                                                                    |
| 282 |    280.133886 |    367.342702 | Armin Reindl                                                                                                                                                                    |
| 283 |    591.476068 |    496.363176 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 284 |    695.841764 |    172.539909 | Rebecca Groom                                                                                                                                                                   |
| 285 |    429.413613 |    360.101707 | John Curtis (vectorized by T. Michael Keesey)                                                                                                                                   |
| 286 |    311.144700 |    334.767014 | Tasman Dixon                                                                                                                                                                    |
| 287 |     84.553447 |    662.036234 | NA                                                                                                                                                                              |
| 288 |    812.015968 |    654.130111 | NA                                                                                                                                                                              |
| 289 |   1015.046547 |    130.084648 | Zimices                                                                                                                                                                         |
| 290 |    314.942525 |    787.086129 | Mathieu Basille                                                                                                                                                                 |
| 291 |    336.851046 |    367.536554 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 292 |    722.034306 |    269.358993 | Jagged Fang Designs                                                                                                                                                             |
| 293 |    580.485572 |     17.007949 | Lukasiniho                                                                                                                                                                      |
| 294 |    312.830748 |      4.367794 | Steven Traver                                                                                                                                                                   |
| 295 |    391.394884 |    429.467873 | Zimices                                                                                                                                                                         |
| 296 |     50.452777 |     65.136753 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 297 |    708.724449 |    614.189117 | Scott Reid                                                                                                                                                                      |
| 298 |    786.034676 |    712.252978 | Dr. Thomas G. Barnes, USFWS                                                                                                                                                     |
| 299 |   1011.622314 |    203.271444 | NA                                                                                                                                                                              |
| 300 |     16.427371 |    427.643010 | Noah Schlottman, photo by Gustav Paulay for Moorea Biocode                                                                                                                      |
| 301 |   1019.700633 |    165.452179 | Campbell Fleming                                                                                                                                                                |
| 302 |    286.642547 |    258.482065 | Markus A. Grohme                                                                                                                                                                |
| 303 |    584.296783 |     76.011533 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                               |
| 304 |    907.344676 |    442.710520 | Margot Michaud                                                                                                                                                                  |
| 305 |    673.426711 |    131.996802 | Margot Michaud                                                                                                                                                                  |
| 306 |    416.343244 |     90.537450 | Nobu Tamura                                                                                                                                                                     |
| 307 |    821.938221 |    255.179762 | T. Michael Keesey                                                                                                                                                               |
| 308 |   1012.764707 |    409.176176 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 309 |    620.300393 |    502.969840 | Zimices                                                                                                                                                                         |
| 310 |    505.975550 |    564.778287 | Noah Schlottman, photo by Casey Dunn                                                                                                                                            |
| 311 |     24.897595 |    233.919815 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 312 |    228.528710 |    309.807932 | Margot Michaud                                                                                                                                                                  |
| 313 |    794.164354 |    787.858248 | Becky Barnes                                                                                                                                                                    |
| 314 |    866.606704 |    711.248894 | T. Michael Keesey                                                                                                                                                               |
| 315 |   1000.186709 |    170.339827 | Gareth Monger                                                                                                                                                                   |
| 316 |    572.363186 |    589.153320 | Zimices                                                                                                                                                                         |
| 317 |    355.467068 |    423.196510 | Dein Freund der Baum (vectorized by T. Michael Keesey)                                                                                                                          |
| 318 |    600.930662 |     13.054877 | Steven Traver                                                                                                                                                                   |
| 319 |    556.263838 |    597.865073 | Chris huh                                                                                                                                                                       |
| 320 |    560.601112 |     31.778332 | Zimices                                                                                                                                                                         |
| 321 |    750.146836 |    282.870190 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 322 |    889.337338 |    163.787722 | Kanchi Nanjo                                                                                                                                                                    |
| 323 |    216.540119 |    642.715905 | NA                                                                                                                                                                              |
| 324 |    381.990550 |     89.863500 | Tasman Dixon                                                                                                                                                                    |
| 325 |    150.648382 |    225.632676 | Markus A. Grohme                                                                                                                                                                |
| 326 |    271.688834 |     54.112112 | Xavier A. Jenkins, Gabriel Ugueto                                                                                                                                               |
| 327 |    891.618358 |    209.601740 | Terpsichores                                                                                                                                                                    |
| 328 |    800.967788 |    449.093833 | Manabu Sakamoto                                                                                                                                                                 |
| 329 |    883.082019 |    783.358110 | Gareth Monger                                                                                                                                                                   |
| 330 |    567.101799 |    294.312864 | Ferran Sayol                                                                                                                                                                    |
| 331 |    890.007421 |    125.286723 | Steven Traver                                                                                                                                                                   |
| 332 |    475.387726 |     11.272212 | Kosta Mumcuoglu (vectorized by T. Michael Keesey)                                                                                                                               |
| 333 |    870.560984 |    743.217059 | Matt Crook                                                                                                                                                                      |
| 334 |    258.358470 |     62.037312 | Sergio A. Muñoz-Gómez                                                                                                                                                           |
| 335 |     20.629984 |    758.761664 | Emily Willoughby                                                                                                                                                                |
| 336 |    214.201453 |     11.180137 | Chris huh                                                                                                                                                                       |
| 337 |    267.968596 |    521.161279 | Matt Crook                                                                                                                                                                      |
| 338 |     88.602924 |    116.402555 | NA                                                                                                                                                                              |
| 339 |    797.931467 |    193.224742 | Emily Jane McTavish, from Haeckel, E. H. P. A. (1904).Kunstformen der Natur. Bibliographisches                                                                                  |
| 340 |    256.055610 |    546.060279 | Kevin Sánchez                                                                                                                                                                   |
| 341 |    647.479609 |    492.540664 | Steven Traver                                                                                                                                                                   |
| 342 |    999.707327 |    644.167418 | Emily Willoughby                                                                                                                                                                |
| 343 |    630.989377 |    294.665867 | Andrew A. Farke                                                                                                                                                                 |
| 344 |    787.761873 |    379.198332 | Christine Axon                                                                                                                                                                  |
| 345 |    215.430566 |    591.223764 | Zimices                                                                                                                                                                         |
| 346 |    574.529364 |    277.600760 | Beth Reinke                                                                                                                                                                     |
| 347 |    998.507450 |     61.305319 | Tasman Dixon                                                                                                                                                                    |
| 348 |    115.255263 |    712.676807 | Margot Michaud                                                                                                                                                                  |
| 349 |    762.574973 |    500.889542 | Harold N Eyster                                                                                                                                                                 |
| 350 |    556.684038 |    727.203345 | Fernando Carezzano                                                                                                                                                              |
| 351 |    791.393161 |    401.230110 | Timothy Knepp of the U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                          |
| 352 |    502.937270 |     23.955151 | Jebulon (vectorized by T. Michael Keesey)                                                                                                                                       |
| 353 |    242.066070 |    499.120566 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                                 |
| 354 |    453.539674 |    371.935313 | Lily Hughes                                                                                                                                                                     |
| 355 |    582.605003 |    649.126392 | Yan Wong                                                                                                                                                                        |
| 356 |    637.827308 |    425.540227 | Matt Crook                                                                                                                                                                      |
| 357 |    542.843154 |    787.081071 | Zimices                                                                                                                                                                         |
| 358 |    151.682189 |    791.941768 | Scott Hartman                                                                                                                                                                   |
| 359 |    672.704599 |     94.044712 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                               |
| 360 |      6.658311 |    663.766045 | Nancy Wyman (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                     |
| 361 |    469.502829 |    603.064593 | Joanna Wolfe                                                                                                                                                                    |
| 362 |    912.789923 |    297.855467 | Margot Michaud                                                                                                                                                                  |
| 363 |    727.910694 |    316.974914 | Tambja (vectorized by T. Michael Keesey)                                                                                                                                        |
| 364 |   1002.452474 |     33.617073 | Ingo Braasch                                                                                                                                                                    |
| 365 |     84.601988 |    332.807824 | Mathew Wedel                                                                                                                                                                    |
| 366 |    309.658822 |     60.468966 | Michele M Tobias                                                                                                                                                                |
| 367 |    745.149820 |     18.058142 | Margot Michaud                                                                                                                                                                  |
| 368 |    232.815455 |    773.252549 | Jaime Chirinos (vectorized by T. Michael Keesey)                                                                                                                                |
| 369 |     68.577535 |    745.285379 | Margot Michaud                                                                                                                                                                  |
| 370 |    209.915744 |    659.739529 | Steve Hillebrand/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                                              |
| 371 |    800.577646 |    179.139189 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 372 |    378.127765 |    129.630623 | Becky Barnes                                                                                                                                                                    |
| 373 |    780.575816 |    327.774787 | Alexander Schmidt-Lebuhn                                                                                                                                                        |
| 374 |    966.526861 |    505.045805 | Konsta Happonen, from a CC-BY-NC image by pelhonen on iNaturalist                                                                                                               |
| 375 |    507.672226 |    155.092444 | Christoph Schomburg                                                                                                                                                             |
| 376 |    529.209800 |    593.922449 | Mike Keesey (vectorization) and Vaibhavcho (photography)                                                                                                                        |
| 377 |    215.589359 |    700.810045 | NA                                                                                                                                                                              |
| 378 |    895.179216 |    599.676868 | Maija Karala                                                                                                                                                                    |
| 379 |    413.406325 |    567.636138 | Iain Reid                                                                                                                                                                       |
| 380 |    190.136058 |    136.703173 | Collin Gross                                                                                                                                                                    |
| 381 |     28.535452 |     82.853102 | Margot Michaud                                                                                                                                                                  |
| 382 |    203.705722 |    127.461337 | Anthony Caravaggi                                                                                                                                                               |
| 383 |    157.586371 |    176.135096 | Sarah Werning                                                                                                                                                                   |
| 384 |    924.210980 |     16.100043 | Chris huh                                                                                                                                                                       |
| 385 |    103.783444 |    255.775106 | Nobu Tamura                                                                                                                                                                     |
| 386 |    237.321988 |    423.070962 | Gustav Mützel                                                                                                                                                                   |
| 387 |    182.934981 |     21.563685 | Zimices                                                                                                                                                                         |
| 388 |    878.864048 |    109.617073 | Arthur S. Brum                                                                                                                                                                  |
| 389 |    192.276279 |    199.279954 | T. Michael Keesey (after Tillyard)                                                                                                                                              |
| 390 |    789.843254 |    235.618681 | Gareth Monger                                                                                                                                                                   |
| 391 |    551.168783 |    292.713715 | Katie S. Collins                                                                                                                                                                |
| 392 |    744.062118 |    261.944666 | Scott Hartman                                                                                                                                                                   |
| 393 |    444.140086 |    730.168750 | Sean McCann                                                                                                                                                                     |
| 394 |    217.419988 |    609.914631 | Dennis C. Murphy, after <https://commons.wikimedia.org/wiki/File:Queensland_State_Archives_2981_Cane_toads_at_the_Meringa_Sugar_Experiment_Station_North_Queensland_c_1935.png> |
| 395 |    764.853887 |    198.815724 | Matt Crook                                                                                                                                                                      |
| 396 |    458.320815 |    781.100844 | Beth Reinke                                                                                                                                                                     |
| 397 |    964.229065 |    640.602793 | Margot Michaud                                                                                                                                                                  |
| 398 |    950.409669 |     53.088686 | Ferran Sayol                                                                                                                                                                    |
| 399 |    775.796591 |    699.917761 | Margot Michaud                                                                                                                                                                  |
| 400 |     98.758328 |    129.586940 | Raven Amos                                                                                                                                                                      |
| 401 |    196.781857 |    274.864349 | Zimices                                                                                                                                                                         |
| 402 |    238.194432 |    701.409302 | Tasman Dixon                                                                                                                                                                    |
| 403 |    113.256903 |     91.066458 | Ghedoghedo                                                                                                                                                                      |
| 404 |    443.738079 |    562.254633 | Kailah Thorn & Mark Hutchinson                                                                                                                                                  |
| 405 |    911.055700 |    543.011821 | Gareth Monger                                                                                                                                                                   |
| 406 |    982.056131 |    527.972442 | Lily Hughes                                                                                                                                                                     |
| 407 |    667.664927 |     18.712361 | NA                                                                                                                                                                              |
| 408 |     12.184702 |     47.740009 | Kamil S. Jaron                                                                                                                                                                  |
| 409 |    373.166731 |     51.252756 | Jaime Headden                                                                                                                                                                   |
| 410 |    406.775024 |    785.825195 | Gareth Monger                                                                                                                                                                   |
| 411 |    277.001610 |    424.426512 | Cathy                                                                                                                                                                           |
| 412 |    190.497465 |    780.338315 | NA                                                                                                                                                                              |
| 413 |    207.273706 |    183.354102 | Yan Wong                                                                                                                                                                        |
| 414 |    625.579451 |    754.381197 | Andrew A. Farke                                                                                                                                                                 |
| 415 |     19.839812 |    487.576358 | Gareth Monger                                                                                                                                                                   |
| 416 |     94.632643 |    427.061761 | Scott Hartman                                                                                                                                                                   |
| 417 |    774.857512 |    726.864133 | xgirouxb                                                                                                                                                                        |
| 418 |    751.391317 |     80.427075 | Zimices                                                                                                                                                                         |
| 419 |    280.805596 |    399.036075 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 420 |     41.000067 |    164.787703 | Mathilde Cordellier                                                                                                                                                             |
| 421 |    506.448067 |     10.012696 | Renato Santos                                                                                                                                                                   |
| 422 |    812.676646 |    449.331324 | Scott Hartman                                                                                                                                                                   |
| 423 |    329.509808 |    467.570208 | Conty                                                                                                                                                                           |
| 424 |    813.938990 |    206.920223 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                                   |
| 425 |    809.466682 |    465.848907 | Jagged Fang Designs                                                                                                                                                             |
| 426 |   1005.411144 |    219.559726 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 427 |    232.935121 |    611.387546 | Andrew A. Farke, shell lines added by Yan Wong                                                                                                                                  |
| 428 |    968.781556 |    620.466344 | Gareth Monger                                                                                                                                                                   |
| 429 |    818.300776 |    608.080724 | C. Camilo Julián-Caballero                                                                                                                                                      |
| 430 |     70.917796 |    277.435032 | Matt Crook                                                                                                                                                                      |
| 431 |    637.593040 |      6.086067 | Chris huh                                                                                                                                                                       |
| 432 |    204.807527 |    794.210945 | John Conway                                                                                                                                                                     |
| 433 |    967.111619 |    526.868599 | Steve Hillebrand/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                                              |
| 434 |    712.592584 |    548.266116 | Matt Crook                                                                                                                                                                      |
| 435 |     24.221666 |     95.709841 | Matt Crook                                                                                                                                                                      |
| 436 |    338.165964 |    583.108235 | Ingo Braasch                                                                                                                                                                    |
| 437 |    646.376204 |    777.544125 | Rainer Schoch                                                                                                                                                                   |
| 438 |    749.394805 |    789.001203 | Christoph Schomburg                                                                                                                                                             |
| 439 |    153.044103 |    132.887695 | Katie S. Collins                                                                                                                                                                |
| 440 |    885.594917 |     35.642100 | FunkMonk                                                                                                                                                                        |
| 441 |    981.448323 |    186.786764 | James R. Spotila and Ray Chatterji                                                                                                                                              |
| 442 |    780.366708 |     71.570832 | Kamil S. Jaron                                                                                                                                                                  |
| 443 |    307.508575 |    270.761992 | Felix Vaux                                                                                                                                                                      |
| 444 |    220.342699 |    191.085656 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 445 |   1009.329095 |    776.443166 | Kamil S. Jaron                                                                                                                                                                  |
| 446 |    969.629853 |     18.951942 | Zimices                                                                                                                                                                         |
| 447 |    229.485758 |     83.017245 | Matt Crook                                                                                                                                                                      |
| 448 |     46.013424 |     30.522252 | Beth Reinke                                                                                                                                                                     |
| 449 |    602.959044 |    423.324169 | Collin Gross                                                                                                                                                                    |
| 450 |     12.789557 |    357.340774 | T. Michael Keesey (vectorization) and Larry Loos (photography)                                                                                                                  |
| 451 |    749.496329 |    138.672476 | Birgit Lang; based on a drawing by C.L. Koch                                                                                                                                    |
| 452 |    429.753837 |    673.122716 | Zimices                                                                                                                                                                         |
| 453 |    291.072784 |    430.459458 | Margot Michaud                                                                                                                                                                  |
| 454 |    236.584533 |     15.042407 | Matt Crook                                                                                                                                                                      |
| 455 |    751.164696 |    230.706226 | T. Michael Keesey                                                                                                                                                               |
| 456 |    176.097302 |    302.111162 | Ferran Sayol                                                                                                                                                                    |
| 457 |    216.025687 |     97.418087 | Sam Fraser-Smith (vectorized by T. Michael Keesey)                                                                                                                              |
| 458 |   1006.708999 |    665.243571 | Matt Crook                                                                                                                                                                      |
| 459 |    926.475676 |    243.255295 | Ferran Sayol                                                                                                                                                                    |
| 460 |    888.623643 |     44.444691 | Felix Vaux                                                                                                                                                                      |
| 461 |    639.186380 |    119.876329 | Chris huh                                                                                                                                                                       |
| 462 |    526.990389 |    193.138512 | (after McCulloch 1908)                                                                                                                                                          |
| 463 |    291.734095 |    180.405308 | Matt Crook                                                                                                                                                                      |
| 464 |    623.178906 |    701.739167 | NA                                                                                                                                                                              |
| 465 |    572.284283 |    183.496437 | Steven Traver                                                                                                                                                                   |
| 466 |    262.868633 |    124.576801 | Terpsichores                                                                                                                                                                    |
| 467 |     79.225647 |    440.663286 | NA                                                                                                                                                                              |
| 468 |    342.522805 |    562.435609 | Milton Tan                                                                                                                                                                      |
| 469 |    373.173277 |    111.825450 | Zimices                                                                                                                                                                         |
| 470 |    281.596951 |    637.707891 | Mali’o Kodis, photograph by John Slapcinsky                                                                                                                                     |
| 471 |      6.225625 |    326.828307 | T. Michael Keesey                                                                                                                                                               |
| 472 |    492.796992 |    252.690411 | Jagged Fang Designs                                                                                                                                                             |
| 473 |    638.795080 |    592.072064 | Zimices                                                                                                                                                                         |
| 474 |    348.354221 |    653.466413 | Zimices                                                                                                                                                                         |
| 475 |     27.826318 |    190.525157 | Benjamint444                                                                                                                                                                    |
| 476 |    672.192133 |    121.755918 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 477 |     19.717512 |    390.185688 | Jagged Fang Designs                                                                                                                                                             |
| 478 |    676.203619 |    536.991007 | Christoph Schomburg                                                                                                                                                             |
| 479 |    374.435188 |     20.293947 | NA                                                                                                                                                                              |
| 480 |    549.132076 |     17.159281 | Armin Reindl                                                                                                                                                                    |
| 481 |    156.593388 |    755.894499 | L. Shyamal                                                                                                                                                                      |
| 482 |    153.726301 |    740.271876 | Matt Crook                                                                                                                                                                      |
| 483 |    407.072788 |    437.742148 | Rebecca Groom                                                                                                                                                                   |
| 484 |    846.514712 |    320.138061 | Jagged Fang Designs                                                                                                                                                             |
| 485 |    577.700591 |    529.915643 | Milton Tan                                                                                                                                                                      |
| 486 |    736.374807 |    300.761555 | Margot Michaud                                                                                                                                                                  |
| 487 |    349.659448 |    291.628349 | Steven Coombs                                                                                                                                                                   |
| 488 |    516.745281 |    559.749364 | Zimices                                                                                                                                                                         |
| 489 |    805.689061 |    669.702351 | Ghedo and T. Michael Keesey                                                                                                                                                     |
| 490 |    996.835457 |    480.580369 | Matt Crook                                                                                                                                                                      |
| 491 |    388.733247 |     65.652744 | Chuanixn Yu                                                                                                                                                                     |
| 492 |    242.202834 |    637.624561 | Scott Hartman                                                                                                                                                                   |
| 493 |    234.294868 |    119.794535 | Joanna Wolfe                                                                                                                                                                    |
| 494 |     80.481503 |    679.439233 | Lily Hughes                                                                                                                                                                     |
| 495 |    275.805867 |    330.073576 | Jay Matternes, vectorized by Zimices                                                                                                                                            |
| 496 |    576.623376 |    636.200486 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 497 |    535.615239 |     70.810734 | NA                                                                                                                                                                              |
| 498 |     92.384059 |    546.576137 | Gareth Monger                                                                                                                                                                   |
| 499 |    603.389678 |    240.879538 | Matt Crook                                                                                                                                                                      |
| 500 |    983.551540 |    548.249453 | Joanna Wolfe                                                                                                                                                                    |
| 501 |    684.856353 |    572.134880 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                         |
| 502 |    480.037049 |    421.572318 | Ferran Sayol                                                                                                                                                                    |
| 503 |    246.843135 |    306.941381 | Cagri Cevrim                                                                                                                                                                    |
| 504 |    349.353880 |     68.233048 | S.Martini                                                                                                                                                                       |
| 505 |    545.634328 |     86.671540 | Pete Buchholz                                                                                                                                                                   |
| 506 |    993.390617 |    258.249515 | Yan Wong                                                                                                                                                                        |
| 507 |    797.248671 |    321.161194 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 508 |    851.902102 |    118.121139 | Gareth Monger                                                                                                                                                                   |
| 509 |     71.622746 |    605.051044 | Mike Hanson                                                                                                                                                                     |
| 510 |    734.520252 |    120.129802 | NA                                                                                                                                                                              |
| 511 |    607.718114 |    223.985423 | Armin Reindl                                                                                                                                                                    |
| 512 |    543.838816 |    699.474760 | Jagged Fang Designs                                                                                                                                                             |
| 513 |    683.753910 |    725.339552 | NA                                                                                                                                                                              |
| 514 |    736.475353 |    746.972063 | Margot Michaud                                                                                                                                                                  |
| 515 |     26.024273 |    704.784141 | Noah Schlottman, photo by Reinhard Jahn                                                                                                                                         |
| 516 |    325.284102 |    440.404581 | David Orr                                                                                                                                                                       |
| 517 |    154.099812 |    781.682312 | Tasman Dixon                                                                                                                                                                    |
| 518 |     50.641889 |    782.813690 | Matt Crook                                                                                                                                                                      |
| 519 |    392.506696 |    333.955356 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 520 |     30.047353 |    502.166461 | Kai R. Caspar                                                                                                                                                                   |
| 521 |    677.351243 |      8.580352 | Gareth Monger                                                                                                                                                                   |
| 522 |    455.728639 |     38.997150 | Armin Reindl                                                                                                                                                                    |
| 523 |    665.170918 |    629.241805 | Tauana J. Cunha                                                                                                                                                                 |
| 524 |    422.617739 |    546.947662 | Tauana J. Cunha                                                                                                                                                                 |
| 525 |    767.633016 |    256.908757 | Tasman Dixon                                                                                                                                                                    |
| 526 |    485.997479 |    694.578124 | ArtFavor & annaleeblysse                                                                                                                                                        |
| 527 |    319.348704 |    656.399163 | Christoph Schomburg                                                                                                                                                             |
| 528 |    837.822551 |    447.656358 | Zimices                                                                                                                                                                         |
| 529 |    341.145708 |    263.539068 | Matt Martyniuk                                                                                                                                                                  |
| 530 |    849.842013 |    710.327983 | Margot Michaud                                                                                                                                                                  |
| 531 |    310.823039 |    467.224773 | NA                                                                                                                                                                              |
| 532 |    955.427098 |    721.281864 | David Tana                                                                                                                                                                      |
| 533 |    963.608598 |    796.841404 | Ignacio Contreras                                                                                                                                                               |
| 534 |    416.395311 |    388.591097 | Steven Traver                                                                                                                                                                   |
| 535 |    330.301389 |    339.242856 | Dmitry Bogdanov                                                                                                                                                                 |
| 536 |    176.577801 |    188.249383 | Peileppe                                                                                                                                                                        |
| 537 |    409.629361 |    663.960281 | Gareth Monger                                                                                                                                                                   |
| 538 |    720.955638 |    295.092878 | L. Shyamal                                                                                                                                                                      |
| 539 |    253.087392 |    389.994861 | NA                                                                                                                                                                              |
| 540 |      8.074361 |    315.777399 | Margot Michaud                                                                                                                                                                  |
| 541 |    812.907692 |    471.446563 | U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                                               |
| 542 |      8.288934 |    207.833467 | NA                                                                                                                                                                              |
| 543 |    251.110820 |    411.999946 | NA                                                                                                                                                                              |
| 544 |    593.478895 |     88.876642 | Robert Gay                                                                                                                                                                      |
| 545 |    677.627099 |     79.379775 | Margot Michaud                                                                                                                                                                  |
| 546 |    790.536326 |    310.311366 | NA                                                                                                                                                                              |
| 547 |    485.601998 |     55.421756 | Matt Crook                                                                                                                                                                      |
| 548 |    310.267461 |    228.589625 | Gareth Monger                                                                                                                                                                   |
| 549 |    696.022662 |    468.479769 | Stanton F. Fink, vectorized by Zimices                                                                                                                                          |
| 550 |    301.458241 |    699.506927 | Tasman Dixon                                                                                                                                                                    |
| 551 |     55.816174 |     45.865123 | Jagged Fang Designs                                                                                                                                                             |
| 552 |    284.920914 |    188.825484 | Chris huh                                                                                                                                                                       |
| 553 |    438.187257 |    517.208199 | Matt Crook                                                                                                                                                                      |
| 554 |    687.648055 |    320.819173 | Michelle Site                                                                                                                                                                   |
| 555 |    233.417344 |    490.284229 | Timothy Knepp (vectorized by T. Michael Keesey)                                                                                                                                 |
| 556 |    592.669987 |    754.175202 | Noah Schlottman, photo by Museum of Geology, University of Tartu                                                                                                                |
| 557 |    376.185616 |     97.291628 | Iain Reid                                                                                                                                                                       |
| 558 |    231.183980 |    681.118601 | Steven Traver                                                                                                                                                                   |
| 559 |    238.553429 |    198.547703 | Zimices                                                                                                                                                                         |
| 560 |    471.964650 |    437.497980 | C. Camilo Julián-Caballero                                                                                                                                                      |
| 561 |     62.318737 |     44.114136 | Matt Crook                                                                                                                                                                      |
| 562 |    798.989391 |    253.480041 | Zimices                                                                                                                                                                         |
| 563 |    999.469393 |    146.472622 | Matt Crook                                                                                                                                                                      |
| 564 |    241.901696 |    721.277154 | Andrew Farke and Joseph Sertich                                                                                                                                                 |
| 565 |    231.698896 |    622.237712 | B. Duygu Özpolat                                                                                                                                                                |
| 566 |    696.046139 |    542.550968 | Chris huh                                                                                                                                                                       |
| 567 |    401.795229 |    147.874688 | Jagged Fang Designs                                                                                                                                                             |
| 568 |    296.235664 |    625.374966 | Karla Martinez                                                                                                                                                                  |
| 569 |     44.690035 |    201.040239 | Margot Michaud                                                                                                                                                                  |
| 570 |    488.772858 |    708.907890 | Ferran Sayol                                                                                                                                                                    |
| 571 |    550.391462 |    335.046461 | NA                                                                                                                                                                              |
| 572 |    984.050908 |     95.893808 | C. W. Nash (illustration) and Timothy J. Bartley (silhouette)                                                                                                                   |
| 573 |    960.250899 |    792.325241 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                           |
| 574 |    960.703296 |     97.586348 | T. Michael Keesey                                                                                                                                                               |
| 575 |    286.935523 |     57.035298 | U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                                               |
| 576 |    366.882225 |    694.996945 | Margot Michaud                                                                                                                                                                  |
| 577 |    580.992345 |    100.835245 | FunkMonk                                                                                                                                                                        |
| 578 |    932.146588 |    796.108812 | Steven Coombs                                                                                                                                                                   |
| 579 |    397.360188 |    629.211477 | Gareth Monger                                                                                                                                                                   |
| 580 |    192.989415 |    658.941484 | Felix Vaux                                                                                                                                                                      |
| 581 |    983.565531 |    761.181853 | Zimices                                                                                                                                                                         |
| 582 |    251.859811 |    487.308165 | Roderic Page and Lois Page                                                                                                                                                      |
| 583 |     80.532364 |    715.672693 | \[unknown\]                                                                                                                                                                     |
| 584 |    654.307090 |    229.007403 | Matt Crook                                                                                                                                                                      |
| 585 |    394.946846 |    618.036217 | kreidefossilien.de                                                                                                                                                              |
| 586 |    140.991162 |    666.404355 | Matt Crook                                                                                                                                                                      |
| 587 |    124.125626 |     85.265604 | Chuanixn Yu                                                                                                                                                                     |
| 588 |    150.153954 |    493.236039 | Tasman Dixon                                                                                                                                                                    |
| 589 |    567.068433 |     78.050586 | Jay Matternes, vectorized by Zimices                                                                                                                                            |
| 590 |    571.168546 |    561.279514 | Steven Traver                                                                                                                                                                   |
| 591 |    750.521523 |    609.361980 | Zimices                                                                                                                                                                         |
| 592 |    224.709300 |    728.210709 | Rebecca Groom                                                                                                                                                                   |
| 593 |    824.864509 |    404.727936 | Zimices                                                                                                                                                                         |
| 594 |    675.846731 |    228.908293 | Matt Crook                                                                                                                                                                      |
| 595 |    240.529722 |     78.912593 | Steven Traver                                                                                                                                                                   |
| 596 |    276.140999 |    503.023503 | Michael Scroggie                                                                                                                                                                |
| 597 |    561.541820 |    442.146949 | Kamil S. Jaron                                                                                                                                                                  |
| 598 |    761.026886 |    360.641164 | Matt Crook                                                                                                                                                                      |
| 599 |    800.068122 |    634.768094 | Michael B. H. (vectorized by T. Michael Keesey)                                                                                                                                 |
| 600 |    781.942330 |    408.254558 | T. Michael Keesey                                                                                                                                                               |
| 601 |    329.530630 |    667.279581 | Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus                                                        |
| 602 |    483.802756 |    207.416736 | Michael Ströck (vectorized by T. Michael Keesey)                                                                                                                                |
| 603 |     71.714156 |    426.577784 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                                |
| 604 |    270.589266 |    684.655003 | Scott Reid                                                                                                                                                                      |
| 605 |    753.435849 |    721.229109 | Michelle Site                                                                                                                                                                   |
| 606 |    436.099598 |     84.519516 | Zimices                                                                                                                                                                         |
| 607 |    818.050654 |    459.235576 | Markus A. Grohme                                                                                                                                                                |
| 608 |     18.262942 |    437.133877 | Matt Crook                                                                                                                                                                      |
| 609 |    930.753791 |     78.469196 | Pete Buchholz                                                                                                                                                                   |
| 610 |    798.282981 |    478.499688 | Pete Buchholz                                                                                                                                                                   |
| 611 |    139.987881 |    151.595365 | Emily Willoughby                                                                                                                                                                |
| 612 |    852.466645 |    284.735291 | NA                                                                                                                                                                              |
| 613 |    514.213240 |    485.517613 | Steven Traver                                                                                                                                                                   |
| 614 |    468.648814 |    378.068219 | Steven Traver                                                                                                                                                                   |
| 615 |    582.555285 |    352.570268 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                           |
| 616 |    277.152860 |    705.796686 | Tess Linden                                                                                                                                                                     |
| 617 |    189.346720 |    634.367994 | Richard J. Harris                                                                                                                                                               |
| 618 |     56.703720 |    719.297430 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                                    |
| 619 |    492.715966 |    468.487570 | Joanna Wolfe                                                                                                                                                                    |
| 620 |    276.258329 |    556.160814 | Margot Michaud                                                                                                                                                                  |
| 621 |     71.529096 |    501.105828 | Birgit Lang                                                                                                                                                                     |
| 622 |    980.451643 |    235.898540 | Tasman Dixon                                                                                                                                                                    |
| 623 |    783.325734 |    429.998300 | Iain Reid                                                                                                                                                                       |
| 624 |    292.245891 |    198.399044 | Matt Crook                                                                                                                                                                      |
| 625 |    384.477818 |    583.715423 | Matt Crook                                                                                                                                                                      |
| 626 |    189.152021 |    649.430080 | Zimices                                                                                                                                                                         |
| 627 |    161.699950 |     37.767263 | H. F. O. March (modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel)                                                                                            |
| 628 |     25.568487 |     14.338188 | Scott Hartman                                                                                                                                                                   |
| 629 |    131.918870 |    427.194280 | NA                                                                                                                                                                              |
| 630 |    450.584053 |    641.545992 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 631 |    982.248085 |    407.588095 | Charles Doolittle Walcott (vectorized by T. Michael Keesey)                                                                                                                     |
| 632 |    937.333333 |      6.770792 | Johan Lindgren, Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe                                                                                                            |
| 633 |    867.708879 |      5.975215 | Dmitry Bogdanov                                                                                                                                                                 |
| 634 |    286.555542 |    220.883235 | Scott Hartman (vectorized by T. Michael Keesey)                                                                                                                                 |
| 635 |    310.611028 |    419.595143 | Matt Crook                                                                                                                                                                      |
| 636 |    748.389965 |    695.761099 | T. Michael Keesey                                                                                                                                                               |
| 637 |    619.083677 |    133.207851 | NA                                                                                                                                                                              |
| 638 |   1018.660215 |      8.723810 | NA                                                                                                                                                                              |
| 639 |    114.887222 |    563.403700 | Zimices                                                                                                                                                                         |
| 640 |    827.172897 |    785.348462 | Armin Reindl                                                                                                                                                                    |
| 641 |    603.021354 |    135.776900 | David Orr                                                                                                                                                                       |
| 642 |    213.080285 |    766.317288 | Ignacio Contreras                                                                                                                                                               |
| 643 |    959.107055 |    463.127515 | Steven Traver                                                                                                                                                                   |
| 644 |    959.934740 |    258.679136 | Auckland Museum                                                                                                                                                                 |
| 645 |    814.378574 |    173.491069 | Gareth Monger                                                                                                                                                                   |
| 646 |    381.930998 |    442.053926 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 647 |    291.326490 |    242.574596 | Matt Martyniuk                                                                                                                                                                  |
| 648 |    997.448032 |    784.568383 | Rebecca Groom                                                                                                                                                                   |
| 649 |    690.743957 |    204.403544 | Tauana J. Cunha                                                                                                                                                                 |
| 650 |      8.149412 |    635.007385 | Jaime Headden                                                                                                                                                                   |
| 651 |    997.794808 |    725.442411 | Alexander Schmidt-Lebuhn                                                                                                                                                        |
| 652 |    265.778841 |    675.539498 | Scott Hartman                                                                                                                                                                   |
| 653 |    542.169973 |     30.978836 | Ferran Sayol                                                                                                                                                                    |
| 654 |    690.688361 |    417.457898 | Smokeybjb                                                                                                                                                                       |
| 655 |     27.636834 |    135.612877 | Chris huh                                                                                                                                                                       |
| 656 |    303.147617 |    478.679598 | Matt Martyniuk                                                                                                                                                                  |
| 657 |    908.927492 |    252.372884 | Margot Michaud                                                                                                                                                                  |
| 658 |    497.133355 |    454.722058 | Liftarn                                                                                                                                                                         |
| 659 |    639.471168 |    306.555574 | Yan Wong from illustration by Jules Richard (1907)                                                                                                                              |
| 660 |    741.090104 |    255.405097 | Frederick William Frohawk (vectorized by T. Michael Keesey)                                                                                                                     |
| 661 |    279.824799 |    783.147073 | Zimices                                                                                                                                                                         |
| 662 |    443.520727 |    612.784553 | Jagged Fang Designs                                                                                                                                                             |
| 663 |    661.053897 |    237.109449 | Kanchi Nanjo                                                                                                                                                                    |
| 664 |    762.801911 |    794.066861 | Nicholas J. Czaplewski, vectorized by Zimices                                                                                                                                   |
| 665 |    144.135095 |    644.121619 | Mike Keesey (vectorization) and Vaibhavcho (photography)                                                                                                                        |
| 666 |    254.432430 |    345.305491 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 667 |      9.230885 |    235.457301 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 668 |    874.019225 |    292.204132 | NA                                                                                                                                                                              |
| 669 |    721.841083 |    632.466162 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                               |
| 670 |    302.304889 |    351.112249 | T. Michael Keesey                                                                                                                                                               |
| 671 |    246.079080 |    141.090186 | Margot Michaud                                                                                                                                                                  |
| 672 |    262.190376 |    474.199260 | Andrew A. Farke                                                                                                                                                                 |
| 673 |    553.265293 |    304.758194 | Robert Bruce Horsfall (vectorized by T. Michael Keesey)                                                                                                                         |
| 674 |    938.967478 |     49.397175 | Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org)                                                                                    |
| 675 |    902.371624 |     18.030395 | Jaime Headden                                                                                                                                                                   |
| 676 |    175.775388 |    163.834289 | Zimices                                                                                                                                                                         |
| 677 |    861.067966 |    510.171115 | Nick Schooler                                                                                                                                                                   |
| 678 |   1002.747191 |    624.858640 | Michael Scroggie                                                                                                                                                                |
| 679 |    444.372216 |    752.976518 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey)           |
| 680 |    661.029218 |    214.264854 | xgirouxb                                                                                                                                                                        |
| 681 |    496.634596 |    667.556393 | Margret Flinsch, vectorized by Zimices                                                                                                                                          |
| 682 |    779.451525 |    542.086936 | T. Michael Keesey                                                                                                                                                               |
| 683 |    889.812109 |     20.107538 | Manabu Bessho-Uehara                                                                                                                                                            |
| 684 |    509.663076 |    785.843736 | T. Michael Keesey                                                                                                                                                               |
| 685 |     29.677422 |     58.534031 | T. Michael Keesey (after Monika Betley)                                                                                                                                         |
| 686 |    726.114468 |     14.166605 | Steven Traver                                                                                                                                                                   |
| 687 |    193.151333 |    245.943229 | Steven Traver                                                                                                                                                                   |
| 688 |    880.921166 |    131.306038 | FJDegrange                                                                                                                                                                      |
| 689 |    144.826727 |    590.401475 | Tasman Dixon                                                                                                                                                                    |
| 690 |    370.928353 |    432.824543 | Dantheman9758 (vectorized by T. Michael Keesey)                                                                                                                                 |
| 691 |    350.200454 |     32.697630 | Margot Michaud                                                                                                                                                                  |
| 692 |     72.310420 |    700.752709 | Michael Scroggie                                                                                                                                                                |
| 693 |    413.124360 |    698.093770 | Robert Gay                                                                                                                                                                      |
| 694 |    214.991219 |    564.555971 | Sarah Alewijnse                                                                                                                                                                 |
| 695 |    402.200243 |    762.639411 | Abraão Leite                                                                                                                                                                    |
| 696 |    625.259901 |    476.821470 | Steven Coombs                                                                                                                                                                   |
| 697 |    977.391887 |     55.561382 | Margot Michaud                                                                                                                                                                  |
| 698 |    912.782403 |    709.238775 | Jagged Fang Designs                                                                                                                                                             |
| 699 |    279.095138 |    570.063197 | Caio Bernardes, vectorized by Zimices                                                                                                                                           |
| 700 |    664.404833 |    795.236761 | Zsoldos Márton (vectorized by T. Michael Keesey)                                                                                                                                |
| 701 |    287.986453 |    755.753066 | Matt Crook                                                                                                                                                                      |
| 702 |    966.852738 |    103.738413 | Jagged Fang Designs                                                                                                                                                             |
| 703 |      9.865701 |    494.268847 | Margot Michaud                                                                                                                                                                  |
| 704 |    250.685270 |     46.153601 | Matt Crook                                                                                                                                                                      |
| 705 |    672.371436 |    718.521495 | Melissa Broussard                                                                                                                                                               |
| 706 |    935.470430 |    113.370818 | Scott Hartman                                                                                                                                                                   |
| 707 |    771.653497 |    350.247269 | Ville-Veikko Sinkkonen                                                                                                                                                          |
| 708 |    640.107106 |    502.984402 | Berivan Temiz                                                                                                                                                                   |
| 709 |    829.968695 |    473.691013 | Jack Mayer Wood                                                                                                                                                                 |
| 710 |    701.635053 |    360.083116 | Matt Crook                                                                                                                                                                      |
| 711 |    633.790450 |    551.707366 | Margot Michaud                                                                                                                                                                  |
| 712 |    484.736863 |    200.559943 | Michael Scroggie                                                                                                                                                                |
| 713 |     27.396395 |    479.025343 | Markus A. Grohme                                                                                                                                                                |
| 714 |    992.730732 |    566.093326 | Scott Hartman                                                                                                                                                                   |
| 715 |    916.976122 |    729.260459 | NA                                                                                                                                                                              |
| 716 |     14.342843 |    128.399848 | Gareth Monger                                                                                                                                                                   |
| 717 |    776.472921 |    523.850607 | Noah Schlottman, photo by Museum of Geology, University of Tartu                                                                                                                |
| 718 |    434.633205 |    604.151255 | Martin R. Smith, after Skovsted et al 2015                                                                                                                                      |
| 719 |    668.747519 |    572.213480 | Scott Hartman                                                                                                                                                                   |
| 720 |     30.262830 |     22.328929 | S.Martini                                                                                                                                                                       |
| 721 |     52.516154 |     55.359362 | Margot Michaud                                                                                                                                                                  |
| 722 |    319.530027 |    345.012159 | Emma Kissling                                                                                                                                                                   |
| 723 |     14.447493 |    505.868784 | Scott Hartman                                                                                                                                                                   |
| 724 |    759.938660 |    481.953792 | Yan Wong                                                                                                                                                                        |
| 725 |    961.669845 |    241.697231 | NA                                                                                                                                                                              |
| 726 |   1006.825016 |    108.605105 | Steven Traver                                                                                                                                                                   |
| 727 |    512.025747 |    551.835224 | Ferran Sayol                                                                                                                                                                    |
| 728 |    981.874634 |    266.112902 | Matt Crook                                                                                                                                                                      |
| 729 |    774.447267 |    455.327589 | Andrew A. Farke                                                                                                                                                                 |
| 730 |    361.259884 |    590.948848 | Yan Wong from photo by Gyik Toma                                                                                                                                                |
| 731 |     85.116863 |     66.780444 | Collin Gross                                                                                                                                                                    |
| 732 |    204.658634 |    289.018443 | Margot Michaud                                                                                                                                                                  |
| 733 |    196.270565 |     37.914775 | Martin R. Smith                                                                                                                                                                 |
| 734 |    623.330468 |    744.200687 | Steven Traver                                                                                                                                                                   |
| 735 |   1002.294805 |      6.019868 | Chris huh                                                                                                                                                                       |
| 736 |    899.591949 |    321.692156 | Y. de Hoev. (vectorized by T. Michael Keesey)                                                                                                                                   |
| 737 |    166.008583 |    430.056666 | Ferran Sayol                                                                                                                                                                    |
| 738 |   1013.117707 |     83.274481 | Sarah Werning                                                                                                                                                                   |
| 739 |    949.363784 |    185.350806 | Zimices                                                                                                                                                                         |
| 740 |    348.715261 |    402.602293 | Yan Wong                                                                                                                                                                        |
| 741 |     66.690062 |    448.915879 | Ferran Sayol                                                                                                                                                                    |
| 742 |    220.203807 |    292.057076 | David Sim (photograph) and T. Michael Keesey (vectorization)                                                                                                                    |
| 743 |    664.570326 |    276.196066 | Matt Wilkins                                                                                                                                                                    |
| 744 |   1000.098829 |    198.973502 | Shyamal                                                                                                                                                                         |
| 745 |    917.113007 |    229.462358 | Jebulon (vectorized by T. Michael Keesey)                                                                                                                                       |
| 746 |    101.841875 |    689.519907 | Chuanixn Yu                                                                                                                                                                     |
| 747 |    228.036917 |    324.402464 | Tasman Dixon                                                                                                                                                                    |
| 748 |    226.494090 |    656.126626 | Harold N Eyster                                                                                                                                                                 |
| 749 |    802.538512 |    647.676542 | NA                                                                                                                                                                              |
| 750 |    304.572000 |    687.667421 | Emily Willoughby                                                                                                                                                                |
| 751 |    492.643350 |    610.890732 | Paul O. Lewis                                                                                                                                                                   |
| 752 |    691.891772 |    152.537601 | Zimices                                                                                                                                                                         |
| 753 |    971.482520 |     34.998155 | Mathew Wedel                                                                                                                                                                    |
| 754 |    977.377654 |    500.760100 | Acrocynus (vectorized by T. Michael Keesey)                                                                                                                                     |
| 755 |    407.564799 |    649.187709 | Zimices                                                                                                                                                                         |
| 756 |    601.261133 |    493.535082 | Ferran Sayol                                                                                                                                                                    |
| 757 |    403.988027 |    709.320396 | Julio Garza                                                                                                                                                                     |
| 758 |    109.748711 |    133.354884 | Chris huh                                                                                                                                                                       |
| 759 |    199.531191 |    596.646054 | Dean Schnabel                                                                                                                                                                   |
| 760 |    358.997446 |     38.330010 | Ferran Sayol                                                                                                                                                                    |
| 761 |    114.208109 |    542.379347 | Leon P. A. M. Claessens, Patrick M. O’Connor, David M. Unwin                                                                                                                    |
| 762 |    491.481644 |     69.493928 | Sarah Werning                                                                                                                                                                   |
| 763 |    555.425751 |    428.526825 | NA                                                                                                                                                                              |
| 764 |    735.320521 |    719.394776 | Iain Reid                                                                                                                                                                       |
| 765 |    249.271611 |    285.206397 | Brockhaus and Efron                                                                                                                                                             |
| 766 |    977.495733 |    378.308444 | T. Michael Keesey                                                                                                                                                               |
| 767 |    635.182808 |    386.289448 | Maxime Dahirel (digitisation), Kees van Achterberg et al (doi: 10.3897/BDJ.8.e49017)(original publication)                                                                      |
| 768 |    903.913023 |      4.196735 | Mo Hassan                                                                                                                                                                       |
| 769 |    917.049102 |    593.826381 | Mali’o Kodis, photograph from Jersabek et al, 2003                                                                                                                              |
| 770 |    476.521198 |     22.024914 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 771 |    772.571427 |    585.973624 | Matt Wilkins (photo by Patrick Kavanagh)                                                                                                                                        |
| 772 |    192.324070 |    786.674991 | Lukasiniho                                                                                                                                                                      |
| 773 |    838.937463 |    242.878558 | Matt Crook                                                                                                                                                                      |
| 774 |    983.791950 |    691.896199 | Ferran Sayol                                                                                                                                                                    |
| 775 |    169.419647 |    672.319040 | Scott Hartman                                                                                                                                                                   |
| 776 |     73.509414 |    291.965266 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 777 |    253.847624 |    773.037747 | Frank Förster (based on a picture by Hans Hillewaert)                                                                                                                           |
| 778 |    142.391987 |    418.709665 | Steven Haddock • Jellywatch.org                                                                                                                                                 |
| 779 |    230.465339 |    180.590874 | Chris huh                                                                                                                                                                       |
| 780 |    647.151539 |    736.275645 | T. Michael Keesey                                                                                                                                                               |
| 781 |    982.143111 |    488.381462 | Tasman Dixon                                                                                                                                                                    |
| 782 |    958.023014 |    678.213594 | Kamil S. Jaron                                                                                                                                                                  |
| 783 |    178.685683 |     15.946302 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                                |
| 784 |    509.667707 |    597.855133 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                                 |
| 785 |     62.663029 |    792.462526 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 786 |    677.361662 |    343.914726 | Verdilak                                                                                                                                                                        |
| 787 |    998.933956 |     86.630947 | Markus A. Grohme                                                                                                                                                                |
| 788 |    658.941686 |     83.279517 | Margot Michaud                                                                                                                                                                  |
| 789 |     33.390561 |    792.569158 | terngirl                                                                                                                                                                        |
| 790 |    434.347828 |    391.789827 | Birgit Lang                                                                                                                                                                     |
| 791 |    572.236805 |    726.717791 | Jake Warner                                                                                                                                                                     |
| 792 |    707.357039 |    480.484921 | Pete Buchholz                                                                                                                                                                   |
| 793 |    204.107386 |    502.496780 | Emily Willoughby                                                                                                                                                                |
| 794 |    867.421416 |    731.960289 | Margot Michaud                                                                                                                                                                  |
| 795 |    706.716939 |    787.756684 | Caroline Harding, MAF (vectorized by T. Michael Keesey)                                                                                                                         |
| 796 |    604.399533 |    105.435543 | Tyler Greenfield                                                                                                                                                                |
| 797 |     47.177387 |    495.460912 | B Kimmel                                                                                                                                                                        |
| 798 |    611.793615 |    479.528703 | Servien (vectorized by T. Michael Keesey)                                                                                                                                       |
| 799 |    385.552713 |    607.011292 | Scott Hartman                                                                                                                                                                   |
| 800 |    274.743716 |    465.048396 | Alexander Schmidt-Lebuhn                                                                                                                                                        |
| 801 |    518.524297 |    254.971241 | Sharon Wegner-Larsen                                                                                                                                                            |
| 802 |    306.472783 |    555.063313 | NA                                                                                                                                                                              |
| 803 |     43.829528 |    524.374959 | Dean Schnabel                                                                                                                                                                   |
| 804 |    459.921498 |    466.841885 | Pete Buchholz                                                                                                                                                                   |
| 805 |    858.993548 |     41.107472 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                                |
| 806 |     21.534703 |    536.005611 | Gopal Murali                                                                                                                                                                    |
| 807 |    429.983644 |    139.006994 | Sarah Werning                                                                                                                                                                   |
| 808 |    246.986639 |    159.112370 | Chris huh                                                                                                                                                                       |
| 809 |    176.924995 |     30.509995 | Margot Michaud                                                                                                                                                                  |
| 810 |     66.798104 |    420.709950 | Scott Hartman                                                                                                                                                                   |
| 811 |    717.248913 |    465.465004 | Steven Traver                                                                                                                                                                   |
| 812 |    626.159500 |    484.705096 | Margot Michaud                                                                                                                                                                  |
| 813 |    680.593777 |    357.098889 | Chris huh                                                                                                                                                                       |
| 814 |    873.478188 |    690.644642 | Sergio A. Muñoz-Gómez                                                                                                                                                           |
| 815 |    623.678405 |    401.889251 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                                |
| 816 |    881.763760 |    407.837466 | Margot Michaud                                                                                                                                                                  |
| 817 |    561.937531 |    347.540962 | Zimices                                                                                                                                                                         |
| 818 |    188.880003 |    263.562764 | Tracy A. Heath                                                                                                                                                                  |
| 819 |    487.438307 |     10.632146 | Maija Karala                                                                                                                                                                    |
| 820 |    365.853681 |    362.298129 | Rebecca Groom                                                                                                                                                                   |
| 821 |    271.526456 |     36.812893 | Tracy A. Heath                                                                                                                                                                  |
| 822 |    548.845185 |    325.998373 | Noah Schlottman                                                                                                                                                                 |
| 823 |    597.862391 |    270.358785 | Ferran Sayol                                                                                                                                                                    |
| 824 |    795.880167 |    469.421194 | C. Camilo Julián-Caballero                                                                                                                                                      |
| 825 |    707.419889 |    380.154436 | Dean Schnabel                                                                                                                                                                   |
| 826 |    181.221860 |    446.315486 | T. Michael Keesey                                                                                                                                                               |
| 827 |    174.937051 |    114.936532 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 828 |    602.989063 |    409.500094 | Beth Reinke                                                                                                                                                                     |
| 829 |    563.913522 |    511.491419 | Matt Crook                                                                                                                                                                      |
| 830 |    279.532687 |      9.334526 | Harold N Eyster                                                                                                                                                                 |
| 831 |     73.521457 |    733.335282 | Steven Traver                                                                                                                                                                   |
| 832 |    888.839901 |    609.633265 | Steven Traver                                                                                                                                                                   |
| 833 |    936.566878 |    306.475779 | Emily Jane McTavish                                                                                                                                                             |
| 834 |    976.049208 |    452.026552 | Sibi (vectorized by T. Michael Keesey)                                                                                                                                          |
| 835 |    908.979901 |     35.861990 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 836 |    170.460522 |    218.713324 | NA                                                                                                                                                                              |
| 837 |    484.340094 |    589.814616 | Tasman Dixon                                                                                                                                                                    |
| 838 |     36.838032 |    174.632625 | Matt Crook                                                                                                                                                                      |
| 839 |    657.885652 |    728.053105 | Renato Santos                                                                                                                                                                   |
| 840 |    983.910279 |     64.475528 | Pollyanna von Knorring and T. Michael Keesey                                                                                                                                    |
| 841 |    198.791741 |    621.980371 | Gareth Monger                                                                                                                                                                   |
| 842 |   1010.835340 |    180.279175 | Christine Axon                                                                                                                                                                  |
| 843 |   1006.522153 |    350.236851 | Margot Michaud                                                                                                                                                                  |
| 844 |    226.646057 |    475.459525 | Matt Crook                                                                                                                                                                      |
| 845 |   1011.040827 |     54.377354 | Margot Michaud                                                                                                                                                                  |
| 846 |    630.362360 |    621.330079 | Steven Traver                                                                                                                                                                   |
| 847 |    572.609203 |    340.206454 | NA                                                                                                                                                                              |
| 848 |     78.831763 |     21.338870 | Mali’o Kodis, photograph by Aqua-Photos (<http://www.flickr.com/people/undervannsfotografen/>)                                                                                  |
| 849 |    342.252569 |    278.402575 | Roberto Díaz Sibaja                                                                                                                                                             |
| 850 |    764.517013 |    408.912911 | Steven Traver                                                                                                                                                                   |
| 851 |      9.743860 |    715.250001 | Margot Michaud                                                                                                                                                                  |
| 852 |    405.134723 |    424.656476 | Bill Bouton (source photo) & T. Michael Keesey (vectorization)                                                                                                                  |
| 853 |    704.579179 |    623.606341 | Scott Hartman                                                                                                                                                                   |
| 854 |    376.736759 |    421.583190 | Alexis Simon                                                                                                                                                                    |
| 855 |    643.974102 |    511.931809 | Steven Traver                                                                                                                                                                   |
| 856 |    607.576844 |    317.794627 | Walter Vladimir                                                                                                                                                                 |
| 857 |    230.254401 |    741.876572 | Lukasiniho                                                                                                                                                                      |
| 858 |    854.666354 |    293.510310 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                             |
| 859 |    543.066566 |    580.521504 | Beth Reinke                                                                                                                                                                     |
| 860 |    614.072233 |    232.708210 | Michael P. Taylor                                                                                                                                                               |
| 861 |    546.790394 |    240.813723 | Zimices                                                                                                                                                                         |
| 862 |    348.856087 |    587.314291 | Margot Michaud                                                                                                                                                                  |
| 863 |    356.209074 |     88.142469 | Lisa Byrne                                                                                                                                                                      |
| 864 |     10.392290 |    271.688322 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 865 |    759.823643 |    670.967575 | Zimices                                                                                                                                                                         |
| 866 |    418.392776 |    792.915153 | Markus A. Grohme                                                                                                                                                                |
| 867 |     56.146820 |    475.885132 | Matt Crook                                                                                                                                                                      |
| 868 |    551.525446 |    561.885390 | Birgit Lang                                                                                                                                                                     |
| 869 |    109.254872 |    537.449728 | Caleb Brown                                                                                                                                                                     |
| 870 |    546.500997 |    633.672528 | Alex Slavenko                                                                                                                                                                   |
| 871 |    823.087904 |    163.993151 | Yan Wong from drawing by Joseph Smit                                                                                                                                            |
| 872 |    721.248270 |    139.292646 | Chase Brownstein                                                                                                                                                                |
| 873 |    428.278708 |    631.349088 | Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey)                                                                                                                |
| 874 |    671.882524 |    739.757050 | Mathew Wedel                                                                                                                                                                    |
| 875 |    407.241298 |     24.413779 | Mike Hanson                                                                                                                                                                     |
| 876 |    947.132898 |    711.039479 | Margot Michaud                                                                                                                                                                  |
| 877 |    987.550820 |     20.014171 | Tauana J. Cunha                                                                                                                                                                 |
| 878 |    819.899278 |    324.456665 | Zimices                                                                                                                                                                         |
| 879 |    711.027155 |    120.828407 | T. Michael Keesey, from a photograph by Thea Boodhoo                                                                                                                            |
| 880 |    262.793907 |    563.214332 | Kent Elson Sorgon                                                                                                                                                               |
| 881 |    337.886908 |    626.473204 | T. Michael Keesey                                                                                                                                                               |
| 882 |    391.312784 |     17.826029 | NA                                                                                                                                                                              |
| 883 |    292.534031 |    158.114407 | Sarah Werning                                                                                                                                                                   |
| 884 |    183.637512 |    208.692363 | Margot Michaud                                                                                                                                                                  |
| 885 |    969.339422 |    219.528592 | Ferran Sayol                                                                                                                                                                    |
| 886 |    529.206539 |     14.666177 | Zimices                                                                                                                                                                         |
| 887 |    686.264205 |    141.796368 | Joseph Wolf, 1863 (vectorization by Dinah Challen)                                                                                                                              |
| 888 |    986.114931 |    663.294553 | Steven Traver                                                                                                                                                                   |
| 889 |    539.817246 |    613.383900 | Chris huh                                                                                                                                                                       |
| 890 |    141.718323 |    725.996766 | Jean-Raphaël Guillaumin (photography) and T. Michael Keesey (vectorization)                                                                                                     |
| 891 |    258.905161 |    539.305684 | Robert Gay                                                                                                                                                                      |
| 892 |    200.071737 |    228.745051 | Mike Hanson                                                                                                                                                                     |
| 893 |    257.773040 |    429.172244 | Sean McCann                                                                                                                                                                     |
| 894 |   1016.984399 |    570.652581 | T. Michael Keesey                                                                                                                                                               |
| 895 |    465.913064 |     72.350815 | Ingo Braasch                                                                                                                                                                    |
| 896 |    215.500888 |     22.560531 | ArtFavor & annaleeblysse                                                                                                                                                        |
| 897 |    168.125187 |    603.858123 | Zimices                                                                                                                                                                         |
| 898 |    155.795640 |    117.754936 | Chris Jennings (Risiatto)                                                                                                                                                       |
| 899 |    131.005481 |    399.716445 | T. Michael Keesey                                                                                                                                                               |
| 900 |    910.261612 |    113.017663 | Kai R. Caspar                                                                                                                                                                   |
| 901 |    930.711706 |    635.028336 | Noah Schlottman, photo from National Science Foundation - Turbellarian Taxonomic Database                                                                                       |
| 902 |    759.474482 |    536.201069 | NA                                                                                                                                                                              |
| 903 |    741.798064 |    677.831883 | Jagged Fang Designs                                                                                                                                                             |
| 904 |    301.934063 |    647.746325 | Steven Traver                                                                                                                                                                   |
| 905 |    451.856355 |    386.568212 | Birgit Lang                                                                                                                                                                     |
| 906 |    959.409262 |    694.693021 | Dean Schnabel                                                                                                                                                                   |
| 907 |    866.375585 |    723.527637 | Johan Lindgren, Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe                                                                                                            |
| 908 |    656.200181 |    442.641520 | Jagged Fang Designs                                                                                                                                                             |
| 909 |    555.100523 |    768.319470 | Chloé Schmidt                                                                                                                                                                   |
| 910 |    326.761234 |     67.583386 | Samanta Orellana                                                                                                                                                                |
| 911 |    446.702441 |     34.441878 | Dean Schnabel                                                                                                                                                                   |
| 912 |    239.351204 |    371.904457 | T. Michael Keesey                                                                                                                                                               |
| 913 |    765.194051 |     54.264227 | NA                                                                                                                                                                              |
| 914 |    745.594212 |    623.728617 | Christoph Schomburg                                                                                                                                                             |
| 915 |     34.030965 |    784.937016 | Caleb Brown                                                                                                                                                                     |
| 916 |    856.934728 |    701.356748 | NA                                                                                                                                                                              |
| 917 |    702.826255 |    130.542380 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 918 |     41.708038 |    543.515891 | Ferran Sayol                                                                                                                                                                    |
| 919 |    794.491399 |    390.828818 | Margot Michaud                                                                                                                                                                  |
| 920 |    966.929989 |    248.087556 | Sharon Wegner-Larsen                                                                                                                                                            |

    #> Your tweet has been posted!
