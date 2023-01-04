
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

Mathieu Basille, Dmitry Bogdanov (vectorized by T. Michael Keesey), Jim
Bendon (photography) and T. Michael Keesey (vectorization), Kent Elson
Sorgon, Cesar Julian, Luis Cunha, Fernando Carezzano, Chris huh, Jay
Matternes (vectorized by T. Michael Keesey), Gareth Monger, Mattia
Menchetti, Collin Gross, Gabriela Palomo-Munoz, Sharon Wegner-Larsen,
Dean Schnabel, Mathieu Pélissié, T. Michael Keesey, Mali’o Kodis,
photograph by Melissa Frey, Steven Traver, Margot Michaud, Zimices,
Kamil S. Jaron, Birgit Lang, H. Filhol (vectorized by T. Michael
Keesey), Matt Crook, Maija Karala, Scott Hartman, C. Camilo
Julián-Caballero, ДиБгд (vectorized by T. Michael Keesey), Jack Mayer
Wood, Alex Slavenko, Michael Scroggie, Michelle Site, Christoph
Schomburg, Jagged Fang Designs, Emily Willoughby, Michele Tobias,
Rebecca Groom, Jaime A. Headden (vectorized by T. Michael Keesey), T.
Michael Keesey (after Monika Betley), Ignacio Contreras, Andy Wilson,
Natalie Claunch, Ramona J Heim, Markus A. Grohme, Todd Marshall,
vectorized by Zimices, Obsidian Soul (vectorized by T. Michael Keesey),
Kenneth Lacovara (vectorized by T. Michael Keesey), Steven Coombs,
Sebastian Stabinger, Tasman Dixon, Anthony Caravaggi, Mathew Wedel,
Ferran Sayol, Noah Schlottman, photo from Moorea Biocode, David Orr,
Ingo Braasch, Manabu Sakamoto, Kai R. Caspar, Nobu Tamura (vectorized by
T. Michael Keesey), T. Michael Keesey (after Colin M. L. Burnett),
Agnello Picorelli, Jaime Headden, Tony Ayling (vectorized by T. Michael
Keesey), Ray Simpson (vectorized by T. Michael Keesey),
Archaeodontosaurus (vectorized by T. Michael Keesey), Apokryltaros
(vectorized by T. Michael Keesey), Matt Martyniuk, Pearson Scott
Foresman (vectorized by T. Michael Keesey), Becky Barnes, T. Michael
Keesey (vectorization) and Nadiatalent (photography), Chris Hay, Sarah
Werning, Matt Martyniuk (vectorized by T. Michael Keesey), Ernst Haeckel
(vectorized by T. Michael Keesey), Metalhead64 (vectorized by T. Michael
Keesey), Felix Vaux and Steven A. Trewick, Matthew E. Clapham, Mali’o
Kodis, photograph from
<http://commons.wikimedia.org/wiki/File:Trichoplax.jpg>, Iain Reid,
Carlos Cano-Barbacil, L. Shyamal, Joanna Wolfe, Jan A. Venter, Herbert
H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael
Keesey), Mali’o Kodis, image by Rebecca Ritger, Noah Schlottman, photo
from Casey Dunn, Felix Vaux, Jiekun He, Lily Hughes, Michael P. Taylor,
T. Michael Keesey (vectorization); Thorsten Assmann, Jörn Buse, Claudia
Drees, Ariel-Leib-Leonid Friedman, Tal Levanony, Andrea Matern, Anika
Timm, and David W. Wrase (photography), T. Tischler, Andrew A. Farke,
Sam Droege (photo) and T. Michael Keesey (vectorization), Pedro de
Siracusa, Emily Jane McTavish, from Haeckel, E. H. P. A.
(1904).Kunstformen der Natur. Bibliographisches, Tim Bertelink (modified
by T. Michael Keesey), Jonathan Wells, Terpsichores, Skye McDavid, Conty
(vectorized by T. Michael Keesey), David Sim (photograph) and T. Michael
Keesey (vectorization), Mason McNair, Beth Reinke, Qiang Ou, Mali’o
Kodis, photograph property of National Museums of Northern Ireland,
Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo
Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael
Keesey), Michael Day, (after Spotila 2004), Tracy A. Heath, Juan Carlos
Jerí, Pete Buchholz, Yan Wong from illustration by Charles Orbigny,
Claus Rebler, U.S. Fish and Wildlife Service (illustration) and Timothy
J. Bartley (silhouette), Crystal Maier, Mathilde Cordellier, Smokeybjb,
Mali’o Kodis, image from the Smithsonian Institution, Louis Ranjard,
Kailah Thorn & Mark Hutchinson, FJDegrange, Gopal Murali, S.Martini,
Francis de Laporte de Castelnau (vectorized by T. Michael Keesey),
Sergio A. Muñoz-Gómez, Cathy, Darren Naish (vectorized by T. Michael
Keesey), zoosnow, Dantheman9758 (vectorized by T. Michael Keesey), Neil
Kelley, Jake Warner, Armin Reindl, Tauana J. Cunha, Auckland Museum,
Mali’o Kodis, photograph by Cordell Expeditions at Cal Academy, Tyler
Greenfield and Scott Hartman, Jose Carlos Arenas-Monroy, James R.
Spotila and Ray Chatterji, Xavier Giroux-Bougard, Ralf Janssen,
Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael
Keesey), Melissa Broussard, Eyal Bartov, Noah Schlottman, photo by
Reinhard Jahn, Francesco Veronesi (vectorized by T. Michael Keesey),
Fernando Campos De Domenico, FunkMonk, Jessica Rick, Darren Naish
(vectorize by T. Michael Keesey), Ian Burt (original) and T. Michael
Keesey (vectorization), Nobu Tamura, xgirouxb, Erika Schumacher, Diana
Pomeroy, Benjamint444, Bruno Maggia, Eric Moody, Mali’o Kodis,
photograph by Ching (<http://www.flickr.com/photos/36302473@N03/>),
Caleb M. Brown, Henry Fairfield Osborn, vectorized by Zimices, Yan Wong,
Zsoldos Márton (vectorized by T. Michael Keesey), Katie S. Collins,
Griensteidl and T. Michael Keesey, Didier Descouens (vectorized by T.
Michael Keesey), www.studiospectre.com, Matt Wilkins (photo by Patrick
Kavanagh), Mark Witton, Taro Maeda, Joedison Rocha, T. Michael Keesey
(vectorization) and Larry Loos (photography), Steven Coombs (vectorized
by T. Michael Keesey), SecretJellyMan - from Mason McNair, Tyler
Greenfield, Birgit Lang, based on a photo by D. Sikes, Nancy Wyman
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Joschua Knüppe, Nicholas J. Czaplewski, vectorized by Zimices,
Dinah Challen, Mali’o Kodis, photograph by John Slapcinsky, Catherine
Yasuda, Ludwik Gąsiorowski, Jakovche, Matus Valach, Dave Angelini,
Berivan Temiz, Henry Lydecker, C. W. Nash (illustration) and Timothy J.
Bartley (silhouette), T. Michael Keesey (vectorization) and HuttyMcphoo
(photography), Mali’o Kodis, photograph by P. Funch and R.M. Kristensen,
M Hutchinson, Myriam\_Ramirez, Jimmy Bernot, Oscar Sanisidro, Karla
Martinez, Oliver Griffith, Brad McFeeters (vectorized by T. Michael
Keesey), Alexander Schmidt-Lebuhn, Lip Kee Yap (vectorized by T. Michael
Keesey), CNZdenek, Frank Förster, Robbie N. Cada (vectorized by T.
Michael Keesey), Gabriel Lio, vectorized by Zimices, Roberto Diaz
Sibaja, based on Domser, Andrew R. Gehrke, Robert Hering, Harold N
Eyster, Saguaro Pictures (source photo) and T. Michael Keesey, C.
Abraczinskas, Nobu Tamura, vectorized by Zimices, Jaime Headden,
modified by T. Michael Keesey, Lukasiniho, JCGiron, Doug Backlund
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Martin Kevil, terngirl, Chuanixn Yu, Philippe Janvier
(vectorized by T. Michael Keesey), Auckland Museum and T. Michael
Keesey, Mariana Ruiz Villarreal (modified by T. Michael Keesey), Ieuan
Jones, Вальдимар (vectorized by T. Michael Keesey), Dennis C. Murphy,
after
<https://commons.wikimedia.org/wiki/File:Queensland_State_Archives_2981_Cane_toads_at_the_Meringa_Sugar_Experiment_Station_North_Queensland_c_1935.png>,
V. Deepak, Tommaso Cancellario, Mattia Menchetti / Yan Wong, T. Michael
Keesey (after Mauricio Antón), Mo Hassan, Matt Dempsey, Isaure
Scavezzoni, Charles Doolittle Walcott (vectorized by T. Michael Keesey),
Jordan Mallon (vectorized by T. Michael Keesey), E. Lear, 1819
(vectorization by Yan Wong), Davidson Sodré, Yan Wong from drawing by T.
F. Zimmermann, Joe Schneid (vectorized by T. Michael Keesey), Arthur
Weasley (vectorized by T. Michael Keesey), Stanton F. Fink (vectorized
by T. Michael Keesey), Owen Jones, Francesca Belem Lopes Palmeira,
Mercedes Yrayzoz (vectorized by T. Michael Keesey), Marmelad, Kelly,
david maas / dave hone, Maha Ghazal, Diego Fontaneto, Elisabeth A.
Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia
Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey),
Matthias Buschmann (vectorized by T. Michael Keesey), Roberto Díaz
Sibaja, Mali’o Kodis, photograph by Bruno Vellutini, Smokeybjb (modified
by T. Michael Keesey), Michael B. H. (vectorized by T. Michael Keesey),
Kimberly Haddrell, Natasha Vitek, Noah Schlottman, photo by Casey Dunn,
Cristina Guijarro, B. Duygu Özpolat, Timothy Knepp (vectorized by T.
Michael Keesey), Arthur S. Brum, Mette Aumala, SauropodomorphMonarch,
Christina N. Hodson, Ewald Rübsamen, Chase Brownstein, Jerry Oldenettel
(vectorized by T. Michael Keesey), J. J. Harrison (photo) & T. Michael
Keesey

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                               |
| --: | ------------: | ------------: | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    588.117229 |    618.963997 | Mathieu Basille                                                                                                                                                                      |
|   2 |    356.572379 |    743.980620 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
|   3 |    115.605880 |    152.198483 | Jim Bendon (photography) and T. Michael Keesey (vectorization)                                                                                                                       |
|   4 |    299.829770 |    406.321293 | Kent Elson Sorgon                                                                                                                                                                    |
|   5 |    459.727654 |    563.321943 | Cesar Julian                                                                                                                                                                         |
|   6 |    410.679400 |    250.577711 | Luis Cunha                                                                                                                                                                           |
|   7 |    289.892438 |    551.709124 | Fernando Carezzano                                                                                                                                                                   |
|   8 |    723.443262 |    312.788205 | Chris huh                                                                                                                                                                            |
|   9 |    768.082151 |    196.921121 | Jay Matternes (vectorized by T. Michael Keesey)                                                                                                                                      |
|  10 |    420.741257 |     77.096526 | Gareth Monger                                                                                                                                                                        |
|  11 |    251.543196 |    682.175477 | Mattia Menchetti                                                                                                                                                                     |
|  12 |    783.769093 |    603.543298 | Collin Gross                                                                                                                                                                         |
|  13 |     72.943928 |    491.271568 | Gabriela Palomo-Munoz                                                                                                                                                                |
|  14 |    510.147710 |    660.522946 | Sharon Wegner-Larsen                                                                                                                                                                 |
|  15 |    916.857874 |     98.324020 | Dean Schnabel                                                                                                                                                                        |
|  16 |    545.070085 |    247.877925 | Mathieu Pélissié                                                                                                                                                                     |
|  17 |     78.670520 |    264.934229 | Gabriela Palomo-Munoz                                                                                                                                                                |
|  18 |    738.313030 |    428.051425 | T. Michael Keesey                                                                                                                                                                    |
|  19 |    343.553092 |    238.022449 | Mali’o Kodis, photograph by Melissa Frey                                                                                                                                             |
|  20 |    912.688944 |    462.355925 | Steven Traver                                                                                                                                                                        |
|  21 |    656.618890 |    537.837923 | Margot Michaud                                                                                                                                                                       |
|  22 |    224.774227 |     56.794578 | Zimices                                                                                                                                                                              |
|  23 |    113.833364 |    605.822375 | Kamil S. Jaron                                                                                                                                                                       |
|  24 |    733.567459 |     73.297333 | Birgit Lang                                                                                                                                                                          |
|  25 |    694.803601 |    714.107444 | H. Filhol (vectorized by T. Michael Keesey)                                                                                                                                          |
|  26 |     73.901908 |    359.149498 | Matt Crook                                                                                                                                                                           |
|  27 |    426.892063 |    517.627988 | Maija Karala                                                                                                                                                                         |
|  28 |    701.999530 |    134.288957 | Scott Hartman                                                                                                                                                                        |
|  29 |    545.401039 |    440.438073 | Gareth Monger                                                                                                                                                                        |
|  30 |    872.681144 |    648.280725 | Matt Crook                                                                                                                                                                           |
|  31 |    571.224031 |     58.848303 | Steven Traver                                                                                                                                                                        |
|  32 |    668.102548 |    213.828890 | C. Camilo Julián-Caballero                                                                                                                                                           |
|  33 |    924.456668 |    218.718846 | Matt Crook                                                                                                                                                                           |
|  34 |    464.846888 |    614.297097 | ДиБгд (vectorized by T. Michael Keesey)                                                                                                                                              |
|  35 |    588.255171 |    710.219012 | Jack Mayer Wood                                                                                                                                                                      |
|  36 |    129.576254 |    751.839202 | Steven Traver                                                                                                                                                                        |
|  37 |    957.697175 |    710.144358 | Alex Slavenko                                                                                                                                                                        |
|  38 |    472.747231 |    210.324889 | Michael Scroggie                                                                                                                                                                     |
|  39 |    558.474513 |    740.528674 | Gabriela Palomo-Munoz                                                                                                                                                                |
|  40 |    854.512638 |    427.094026 | Michelle Site                                                                                                                                                                        |
|  41 |    990.391268 |    287.722750 | Christoph Schomburg                                                                                                                                                                  |
|  42 |    837.287465 |    726.749880 | Jagged Fang Designs                                                                                                                                                                  |
|  43 |    949.824812 |    553.728941 | Margot Michaud                                                                                                                                                                       |
|  44 |    395.083099 |    672.306375 | Emily Willoughby                                                                                                                                                                     |
|  45 |    438.291085 |    760.950336 | Michele Tobias                                                                                                                                                                       |
|  46 |    870.200591 |    528.875337 | Gabriela Palomo-Munoz                                                                                                                                                                |
|  47 |    107.214238 |    531.657408 | Jagged Fang Designs                                                                                                                                                                  |
|  48 |    260.642872 |    196.827859 | Rebecca Groom                                                                                                                                                                        |
|  49 |    217.394171 |    477.961025 | Alex Slavenko                                                                                                                                                                        |
|  50 |    629.922702 |    680.611192 | Jaime A. Headden (vectorized by T. Michael Keesey)                                                                                                                                   |
|  51 |    258.657693 |    112.196765 | NA                                                                                                                                                                                   |
|  52 |    181.917954 |    287.586340 | T. Michael Keesey (after Monika Betley)                                                                                                                                              |
|  53 |     70.084080 |     24.579733 | Gareth Monger                                                                                                                                                                        |
|  54 |    111.297770 |    680.550339 | NA                                                                                                                                                                                   |
|  55 |    185.162855 |    783.720139 | Ignacio Contreras                                                                                                                                                                    |
|  56 |    716.432206 |    570.657437 | Matt Crook                                                                                                                                                                           |
|  57 |    969.460097 |    134.130302 | Andy Wilson                                                                                                                                                                          |
|  58 |    633.575775 |    443.127007 | Natalie Claunch                                                                                                                                                                      |
|  59 |    762.373436 |    783.410170 | Scott Hartman                                                                                                                                                                        |
|  60 |    935.516411 |    345.086332 | Gareth Monger                                                                                                                                                                        |
|  61 |    844.523668 |    110.699499 | Ramona J Heim                                                                                                                                                                        |
|  62 |    958.681045 |    761.030839 | Markus A. Grohme                                                                                                                                                                     |
|  63 |    825.587501 |     22.632755 | Todd Marshall, vectorized by Zimices                                                                                                                                                 |
|  64 |    166.712322 |    560.964980 | Matt Crook                                                                                                                                                                           |
|  65 |    743.896710 |    474.555295 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                                      |
|  66 |   1006.196747 |    389.883595 | NA                                                                                                                                                                                   |
|  67 |    750.258478 |     33.293325 | Kenneth Lacovara (vectorized by T. Michael Keesey)                                                                                                                                   |
|  68 |    846.448494 |    769.913296 | Steven Coombs                                                                                                                                                                        |
|  69 |    350.272886 |    616.534010 | Sebastian Stabinger                                                                                                                                                                  |
|  70 |    294.924386 |    323.666260 | Chris huh                                                                                                                                                                            |
|  71 |    697.808098 |    378.729413 | Sharon Wegner-Larsen                                                                                                                                                                 |
|  72 |    315.721636 |    492.251286 | Tasman Dixon                                                                                                                                                                         |
|  73 |    343.532857 |     95.812812 | Dean Schnabel                                                                                                                                                                        |
|  74 |    455.255649 |    449.726337 | Anthony Caravaggi                                                                                                                                                                    |
|  75 |    774.181082 |    663.484799 | Mathew Wedel                                                                                                                                                                         |
|  76 |    782.729239 |    246.449773 | Chris huh                                                                                                                                                                            |
|  77 |    694.678288 |    760.225082 | NA                                                                                                                                                                                   |
|  78 |     53.180278 |    753.369486 | Ferran Sayol                                                                                                                                                                         |
|  79 |    871.768051 |    740.827259 | Noah Schlottman, photo from Moorea Biocode                                                                                                                                           |
|  80 |    924.856102 |    748.582933 | David Orr                                                                                                                                                                            |
|  81 |    306.331276 |    152.419214 | Ferran Sayol                                                                                                                                                                         |
|  82 |    967.914447 |    640.377426 | Matt Crook                                                                                                                                                                           |
|  83 |    535.027792 |    160.376700 | Ingo Braasch                                                                                                                                                                         |
|  84 |    806.319665 |    757.103751 | Dean Schnabel                                                                                                                                                                        |
|  85 |    273.540575 |    622.869025 | Manabu Sakamoto                                                                                                                                                                      |
|  86 |    666.262309 |     36.656069 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
|  87 |    516.225350 |    371.930032 | Jagged Fang Designs                                                                                                                                                                  |
|  88 |    138.833125 |    482.143610 | Kai R. Caspar                                                                                                                                                                        |
|  89 |     50.079189 |    570.303642 | Gabriela Palomo-Munoz                                                                                                                                                                |
|  90 |    806.905490 |    390.571579 | T. Michael Keesey                                                                                                                                                                    |
|  91 |    618.490472 |    768.145162 | Ignacio Contreras                                                                                                                                                                    |
|  92 |    311.683898 |     24.663410 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
|  93 |     88.437782 |    436.956393 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
|  94 |    591.486232 |    517.859505 | Margot Michaud                                                                                                                                                                       |
|  95 |    517.132695 |    399.912355 | Matt Crook                                                                                                                                                                           |
|  96 |    118.833766 |    222.119813 | T. Michael Keesey (after Colin M. L. Burnett)                                                                                                                                        |
|  97 |    749.197127 |    504.454546 | NA                                                                                                                                                                                   |
|  98 |    109.682237 |     38.156336 | Zimices                                                                                                                                                                              |
|  99 |    356.549184 |    761.363215 | Matt Crook                                                                                                                                                                           |
| 100 |    127.110039 |     58.089082 | NA                                                                                                                                                                                   |
| 101 |    127.651202 |    441.064168 | Jagged Fang Designs                                                                                                                                                                  |
| 102 |    369.392142 |    469.257896 | Agnello Picorelli                                                                                                                                                                    |
| 103 |    547.592726 |    570.940022 | Jaime Headden                                                                                                                                                                        |
| 104 |    384.778895 |    324.142369 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                                        |
| 105 |    790.497529 |    138.515318 | Ray Simpson (vectorized by T. Michael Keesey)                                                                                                                                        |
| 106 |     31.050152 |    714.813450 | Archaeodontosaurus (vectorized by T. Michael Keesey)                                                                                                                                 |
| 107 |    958.612287 |    743.206498 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                                       |
| 108 |    989.183511 |     11.631895 | Jagged Fang Designs                                                                                                                                                                  |
| 109 |    252.698022 |    741.761834 | Jagged Fang Designs                                                                                                                                                                  |
| 110 |    287.422636 |    265.190961 | Zimices                                                                                                                                                                              |
| 111 |    896.687532 |     25.776536 | Cesar Julian                                                                                                                                                                         |
| 112 |    387.668047 |    154.402453 | Margot Michaud                                                                                                                                                                       |
| 113 |    651.929947 |    419.407309 | Matt Martyniuk                                                                                                                                                                       |
| 114 |     15.720632 |    776.696021 | Zimices                                                                                                                                                                              |
| 115 |    694.774944 |      5.845740 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                                             |
| 116 |    914.831165 |    654.731369 | Tasman Dixon                                                                                                                                                                         |
| 117 |    986.924584 |    508.675571 | Zimices                                                                                                                                                                              |
| 118 |     19.782696 |    325.583705 | Dean Schnabel                                                                                                                                                                        |
| 119 |    284.815975 |     18.897157 | Jagged Fang Designs                                                                                                                                                                  |
| 120 |    792.391121 |    687.382432 | Matt Crook                                                                                                                                                                           |
| 121 |    516.229776 |    527.134105 | Becky Barnes                                                                                                                                                                         |
| 122 |    147.047023 |    344.720770 | T. Michael Keesey (vectorization) and Nadiatalent (photography)                                                                                                                      |
| 123 |    638.929006 |    620.206424 | Zimices                                                                                                                                                                              |
| 124 |   1008.963014 |    708.737648 | Zimices                                                                                                                                                                              |
| 125 |    396.317121 |    352.079538 | NA                                                                                                                                                                                   |
| 126 |    853.807003 |    491.935966 | Chris Hay                                                                                                                                                                            |
| 127 |    120.494376 |    258.775015 | Jagged Fang Designs                                                                                                                                                                  |
| 128 |    290.844152 |    226.898759 | T. Michael Keesey                                                                                                                                                                    |
| 129 |     97.963562 |    463.154451 | Sarah Werning                                                                                                                                                                        |
| 130 |    703.437358 |    177.756464 | Zimices                                                                                                                                                                              |
| 131 |    627.295007 |    739.450321 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                                     |
| 132 |    666.874109 |    114.123149 | Matt Crook                                                                                                                                                                           |
| 133 |    367.069283 |    500.802343 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                                      |
| 134 |    829.425048 |    643.365170 | Chris huh                                                                                                                                                                            |
| 135 |    817.028543 |     74.500586 | T. Michael Keesey                                                                                                                                                                    |
| 136 |    726.024973 |    785.623221 | Zimices                                                                                                                                                                              |
| 137 |    853.753421 |    217.243111 | T. Michael Keesey                                                                                                                                                                    |
| 138 |    876.699553 |    187.721181 | Metalhead64 (vectorized by T. Michael Keesey)                                                                                                                                        |
| 139 |    133.968838 |    457.728917 | Ferran Sayol                                                                                                                                                                         |
| 140 |    488.344891 |    766.930051 | Felix Vaux and Steven A. Trewick                                                                                                                                                     |
| 141 |    496.718155 |     56.614383 | Gareth Monger                                                                                                                                                                        |
| 142 |    665.311325 |    166.031708 | NA                                                                                                                                                                                   |
| 143 |    172.269158 |    151.024536 | Matthew E. Clapham                                                                                                                                                                   |
| 144 |     32.081092 |    455.094833 | Steven Traver                                                                                                                                                                        |
| 145 |    566.280275 |    128.273206 | Mali’o Kodis, photograph from <http://commons.wikimedia.org/wiki/File:Trichoplax.jpg>                                                                                                |
| 146 |    312.215188 |     77.566286 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 147 |    592.499652 |    538.022287 | Iain Reid                                                                                                                                                                            |
| 148 |    657.923739 |    775.132540 | Collin Gross                                                                                                                                                                         |
| 149 |    760.068903 |    769.869180 | T. Michael Keesey                                                                                                                                                                    |
| 150 |    681.544555 |    569.736251 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 151 |    905.291941 |    141.710254 | NA                                                                                                                                                                                   |
| 152 |    824.348051 |    492.269318 | L. Shyamal                                                                                                                                                                           |
| 153 |     13.340557 |    281.743354 | Gareth Monger                                                                                                                                                                        |
| 154 |    224.404204 |    515.584674 | Matt Crook                                                                                                                                                                           |
| 155 |    517.842616 |    249.804496 | Joanna Wolfe                                                                                                                                                                         |
| 156 |    123.170461 |    560.707065 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                                  |
| 157 |      5.534232 |    790.538507 | Mali’o Kodis, image by Rebecca Ritger                                                                                                                                                |
| 158 |    481.691535 |     30.387640 | Noah Schlottman, photo from Casey Dunn                                                                                                                                               |
| 159 |    561.041505 |    307.472083 | Scott Hartman                                                                                                                                                                        |
| 160 |    181.215736 |    127.219503 | Joanna Wolfe                                                                                                                                                                         |
| 161 |    136.264103 |    324.993073 | Felix Vaux                                                                                                                                                                           |
| 162 |   1011.463102 |    502.598287 | Birgit Lang                                                                                                                                                                          |
| 163 |    801.219278 |    536.407338 | Tasman Dixon                                                                                                                                                                         |
| 164 |    190.361860 |    699.045132 | Jiekun He                                                                                                                                                                            |
| 165 |    159.766366 |    645.330726 | Lily Hughes                                                                                                                                                                          |
| 166 |    653.718707 |    790.420774 | Gareth Monger                                                                                                                                                                        |
| 167 |    807.209079 |    355.364530 | Birgit Lang                                                                                                                                                                          |
| 168 |    343.547879 |    753.999907 | Margot Michaud                                                                                                                                                                       |
| 169 |    650.755592 |    174.172727 | NA                                                                                                                                                                                   |
| 170 |    464.187510 |     80.214521 | Scott Hartman                                                                                                                                                                        |
| 171 |    868.134960 |    796.673728 | Markus A. Grohme                                                                                                                                                                     |
| 172 |    695.527833 |    523.664588 | Michael P. Taylor                                                                                                                                                                    |
| 173 |    112.905348 |    483.341835 | T. Michael Keesey (vectorization); Thorsten Assmann, Jörn Buse, Claudia Drees, Ariel-Leib-Leonid Friedman, Tal Levanony, Andrea Matern, Anika Timm, and David W. Wrase (photography) |
| 174 |   1005.450449 |    462.903642 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 175 |    309.581369 |    700.705183 | T. Tischler                                                                                                                                                                          |
| 176 |     22.722526 |    609.848151 | Margot Michaud                                                                                                                                                                       |
| 177 |     44.392850 |    448.348485 | Gareth Monger                                                                                                                                                                        |
| 178 |    280.119080 |    728.447470 | Zimices                                                                                                                                                                              |
| 179 |    856.337045 |    354.404170 | Matt Martyniuk                                                                                                                                                                       |
| 180 |    827.466966 |    372.093872 | Andrew A. Farke                                                                                                                                                                      |
| 181 |    257.718904 |    276.528425 | Sharon Wegner-Larsen                                                                                                                                                                 |
| 182 |    987.246903 |     40.630583 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 183 |    460.520018 |    328.594421 | Andrew A. Farke                                                                                                                                                                      |
| 184 |    984.899633 |    693.099732 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 185 |    426.865612 |    637.699190 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 186 |    989.583029 |    473.005247 | Jagged Fang Designs                                                                                                                                                                  |
| 187 |    842.019218 |    199.285813 | Matt Crook                                                                                                                                                                           |
| 188 |     63.609861 |    682.987885 | Sam Droege (photo) and T. Michael Keesey (vectorization)                                                                                                                             |
| 189 |    453.761198 |    794.246056 | Steven Traver                                                                                                                                                                        |
| 190 |    867.611303 |    583.301518 | Pedro de Siracusa                                                                                                                                                                    |
| 191 |    157.770351 |    320.890645 | Andy Wilson                                                                                                                                                                          |
| 192 |    768.745159 |    740.971181 | Steven Traver                                                                                                                                                                        |
| 193 |    357.607159 |    585.321517 | Emily Jane McTavish, from Haeckel, E. H. P. A. (1904).Kunstformen der Natur. Bibliographisches                                                                                       |
| 194 |    392.605082 |    606.707935 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 195 |    308.840732 |    179.441151 | Steven Traver                                                                                                                                                                        |
| 196 |    762.967935 |    166.174839 | Tim Bertelink (modified by T. Michael Keesey)                                                                                                                                        |
| 197 |    473.097040 |    278.921753 | T. Michael Keesey                                                                                                                                                                    |
| 198 |    556.880660 |    143.714690 | Gareth Monger                                                                                                                                                                        |
| 199 |    293.835967 |    215.040033 | Zimices                                                                                                                                                                              |
| 200 |    666.984336 |    593.954458 | Ferran Sayol                                                                                                                                                                         |
| 201 |    839.205449 |    167.099162 | Andrew A. Farke                                                                                                                                                                      |
| 202 |     93.719024 |    297.951903 | Scott Hartman                                                                                                                                                                        |
| 203 |    192.928266 |    323.829452 | Tasman Dixon                                                                                                                                                                         |
| 204 |    864.615774 |    232.169907 | Jonathan Wells                                                                                                                                                                       |
| 205 |    895.703508 |    784.587256 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 206 |    841.253655 |    230.562889 | Margot Michaud                                                                                                                                                                       |
| 207 |    675.598187 |    248.667888 | Jaime Headden                                                                                                                                                                        |
| 208 |    920.814023 |    279.606727 | Tasman Dixon                                                                                                                                                                         |
| 209 |    966.573224 |    723.740420 | Matt Crook                                                                                                                                                                           |
| 210 |    699.487969 |    194.066637 | Zimices                                                                                                                                                                              |
| 211 |    308.443808 |     96.691219 | Margot Michaud                                                                                                                                                                       |
| 212 |    727.566245 |    221.251707 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 213 |    740.978003 |    110.919918 | Terpsichores                                                                                                                                                                         |
| 214 |    967.112178 |    410.923483 | Skye McDavid                                                                                                                                                                         |
| 215 |    225.267902 |     26.086206 | Gareth Monger                                                                                                                                                                        |
| 216 |    695.886739 |    650.668563 | NA                                                                                                                                                                                   |
| 217 |    107.204763 |    367.129179 | NA                                                                                                                                                                                   |
| 218 |    811.546886 |     23.166257 | Conty (vectorized by T. Michael Keesey)                                                                                                                                              |
| 219 |    916.516414 |    163.286693 | Jagged Fang Designs                                                                                                                                                                  |
| 220 |    753.863482 |    116.827674 | David Sim (photograph) and T. Michael Keesey (vectorization)                                                                                                                         |
| 221 |     54.259662 |    393.198122 | Mason McNair                                                                                                                                                                         |
| 222 |    647.946191 |    753.284072 | Margot Michaud                                                                                                                                                                       |
| 223 |    761.345558 |    557.356225 | Alex Slavenko                                                                                                                                                                        |
| 224 |    699.119839 |    668.480028 | Beth Reinke                                                                                                                                                                          |
| 225 |    599.590003 |    137.906729 | Michael Scroggie                                                                                                                                                                     |
| 226 |    978.312226 |    649.783218 | Matt Crook                                                                                                                                                                           |
| 227 |    546.043612 |    528.052911 | Scott Hartman                                                                                                                                                                        |
| 228 |    518.816973 |    585.529858 | Qiang Ou                                                                                                                                                                             |
| 229 |    272.378964 |    141.190809 | Felix Vaux                                                                                                                                                                           |
| 230 |    575.358572 |    661.863993 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 231 |    349.020087 |    637.236305 | Chris huh                                                                                                                                                                            |
| 232 |    168.251050 |     41.158176 | Steven Traver                                                                                                                                                                        |
| 233 |    545.940608 |    714.423483 | Mali’o Kodis, photograph property of National Museums of Northern Ireland                                                                                                            |
| 234 |    851.678493 |    380.651447 | Dean Schnabel                                                                                                                                                                        |
| 235 |    504.706730 |    496.896687 | T. Michael Keesey                                                                                                                                                                    |
| 236 |   1000.073436 |    600.892271 | Ferran Sayol                                                                                                                                                                         |
| 237 |    939.424039 |     75.408254 | T. Michael Keesey                                                                                                                                                                    |
| 238 |    206.651675 |     95.630655 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 239 |    371.187250 |    597.729551 | Zimices                                                                                                                                                                              |
| 240 |    390.054617 |    128.877418 | Chris huh                                                                                                                                                                            |
| 241 |    844.876727 |    452.696388 | Margot Michaud                                                                                                                                                                       |
| 242 |    313.078150 |    777.674814 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                              |
| 243 |    476.151524 |     74.445505 | Michael Scroggie                                                                                                                                                                     |
| 244 |    955.334159 |    589.559021 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                                 |
| 245 |    784.476218 |    124.420741 | Michael Day                                                                                                                                                                          |
| 246 |    990.981645 |    786.638579 | (after Spotila 2004)                                                                                                                                                                 |
| 247 |    252.711128 |    763.039443 | Anthony Caravaggi                                                                                                                                                                    |
| 248 |    198.211410 |    636.848749 | Tracy A. Heath                                                                                                                                                                       |
| 249 |      8.170160 |    422.296957 | T. Michael Keesey                                                                                                                                                                    |
| 250 |    259.680783 |    306.052162 | Juan Carlos Jerí                                                                                                                                                                     |
| 251 |    126.244082 |    249.144172 | Scott Hartman                                                                                                                                                                        |
| 252 |    805.833698 |    370.511053 | Tracy A. Heath                                                                                                                                                                       |
| 253 |    581.806303 |    367.070717 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 254 |     43.570710 |    787.618565 | Pete Buchholz                                                                                                                                                                        |
| 255 |    304.398007 |    798.234235 | Gareth Monger                                                                                                                                                                        |
| 256 |    413.026665 |    337.471415 | Ferran Sayol                                                                                                                                                                         |
| 257 |    629.208575 |    561.283449 | T. Michael Keesey                                                                                                                                                                    |
| 258 |    380.401173 |    302.094361 | NA                                                                                                                                                                                   |
| 259 |    270.574935 |    600.968385 | Zimices                                                                                                                                                                              |
| 260 |    854.356752 |    243.336094 | NA                                                                                                                                                                                   |
| 261 |    904.053317 |    331.611803 | Yan Wong from illustration by Charles Orbigny                                                                                                                                        |
| 262 |    751.852828 |    137.670860 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 263 |    228.134228 |    255.756333 | Claus Rebler                                                                                                                                                                         |
| 264 |    448.234241 |    301.700733 | Andy Wilson                                                                                                                                                                          |
| 265 |     36.949537 |    392.506020 | NA                                                                                                                                                                                   |
| 266 |    878.210154 |    379.768567 | U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                                                    |
| 267 |     46.507277 |    778.027785 | Birgit Lang                                                                                                                                                                          |
| 268 |     39.277786 |    622.415661 | Crystal Maier                                                                                                                                                                        |
| 269 |   1004.482156 |     73.769284 | Mathilde Cordellier                                                                                                                                                                  |
| 270 |    610.564218 |    364.405334 | Ferran Sayol                                                                                                                                                                         |
| 271 |    377.854380 |    237.074201 | Margot Michaud                                                                                                                                                                       |
| 272 |    867.247607 |     45.045934 | Smokeybjb                                                                                                                                                                            |
| 273 |    588.631263 |    509.710583 | Steven Coombs                                                                                                                                                                        |
| 274 |     72.149836 |    388.614663 | Mali’o Kodis, image from the Smithsonian Institution                                                                                                                                 |
| 275 |     11.286094 |    464.501282 | Louis Ranjard                                                                                                                                                                        |
| 276 |    904.731728 |    672.145370 | Kailah Thorn & Mark Hutchinson                                                                                                                                                       |
| 277 |    583.038786 |    396.900168 | FJDegrange                                                                                                                                                                           |
| 278 |    847.508839 |    476.122808 | Scott Hartman                                                                                                                                                                        |
| 279 |    913.078783 |    726.001402 | Gopal Murali                                                                                                                                                                         |
| 280 |    260.971063 |    640.120557 | Zimices                                                                                                                                                                              |
| 281 |    907.988663 |    712.095083 | Margot Michaud                                                                                                                                                                       |
| 282 |     44.428334 |    650.790665 | NA                                                                                                                                                                                   |
| 283 |    950.695028 |    613.343110 | Sarah Werning                                                                                                                                                                        |
| 284 |    673.375994 |    626.158999 | Beth Reinke                                                                                                                                                                          |
| 285 |    445.497761 |    660.904870 | Steven Traver                                                                                                                                                                        |
| 286 |    444.771618 |    132.072174 | S.Martini                                                                                                                                                                            |
| 287 |    658.908805 |    476.485705 | Zimices                                                                                                                                                                              |
| 288 |    772.525248 |    108.557305 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 289 |    447.076275 |    717.692599 | Luis Cunha                                                                                                                                                                           |
| 290 |     27.639649 |     50.771714 | Zimices                                                                                                                                                                              |
| 291 |    400.324895 |    729.740676 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 292 |    574.764707 |    655.855189 | Matt Crook                                                                                                                                                                           |
| 293 |    869.555604 |    457.678583 | Scott Hartman                                                                                                                                                                        |
| 294 |    428.060201 |    177.540943 | Ferran Sayol                                                                                                                                                                         |
| 295 |    940.411377 |    668.742351 | Steven Traver                                                                                                                                                                        |
| 296 |    857.959026 |    340.696857 | Smokeybjb                                                                                                                                                                            |
| 297 |    169.100878 |    334.967838 | Scott Hartman                                                                                                                                                                        |
| 298 |    212.691249 |    742.118423 | Christoph Schomburg                                                                                                                                                                  |
| 299 |    320.682769 |    586.927495 | Francis de Laporte de Castelnau (vectorized by T. Michael Keesey)                                                                                                                    |
| 300 |    782.044135 |    704.174762 | Markus A. Grohme                                                                                                                                                                     |
| 301 |   1007.498494 |    698.743310 | Chris huh                                                                                                                                                                            |
| 302 |    143.980533 |    235.451256 | Sergio A. Muñoz-Gómez                                                                                                                                                                |
| 303 |    395.232452 |    595.932921 | Cathy                                                                                                                                                                                |
| 304 |    227.870331 |    616.416706 | Zimices                                                                                                                                                                              |
| 305 |     34.735011 |    202.652211 | Kamil S. Jaron                                                                                                                                                                       |
| 306 |    690.880110 |    208.957805 | NA                                                                                                                                                                                   |
| 307 |    324.661772 |    158.209168 | Michelle Site                                                                                                                                                                        |
| 308 |    567.940188 |    565.190586 | NA                                                                                                                                                                                   |
| 309 |    544.486796 |    121.104777 | Margot Michaud                                                                                                                                                                       |
| 310 |    528.394944 |    238.981685 | Matt Crook                                                                                                                                                                           |
| 311 |    906.175666 |    558.070620 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 312 |   1004.858162 |    583.559731 | Ferran Sayol                                                                                                                                                                         |
| 313 |    232.018998 |    725.631960 | Felix Vaux                                                                                                                                                                           |
| 314 |    444.293925 |    372.199724 | Steven Traver                                                                                                                                                                        |
| 315 |    787.860428 |    794.977439 | Steven Traver                                                                                                                                                                        |
| 316 |    483.212212 |    732.757181 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                                       |
| 317 |    696.789247 |    568.502933 | Zimices                                                                                                                                                                              |
| 318 |    523.408299 |    138.865307 | Zimices                                                                                                                                                                              |
| 319 |    390.574492 |    634.852234 | Zimices                                                                                                                                                                              |
| 320 |    350.979170 |    781.707147 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 321 |    512.507293 |    507.252918 | Zimices                                                                                                                                                                              |
| 322 |    895.324412 |    286.446287 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 323 |    372.256287 |    174.785936 | Ferran Sayol                                                                                                                                                                         |
| 324 |     11.514727 |    664.026634 | Terpsichores                                                                                                                                                                         |
| 325 |     69.831043 |    655.913528 | zoosnow                                                                                                                                                                              |
| 326 |    418.511059 |     27.010593 | Dantheman9758 (vectorized by T. Michael Keesey)                                                                                                                                      |
| 327 |    608.086452 |    558.111415 | T. Michael Keesey                                                                                                                                                                    |
| 328 |    237.035869 |    752.444810 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 329 |    431.229378 |    326.780831 | Gareth Monger                                                                                                                                                                        |
| 330 |    679.943117 |     98.525855 | Neil Kelley                                                                                                                                                                          |
| 331 |     34.177565 |    683.801684 | Jake Warner                                                                                                                                                                          |
| 332 |    905.971021 |    740.279478 | Armin Reindl                                                                                                                                                                         |
| 333 |    581.071165 |    473.259358 | Tauana J. Cunha                                                                                                                                                                      |
| 334 |    962.849734 |    793.584586 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 335 |     94.381196 |    214.868711 | Auckland Museum                                                                                                                                                                      |
| 336 |    663.605314 |    644.038111 | Scott Hartman                                                                                                                                                                        |
| 337 |     23.704572 |    212.161667 | Mathieu Basille                                                                                                                                                                      |
| 338 |    845.087579 |    427.548749 | Margot Michaud                                                                                                                                                                       |
| 339 |    729.165905 |    162.157315 | Jagged Fang Designs                                                                                                                                                                  |
| 340 |    443.279357 |    695.457733 | Margot Michaud                                                                                                                                                                       |
| 341 |    500.651489 |     88.599568 | Gareth Monger                                                                                                                                                                        |
| 342 |    518.403028 |    181.841599 | Jaime Headden                                                                                                                                                                        |
| 343 |    827.964614 |    383.817928 | Mali’o Kodis, photograph by Cordell Expeditions at Cal Academy                                                                                                                       |
| 344 |    462.816423 |     28.396728 | Chris huh                                                                                                                                                                            |
| 345 |    194.590179 |    726.258973 | Tyler Greenfield and Scott Hartman                                                                                                                                                   |
| 346 |    783.018056 |     19.061311 | Sergio A. Muñoz-Gómez                                                                                                                                                                |
| 347 |    202.885330 |    198.200501 | Maija Karala                                                                                                                                                                         |
| 348 |    853.990258 |    190.291854 | Jose Carlos Arenas-Monroy                                                                                                                                                            |
| 349 |     11.041215 |    559.059110 | Matt Martyniuk                                                                                                                                                                       |
| 350 |    555.231431 |    366.144528 | James R. Spotila and Ray Chatterji                                                                                                                                                   |
| 351 |    113.557279 |    788.090270 | Dean Schnabel                                                                                                                                                                        |
| 352 |     70.538185 |    553.576146 | T. Michael Keesey                                                                                                                                                                    |
| 353 |    407.550863 |    160.857746 | Xavier Giroux-Bougard                                                                                                                                                                |
| 354 |    950.516371 |     82.788665 | Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael Keesey)                                                                                               |
| 355 |    194.916337 |    122.737678 | Smokeybjb                                                                                                                                                                            |
| 356 |    274.791273 |    213.840492 | Andy Wilson                                                                                                                                                                          |
| 357 |    935.359562 |    796.496490 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 358 |    762.108174 |    126.281413 | T. Michael Keesey                                                                                                                                                                    |
| 359 |    489.979001 |    123.726665 | James R. Spotila and Ray Chatterji                                                                                                                                                   |
| 360 |    282.199491 |    522.385382 | Melissa Broussard                                                                                                                                                                    |
| 361 |    174.691514 |    624.972964 | Eyal Bartov                                                                                                                                                                          |
| 362 |    111.530160 |    569.410450 | Christoph Schomburg                                                                                                                                                                  |
| 363 |    934.367709 |    631.179686 | Noah Schlottman, photo by Reinhard Jahn                                                                                                                                              |
| 364 |    204.856784 |    219.331208 | Francesco Veronesi (vectorized by T. Michael Keesey)                                                                                                                                 |
| 365 |     28.443002 |    533.917410 | Ferran Sayol                                                                                                                                                                         |
| 366 |    236.135314 |    607.310915 | Tasman Dixon                                                                                                                                                                         |
| 367 |    404.704821 |    176.640684 | Steven Traver                                                                                                                                                                        |
| 368 |    478.244862 |    427.279947 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                                 |
| 369 |     48.344727 |    635.194261 | Alex Slavenko                                                                                                                                                                        |
| 370 |    297.941716 |     57.990707 | Mathilde Cordellier                                                                                                                                                                  |
| 371 |    913.363723 |    383.429997 | Zimices                                                                                                                                                                              |
| 372 |    972.297376 |    670.246679 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 373 |    600.249191 |    495.544212 | Fernando Campos De Domenico                                                                                                                                                          |
| 374 |    618.595751 |    134.439499 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 375 |    467.859064 |    714.958969 | FunkMonk                                                                                                                                                                             |
| 376 |    699.609924 |    454.080021 | Matt Crook                                                                                                                                                                           |
| 377 |    547.807154 |    505.396203 | Birgit Lang                                                                                                                                                                          |
| 378 |    843.820650 |    735.458995 | Matt Crook                                                                                                                                                                           |
| 379 |    749.426835 |    360.181244 | Christoph Schomburg                                                                                                                                                                  |
| 380 |    464.546311 |     63.446173 | Jessica Rick                                                                                                                                                                         |
| 381 |    264.646481 |    523.798406 | Andy Wilson                                                                                                                                                                          |
| 382 |    605.493389 |    251.575037 | Felix Vaux                                                                                                                                                                           |
| 383 |    873.892080 |     99.075162 | Zimices                                                                                                                                                                              |
| 384 |    450.411566 |    350.657651 | Rebecca Groom                                                                                                                                                                        |
| 385 |    354.745525 |    527.040180 | Zimices                                                                                                                                                                              |
| 386 |    272.852275 |     61.294390 | Matt Crook                                                                                                                                                                           |
| 387 |    369.719497 |    137.003777 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                                        |
| 388 |    411.043945 |    251.187148 | Zimices                                                                                                                                                                              |
| 389 |    675.197533 |     16.547063 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 390 |    396.919304 |    553.031534 | Margot Michaud                                                                                                                                                                       |
| 391 |    474.741905 |    302.485539 | Sarah Werning                                                                                                                                                                        |
| 392 |     69.598523 |    450.396462 | Ian Burt (original) and T. Michael Keesey (vectorization)                                                                                                                            |
| 393 |    499.671058 |     12.785407 | FunkMonk                                                                                                                                                                             |
| 394 |     63.593916 |    508.132057 | NA                                                                                                                                                                                   |
| 395 |    233.387932 |      5.971315 | Nobu Tamura                                                                                                                                                                          |
| 396 |    369.078790 |    294.243235 | Margot Michaud                                                                                                                                                                       |
| 397 |    563.127990 |    399.471056 | xgirouxb                                                                                                                                                                             |
| 398 |    864.895368 |    260.458481 | Erika Schumacher                                                                                                                                                                     |
| 399 |    983.425867 |    626.291631 | Dean Schnabel                                                                                                                                                                        |
| 400 |    919.697925 |    526.092197 | T. Michael Keesey                                                                                                                                                                    |
| 401 |     90.417935 |     61.919820 | Diana Pomeroy                                                                                                                                                                        |
| 402 |    489.874672 |    587.545306 | Birgit Lang                                                                                                                                                                          |
| 403 |    650.351950 |    151.682052 | Birgit Lang                                                                                                                                                                          |
| 404 |    280.995676 |     49.906797 | Ingo Braasch                                                                                                                                                                         |
| 405 |    655.480741 |    409.115462 | Tasman Dixon                                                                                                                                                                         |
| 406 |    482.695991 |    391.065143 | Steven Traver                                                                                                                                                                        |
| 407 |    751.493928 |    615.845414 | Steven Traver                                                                                                                                                                        |
| 408 |     12.566036 |    177.110960 | Zimices                                                                                                                                                                              |
| 409 |    492.369648 |    483.795534 | Scott Hartman                                                                                                                                                                        |
| 410 |    851.672419 |    623.607449 | NA                                                                                                                                                                                   |
| 411 |    883.304163 |    563.258934 | Matt Crook                                                                                                                                                                           |
| 412 |    454.134077 |     43.645302 | Margot Michaud                                                                                                                                                                       |
| 413 |    980.433623 |    604.914116 | Benjamint444                                                                                                                                                                         |
| 414 |    305.904505 |    515.020980 | Matt Crook                                                                                                                                                                           |
| 415 |    879.652705 |    370.624485 | Erika Schumacher                                                                                                                                                                     |
| 416 |    723.677308 |      7.029207 | Scott Hartman                                                                                                                                                                        |
| 417 |    214.605097 |    568.770264 | Rebecca Groom                                                                                                                                                                        |
| 418 |    514.624575 |    677.594853 | Zimices                                                                                                                                                                              |
| 419 |    174.637932 |    508.414526 | Collin Gross                                                                                                                                                                         |
| 420 |    978.342387 |    391.728059 | Margot Michaud                                                                                                                                                                       |
| 421 |   1001.126064 |    477.961848 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 422 |     16.229002 |    534.486354 | Matt Crook                                                                                                                                                                           |
| 423 |    772.594578 |    553.092884 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 424 |    948.749510 |     87.899737 | Markus A. Grohme                                                                                                                                                                     |
| 425 |     17.410212 |    579.735709 | Bruno Maggia                                                                                                                                                                         |
| 426 |    698.961450 |    630.393563 | Zimices                                                                                                                                                                              |
| 427 |     31.985042 |    177.962803 | Zimices                                                                                                                                                                              |
| 428 |     14.565995 |    543.981697 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 429 |    232.039626 |    211.981962 | Sergio A. Muñoz-Gómez                                                                                                                                                                |
| 430 |     95.245284 |    716.585066 | Mathieu Pélissié                                                                                                                                                                     |
| 431 |    670.100872 |     90.873694 | Eric Moody                                                                                                                                                                           |
| 432 |    372.071893 |     81.128860 | Markus A. Grohme                                                                                                                                                                     |
| 433 |    622.098951 |    573.201140 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 434 |    576.042440 |    553.530879 | Markus A. Grohme                                                                                                                                                                     |
| 435 |    970.337946 |    534.025595 | Margot Michaud                                                                                                                                                                       |
| 436 |    378.270827 |      8.057736 | Mali’o Kodis, photograph by Melissa Frey                                                                                                                                             |
| 437 |    882.525521 |    268.353349 | Margot Michaud                                                                                                                                                                       |
| 438 |    791.317492 |    715.599818 | NA                                                                                                                                                                                   |
| 439 |    206.450725 |    182.111152 | Crystal Maier                                                                                                                                                                        |
| 440 |    184.414825 |    159.506098 | Matt Crook                                                                                                                                                                           |
| 441 |    255.477739 |    515.764787 | Mali’o Kodis, photograph by Ching (<http://www.flickr.com/photos/36302473@N03/>)                                                                                                     |
| 442 |    549.662495 |    131.350050 | Matt Crook                                                                                                                                                                           |
| 443 |    709.563256 |    796.512945 | Caleb M. Brown                                                                                                                                                                       |
| 444 |    576.095452 |    537.468985 | Chris huh                                                                                                                                                                            |
| 445 |    758.447523 |    696.783234 | Margot Michaud                                                                                                                                                                       |
| 446 |    217.695179 |    333.249263 | Zimices                                                                                                                                                                              |
| 447 |    721.110159 |    625.288567 | Matt Crook                                                                                                                                                                           |
| 448 |    997.737037 |    349.374229 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                                                        |
| 449 |    330.857868 |    767.273068 | Matt Crook                                                                                                                                                                           |
| 450 |    149.862452 |     83.608540 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 451 |    162.726691 |    100.450767 | Gareth Monger                                                                                                                                                                        |
| 452 |    473.556573 |    383.475834 | Ferran Sayol                                                                                                                                                                         |
| 453 |    632.042088 |    547.810397 | Zimices                                                                                                                                                                              |
| 454 |     87.225677 |    728.138972 | Scott Hartman                                                                                                                                                                        |
| 455 |    725.035039 |    744.156637 | NA                                                                                                                                                                                   |
| 456 |    985.756957 |    491.786711 | Scott Hartman                                                                                                                                                                        |
| 457 |    612.117495 |    753.469309 | Yan Wong                                                                                                                                                                             |
| 458 |    458.749562 |    137.103870 | Margot Michaud                                                                                                                                                                       |
| 459 |    931.893825 |      6.585442 | Zsoldos Márton (vectorized by T. Michael Keesey)                                                                                                                                     |
| 460 |    568.998285 |    423.614066 | FunkMonk                                                                                                                                                                             |
| 461 |    366.775241 |    569.644228 | Birgit Lang                                                                                                                                                                          |
| 462 |    442.050730 |    590.818898 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 463 |    480.511557 |    541.374128 | Katie S. Collins                                                                                                                                                                     |
| 464 |    972.598459 |    374.565358 | NA                                                                                                                                                                                   |
| 465 |    374.701715 |     44.123250 | Conty (vectorized by T. Michael Keesey)                                                                                                                                              |
| 466 |    664.737384 |    670.557968 | Chris huh                                                                                                                                                                            |
| 467 |    710.554550 |    257.204335 | Christoph Schomburg                                                                                                                                                                  |
| 468 |     90.010176 |    232.373700 | Gareth Monger                                                                                                                                                                        |
| 469 |    816.071856 |    661.471509 | NA                                                                                                                                                                                   |
| 470 |    941.132989 |    414.026468 | Mali’o Kodis, image from the Smithsonian Institution                                                                                                                                 |
| 471 |    140.876664 |     34.113172 | Margot Michaud                                                                                                                                                                       |
| 472 |     26.794516 |     38.017300 | Griensteidl and T. Michael Keesey                                                                                                                                                    |
| 473 |    887.526910 |    716.594603 | Joanna Wolfe                                                                                                                                                                         |
| 474 |    800.508854 |    663.510077 | Dean Schnabel                                                                                                                                                                        |
| 475 |    187.625423 |     22.570908 | Margot Michaud                                                                                                                                                                       |
| 476 |    598.324168 |    298.950815 | Matt Crook                                                                                                                                                                           |
| 477 |    628.206533 |    159.094394 | Zimices                                                                                                                                                                              |
| 478 |    569.764931 |    147.729526 | T. Michael Keesey (vectorization) and Nadiatalent (photography)                                                                                                                      |
| 479 |    262.277207 |     12.289986 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                                   |
| 480 |    421.531096 |    154.292024 | Matt Crook                                                                                                                                                                           |
| 481 |    855.076854 |    559.721774 | Zimices                                                                                                                                                                              |
| 482 |    594.543066 |    222.748684 | Tasman Dixon                                                                                                                                                                         |
| 483 |    374.114585 |     22.905511 | Steven Traver                                                                                                                                                                        |
| 484 |    787.530931 |    390.062387 | Mali’o Kodis, image from the Smithsonian Institution                                                                                                                                 |
| 485 |    497.297385 |    395.651995 | L. Shyamal                                                                                                                                                                           |
| 486 |    905.868976 |    352.269427 | Scott Hartman                                                                                                                                                                        |
| 487 |    293.248674 |    131.007037 | Kamil S. Jaron                                                                                                                                                                       |
| 488 |    224.173825 |    601.355512 | Gareth Monger                                                                                                                                                                        |
| 489 |    686.007682 |    262.073797 | www.studiospectre.com                                                                                                                                                                |
| 490 |    821.311344 |     43.050413 | Matt Wilkins (photo by Patrick Kavanagh)                                                                                                                                             |
| 491 |    371.804054 |    543.863700 | Michelle Site                                                                                                                                                                        |
| 492 |   1003.788688 |     22.359037 | Matt Martyniuk                                                                                                                                                                       |
| 493 |     17.308533 |    146.852945 | Zimices                                                                                                                                                                              |
| 494 |    659.528134 |    572.373427 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 495 |    781.115797 |    363.498470 | Mark Witton                                                                                                                                                                          |
| 496 |    970.634533 |    680.481531 | Jagged Fang Designs                                                                                                                                                                  |
| 497 |    571.871032 |    587.905668 | NA                                                                                                                                                                                   |
| 498 |    500.459377 |     36.574658 | Zimices                                                                                                                                                                              |
| 499 |    348.778631 |     16.710686 | Margot Michaud                                                                                                                                                                       |
| 500 |    245.334088 |    530.332154 | Matt Crook                                                                                                                                                                           |
| 501 |     44.788446 |    186.317083 | Matt Crook                                                                                                                                                                           |
| 502 |    264.712198 |    735.768118 | Michelle Site                                                                                                                                                                        |
| 503 |    596.522311 |    550.146351 | Steven Traver                                                                                                                                                                        |
| 504 |    183.220464 |    695.192420 | Matt Crook                                                                                                                                                                           |
| 505 |    920.597526 |    268.661778 | Chris Hay                                                                                                                                                                            |
| 506 |    142.802544 |    722.009982 | Ferran Sayol                                                                                                                                                                         |
| 507 |    424.767528 |    137.383952 | Felix Vaux                                                                                                                                                                           |
| 508 |    620.267593 |    286.603033 | Michelle Site                                                                                                                                                                        |
| 509 |    215.460997 |    577.458384 | NA                                                                                                                                                                                   |
| 510 |     20.519457 |    438.688968 | Jagged Fang Designs                                                                                                                                                                  |
| 511 |    648.806920 |     51.978219 | Matt Crook                                                                                                                                                                           |
| 512 |    628.100499 |    148.678180 | Margot Michaud                                                                                                                                                                       |
| 513 |    657.600793 |    639.877981 | Matt Crook                                                                                                                                                                           |
| 514 |    138.019072 |    530.407775 | Andy Wilson                                                                                                                                                                          |
| 515 |    118.039635 |     78.870535 | Taro Maeda                                                                                                                                                                           |
| 516 |    676.055738 |    423.589720 | Becky Barnes                                                                                                                                                                         |
| 517 |    295.310868 |    628.192160 | Matt Crook                                                                                                                                                                           |
| 518 |    658.319957 |     64.756588 | Joedison Rocha                                                                                                                                                                       |
| 519 |    884.346638 |    152.400398 | Andy Wilson                                                                                                                                                                          |
| 520 |    811.498964 |    447.844531 | Sergio A. Muñoz-Gómez                                                                                                                                                                |
| 521 |    660.847089 |    510.045384 | T. Michael Keesey (vectorization) and Larry Loos (photography)                                                                                                                       |
| 522 |    792.522332 |    492.396888 | Zimices                                                                                                                                                                              |
| 523 |    825.431017 |    474.766432 | Steven Coombs (vectorized by T. Michael Keesey)                                                                                                                                      |
| 524 |    867.162450 |    689.872103 | Scott Hartman                                                                                                                                                                        |
| 525 |    407.493159 |    188.407163 | Dean Schnabel                                                                                                                                                                        |
| 526 |    328.833342 |    685.803032 | Zimices                                                                                                                                                                              |
| 527 |    291.690553 |     93.314067 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 528 |    327.691838 |    661.654665 | Margot Michaud                                                                                                                                                                       |
| 529 |    414.333001 |     11.142757 | Andy Wilson                                                                                                                                                                          |
| 530 |    621.693342 |    196.321040 | SecretJellyMan - from Mason McNair                                                                                                                                                   |
| 531 |    810.105357 |    135.181939 | Melissa Broussard                                                                                                                                                                    |
| 532 |    374.383189 |    447.450003 | Zimices                                                                                                                                                                              |
| 533 |    387.670219 |    788.899684 | Zimices                                                                                                                                                                              |
| 534 |    165.326732 |    117.588462 | Zimices                                                                                                                                                                              |
| 535 |    306.692107 |    617.170538 | Conty (vectorized by T. Michael Keesey)                                                                                                                                              |
| 536 |    277.957791 |    283.165829 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 537 |    106.474685 |    645.105249 | NA                                                                                                                                                                                   |
| 538 |    444.351427 |     52.837628 | Felix Vaux                                                                                                                                                                           |
| 539 |    463.149736 |     13.431231 | Pete Buchholz                                                                                                                                                                        |
| 540 |    381.031927 |    589.828987 | Tyler Greenfield                                                                                                                                                                     |
| 541 |    477.339632 |    362.541274 | Michelle Site                                                                                                                                                                        |
| 542 |    135.602214 |    219.170408 | Birgit Lang, based on a photo by D. Sikes                                                                                                                                            |
| 543 |   1000.144498 |    658.719275 | Matt Crook                                                                                                                                                                           |
| 544 |    647.590699 |    640.943951 | Nancy Wyman (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                          |
| 545 |    280.177761 |    511.050011 | Cesar Julian                                                                                                                                                                         |
| 546 |    885.659917 |    496.873321 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 547 |    932.378946 |     88.389937 | Tracy A. Heath                                                                                                                                                                       |
| 548 |     61.820039 |    774.147885 | Joschua Knüppe                                                                                                                                                                       |
| 549 |    648.832343 |     20.588248 | Matt Crook                                                                                                                                                                           |
| 550 |    900.091243 |    683.117666 | Margot Michaud                                                                                                                                                                       |
| 551 |     35.760301 |    795.409574 | Nicholas J. Czaplewski, vectorized by Zimices                                                                                                                                        |
| 552 |    726.453550 |    540.927929 | Dinah Challen                                                                                                                                                                        |
| 553 |    390.967107 |    463.909375 | Matt Crook                                                                                                                                                                           |
| 554 |    498.745408 |    376.821822 | Tauana J. Cunha                                                                                                                                                                      |
| 555 |    900.837052 |    179.257603 | Matt Crook                                                                                                                                                                           |
| 556 |    338.274605 |     16.228560 | Mali’o Kodis, photograph by John Slapcinsky                                                                                                                                          |
| 557 |    283.530067 |    786.248817 | Birgit Lang                                                                                                                                                                          |
| 558 |    146.771061 |    466.676820 | Gareth Monger                                                                                                                                                                        |
| 559 |    663.262184 |    764.981811 | Armin Reindl                                                                                                                                                                         |
| 560 |     89.385578 |    565.383032 | NA                                                                                                                                                                                   |
| 561 |    821.280169 |    455.988502 | Ferran Sayol                                                                                                                                                                         |
| 562 |    985.672412 |    456.126733 | Catherine Yasuda                                                                                                                                                                     |
| 563 |    535.950340 |    210.267362 | Mason McNair                                                                                                                                                                         |
| 564 |    498.695732 |    794.682476 | Zimices                                                                                                                                                                              |
| 565 |    375.680383 |    792.743299 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 566 |    871.013696 |    161.338260 | Ludwik Gąsiorowski                                                                                                                                                                   |
| 567 |    369.829218 |    779.524219 | Jakovche                                                                                                                                                                             |
| 568 |     18.770417 |    367.562667 | Matus Valach                                                                                                                                                                         |
| 569 |    747.650033 |    458.536266 | Tasman Dixon                                                                                                                                                                         |
| 570 |    439.882497 |    357.539112 | Anthony Caravaggi                                                                                                                                                                    |
| 571 |    133.797379 |     13.806327 | Michelle Site                                                                                                                                                                        |
| 572 |    163.826477 |     22.250167 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 573 |    807.120194 |     81.770803 | NA                                                                                                                                                                                   |
| 574 |    284.667133 |     81.076236 | Markus A. Grohme                                                                                                                                                                     |
| 575 |     74.231396 |     30.961478 | Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael Keesey)                                                                                               |
| 576 |    220.675242 |    762.507337 | Dave Angelini                                                                                                                                                                        |
| 577 |    696.897424 |     28.625742 | Berivan Temiz                                                                                                                                                                        |
| 578 |   1003.598194 |    212.421519 | Sarah Werning                                                                                                                                                                        |
| 579 |    334.399906 |    163.260745 | Henry Lydecker                                                                                                                                                                       |
| 580 |    516.950854 |    229.242123 | C. W. Nash (illustration) and Timothy J. Bartley (silhouette)                                                                                                                        |
| 581 |    498.727583 |    116.472212 | Steven Traver                                                                                                                                                                        |
| 582 |    285.571443 |    340.310298 | Beth Reinke                                                                                                                                                                          |
| 583 |    667.996875 |    445.753801 | Andrew A. Farke                                                                                                                                                                      |
| 584 |    285.971937 |    488.148634 | T. Michael Keesey                                                                                                                                                                    |
| 585 |    597.333154 |    588.364873 | T. Michael Keesey (vectorization) and HuttyMcphoo (photography)                                                                                                                      |
| 586 |    403.828850 |    589.824924 | Mali’o Kodis, photograph by P. Funch and R.M. Kristensen                                                                                                                             |
| 587 |    764.140854 |    145.541548 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 588 |     34.423567 |    766.303534 | M Hutchinson                                                                                                                                                                         |
| 589 |    341.575592 |    572.926782 | Myriam\_Ramirez                                                                                                                                                                      |
| 590 |    569.136718 |    359.065653 | Yan Wong from illustration by Charles Orbigny                                                                                                                                        |
| 591 |    758.270932 |    713.822179 | Jimmy Bernot                                                                                                                                                                         |
| 592 |     90.703641 |    404.872261 | Zimices                                                                                                                                                                              |
| 593 |     92.430288 |    777.827299 | Oscar Sanisidro                                                                                                                                                                      |
| 594 |    956.276012 |    185.532165 | Gareth Monger                                                                                                                                                                        |
| 595 |    647.172784 |    741.948470 | Margot Michaud                                                                                                                                                                       |
| 596 |    649.872894 |     80.957635 | Margot Michaud                                                                                                                                                                       |
| 597 |    511.537704 |    119.774565 | Karla Martinez                                                                                                                                                                       |
| 598 |    729.904043 |    682.311308 | Oliver Griffith                                                                                                                                                                      |
| 599 |    794.358975 |    103.756933 | L. Shyamal                                                                                                                                                                           |
| 600 |    738.230275 |    210.431621 | Matt Crook                                                                                                                                                                           |
| 601 |      7.148701 |    192.367375 | Anthony Caravaggi                                                                                                                                                                    |
| 602 |   1003.509795 |    492.792450 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                                     |
| 603 |     50.870870 |      5.567140 | Steven Traver                                                                                                                                                                        |
| 604 |    579.957612 |    572.486864 | Matt Crook                                                                                                                                                                           |
| 605 |    827.427963 |    348.410396 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                                     |
| 606 |    673.878132 |    437.904102 | Andrew A. Farke                                                                                                                                                                      |
| 607 |    479.051130 |     39.398239 | Ferran Sayol                                                                                                                                                                         |
| 608 |    161.223052 |    239.846093 | Ignacio Contreras                                                                                                                                                                    |
| 609 |    485.433795 |    368.442996 | Andy Wilson                                                                                                                                                                          |
| 610 |     27.891534 |    167.268793 | Jagged Fang Designs                                                                                                                                                                  |
| 611 |    215.521191 |    624.893844 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 612 |    819.229168 |    266.139546 | Lip Kee Yap (vectorized by T. Michael Keesey)                                                                                                                                        |
| 613 |     49.457673 |    224.713577 | Matt Crook                                                                                                                                                                           |
| 614 |    114.315877 |      3.075077 | Scott Hartman                                                                                                                                                                        |
| 615 |    316.572349 |    145.390735 | T. Michael Keesey                                                                                                                                                                    |
| 616 |    478.663052 |    533.120291 | CNZdenek                                                                                                                                                                             |
| 617 |    565.461966 |    413.745876 | Nobu Tamura                                                                                                                                                                          |
| 618 |    601.144148 |    771.596556 | NA                                                                                                                                                                                   |
| 619 |    346.976364 |    338.628249 | Frank Förster                                                                                                                                                                        |
| 620 |    458.388897 |    307.017877 | Gareth Monger                                                                                                                                                                        |
| 621 |    530.234873 |    128.490322 | NA                                                                                                                                                                                   |
| 622 |     10.399460 |    254.354528 | Ignacio Contreras                                                                                                                                                                    |
| 623 |    403.411885 |    127.098457 | Matt Crook                                                                                                                                                                           |
| 624 |    401.004685 |    614.232019 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                                     |
| 625 |    793.078981 |    550.953138 | Sergio A. Muñoz-Gómez                                                                                                                                                                |
| 626 |    207.631283 |    164.622236 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 627 |    967.146553 |    425.984774 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 628 |     50.858969 |    557.240315 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 629 |     54.643656 |    721.117875 | Gabriel Lio, vectorized by Zimices                                                                                                                                                   |
| 630 |    395.495950 |    331.446112 | Michael Scroggie                                                                                                                                                                     |
| 631 |    245.699721 |    144.295096 | Roberto Diaz Sibaja, based on Domser                                                                                                                                                 |
| 632 |    701.797698 |    515.785939 | Chris huh                                                                                                                                                                            |
| 633 |      9.401794 |    449.379905 | Matt Crook                                                                                                                                                                           |
| 634 |    937.894981 |    731.455159 | Scott Hartman                                                                                                                                                                        |
| 635 |    996.159004 |    679.880517 | Margot Michaud                                                                                                                                                                       |
| 636 |    629.255702 |    755.365325 | NA                                                                                                                                                                                   |
| 637 |    674.430533 |    781.102151 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 638 |    966.612769 |    363.333309 | Neil Kelley                                                                                                                                                                          |
| 639 |    939.127238 |    718.918791 | Iain Reid                                                                                                                                                                            |
| 640 |    358.731368 |    457.943632 | Smokeybjb                                                                                                                                                                            |
| 641 |    538.221224 |    321.463839 | Andrew R. Gehrke                                                                                                                                                                     |
| 642 |    626.740261 |    782.777480 | Robert Hering                                                                                                                                                                        |
| 643 |    676.454071 |    517.081536 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 644 |    391.474811 |    645.241884 | Chris huh                                                                                                                                                                            |
| 645 |    475.215306 |    144.772919 | Margot Michaud                                                                                                                                                                       |
| 646 |     37.880043 |    376.081222 | Erika Schumacher                                                                                                                                                                     |
| 647 |    464.264636 |    290.951077 | Ignacio Contreras                                                                                                                                                                    |
| 648 |    215.198457 |    228.523042 | Collin Gross                                                                                                                                                                         |
| 649 |    633.240761 |    134.313282 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 650 |    384.897789 |     52.773703 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 651 |    327.208888 |    125.622464 | Christoph Schomburg                                                                                                                                                                  |
| 652 |   1001.636129 |    554.421976 | Gareth Monger                                                                                                                                                                        |
| 653 |    848.799979 |    701.939007 | Maija Karala                                                                                                                                                                         |
| 654 |    929.606134 |    582.321029 | Mathew Wedel                                                                                                                                                                         |
| 655 |    889.883234 |     97.226186 | Steven Traver                                                                                                                                                                        |
| 656 |    452.537656 |    148.152062 | Chris huh                                                                                                                                                                            |
| 657 |    865.711479 |    631.319851 | Margot Michaud                                                                                                                                                                       |
| 658 |    185.251136 |    685.778679 | Chris huh                                                                                                                                                                            |
| 659 |     34.146351 |    751.530268 | Matt Martyniuk                                                                                                                                                                       |
| 660 |    159.875435 |    470.765830 | Matt Crook                                                                                                                                                                           |
| 661 |     75.197664 |    788.823892 | FunkMonk                                                                                                                                                                             |
| 662 |    933.170381 |     34.370923 | Harold N Eyster                                                                                                                                                                      |
| 663 |    427.477142 |     15.192085 | Michelle Site                                                                                                                                                                        |
| 664 |    894.120685 |    737.389777 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 665 |    440.646020 |     37.335198 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 666 |    241.669089 |    632.550843 | NA                                                                                                                                                                                   |
| 667 |    687.729683 |    623.998132 | Saguaro Pictures (source photo) and T. Michael Keesey                                                                                                                                |
| 668 |    238.271444 |    328.770628 | Zimices                                                                                                                                                                              |
| 669 |    425.042680 |    201.012241 | C. Abraczinskas                                                                                                                                                                      |
| 670 |    289.999116 |    505.931233 | Steven Coombs                                                                                                                                                                        |
| 671 |    655.311561 |    106.195221 | Michelle Site                                                                                                                                                                        |
| 672 |    932.530538 |    524.869869 | Gareth Monger                                                                                                                                                                        |
| 673 |    982.826871 |    499.623788 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 674 |    529.564751 |    200.088372 | Jaime Headden, modified by T. Michael Keesey                                                                                                                                         |
| 675 |    488.675735 |    759.251401 | NA                                                                                                                                                                                   |
| 676 |    643.558404 |    364.980115 | Lukasiniho                                                                                                                                                                           |
| 677 |    811.121594 |    116.425122 | Gareth Monger                                                                                                                                                                        |
| 678 |    212.856937 |    592.643999 | NA                                                                                                                                                                                   |
| 679 |    355.813931 |    556.183133 | Kai R. Caspar                                                                                                                                                                        |
| 680 |    196.523903 |    714.349748 | Juan Carlos Jerí                                                                                                                                                                     |
| 681 |    636.416470 |    572.130480 | JCGiron                                                                                                                                                                              |
| 682 |    335.011482 |    597.839808 | Mason McNair                                                                                                                                                                         |
| 683 |    842.061088 |    131.102674 | T. Michael Keesey                                                                                                                                                                    |
| 684 |      9.964586 |    486.194854 | Doug Backlund (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                        |
| 685 |     26.096351 |    647.936987 | Martin Kevil                                                                                                                                                                         |
| 686 |    517.887507 |    649.292906 | Manabu Sakamoto                                                                                                                                                                      |
| 687 |    274.851813 |    613.353960 | NA                                                                                                                                                                                   |
| 688 |    585.230309 |    235.878363 | terngirl                                                                                                                                                                             |
| 689 |    202.157584 |    100.736552 | Jagged Fang Designs                                                                                                                                                                  |
| 690 |    480.275286 |    135.293233 | Chuanixn Yu                                                                                                                                                                          |
| 691 |    783.044028 |    375.776091 | Nobu Tamura                                                                                                                                                                          |
| 692 |    779.412008 |    159.090181 | Philippe Janvier (vectorized by T. Michael Keesey)                                                                                                                                   |
| 693 |    227.388262 |    319.883648 | Zimices                                                                                                                                                                              |
| 694 |    246.258030 |    726.634292 | Tasman Dixon                                                                                                                                                                         |
| 695 |    294.716359 |     36.230267 | Auckland Museum and T. Michael Keesey                                                                                                                                                |
| 696 |    907.741427 |     10.088694 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 697 |     18.452013 |    749.043382 | Ferran Sayol                                                                                                                                                                         |
| 698 |    460.200087 |      2.448457 | Scott Hartman                                                                                                                                                                        |
| 699 |    720.998064 |    612.229584 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 700 |    364.759194 |    637.986616 | Chris huh                                                                                                                                                                            |
| 701 |    171.194940 |    638.627199 | Margot Michaud                                                                                                                                                                       |
| 702 |    982.133109 |    370.690444 | NA                                                                                                                                                                                   |
| 703 |    670.758656 |    679.895027 | Mariana Ruiz Villarreal (modified by T. Michael Keesey)                                                                                                                              |
| 704 |    945.748318 |    155.272115 | Jagged Fang Designs                                                                                                                                                                  |
| 705 |    876.129067 |    451.964917 | Ieuan Jones                                                                                                                                                                          |
| 706 |    383.033795 |    169.247908 | Scott Hartman                                                                                                                                                                        |
| 707 |    982.071117 |    731.687564 | Вальдимар (vectorized by T. Michael Keesey)                                                                                                                                          |
| 708 |    155.250056 |    531.544436 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 709 |    918.011165 |     33.541488 | Dennis C. Murphy, after <https://commons.wikimedia.org/wiki/File:Queensland_State_Archives_2981_Cane_toads_at_the_Meringa_Sugar_Experiment_Station_North_Queensland_c_1935.png>      |
| 710 |    218.096355 |     76.778225 | V. Deepak                                                                                                                                                                            |
| 711 |     87.580277 |     49.293411 | Matt Crook                                                                                                                                                                           |
| 712 |    326.316153 |    637.974680 | NA                                                                                                                                                                                   |
| 713 |    592.770029 |    486.073394 | Jagged Fang Designs                                                                                                                                                                  |
| 714 |    908.923652 |    374.426185 | Tommaso Cancellario                                                                                                                                                                  |
| 715 |   1006.623401 |    546.719260 | Mattia Menchetti / Yan Wong                                                                                                                                                          |
| 716 |    524.216744 |    636.526198 | Ingo Braasch                                                                                                                                                                         |
| 717 |    899.217599 |    754.120726 | T. Michael Keesey (after Mauricio Antón)                                                                                                                                             |
| 718 |    334.440030 |    171.445564 | Melissa Broussard                                                                                                                                                                    |
| 719 |    765.877173 |    641.374184 | Ignacio Contreras                                                                                                                                                                    |
| 720 |    413.391131 |    240.268286 | Ferran Sayol                                                                                                                                                                         |
| 721 |    151.696502 |     56.850629 | Zimices                                                                                                                                                                              |
| 722 |    807.253118 |    510.908484 | Tyler Greenfield                                                                                                                                                                     |
| 723 |    707.875685 |     10.953657 | Matt Crook                                                                                                                                                                           |
| 724 |    477.575566 |    749.734612 | Mo Hassan                                                                                                                                                                            |
| 725 |    229.928215 |    570.435063 | Zimices                                                                                                                                                                              |
| 726 |    662.709257 |     19.874170 | Mathieu Pélissié                                                                                                                                                                     |
| 727 |    632.409978 |    275.383757 | Michelle Site                                                                                                                                                                        |
| 728 |     73.317219 |     46.326322 | Birgit Lang                                                                                                                                                                          |
| 729 |    548.137716 |    171.401369 | Margot Michaud                                                                                                                                                                       |
| 730 |    730.329295 |    526.364222 | Matt Crook                                                                                                                                                                           |
| 731 |    889.193387 |    160.341572 | Zimices                                                                                                                                                                              |
| 732 |     12.393579 |     82.811852 | Jimmy Bernot                                                                                                                                                                         |
| 733 |    810.518660 |    671.464900 | NA                                                                                                                                                                                   |
| 734 |    642.412487 |    788.046713 | Matt Dempsey                                                                                                                                                                         |
| 735 |    144.042578 |    294.878751 | NA                                                                                                                                                                                   |
| 736 |    316.505234 |     13.514576 | T. Tischler                                                                                                                                                                          |
| 737 |    276.588214 |    244.349598 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                                     |
| 738 |    542.488211 |    598.163310 | NA                                                                                                                                                                                   |
| 739 |    976.530190 |    219.646245 | Steven Traver                                                                                                                                                                        |
| 740 |    260.537657 |    752.764890 | Pedro de Siracusa                                                                                                                                                                    |
| 741 |     60.360259 |    201.607026 | Christoph Schomburg                                                                                                                                                                  |
| 742 |     79.248297 |      8.942619 | Birgit Lang                                                                                                                                                                          |
| 743 |    404.945195 |    140.564445 | Isaure Scavezzoni                                                                                                                                                                    |
| 744 |    644.040395 |     38.298229 | Charles Doolittle Walcott (vectorized by T. Michael Keesey)                                                                                                                          |
| 745 |    494.715114 |    508.326309 | Margot Michaud                                                                                                                                                                       |
| 746 |    998.904560 |    796.660743 | Markus A. Grohme                                                                                                                                                                     |
| 747 |    928.546668 |     63.770209 | Jordan Mallon (vectorized by T. Michael Keesey)                                                                                                                                      |
| 748 |    207.146408 |    762.882096 | Lukasiniho                                                                                                                                                                           |
| 749 |    382.224876 |    554.866350 | Maija Karala                                                                                                                                                                         |
| 750 |    585.600241 |    382.301097 | Sarah Werning                                                                                                                                                                        |
| 751 |    750.352565 |    447.103958 | Matt Crook                                                                                                                                                                           |
| 752 |    974.135272 |     82.817862 | E. Lear, 1819 (vectorization by Yan Wong)                                                                                                                                            |
| 753 |     83.308724 |    666.103967 | Davidson Sodré                                                                                                                                                                       |
| 754 |    891.464436 |    363.529139 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                                     |
| 755 |    563.811381 |    504.791876 | M Hutchinson                                                                                                                                                                         |
| 756 |    629.177332 |    713.661323 | Yan Wong from drawing by T. F. Zimmermann                                                                                                                                            |
| 757 |    153.592349 |    501.638782 | Steven Traver                                                                                                                                                                        |
| 758 |   1016.136780 |    595.351849 | Joe Schneid (vectorized by T. Michael Keesey)                                                                                                                                        |
| 759 |    440.942451 |     12.766061 | Matt Crook                                                                                                                                                                           |
| 760 |    533.512268 |    681.806402 | Maija Karala                                                                                                                                                                         |
| 761 |    646.964317 |    115.892844 | Sarah Werning                                                                                                                                                                        |
| 762 |    800.923331 |    746.105689 | Matt Crook                                                                                                                                                                           |
| 763 |    965.543870 |     68.735009 | Jagged Fang Designs                                                                                                                                                                  |
| 764 |    564.184754 |    290.799441 | Chris huh                                                                                                                                                                            |
| 765 |   1014.249994 |    662.995604 | Steven Traver                                                                                                                                                                        |
| 766 |    101.735383 |    444.038547 | Steven Traver                                                                                                                                                                        |
| 767 |    924.016156 |    513.898778 | Beth Reinke                                                                                                                                                                          |
| 768 |    900.716579 |    596.061762 | Joanna Wolfe                                                                                                                                                                         |
| 769 |    606.355508 |    491.530835 | Christoph Schomburg                                                                                                                                                                  |
| 770 |    773.918186 |    224.770931 | Margot Michaud                                                                                                                                                                       |
| 771 |     14.540796 |    589.740881 | Jonathan Wells                                                                                                                                                                       |
| 772 |    531.757583 |    221.435988 | Arthur Weasley (vectorized by T. Michael Keesey)                                                                                                                                     |
| 773 |    920.348589 |    792.052019 | Sarah Werning                                                                                                                                                                        |
| 774 |    975.907120 |    589.616123 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                                    |
| 775 |    489.897285 |     78.746827 | CNZdenek                                                                                                                                                                             |
| 776 |    682.594523 |    643.589352 | Gareth Monger                                                                                                                                                                        |
| 777 |     13.675890 |    404.854428 | Zimices                                                                                                                                                                              |
| 778 |    680.457669 |    172.403155 | Owen Jones                                                                                                                                                                           |
| 779 |    183.538845 |    100.635896 | Matt Crook                                                                                                                                                                           |
| 780 |    516.743998 |    155.321689 | Andy Wilson                                                                                                                                                                          |
| 781 |    793.144286 |     52.913568 | Ian Burt (original) and T. Michael Keesey (vectorization)                                                                                                                            |
| 782 |    170.476393 |    454.935988 | Andy Wilson                                                                                                                                                                          |
| 783 |     89.918140 |     28.732157 | Francesca Belem Lopes Palmeira                                                                                                                                                       |
| 784 |    742.521520 |    743.298161 | Armin Reindl                                                                                                                                                                         |
| 785 |    582.504492 |    141.828907 | Mercedes Yrayzoz (vectorized by T. Michael Keesey)                                                                                                                                   |
| 786 |    187.060283 |    660.294958 | Joanna Wolfe                                                                                                                                                                         |
| 787 |    148.574458 |    304.182214 | Margot Michaud                                                                                                                                                                       |
| 788 |    670.837188 |    458.218599 | Tasman Dixon                                                                                                                                                                         |
| 789 |    322.164605 |    703.199454 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 790 |   1017.775367 |    122.165951 | NA                                                                                                                                                                                   |
| 791 |    292.175287 |    245.525231 | Marmelad                                                                                                                                                                             |
| 792 |    589.072308 |    655.227012 | James R. Spotila and Ray Chatterji                                                                                                                                                   |
| 793 |    448.615241 |    497.473326 | Kelly                                                                                                                                                                                |
| 794 |    216.088211 |    256.178989 | T. Michael Keesey                                                                                                                                                                    |
| 795 |   1017.639286 |      9.915573 | Michael Scroggie                                                                                                                                                                     |
| 796 |    179.036014 |    329.997891 | NA                                                                                                                                                                                   |
| 797 |    276.571201 |    236.966390 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 798 |    871.605064 |    171.804464 | Matt Crook                                                                                                                                                                           |
| 799 |    967.371533 |    584.044401 | david maas / dave hone                                                                                                                                                               |
| 800 |    182.464669 |    710.075218 | Steven Traver                                                                                                                                                                        |
| 801 |     11.951631 |    686.856259 | T. Michael Keesey                                                                                                                                                                    |
| 802 |    537.684135 |    782.564494 | Matt Crook                                                                                                                                                                           |
| 803 |    721.444677 |     38.069872 | T. Michael Keesey                                                                                                                                                                    |
| 804 |    317.124506 |    647.591946 | NA                                                                                                                                                                                   |
| 805 |    774.730746 |    717.299326 | Maha Ghazal                                                                                                                                                                          |
| 806 |      8.928249 |    758.583960 | Ferran Sayol                                                                                                                                                                         |
| 807 |    708.674299 |    604.048628 | Philippe Janvier (vectorized by T. Michael Keesey)                                                                                                                                   |
| 808 |    848.243729 |    442.465133 | NA                                                                                                                                                                                   |
| 809 |    662.170291 |    696.195626 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey)                |
| 810 |    663.199528 |    488.755791 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 811 |    156.399809 |    765.757665 | Gareth Monger                                                                                                                                                                        |
| 812 |    381.146221 |    578.941153 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 813 |    417.916171 |    652.859819 | Mathilde Cordellier                                                                                                                                                                  |
| 814 |    710.361617 |    640.505115 | Matthias Buschmann (vectorized by T. Michael Keesey)                                                                                                                                 |
| 815 |    329.465425 |    304.223815 | Joschua Knüppe                                                                                                                                                                       |
| 816 |    282.966069 |    644.351237 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 817 |    870.005513 |    363.453410 | Ferran Sayol                                                                                                                                                                         |
| 818 |     86.305567 |    782.685936 | Ieuan Jones                                                                                                                                                                          |
| 819 |    108.057548 |    241.907348 | Mali’o Kodis, photograph by Bruno Vellutini                                                                                                                                          |
| 820 |    530.350761 |    409.102528 | Karla Martinez                                                                                                                                                                       |
| 821 |    193.244471 |    763.723681 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                                        |
| 822 |    414.762730 |    144.132167 | Nobu Tamura                                                                                                                                                                          |
| 823 |    522.261644 |    172.223236 | Matt Martyniuk                                                                                                                                                                       |
| 824 |     22.954123 |    660.767392 | Archaeodontosaurus (vectorized by T. Michael Keesey)                                                                                                                                 |
| 825 |    983.523234 |    618.613837 | Pete Buchholz                                                                                                                                                                        |
| 826 |      7.607926 |    355.840491 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 827 |    239.717744 |    787.258322 | Pedro de Siracusa                                                                                                                                                                    |
| 828 |    606.432972 |    787.580443 | NA                                                                                                                                                                                   |
| 829 |     64.870803 |    289.592992 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 830 |    956.330322 |      5.641089 | Zimices                                                                                                                                                                              |
| 831 |    113.998693 |    468.006847 | Smokeybjb (modified by T. Michael Keesey)                                                                                                                                            |
| 832 |     10.269193 |    117.609317 | Tasman Dixon                                                                                                                                                                         |
| 833 |    535.510515 |    173.316523 | Emily Willoughby                                                                                                                                                                     |
| 834 |     17.157483 |    185.037300 | ДиБгд (vectorized by T. Michael Keesey)                                                                                                                                              |
| 835 |    381.764787 |    739.630424 | FunkMonk                                                                                                                                                                             |
| 836 |    249.563036 |     19.098251 | Steven Traver                                                                                                                                                                        |
| 837 |    673.866218 |    543.601838 | Margot Michaud                                                                                                                                                                       |
| 838 |    121.471510 |    721.577847 | Michael B. H. (vectorized by T. Michael Keesey)                                                                                                                                      |
| 839 |    128.003623 |     90.205641 | Matt Crook                                                                                                                                                                           |
| 840 |    156.029948 |    730.247573 | Bruno Maggia                                                                                                                                                                         |
| 841 |     29.573300 |    518.900622 | Matt Crook                                                                                                                                                                           |
| 842 |    723.487470 |    239.785639 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 843 |    124.393418 |    104.862159 | Kimberly Haddrell                                                                                                                                                                    |
| 844 |     19.185823 |    790.136989 | Jiekun He                                                                                                                                                                            |
| 845 |    977.507995 |    439.841323 | Zimices                                                                                                                                                                              |
| 846 |    584.111047 |    438.675607 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 847 |    995.693369 |    688.952488 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 848 |    502.667211 |    354.976170 | Natasha Vitek                                                                                                                                                                        |
| 849 |    853.984139 |    465.192772 | Noah Schlottman, photo by Casey Dunn                                                                                                                                                 |
| 850 |     12.873816 |    720.931269 | Zimices                                                                                                                                                                              |
| 851 |    480.930177 |    474.620755 | NA                                                                                                                                                                                   |
| 852 |    853.465497 |    205.470847 | Jagged Fang Designs                                                                                                                                                                  |
| 853 |    286.763055 |    304.043229 | NA                                                                                                                                                                                   |
| 854 |    805.888008 |    227.661500 | Margot Michaud                                                                                                                                                                       |
| 855 |     15.157535 |    517.923826 | L. Shyamal                                                                                                                                                                           |
| 856 |    158.363353 |    130.623301 | Natasha Vitek                                                                                                                                                                        |
| 857 |    943.916754 |    597.000142 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 858 |    678.900155 |    493.108083 | Zimices                                                                                                                                                                              |
| 859 |    399.387611 |    298.418178 | Skye McDavid                                                                                                                                                                         |
| 860 |     38.003233 |    406.101882 | Matt Crook                                                                                                                                                                           |
| 861 |     53.058515 |    365.935747 | Cristina Guijarro                                                                                                                                                                    |
| 862 |     78.000540 |    735.557835 | B. Duygu Özpolat                                                                                                                                                                     |
| 863 |    149.831839 |     11.069822 | Zimices                                                                                                                                                                              |
| 864 |    929.385650 |     42.343004 | Timothy Knepp (vectorized by T. Michael Keesey)                                                                                                                                      |
| 865 |    620.556927 |    494.638398 | Arthur S. Brum                                                                                                                                                                       |
| 866 |    891.511540 |    166.122975 | Mette Aumala                                                                                                                                                                         |
| 867 |    972.096463 |    687.892267 | Matt Crook                                                                                                                                                                           |
| 868 |    167.719612 |     13.746807 | Gareth Monger                                                                                                                                                                        |
| 869 |    626.815912 |    246.292363 | SauropodomorphMonarch                                                                                                                                                                |
| 870 |    143.311633 |    104.414247 | NA                                                                                                                                                                                   |
| 871 |    559.999453 |    536.462038 | Michelle Site                                                                                                                                                                        |
| 872 |    941.292760 |    500.291508 | Jimmy Bernot                                                                                                                                                                         |
| 873 |    604.151620 |    228.852122 | Beth Reinke                                                                                                                                                                          |
| 874 |    131.734106 |    368.420036 | Fernando Carezzano                                                                                                                                                                   |
| 875 |    651.608253 |    610.829550 | Ferran Sayol                                                                                                                                                                         |
| 876 |    948.179238 |     96.552853 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 877 |    137.157094 |     50.679603 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 878 |    388.066205 |    135.197495 | Jose Carlos Arenas-Monroy                                                                                                                                                            |
| 879 |    414.638620 |    230.512728 | Christina N. Hodson                                                                                                                                                                  |
| 880 |    621.872607 |    184.210572 | Margot Michaud                                                                                                                                                                       |
| 881 |     78.277760 |    415.293784 | Jimmy Bernot                                                                                                                                                                         |
| 882 |     56.528276 |    376.285347 | Steven Coombs                                                                                                                                                                        |
| 883 |    932.365225 |     18.714928 | Michael Scroggie                                                                                                                                                                     |
| 884 |    533.381481 |    182.858560 | Kailah Thorn & Mark Hutchinson                                                                                                                                                       |
| 885 |    590.987056 |    718.457102 | Ewald Rübsamen                                                                                                                                                                       |
| 886 |     65.412640 |    642.867480 | CNZdenek                                                                                                                                                                             |
| 887 |    833.578974 |    177.257352 | Gareth Monger                                                                                                                                                                        |
| 888 |    151.383259 |     28.583142 | Margot Michaud                                                                                                                                                                       |
| 889 |    602.800998 |    725.245620 | Christoph Schomburg                                                                                                                                                                  |
| 890 |    633.667176 |    613.616224 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 891 |     81.767209 |    682.057338 | Chase Brownstein                                                                                                                                                                     |
| 892 |   1020.093552 |    641.942820 | Dean Schnabel                                                                                                                                                                        |
| 893 |    596.484502 |    577.810182 | Chris huh                                                                                                                                                                            |
| 894 |    241.363367 |    241.213959 | Gareth Monger                                                                                                                                                                        |
| 895 |    516.982098 |    194.189112 | Jerry Oldenettel (vectorized by T. Michael Keesey)                                                                                                                                   |
| 896 |    883.176973 |    613.875755 | J. J. Harrison (photo) & T. Michael Keesey                                                                                                                                           |
| 897 |     43.422871 |    355.565980 | Collin Gross                                                                                                                                                                         |
| 898 |    651.167377 |    486.171166 | Jose Carlos Arenas-Monroy                                                                                                                                                            |
| 899 |    648.926334 |    439.270050 | Margot Michaud                                                                                                                                                                       |
| 900 |    557.561189 |    158.888749 | Margot Michaud                                                                                                                                                                       |
| 901 |    219.818307 |     95.224796 | Gareth Monger                                                                                                                                                                        |
| 902 |    344.143043 |    792.727501 | Tracy A. Heath                                                                                                                                                                       |
| 903 |    908.904827 |    287.750229 | L. Shyamal                                                                                                                                                                           |
| 904 |    969.779609 |    521.983168 | Margot Michaud                                                                                                                                                                       |

    #> Your tweet has been posted!
