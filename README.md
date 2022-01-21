
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

FunkMonk (Michael B. H.), Andrew A. Farke, Rebecca Groom, Yan Wong,
Zimices, Margot Michaud, L. Shyamal, Sarah Werning, Tony Ayling
(vectorized by T. Michael Keesey), Scott Hartman, Jagged Fang Designs,
Didier Descouens (vectorized by T. Michael Keesey), T. Michael Keesey,
Tasman Dixon, Ingo Braasch, FunkMonk, Dmitry Bogdanov, Birgit Lang,
Becky Barnes, Juan Carlos Jerí, Dean Schnabel, Sam Fraser-Smith
(vectorized by T. Michael Keesey), Agnello Picorelli, Alexander
Schmidt-Lebuhn, Gareth Monger, Maija Karala, Darren Naish (vectorized by
T. Michael Keesey), T. Michael Keesey (after Joseph Wolf), Frank Förster
(based on a picture by Hans Hillewaert), Ferran Sayol, Noah Schlottman,
photo from Casey Dunn, Ellen Edmonson and Hugh Chrisp (vectorized by T.
Michael Keesey), Chris huh, Felix Vaux, Tim Bertelink (modified by T.
Michael Keesey), Dmitry Bogdanov (vectorized by T. Michael Keesey),
Steven Traver, Robert Hering, Robert Bruce Horsfall (vectorized by T.
Michael Keesey), Melissa Broussard, Jack Mayer Wood, Mattia Menchetti,
Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley
(silhouette), Christoph Schomburg, Fernando Campos De Domenico, Kai R.
Caspar, Cesar Julian, SecretJellyMan - from Mason McNair, Dexter R.
Mardis, Mathieu Basille, Javiera Constanzo, Jaime Headden, Harold N
Eyster, Matt Crook, Armin Reindl, Mali’o Kodis, photograph by Melissa
Frey, Nobu Tamura (vectorized by T. Michael Keesey), Emily Willoughby,
Michael Scroggie, Benjamin Monod-Broca, Yan Wong (vectorization) from
1873 illustration, Pollyanna von Knorring and T. Michael Keesey,
\<U+0412\>\<U+0430\>\<U+043B\>\<U+044C\>\<U+0434\>\<U+0438\>\<U+043C\>\<U+0430\>\<U+0440\>
(vectorized by T. Michael Keesey), Alex Slavenko, C. Camilo
Julián-Caballero, Caleb M. Brown, Nina Skinner, Lee Harding (photo),
John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G.
Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey,
Gabriele Midolo, Dianne Bray / Museum Victoria (vectorized by T. Michael
Keesey), Duane Raver/USFWS, Chase Brownstein, Jakovche, Lauren Anderson,
Conty (vectorized by T. Michael Keesey), Crystal Maier, Auckland Museum,
Carlos Cano-Barbacil, Robert Bruce Horsfall, vectorized by Zimices,
Chuanixn Yu, RS, Verdilak, Gabriela Palomo-Munoz, Siobhon Egan, Obsidian
Soul (vectorized by T. Michael Keesey), Renata F. Martins, Tyler
Greenfield and Dean Schnabel, Matt Martyniuk, Jan A. Venter, Herbert H.
T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael
Keesey), Mykle Hoban, Terpsichores, Brian Swartz (vectorized by T.
Michael Keesey), Oliver Griffith, Noah Schlottman, photo by Carol
Cummings, Owen Jones, FunkMonk (Michael B.H.; vectorized by T. Michael
Keesey), Alexandre Vong, Esme Ashe-Jepson, Antonov (vectorized by T.
Michael Keesey), Smokeybjb (modified by Mike Keesey), Henry Fairfield
Osborn, vectorized by Zimices, Julie Blommaert based on photo by
Sofdrakou, B. Duygu Özpolat, Geoff Shaw, Michelle Site, Dmitry Bogdanov,
vectorized by Zimices, Birgit Lang, based on a photo by D. Sikes, Katie
S. Collins, Roberto Díaz Sibaja, Dennis C. Murphy, after
<https://commons.wikimedia.org/wiki/File:Queensland_State_Archives_2981_Cane_toads_at_the_Meringa_Sugar_Experiment_Station_North_Queensland_c_1935.png>,
Ricardo Araújo, Ville Koistinen and T. Michael Keesey, Mathew Wedel,
Noah Schlottman, Marcos Pérez-Losada, Jens T. Høeg & Keith A. Crandall,
Derek Bakken (photograph) and T. Michael Keesey (vectorization), Louis
Ranjard, T. Michael Keesey (photo by Darren Swim), Milton Tan, Markus A.
Grohme, Iain Reid, Smokeybjb (vectorized by T. Michael Keesey), Karl
Ragnar Gjertsen (vectorized by T. Michael Keesey), Walter Vladimir,
Notafly (vectorized by T. Michael Keesey), Mali’o Kodis, image from the
Biodiversity Heritage Library, zoosnow, Ben Liebeskind, Oscar Sanisidro,
C. W. Nash (illustration) and Timothy J. Bartley (silhouette), Joseph
Wolf, 1863 (vectorization by Dinah Challen), Lafage, Neil Kelley,
Dantheman9758 (vectorized by T. Michael Keesey), Gabriel Lio, vectorized
by Zimices, Moussa Direct Ltd. (photography) and T. Michael Keesey
(vectorization), Steven Coombs, Steve Hillebrand/U. S. Fish and Wildlife
Service (source photo), T. Michael Keesey (vectorization), Joanna Wolfe,
T. Michael Keesey (vector) and Stuart Halliday (photograph), T. Michael
Keesey (photo by J. M. Garg), Noah Schlottman, photo from Moorea
Biocode, Bruno C. Vellutini, Kanchi Nanjo, Lisa Byrne, Martin R. Smith,
Kamil S. Jaron, Jiekun He, Griensteidl and T. Michael Keesey, Jake
Warner, T. Michael Keesey (after Monika Betley), Tony Ayling, Original
drawing by Antonov, vectorized by Roberto Díaz Sibaja, Tracy A. Heath,
Noah Schlottman, photo by Reinhard Jahn, Matt Dempsey, Mo Hassan, T.
Michael Keesey (after Masteraah), Smokeybjb, Anthony Caravaggi, Liftarn,
Brad McFeeters (vectorized by T. Michael Keesey), Robbie N. Cada
(vectorized by T. Michael Keesey), T. Michael Keesey (vectorization) and
HuttyMcphoo (photography), Fernando Carezzano, Mali’o Kodis, photograph
by “Wildcat Dunny” (<http://www.flickr.com/people/wildcat_dunny/>),
Mali’o Kodis, photograph by P. Funch and R.M. Kristensen, Stemonitis
(photography) and T. Michael Keesey (vectorization), Ville-Veikko
Sinkkonen, Doug Backlund (photo), John E. McCormack, Michael G. Harvey,
Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T.
Brumfield & T. Michael Keesey, Falconaumanni and T. Michael Keesey,
Original photo by Andrew Murray, vectorized by Roberto Díaz Sibaja,
Stephen O’Connor (vectorized by T. Michael Keesey), Mathilde Cordellier,
Nobu Tamura, vectorized by Zimices, Sarah Alewijnse, Noah Schlottman,
photo from National Science Foundation - Turbellarian Taxonomic
Database, Beth Reinke, LeonardoG (photography) and T. Michael Keesey
(vectorization), Unknown (photo), John E. McCormack, Michael G. Harvey,
Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T.
Brumfield & T. Michael Keesey, Collin Gross, Aadx, Hans Hillewaert
(vectorized by T. Michael Keesey), George Edward Lodge (vectorized by T.
Michael Keesey), Matt Martyniuk (modified by T. Michael Keesey), Ignacio
Contreras, Steven Blackwood, Joseph J. W. Sertich, Mark A. Loewen, Trond
R. Oskars, Eyal Bartov, Blair Perry, David Orr, JCGiron, Kanako
Bessho-Uehara, Noah Schlottman, photo by Carlos Sánchez-Ortiz, A. H.
Baldwin (vectorized by T. Michael Keesey), Jonathan Wells, Blanco et
al., 2014, vectorized by Zimices, david maas / dave hone, Aline M.
Ghilardi, Lily Hughes, T. Michael Keesey and Tanetahi, Thea Boodhoo
(photograph) and T. Michael Keesey (vectorization), Pedro de Siracusa,
Todd Marshall, vectorized by Zimices, Mario Quevedo, Berivan Temiz, T.
K. Robinson, Mariana Ruiz Villarreal, T. Michael Keesey (after Colin M.
L. Burnett), Robert Gay, T. Michael Keesey (after MPF), Nicholas J.
Czaplewski, vectorized by Zimices, Margret Flinsch, vectorized by
Zimices, Shyamal, \[unknown\], NASA, Michael P. Taylor, V. Deepak, Roule
Jammes (vectorized by T. Michael Keesey), T. Michael Keesey (after James
& al.), Nobu Tamura, Diego Fontaneto, Elisabeth A. Herniou, Chiara
Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy
G. Barraclough (vectorized by T. Michael Keesey), Christian A.
Masnaghetti, Taro Maeda, Nobu Tamura (modified by T. Michael Keesey),
John Conway, Eduard Solà (vectorized by T. Michael Keesey), Matthew E.
Clapham, Michele M Tobias, Pete Buchholz, Alexis Simon, Joris van der
Ham (vectorized by T. Michael Keesey), Inessa Voet, Lankester Edwin Ray
(vectorized by T. Michael Keesey), Paul O. Lewis, Noah Schlottman, photo
by Museum of Geology, University of Tartu, Allison Pease, Mihai Dragos
(vectorized by T. Michael Keesey), Tim H. Heupink, Leon Huynen, and
David M. Lambert (vectorized by T. Michael Keesey), Hans Hillewaert,
Matt Celeskey, Dinah Challen, Francesco “Architetto” Rollandin, Konsta
Happonen, from a CC-BY-NC image by sokolkov2002 on iNaturalist, Matt
Martyniuk (modified by Serenchia), Kent Sorgon, Claus Rebler,
FJDegrange, Cristina Guijarro, Meyer-Wachsmuth I, Curini Galletti M,
Jondelius U (<doi:10.1371/journal.pone.0107688>). Vectorization by Y.
Wong, Kevin Sánchez, Jose Carlos Arenas-Monroy, Sam Droege (photo) and
T. Michael Keesey (vectorization), Gopal Murali, Andrew R. Gehrke, Emily
Jane McTavish, from Haeckel, E. H. P. A. (1904).Kunstformen der Natur.
Bibliographisches, Lukas Panzarin, Michael B. H. (vectorized by T.
Michael Keesey), Tyler McCraney, Scott Reid, (after McCulloch 1908),
Andrew A. Farke, modified from original by Robert Bruce Horsfall, from
Scott 1912, Chloé Schmidt, Lisa M. “Pixxl” (photo), John E. McCormack,
Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C.
Glenn, Robb T. Brumfield & T. Michael Keesey, David Sim (photograph) and
T. Michael Keesey (vectorization), terngirl, Chris A. Hamilton, Sarefo
(vectorized by T. Michael Keesey), Robbie N. Cada (modified by T.
Michael Keesey), Chris Hay, Sharon Wegner-Larsen, Dr. Thomas G. Barnes,
USFWS, Lukasiniho, Julio Garza, Ron Holmes/U. S. Fish and Wildlife
Service (source photo), T. Michael Keesey (vectorization), Andreas
Trepte (vectorized by T. Michael Keesey), Ludwik Gasiorowski,
Apokryltaros (vectorized by T. Michael Keesey), T. Michael Keesey
(vectorization) and Nadiatalent (photography), Birgit Lang; based on a
drawing by C.L. Koch, Lani Mohan, Florian Pfaff

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                          |
| --: | ------------: | ------------: | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
|   1 |    789.472095 |    134.439425 | FunkMonk (Michael B. H.)                                                                                                                                                        |
|   2 |    315.591817 |     52.351320 | Andrew A. Farke                                                                                                                                                                 |
|   3 |    303.364812 |    239.830810 | Rebecca Groom                                                                                                                                                                   |
|   4 |    532.048146 |    453.056452 | Yan Wong                                                                                                                                                                        |
|   5 |    436.287670 |    562.260634 | Zimices                                                                                                                                                                         |
|   6 |    800.337570 |    744.399551 | NA                                                                                                                                                                              |
|   7 |    539.840394 |     74.331565 | Margot Michaud                                                                                                                                                                  |
|   8 |    911.611154 |    246.970443 | L. Shyamal                                                                                                                                                                      |
|   9 |    526.333492 |    248.006664 | Sarah Werning                                                                                                                                                                   |
|  10 |     98.773852 |    395.994618 | NA                                                                                                                                                                              |
|  11 |    447.279533 |    692.053027 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                                   |
|  12 |    924.425317 |    695.080101 | Scott Hartman                                                                                                                                                                   |
|  13 |    669.928490 |     42.694229 | Jagged Fang Designs                                                                                                                                                             |
|  14 |    180.297835 |    716.032465 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                              |
|  15 |    260.824919 |    508.710043 | T. Michael Keesey                                                                                                                                                               |
|  16 |    100.329339 |    283.054114 | Tasman Dixon                                                                                                                                                                    |
|  17 |    817.930856 |    777.654290 | Tasman Dixon                                                                                                                                                                    |
|  18 |    106.494199 |    332.761192 | Scott Hartman                                                                                                                                                                   |
|  19 |    114.226482 |    500.940592 | T. Michael Keesey                                                                                                                                                               |
|  20 |    395.307232 |    726.012887 | Ingo Braasch                                                                                                                                                                    |
|  21 |    693.218639 |    301.123411 | FunkMonk                                                                                                                                                                        |
|  22 |     91.331447 |    631.368054 | Dmitry Bogdanov                                                                                                                                                                 |
|  23 |    956.301261 |    621.511005 | Birgit Lang                                                                                                                                                                     |
|  24 |    657.028035 |    595.434476 | Scott Hartman                                                                                                                                                                   |
|  25 |    827.722434 |    563.433295 | Rebecca Groom                                                                                                                                                                   |
|  26 |    448.785492 |    183.610130 | Jagged Fang Designs                                                                                                                                                             |
|  27 |    110.477085 |    101.647267 | Margot Michaud                                                                                                                                                                  |
|  28 |    737.713041 |    499.662222 | Margot Michaud                                                                                                                                                                  |
|  29 |    759.725630 |    663.012057 | Becky Barnes                                                                                                                                                                    |
|  30 |    319.393221 |    611.348471 | Juan Carlos Jerí                                                                                                                                                                |
|  31 |    371.841275 |    402.926172 | Dean Schnabel                                                                                                                                                                   |
|  32 |    840.656738 |    348.794554 | Sam Fraser-Smith (vectorized by T. Michael Keesey)                                                                                                                              |
|  33 |    386.049320 |    773.803789 | Agnello Picorelli                                                                                                                                                               |
|  34 |    921.658441 |    420.041102 | NA                                                                                                                                                                              |
|  35 |    557.914462 |    669.761089 | Alexander Schmidt-Lebuhn                                                                                                                                                        |
|  36 |    918.777404 |    471.557744 | Margot Michaud                                                                                                                                                                  |
|  37 |    648.411012 |    144.140401 | Gareth Monger                                                                                                                                                                   |
|  38 |    128.739865 |    188.883089 | NA                                                                                                                                                                              |
|  39 |    171.431203 |    577.751692 | Andrew A. Farke                                                                                                                                                                 |
|  40 |    557.467503 |    379.437199 | Maija Karala                                                                                                                                                                    |
|  41 |    523.046086 |    547.477537 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                                  |
|  42 |    689.019371 |    122.297338 | T. Michael Keesey (after Joseph Wolf)                                                                                                                                           |
|  43 |    893.401595 |     77.750010 | Frank Förster (based on a picture by Hans Hillewaert)                                                                                                                           |
|  44 |    203.687189 |    390.500684 | Ferran Sayol                                                                                                                                                                    |
|  45 |    980.464500 |    126.462196 | Noah Schlottman, photo from Casey Dunn                                                                                                                                          |
|  46 |    936.273449 |    751.378567 | Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey)                                                                                                                |
|  47 |    313.882976 |    132.100352 | Chris huh                                                                                                                                                                       |
|  48 |    245.899970 |    658.076187 | NA                                                                                                                                                                              |
|  49 |    939.891353 |    355.466557 | Felix Vaux                                                                                                                                                                      |
|  50 |    227.238195 |    100.813733 | Zimices                                                                                                                                                                         |
|  51 |    634.336794 |    713.362489 | Tim Bertelink (modified by T. Michael Keesey)                                                                                                                                   |
|  52 |    659.101829 |    749.956309 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
|  53 |    431.034809 |    113.014420 | Steven Traver                                                                                                                                                                   |
|  54 |    158.673223 |     22.876587 | Chris huh                                                                                                                                                                       |
|  55 |    440.313206 |    308.648137 | Scott Hartman                                                                                                                                                                   |
|  56 |    934.748033 |    538.852262 | Robert Hering                                                                                                                                                                   |
|  57 |    540.276414 |    763.056803 | Robert Bruce Horsfall (vectorized by T. Michael Keesey)                                                                                                                         |
|  58 |     75.702095 |    736.278438 | Melissa Broussard                                                                                                                                                               |
|  59 |    460.067148 |    625.507624 | Zimices                                                                                                                                                                         |
|  60 |    300.671540 |    749.652948 | Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey)                                                                                                                |
|  61 |    668.071028 |    478.599223 | Jack Mayer Wood                                                                                                                                                                 |
|  62 |    203.619739 |    320.843580 | Agnello Picorelli                                                                                                                                                               |
|  63 |     50.239105 |    542.855274 | Mattia Menchetti                                                                                                                                                                |
|  64 |     85.479893 |     54.363483 | Jagged Fang Designs                                                                                                                                                             |
|  65 |    579.031813 |    141.873741 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                                               |
|  66 |    469.389038 |     15.247411 | Scott Hartman                                                                                                                                                                   |
|  67 |    101.341790 |    367.054746 | T. Michael Keesey                                                                                                                                                               |
|  68 |    183.312254 |    496.740338 | Zimices                                                                                                                                                                         |
|  69 |    603.743492 |    511.955883 | Christoph Schomburg                                                                                                                                                             |
|  70 |    347.410754 |    333.654319 | Scott Hartman                                                                                                                                                                   |
|  71 |    526.899972 |    312.899954 | Chris huh                                                                                                                                                                       |
|  72 |    475.978318 |    398.329659 | Jagged Fang Designs                                                                                                                                                             |
|  73 |    687.172111 |    427.385505 | Dean Schnabel                                                                                                                                                                   |
|  74 |    299.950164 |    431.568155 | Scott Hartman                                                                                                                                                                   |
|  75 |    868.235889 |    654.230158 | Fernando Campos De Domenico                                                                                                                                                     |
|  76 |    924.505827 |    187.234761 | Kai R. Caspar                                                                                                                                                                   |
|  77 |    610.859867 |    602.119468 | Cesar Julian                                                                                                                                                                    |
|  78 |    455.022408 |    265.272374 | SecretJellyMan - from Mason McNair                                                                                                                                              |
|  79 |    435.630549 |    238.283200 | NA                                                                                                                                                                              |
|  80 |    114.780353 |    680.445762 | Scott Hartman                                                                                                                                                                   |
|  81 |    541.304084 |    184.964244 | Dexter R. Mardis                                                                                                                                                                |
|  82 |    830.729881 |    481.377563 | Mathieu Basille                                                                                                                                                                 |
|  83 |    385.194501 |    674.598514 | Tasman Dixon                                                                                                                                                                    |
|  84 |    249.804572 |    781.322603 | Javiera Constanzo                                                                                                                                                               |
|  85 |    712.360670 |    205.287052 | Jaime Headden                                                                                                                                                                   |
|  86 |    597.821098 |    575.197795 | Harold N Eyster                                                                                                                                                                 |
|  87 |    376.611265 |    297.086452 | Matt Crook                                                                                                                                                                      |
|  88 |    189.051226 |    786.071339 | Armin Reindl                                                                                                                                                                    |
|  89 |    636.717572 |    672.814910 | Mali’o Kodis, photograph by Melissa Frey                                                                                                                                        |
|  90 |    261.196967 |    720.406203 | Steven Traver                                                                                                                                                                   |
|  91 |    326.548308 |    357.907738 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
|  92 |    447.086818 |    496.439892 | Zimices                                                                                                                                                                         |
|  93 |    865.900689 |    155.092199 | Emily Willoughby                                                                                                                                                                |
|  94 |    130.030488 |    744.946180 | T. Michael Keesey                                                                                                                                                               |
|  95 |    162.219462 |    634.043290 | Michael Scroggie                                                                                                                                                                |
|  96 |    959.431202 |    778.192598 | Chris huh                                                                                                                                                                       |
|  97 |    123.605218 |    414.174678 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
|  98 |     44.619245 |    686.143117 | Benjamin Monod-Broca                                                                                                                                                            |
|  99 |    825.373451 |    223.727943 | Yan Wong (vectorization) from 1873 illustration                                                                                                                                 |
| 100 |    233.386463 |    261.819415 | T. Michael Keesey                                                                                                                                                               |
| 101 |    983.689852 |    240.449317 | FunkMonk                                                                                                                                                                        |
| 102 |   1000.061495 |    330.658967 | Ferran Sayol                                                                                                                                                                    |
| 103 |    167.764485 |    653.348486 | Zimices                                                                                                                                                                         |
| 104 |    786.219061 |     56.901686 | Pollyanna von Knorring and T. Michael Keesey                                                                                                                                    |
| 105 |    268.939517 |    271.283658 | Michael Scroggie                                                                                                                                                                |
| 106 |     29.043254 |    454.205739 | \<U+0412\>\<U+0430\>\<U+043B\>\<U+044C\>\<U+0434\>\<U+0438\>\<U+043C\>\<U+0430\>\<U+0440\> (vectorized by T. Michael Keesey)                                                    |
| 107 |     29.941770 |     80.855401 | Alex Slavenko                                                                                                                                                                   |
| 108 |    791.983383 |    345.053811 | Ferran Sayol                                                                                                                                                                    |
| 109 |    855.311189 |    625.884285 | Chris huh                                                                                                                                                                       |
| 110 |    344.496709 |    440.936193 | C. Camilo Julián-Caballero                                                                                                                                                      |
| 111 |    364.820414 |    500.868925 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                                  |
| 112 |    149.619570 |    259.534093 | Caleb M. Brown                                                                                                                                                                  |
| 113 |    688.184717 |    152.530732 | T. Michael Keesey                                                                                                                                                               |
| 114 |     84.641897 |     21.588818 | Nina Skinner                                                                                                                                                                    |
| 115 |    661.143930 |    359.448359 | Zimices                                                                                                                                                                         |
| 116 |    194.775083 |    144.208432 | NA                                                                                                                                                                              |
| 117 |    265.368169 |    296.315027 | Jagged Fang Designs                                                                                                                                                             |
| 118 |    425.102106 |    738.782562 | Chris huh                                                                                                                                                                       |
| 119 |    400.533654 |     56.680343 | Lee Harding (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                     |
| 120 |   1005.347862 |    486.577152 | Gabriele Midolo                                                                                                                                                                 |
| 121 |    881.996118 |    141.307068 | Dianne Bray / Museum Victoria (vectorized by T. Michael Keesey)                                                                                                                 |
| 122 |    848.901407 |    175.269941 | Gareth Monger                                                                                                                                                                   |
| 123 |    998.756161 |    428.770946 | Duane Raver/USFWS                                                                                                                                                               |
| 124 |    532.857313 |    110.446935 | Yan Wong                                                                                                                                                                        |
| 125 |    616.466456 |    128.671922 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 126 |    269.217131 |    638.041519 | Chase Brownstein                                                                                                                                                                |
| 127 |    396.538012 |    198.432681 | Zimices                                                                                                                                                                         |
| 128 |   1011.927034 |    556.854461 | Jakovche                                                                                                                                                                        |
| 129 |    925.567352 |    143.824319 | Dmitry Bogdanov                                                                                                                                                                 |
| 130 |     17.754175 |    680.248302 | Lauren Anderson                                                                                                                                                                 |
| 131 |     19.700123 |    428.774403 | Conty (vectorized by T. Michael Keesey)                                                                                                                                         |
| 132 |    418.233821 |    479.036535 | Matt Crook                                                                                                                                                                      |
| 133 |     78.707783 |    513.655433 | Matt Crook                                                                                                                                                                      |
| 134 |   1003.961739 |    308.532699 | Crystal Maier                                                                                                                                                                   |
| 135 |    616.384695 |    180.719384 | Auckland Museum                                                                                                                                                                 |
| 136 |    506.120293 |    569.947082 | T. Michael Keesey                                                                                                                                                               |
| 137 |    937.995535 |    625.829337 | Carlos Cano-Barbacil                                                                                                                                                            |
| 138 |    796.707715 |    359.508175 | Zimices                                                                                                                                                                         |
| 139 |    972.558939 |    326.517972 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                                    |
| 140 |     23.688704 |    233.166057 | NA                                                                                                                                                                              |
| 141 |    721.527300 |    730.448381 | Ferran Sayol                                                                                                                                                                    |
| 142 |    255.548623 |    585.811230 | Chuanixn Yu                                                                                                                                                                     |
| 143 |    162.108555 |    612.910817 | NA                                                                                                                                                                              |
| 144 |    419.710318 |    453.722809 | RS                                                                                                                                                                              |
| 145 |    781.988356 |    412.532124 | Verdilak                                                                                                                                                                        |
| 146 |    790.058165 |     12.988965 | Ferran Sayol                                                                                                                                                                    |
| 147 |    940.276984 |    554.451226 | Matt Crook                                                                                                                                                                      |
| 148 |    491.301370 |    788.147428 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 149 |     11.502564 |     84.967565 | Scott Hartman                                                                                                                                                                   |
| 150 |    385.241782 |    642.846903 | Felix Vaux                                                                                                                                                                      |
| 151 |    202.065304 |    230.202131 | Ferran Sayol                                                                                                                                                                    |
| 152 |    890.031573 |    320.903310 | NA                                                                                                                                                                              |
| 153 |     86.563653 |    539.098291 | Margot Michaud                                                                                                                                                                  |
| 154 |    761.450806 |     97.316603 | NA                                                                                                                                                                              |
| 155 |    641.826826 |    777.066129 | Siobhon Egan                                                                                                                                                                    |
| 156 |     34.490904 |    222.804014 | Zimices                                                                                                                                                                         |
| 157 |   1001.224810 |    352.534009 | Felix Vaux                                                                                                                                                                      |
| 158 |    730.732141 |    183.253616 | Matt Crook                                                                                                                                                                      |
| 159 |    366.056384 |    281.678998 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                                 |
| 160 |     11.194072 |    740.449369 | Renata F. Martins                                                                                                                                                               |
| 161 |    630.363991 |     97.262327 | Tyler Greenfield and Dean Schnabel                                                                                                                                              |
| 162 |     33.261612 |    723.555657 | Ferran Sayol                                                                                                                                                                    |
| 163 |    491.594498 |    186.968109 | Margot Michaud                                                                                                                                                                  |
| 164 |    925.775543 |    403.934332 | Matt Crook                                                                                                                                                                      |
| 165 |    959.844205 |    342.770838 | Matt Crook                                                                                                                                                                      |
| 166 |    882.646450 |    713.457433 | Steven Traver                                                                                                                                                                   |
| 167 |    594.939192 |    329.115611 | T. Michael Keesey                                                                                                                                                               |
| 168 |    978.979840 |    490.754822 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 169 |    684.907814 |    674.601745 | NA                                                                                                                                                                              |
| 170 |   1000.424993 |    780.184173 | Matt Martyniuk                                                                                                                                                                  |
| 171 |    115.323637 |    435.725859 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                             |
| 172 |    289.906760 |    540.759349 | Mykle Hoban                                                                                                                                                                     |
| 173 |    856.337219 |    517.722989 | Zimices                                                                                                                                                                         |
| 174 |    779.189738 |    332.158954 | Terpsichores                                                                                                                                                                    |
| 175 |    705.324814 |    101.295654 | Brian Swartz (vectorized by T. Michael Keesey)                                                                                                                                  |
| 176 |    630.786981 |    780.187082 | T. Michael Keesey                                                                                                                                                               |
| 177 |    423.344898 |    218.278516 | Oliver Griffith                                                                                                                                                                 |
| 178 |    497.456639 |    725.660453 | NA                                                                                                                                                                              |
| 179 |    150.125562 |    343.464283 | Noah Schlottman, photo by Carol Cummings                                                                                                                                        |
| 180 |    699.269656 |    693.659715 | Jaime Headden                                                                                                                                                                   |
| 181 |    509.508179 |    625.309442 | Gareth Monger                                                                                                                                                                   |
| 182 |    831.291865 |    411.046557 | Owen Jones                                                                                                                                                                      |
| 183 |    301.721075 |    350.524049 | Steven Traver                                                                                                                                                                   |
| 184 |    988.063740 |    373.180040 | FunkMonk (Michael B.H.; vectorized by T. Michael Keesey)                                                                                                                        |
| 185 |    136.230803 |    428.987496 | Jagged Fang Designs                                                                                                                                                             |
| 186 |    557.949578 |     15.122206 | Alexandre Vong                                                                                                                                                                  |
| 187 |    248.288539 |    326.988997 | Ferran Sayol                                                                                                                                                                    |
| 188 |     35.966874 |    697.602298 | Esme Ashe-Jepson                                                                                                                                                                |
| 189 |    920.930623 |    382.958481 | Antonov (vectorized by T. Michael Keesey)                                                                                                                                       |
| 190 |    609.242192 |    297.960405 | NA                                                                                                                                                                              |
| 191 |    961.586201 |    663.578138 | Gareth Monger                                                                                                                                                                   |
| 192 |    789.966999 |    221.366242 | Michael Scroggie                                                                                                                                                                |
| 193 |     98.372894 |    242.690291 | Matt Crook                                                                                                                                                                      |
| 194 |    441.758372 |    369.266807 | Smokeybjb (modified by Mike Keesey)                                                                                                                                             |
| 195 |    524.229780 |    340.022689 | FunkMonk                                                                                                                                                                        |
| 196 |    154.282850 |    300.484096 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                                                   |
| 197 |    777.096099 |    581.845685 | NA                                                                                                                                                                              |
| 198 |    764.515560 |    545.662509 | Julie Blommaert based on photo by Sofdrakou                                                                                                                                     |
| 199 |    876.629987 |    542.976677 | Harold N Eyster                                                                                                                                                                 |
| 200 |     69.194529 |    181.758791 | Margot Michaud                                                                                                                                                                  |
| 201 |    207.896970 |    753.403410 | Zimices                                                                                                                                                                         |
| 202 |    582.802032 |    181.484814 | Margot Michaud                                                                                                                                                                  |
| 203 |    329.806391 |    288.344471 | Matt Crook                                                                                                                                                                      |
| 204 |    329.760014 |    387.425329 | B. Duygu Özpolat                                                                                                                                                                |
| 205 |    784.371905 |    619.835173 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 206 |    975.261541 |    309.129377 | Zimices                                                                                                                                                                         |
| 207 |    501.123706 |    794.626645 | Geoff Shaw                                                                                                                                                                      |
| 208 |    128.085195 |    451.833615 | Michelle Site                                                                                                                                                                   |
| 209 |    392.776241 |     86.002966 | NA                                                                                                                                                                              |
| 210 |     52.679792 |     11.045650 | NA                                                                                                                                                                              |
| 211 |    339.538476 |     10.854950 | Dmitry Bogdanov, vectorized by Zimices                                                                                                                                          |
| 212 |    141.617328 |    760.757481 | Birgit Lang, based on a photo by D. Sikes                                                                                                                                       |
| 213 |    110.738085 |    662.958266 | Katie S. Collins                                                                                                                                                                |
| 214 |    292.273449 |    517.189027 | Michelle Site                                                                                                                                                                   |
| 215 |    911.253750 |    630.607936 | Gareth Monger                                                                                                                                                                   |
| 216 |    287.264087 |    701.497574 | Roberto Díaz Sibaja                                                                                                                                                             |
| 217 |    865.038598 |    440.633863 | Scott Hartman                                                                                                                                                                   |
| 218 |   1007.907091 |    238.259222 | Margot Michaud                                                                                                                                                                  |
| 219 |    382.377859 |    616.913543 | Zimices                                                                                                                                                                         |
| 220 |    150.358244 |    792.583166 | Scott Hartman                                                                                                                                                                   |
| 221 |     34.108086 |    612.083218 | Margot Michaud                                                                                                                                                                  |
| 222 |    662.824397 |    563.775895 | Dennis C. Murphy, after <https://commons.wikimedia.org/wiki/File:Queensland_State_Archives_2981_Cane_toads_at_the_Meringa_Sugar_Experiment_Station_North_Queensland_c_1935.png> |
| 223 |    774.487814 |    197.176201 | Ricardo Araújo                                                                                                                                                                  |
| 224 |    518.185946 |    127.800046 | Dmitry Bogdanov                                                                                                                                                                 |
| 225 |    861.664182 |    448.580449 | Scott Hartman                                                                                                                                                                   |
| 226 |    661.165487 |    135.321092 | C. Camilo Julián-Caballero                                                                                                                                                      |
| 227 |    775.131193 |     85.151412 | Maija Karala                                                                                                                                                                    |
| 228 |    228.887436 |     50.905759 | Scott Hartman                                                                                                                                                                   |
| 229 |    290.750398 |    407.795058 | Michael Scroggie                                                                                                                                                                |
| 230 |    119.587513 |    309.096980 | Ville Koistinen and T. Michael Keesey                                                                                                                                           |
| 231 |    756.663707 |     65.722605 | Zimices                                                                                                                                                                         |
| 232 |    827.183544 |    437.569945 | Mathew Wedel                                                                                                                                                                    |
| 233 |   1000.325041 |    681.447206 | Noah Schlottman                                                                                                                                                                 |
| 234 |     35.866326 |    718.653799 | Gareth Monger                                                                                                                                                                   |
| 235 |    746.314516 |    772.770453 | Steven Traver                                                                                                                                                                   |
| 236 |    234.300185 |    308.000032 | Juan Carlos Jerí                                                                                                                                                                |
| 237 |    155.508231 |    358.038002 | Marcos Pérez-Losada, Jens T. Høeg & Keith A. Crandall                                                                                                                           |
| 238 |    912.544912 |    110.075917 | Derek Bakken (photograph) and T. Michael Keesey (vectorization)                                                                                                                 |
| 239 |    865.690639 |    755.930260 | Louis Ranjard                                                                                                                                                                   |
| 240 |    589.660110 |    294.133858 | Gareth Monger                                                                                                                                                                   |
| 241 |    998.602894 |    523.919644 | Noah Schlottman, photo by Carol Cummings                                                                                                                                        |
| 242 |    744.226813 |    615.697047 | Alex Slavenko                                                                                                                                                                   |
| 243 |    123.620930 |    351.987424 | Melissa Broussard                                                                                                                                                               |
| 244 |    969.406191 |     47.208402 | T. Michael Keesey (photo by Darren Swim)                                                                                                                                        |
| 245 |     29.358629 |    133.654236 | Milton Tan                                                                                                                                                                      |
| 246 |    417.684852 |     41.185428 | Markus A. Grohme                                                                                                                                                                |
| 247 |    470.054795 |    742.521029 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 248 |    289.955464 |    724.418046 | Iain Reid                                                                                                                                                                       |
| 249 |    618.563034 |    484.674660 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 250 |    268.712397 |    307.540763 | Yan Wong                                                                                                                                                                        |
| 251 |    539.432217 |     11.613076 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 252 |    951.885176 |    238.263478 | Matt Crook                                                                                                                                                                      |
| 253 |    233.687228 |    549.316119 | Matt Martyniuk                                                                                                                                                                  |
| 254 |    625.847604 |    651.788591 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                                     |
| 255 |     11.615011 |    145.044398 | NA                                                                                                                                                                              |
| 256 |    864.898139 |     63.658711 | Margot Michaud                                                                                                                                                                  |
| 257 |    731.988237 |    573.435996 | Karl Ragnar Gjertsen (vectorized by T. Michael Keesey)                                                                                                                          |
| 258 |    932.514637 |    131.023216 | Walter Vladimir                                                                                                                                                                 |
| 259 |    166.663489 |    369.930996 | Matt Crook                                                                                                                                                                      |
| 260 |    320.208335 |    785.625994 | Andrew A. Farke                                                                                                                                                                 |
| 261 |    176.038003 |    395.574361 | Notafly (vectorized by T. Michael Keesey)                                                                                                                                       |
| 262 |    583.655890 |    344.365002 | Mali’o Kodis, image from the Biodiversity Heritage Library                                                                                                                      |
| 263 |    871.982446 |    769.078995 | Roberto Díaz Sibaja                                                                                                                                                             |
| 264 |    733.405612 |    733.264629 | NA                                                                                                                                                                              |
| 265 |    183.121022 |    628.932652 | Zimices                                                                                                                                                                         |
| 266 |    825.758877 |     73.425231 | zoosnow                                                                                                                                                                         |
| 267 |     30.262731 |    178.936658 | Gareth Monger                                                                                                                                                                   |
| 268 |    460.251946 |    474.140425 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 269 |    489.257267 |    765.973205 | Margot Michaud                                                                                                                                                                  |
| 270 |    621.972545 |     67.909348 | Zimices                                                                                                                                                                         |
| 271 |    678.530094 |    629.715981 | Katie S. Collins                                                                                                                                                                |
| 272 |    400.441539 |     13.437311 | Maija Karala                                                                                                                                                                    |
| 273 |    190.694846 |     66.590830 | Sarah Werning                                                                                                                                                                   |
| 274 |    730.777603 |    758.286369 | Scott Hartman                                                                                                                                                                   |
| 275 |    546.660917 |     36.296162 | Steven Traver                                                                                                                                                                   |
| 276 |    125.651573 |    247.927761 | Zimices                                                                                                                                                                         |
| 277 |    371.050304 |    262.201942 | Ben Liebeskind                                                                                                                                                                  |
| 278 |    200.763212 |    309.080708 | Yan Wong                                                                                                                                                                        |
| 279 |    105.899567 |    383.949879 | Tasman Dixon                                                                                                                                                                    |
| 280 |    928.660602 |    630.775141 | Terpsichores                                                                                                                                                                    |
| 281 |     58.935212 |    589.370893 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 282 |    844.784806 |    679.658395 | Matt Crook                                                                                                                                                                      |
| 283 |    593.732995 |    213.357796 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 284 |    619.396788 |    446.300461 | Ferran Sayol                                                                                                                                                                    |
| 285 |   1001.122246 |    221.481640 | Matt Crook                                                                                                                                                                      |
| 286 |    373.887357 |     17.587149 | Oscar Sanisidro                                                                                                                                                                 |
| 287 |     67.860807 |    173.810385 | Zimices                                                                                                                                                                         |
| 288 |    190.653907 |     82.770720 | Margot Michaud                                                                                                                                                                  |
| 289 |    843.862300 |    287.351396 | C. W. Nash (illustration) and Timothy J. Bartley (silhouette)                                                                                                                   |
| 290 |    452.980193 |    202.422111 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 291 |    620.353028 |    779.857540 | Scott Hartman                                                                                                                                                                   |
| 292 |    372.224071 |    560.765694 | Zimices                                                                                                                                                                         |
| 293 |    383.522553 |     82.280044 | Joseph Wolf, 1863 (vectorization by Dinah Challen)                                                                                                                              |
| 294 |    743.041784 |     45.464625 | Lafage                                                                                                                                                                          |
| 295 |    517.778223 |    795.018823 | Steven Traver                                                                                                                                                                   |
| 296 |    937.382057 |    647.755704 | Neil Kelley                                                                                                                                                                     |
| 297 |    542.068952 |    697.072698 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 298 |    381.446411 |    749.639664 | Gareth Monger                                                                                                                                                                   |
| 299 |    946.290676 |    669.842151 | Dantheman9758 (vectorized by T. Michael Keesey)                                                                                                                                 |
| 300 |    126.554632 |    653.472887 | Gabriel Lio, vectorized by Zimices                                                                                                                                              |
| 301 |    752.638214 |    251.709718 | Jagged Fang Designs                                                                                                                                                             |
| 302 |   1009.601438 |    599.063719 | NA                                                                                                                                                                              |
| 303 |     83.202064 |    213.020916 | Andrew A. Farke                                                                                                                                                                 |
| 304 |    160.320875 |    532.242436 | Armin Reindl                                                                                                                                                                    |
| 305 |    907.133227 |    784.801223 | Milton Tan                                                                                                                                                                      |
| 306 |    312.153313 |    719.514132 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 307 |    558.351550 |    608.631353 | Jack Mayer Wood                                                                                                                                                                 |
| 308 |     76.071876 |    473.503661 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 309 |     58.784026 |    299.789635 | Zimices                                                                                                                                                                         |
| 310 |    651.834522 |    685.969787 | Moussa Direct Ltd. (photography) and T. Michael Keesey (vectorization)                                                                                                          |
| 311 |   1000.960340 |     23.046828 | T. Michael Keesey                                                                                                                                                               |
| 312 |    912.979031 |    617.790672 | Steven Coombs                                                                                                                                                                   |
| 313 |    761.232846 |    782.415503 | Melissa Broussard                                                                                                                                                               |
| 314 |    235.332233 |    125.565415 | Zimices                                                                                                                                                                         |
| 315 |    659.838818 |    540.571944 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 316 |    257.745132 |     49.810958 | Zimices                                                                                                                                                                         |
| 317 |    266.291288 |    623.588391 | NA                                                                                                                                                                              |
| 318 |     98.893319 |    592.196153 | Steve Hillebrand/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                                              |
| 319 |    549.785737 |    792.203443 | Michelle Site                                                                                                                                                                   |
| 320 |    291.528140 |    526.269224 | Tasman Dixon                                                                                                                                                                    |
| 321 |    813.015409 |    388.897373 | Matt Martyniuk                                                                                                                                                                  |
| 322 |    442.015907 |    268.433382 | Joanna Wolfe                                                                                                                                                                    |
| 323 |    455.138264 |    185.774387 | Mattia Menchetti                                                                                                                                                                |
| 324 |    115.744977 |    473.293239 | T. Michael Keesey (vector) and Stuart Halliday (photograph)                                                                                                                     |
| 325 |    825.334732 |    259.701807 | T. Michael Keesey (photo by J. M. Garg)                                                                                                                                         |
| 326 |    451.983222 |    660.689289 | Birgit Lang                                                                                                                                                                     |
| 327 |     38.346367 |    144.028040 | Matt Crook                                                                                                                                                                      |
| 328 |    512.093209 |    710.519231 | Noah Schlottman, photo from Moorea Biocode                                                                                                                                      |
| 329 |    238.508717 |    498.510070 | Chuanixn Yu                                                                                                                                                                     |
| 330 |    203.472914 |    121.470383 | Emily Willoughby                                                                                                                                                                |
| 331 |      5.507018 |    498.417757 | Bruno C. Vellutini                                                                                                                                                              |
| 332 |    353.129122 |    299.408143 | Kanchi Nanjo                                                                                                                                                                    |
| 333 |    682.147765 |     56.469709 | Iain Reid                                                                                                                                                                       |
| 334 |     96.108655 |    308.887740 | Michelle Site                                                                                                                                                                   |
| 335 |    529.707068 |      7.864372 | Lisa Byrne                                                                                                                                                                      |
| 336 |    356.629533 |    650.732771 | NA                                                                                                                                                                              |
| 337 |    323.989675 |    264.622830 | Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey)                                                                                                                |
| 338 |    270.164477 |    771.567402 | FunkMonk                                                                                                                                                                        |
| 339 |    595.460954 |    541.339376 | Margot Michaud                                                                                                                                                                  |
| 340 |    735.989013 |    711.595544 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                                    |
| 341 |     32.854345 |    484.027589 | NA                                                                                                                                                                              |
| 342 |    431.169710 |    438.691863 | Martin R. Smith                                                                                                                                                                 |
| 343 |    310.294296 |    488.736529 | Gareth Monger                                                                                                                                                                   |
| 344 |    875.506906 |     73.018044 | Michael Scroggie                                                                                                                                                                |
| 345 |    421.790925 |    274.243037 | Gareth Monger                                                                                                                                                                   |
| 346 |    114.410672 |    734.468265 | Kamil S. Jaron                                                                                                                                                                  |
| 347 |    995.464649 |    404.888655 | Jiekun He                                                                                                                                                                       |
| 348 |      6.375941 |     32.967116 | Griensteidl and T. Michael Keesey                                                                                                                                               |
| 349 |    152.237170 |     54.170578 | Jake Warner                                                                                                                                                                     |
| 350 |    810.728685 |     57.656350 | NA                                                                                                                                                                              |
| 351 |    464.061292 |    139.600184 | T. Michael Keesey (after Monika Betley)                                                                                                                                         |
| 352 |     62.434517 |    446.816246 | Ferran Sayol                                                                                                                                                                    |
| 353 |    850.614114 |    724.115851 | Chris huh                                                                                                                                                                       |
| 354 |     35.349879 |    436.375562 | Tony Ayling                                                                                                                                                                     |
| 355 |    121.755536 |    149.837743 | Kai R. Caspar                                                                                                                                                                   |
| 356 |    140.918045 |    409.929400 | Matt Crook                                                                                                                                                                      |
| 357 |     57.201728 |    656.737381 | Original drawing by Antonov, vectorized by Roberto Díaz Sibaja                                                                                                                  |
| 358 |    716.455460 |     27.527726 | Kanchi Nanjo                                                                                                                                                                    |
| 359 |    151.368775 |    745.532761 | Tracy A. Heath                                                                                                                                                                  |
| 360 |    977.407134 |    576.465399 | Matt Crook                                                                                                                                                                      |
| 361 |    453.375050 |    775.005218 | Gareth Monger                                                                                                                                                                   |
| 362 |     72.901158 |    681.800699 | Noah Schlottman, photo by Reinhard Jahn                                                                                                                                         |
| 363 |    467.770646 |    305.889711 | Matt Dempsey                                                                                                                                                                    |
| 364 |    675.371596 |    777.319199 | Steven Traver                                                                                                                                                                   |
| 365 |    693.836192 |    448.853996 | Roberto Díaz Sibaja                                                                                                                                                             |
| 366 |     23.408783 |    379.826691 | Scott Hartman                                                                                                                                                                   |
| 367 |    284.555830 |    497.229047 | Mo Hassan                                                                                                                                                                       |
| 368 |    137.673860 |     46.398922 | Noah Schlottman                                                                                                                                                                 |
| 369 |    503.158183 |    580.173586 | Zimices                                                                                                                                                                         |
| 370 |    795.735049 |    721.813534 | Chris huh                                                                                                                                                                       |
| 371 |    912.336811 |    548.420749 | T. Michael Keesey (after Masteraah)                                                                                                                                             |
| 372 |    752.237378 |     26.423573 | Yan Wong                                                                                                                                                                        |
| 373 |    353.353701 |    254.609948 | Zimices                                                                                                                                                                         |
| 374 |    638.365560 |    403.852882 | Jagged Fang Designs                                                                                                                                                             |
| 375 |    584.299080 |    687.330184 | Smokeybjb                                                                                                                                                                       |
| 376 |    229.412619 |    765.273734 | Margot Michaud                                                                                                                                                                  |
| 377 |    356.515354 |    535.412480 | Gareth Monger                                                                                                                                                                   |
| 378 |    297.961294 |    793.147547 | Zimices                                                                                                                                                                         |
| 379 |    414.412457 |    230.043163 | Steven Traver                                                                                                                                                                   |
| 380 |    875.204166 |    730.039124 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 381 |    986.725246 |    715.067317 | Zimices                                                                                                                                                                         |
| 382 |     15.244279 |    615.025604 | Jagged Fang Designs                                                                                                                                                             |
| 383 |   1014.162357 |    455.429449 | Gareth Monger                                                                                                                                                                   |
| 384 |    914.660902 |     75.431375 | Yan Wong                                                                                                                                                                        |
| 385 |    862.853335 |    605.307814 | Anthony Caravaggi                                                                                                                                                               |
| 386 |    475.518672 |    369.815347 | NA                                                                                                                                                                              |
| 387 |    233.607911 |    237.129747 | NA                                                                                                                                                                              |
| 388 |    420.200291 |    522.924821 | Lee Harding (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                     |
| 389 |    997.394720 |    195.216557 | Liftarn                                                                                                                                                                         |
| 390 |    924.619770 |    442.255471 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 391 |    212.494452 |    782.157261 | Markus A. Grohme                                                                                                                                                                |
| 392 |   1004.312915 |    727.857998 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                                |
| 393 |    393.003989 |     39.807282 | NA                                                                                                                                                                              |
| 394 |    745.452194 |    336.911883 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                                |
| 395 |    277.328960 |    685.711390 | T. Michael Keesey (vectorization) and HuttyMcphoo (photography)                                                                                                                 |
| 396 |    464.340844 |    386.479601 | Fernando Carezzano                                                                                                                                                              |
| 397 |     34.149293 |    203.880929 | Katie S. Collins                                                                                                                                                                |
| 398 |    997.784628 |     43.468480 | Birgit Lang                                                                                                                                                                     |
| 399 |    453.265536 |    750.736504 | T. Michael Keesey                                                                                                                                                               |
| 400 |    498.575352 |    631.601579 | Birgit Lang                                                                                                                                                                     |
| 401 |   1015.793666 |    432.031815 | Mali’o Kodis, photograph by “Wildcat Dunny” (<http://www.flickr.com/people/wildcat_dunny/>)                                                                                     |
| 402 |    379.201085 |    555.201477 | Birgit Lang, based on a photo by D. Sikes                                                                                                                                       |
| 403 |    492.407078 |    386.229036 | Matt Crook                                                                                                                                                                      |
| 404 |    598.343900 |     65.831961 | Mali’o Kodis, photograph by P. Funch and R.M. Kristensen                                                                                                                        |
| 405 |    183.536073 |    306.963337 | Melissa Broussard                                                                                                                                                               |
| 406 |    344.738720 |    116.427195 | Scott Hartman                                                                                                                                                                   |
| 407 |    412.837041 |    383.368921 | Stemonitis (photography) and T. Michael Keesey (vectorization)                                                                                                                  |
| 408 |    800.022967 |    278.530232 | Ville-Veikko Sinkkonen                                                                                                                                                          |
| 409 |    589.508977 |    168.865634 | Margot Michaud                                                                                                                                                                  |
| 410 |     45.051110 |    244.640584 | Doug Backlund (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                   |
| 411 |     17.840961 |    296.075775 | Matt Crook                                                                                                                                                                      |
| 412 |    937.697873 |    713.540610 | C. Camilo Julián-Caballero                                                                                                                                                      |
| 413 |    667.030758 |    662.286048 | Tasman Dixon                                                                                                                                                                    |
| 414 |    551.366743 |    349.032002 | Falconaumanni and T. Michael Keesey                                                                                                                                             |
| 415 |     74.322958 |    245.071218 | Original photo by Andrew Murray, vectorized by Roberto Díaz Sibaja                                                                                                              |
| 416 |    918.624965 |    496.595686 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 417 |    797.498717 |    495.553676 | NA                                                                                                                                                                              |
| 418 |    964.942976 |    213.561724 | Stephen O’Connor (vectorized by T. Michael Keesey)                                                                                                                              |
| 419 |    512.964434 |    553.551449 | Ferran Sayol                                                                                                                                                                    |
| 420 |    966.142298 |    510.540090 | Jagged Fang Designs                                                                                                                                                             |
| 421 |     20.921858 |    771.148445 | FunkMonk                                                                                                                                                                        |
| 422 |    745.949371 |     11.821834 | Matt Crook                                                                                                                                                                      |
| 423 |    784.006241 |    201.091405 | Scott Hartman                                                                                                                                                                   |
| 424 |    567.104922 |    200.059276 | Margot Michaud                                                                                                                                                                  |
| 425 |    460.880072 |    461.562211 | Mathilde Cordellier                                                                                                                                                             |
| 426 |    212.429076 |    734.366867 | Nobu Tamura, vectorized by Zimices                                                                                                                                              |
| 427 |    828.148239 |     16.237388 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 428 |    401.633133 |    447.400631 | Scott Hartman                                                                                                                                                                   |
| 429 |    811.335672 |    240.767147 | Steven Traver                                                                                                                                                                   |
| 430 |    579.669628 |     49.502869 | Christoph Schomburg                                                                                                                                                             |
| 431 |    812.937536 |    704.059158 | Birgit Lang                                                                                                                                                                     |
| 432 |    550.389697 |    673.717950 | Fernando Carezzano                                                                                                                                                              |
| 433 |    362.943384 |    687.346191 | Sarah Alewijnse                                                                                                                                                                 |
| 434 |    214.167562 |    681.897854 | Noah Schlottman, photo from National Science Foundation - Turbellarian Taxonomic Database                                                                                       |
| 435 |    339.635601 |    312.843765 | Juan Carlos Jerí                                                                                                                                                                |
| 436 |    490.063617 |    338.159707 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 437 |    487.442572 |    171.936254 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 438 |    857.540347 |    390.237340 | Gareth Monger                                                                                                                                                                   |
| 439 |    911.364534 |    358.661799 | Scott Hartman                                                                                                                                                                   |
| 440 |    821.925386 |     24.168462 | Scott Hartman                                                                                                                                                                   |
| 441 |    903.065482 |     20.924653 | NA                                                                                                                                                                              |
| 442 |    376.948538 |     93.727020 | \<U+0412\>\<U+0430\>\<U+043B\>\<U+044C\>\<U+0434\>\<U+0438\>\<U+043C\>\<U+0430\>\<U+0440\> (vectorized by T. Michael Keesey)                                                    |
| 443 |    899.367075 |    100.118351 | T. Michael Keesey                                                                                                                                                               |
| 444 |    978.281053 |    726.944398 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                                   |
| 445 |    921.030117 |     92.816335 | Gareth Monger                                                                                                                                                                   |
| 446 |    674.565183 |    454.217373 | Doug Backlund (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                   |
| 447 |    471.711718 |    181.683694 | Gareth Monger                                                                                                                                                                   |
| 448 |    882.059626 |    580.613720 | Beth Reinke                                                                                                                                                                     |
| 449 |    826.405922 |    175.927854 | LeonardoG (photography) and T. Michael Keesey (vectorization)                                                                                                                   |
| 450 |    165.455363 |     74.079002 | Jagged Fang Designs                                                                                                                                                             |
| 451 |    910.154630 |    610.471859 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                             |
| 452 |    638.070536 |    628.976740 | Christoph Schomburg                                                                                                                                                             |
| 453 |    893.638688 |    377.616794 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                         |
| 454 |    790.711897 |    239.576747 | Steven Traver                                                                                                                                                                   |
| 455 |     74.556747 |    591.608370 | NA                                                                                                                                                                              |
| 456 |    283.472478 |    397.948146 | Matt Crook                                                                                                                                                                      |
| 457 |    436.811034 |     65.161274 | Kamil S. Jaron                                                                                                                                                                  |
| 458 |    825.359724 |      9.618786 | Noah Schlottman                                                                                                                                                                 |
| 459 |    174.476450 |    274.867446 | L. Shyamal                                                                                                                                                                      |
| 460 |    101.749749 |    755.662385 | Mattia Menchetti                                                                                                                                                                |
| 461 |    550.584507 |    720.676797 | Jagged Fang Designs                                                                                                                                                             |
| 462 |    592.325233 |    761.103437 | Alex Slavenko                                                                                                                                                                   |
| 463 |     56.583332 |    236.378491 | T. Michael Keesey                                                                                                                                                               |
| 464 |    851.836636 |    413.472176 | Matt Crook                                                                                                                                                                      |
| 465 |     10.058636 |    764.016072 | Chris huh                                                                                                                                                                       |
| 466 |    259.657223 |    696.121588 | Scott Hartman                                                                                                                                                                   |
| 467 |    667.353709 |    184.712414 | Neil Kelley                                                                                                                                                                     |
| 468 |    763.199559 |    603.190564 | Margot Michaud                                                                                                                                                                  |
| 469 |    163.982532 |    294.222449 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                              |
| 470 |    139.883530 |    317.963861 | Ferran Sayol                                                                                                                                                                    |
| 471 |    882.496825 |    303.568991 | Collin Gross                                                                                                                                                                    |
| 472 |    210.595526 |    185.555448 | Zimices                                                                                                                                                                         |
| 473 |    148.046399 |    145.216703 | Aadx                                                                                                                                                                            |
| 474 |    601.885684 |    423.565425 | Collin Gross                                                                                                                                                                    |
| 475 |     38.671091 |    770.832646 | Zimices                                                                                                                                                                         |
| 476 |    194.791310 |    436.506982 | Margot Michaud                                                                                                                                                                  |
| 477 |   1007.144049 |    422.169312 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                               |
| 478 |    912.892628 |    561.660209 | Terpsichores                                                                                                                                                                    |
| 479 |    448.615589 |    667.689021 | George Edward Lodge (vectorized by T. Michael Keesey)                                                                                                                           |
| 480 |    896.773007 |    390.921990 | Margot Michaud                                                                                                                                                                  |
| 481 |     96.625265 |    700.510897 | Katie S. Collins                                                                                                                                                                |
| 482 |    287.314438 |    784.500206 | Margot Michaud                                                                                                                                                                  |
| 483 |    925.982639 |    217.429512 | Zimices                                                                                                                                                                         |
| 484 |    229.208562 |    287.895924 | Matt Martyniuk (modified by T. Michael Keesey)                                                                                                                                  |
| 485 |    715.864965 |    476.812894 | Tasman Dixon                                                                                                                                                                    |
| 486 |    317.314573 |    430.887481 | Beth Reinke                                                                                                                                                                     |
| 487 |    523.941738 |    394.201648 | Gabriele Midolo                                                                                                                                                                 |
| 488 |   1012.934779 |      8.021944 | Ignacio Contreras                                                                                                                                                               |
| 489 |    801.946758 |     77.127614 | Chris huh                                                                                                                                                                       |
| 490 |    838.913793 |    395.885566 | Birgit Lang                                                                                                                                                                     |
| 491 |    814.651468 |    445.233405 | Steven Traver                                                                                                                                                                   |
| 492 |    615.667602 |    416.633843 | Rebecca Groom                                                                                                                                                                   |
| 493 |    300.849678 |    147.548405 | Zimices                                                                                                                                                                         |
| 494 |    354.037042 |    678.903251 | Steven Blackwood                                                                                                                                                                |
| 495 |    258.618194 |    792.718895 | Carlos Cano-Barbacil                                                                                                                                                            |
| 496 |    239.676158 |    437.422163 | Scott Hartman                                                                                                                                                                   |
| 497 |    939.495586 |    289.987067 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 498 |    370.729079 |    325.407046 | Joseph J. W. Sertich, Mark A. Loewen                                                                                                                                            |
| 499 |    675.619815 |    653.513696 | Tasman Dixon                                                                                                                                                                    |
| 500 |     32.775888 |    670.237282 | Scott Hartman                                                                                                                                                                   |
| 501 |     16.607928 |    273.753431 | NA                                                                                                                                                                              |
| 502 |    115.346083 |    790.307372 | T. Michael Keesey                                                                                                                                                               |
| 503 |    464.690744 |    785.245543 | Melissa Broussard                                                                                                                                                               |
| 504 |    905.114667 |    703.387059 | Gareth Monger                                                                                                                                                                   |
| 505 |    397.423591 |     71.019798 | Matt Crook                                                                                                                                                                      |
| 506 |    457.891923 |     37.272719 | FunkMonk                                                                                                                                                                        |
| 507 |    815.145594 |    496.053608 | Trond R. Oskars                                                                                                                                                                 |
| 508 |    903.058066 |    314.542541 | Gareth Monger                                                                                                                                                                   |
| 509 |    808.483360 |    759.121819 | Chris huh                                                                                                                                                                       |
| 510 |    964.813006 |    492.594982 | Eyal Bartov                                                                                                                                                                     |
| 511 |    808.505665 |    679.455799 | Steven Traver                                                                                                                                                                   |
| 512 |    360.829503 |    194.616936 | Blair Perry                                                                                                                                                                     |
| 513 |    702.450519 |    544.719419 | David Orr                                                                                                                                                                       |
| 514 |    216.719403 |    620.050451 | Agnello Picorelli                                                                                                                                                               |
| 515 |    323.028332 |    396.464922 | Tasman Dixon                                                                                                                                                                    |
| 516 |    393.784799 |    230.674573 | NA                                                                                                                                                                              |
| 517 |    549.660338 |     99.809499 | NA                                                                                                                                                                              |
| 518 |    880.628219 |    606.988984 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 519 |    457.331617 |    769.777914 | Tasman Dixon                                                                                                                                                                    |
| 520 |    475.281088 |    721.110003 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                                               |
| 521 |    699.209811 |    493.042959 | Birgit Lang                                                                                                                                                                     |
| 522 |    186.893983 |    172.961933 | JCGiron                                                                                                                                                                         |
| 523 |    128.591670 |    599.555357 | Maija Karala                                                                                                                                                                    |
| 524 |    307.150538 |    160.899932 | Armin Reindl                                                                                                                                                                    |
| 525 |    431.770364 |     30.479057 | Terpsichores                                                                                                                                                                    |
| 526 |    840.182144 |    446.040290 | Kanako Bessho-Uehara                                                                                                                                                            |
| 527 |    324.617678 |    415.086610 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                             |
| 528 |    770.097391 |    451.651419 | Noah Schlottman, photo by Carlos Sánchez-Ortiz                                                                                                                                  |
| 529 |    916.983866 |    313.072261 | Steven Traver                                                                                                                                                                   |
| 530 |    577.890530 |    492.204997 | A. H. Baldwin (vectorized by T. Michael Keesey)                                                                                                                                 |
| 531 |    892.208494 |    153.784954 | Chris huh                                                                                                                                                                       |
| 532 |     55.571295 |    135.771807 | Margot Michaud                                                                                                                                                                  |
| 533 |    396.349225 |    314.197145 | Tracy A. Heath                                                                                                                                                                  |
| 534 |    950.059779 |    651.750750 | Jonathan Wells                                                                                                                                                                  |
| 535 |    756.146173 |    408.214662 | Collin Gross                                                                                                                                                                    |
| 536 |    983.380620 |    439.660692 | Margot Michaud                                                                                                                                                                  |
| 537 |    244.490622 |    442.472528 | Tasman Dixon                                                                                                                                                                    |
| 538 |    640.780383 |    741.514266 | Blanco et al., 2014, vectorized by Zimices                                                                                                                                      |
| 539 |     67.907261 |    145.482256 | Trond R. Oskars                                                                                                                                                                 |
| 540 |    547.372657 |    115.089259 | david maas / dave hone                                                                                                                                                          |
| 541 |     18.480223 |    199.786627 | Aline M. Ghilardi                                                                                                                                                               |
| 542 |    135.122099 |    665.080174 | Lily Hughes                                                                                                                                                                     |
| 543 |   1014.201718 |    174.220366 | Zimices                                                                                                                                                                         |
| 544 |     14.475445 |    639.879542 | T. Michael Keesey and Tanetahi                                                                                                                                                  |
| 545 |    467.669668 |    762.053991 | Andrew A. Farke                                                                                                                                                                 |
| 546 |    344.576017 |    157.439459 | Margot Michaud                                                                                                                                                                  |
| 547 |    196.400074 |    210.174732 | Thea Boodhoo (photograph) and T. Michael Keesey (vectorization)                                                                                                                 |
| 548 |     21.249674 |    106.487395 | Matt Crook                                                                                                                                                                      |
| 549 |    111.207673 |    647.534338 | Pedro de Siracusa                                                                                                                                                               |
| 550 |    509.938819 |     30.546888 | Todd Marshall, vectorized by Zimices                                                                                                                                            |
| 551 |    384.585498 |     39.598846 | Mario Quevedo                                                                                                                                                                   |
| 552 |    935.969940 |    145.837087 | T. Michael Keesey                                                                                                                                                               |
| 553 |    320.502526 |    304.937540 | NA                                                                                                                                                                              |
| 554 |    240.789056 |    450.640492 | Beth Reinke                                                                                                                                                                     |
| 555 |    673.383738 |    157.023426 | Berivan Temiz                                                                                                                                                                   |
| 556 |    738.283027 |    263.818511 | Markus A. Grohme                                                                                                                                                                |
| 557 |    982.118114 |     56.131425 | Scott Hartman                                                                                                                                                                   |
| 558 |    735.739486 |    407.467877 | Matt Crook                                                                                                                                                                      |
| 559 |    204.746541 |    773.116225 | Ferran Sayol                                                                                                                                                                    |
| 560 |    196.493293 |    648.378734 | Matt Crook                                                                                                                                                                      |
| 561 |    620.342976 |    162.822494 | T. K. Robinson                                                                                                                                                                  |
| 562 |    198.545133 |    425.822633 | Gareth Monger                                                                                                                                                                   |
| 563 |    898.937053 |    727.601344 | Margot Michaud                                                                                                                                                                  |
| 564 |    785.262370 |    298.197409 | Ben Liebeskind                                                                                                                                                                  |
| 565 |    604.904277 |    452.200841 | Mariana Ruiz Villarreal                                                                                                                                                         |
| 566 |    313.137601 |    478.137852 | Gareth Monger                                                                                                                                                                   |
| 567 |    665.973230 |    769.780620 | Maija Karala                                                                                                                                                                    |
| 568 |    419.174122 |    252.137432 | Ferran Sayol                                                                                                                                                                    |
| 569 |    675.782929 |    788.246262 | Jaime Headden                                                                                                                                                                   |
| 570 |    678.731455 |    234.957338 | Ferran Sayol                                                                                                                                                                    |
| 571 |     98.760711 |    419.263641 | Scott Hartman                                                                                                                                                                   |
| 572 |     88.077585 |    650.060775 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 573 |     17.450240 |    475.668452 | Carlos Cano-Barbacil                                                                                                                                                            |
| 574 |    485.941943 |    777.281448 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 575 |    449.515113 |    430.099577 | Gareth Monger                                                                                                                                                                   |
| 576 |    306.513076 |    456.928494 | Armin Reindl                                                                                                                                                                    |
| 577 |    172.949919 |    154.572193 | Margot Michaud                                                                                                                                                                  |
| 578 |    259.693656 |    364.627484 | Jonathan Wells                                                                                                                                                                  |
| 579 |    383.267604 |    153.511302 | NA                                                                                                                                                                              |
| 580 |    849.333039 |    603.572716 | Zimices                                                                                                                                                                         |
| 581 |    194.399366 |    323.718679 | Roberto Díaz Sibaja                                                                                                                                                             |
| 582 |    868.708317 |    716.221875 | T. Michael Keesey (after Colin M. L. Burnett)                                                                                                                                   |
| 583 |    670.734640 |    174.477067 | Joanna Wolfe                                                                                                                                                                    |
| 584 |    466.953436 |    733.550221 | Robert Gay                                                                                                                                                                      |
| 585 |    378.087668 |    351.592128 | NA                                                                                                                                                                              |
| 586 |    765.837233 |     15.431510 | T. Michael Keesey (after MPF)                                                                                                                                                   |
| 587 |    841.460417 |    582.025747 | Gareth Monger                                                                                                                                                                   |
| 588 |    837.845655 |    701.302884 | Matt Crook                                                                                                                                                                      |
| 589 |    821.872880 |    766.530611 | Scott Hartman                                                                                                                                                                   |
| 590 |     39.325417 |    212.202608 | Nicholas J. Czaplewski, vectorized by Zimices                                                                                                                                   |
| 591 |    561.404746 |    349.675977 | Birgit Lang                                                                                                                                                                     |
| 592 |    838.087523 |      4.329028 | Margret Flinsch, vectorized by Zimices                                                                                                                                          |
| 593 |     11.206224 |     17.219826 | Shyamal                                                                                                                                                                         |
| 594 |    710.386513 |    776.470025 | \[unknown\]                                                                                                                                                                     |
| 595 |    875.554874 |    484.010449 | Zimices                                                                                                                                                                         |
| 596 |     49.013678 |    169.091412 | NASA                                                                                                                                                                            |
| 597 |    808.050185 |     95.135169 | Smokeybjb                                                                                                                                                                       |
| 598 |    227.416081 |    216.118468 | Ferran Sayol                                                                                                                                                                    |
| 599 |    811.594699 |    406.061452 | Matt Crook                                                                                                                                                                      |
| 600 |     88.154551 |    558.947310 | Michael P. Taylor                                                                                                                                                               |
| 601 |    945.885025 |     20.346988 | V. Deepak                                                                                                                                                                       |
| 602 |    783.259447 |    431.067353 | Jagged Fang Designs                                                                                                                                                             |
| 603 |    926.537232 |    721.210150 | Roule Jammes (vectorized by T. Michael Keesey)                                                                                                                                  |
| 604 |    506.612046 |    735.777208 | Gareth Monger                                                                                                                                                                   |
| 605 |    841.621271 |    423.306158 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 606 |    735.375185 |     25.969049 | Noah Schlottman, photo from Casey Dunn                                                                                                                                          |
| 607 |      9.125333 |    259.305690 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                             |
| 608 |    608.776194 |    263.623060 | T. Michael Keesey (after James & al.)                                                                                                                                           |
| 609 |    624.496563 |    369.670568 | Michelle Site                                                                                                                                                                   |
| 610 |    497.546861 |    329.950101 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                                  |
| 611 |     36.322676 |    360.422575 | Matt Crook                                                                                                                                                                      |
| 612 |    146.606112 |    774.329181 | Nobu Tamura                                                                                                                                                                     |
| 613 |     87.081294 |    260.474048 | Michael P. Taylor                                                                                                                                                               |
| 614 |    567.811709 |    282.839380 | Zimices                                                                                                                                                                         |
| 615 |     67.693603 |    227.979344 | Noah Schlottman                                                                                                                                                                 |
| 616 |    873.057357 |    785.647905 | C. Camilo Julián-Caballero                                                                                                                                                      |
| 617 |    707.775630 |    626.315094 | Rebecca Groom                                                                                                                                                                   |
| 618 |    396.755526 |    216.335601 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey)           |
| 619 |     78.685207 |    671.954724 | Christian A. Masnaghetti                                                                                                                                                        |
| 620 |    219.891402 |     39.802059 | Zimices                                                                                                                                                                         |
| 621 |    346.799235 |    636.196356 | Taro Maeda                                                                                                                                                                      |
| 622 |    108.768387 |    569.280650 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                                     |
| 623 |    672.746733 |    200.082494 | John Conway                                                                                                                                                                     |
| 624 |    895.198260 |     76.588018 | Ferran Sayol                                                                                                                                                                    |
| 625 |     28.303006 |    734.456358 | Eduard Solà (vectorized by T. Michael Keesey)                                                                                                                                   |
| 626 |    959.746346 |    381.710665 | \<U+0412\>\<U+0430\>\<U+043B\>\<U+044C\>\<U+0434\>\<U+0438\>\<U+043C\>\<U+0430\>\<U+0440\> (vectorized by T. Michael Keesey)                                                    |
| 627 |    695.453650 |    191.863922 | Zimices                                                                                                                                                                         |
| 628 |    942.561425 |    504.306992 | Birgit Lang                                                                                                                                                                     |
| 629 |    607.620009 |    359.320748 | Matthew E. Clapham                                                                                                                                                              |
| 630 |    548.261694 |    196.247274 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 631 |   1002.653369 |    614.406198 | Alex Slavenko                                                                                                                                                                   |
| 632 |    170.002851 |    313.263039 | Melissa Broussard                                                                                                                                                               |
| 633 |    231.249100 |    521.347292 | Michele M Tobias                                                                                                                                                                |
| 634 |    618.819624 |    684.508794 | Margot Michaud                                                                                                                                                                  |
| 635 |    865.595682 |    491.621423 | Zimices                                                                                                                                                                         |
| 636 |    204.370862 |    613.772247 | Margot Michaud                                                                                                                                                                  |
| 637 |     15.911168 |    284.371534 | Ferran Sayol                                                                                                                                                                    |
| 638 |    450.662823 |    787.579257 | Pete Buchholz                                                                                                                                                                   |
| 639 |    337.851450 |    480.861128 | Alexis Simon                                                                                                                                                                    |
| 640 |    138.435202 |    785.056268 | Markus A. Grohme                                                                                                                                                                |
| 641 |     57.792130 |     34.406720 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 642 |    881.313554 |     47.168501 | Joris van der Ham (vectorized by T. Michael Keesey)                                                                                                                             |
| 643 |    762.995716 |    279.826934 | Gareth Monger                                                                                                                                                                   |
| 644 |    778.626190 |    246.035141 | Inessa Voet                                                                                                                                                                     |
| 645 |    550.076237 |    582.517736 | Michael Scroggie                                                                                                                                                                |
| 646 |    519.944228 |    723.576970 | Chris huh                                                                                                                                                                       |
| 647 |    979.276661 |     14.840494 | L. Shyamal                                                                                                                                                                      |
| 648 |    801.595231 |    611.183098 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                                           |
| 649 |    402.335663 |    268.688381 | Collin Gross                                                                                                                                                                    |
| 650 |    208.365758 |     72.125558 | Felix Vaux                                                                                                                                                                      |
| 651 |     28.627199 |    242.949604 | NA                                                                                                                                                                              |
| 652 |    703.982026 |    138.815167 | NA                                                                                                                                                                              |
| 653 |    257.968736 |    245.492628 | T. Michael Keesey                                                                                                                                                               |
| 654 |     46.080364 |    156.285391 | Margot Michaud                                                                                                                                                                  |
| 655 |   1007.335747 |    694.903919 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 656 |    516.508208 |    502.703985 | NA                                                                                                                                                                              |
| 657 |    870.639956 |    700.119687 | Tracy A. Heath                                                                                                                                                                  |
| 658 |    415.656867 |     27.080849 | Jack Mayer Wood                                                                                                                                                                 |
| 659 |     38.424480 |     65.814530 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 660 |    318.480885 |    472.379542 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 661 |    856.228034 |    137.065416 | Gareth Monger                                                                                                                                                                   |
| 662 |    505.007137 |    145.958044 | Zimices                                                                                                                                                                         |
| 663 |    816.087596 |    464.553298 | Matt Crook                                                                                                                                                                      |
| 664 |    221.120252 |    603.998466 | Zimices                                                                                                                                                                         |
| 665 |     59.634822 |     22.376438 | Paul O. Lewis                                                                                                                                                                   |
| 666 |   1015.745364 |    625.327841 | Scott Hartman                                                                                                                                                                   |
| 667 |    794.850619 |    211.472723 | Chris huh                                                                                                                                                                       |
| 668 |    179.133627 |    762.871475 | Noah Schlottman, photo by Museum of Geology, University of Tartu                                                                                                                |
| 669 |    184.181064 |    525.500335 | Trond R. Oskars                                                                                                                                                                 |
| 670 |    244.162389 |    544.689125 | Beth Reinke                                                                                                                                                                     |
| 671 |    619.683413 |      9.969274 | Gareth Monger                                                                                                                                                                   |
| 672 |    729.585438 |    601.974476 | Ferran Sayol                                                                                                                                                                    |
| 673 |    357.510852 |    143.091563 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 674 |    955.448392 |     35.923790 | Allison Pease                                                                                                                                                                   |
| 675 |     50.342068 |    414.546761 | Mihai Dragos (vectorized by T. Michael Keesey)                                                                                                                                  |
| 676 |    149.968009 |    162.180847 | Tim H. Heupink, Leon Huynen, and David M. Lambert (vectorized by T. Michael Keesey)                                                                                             |
| 677 |     18.202945 |    603.065964 | Matt Crook                                                                                                                                                                      |
| 678 |    270.965845 |    645.363956 | Hans Hillewaert                                                                                                                                                                 |
| 679 |    482.019296 |    263.562136 | NA                                                                                                                                                                              |
| 680 |    799.785515 |    447.657995 | Birgit Lang                                                                                                                                                                     |
| 681 |    860.430907 |      6.634651 | Ferran Sayol                                                                                                                                                                    |
| 682 |    727.430370 |     46.962272 | Shyamal                                                                                                                                                                         |
| 683 |    956.234564 |     60.286546 | Matt Crook                                                                                                                                                                      |
| 684 |    829.359636 |    245.281869 | Matt Crook                                                                                                                                                                      |
| 685 |    892.047348 |    535.218821 | Matt Celeskey                                                                                                                                                                   |
| 686 |    447.838829 |    677.624458 | NA                                                                                                                                                                              |
| 687 |    121.642485 |    708.563848 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                                |
| 688 |    620.710865 |    790.210572 | Margot Michaud                                                                                                                                                                  |
| 689 |    234.555497 |    741.117993 | Gareth Monger                                                                                                                                                                   |
| 690 |     10.233344 |     67.960334 | NA                                                                                                                                                                              |
| 691 |     15.318926 |    468.278147 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 692 |    774.638262 |    385.745309 | Zimices                                                                                                                                                                         |
| 693 |    850.870344 |    484.100408 | NA                                                                                                                                                                              |
| 694 |    675.563304 |    690.105803 | Gareth Monger                                                                                                                                                                   |
| 695 |    520.529088 |    612.110352 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 696 |    920.391313 |     14.121621 | L. Shyamal                                                                                                                                                                      |
| 697 |    596.324848 |    792.472648 | Andrew A. Farke                                                                                                                                                                 |
| 698 |    445.303182 |    216.632404 | Dinah Challen                                                                                                                                                                   |
| 699 |    391.406535 |    702.361914 | V. Deepak                                                                                                                                                                       |
| 700 |    307.045138 |    520.169098 | NA                                                                                                                                                                              |
| 701 |    134.964476 |    467.748665 | Sarah Werning                                                                                                                                                                   |
| 702 |   1001.027968 |    374.020488 | Kamil S. Jaron                                                                                                                                                                  |
| 703 |    719.976037 |    612.405681 | Smokeybjb                                                                                                                                                                       |
| 704 |    857.204573 |     51.234903 | Matt Crook                                                                                                                                                                      |
| 705 |    461.922656 |    149.211050 | Mathew Wedel                                                                                                                                                                    |
| 706 |    810.926494 |    357.995054 | Tasman Dixon                                                                                                                                                                    |
| 707 |    496.844487 |    538.288221 | Francesco “Architetto” Rollandin                                                                                                                                                |
| 708 |     14.640368 |    225.267314 | Konsta Happonen, from a CC-BY-NC image by sokolkov2002 on iNaturalist                                                                                                           |
| 709 |    953.773137 |    436.884815 | Jagged Fang Designs                                                                                                                                                             |
| 710 |    195.623859 |    639.433849 | Matt Martyniuk (modified by Serenchia)                                                                                                                                          |
| 711 |    407.205423 |    241.673776 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey)           |
| 712 |    740.264688 |    203.762901 | Kent Sorgon                                                                                                                                                                     |
| 713 |    787.372520 |     32.840914 | Kamil S. Jaron                                                                                                                                                                  |
| 714 |    534.241255 |    688.604089 | Claus Rebler                                                                                                                                                                    |
| 715 |    157.832538 |    404.443928 | Katie S. Collins                                                                                                                                                                |
| 716 |    167.118414 |     39.351420 | Matt Crook                                                                                                                                                                      |
| 717 |    556.811765 |    733.714821 | FJDegrange                                                                                                                                                                      |
| 718 |    664.004376 |    404.757945 | Cristina Guijarro                                                                                                                                                               |
| 719 |    957.955478 |    225.255763 | Steven Traver                                                                                                                                                                   |
| 720 |    427.301756 |     59.607365 | Emily Willoughby                                                                                                                                                                |
| 721 |     37.456915 |    760.142196 | Milton Tan                                                                                                                                                                      |
| 722 |    927.024645 |    327.626477 | Meyer-Wachsmuth I, Curini Galletti M, Jondelius U (<doi:10.1371/journal.pone.0107688>). Vectorization by Y. Wong                                                                |
| 723 |    906.764745 |     16.109214 | Zimices                                                                                                                                                                         |
| 724 |    501.452995 |    110.052028 | Crystal Maier                                                                                                                                                                   |
| 725 |    961.986514 |    733.883401 | Matt Martyniuk                                                                                                                                                                  |
| 726 |     54.197457 |    701.071125 | Ignacio Contreras                                                                                                                                                               |
| 727 |    144.860797 |    232.868066 | Roberto Díaz Sibaja                                                                                                                                                             |
| 728 |     79.457502 |     30.854552 | Katie S. Collins                                                                                                                                                                |
| 729 |    811.230770 |    422.307668 | Steven Traver                                                                                                                                                                   |
| 730 |    897.890120 |    295.861912 | Nobu Tamura, vectorized by Zimices                                                                                                                                              |
| 731 |    698.565361 |    793.095971 | Zimices                                                                                                                                                                         |
| 732 |   1003.502879 |    752.705322 | Kevin Sánchez                                                                                                                                                                   |
| 733 |    887.522362 |     16.194543 | Markus A. Grohme                                                                                                                                                                |
| 734 |    156.697812 |    499.261792 | Jose Carlos Arenas-Monroy                                                                                                                                                       |
| 735 |    977.828693 |    353.613445 | Margot Michaud                                                                                                                                                                  |
| 736 |    161.079505 |    673.461734 | NA                                                                                                                                                                              |
| 737 |    948.677722 |    402.457766 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 738 |    345.188896 |    413.124941 | Margot Michaud                                                                                                                                                                  |
| 739 |    633.892784 |    119.902612 | Sam Droege (photo) and T. Michael Keesey (vectorization)                                                                                                                        |
| 740 |    203.825752 |    679.924837 | Gareth Monger                                                                                                                                                                   |
| 741 |     45.177226 |    692.774911 | Margot Michaud                                                                                                                                                                  |
| 742 |    563.020358 |    337.230170 | Kamil S. Jaron                                                                                                                                                                  |
| 743 |    497.938098 |    372.353809 | C. Camilo Julián-Caballero                                                                                                                                                      |
| 744 |    490.019853 |    585.448117 | Gopal Murali                                                                                                                                                                    |
| 745 |    587.610920 |    249.686361 | T. Michael Keesey                                                                                                                                                               |
| 746 |    355.397052 |    418.515896 | Kamil S. Jaron                                                                                                                                                                  |
| 747 |   1010.475851 |    712.852906 | T. Michael Keesey                                                                                                                                                               |
| 748 |    137.005236 |    608.359166 | Becky Barnes                                                                                                                                                                    |
| 749 |    724.917872 |    131.405496 | Kamil S. Jaron                                                                                                                                                                  |
| 750 |    894.122462 |    352.346523 | Zimices                                                                                                                                                                         |
| 751 |    588.258201 |    590.066687 | Steven Traver                                                                                                                                                                   |
| 752 |    844.649873 |    460.408258 | Andrew R. Gehrke                                                                                                                                                                |
| 753 |    250.825496 |     12.351028 | Emily Jane McTavish, from Haeckel, E. H. P. A. (1904).Kunstformen der Natur. Bibliographisches                                                                                  |
| 754 |    580.160552 |    746.532556 | Lukas Panzarin                                                                                                                                                                  |
| 755 |    610.366908 |    490.206806 | Rebecca Groom                                                                                                                                                                   |
| 756 |    770.187787 |    444.393351 | Zimices                                                                                                                                                                         |
| 757 |    338.079298 |    789.050917 | T. Michael Keesey                                                                                                                                                               |
| 758 |     57.632959 |     76.484100 | Felix Vaux                                                                                                                                                                      |
| 759 |    345.828613 |    662.582321 | Michael Scroggie                                                                                                                                                                |
| 760 |    577.239095 |    732.604228 | Jonathan Wells                                                                                                                                                                  |
| 761 |    428.453179 |    406.723105 | Michelle Site                                                                                                                                                                   |
| 762 |   1002.401699 |    395.599055 | C. Camilo Julián-Caballero                                                                                                                                                      |
| 763 |    714.539169 |    446.921521 | Steven Traver                                                                                                                                                                   |
| 764 |    790.242801 |    715.910710 | Scott Hartman                                                                                                                                                                   |
| 765 |    802.915189 |    581.115982 | Michael B. H. (vectorized by T. Michael Keesey)                                                                                                                                 |
| 766 |    609.324102 |     78.989212 | Tyler McCraney                                                                                                                                                                  |
| 767 |    226.337395 |    784.756638 | Margot Michaud                                                                                                                                                                  |
| 768 |     34.783033 |    664.298238 | Scott Reid                                                                                                                                                                      |
| 769 |    245.101314 |    686.522801 | Margot Michaud                                                                                                                                                                  |
| 770 |    459.940787 |    440.701288 | Tasman Dixon                                                                                                                                                                    |
| 771 |    326.440334 |    463.433938 | Jake Warner                                                                                                                                                                     |
| 772 |    192.230590 |    288.120174 | Mathieu Basille                                                                                                                                                                 |
| 773 |    136.348129 |    529.410218 | Andrew R. Gehrke                                                                                                                                                                |
| 774 |    184.188681 |    672.441593 | Zimices                                                                                                                                                                         |
| 775 |    338.899730 |    266.388983 | NA                                                                                                                                                                              |
| 776 |   1008.441957 |    269.336602 | (after McCulloch 1908)                                                                                                                                                          |
| 777 |    876.713724 |    499.253034 | Margot Michaud                                                                                                                                                                  |
| 778 |     23.760389 |    347.134143 | NA                                                                                                                                                                              |
| 779 |     13.548700 |    386.045846 | Sarah Werning                                                                                                                                                                   |
| 780 |    121.954327 |    158.321598 | Andrew A. Farke, modified from original by Robert Bruce Horsfall, from Scott 1912                                                                                               |
| 781 |    640.746779 |      8.337890 | Chloé Schmidt                                                                                                                                                                   |
| 782 |    611.303797 |    615.984213 | T. Michael Keesey                                                                                                                                                               |
| 783 |     48.752628 |    468.648649 | Zimices                                                                                                                                                                         |
| 784 |    212.256263 |    217.298393 | Gareth Monger                                                                                                                                                                   |
| 785 |    550.610351 |    291.487506 | T. Michael Keesey                                                                                                                                                               |
| 786 |    458.494907 |    282.820195 | Yan Wong                                                                                                                                                                        |
| 787 |    800.317047 |    693.212970 | Ferran Sayol                                                                                                                                                                    |
| 788 |     45.097800 |    377.856673 | Beth Reinke                                                                                                                                                                     |
| 789 |    964.464912 |    721.886188 | NA                                                                                                                                                                              |
| 790 |    648.607313 |    734.144116 | C. Camilo Julián-Caballero                                                                                                                                                      |
| 791 |    449.776211 |    593.419091 | NA                                                                                                                                                                              |
| 792 |    286.107063 |    690.712244 | Ferran Sayol                                                                                                                                                                    |
| 793 |    967.316030 |    705.644392 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 794 |    154.764943 |    758.899768 | Lisa M. “Pixxl” (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                 |
| 795 |    568.467722 |    193.143789 | Beth Reinke                                                                                                                                                                     |
| 796 |    330.790231 |    446.882975 | Beth Reinke                                                                                                                                                                     |
| 797 |    182.140794 |    340.572611 | David Sim (photograph) and T. Michael Keesey (vectorization)                                                                                                                    |
| 798 |    596.777347 |    122.432326 | terngirl                                                                                                                                                                        |
| 799 |    411.447476 |    418.559754 | Chris A. Hamilton                                                                                                                                                               |
| 800 |    494.344558 |     29.168955 | Michelle Site                                                                                                                                                                   |
| 801 |    321.167029 |     17.967266 | Oscar Sanisidro                                                                                                                                                                 |
| 802 |    592.022274 |     48.635481 | Sarefo (vectorized by T. Michael Keesey)                                                                                                                                        |
| 803 |    292.885909 |    448.527013 | Matt Crook                                                                                                                                                                      |
| 804 |    166.584998 |    141.394624 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                                                  |
| 805 |    239.553923 |    628.117835 | Steven Traver                                                                                                                                                                   |
| 806 |    393.150636 |    555.976766 | NA                                                                                                                                                                              |
| 807 |    451.090681 |    478.432387 | Chris Hay                                                                                                                                                                       |
| 808 |    397.182354 |    519.899123 | Terpsichores                                                                                                                                                                    |
| 809 |    793.591138 |    261.322948 | Nobu Tamura, vectorized by Zimices                                                                                                                                              |
| 810 |    935.223062 |      7.586819 | Matt Crook                                                                                                                                                                      |
| 811 |    410.709279 |    471.435336 | Collin Gross                                                                                                                                                                    |
| 812 |    787.530315 |    377.332268 | Scott Hartman                                                                                                                                                                   |
| 813 |    539.477233 |     99.390691 | Jaime Headden                                                                                                                                                                   |
| 814 |     63.771173 |    430.460088 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                                |
| 815 |    605.499064 |    741.576326 | Matt Crook                                                                                                                                                                      |
| 816 |    887.736765 |    525.820315 | Zimices                                                                                                                                                                         |
| 817 |   1014.946940 |     77.900348 | NA                                                                                                                                                                              |
| 818 |    231.142222 |     16.465964 | Margot Michaud                                                                                                                                                                  |
| 819 |    166.920529 |    325.543401 | Lafage                                                                                                                                                                          |
| 820 |    670.925034 |      5.245381 | Gareth Monger                                                                                                                                                                   |
| 821 |    951.482282 |    638.023871 | Birgit Lang                                                                                                                                                                     |
| 822 |    540.643941 |    290.262466 | Sharon Wegner-Larsen                                                                                                                                                            |
| 823 |    532.060770 |    599.873759 | Kai R. Caspar                                                                                                                                                                   |
| 824 |    839.581199 |    573.520546 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                                                   |
| 825 |    298.934911 |    375.018217 | Kanchi Nanjo                                                                                                                                                                    |
| 826 |    990.319059 |    417.303039 | Emily Willoughby                                                                                                                                                                |
| 827 |    182.824021 |    687.027099 | Matt Crook                                                                                                                                                                      |
| 828 |    412.970767 |    564.931120 | Original drawing by Antonov, vectorized by Roberto Díaz Sibaja                                                                                                                  |
| 829 |    374.145370 |    213.968205 | Alexander Schmidt-Lebuhn                                                                                                                                                        |
| 830 |    669.057348 |    118.547821 | Dr. Thomas G. Barnes, USFWS                                                                                                                                                     |
| 831 |    495.919885 |    496.067160 | Tasman Dixon                                                                                                                                                                    |
| 832 |    973.080776 |    254.557660 | Andrew A. Farke                                                                                                                                                                 |
| 833 |    279.595510 |    349.772533 | Cristina Guijarro                                                                                                                                                               |
| 834 |    695.871637 |    663.091584 | Zimices                                                                                                                                                                         |
| 835 |    471.787315 |    712.368501 | Tasman Dixon                                                                                                                                                                    |
| 836 |    688.494734 |    567.355660 | Margot Michaud                                                                                                                                                                  |
| 837 |    175.303121 |    352.031918 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                                 |
| 838 |    815.724279 |      5.049794 | Markus A. Grohme                                                                                                                                                                |
| 839 |    280.899309 |    708.724210 | Harold N Eyster                                                                                                                                                                 |
| 840 |    792.878533 |     82.945024 | Roberto Díaz Sibaja                                                                                                                                                             |
| 841 |    612.937325 |    764.000621 | Matt Crook                                                                                                                                                                      |
| 842 |    347.223729 |    768.407801 | Steven Traver                                                                                                                                                                   |
| 843 |    731.013958 |    563.274581 | Lukasiniho                                                                                                                                                                      |
| 844 |    597.827256 |    241.321265 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 845 |    751.945446 |    439.495447 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 846 |    291.934021 |    474.737310 | Anthony Caravaggi                                                                                                                                                               |
| 847 |    434.593981 |    382.462327 | Birgit Lang                                                                                                                                                                     |
| 848 |    830.319203 |    290.697057 | Tasman Dixon                                                                                                                                                                    |
| 849 |    614.520734 |     86.219055 | Birgit Lang                                                                                                                                                                     |
| 850 |    642.100149 |    111.473940 | Chloé Schmidt                                                                                                                                                                   |
| 851 |    616.202541 |    433.043467 | Scott Hartman                                                                                                                                                                   |
| 852 |    287.916913 |    488.640967 | Julio Garza                                                                                                                                                                     |
| 853 |     29.774338 |    793.068052 | Matt Martyniuk                                                                                                                                                                  |
| 854 |    498.920731 |     86.846381 | Chuanixn Yu                                                                                                                                                                     |
| 855 |     17.443103 |    367.368891 | NA                                                                                                                                                                              |
| 856 |    745.577581 |     82.873352 | Ron Holmes/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                                                    |
| 857 |    179.738417 |    507.937450 | Andreas Trepte (vectorized by T. Michael Keesey)                                                                                                                                |
| 858 |    768.077209 |    197.750705 | Scott Hartman                                                                                                                                                                   |
| 859 |    925.443635 |     97.969180 | Gareth Monger                                                                                                                                                                   |
| 860 |    554.114444 |    781.450004 | Kamil S. Jaron                                                                                                                                                                  |
| 861 |    526.187369 |    709.877593 | Gareth Monger                                                                                                                                                                   |
| 862 |    176.712856 |    259.938498 | T. Michael Keesey                                                                                                                                                               |
| 863 |    580.565903 |    357.889904 | Ferran Sayol                                                                                                                                                                    |
| 864 |    616.102173 |    113.809412 | Matt Crook                                                                                                                                                                      |
| 865 |    326.105041 |     80.191116 | Birgit Lang                                                                                                                                                                     |
| 866 |   1009.109313 |    537.445612 | Matt Martyniuk                                                                                                                                                                  |
| 867 |    391.273040 |    461.813527 | T. Michael Keesey                                                                                                                                                               |
| 868 |    107.897975 |     63.019954 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 869 |     97.201427 |    521.563190 | NA                                                                                                                                                                              |
| 870 |    879.089818 |    590.620997 | Michelle Site                                                                                                                                                                   |
| 871 |    209.363917 |     11.443853 | Beth Reinke                                                                                                                                                                     |
| 872 |    791.684500 |    558.034771 | Sarah Werning                                                                                                                                                                   |
| 873 |    619.207339 |    532.778406 | NA                                                                                                                                                                              |
| 874 |    690.584975 |     24.872480 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                                  |
| 875 |    811.771849 |    161.279762 | Tasman Dixon                                                                                                                                                                    |
| 876 |    102.678515 |    788.116149 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                              |
| 877 |   1009.678197 |    576.603429 | Steven Traver                                                                                                                                                                   |
| 878 |    220.276703 |    296.164603 | Ferran Sayol                                                                                                                                                                    |
| 879 |    747.076042 |    595.471472 | Ludwik Gasiorowski                                                                                                                                                              |
| 880 |    132.343893 |     11.804773 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                                  |
| 881 |    247.031419 |    243.611809 | T. Michael Keesey (vectorization) and Nadiatalent (photography)                                                                                                                 |
| 882 |    381.857148 |    195.745581 | Zimices                                                                                                                                                                         |
| 883 |     41.285624 |    781.541129 | Steven Traver                                                                                                                                                                   |
| 884 |    553.232814 |    274.146558 | Gopal Murali                                                                                                                                                                    |
| 885 |    356.773117 |    563.685541 | C. Camilo Julián-Caballero                                                                                                                                                      |
| 886 |    616.446080 |    797.276699 | C. Camilo Julián-Caballero                                                                                                                                                      |
| 887 |     20.733541 |    705.267978 | Gareth Monger                                                                                                                                                                   |
| 888 |     55.884543 |    199.276825 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 889 |    812.155785 |    180.679864 | Matt Crook                                                                                                                                                                      |
| 890 |    472.336181 |    664.946338 | NA                                                                                                                                                                              |
| 891 |    282.697055 |    457.011171 | Chris huh                                                                                                                                                                       |
| 892 |    670.313720 |     70.225490 | Ignacio Contreras                                                                                                                                                               |
| 893 |    178.951429 |     57.068155 | Birgit Lang; based on a drawing by C.L. Koch                                                                                                                                    |
| 894 |    539.173475 |    610.318268 | Jose Carlos Arenas-Monroy                                                                                                                                                       |
| 895 |    531.991712 |    503.030625 | Zimices                                                                                                                                                                         |
| 896 |    374.886558 |    321.008929 | Scott Hartman                                                                                                                                                                   |
| 897 |    847.571043 |     15.709675 | Jaime Headden                                                                                                                                                                   |
| 898 |    628.879277 |    412.772248 | Chuanixn Yu                                                                                                                                                                     |
| 899 |    280.210864 |    561.674484 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                                     |
| 900 |    140.322141 |    285.296115 | Chris huh                                                                                                                                                                       |
| 901 |    340.524669 |    650.004437 | NA                                                                                                                                                                              |
| 902 |    153.324928 |    434.691928 | Ignacio Contreras                                                                                                                                                               |
| 903 |     44.852162 |    426.043782 | Zimices                                                                                                                                                                         |
| 904 |    332.698634 |     97.519606 | C. Camilo Julián-Caballero                                                                                                                                                      |
| 905 |    935.389531 |    307.066741 | Martin R. Smith                                                                                                                                                                 |
| 906 |    821.028895 |    512.719572 | Margot Michaud                                                                                                                                                                  |
| 907 |    838.394452 |    508.020130 | Lani Mohan                                                                                                                                                                      |
| 908 |   1009.868064 |     98.255602 | David Orr                                                                                                                                                                       |
| 909 |    396.527339 |     24.631855 | Beth Reinke                                                                                                                                                                     |
| 910 |    330.132743 |    702.506940 | Florian Pfaff                                                                                                                                                                   |
| 911 |    182.583918 |    345.078005 | Carlos Cano-Barbacil                                                                                                                                                            |
| 912 |    230.128327 |     72.420830 | Iain Reid                                                                                                                                                                       |
| 913 |    489.637573 |    115.992916 | Chloé Schmidt                                                                                                                                                                   |
| 914 |    701.835961 |    714.656005 | Dmitry Bogdanov, vectorized by Zimices                                                                                                                                          |
| 915 |    406.218441 |    795.471734 | Zimices                                                                                                                                                                         |
| 916 |    357.646749 |    663.090006 | Tracy A. Heath                                                                                                                                                                  |
| 917 |    622.949976 |    495.178861 | Steven Traver                                                                                                                                                                   |
| 918 |    946.516560 |    135.527697 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 919 |    119.591792 |     39.889123 | T. Michael Keesey                                                                                                                                                               |

    #> Your tweet has been posted!
