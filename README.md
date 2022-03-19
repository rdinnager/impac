
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

T. Michael Keesey, Jagged Fang Designs, Nobu Tamura (vectorized by T.
Michael Keesey), Michelle Site, Markus A. Grohme, Margot Michaud, Amanda
Katzer, U.S. National Park Service (vectorized by William Gearty), Mark
Witton, Scott Hartman, M Hutchinson, FunkMonk, SecretJellyMan, Ignacio
Contreras, Gabriela Palomo-Munoz, Matt Crook, Pearson Scott Foresman
(vectorized by T. Michael Keesey), Sarah Werning, Lafage, Chris huh,
Zimices, Ferran Sayol, Pete Buchholz, Joseph J. W. Sertich, Mark A.
Loewen, Pedro de Siracusa, Dennis C. Murphy, after
<https://commons.wikimedia.org/wiki/File:Queensland_State_Archives_2981_Cane_toads_at_the_Meringa_Sugar_Experiment_Station_North_Queensland_c_1935.png>,
C. Camilo Julián-Caballero, Birgit Lang, Mali’o Kodis, photograph by
Bruno Vellutini, Lankester Edwin Ray (vectorized by T. Michael Keesey),
Gareth Monger, Gregor Bucher, Max Farnworth, Xavier Giroux-Bougard,
Michael P. Taylor, Kenneth Lacovara (vectorized by T. Michael Keesey),
S.Martini, Anthony Caravaggi, T. Michael Keesey (after Colin M. L.
Burnett), T. Michael Keesey (vectorization) and Nadiatalent
(photography), Steven Traver, Katie S. Collins, Liftarn, Michael Wolf
(photo), Hans Hillewaert (editing), T. Michael Keesey (vectorization),
Saguaro Pictures (source photo) and T. Michael Keesey, Hans Hillewaert,
T. Michael Keesey (photo by Bc999 \[Black crow\]), Iain Reid, Tauana J.
Cunha, Ghedoghedo, vectorized by Zimices, Christine Axon, I. Sácek,
Sr. (vectorized by T. Michael Keesey), Luc Viatour (source photo) and
Andreas Plank, Lukasiniho, M Kolmann, Andrew A. Farke, Kai R. Caspar,
Peileppe, Cesar Julian, Matt Wilkins, Dmitry Bogdanov, Mali’o Kodis,
photograph by “Wildcat Dunny”
(<http://www.flickr.com/people/wildcat_dunny/>), Ghedoghedo (vectorized
by T. Michael Keesey), Yan Wong, Alex Slavenko, Felix Vaux, Melissa
Broussard, Milton Tan, B. Duygu Özpolat, Sam Droege (photo) and T.
Michael Keesey (vectorization), L. Shyamal, Joanna Wolfe, David Orr, J.
J. Harrison (photo) & T. Michael Keesey, Ron Holmes/U. S. Fish and
Wildlife Service (source photo), T. Michael Keesey (vectorization),
Tasman Dixon, Jose Carlos Arenas-Monroy, Mali’o Kodis, traced image from
the National Science Foundation’s Turbellarian Taxonomic Database, Tony
Ayling (vectorized by T. Michael Keesey), Martin R. Smith, Francesca
Belem Lopes Palmeira, L.M. Davalos, Cristopher Silva, Chloé Schmidt,
Dmitry Bogdanov (vectorized by T. Michael Keesey), Jimmy Bernot, Mike
Hanson, Filip em, Noah Schlottman, photo from Casey Dunn, Original
drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja, Michael
Scroggie, Darren Naish, Nemo, and T. Michael Keesey, Catherine Yasuda,
Gabriele Midolo, TaraTaylorDesign, Beth Reinke, Andy Wilson, Jaime
Headden, Stemonitis (photography) and T. Michael Keesey (vectorization),
Yan Wong from photo by Denes Emoke, Natalie Claunch, Scott D. Sampson,
Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster,
Joshua A. Smith, Alan L. Titus, Ingo Braasch, Rebecca Groom, Collin
Gross, T. Michael Keesey (after Heinrich Harder), Stacy Spensley
(Modified), DW Bapst (modified from Bulman, 1970), Mali’o Kodis,
photograph by P. Funch and R.M. Kristensen, Maxime Dahirel, Trond R.
Oskars, Scott Reid, Theodore W. Pietsch (photography) and T. Michael
Keesey (vectorization), Baheerathan Murugavel, Mathilde Cordellier,
Matus Valach, Didier Descouens (vectorized by T. Michael Keesey), Mali’o
Kodis, image from the Smithsonian Institution, Obsidian Soul (vectorized
by T. Michael Keesey), Martin Kevil, Sean McCann, Dean Schnabel, Todd
Marshall, vectorized by Zimices, Shyamal, xgirouxb, Manabu
Bessho-Uehara, Philippe Janvier (vectorized by T. Michael Keesey), T.
Michael Keesey (after Kukalová), Jack Mayer Wood, Lee Harding (photo),
John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G.
Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Nobu
Tamura, modified by Andrew A. Farke, , Terpsichores, Tracy A. Heath,
Abraão Leite, Roberto Díaz Sibaja, Geoff Shaw, wsnaccad, Matthew E.
Clapham, Kelly, Jessica Anne Miller, A. H. Baldwin (vectorized by T.
Michael Keesey), Rachel Shoop, Eric Moody, Josep Marti Solans, Douglas
Brown (modified by T. Michael Keesey), Maxwell Lefroy (vectorized by T.
Michael Keesey), Jakovche, FunkMonk (Michael B. H.), Martien Brand
(original photo), Renato Santos (vector silhouette), Christoph
Schomburg, Kent Elson Sorgon, Daniel Stadtmauer, Sharon Wegner-Larsen,
Robbie N. Cada (vectorized by T. Michael Keesey), Kamil S. Jaron,
Donovan Reginald Rosevear (vectorized by T. Michael Keesey), Jaime
Chirinos (vectorized by T. Michael Keesey), Raven Amos, Metalhead64
(vectorized by T. Michael Keesey), Steven Coombs, RS, Mason McNair,
Ludwik Gasiorowski, Adrian Reich, Steven Haddock • Jellywatch.org,
Jessica Rick, Nobu Tamura, vectorized by Zimices, Armin Reindl, Kanchi
Nanjo, Skye M, Melissa Ingala, Apokryltaros (vectorized by T. Michael
Keesey), Juan Carlos Jerí, Isaure Scavezzoni, Haplochromis (vectorized
by T. Michael Keesey), Ekaterina Kopeykina (vectorized by T. Michael
Keesey), Maija Karala, B Kimmel, Young and Zhao (1972:figure 4),
modified by Michael P. Taylor, Richard J. Harris, Cathy, Matt Martyniuk
(modified by Serenchia), Tyler Greenfield, Dave Angelini, Crystal Maier,
Julio Garza, Joseph Wolf, 1863 (vectorization by Dinah Challen), Richard
Parker (vectorized by T. Michael Keesey), Kimberly Haddrell, Yan Wong
from drawing in The Century Dictionary (1911), Andrew A. Farke, modified
from original by H. Milne Edwards, Wynston Cooper (photo) and
Albertonykus (silhouette), Bennet McComish, photo by Hans Hillewaert,
Tess Linden, Frank Förster, Becky Barnes, terngirl, Brad McFeeters
(vectorized by T. Michael Keesey), Chase Brownstein, Sherman Foote
Denton (illustration, 1897) and Timothy J. Bartley (silhouette), Nobu
Tamura, Meliponicultor Itaymbere, Mr E? (vectorized by T. Michael
Keesey), Eduard Solà Vázquez, vectorised by Yan Wong, Kosta Mumcuoglu
(vectorized by T. Michael Keesey), T. Michael Keesey (after Masteraah),
Original drawing by Nobu Tamura, vectorized by Roberto Díaz Sibaja,
Matthew Hooge (vectorized by T. Michael Keesey), Andrew R. Gehrke,
Lauren Sumner-Rooney, Caroline Harding, MAF (vectorized by T. Michael
Keesey), Mathieu Pélissié, Conty, Sam Fraser-Smith (vectorized by T.
Michael Keesey), Fritz Geller-Grimm (vectorized by T. Michael Keesey),
Nobu Tamura (modified by T. Michael Keesey), T. Michael Keesey
(vectorization); Thorsten Assmann, Jörn Buse, Claudia Drees,
Ariel-Leib-Leonid Friedman, Tal Levanony, Andrea Matern, Anika Timm, and
David W. Wrase (photography), Neil Kelley, Antonov (vectorized by T.
Michael Keesey), Unknown (photo), John E. McCormack, Michael G. Harvey,
Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T.
Brumfield & T. Michael Keesey, Leon P. A. M. Claessens, Patrick M.
O’Connor, David M. Unwin, Mali’o Kodis, image from the “Proceedings of
the Zoological Society of London”,
\<U+0414\>\<U+0438\>\<U+0411\>\<U+0433\>\<U+0434\> (vectorized by T.
Michael Keesey), Yan Wong from drawing by Joseph Smit, Smokeybjb, John
Curtis (vectorized by T. Michael Keesey), Kristina Gagalova, Alexandre
Vong, Matt Martyniuk, Oscar Sanisidro, Berivan Temiz, Caleb M. Brown,
Campbell Fleming, Emily Willoughby, Timothy Knepp (vectorized by T.
Michael Keesey), Mariana Ruiz (vectorized by T. Michael Keesey), Robert
Bruce Horsfall (vectorized by William Gearty), Gustav Mützel, Robert
Gay, Lily Hughes, Kanako Bessho-Uehara, T. Michael Keesey (after A. Y.
Ivantsov), Hugo Gruson, Roger Witter, vectorized by Zimices, Bryan
Carstens, T. Tischler, Meyer-Wachsmuth I, Curini Galletti M, Jondelius U
(<doi:10.1371/journal.pone.0107688>). Vectorization by Y. Wong, Nobu
Tamura (vectorized by A. Verrière), Mali’o Kodis, photograph by Derek
Keats (<http://www.flickr.com/photos/dkeats/>), Steve Hillebrand/U. S.
Fish and Wildlife Service (source photo), T. Michael Keesey
(vectorization), Dexter R. Mardis, Owen Jones, Hans Hillewaert
(vectorized by T. Michael Keesey), Jordan Mallon (vectorized by T.
Michael Keesey), Erika Schumacher, Conty (vectorized by T. Michael
Keesey), Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob
Slotow (vectorized by T. Michael Keesey), Tom Tarrant (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Daniel Jaron, T.
Michael Keesey (photo by Darren Swim), Caleb M. Gordon, Jonathan Wells,
David Tana, Aadx, Francesco “Architetto” Rollandin, Tyler Greenfield and
Scott Hartman, Carlos Cano-Barbacil, Dave Souza (vectorized by T.
Michael Keesey), Emma Hughes, Stephen O’Connor (vectorized by T. Michael
Keesey), Harold N Eyster, CNZdenek, Mathew Wedel, Jon Hill (Photo by
Benjamint444:
<http://en.wikipedia.org/wiki/File:Blue-footed-booby.jpg>), Yusan Yang,
Frank Förster (based on a picture by Hans Hillewaert), T. Michael Keesey
(after MPF), Maky (vectorization), Gabriella Skollar (photography),
Rebecca Lewis (editing), Qiang Ou, Tommaso Cancellario, M. A. Broussard

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                               |
| --: | ------------: | ------------: | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    827.033057 |    348.124546 | T. Michael Keesey                                                                                                                                                                    |
|   2 |    219.690125 |    178.359359 | Jagged Fang Designs                                                                                                                                                                  |
|   3 |    681.849240 |    171.801666 | NA                                                                                                                                                                                   |
|   4 |    739.310784 |    590.299894 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
|   5 |    573.476276 |    359.288275 | T. Michael Keesey                                                                                                                                                                    |
|   6 |    273.510511 |    381.348804 | Michelle Site                                                                                                                                                                        |
|   7 |    927.056225 |    450.065714 | T. Michael Keesey                                                                                                                                                                    |
|   8 |    555.500952 |     43.656680 | Markus A. Grohme                                                                                                                                                                     |
|   9 |    422.472648 |    484.789608 | NA                                                                                                                                                                                   |
|  10 |    967.803453 |    716.081066 | NA                                                                                                                                                                                   |
|  11 |    354.615367 |    161.422190 | Margot Michaud                                                                                                                                                                       |
|  12 |    544.510680 |    660.578467 | Amanda Katzer                                                                                                                                                                        |
|  13 |    100.308127 |    742.261958 | U.S. National Park Service (vectorized by William Gearty)                                                                                                                            |
|  14 |    880.146162 |    636.337395 | NA                                                                                                                                                                                   |
|  15 |    875.564518 |     49.484826 | NA                                                                                                                                                                                   |
|  16 |    563.732084 |    737.428058 | Mark Witton                                                                                                                                                                          |
|  17 |    255.182822 |     66.334236 | Scott Hartman                                                                                                                                                                        |
|  18 |    322.257956 |    580.707848 | T. Michael Keesey                                                                                                                                                                    |
|  19 |    767.743825 |    501.608653 | M Hutchinson                                                                                                                                                                         |
|  20 |    175.747068 |    532.238695 | NA                                                                                                                                                                                   |
|  21 |    850.013784 |    163.321235 | FunkMonk                                                                                                                                                                             |
|  22 |     64.353691 |    513.872393 | SecretJellyMan                                                                                                                                                                       |
|  23 |    144.320854 |    660.719740 | Ignacio Contreras                                                                                                                                                                    |
|  24 |    783.271389 |    726.967214 | NA                                                                                                                                                                                   |
|  25 |    446.813668 |    260.373600 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
|  26 |    251.220122 |    462.407224 | Scott Hartman                                                                                                                                                                        |
|  27 |    420.155166 |     76.473439 | Margot Michaud                                                                                                                                                                       |
|  28 |    253.089642 |    617.894803 | Gabriela Palomo-Munoz                                                                                                                                                                |
|  29 |    341.592385 |    653.510591 | Matt Crook                                                                                                                                                                           |
|  30 |    813.644878 |    279.499552 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                                             |
|  31 |    126.891591 |    425.951098 | T. Michael Keesey                                                                                                                                                                    |
|  32 |    285.772432 |    738.317689 | NA                                                                                                                                                                                   |
|  33 |    437.891533 |    705.180541 | Sarah Werning                                                                                                                                                                        |
|  34 |    529.379747 |     92.760754 | Lafage                                                                                                                                                                               |
|  35 |    400.546578 |    349.776381 | Chris huh                                                                                                                                                                            |
|  36 |    772.532783 |    416.267514 | Zimices                                                                                                                                                                              |
|  37 |    969.645955 |    361.318833 | NA                                                                                                                                                                                   |
|  38 |    939.721481 |    581.744306 | Ferran Sayol                                                                                                                                                                         |
|  39 |    203.675518 |    129.055897 | Margot Michaud                                                                                                                                                                       |
|  40 |    942.917631 |    240.395662 | Pete Buchholz                                                                                                                                                                        |
|  41 |    649.474596 |    697.997944 | Joseph J. W. Sertich, Mark A. Loewen                                                                                                                                                 |
|  42 |    703.694698 |    320.325902 | Zimices                                                                                                                                                                              |
|  43 |     90.269551 |    307.910694 | Pedro de Siracusa                                                                                                                                                                    |
|  44 |    942.992290 |    126.257084 | Dennis C. Murphy, after <https://commons.wikimedia.org/wiki/File:Queensland_State_Archives_2981_Cane_toads_at_the_Meringa_Sugar_Experiment_Station_North_Queensland_c_1935.png>      |
|  45 |    708.996300 |    646.652807 | C. Camilo Julián-Caballero                                                                                                                                                           |
|  46 |    478.133379 |    192.089072 | Sarah Werning                                                                                                                                                                        |
|  47 |    769.555553 |    192.703897 | Matt Crook                                                                                                                                                                           |
|  48 |    516.795339 |    578.213530 | Markus A. Grohme                                                                                                                                                                     |
|  49 |    509.942355 |    613.470346 | Birgit Lang                                                                                                                                                                          |
|  50 |    663.041025 |     20.238420 | NA                                                                                                                                                                                   |
|  51 |    870.036879 |    525.723579 | Mali’o Kodis, photograph by Bruno Vellutini                                                                                                                                          |
|  52 |    944.849326 |     24.362420 | NA                                                                                                                                                                                   |
|  53 |    680.753412 |    509.622626 | NA                                                                                                                                                                                   |
|  54 |     36.808191 |    138.944548 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                                                |
|  55 |    351.230847 |    415.232286 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
|  56 |    129.809894 |     88.979681 | Gareth Monger                                                                                                                                                                        |
|  57 |    869.177716 |    740.288837 | Margot Michaud                                                                                                                                                                       |
|  58 |    976.249626 |    489.935448 | Gregor Bucher, Max Farnworth                                                                                                                                                         |
|  59 |    644.637451 |    777.837598 | Xavier Giroux-Bougard                                                                                                                                                                |
|  60 |    397.507827 |    377.670343 | Chris huh                                                                                                                                                                            |
|  61 |    166.761040 |    775.624363 | Markus A. Grohme                                                                                                                                                                     |
|  62 |    272.736907 |     29.417577 | Michael P. Taylor                                                                                                                                                                    |
|  63 |    221.784833 |    193.562011 | Jagged Fang Designs                                                                                                                                                                  |
|  64 |    197.033189 |    390.882197 | Zimices                                                                                                                                                                              |
|  65 |    473.089140 |    151.409542 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
|  66 |    620.041572 |    622.984181 | Kenneth Lacovara (vectorized by T. Michael Keesey)                                                                                                                                   |
|  67 |    772.297550 |     99.986236 | Zimices                                                                                                                                                                              |
|  68 |    760.584727 |    623.664543 | Scott Hartman                                                                                                                                                                        |
|  69 |    782.946684 |     12.282377 | T. Michael Keesey                                                                                                                                                                    |
|  70 |    826.547855 |    449.352856 | Chris huh                                                                                                                                                                            |
|  71 |    342.161189 |    461.602787 | S.Martini                                                                                                                                                                            |
|  72 |    718.153320 |    379.893041 | Chris huh                                                                                                                                                                            |
|  73 |    463.378172 |    211.481799 | Anthony Caravaggi                                                                                                                                                                    |
|  74 |    917.785650 |     79.563824 | T. Michael Keesey (after Colin M. L. Burnett)                                                                                                                                        |
|  75 |   1007.120991 |    192.218323 | T. Michael Keesey (vectorization) and Nadiatalent (photography)                                                                                                                      |
|  76 |    639.078727 |     42.543335 | Steven Traver                                                                                                                                                                        |
|  77 |     64.771881 |    689.804826 | T. Michael Keesey                                                                                                                                                                    |
|  78 |    734.430844 |    457.875441 | Steven Traver                                                                                                                                                                        |
|  79 |    834.965148 |    505.558676 | Ferran Sayol                                                                                                                                                                         |
|  80 |    745.779489 |    354.683121 | Katie S. Collins                                                                                                                                                                     |
|  81 |    705.628815 |     61.606764 | Chris huh                                                                                                                                                                            |
|  82 |    334.863191 |    245.094753 | Matt Crook                                                                                                                                                                           |
|  83 |    352.188325 |    256.429047 | Matt Crook                                                                                                                                                                           |
|  84 |    946.144752 |    662.683971 | Liftarn                                                                                                                                                                              |
|  85 |    954.811928 |    277.862276 | Michael Wolf (photo), Hans Hillewaert (editing), T. Michael Keesey (vectorization)                                                                                                   |
|  86 |    866.324512 |    410.963265 | Steven Traver                                                                                                                                                                        |
|  87 |     37.384051 |    381.008338 | NA                                                                                                                                                                                   |
|  88 |    662.561612 |    441.340194 | Margot Michaud                                                                                                                                                                       |
|  89 |    132.072717 |    619.317509 | Gareth Monger                                                                                                                                                                        |
|  90 |    643.718539 |    160.081470 | Saguaro Pictures (source photo) and T. Michael Keesey                                                                                                                                |
|  91 |    152.243855 |    166.996810 | Hans Hillewaert                                                                                                                                                                      |
|  92 |    501.586510 |    476.348219 | T. Michael Keesey (photo by Bc999 \[Black crow\])                                                                                                                                    |
|  93 |    506.091223 |     14.582867 | Iain Reid                                                                                                                                                                            |
|  94 |    501.898709 |    329.172687 | Ferran Sayol                                                                                                                                                                         |
|  95 |    715.802865 |    742.539792 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
|  96 |    872.462077 |    212.421445 | Tauana J. Cunha                                                                                                                                                                      |
|  97 |    728.466758 |    774.401120 | Katie S. Collins                                                                                                                                                                     |
|  98 |     17.982663 |    679.742518 | Gareth Monger                                                                                                                                                                        |
|  99 |    167.901021 |    592.571375 | Ghedoghedo, vectorized by Zimices                                                                                                                                                    |
| 100 |    239.382784 |    350.997967 | Christine Axon                                                                                                                                                                       |
| 101 |    331.545509 |     32.425471 | I. Sácek, Sr. (vectorized by T. Michael Keesey)                                                                                                                                      |
| 102 |    852.948775 |    230.531675 | Tauana J. Cunha                                                                                                                                                                      |
| 103 |    886.493066 |    592.977947 | Zimices                                                                                                                                                                              |
| 104 |     34.949765 |    284.658149 | Matt Crook                                                                                                                                                                           |
| 105 |    746.752059 |     47.116474 | Luc Viatour (source photo) and Andreas Plank                                                                                                                                         |
| 106 |    217.229613 |    704.198636 | Scott Hartman                                                                                                                                                                        |
| 107 |    439.922097 |    624.355134 | Lukasiniho                                                                                                                                                                           |
| 108 |    895.583457 |    768.385243 | M Kolmann                                                                                                                                                                            |
| 109 |    298.321087 |    227.940726 | Andrew A. Farke                                                                                                                                                                      |
| 110 |    299.488001 |    494.755648 | Matt Crook                                                                                                                                                                           |
| 111 |    938.194787 |    769.307944 | Margot Michaud                                                                                                                                                                       |
| 112 |    712.047742 |    234.062294 | Kai R. Caspar                                                                                                                                                                        |
| 113 |    364.222717 |    325.037237 | Peileppe                                                                                                                                                                             |
| 114 |    669.675596 |    672.910924 | Cesar Julian                                                                                                                                                                         |
| 115 |    968.382584 |    303.537198 | NA                                                                                                                                                                                   |
| 116 |    477.222744 |    286.277084 | Matt Wilkins                                                                                                                                                                         |
| 117 |    512.357001 |    170.370762 | Dmitry Bogdanov                                                                                                                                                                      |
| 118 |    495.802663 |    696.256727 | Mali’o Kodis, photograph by “Wildcat Dunny” (<http://www.flickr.com/people/wildcat_dunny/>)                                                                                          |
| 119 |     33.589122 |    343.529423 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                                         |
| 120 |    145.944075 |    562.983991 | Yan Wong                                                                                                                                                                             |
| 121 |    292.046249 |    327.484170 | Ferran Sayol                                                                                                                                                                         |
| 122 |    295.525551 |    308.567783 | Ferran Sayol                                                                                                                                                                         |
| 123 |    901.757386 |    741.685789 | Alex Slavenko                                                                                                                                                                        |
| 124 |    857.118043 |     37.646899 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 125 |    476.647426 |     43.918029 | Felix Vaux                                                                                                                                                                           |
| 126 |   1007.536530 |    268.438020 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 127 |    907.407453 |    281.939559 | Zimices                                                                                                                                                                              |
| 128 |    821.877330 |    199.466149 | Jagged Fang Designs                                                                                                                                                                  |
| 129 |    646.697988 |    210.174275 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 130 |    306.240520 |    323.942196 | Margot Michaud                                                                                                                                                                       |
| 131 |    294.693783 |    434.994242 | Melissa Broussard                                                                                                                                                                    |
| 132 |    778.978603 |    475.135002 | Milton Tan                                                                                                                                                                           |
| 133 |    718.343120 |    719.239137 | B. Duygu Özpolat                                                                                                                                                                     |
| 134 |    269.011420 |    433.567807 | Sam Droege (photo) and T. Michael Keesey (vectorization)                                                                                                                             |
| 135 |    320.463256 |     79.118738 | Markus A. Grohme                                                                                                                                                                     |
| 136 |    422.313446 |    213.245240 | Markus A. Grohme                                                                                                                                                                     |
| 137 |    572.468198 |    684.635872 | Matt Crook                                                                                                                                                                           |
| 138 |    165.163953 |    624.784266 | Scott Hartman                                                                                                                                                                        |
| 139 |    265.123219 |    301.528834 | L. Shyamal                                                                                                                                                                           |
| 140 |    474.055568 |    653.044157 | Joanna Wolfe                                                                                                                                                                         |
| 141 |    256.179553 |    185.845258 | Scott Hartman                                                                                                                                                                        |
| 142 |    538.872816 |    784.439825 | Ferran Sayol                                                                                                                                                                         |
| 143 |    634.110360 |     97.802638 | David Orr                                                                                                                                                                            |
| 144 |    395.442449 |    683.600467 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 145 |    262.506736 |    676.350305 | NA                                                                                                                                                                                   |
| 146 |    112.719491 |    750.773708 | Tauana J. Cunha                                                                                                                                                                      |
| 147 |    738.767663 |    240.866169 | Jagged Fang Designs                                                                                                                                                                  |
| 148 |    917.918019 |    785.335336 | J. J. Harrison (photo) & T. Michael Keesey                                                                                                                                           |
| 149 |    602.275527 |    584.667987 | Ron Holmes/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                                                         |
| 150 |    579.859742 |    665.945260 | M Kolmann                                                                                                                                                                            |
| 151 |    191.145534 |    751.311137 | Tasman Dixon                                                                                                                                                                         |
| 152 |    839.531326 |    566.966919 | Jose Carlos Arenas-Monroy                                                                                                                                                            |
| 153 |    111.948538 |     92.616340 | Mali’o Kodis, traced image from the National Science Foundation’s Turbellarian Taxonomic Database                                                                                    |
| 154 |    272.170081 |    114.465291 | Zimices                                                                                                                                                                              |
| 155 |    219.789853 |    363.393319 | T. Michael Keesey                                                                                                                                                                    |
| 156 |    813.806278 |    244.784450 | Matt Crook                                                                                                                                                                           |
| 157 |    803.329444 |    547.543711 | Zimices                                                                                                                                                                              |
| 158 |    637.076259 |    234.629572 | Gareth Monger                                                                                                                                                                        |
| 159 |    622.480610 |    575.256580 | Birgit Lang                                                                                                                                                                          |
| 160 |    873.636918 |    269.294032 | Markus A. Grohme                                                                                                                                                                     |
| 161 |    723.886249 |    421.860702 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                                        |
| 162 |    529.873848 |    309.446965 | Martin R. Smith                                                                                                                                                                      |
| 163 |    558.713352 |    772.284570 | Gareth Monger                                                                                                                                                                        |
| 164 |    118.957010 |    677.496798 | Francesca Belem Lopes Palmeira                                                                                                                                                       |
| 165 |    256.639972 |    416.979838 | L.M. Davalos                                                                                                                                                                         |
| 166 |    972.128701 |    424.794223 | Markus A. Grohme                                                                                                                                                                     |
| 167 |    641.901149 |    607.825019 | Cristopher Silva                                                                                                                                                                     |
| 168 |    650.602633 |    361.105998 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 169 |    251.550220 |    528.890938 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 170 |    454.780432 |    134.214253 | Gareth Monger                                                                                                                                                                        |
| 171 |    799.483526 |    377.029902 | Chloé Schmidt                                                                                                                                                                        |
| 172 |    632.659466 |    503.800859 | Martin R. Smith                                                                                                                                                                      |
| 173 |    249.709460 |      7.210926 | Zimices                                                                                                                                                                              |
| 174 |    160.655496 |    464.044409 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 175 |      7.774411 |     40.965343 | Kai R. Caspar                                                                                                                                                                        |
| 176 |    773.814081 |    124.173631 | Chris huh                                                                                                                                                                            |
| 177 |    345.605903 |    711.392102 | Joanna Wolfe                                                                                                                                                                         |
| 178 |     29.481072 |    683.579726 | Jimmy Bernot                                                                                                                                                                         |
| 179 |    387.770010 |    239.936927 | Mike Hanson                                                                                                                                                                          |
| 180 |    993.002392 |     93.311274 | Gareth Monger                                                                                                                                                                        |
| 181 |    401.452347 |    119.705489 | Jagged Fang Designs                                                                                                                                                                  |
| 182 |    232.797901 |    486.718489 | Filip em                                                                                                                                                                             |
| 183 |    384.460374 |    705.757288 | Liftarn                                                                                                                                                                              |
| 184 |    240.674817 |    720.393365 | Noah Schlottman, photo from Casey Dunn                                                                                                                                               |
| 185 |    266.284193 |    559.724338 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                                               |
| 186 |    679.169043 |    735.712672 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 187 |    600.625329 |    124.872588 | Katie S. Collins                                                                                                                                                                     |
| 188 |     79.557051 |    671.967857 | Tasman Dixon                                                                                                                                                                         |
| 189 |    498.377622 |    269.087044 | Margot Michaud                                                                                                                                                                       |
| 190 |    807.162361 |    528.124686 | NA                                                                                                                                                                                   |
| 191 |    347.656756 |    774.934165 | Michael Scroggie                                                                                                                                                                     |
| 192 |    910.723489 |    358.576157 | Darren Naish, Nemo, and T. Michael Keesey                                                                                                                                            |
| 193 |    379.609648 |     28.215897 | Scott Hartman                                                                                                                                                                        |
| 194 |    530.059468 |    793.710668 | Jose Carlos Arenas-Monroy                                                                                                                                                            |
| 195 |    725.114484 |    555.553613 | NA                                                                                                                                                                                   |
| 196 |    595.239852 |    597.202604 | Tasman Dixon                                                                                                                                                                         |
| 197 |    498.451007 |    446.947611 | Catherine Yasuda                                                                                                                                                                     |
| 198 |    507.657101 |    262.047899 | Matt Crook                                                                                                                                                                           |
| 199 |    447.761276 |    323.552538 | Gareth Monger                                                                                                                                                                        |
| 200 |    377.235505 |    598.775836 | Ferran Sayol                                                                                                                                                                         |
| 201 |    856.866419 |    695.911394 | Margot Michaud                                                                                                                                                                       |
| 202 |     38.605670 |    407.920620 | Gabriele Midolo                                                                                                                                                                      |
| 203 |   1016.255440 |    105.766856 | TaraTaylorDesign                                                                                                                                                                     |
| 204 |   1008.297989 |    628.259654 | Gareth Monger                                                                                                                                                                        |
| 205 |    652.018196 |     56.603061 | Jagged Fang Designs                                                                                                                                                                  |
| 206 |    658.920128 |    103.159055 | Zimices                                                                                                                                                                              |
| 207 |     91.505774 |      4.584802 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 208 |    304.535728 |    521.827618 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 209 |    671.243183 |    427.439002 | Matt Crook                                                                                                                                                                           |
| 210 |    106.224073 |    507.421274 | Jagged Fang Designs                                                                                                                                                                  |
| 211 |    182.371724 |    612.255884 | Melissa Broussard                                                                                                                                                                    |
| 212 |    998.733716 |    298.696828 | Beth Reinke                                                                                                                                                                          |
| 213 |      8.988392 |    170.864842 | Zimices                                                                                                                                                                              |
| 214 |    399.789220 |    355.470601 | Margot Michaud                                                                                                                                                                       |
| 215 |    839.769163 |     22.949797 | NA                                                                                                                                                                                   |
| 216 |    381.883824 |     37.687097 | S.Martini                                                                                                                                                                            |
| 217 |     87.648754 |     12.720377 | Andy Wilson                                                                                                                                                                          |
| 218 |    879.864414 |    304.442501 | FunkMonk                                                                                                                                                                             |
| 219 |    679.656006 |    402.065977 | Gareth Monger                                                                                                                                                                        |
| 220 |    185.459395 |    747.895124 | Matt Crook                                                                                                                                                                           |
| 221 |    717.859504 |    160.438807 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 222 |   1010.658923 |    364.783836 | David Orr                                                                                                                                                                            |
| 223 |    520.678499 |    773.097869 | Jaime Headden                                                                                                                                                                        |
| 224 |     89.098217 |    620.151047 | Stemonitis (photography) and T. Michael Keesey (vectorization)                                                                                                                       |
| 225 |    165.663475 |    606.826292 | Yan Wong from photo by Denes Emoke                                                                                                                                                   |
| 226 |     18.586619 |    661.709569 | Beth Reinke                                                                                                                                                                          |
| 227 |    932.825792 |    702.945796 | Natalie Claunch                                                                                                                                                                      |
| 228 |     11.476680 |    424.304742 | Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus                                                             |
| 229 |    447.394778 |      9.212289 | Melissa Broussard                                                                                                                                                                    |
| 230 |    173.676997 |     68.687570 | Ingo Braasch                                                                                                                                                                         |
| 231 |    585.684043 |    793.070814 | Ferran Sayol                                                                                                                                                                         |
| 232 |    637.606946 |    249.666663 | Zimices                                                                                                                                                                              |
| 233 |   1013.589850 |     79.655683 | Matt Crook                                                                                                                                                                           |
| 234 |    401.008132 |    395.958366 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 235 |    487.498976 |    404.894778 | Rebecca Groom                                                                                                                                                                        |
| 236 |    344.952538 |    118.578361 | Collin Gross                                                                                                                                                                         |
| 237 |    895.480632 |    365.018737 | Matt Crook                                                                                                                                                                           |
| 238 |      8.240654 |     74.823809 | Zimices                                                                                                                                                                              |
| 239 |    276.776563 |     90.879352 | T. Michael Keesey (after Heinrich Harder)                                                                                                                                            |
| 240 |    732.353949 |    793.599566 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 241 |    239.981873 |    556.257652 | Stacy Spensley (Modified)                                                                                                                                                            |
| 242 |    714.217974 |    180.716543 | S.Martini                                                                                                                                                                            |
| 243 |    367.446337 |    432.327934 | NA                                                                                                                                                                                   |
| 244 |    404.880985 |     10.546695 | DW Bapst (modified from Bulman, 1970)                                                                                                                                                |
| 245 |     11.298361 |    281.298882 | Mali’o Kodis, photograph by P. Funch and R.M. Kristensen                                                                                                                             |
| 246 |    465.257937 |    687.940832 | Maxime Dahirel                                                                                                                                                                       |
| 247 |    633.214709 |    648.496370 | Zimices                                                                                                                                                                              |
| 248 |     65.167494 |    132.358700 | NA                                                                                                                                                                                   |
| 249 |    158.757371 |     27.879629 | Matt Crook                                                                                                                                                                           |
| 250 |    711.235936 |    141.915068 | Trond R. Oskars                                                                                                                                                                      |
| 251 |    155.826862 |    443.882496 | Scott Reid                                                                                                                                                                           |
| 252 |    140.497922 |    499.372865 | Theodore W. Pietsch (photography) and T. Michael Keesey (vectorization)                                                                                                              |
| 253 |    484.735226 |    174.433895 | Baheerathan Murugavel                                                                                                                                                                |
| 254 |    427.953250 |    592.295768 | Zimices                                                                                                                                                                              |
| 255 |    229.402942 |    775.021415 | Mathilde Cordellier                                                                                                                                                                  |
| 256 |     69.882530 |    386.810815 | Sarah Werning                                                                                                                                                                        |
| 257 |    259.923797 |    486.775035 | Zimices                                                                                                                                                                              |
| 258 |    117.270343 |    384.620296 | Gareth Monger                                                                                                                                                                        |
| 259 |    202.383839 |    498.983840 | Matus Valach                                                                                                                                                                         |
| 260 |    629.721547 |    406.686599 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                                   |
| 261 |    567.511477 |    595.675088 | NA                                                                                                                                                                                   |
| 262 |    425.964126 |    634.206719 | Chris huh                                                                                                                                                                            |
| 263 |    397.022147 |    218.890728 | Mali’o Kodis, image from the Smithsonian Institution                                                                                                                                 |
| 264 |    377.362630 |    218.842628 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 265 |    833.939058 |    243.956273 | FunkMonk                                                                                                                                                                             |
| 266 |    416.176497 |    582.100198 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                                      |
| 267 |    782.459272 |    615.737501 | Steven Traver                                                                                                                                                                        |
| 268 |    254.431668 |    248.353692 | Zimices                                                                                                                                                                              |
| 269 |    356.760359 |    551.110379 | Gareth Monger                                                                                                                                                                        |
| 270 |    798.188365 |    120.043123 | Jimmy Bernot                                                                                                                                                                         |
| 271 |    318.064189 |    637.251781 | Steven Traver                                                                                                                                                                        |
| 272 |    792.986082 |    307.664383 | NA                                                                                                                                                                                   |
| 273 |     29.986206 |    483.581427 | Martin Kevil                                                                                                                                                                         |
| 274 |    469.746302 |    341.948765 | Gareth Monger                                                                                                                                                                        |
| 275 |     17.430001 |    543.791439 | Sean McCann                                                                                                                                                                          |
| 276 |    346.829936 |     25.500253 | Dean Schnabel                                                                                                                                                                        |
| 277 |    532.281779 |    500.041593 | Matt Crook                                                                                                                                                                           |
| 278 |    338.494970 |    126.526877 | Pete Buchholz                                                                                                                                                                        |
| 279 |    163.987229 |    414.148591 | Matt Crook                                                                                                                                                                           |
| 280 |    749.972007 |    244.300204 | Scott Hartman                                                                                                                                                                        |
| 281 |    175.215517 |    203.995704 | Steven Traver                                                                                                                                                                        |
| 282 |    946.634834 |     76.484029 | Todd Marshall, vectorized by Zimices                                                                                                                                                 |
| 283 |     75.117498 |    198.707392 | NA                                                                                                                                                                                   |
| 284 |    586.023535 |     74.108363 | Shyamal                                                                                                                                                                              |
| 285 |    171.824209 |    217.231446 | Chris huh                                                                                                                                                                            |
| 286 |    435.436306 |    194.121226 | NA                                                                                                                                                                                   |
| 287 |    291.688473 |    425.280593 | NA                                                                                                                                                                                   |
| 288 |    301.579498 |     50.949633 | Chris huh                                                                                                                                                                            |
| 289 |    428.674200 |    301.316861 | xgirouxb                                                                                                                                                                             |
| 290 |    969.724608 |    192.897967 | Manabu Bessho-Uehara                                                                                                                                                                 |
| 291 |    269.847588 |    589.285750 | Michael P. Taylor                                                                                                                                                                    |
| 292 |    488.851105 |    347.359438 | NA                                                                                                                                                                                   |
| 293 |    362.287636 |    451.457869 | Scott Hartman                                                                                                                                                                        |
| 294 |    170.194739 |    671.787355 | Philippe Janvier (vectorized by T. Michael Keesey)                                                                                                                                   |
| 295 |    431.075284 |    283.615003 | Matt Crook                                                                                                                                                                           |
| 296 |    275.501019 |    198.682389 | S.Martini                                                                                                                                                                            |
| 297 |    795.580593 |     23.240963 | T. Michael Keesey (after Kukalová)                                                                                                                                                   |
| 298 |    521.779327 |    479.169167 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 299 |     24.230923 |    622.052343 | Beth Reinke                                                                                                                                                                          |
| 300 |    658.355507 |    239.003494 | Jack Mayer Wood                                                                                                                                                                      |
| 301 |    654.118183 |    663.796734 | Lee Harding (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                          |
| 302 |    142.199486 |    309.000941 | Jagged Fang Designs                                                                                                                                                                  |
| 303 |    492.848596 |    426.635400 | xgirouxb                                                                                                                                                                             |
| 304 |    210.855390 |    232.514151 | Margot Michaud                                                                                                                                                                       |
| 305 |    257.270832 |    581.339068 | Nobu Tamura, modified by Andrew A. Farke                                                                                                                                             |
| 306 |    208.786231 |    485.830905 |                                                                                                                                                                                      |
| 307 |    325.531639 |    535.708678 | Chris huh                                                                                                                                                                            |
| 308 |    418.537334 |    786.793208 | Matt Crook                                                                                                                                                                           |
| 309 |    366.556119 |    768.031775 | NA                                                                                                                                                                                   |
| 310 |    910.040899 |    411.024052 | Scott Hartman                                                                                                                                                                        |
| 311 |    414.502661 |    544.905287 | Terpsichores                                                                                                                                                                         |
| 312 |    915.870527 |    320.371018 | Gareth Monger                                                                                                                                                                        |
| 313 |    758.514117 |    573.082420 | NA                                                                                                                                                                                   |
| 314 |    996.484467 |     71.539777 | L.M. Davalos                                                                                                                                                                         |
| 315 |   1015.962065 |     48.984690 | Margot Michaud                                                                                                                                                                       |
| 316 |    383.024652 |    749.269159 | Tracy A. Heath                                                                                                                                                                       |
| 317 |    482.054350 |    759.909785 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 318 |    456.811059 |    115.851622 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 319 |    628.497187 |    182.917131 | Gareth Monger                                                                                                                                                                        |
| 320 |     34.552847 |    395.738170 | Scott Hartman                                                                                                                                                                        |
| 321 |    510.693521 |    339.013995 | Ferran Sayol                                                                                                                                                                         |
| 322 |     99.459279 |    613.571777 | Abraão Leite                                                                                                                                                                         |
| 323 |    527.515279 |    256.291764 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 324 |    586.959042 |    135.790759 | Geoff Shaw                                                                                                                                                                           |
| 325 |     11.178243 |    380.908896 | wsnaccad                                                                                                                                                                             |
| 326 |    183.587750 |    501.478660 | Matthew E. Clapham                                                                                                                                                                   |
| 327 |    856.606366 |    424.939224 | Tasman Dixon                                                                                                                                                                         |
| 328 |    577.974499 |    706.809669 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 329 |   1010.131526 |    228.898717 | Margot Michaud                                                                                                                                                                       |
| 330 |    960.227531 |    248.752295 | Jagged Fang Designs                                                                                                                                                                  |
| 331 |    454.991223 |    783.910833 | Cristopher Silva                                                                                                                                                                     |
| 332 |    559.043098 |    675.820748 | Ignacio Contreras                                                                                                                                                                    |
| 333 |    527.354679 |    709.505421 | Margot Michaud                                                                                                                                                                       |
| 334 |    627.961895 |    205.032106 | Steven Traver                                                                                                                                                                        |
| 335 |    866.766687 |    603.034605 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 336 |    621.657294 |    132.427931 | Kelly                                                                                                                                                                                |
| 337 |    844.295335 |    555.083061 | Rebecca Groom                                                                                                                                                                        |
| 338 |   1015.672082 |     26.180994 | Dmitry Bogdanov                                                                                                                                                                      |
| 339 |     33.083762 |    706.870738 | Jessica Anne Miller                                                                                                                                                                  |
| 340 |    857.336280 |     14.044007 | Margot Michaud                                                                                                                                                                       |
| 341 |    521.667826 |    495.860962 | A. H. Baldwin (vectorized by T. Michael Keesey)                                                                                                                                      |
| 342 |    201.885298 |    725.570724 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 343 |    696.304911 |    418.149377 | Rachel Shoop                                                                                                                                                                         |
| 344 |    805.574865 |    232.141342 | Margot Michaud                                                                                                                                                                       |
| 345 |    271.981761 |    137.595452 | Eric Moody                                                                                                                                                                           |
| 346 |    100.631945 |    521.530326 | Josep Marti Solans                                                                                                                                                                   |
| 347 |    639.949280 |    761.419687 | Douglas Brown (modified by T. Michael Keesey)                                                                                                                                        |
| 348 |    757.397446 |    464.963752 | Scott Hartman                                                                                                                                                                        |
| 349 |    344.041120 |    678.395288 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                                     |
| 350 |    899.463978 |    490.186582 | Katie S. Collins                                                                                                                                                                     |
| 351 |    571.193509 |    145.538368 | Jakovche                                                                                                                                                                             |
| 352 |    856.694577 |    481.226375 | Alex Slavenko                                                                                                                                                                        |
| 353 |    699.176267 |    272.008219 | Ferran Sayol                                                                                                                                                                         |
| 354 |   1012.419790 |    576.554318 | NA                                                                                                                                                                                   |
| 355 |     72.169457 |    230.710904 | Margot Michaud                                                                                                                                                                       |
| 356 |    647.090129 |    214.307619 | Jagged Fang Designs                                                                                                                                                                  |
| 357 |     21.744838 |    637.002499 | FunkMonk (Michael B. H.)                                                                                                                                                             |
| 358 |    292.934979 |    184.484905 | Matt Crook                                                                                                                                                                           |
| 359 |    407.448185 |    153.723119 | J. J. Harrison (photo) & T. Michael Keesey                                                                                                                                           |
| 360 |    490.084095 |    553.885444 | Melissa Broussard                                                                                                                                                                    |
| 361 |    554.434995 |    354.478667 | Mali’o Kodis, image from the Smithsonian Institution                                                                                                                                 |
| 362 |    276.213530 |    700.150933 | NA                                                                                                                                                                                   |
| 363 |    807.033139 |    609.278493 | Margot Michaud                                                                                                                                                                       |
| 364 |    658.210801 |    740.915501 | Margot Michaud                                                                                                                                                                       |
| 365 |    661.183116 |    416.004055 | Martien Brand (original photo), Renato Santos (vector silhouette)                                                                                                                    |
| 366 |    103.371263 |    690.942157 | Markus A. Grohme                                                                                                                                                                     |
| 367 |    184.465986 |    677.280664 | NA                                                                                                                                                                                   |
| 368 |    504.244017 |    392.147864 | Anthony Caravaggi                                                                                                                                                                    |
| 369 |    246.952926 |    680.109700 | Katie S. Collins                                                                                                                                                                     |
| 370 |    314.945451 |    339.385548 | Zimices                                                                                                                                                                              |
| 371 |     88.100018 |    583.499649 | NA                                                                                                                                                                                   |
| 372 |    393.175956 |    321.698727 | NA                                                                                                                                                                                   |
| 373 |    496.013673 |    783.870374 | Andy Wilson                                                                                                                                                                          |
| 374 |    208.063844 |    347.963858 | Christoph Schomburg                                                                                                                                                                  |
| 375 |    518.074908 |    283.256405 | NA                                                                                                                                                                                   |
| 376 |    693.521428 |    791.706960 | Ferran Sayol                                                                                                                                                                         |
| 377 |    245.037640 |    793.198334 | Matt Crook                                                                                                                                                                           |
| 378 |    885.434462 |    255.180973 | Tracy A. Heath                                                                                                                                                                       |
| 379 |    501.331795 |    461.105212 | T. Michael Keesey                                                                                                                                                                    |
| 380 |    830.470811 |    637.481062 | Kent Elson Sorgon                                                                                                                                                                    |
| 381 |    169.894577 |    575.025901 | Dean Schnabel                                                                                                                                                                        |
| 382 |    475.847553 |    768.375189 | Daniel Stadtmauer                                                                                                                                                                    |
| 383 |    703.909509 |    725.140989 | Scott Hartman                                                                                                                                                                        |
| 384 |    893.294367 |    695.701262 | Sharon Wegner-Larsen                                                                                                                                                                 |
| 385 |    318.186133 |    352.302084 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                                     |
| 386 |    867.745807 |    458.683352 | Markus A. Grohme                                                                                                                                                                     |
| 387 |    940.305663 |    643.817517 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                                               |
| 388 |    616.579296 |    115.424976 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 389 |     30.436128 |    359.841701 | Kamil S. Jaron                                                                                                                                                                       |
| 390 |    947.653187 |    183.471065 | Donovan Reginald Rosevear (vectorized by T. Michael Keesey)                                                                                                                          |
| 391 |    388.823216 |    399.837815 | Christoph Schomburg                                                                                                                                                                  |
| 392 |    592.887395 |    605.174811 | Tasman Dixon                                                                                                                                                                         |
| 393 |    705.024592 |    425.656843 | Matt Crook                                                                                                                                                                           |
| 394 |    791.975496 |    599.850864 | Jagged Fang Designs                                                                                                                                                                  |
| 395 |     44.650118 |    649.510378 | Gareth Monger                                                                                                                                                                        |
| 396 |    378.157675 |    253.713958 | Matt Crook                                                                                                                                                                           |
| 397 |    634.806072 |    451.846922 | Zimices                                                                                                                                                                              |
| 398 |    219.448314 |    680.634788 | NA                                                                                                                                                                                   |
| 399 |    648.918366 |    302.940358 | Margot Michaud                                                                                                                                                                       |
| 400 |    120.920337 |    513.794711 | Tasman Dixon                                                                                                                                                                         |
| 401 |    170.099345 |    454.924887 | NA                                                                                                                                                                                   |
| 402 |    490.844068 |    387.150472 | Matt Crook                                                                                                                                                                           |
| 403 |    353.241917 |    747.572698 | Katie S. Collins                                                                                                                                                                     |
| 404 |    257.958005 |    509.876936 | Michelle Site                                                                                                                                                                        |
| 405 |    469.667074 |    379.941955 | Zimices                                                                                                                                                                              |
| 406 |    652.882662 |    112.729571 | Ferran Sayol                                                                                                                                                                         |
| 407 |    332.161888 |    318.055769 | Margot Michaud                                                                                                                                                                       |
| 408 |   1016.262239 |    439.272501 | Jaime Chirinos (vectorized by T. Michael Keesey)                                                                                                                                     |
| 409 |   1005.149076 |    283.872716 | Ferran Sayol                                                                                                                                                                         |
| 410 |    145.742897 |    267.686568 | T. Michael Keesey                                                                                                                                                                    |
| 411 |    876.061470 |     36.336316 | Iain Reid                                                                                                                                                                            |
| 412 |    617.925238 |     76.389549 | Chris huh                                                                                                                                                                            |
| 413 |    204.494709 |    687.033520 | Matt Crook                                                                                                                                                                           |
| 414 |    668.811443 |    223.223194 | Raven Amos                                                                                                                                                                           |
| 415 |    853.209935 |    133.815947 | Jaime Headden                                                                                                                                                                        |
| 416 |    344.545738 |     90.643056 | David Orr                                                                                                                                                                            |
| 417 |     28.649395 |    240.689380 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 418 |    153.784676 |    639.048725 | NA                                                                                                                                                                                   |
| 419 |    954.741688 |    168.495732 | Zimices                                                                                                                                                                              |
| 420 |    652.161132 |    293.108287 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 421 |    137.416188 |    152.835476 | NA                                                                                                                                                                                   |
| 422 |    983.805304 |    270.343002 | Metalhead64 (vectorized by T. Michael Keesey)                                                                                                                                        |
| 423 |    734.616644 |    705.231339 | Chris huh                                                                                                                                                                            |
| 424 |    717.403963 |    684.583310 | Ferran Sayol                                                                                                                                                                         |
| 425 |    755.598271 |    449.051852 | NA                                                                                                                                                                                   |
| 426 |    204.186242 |    636.395432 | NA                                                                                                                                                                                   |
| 427 |    540.249098 |    378.121016 | Tasman Dixon                                                                                                                                                                         |
| 428 |    151.820504 |    496.255997 | Douglas Brown (modified by T. Michael Keesey)                                                                                                                                        |
| 429 |    622.945348 |    667.612929 | Noah Schlottman, photo from Casey Dunn                                                                                                                                               |
| 430 |    233.813463 |    161.093902 | Steven Traver                                                                                                                                                                        |
| 431 |    544.484953 |    303.294809 | Matus Valach                                                                                                                                                                         |
| 432 |    319.477857 |    519.080842 | Andy Wilson                                                                                                                                                                          |
| 433 |    511.892793 |    223.816222 | Steven Coombs                                                                                                                                                                        |
| 434 |    667.717918 |    588.710735 | Zimices                                                                                                                                                                              |
| 435 |    998.273209 |    571.398415 | RS                                                                                                                                                                                   |
| 436 |    725.158885 |    527.570403 | Zimices                                                                                                                                                                              |
| 437 |    117.497349 |    568.302959 | FunkMonk                                                                                                                                                                             |
| 438 |    764.811126 |    327.126676 | Mason McNair                                                                                                                                                                         |
| 439 |    655.959442 |    194.579423 | FunkMonk (Michael B. H.)                                                                                                                                                             |
| 440 |     77.656327 |    633.865468 | NA                                                                                                                                                                                   |
| 441 |   1010.811513 |    694.283857 | NA                                                                                                                                                                                   |
| 442 |    447.109406 |     94.801688 | Scott Reid                                                                                                                                                                           |
| 443 |    247.030419 |    745.922692 | Ludwik Gasiorowski                                                                                                                                                                   |
| 444 |    265.326224 |    518.027068 | Adrian Reich                                                                                                                                                                         |
| 445 |    228.047623 |    543.595337 | NA                                                                                                                                                                                   |
| 446 |    154.808249 |    671.668582 | Matt Crook                                                                                                                                                                           |
| 447 |    530.336192 |    190.010101 | Steven Haddock • Jellywatch.org                                                                                                                                                      |
| 448 |    915.505905 |    772.489011 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 449 |    590.650848 |    154.492878 | David Orr                                                                                                                                                                            |
| 450 |     91.250876 |    224.559136 | Beth Reinke                                                                                                                                                                          |
| 451 |    362.340480 |    790.610091 | Jessica Rick                                                                                                                                                                         |
| 452 |    885.369888 |    785.180557 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 453 |    107.545288 |    241.364099 | Gareth Monger                                                                                                                                                                        |
| 454 |    196.170816 |    471.282787 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 455 |    282.541009 |    148.971439 | Matt Crook                                                                                                                                                                           |
| 456 |    870.489699 |    112.777148 | Chris huh                                                                                                                                                                            |
| 457 |    651.694966 |    611.652265 | Chris huh                                                                                                                                                                            |
| 458 |    331.958885 |    620.662708 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 459 |    445.368111 |    314.563595 | Armin Reindl                                                                                                                                                                         |
| 460 |      5.110502 |    626.932846 | Kanchi Nanjo                                                                                                                                                                         |
| 461 |    926.187950 |    204.458533 | NA                                                                                                                                                                                   |
| 462 |    650.371092 |    680.713824 | Skye M                                                                                                                                                                               |
| 463 |    564.230174 |    100.744348 | Alex Slavenko                                                                                                                                                                        |
| 464 |    797.796696 |    786.426354 | Zimices                                                                                                                                                                              |
| 465 |    342.455344 |    498.003069 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                                         |
| 466 |    210.387407 |    365.937993 | Dean Schnabel                                                                                                                                                                        |
| 467 |      8.213470 |    355.750680 | Chris huh                                                                                                                                                                            |
| 468 |    181.620376 |    640.438001 | Melissa Ingala                                                                                                                                                                       |
| 469 |    646.411259 |    652.597083 | NA                                                                                                                                                                                   |
| 470 |    578.685768 |    510.867651 | Zimices                                                                                                                                                                              |
| 471 |    839.684821 |    426.011702 | Zimices                                                                                                                                                                              |
| 472 |    655.871822 |    546.434401 | Ferran Sayol                                                                                                                                                                         |
| 473 |   1000.078906 |    442.247197 | Zimices                                                                                                                                                                              |
| 474 |    879.700814 |    556.187227 | NA                                                                                                                                                                                   |
| 475 |   1009.927105 |    598.855545 | Zimices                                                                                                                                                                              |
| 476 |    619.194447 |     36.054253 | Jagged Fang Designs                                                                                                                                                                  |
| 477 |     36.139631 |    660.699569 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                                       |
| 478 |    228.020812 |     92.708094 | Markus A. Grohme                                                                                                                                                                     |
| 479 |    977.427457 |    102.557122 | Steven Traver                                                                                                                                                                        |
| 480 |    289.881582 |    164.938828 | Juan Carlos Jerí                                                                                                                                                                     |
| 481 |    468.556415 |    776.138043 | Isaure Scavezzoni                                                                                                                                                                    |
| 482 |    668.719421 |    279.575648 | NA                                                                                                                                                                                   |
| 483 |    519.130303 |      4.774344 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                                       |
| 484 |    784.715502 |    629.921628 | Ekaterina Kopeykina (vectorized by T. Michael Keesey)                                                                                                                                |
| 485 |    743.889369 |    515.508430 | Steven Traver                                                                                                                                                                        |
| 486 |    336.520422 |    335.107200 | Maija Karala                                                                                                                                                                         |
| 487 |    256.324725 |    692.869822 | Michelle Site                                                                                                                                                                        |
| 488 |    777.230863 |    439.902715 | B Kimmel                                                                                                                                                                             |
| 489 |    711.195454 |    291.714567 | NA                                                                                                                                                                                   |
| 490 |    246.033531 |    590.629341 | Young and Zhao (1972:figure 4), modified by Michael P. Taylor                                                                                                                        |
| 491 |    186.900723 |    462.329282 | T. Michael Keesey                                                                                                                                                                    |
| 492 |    394.218130 |    731.783010 | NA                                                                                                                                                                                   |
| 493 |    311.250721 |    550.224884 | Jagged Fang Designs                                                                                                                                                                  |
| 494 |    580.733054 |    124.245307 | Richard J. Harris                                                                                                                                                                    |
| 495 |    901.260058 |    470.906041 | NA                                                                                                                                                                                   |
| 496 |     57.290918 |    180.520305 | Maxime Dahirel                                                                                                                                                                       |
| 497 |    356.080661 |    100.409704 | Kanchi Nanjo                                                                                                                                                                         |
| 498 |    312.330724 |     70.222300 | Cathy                                                                                                                                                                                |
| 499 |    997.842980 |    789.159718 | Gareth Monger                                                                                                                                                                        |
| 500 |    372.896266 |    737.035871 | Margot Michaud                                                                                                                                                                       |
| 501 |    869.731387 |    107.526568 | Dmitry Bogdanov                                                                                                                                                                      |
| 502 |    872.700099 |     31.874486 | Matt Martyniuk (modified by Serenchia)                                                                                                                                               |
| 503 |     99.311033 |    421.049995 | Chris huh                                                                                                                                                                            |
| 504 |    195.147769 |    618.939389 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 505 |    717.394160 |    187.117411 | Chris huh                                                                                                                                                                            |
| 506 |     58.360017 |    621.023049 | Matt Crook                                                                                                                                                                           |
| 507 |    915.069961 |    380.471746 | Tyler Greenfield                                                                                                                                                                     |
| 508 |    745.332921 |    443.645178 | Gareth Monger                                                                                                                                                                        |
| 509 |    542.960293 |    127.141582 | Chris huh                                                                                                                                                                            |
| 510 |    379.783573 |    264.297832 | Zimices                                                                                                                                                                              |
| 511 |    407.965946 |    609.325135 | Dave Angelini                                                                                                                                                                        |
| 512 |    532.659759 |    390.387762 | Margot Michaud                                                                                                                                                                       |
| 513 |    821.158081 |    572.441193 | Margot Michaud                                                                                                                                                                       |
| 514 |    366.125043 |      7.162402 | Zimices                                                                                                                                                                              |
| 515 |    181.925206 |     25.454708 | Crystal Maier                                                                                                                                                                        |
| 516 |    743.834944 |    394.371050 | Julio Garza                                                                                                                                                                          |
| 517 |    392.006171 |    641.764164 | Joseph Wolf, 1863 (vectorization by Dinah Challen)                                                                                                                                   |
| 518 |    172.448440 |    166.490954 | Ghedoghedo, vectorized by Zimices                                                                                                                                                    |
| 519 |    223.179185 |    497.917543 | Andy Wilson                                                                                                                                                                          |
| 520 |    648.232009 |    273.037793 | Richard Parker (vectorized by T. Michael Keesey)                                                                                                                                     |
| 521 |    582.601714 |    623.108594 | Kimberly Haddrell                                                                                                                                                                    |
| 522 |    820.464422 |    388.116062 | Chris huh                                                                                                                                                                            |
| 523 |    563.243728 |    790.105509 | Yan Wong from drawing in The Century Dictionary (1911)                                                                                                                               |
| 524 |    112.724548 |    124.693462 | Chloé Schmidt                                                                                                                                                                        |
| 525 |    345.772869 |    721.828638 | Mike Hanson                                                                                                                                                                          |
| 526 |    119.970033 |    240.746741 | Alex Slavenko                                                                                                                                                                        |
| 527 |     98.625539 |    472.972956 | Dean Schnabel                                                                                                                                                                        |
| 528 |    387.971670 |     13.874321 | Jagged Fang Designs                                                                                                                                                                  |
| 529 |    205.995304 |    479.212544 | NA                                                                                                                                                                                   |
| 530 |    367.360175 |    781.354854 | Andrew A. Farke, modified from original by H. Milne Edwards                                                                                                                          |
| 531 |    901.363161 |    404.037935 | Maxime Dahirel                                                                                                                                                                       |
| 532 |    732.433219 |    686.712926 | Rachel Shoop                                                                                                                                                                         |
| 533 |     91.625120 |    196.255683 | Tasman Dixon                                                                                                                                                                         |
| 534 |    242.257708 |    222.360116 | Gareth Monger                                                                                                                                                                        |
| 535 |    677.154017 |    357.595346 | Juan Carlos Jerí                                                                                                                                                                     |
| 536 |    296.771238 |     77.394266 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 537 |    720.501589 |    546.707313 | Ferran Sayol                                                                                                                                                                         |
| 538 |    233.820707 |    199.695417 | Wynston Cooper (photo) and Albertonykus (silhouette)                                                                                                                                 |
| 539 |    997.846535 |    422.651781 | NA                                                                                                                                                                                   |
| 540 |    761.852807 |    541.208679 | Michael Scroggie                                                                                                                                                                     |
| 541 |    984.830957 |    180.509206 | Gareth Monger                                                                                                                                                                        |
| 542 |    157.929679 |     87.701050 | Gareth Monger                                                                                                                                                                        |
| 543 |    635.866451 |    731.935733 | Matt Crook                                                                                                                                                                           |
| 544 |    417.953650 |    172.556686 | Bennet McComish, photo by Hans Hillewaert                                                                                                                                            |
| 545 |    956.521966 |    779.483529 | Tess Linden                                                                                                                                                                          |
| 546 |    901.214089 |    575.687103 | Zimices                                                                                                                                                                              |
| 547 |    103.781731 |    397.727289 | Ferran Sayol                                                                                                                                                                         |
| 548 |    830.991320 |    489.334102 | T. Michael Keesey                                                                                                                                                                    |
| 549 |    142.291469 |    180.350504 | Ghedoghedo, vectorized by Zimices                                                                                                                                                    |
| 550 |    693.903709 |    353.161620 | Tauana J. Cunha                                                                                                                                                                      |
| 551 |    238.833289 |    472.119405 | Frank Förster                                                                                                                                                                        |
| 552 |     56.615464 |    703.255004 | Chris huh                                                                                                                                                                            |
| 553 |    198.867305 |     34.716093 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 554 |    792.999347 |    364.371462 | Becky Barnes                                                                                                                                                                         |
| 555 |    456.682010 |    227.254173 | Chris huh                                                                                                                                                                            |
| 556 |    928.824011 |    196.490860 | Steven Traver                                                                                                                                                                        |
| 557 |     73.197918 |    162.047077 | NA                                                                                                                                                                                   |
| 558 |    903.039100 |    325.854010 | Matt Crook                                                                                                                                                                           |
| 559 |     16.895219 |    599.030282 | Tasman Dixon                                                                                                                                                                         |
| 560 |    387.757715 |    766.303809 | Sarah Werning                                                                                                                                                                        |
| 561 |      8.627061 |     27.005641 | terngirl                                                                                                                                                                             |
| 562 |    827.319903 |    114.149012 | Margot Michaud                                                                                                                                                                       |
| 563 |    723.431686 |    220.086774 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                                     |
| 564 |     22.608228 |    257.191000 | Matt Crook                                                                                                                                                                           |
| 565 |      8.714118 |    152.311592 | Chase Brownstein                                                                                                                                                                     |
| 566 |    146.944921 |    347.846856 | Sherman Foote Denton (illustration, 1897) and Timothy J. Bartley (silhouette)                                                                                                        |
| 567 |    927.280655 |    187.658207 | Andy Wilson                                                                                                                                                                          |
| 568 |   1010.999116 |    667.623849 | Dean Schnabel                                                                                                                                                                        |
| 569 |    293.506844 |    247.840814 | Nobu Tamura                                                                                                                                                                          |
| 570 |    222.551592 |    743.973079 | Lukasiniho                                                                                                                                                                           |
| 571 |    323.448765 |    198.352200 | Felix Vaux                                                                                                                                                                           |
| 572 |    561.809230 |    561.817857 | Christine Axon                                                                                                                                                                       |
| 573 |    382.730148 |    228.710548 | Gareth Monger                                                                                                                                                                        |
| 574 |    294.374343 |    350.594739 | Andy Wilson                                                                                                                                                                          |
| 575 |     98.273297 |     55.714624 | NA                                                                                                                                                                                   |
| 576 |    589.993215 |    581.584723 | FunkMonk                                                                                                                                                                             |
| 577 |    132.685605 |    688.707488 | Rebecca Groom                                                                                                                                                                        |
| 578 |    453.055041 |    273.901823 | Michael Scroggie                                                                                                                                                                     |
| 579 |     75.497738 |    610.286988 | Tyler Greenfield                                                                                                                                                                     |
| 580 |    641.888359 |    477.100282 | T. Michael Keesey                                                                                                                                                                    |
| 581 |    816.955393 |    188.914978 | Meliponicultor Itaymbere                                                                                                                                                             |
| 582 |    807.889383 |    460.771941 | Mr E? (vectorized by T. Michael Keesey)                                                                                                                                              |
| 583 |    395.620054 |    740.379949 | Eduard Solà Vázquez, vectorised by Yan Wong                                                                                                                                          |
| 584 |    158.652985 |    136.914549 | Margot Michaud                                                                                                                                                                       |
| 585 |    227.515873 |    235.728089 | Jagged Fang Designs                                                                                                                                                                  |
| 586 |    105.638880 |    640.740853 | Kosta Mumcuoglu (vectorized by T. Michael Keesey)                                                                                                                                    |
| 587 |    542.287582 |    676.918535 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 588 |    336.756565 |    310.615778 | Scott Hartman                                                                                                                                                                        |
| 589 |    981.563153 |    166.855217 | Trond R. Oskars                                                                                                                                                                      |
| 590 |    560.708914 |    635.813328 | T. Michael Keesey (after Masteraah)                                                                                                                                                  |
| 591 |    319.250749 |    448.353757 | Chris huh                                                                                                                                                                            |
| 592 |    494.527374 |    188.776371 | Zimices                                                                                                                                                                              |
| 593 |    613.907815 |    592.641984 | Margot Michaud                                                                                                                                                                       |
| 594 |    149.756307 |    147.700286 | Felix Vaux                                                                                                                                                                           |
| 595 |    155.627918 |    486.013527 | Original drawing by Nobu Tamura, vectorized by Roberto Díaz Sibaja                                                                                                                   |
| 596 |    439.794062 |    767.866020 | Matthew Hooge (vectorized by T. Michael Keesey)                                                                                                                                      |
| 597 |    526.991847 |    241.682505 | Steven Traver                                                                                                                                                                        |
| 598 |    101.781590 |    408.588880 | Margot Michaud                                                                                                                                                                       |
| 599 |    238.497572 |    538.635817 | NA                                                                                                                                                                                   |
| 600 |    426.772100 |    148.511055 | Jaime Headden                                                                                                                                                                        |
| 601 |    230.632033 |    732.212260 | Andrew R. Gehrke                                                                                                                                                                     |
| 602 |    798.088048 |    569.601924 | Tasman Dixon                                                                                                                                                                         |
| 603 |    323.194814 |    507.681992 | Gareth Monger                                                                                                                                                                        |
| 604 |     13.657268 |    366.548719 | Juan Carlos Jerí                                                                                                                                                                     |
| 605 |    346.467243 |    507.342412 | Steven Traver                                                                                                                                                                        |
| 606 |    133.136089 |    258.808093 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 607 |    737.909378 |    123.875176 | Tauana J. Cunha                                                                                                                                                                      |
| 608 |    356.105661 |    368.764274 | Lauren Sumner-Rooney                                                                                                                                                                 |
| 609 |    100.376208 |    211.525937 | Caroline Harding, MAF (vectorized by T. Michael Keesey)                                                                                                                              |
| 610 |    333.404851 |    255.119947 | Mathieu Pélissié                                                                                                                                                                     |
| 611 |    503.896513 |    376.532507 | Matt Crook                                                                                                                                                                           |
| 612 |    999.435437 |     85.947278 | T. Michael Keesey                                                                                                                                                                    |
| 613 |    544.897247 |     15.801791 | Kanchi Nanjo                                                                                                                                                                         |
| 614 |    385.155737 |    661.429638 | Zimices                                                                                                                                                                              |
| 615 |     57.312842 |    780.908539 | Ferran Sayol                                                                                                                                                                         |
| 616 |    654.382512 |    230.998079 | Zimices                                                                                                                                                                              |
| 617 |    283.450703 |    130.828545 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 618 |     69.315744 |    211.295722 | Zimices                                                                                                                                                                              |
| 619 |   1003.377017 |    392.223501 | Conty                                                                                                                                                                                |
| 620 |     83.390079 |     35.014081 | Jaime Headden                                                                                                                                                                        |
| 621 |    890.358997 |    125.899523 | Sam Fraser-Smith (vectorized by T. Michael Keesey)                                                                                                                                   |
| 622 |    995.839945 |     51.216405 | T. Michael Keesey (after Masteraah)                                                                                                                                                  |
| 623 |    340.027511 |    630.285540 | NA                                                                                                                                                                                   |
| 624 |    325.655908 |    544.652953 | Zimices                                                                                                                                                                              |
| 625 |     21.059417 |    168.508088 | Felix Vaux                                                                                                                                                                           |
| 626 |    713.791070 |    100.353262 | Fritz Geller-Grimm (vectorized by T. Michael Keesey)                                                                                                                                 |
| 627 |    229.256487 |    456.903892 | Katie S. Collins                                                                                                                                                                     |
| 628 |      3.958981 |    319.891243 | T. Michael Keesey                                                                                                                                                                    |
| 629 |    648.619325 |    561.001780 | Kamil S. Jaron                                                                                                                                                                       |
| 630 |    166.777600 |    476.996706 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                                          |
| 631 |    930.660434 |    380.090447 | Andy Wilson                                                                                                                                                                          |
| 632 |    313.363460 |    267.720642 | Julio Garza                                                                                                                                                                          |
| 633 |      5.051622 |    765.099533 | L. Shyamal                                                                                                                                                                           |
| 634 |    270.740563 |    746.367298 | Melissa Broussard                                                                                                                                                                    |
| 635 |    817.728948 |    400.125706 | Julio Garza                                                                                                                                                                          |
| 636 |    526.291782 |    463.683807 | Gareth Monger                                                                                                                                                                        |
| 637 |    983.878593 |    563.220446 | T. Michael Keesey (vectorization); Thorsten Assmann, Jörn Buse, Claudia Drees, Ariel-Leib-Leonid Friedman, Tal Levanony, Andrea Matern, Anika Timm, and David W. Wrase (photography) |
| 638 |    479.687628 |    633.464822 | Steven Traver                                                                                                                                                                        |
| 639 |    596.729763 |    106.136083 | Neil Kelley                                                                                                                                                                          |
| 640 |    495.941455 |    230.847720 | T. Michael Keesey                                                                                                                                                                    |
| 641 |    191.883121 |    633.776130 | Zimices                                                                                                                                                                              |
| 642 |     17.427444 |    330.577200 | Lauren Sumner-Rooney                                                                                                                                                                 |
| 643 |    527.046509 |    111.354913 | Antonov (vectorized by T. Michael Keesey)                                                                                                                                            |
| 644 |    678.010656 |    609.890790 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                              |
| 645 |    653.268427 |    384.194331 | Ferran Sayol                                                                                                                                                                         |
| 646 |    644.715911 |    428.478085 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 647 |    382.306143 |    680.545247 | Jagged Fang Designs                                                                                                                                                                  |
| 648 |    615.809967 |    143.774251 | Margot Michaud                                                                                                                                                                       |
| 649 |    403.727998 |    771.278712 | Leon P. A. M. Claessens, Patrick M. O’Connor, David M. Unwin                                                                                                                         |
| 650 |    886.004547 |     80.244348 | Chris huh                                                                                                                                                                            |
| 651 |    684.400681 |     90.935122 | Mali’o Kodis, image from the “Proceedings of the Zoological Society of London”                                                                                                       |
| 652 |    372.584734 |    664.812494 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                              |
| 653 |    250.948891 |    543.175275 | Ferran Sayol                                                                                                                                                                         |
| 654 |    323.963465 |    473.428579 | Ferran Sayol                                                                                                                                                                         |
| 655 |    880.555570 |    516.341962 | Maija Karala                                                                                                                                                                         |
| 656 |    495.897174 |    361.322572 | NA                                                                                                                                                                                   |
| 657 |    395.222332 |    668.575019 | NA                                                                                                                                                                                   |
| 658 |    218.355635 |    220.843758 | Zimices                                                                                                                                                                              |
| 659 |    478.160714 |    674.865216 | Sarah Werning                                                                                                                                                                        |
| 660 |    545.235865 |    222.973181 | Katie S. Collins                                                                                                                                                                     |
| 661 |    652.994889 |    129.257802 | \<U+0414\>\<U+0438\>\<U+0411\>\<U+0433\>\<U+0434\> (vectorized by T. Michael Keesey)                                                                                                 |
| 662 |    713.564286 |    444.219493 | Kamil S. Jaron                                                                                                                                                                       |
| 663 |     69.949489 |    180.133939 | Yan Wong from drawing by Joseph Smit                                                                                                                                                 |
| 664 |    668.425986 |    728.277948 | Andy Wilson                                                                                                                                                                          |
| 665 |    974.123880 |    311.111760 | Steven Traver                                                                                                                                                                        |
| 666 |   1016.019248 |    721.732017 | Matt Crook                                                                                                                                                                           |
| 667 |    470.641005 |    443.897420 | Gareth Monger                                                                                                                                                                        |
| 668 |    490.237444 |    748.985565 | Andy Wilson                                                                                                                                                                          |
| 669 |    254.610152 |     98.764007 | Smokeybjb                                                                                                                                                                            |
| 670 |    817.937239 |    668.111309 | John Curtis (vectorized by T. Michael Keesey)                                                                                                                                        |
| 671 |    718.319562 |    246.110738 | Jessica Rick                                                                                                                                                                         |
| 672 |    151.503679 |      7.879163 | Dean Schnabel                                                                                                                                                                        |
| 673 |    675.863243 |    371.887767 | Christoph Schomburg                                                                                                                                                                  |
| 674 |    599.544072 |     77.549637 | Kristina Gagalova                                                                                                                                                                    |
| 675 |    859.436307 |    589.979449 | Margot Michaud                                                                                                                                                                       |
| 676 |    683.758893 |    253.705104 | Matt Crook                                                                                                                                                                           |
| 677 |   1003.969970 |    553.895656 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 678 |    156.252725 |    197.206771 | Alexandre Vong                                                                                                                                                                       |
| 679 |    520.031216 |    445.048834 | Zimices                                                                                                                                                                              |
| 680 |    902.675767 |    216.203808 | Matt Martyniuk                                                                                                                                                                       |
| 681 |    311.794050 |     38.061659 | Andy Wilson                                                                                                                                                                          |
| 682 |    151.261583 |    555.819337 | Amanda Katzer                                                                                                                                                                        |
| 683 |    252.889695 |    711.179335 | Zimices                                                                                                                                                                              |
| 684 |    970.857524 |    552.729518 | Eric Moody                                                                                                                                                                           |
| 685 |    155.436323 |    285.580608 | Melissa Broussard                                                                                                                                                                    |
| 686 |    540.428719 |    167.386446 | Margot Michaud                                                                                                                                                                       |
| 687 |    633.605008 |    438.815742 | Oscar Sanisidro                                                                                                                                                                      |
| 688 |    501.872065 |     50.765238 | Birgit Lang                                                                                                                                                                          |
| 689 |     16.160565 |    522.986049 | Birgit Lang                                                                                                                                                                          |
| 690 |    906.978931 |    564.761546 | NA                                                                                                                                                                                   |
| 691 |     10.503832 |    132.632786 | Gareth Monger                                                                                                                                                                        |
| 692 |    416.599429 |     31.723831 | Lukasiniho                                                                                                                                                                           |
| 693 |    133.241802 |    577.857291 | Cristopher Silva                                                                                                                                                                     |
| 694 |    775.334492 |    793.374494 | Berivan Temiz                                                                                                                                                                        |
| 695 |    264.504581 |    712.803711 | Maxime Dahirel                                                                                                                                                                       |
| 696 |    639.316603 |    263.011737 | Caleb M. Brown                                                                                                                                                                       |
| 697 |    956.071256 |    628.327562 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 698 |    921.000233 |    290.833139 | Kamil S. Jaron                                                                                                                                                                       |
| 699 |    200.731558 |    678.160155 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                                      |
| 700 |    740.596278 |    540.695922 | NA                                                                                                                                                                                   |
| 701 |     25.025030 |    657.040535 | Campbell Fleming                                                                                                                                                                     |
| 702 |    324.161749 |    106.846542 | Sean McCann                                                                                                                                                                          |
| 703 |    448.343323 |     16.677304 | Gareth Monger                                                                                                                                                                        |
| 704 |    866.202175 |    121.121574 | Emily Willoughby                                                                                                                                                                     |
| 705 |     66.918591 |    151.335687 | Timothy Knepp (vectorized by T. Michael Keesey)                                                                                                                                      |
| 706 |    817.803001 |    416.860916 | Matt Crook                                                                                                                                                                           |
| 707 |   1016.340103 |    355.783926 | Margot Michaud                                                                                                                                                                       |
| 708 |    947.280637 |    478.619919 | Ferran Sayol                                                                                                                                                                         |
| 709 |    500.090912 |    501.158798 | Mariana Ruiz (vectorized by T. Michael Keesey)                                                                                                                                       |
| 710 |    852.776131 |    362.237481 | Markus A. Grohme                                                                                                                                                                     |
| 711 |    163.815743 |     11.757297 | Robert Bruce Horsfall (vectorized by William Gearty)                                                                                                                                 |
| 712 |    255.925153 |    344.241580 | Gustav Mützel                                                                                                                                                                        |
| 713 |    778.938665 |    567.937518 | Robert Gay                                                                                                                                                                           |
| 714 |   1010.991796 |    478.734992 | Gareth Monger                                                                                                                                                                        |
| 715 |    313.716371 |    770.185519 | Birgit Lang                                                                                                                                                                          |
| 716 |     30.774319 |      6.725127 | Lily Hughes                                                                                                                                                                          |
| 717 |    767.674632 |    314.354852 | Kanako Bessho-Uehara                                                                                                                                                                 |
| 718 |    275.358528 |    527.485809 | Steven Traver                                                                                                                                                                        |
| 719 |    102.038328 |    678.695750 | Kamil S. Jaron                                                                                                                                                                       |
| 720 |    186.189871 |     12.172452 | Christine Axon                                                                                                                                                                       |
| 721 |    402.860865 |    782.762057 | T. Michael Keesey                                                                                                                                                                    |
| 722 |    525.360842 |    515.424059 | Zimices                                                                                                                                                                              |
| 723 |    754.634232 |     66.139744 | Scott Reid                                                                                                                                                                           |
| 724 |    932.934610 |    176.686053 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 725 |    474.602621 |    307.692243 | Margot Michaud                                                                                                                                                                       |
| 726 |    750.009897 |    794.577073 | Collin Gross                                                                                                                                                                         |
| 727 |    825.824188 |    578.770364 | Matt Crook                                                                                                                                                                           |
| 728 |    475.509310 |    264.344839 | Jose Carlos Arenas-Monroy                                                                                                                                                            |
| 729 |    509.619135 |    231.617315 | Lukasiniho                                                                                                                                                                           |
| 730 |    487.249553 |     45.753956 | Christoph Schomburg                                                                                                                                                                  |
| 731 |    405.402396 |    308.960486 | Margot Michaud                                                                                                                                                                       |
| 732 |    372.064450 |    468.766469 | Steven Traver                                                                                                                                                                        |
| 733 |    898.887399 |    458.124619 | Matt Crook                                                                                                                                                                           |
| 734 |     84.440330 |    241.118273 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 735 |    472.757459 |    372.845845 | Becky Barnes                                                                                                                                                                         |
| 736 |    763.734412 |    607.689083 | T. Michael Keesey (after A. Y. Ivantsov)                                                                                                                                             |
| 737 |    536.204640 |    692.359903 | Christoph Schomburg                                                                                                                                                                  |
| 738 |    311.244608 |    314.394241 | Markus A. Grohme                                                                                                                                                                     |
| 739 |    865.797259 |    704.768881 | Steven Traver                                                                                                                                                                        |
| 740 |    423.619261 |    611.435643 | Hugo Gruson                                                                                                                                                                          |
| 741 |    441.996463 |    211.674157 | Roger Witter, vectorized by Zimices                                                                                                                                                  |
| 742 |    853.572483 |    205.284996 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 743 |      5.525567 |    549.278798 | Kanchi Nanjo                                                                                                                                                                         |
| 744 |    996.263202 |    542.731913 | Martien Brand (original photo), Renato Santos (vector silhouette)                                                                                                                    |
| 745 |    922.733601 |    642.602772 | Bryan Carstens                                                                                                                                                                       |
| 746 |    859.284758 |     81.257815 | Dean Schnabel                                                                                                                                                                        |
| 747 |    298.458052 |    532.913810 | T. Tischler                                                                                                                                                                          |
| 748 |    772.532092 |     45.296201 | Gareth Monger                                                                                                                                                                        |
| 749 |    641.458760 |    385.126035 | Armin Reindl                                                                                                                                                                         |
| 750 |      7.600700 |    413.854988 | Tasman Dixon                                                                                                                                                                         |
| 751 |    842.137376 |    119.636540 | Gareth Monger                                                                                                                                                                        |
| 752 |     45.612721 |    356.703515 | Chris huh                                                                                                                                                                            |
| 753 |    934.006307 |    525.843557 | Matt Crook                                                                                                                                                                           |
| 754 |    982.887842 |      4.975454 | Dean Schnabel                                                                                                                                                                        |
| 755 |    813.019485 |    781.344304 | Zimices                                                                                                                                                                              |
| 756 |     59.457357 |    405.614453 | Gareth Monger                                                                                                                                                                        |
| 757 |    943.118933 |    395.427842 | Matt Crook                                                                                                                                                                           |
| 758 |     21.567072 |    503.789324 | Tasman Dixon                                                                                                                                                                         |
| 759 |    545.507400 |    232.574857 | Tasman Dixon                                                                                                                                                                         |
| 760 |    830.811375 |    525.399624 | T. Michael Keesey                                                                                                                                                                    |
| 761 |    369.253375 |    689.795638 | NA                                                                                                                                                                                   |
| 762 |    559.132099 |    151.412616 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 763 |    273.847883 |    675.788703 | Jagged Fang Designs                                                                                                                                                                  |
| 764 |    533.412253 |    270.542191 | Anthony Caravaggi                                                                                                                                                                    |
| 765 |    656.820461 |    256.711122 | Steven Traver                                                                                                                                                                        |
| 766 |    471.062429 |    355.405836 | Zimices                                                                                                                                                                              |
| 767 |   1015.942585 |    526.538989 | Sharon Wegner-Larsen                                                                                                                                                                 |
| 768 |   1015.996304 |    414.605416 | Matt Crook                                                                                                                                                                           |
| 769 |    931.612176 |    790.984105 | Meyer-Wachsmuth I, Curini Galletti M, Jondelius U (<doi:10.1371/journal.pone.0107688>). Vectorization by Y. Wong                                                                     |
| 770 |    844.442160 |    259.519911 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                                              |
| 771 |    920.044522 |    277.530813 | Mali’o Kodis, photograph by Derek Keats (<http://www.flickr.com/photos/dkeats/>)                                                                                                     |
| 772 |     41.618177 |    694.998643 | Gareth Monger                                                                                                                                                                        |
| 773 |    291.060740 |    542.388302 | Steven Traver                                                                                                                                                                        |
| 774 |    531.506160 |    409.176364 | Matt Crook                                                                                                                                                                           |
| 775 |    114.057799 |    627.044938 | Steven Traver                                                                                                                                                                        |
| 776 |     38.940378 |    604.137303 | Markus A. Grohme                                                                                                                                                                     |
| 777 |    318.200056 |     88.551286 | Matt Crook                                                                                                                                                                           |
| 778 |    436.554324 |    494.048918 | Gareth Monger                                                                                                                                                                        |
| 779 |    634.870187 |    219.981255 | Gareth Monger                                                                                                                                                                        |
| 780 |    282.711041 |    419.467610 | Ferran Sayol                                                                                                                                                                         |
| 781 |    536.589264 |    705.879362 | Zimices                                                                                                                                                                              |
| 782 |     39.113661 |    674.903904 | Scott Hartman                                                                                                                                                                        |
| 783 |    600.305898 |    566.121224 | Zimices                                                                                                                                                                              |
| 784 |    401.596766 |    708.666767 | Tracy A. Heath                                                                                                                                                                       |
| 785 |     44.471623 |    300.601062 | Zimices                                                                                                                                                                              |
| 786 |    597.693366 |    631.758598 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 787 |    768.471436 |    558.175509 | Steve Hillebrand/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                                                   |
| 788 |    993.898965 |    116.426317 | Steven Traver                                                                                                                                                                        |
| 789 |    513.478067 |    188.526368 | Andy Wilson                                                                                                                                                                          |
| 790 |    583.714586 |    639.524030 | Armin Reindl                                                                                                                                                                         |
| 791 |    311.019125 |    627.640909 | Rebecca Groom                                                                                                                                                                        |
| 792 |     89.155075 |    396.047832 | Matt Crook                                                                                                                                                                           |
| 793 |     55.584851 |    369.621359 | Dexter R. Mardis                                                                                                                                                                     |
| 794 |    745.324588 |    146.510997 | Owen Jones                                                                                                                                                                           |
| 795 |   1013.451241 |    133.797415 | Zimices                                                                                                                                                                              |
| 796 |    554.963242 |    687.286534 | Jagged Fang Designs                                                                                                                                                                  |
| 797 |    515.242775 |    308.808530 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                                    |
| 798 |    840.900659 |    214.789633 | Jordan Mallon (vectorized by T. Michael Keesey)                                                                                                                                      |
| 799 |      8.870524 |     62.444438 | Erika Schumacher                                                                                                                                                                     |
| 800 |    210.423334 |     44.706895 | Scott Hartman                                                                                                                                                                        |
| 801 |    588.600290 |    505.739824 | Tasman Dixon                                                                                                                                                                         |
| 802 |    476.664572 |    395.032842 | Matt Crook                                                                                                                                                                           |
| 803 |    273.404478 |    167.628423 | Sean McCann                                                                                                                                                                          |
| 804 |    377.732242 |     51.030236 | Conty (vectorized by T. Michael Keesey)                                                                                                                                              |
| 805 |    389.354775 |    720.705611 | Jessica Anne Miller                                                                                                                                                                  |
| 806 |    984.043085 |     62.261129 | Matt Crook                                                                                                                                                                           |
| 807 |    356.281560 |    670.393288 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                                  |
| 808 |    526.196111 |    632.157184 | Dean Schnabel                                                                                                                                                                        |
| 809 |    988.507693 |    609.459324 | Steven Traver                                                                                                                                                                        |
| 810 |     22.579572 |    407.724531 | Steven Traver                                                                                                                                                                        |
| 811 |    237.304320 |    499.744297 | Tom Tarrant (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                          |
| 812 |    341.381534 |    133.605668 | Daniel Jaron                                                                                                                                                                         |
| 813 |    886.997811 |      1.979967 | Kenneth Lacovara (vectorized by T. Michael Keesey)                                                                                                                                   |
| 814 |    808.771183 |    506.004363 | Matt Crook                                                                                                                                                                           |
| 815 |   1016.415955 |    750.727734 | Steven Traver                                                                                                                                                                        |
| 816 |    701.717189 |    625.023593 | Tauana J. Cunha                                                                                                                                                                      |
| 817 |    929.816906 |    759.047329 | Anthony Caravaggi                                                                                                                                                                    |
| 818 |    880.395113 |    195.789648 | Margot Michaud                                                                                                                                                                       |
| 819 |    364.945423 |    725.494057 | T. Michael Keesey (photo by Darren Swim)                                                                                                                                             |
| 820 |    142.672355 |    702.907456 | Matt Crook                                                                                                                                                                           |
| 821 |    117.960551 |    795.041271 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 822 |    639.428538 |    332.288218 | Steven Traver                                                                                                                                                                        |
| 823 |    220.055832 |    650.789140 | Caleb M. Gordon                                                                                                                                                                      |
| 824 |    807.877581 |    366.483078 | Gareth Monger                                                                                                                                                                        |
| 825 |     18.655718 |    223.873806 | FunkMonk (Michael B. H.)                                                                                                                                                             |
| 826 |    235.084798 |    758.739007 | Gareth Monger                                                                                                                                                                        |
| 827 |    766.942088 |    434.343361 | Jonathan Wells                                                                                                                                                                       |
| 828 |    299.550947 |     88.360730 | Steven Traver                                                                                                                                                                        |
| 829 |    712.737824 |    456.395223 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 830 |    905.357213 |    344.045691 | Ferran Sayol                                                                                                                                                                         |
| 831 |    185.814375 |     87.603688 | David Tana                                                                                                                                                                           |
| 832 |    688.852286 |    270.403476 | Collin Gross                                                                                                                                                                         |
| 833 |    935.606411 |    296.376398 | Michael Scroggie                                                                                                                                                                     |
| 834 |    646.134017 |    505.460200 | Aadx                                                                                                                                                                                 |
| 835 |    308.178221 |     45.788709 | Armin Reindl                                                                                                                                                                         |
| 836 |    150.775734 |    338.478845 | Chris huh                                                                                                                                                                            |
| 837 |    344.374908 |    107.185286 | Michelle Site                                                                                                                                                                        |
| 838 |    369.821123 |    277.792071 | Gareth Monger                                                                                                                                                                        |
| 839 |   1007.682278 |    509.059939 | Sam Fraser-Smith (vectorized by T. Michael Keesey)                                                                                                                                   |
| 840 |    652.082877 |    533.650459 | T. Michael Keesey                                                                                                                                                                    |
| 841 |    713.610692 |    709.386644 | Scott Hartman                                                                                                                                                                        |
| 842 |    284.446587 |    349.938621 | Margot Michaud                                                                                                                                                                       |
| 843 |    503.718103 |    768.403333 | Markus A. Grohme                                                                                                                                                                     |
| 844 |    793.682391 |    762.183666 | Tracy A. Heath                                                                                                                                                                       |
| 845 |    971.749425 |    290.622768 | Francesco “Architetto” Rollandin                                                                                                                                                     |
| 846 |    740.581240 |    743.624448 | Margot Michaud                                                                                                                                                                       |
| 847 |     43.198762 |    625.680831 | Margot Michaud                                                                                                                                                                       |
| 848 |    649.070102 |    518.081290 | Tyler Greenfield and Scott Hartman                                                                                                                                                   |
| 849 |    776.473017 |    386.807194 | Antonov (vectorized by T. Michael Keesey)                                                                                                                                            |
| 850 |    343.059555 |      4.443352 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 851 |    254.328033 |    118.037683 | NA                                                                                                                                                                                   |
| 852 |    742.077986 |     36.580331 | NA                                                                                                                                                                                   |
| 853 |      9.525337 |    509.654188 | Becky Barnes                                                                                                                                                                         |
| 854 |    457.724292 |    644.150331 | Matt Crook                                                                                                                                                                           |
| 855 |    195.608009 |    213.693437 | Margot Michaud                                                                                                                                                                       |
| 856 |    475.908115 |    785.715280 | Dave Souza (vectorized by T. Michael Keesey)                                                                                                                                         |
| 857 |    496.697891 |    308.092325 | Emma Hughes                                                                                                                                                                          |
| 858 |    909.194098 |    447.954588 | Steven Traver                                                                                                                                                                        |
| 859 |    418.022076 |    767.662074 | Collin Gross                                                                                                                                                                         |
| 860 |    677.684045 |    265.397620 | Matt Crook                                                                                                                                                                           |
| 861 |    847.519922 |     92.693493 | Stephen O’Connor (vectorized by T. Michael Keesey)                                                                                                                                   |
| 862 |    315.614684 |    438.472393 | Yan Wong                                                                                                                                                                             |
| 863 |    425.519271 |    224.260571 | Zimices                                                                                                                                                                              |
| 864 |    377.574745 |    307.538417 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 865 |    311.922674 |    232.272309 | Scott Hartman                                                                                                                                                                        |
| 866 |     17.286750 |    197.331303 | Harold N Eyster                                                                                                                                                                      |
| 867 |    184.229912 |     79.299436 | Scott Hartman                                                                                                                                                                        |
| 868 |    345.084386 |     74.356210 | Beth Reinke                                                                                                                                                                          |
| 869 |    590.732048 |    712.307993 | Sharon Wegner-Larsen                                                                                                                                                                 |
| 870 |    158.822131 |    680.643437 | Jagged Fang Designs                                                                                                                                                                  |
| 871 |    719.361074 |    564.510593 | Michelle Site                                                                                                                                                                        |
| 872 |    189.846817 |    483.897568 | Matt Crook                                                                                                                                                                           |
| 873 |    261.143046 |    233.372784 | L. Shyamal                                                                                                                                                                           |
| 874 |    728.939078 |    291.720195 | Jimmy Bernot                                                                                                                                                                         |
| 875 |    234.205835 |    565.860901 | CNZdenek                                                                                                                                                                             |
| 876 |    474.871011 |    705.223553 | T. Michael Keesey                                                                                                                                                                    |
| 877 |    469.548706 |      8.646310 | Sarah Werning                                                                                                                                                                        |
| 878 |    992.528783 |    248.050028 | Birgit Lang                                                                                                                                                                          |
| 879 |    448.582804 |    162.002644 | NA                                                                                                                                                                                   |
| 880 |    163.018095 |    789.895643 | Mathew Wedel                                                                                                                                                                         |
| 881 |    888.050564 |    392.129068 | Margot Michaud                                                                                                                                                                       |
| 882 |    259.186906 |    201.312898 | Matt Crook                                                                                                                                                                           |
| 883 |    800.707321 |    662.459519 | NA                                                                                                                                                                                   |
| 884 |    485.596041 |    373.184534 | T. Michael Keesey                                                                                                                                                                    |
| 885 |    628.510431 |    598.522161 | Steven Traver                                                                                                                                                                        |
| 886 |    771.289168 |    658.436442 | Jon Hill (Photo by Benjamint444: <http://en.wikipedia.org/wiki/File:Blue-footed-booby.jpg>)                                                                                          |
| 887 |    212.519620 |    430.342056 | Zimices                                                                                                                                                                              |
| 888 |    281.393928 |    614.693658 | Tracy A. Heath                                                                                                                                                                       |
| 889 |    442.973067 |    298.925713 | Melissa Broussard                                                                                                                                                                    |
| 890 |    455.935768 |    600.014236 | Zimices                                                                                                                                                                              |
| 891 |    688.391502 |    426.474250 | Andy Wilson                                                                                                                                                                          |
| 892 |     85.339840 |     44.167367 | Steven Traver                                                                                                                                                                        |
| 893 |    981.744265 |    597.093473 | Yan Wong                                                                                                                                                                             |
| 894 |    129.695673 |     13.617398 | Kai R. Caspar                                                                                                                                                                        |
| 895 |    707.590524 |    780.237046 | Gareth Monger                                                                                                                                                                        |
| 896 |    720.914306 |    355.149659 | Anthony Caravaggi                                                                                                                                                                    |
| 897 |    986.415218 |    648.353863 | Yusan Yang                                                                                                                                                                           |
| 898 |   1003.798713 |    587.242510 | T. Michael Keesey                                                                                                                                                                    |
| 899 |     10.257623 |     13.853549 | Frank Förster (based on a picture by Hans Hillewaert)                                                                                                                                |
| 900 |    215.465209 |    756.657152 | T. Michael Keesey (after MPF)                                                                                                                                                        |
| 901 |   1013.487874 |    171.436294 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 902 |     11.216614 |    641.849429 | Juan Carlos Jerí                                                                                                                                                                     |
| 903 |    682.574482 |     36.502077 | Scott Hartman                                                                                                                                                                        |
| 904 |     50.818001 |    664.017882 | Maky (vectorization), Gabriella Skollar (photography), Rebecca Lewis (editing)                                                                                                       |
| 905 |    443.734763 |    792.414718 | Joanna Wolfe                                                                                                                                                                         |
| 906 |    292.979132 |    102.922664 | Margot Michaud                                                                                                                                                                       |
| 907 |    579.274915 |    772.171097 | NA                                                                                                                                                                                   |
| 908 |     82.857539 |    407.896845 | Matt Crook                                                                                                                                                                           |
| 909 |    906.787266 |    548.772188 | Felix Vaux                                                                                                                                                                           |
| 910 |    633.120709 |    286.198932 | Qiang Ou                                                                                                                                                                             |
| 911 |    481.575740 |     61.290460 | Richard J. Harris                                                                                                                                                                    |
| 912 |    532.258102 |    182.534111 | Emily Willoughby                                                                                                                                                                     |
| 913 |    139.347843 |    509.476662 | Steven Traver                                                                                                                                                                        |
| 914 |    831.206982 |    258.847091 | Tommaso Cancellario                                                                                                                                                                  |
| 915 |    956.785078 |     93.283509 | Steven Traver                                                                                                                                                                        |
| 916 |    344.521939 |    528.838074 | M. A. Broussard                                                                                                                                                                      |
| 917 |    901.768688 |    432.052400 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                                      |
| 918 |     73.544340 |    262.702366 | Felix Vaux                                                                                                                                                                           |

    #> Your tweet has been posted!
