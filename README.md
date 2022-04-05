
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

Martin R. Smith, Ferran Sayol, Jaime Headden, Plukenet, Steven Traver,
Gabriela Palomo-Munoz, Caleb M. Brown, Markus A. Grohme, Lafage, Sarah
Werning, White Wolf, Nobu Tamura (vectorized by T. Michael Keesey),
Zimices, Tasman Dixon, Chris huh, T. Michael Keesey (after Monika
Betley), Scott Hartman, Oscar Sanisidro, Michele M Tobias, Jay
Matternes, vectorized by Zimices, Iain Reid, Melissa Broussard, Gareth
Monger, Felix Vaux, Robbie N. Cada (modified by T. Michael Keesey),
S.Martini, Dmitry Bogdanov (vectorized by T. Michael Keesey), Lily
Hughes, Michael P. Taylor, Filip em, M Kolmann, Erika Schumacher, Margot
Michaud, Matt Crook, Dean Schnabel, Jan Sevcik (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Robert Bruce
Horsfall (vectorized by William Gearty), CNZdenek, Alex Slavenko, Tracy
A. Heath, Jagged Fang Designs, Michelle Site, Nobu Tamura, Harold N
Eyster, Noah Schlottman, Cesar Julian, Renata F. Martins, Andy Wilson,
Lukasiniho, Emily Willoughby, Ignacio Contreras, Didier Descouens
(vectorized by T. Michael Keesey), David Orr, Jesús Gómez, vectorized by
Zimices, Henry Lydecker, T. Michael Keesey (after James & al.), Jake
Warner, Andrew A. Farke, Sean McCann, Kamil S. Jaron, Sharon
Wegner-Larsen, T. Michael Keesey, Roberto Díaz Sibaja, Ellen Edmonson
(illustration) and Timothy J. Bartley (silhouette), B. Duygu Özpolat,
xgirouxb, Smokeybjb, Ludwik Gasiorowski, Christoph Schomburg, T. Michael
Keesey (after Kukalová), Matt Martyniuk, Mathieu Pélissié, Alexandre
Vong, T. Tischler, Jack Mayer Wood, Martin R. Smith, from photo by
Jürgen Schoner, Katie S. Collins, Nobu Tamura, vectorized by Zimices,
Wayne Decatur, Mali’o Kodis, photograph by Ching
(<http://www.flickr.com/photos/36302473@N03/>), Mette Aumala, Chase
Brownstein, Mali’o Kodis, image from the “Proceedings of the Zoological
Society of London”, Rebecca Groom,
\<U+0412\>\<U+0430\>\<U+043B\>\<U+044C\>\<U+0434\>\<U+0438\>\<U+043C\>\<U+0430\>\<U+0440\>
(vectorized by T. Michael Keesey), NOAA Great Lakes Environmental
Research Laboratory (illustration) and Timothy J. Bartley (silhouette),
Dann Pigdon, Ghedoghedo (vectorized by T. Michael Keesey), Marie
Russell, Michael Scroggie, Jimmy Bernot, Marcos Pérez-Losada, Jens T.
Høeg & Keith A. Crandall, Jaime Chirinos (vectorized by T. Michael
Keesey), C. Camilo Julián-Caballero, Tomas Willems (vectorized by T.
Michael Keesey), Mariana Ruiz Villarreal, Jakovche, Abraão B. Leite,
Skye M, FunkMonk, Nobu Tamura and T. Michael Keesey, FJDegrange, Robbie
Cada (vectorized by T. Michael Keesey), Steve Hillebrand/U. S. Fish and
Wildlife Service (source photo), T. Michael Keesey (vectorization),
Griensteidl and T. Michael Keesey, Milton Tan, Christian A. Masnaghetti,
Jose Carlos Arenas-Monroy, Fernando Carezzano, Mathew Wedel, Emil
Schmidt (vectorized by Maxime Dahirel), Ryan Cupo, Ben Moon, Armelle
Ansart (photograph), Maxime Dahirel (digitisation), Birgit Lang, T.
Michael Keesey (vectorization) and Nadiatalent (photography), T. Michael
Keesey (after A. Y. Ivantsov), Collin Gross, Owen Jones (derived from a
CC-BY 2.0 photograph by Paulo B. Chaves), Joanna Wolfe, Lankester Edwin
Ray (vectorized by T. Michael Keesey), T. K. Robinson, Noah Schlottman,
photo by Casey Dunn, Ekaterina Kopeykina (vectorized by T. Michael
Keesey), Yan Wong from SEM by Arnau Sebé-Pedrós (PD agreed by Iñaki
Ruiz-Trillo), Alan Manson (photo), John E. McCormack, Michael G. Harvey,
Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T.
Brumfield & T. Michael Keesey, Mathilde Cordellier, Anthony Caravaggi,
Yan Wong, NASA, L. Shyamal, Burton Robert, USFWS, Hans Hillewaert
(vectorized by T. Michael Keesey), Jessica Anne Miller, Scarlet23
(vectorized by T. Michael Keesey), Maija Karala, Marmelad, Stanton F.
Fink (vectorized by T. Michael Keesey), Carlos Cano-Barbacil, Lauren
Anderson, B Kimmel, Pete Buchholz, Kanchi Nanjo, T. Michael Keesey
(after Marek Velechovský), James R. Spotila and Ray Chatterji, Arthur S.
Brum, Peileppe, Mateus Zica (modified by T. Michael Keesey),
Benjamint444, Sam Droege (photography) and T. Michael Keesey
(vectorization), DW Bapst, modified from Ishitani et al. 2016, Ingo
Braasch, Hanyong Pu, Yoshitsugu Kobayashi, Junchang Lü, Li Xu, Yanhua
Wu, Huali Chang, Jiming Zhang, Songhai Jia & T. Michael Keesey, Servien
(vectorized by T. Michael Keesey), Matt Dempsey, Shyamal, Christine
Axon, Dexter R. Mardis, Juan Carlos Jerí, Myriam\_Ramirez, Meyers
Konversations-Lexikon 1897 (vectorized: Yan Wong), Cristopher Silva, DW
Bapst (modified from Bulman, 1970), Inessa Voet, Noah Schlottman, photo
from Casey Dunn, Tim H. Heupink, Leon Huynen, and David M. Lambert
(vectorized by T. Michael Keesey), Danny Cicchetti (vectorized by T.
Michael Keesey), E. R. Waite & H. M. Hale (vectorized by T. Michael
Keesey), Robert Gay, modified from FunkMonk (Michael B.H.) and T.
Michael Keesey., Cristina Guijarro, André Karwath (vectorized by T.
Michael Keesey), Kai R. Caspar, T. Michael Keesey (after Heinrich
Harder), Henry Fairfield Osborn, vectorized by Zimices, Maxime Dahirel,
Ben Liebeskind, Julio Garza, Roule Jammes (vectorized by T. Michael
Keesey), Mason McNair, Tauana J. Cunha, . Original drawing by M. Antón,
published in Montoya and Morales 1984. Vectorized by O. Sanisidro, Maky
(vectorization), Gabriella Skollar (photography), Rebecca Lewis
(editing), Remes K, Ortega F, Fierro I, Joger U, Kosma R, et al., Steven
Blackwood, Paul O. Lewis, Charles R. Knight (vectorized by T. Michael
Keesey), Meliponicultor Itaymbere, Gabriel Lio, vectorized by Zimices,
Scott Reid, Archaeodontosaurus (vectorized by T. Michael Keesey), J
Levin W (illustration) and T. Michael Keesey (vectorization), Francis de
Laporte de Castelnau (vectorized by T. Michael Keesey), Obsidian Soul
(vectorized by T. Michael Keesey), Oren Peles / vectorized by Yan Wong,
Alexander Schmidt-Lebuhn, Smokeybjb, vectorized by Zimices, Brockhaus
and Efron, Dmitry Bogdanov, vectorized by Zimices, Isaure Scavezzoni,
Mareike C. Janiak, Becky Barnes, Michele M Tobias from an image By
Dcrjsr - Own work, CC BY 3.0,
<https://commons.wikimedia.org/w/index.php?curid=18059686>, \[unknown\],
David Tana, Todd Marshall, vectorized by Zimices, Matt Wilkins (photo by
Patrick Kavanagh), Mo Hassan, Mali’o Kodis, image from Higgins and
Kristensen, 1986, Eric Moody, Ricardo Araújo, T. Michael Keesey (from a
photograph by Frank Glaw, Jörn Köhler, Ted M. Townsend & Miguel Vences),
Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Dmitry Bogdanov, Daniel Stadtmauer, Matt Hayes, Noah
Schlottman, photo by Antonio Guillén, Hans Hillewaert, Mali’o Kodis,
photograph by Cordell Expeditions at Cal Academy, Jan A. Venter, Herbert
H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael
Keesey), Chris Jennings (vectorized by A. Verrière), Mattia Menchetti /
Yan Wong, Robert Gay, Raven Amos, Ville-Veikko Sinkkonen, Armin Reindl,
Robert Bruce Horsfall, vectorized by Zimices, Evan-Amos (vectorized by
T. Michael Keesey), Walter Vladimir, Trond R. Oskars, C. W. Nash
(illustration) and Timothy J. Bartley (silhouette), Haplochromis
(vectorized by T. Michael Keesey), Julien Louys, Matt Celeskey, Jay
Matternes (vectorized by T. Michael Keesey), Smokeybjb (modified by Mike
Keesey), Mattia Menchetti, Dr. Thomas G. Barnes, USFWS, Chuanixn Yu,
david maas / dave hone, Don Armstrong, Philip Chalmers (vectorized by T.
Michael Keesey), Danielle Alba, Scott Hartman (vectorized by T. Michael
Keesey), Noah Schlottman, photo by Adam G. Clause, Lindberg (vectorized
by T. Michael Keesey), Francisco Manuel Blanco (vectorized by T. Michael
Keesey), Blanco et al., 2014, vectorized by Zimices, Siobhon Egan,
(after Spotila 2004), Louis Ranjard, Nobu Tamura (modified by T. Michael
Keesey), Chloé Schmidt, Natalie Claunch, Darren Naish (vectorize by T.
Michael Keesey), Arthur Weasley (vectorized by T. Michael Keesey), Beth
Reinke, A. R. McCulloch (vectorized by T. Michael Keesey), Robert
Hering, Mali’o Kodis, image from the Biodiversity Heritage Library,
Mihai Dragos (vectorized by T. Michael Keesey), Andreas Trepte
(vectorized by T. Michael Keesey), Terpsichores, Rene Martin,
kreidefossilien.de, Jim Bendon (photography) and T. Michael Keesey
(vectorization), Steven Coombs, Felix Vaux and Steven A. Trewick, Arthur
Grosset (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                         |
| --: | ------------: | ------------: | :------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    654.208446 |    625.979617 | Martin R. Smith                                                                                                                                                |
|   2 |    255.836181 |     86.470419 | Ferran Sayol                                                                                                                                                   |
|   3 |    694.967819 |    268.214515 | Jaime Headden                                                                                                                                                  |
|   4 |    951.372876 |    256.445551 | Plukenet                                                                                                                                                       |
|   5 |    413.683220 |    240.066438 | Steven Traver                                                                                                                                                  |
|   6 |    527.981719 |    699.648075 | Gabriela Palomo-Munoz                                                                                                                                          |
|   7 |    963.139212 |    519.457369 | Caleb M. Brown                                                                                                                                                 |
|   8 |    787.001621 |    502.946560 | Markus A. Grohme                                                                                                                                               |
|   9 |    853.033850 |    158.167782 | Lafage                                                                                                                                                         |
|  10 |    115.912269 |    553.084404 | Sarah Werning                                                                                                                                                  |
|  11 |    246.502400 |    409.176255 | Steven Traver                                                                                                                                                  |
|  12 |    222.269663 |    636.311595 | White Wolf                                                                                                                                                     |
|  13 |    159.343708 |    698.203231 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
|  14 |     67.746992 |    290.782081 | Zimices                                                                                                                                                        |
|  15 |    369.421650 |     39.506769 | Tasman Dixon                                                                                                                                                   |
|  16 |     70.721535 |    672.440966 | Chris huh                                                                                                                                                      |
|  17 |    903.153690 |    547.954948 | Ferran Sayol                                                                                                                                                   |
|  18 |    566.453072 |    480.735841 | T. Michael Keesey (after Monika Betley)                                                                                                                        |
|  19 |    515.905642 |    117.576474 | Zimices                                                                                                                                                        |
|  20 |    956.136857 |    650.228084 | Scott Hartman                                                                                                                                                  |
|  21 |    543.137869 |    386.702371 | Oscar Sanisidro                                                                                                                                                |
|  22 |     66.611210 |    393.905369 | Michele M Tobias                                                                                                                                               |
|  23 |    954.108208 |    394.851926 | Jay Matternes, vectorized by Zimices                                                                                                                           |
|  24 |    204.021035 |    238.864179 | Iain Reid                                                                                                                                                      |
|  25 |    555.375380 |    200.790689 | NA                                                                                                                                                             |
|  26 |    697.758321 |    131.053493 | Melissa Broussard                                                                                                                                              |
|  27 |    144.079316 |     70.323300 | Gareth Monger                                                                                                                                                  |
|  28 |    381.896699 |    642.880829 | Felix Vaux                                                                                                                                                     |
|  29 |    813.179564 |    380.276634 | Melissa Broussard                                                                                                                                              |
|  30 |    893.613082 |    771.965320 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                                 |
|  31 |    964.042956 |     73.704768 | S.Martini                                                                                                                                                      |
|  32 |    809.397939 |    100.436315 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
|  33 |    783.636656 |    711.510993 | Lily Hughes                                                                                                                                                    |
|  34 |    265.762649 |    566.026810 | Melissa Broussard                                                                                                                                              |
|  35 |    629.792112 |    775.063484 | Gareth Monger                                                                                                                                                  |
|  36 |    303.846293 |    703.860218 | Michael P. Taylor                                                                                                                                              |
|  37 |    229.466938 |     18.155738 | Filip em                                                                                                                                                       |
|  38 |    380.457600 |    362.741754 | M Kolmann                                                                                                                                                      |
|  39 |    183.842406 |    756.805808 | Erika Schumacher                                                                                                                                               |
|  40 |    408.368928 |    477.331600 | Margot Michaud                                                                                                                                                 |
|  41 |    560.287215 |    296.328397 | Matt Crook                                                                                                                                                     |
|  42 |    860.351792 |    609.771655 | Tasman Dixon                                                                                                                                                   |
|  43 |    173.200018 |    335.638664 | Zimices                                                                                                                                                        |
|  44 |    707.759110 |     76.585175 | Matt Crook                                                                                                                                                     |
|  45 |    278.182486 |    177.815568 | Dean Schnabel                                                                                                                                                  |
|  46 |    600.235795 |    532.985696 | Iain Reid                                                                                                                                                      |
|  47 |    659.095221 |    453.189744 | Gareth Monger                                                                                                                                                  |
|  48 |    491.144252 |     33.732428 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
|  49 |    840.622002 |    312.468634 | Zimices                                                                                                                                                        |
|  50 |    106.196342 |    155.996285 | Matt Crook                                                                                                                                                     |
|  51 |     71.274917 |    101.855783 | Zimices                                                                                                                                                        |
|  52 |    919.557172 |    707.932441 | Margot Michaud                                                                                                                                                 |
|  53 |    138.401981 |    602.858576 | Jan Sevcik (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey     |
|  54 |    453.589203 |    547.639080 | Robert Bruce Horsfall (vectorized by William Gearty)                                                                                                           |
|  55 |    544.457417 |    581.390464 | CNZdenek                                                                                                                                                       |
|  56 |    761.356265 |    255.273789 | Scott Hartman                                                                                                                                                  |
|  57 |    788.096966 |    565.255767 | Alex Slavenko                                                                                                                                                  |
|  58 |    102.341186 |    480.898457 | Matt Crook                                                                                                                                                     |
|  59 |    412.384780 |    134.170685 | Gabriela Palomo-Munoz                                                                                                                                          |
|  60 |    381.588493 |    758.217505 | Tracy A. Heath                                                                                                                                                 |
|  61 |    855.029212 |    211.406925 | Jagged Fang Designs                                                                                                                                            |
|  62 |    826.340100 |     28.619286 | Steven Traver                                                                                                                                                  |
|  63 |    825.435496 |     68.915562 | Michelle Site                                                                                                                                                  |
|  64 |    594.234464 |     60.244736 | Zimices                                                                                                                                                        |
|  65 |    957.530369 |    613.697091 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
|  66 |    702.620606 |    391.476378 | Gareth Monger                                                                                                                                                  |
|  67 |    873.991789 |    463.095476 | Scott Hartman                                                                                                                                                  |
|  68 |    837.477218 |    664.260984 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
|  69 |    499.312848 |    406.691660 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
|  70 |    127.908710 |    181.203613 | Nobu Tamura                                                                                                                                                    |
|  71 |    742.865432 |    610.180523 | Dean Schnabel                                                                                                                                                  |
|  72 |    758.275959 |    758.029501 | Jagged Fang Designs                                                                                                                                            |
|  73 |    768.930586 |    464.565102 | Harold N Eyster                                                                                                                                                |
|  74 |     77.176804 |    238.098099 | Noah Schlottman                                                                                                                                                |
|  75 |    667.916796 |    343.234034 | Markus A. Grohme                                                                                                                                               |
|  76 |    270.040269 |    282.179685 | Zimices                                                                                                                                                        |
|  77 |     98.433195 |     19.143766 | Scott Hartman                                                                                                                                                  |
|  78 |     86.715337 |    778.060892 | Cesar Julian                                                                                                                                                   |
|  79 |    614.857585 |    600.930814 | Renata F. Martins                                                                                                                                              |
|  80 |    996.056313 |    320.375486 | Andy Wilson                                                                                                                                                    |
|  81 |    314.317908 |    629.381856 | Margot Michaud                                                                                                                                                 |
|  82 |    214.665104 |    612.857130 | Lukasiniho                                                                                                                                                     |
|  83 |    445.469241 |    321.149782 | Gabriela Palomo-Munoz                                                                                                                                          |
|  84 |    109.335566 |     47.528776 | Emily Willoughby                                                                                                                                               |
|  85 |    347.055126 |    575.789554 | Ignacio Contreras                                                                                                                                              |
|  86 |    159.318298 |    467.632791 | Matt Crook                                                                                                                                                     |
|  87 |    342.145558 |    605.784238 | Markus A. Grohme                                                                                                                                               |
|  88 |    640.454100 |    208.936022 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                             |
|  89 |    588.534425 |    693.582811 | Matt Crook                                                                                                                                                     |
|  90 |     22.192143 |    712.840053 | Zimices                                                                                                                                                        |
|  91 |    891.617290 |    224.381048 | David Orr                                                                                                                                                      |
|  92 |     32.423743 |    134.778464 | Jesús Gómez, vectorized by Zimices                                                                                                                             |
|  93 |    262.538525 |    781.554796 | Tasman Dixon                                                                                                                                                   |
|  94 |    795.090726 |    437.819805 | Henry Lydecker                                                                                                                                                 |
|  95 |    932.796507 |    442.313163 | T. Michael Keesey (after James & al.)                                                                                                                          |
|  96 |     35.190992 |    543.453743 | Zimices                                                                                                                                                        |
|  97 |    574.619030 |    649.285258 | Gareth Monger                                                                                                                                                  |
|  98 |   1003.493319 |    209.906623 | Jake Warner                                                                                                                                                    |
|  99 |    197.467827 |    392.023975 | Gareth Monger                                                                                                                                                  |
| 100 |    770.793817 |    202.414127 | Andrew A. Farke                                                                                                                                                |
| 101 |    978.483128 |    466.324839 | Sean McCann                                                                                                                                                    |
| 102 |    151.935370 |    431.921668 | Kamil S. Jaron                                                                                                                                                 |
| 103 |    391.718378 |    738.430270 | Gareth Monger                                                                                                                                                  |
| 104 |     37.665400 |     32.597854 | Sharon Wegner-Larsen                                                                                                                                           |
| 105 |    148.512993 |    282.431690 | Gareth Monger                                                                                                                                                  |
| 106 |     63.597825 |    725.158406 | T. Michael Keesey                                                                                                                                              |
| 107 |    798.299000 |    230.248715 | Lily Hughes                                                                                                                                                    |
| 108 |    947.984814 |    783.341908 | Zimices                                                                                                                                                        |
| 109 |    115.253908 |    452.511299 | Matt Crook                                                                                                                                                     |
| 110 |    337.700311 |    266.528308 | Roberto Díaz Sibaja                                                                                                                                            |
| 111 |    298.972970 |     28.377532 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                              |
| 112 |    998.630145 |    181.709635 | B. Duygu Özpolat                                                                                                                                               |
| 113 |    791.958172 |    606.995629 | xgirouxb                                                                                                                                                       |
| 114 |    305.034944 |    516.470030 | Felix Vaux                                                                                                                                                     |
| 115 |    189.156537 |    509.750059 | Margot Michaud                                                                                                                                                 |
| 116 |    348.613262 |    403.359894 | Kamil S. Jaron                                                                                                                                                 |
| 117 |    994.456683 |    562.641241 | Smokeybjb                                                                                                                                                      |
| 118 |    183.984618 |    283.718067 | Gareth Monger                                                                                                                                                  |
| 119 |    231.138937 |    511.277927 | Zimices                                                                                                                                                        |
| 120 |     38.734975 |    508.434793 | Ludwik Gasiorowski                                                                                                                                             |
| 121 |    531.023897 |    304.169195 | Christoph Schomburg                                                                                                                                            |
| 122 |    264.878105 |     99.281482 | Markus A. Grohme                                                                                                                                               |
| 123 |    431.128118 |    743.937839 | Matt Crook                                                                                                                                                     |
| 124 |     27.757726 |    198.979300 | Steven Traver                                                                                                                                                  |
| 125 |    817.149272 |     93.527815 | Markus A. Grohme                                                                                                                                               |
| 126 |    439.423688 |    653.881115 | T. Michael Keesey (after Kukalová)                                                                                                                             |
| 127 |    630.108615 |    715.316813 | Matt Martyniuk                                                                                                                                                 |
| 128 |    622.278448 |    139.567319 | Mathieu Pélissié                                                                                                                                               |
| 129 |    152.204421 |    248.930057 | Alexandre Vong                                                                                                                                                 |
| 130 |    789.108249 |    276.162483 | Steven Traver                                                                                                                                                  |
| 131 |    798.199679 |    578.523199 | T. Tischler                                                                                                                                                    |
| 132 |    984.695160 |    524.614126 | Gabriela Palomo-Munoz                                                                                                                                          |
| 133 |    691.504912 |    294.884662 | Matt Crook                                                                                                                                                     |
| 134 |    341.952781 |    793.618301 | Sharon Wegner-Larsen                                                                                                                                           |
| 135 |    613.539954 |    154.890194 | NA                                                                                                                                                             |
| 136 |    899.315512 |     73.616137 | Scott Hartman                                                                                                                                                  |
| 137 |    393.075458 |    187.984742 | Christoph Schomburg                                                                                                                                            |
| 138 |    222.744727 |    669.404121 | Smokeybjb                                                                                                                                                      |
| 139 |    329.556115 |    598.746726 | Iain Reid                                                                                                                                                      |
| 140 |    464.604018 |    338.123373 | Jack Mayer Wood                                                                                                                                                |
| 141 |    898.973882 |     30.319152 | Martin R. Smith, from photo by Jürgen Schoner                                                                                                                  |
| 142 |    702.901938 |     84.841771 | Matt Crook                                                                                                                                                     |
| 143 |    418.071865 |    434.839499 | Smokeybjb                                                                                                                                                      |
| 144 |    406.989420 |    576.832592 | Steven Traver                                                                                                                                                  |
| 145 |    870.269553 |    390.440442 | Katie S. Collins                                                                                                                                               |
| 146 |    889.367458 |    118.626466 | Matt Crook                                                                                                                                                     |
| 147 |    625.130079 |     16.561525 | Katie S. Collins                                                                                                                                               |
| 148 |   1011.478688 |    647.088389 | Nobu Tamura, vectorized by Zimices                                                                                                                             |
| 149 |    933.538891 |    122.363416 | Wayne Decatur                                                                                                                                                  |
| 150 |    885.029645 |    232.872900 | Mali’o Kodis, photograph by Ching (<http://www.flickr.com/photos/36302473@N03/>)                                                                               |
| 151 |    729.909742 |    188.372252 | Mette Aumala                                                                                                                                                   |
| 152 |    276.316828 |    191.234169 | Sharon Wegner-Larsen                                                                                                                                           |
| 153 |    123.425484 |    643.794660 | T. Michael Keesey                                                                                                                                              |
| 154 |    320.336816 |    378.693096 | NA                                                                                                                                                             |
| 155 |    415.965927 |    706.627918 | NA                                                                                                                                                             |
| 156 |    148.058180 |    205.742101 | Ferran Sayol                                                                                                                                                   |
| 157 |    314.568539 |    146.001263 | Zimices                                                                                                                                                        |
| 158 |    243.457536 |    764.689934 | Zimices                                                                                                                                                        |
| 159 |    456.903444 |    771.225722 | Chase Brownstein                                                                                                                                               |
| 160 |    661.022663 |    478.476781 | Mali’o Kodis, image from the “Proceedings of the Zoological Society of London”                                                                                 |
| 161 |    345.131251 |    365.841269 | Rebecca Groom                                                                                                                                                  |
| 162 |    485.116887 |    752.471272 | \<U+0412\>\<U+0430\>\<U+043B\>\<U+044C\>\<U+0434\>\<U+0438\>\<U+043C\>\<U+0430\>\<U+0440\> (vectorized by T. Michael Keesey)                                   |
| 163 |    999.468918 |    766.600103 | Steven Traver                                                                                                                                                  |
| 164 |    626.985338 |    395.904411 | Markus A. Grohme                                                                                                                                               |
| 165 |    120.579578 |      2.672065 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                          |
| 166 |    373.406482 |    785.759154 | Dann Pigdon                                                                                                                                                    |
| 167 |    924.586084 |    321.320801 | xgirouxb                                                                                                                                                       |
| 168 |   1008.322732 |    695.429676 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                   |
| 169 |    350.477286 |    103.584241 | Zimices                                                                                                                                                        |
| 170 |    685.298719 |    694.135611 | Zimices                                                                                                                                                        |
| 171 |    660.733043 |     46.138368 | Ferran Sayol                                                                                                                                                   |
| 172 |    169.736336 |    204.160877 | Michelle Site                                                                                                                                                  |
| 173 |    334.952147 |    148.747780 | Marie Russell                                                                                                                                                  |
| 174 |    828.676834 |    248.749268 | Ferran Sayol                                                                                                                                                   |
| 175 |    718.449094 |    545.781647 | Michael Scroggie                                                                                                                                               |
| 176 |    755.411442 |    222.090695 | Gareth Monger                                                                                                                                                  |
| 177 |    866.375894 |    360.114119 | NA                                                                                                                                                             |
| 178 |    335.636586 |    390.208833 | Chris huh                                                                                                                                                      |
| 179 |    147.586652 |    359.509048 | Zimices                                                                                                                                                        |
| 180 |    593.906377 |    150.025312 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 181 |    708.495475 |    278.441952 | T. Michael Keesey                                                                                                                                              |
| 182 |    436.309178 |    665.199761 | T. Michael Keesey                                                                                                                                              |
| 183 |     19.453413 |    461.399633 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 184 |    705.251041 |    632.084657 | Sean McCann                                                                                                                                                    |
| 185 |    182.023231 |    700.642997 | Iain Reid                                                                                                                                                      |
| 186 |    350.334430 |    245.000943 | Matt Crook                                                                                                                                                     |
| 187 |    148.750660 |     85.445469 | Jimmy Bernot                                                                                                                                                   |
| 188 |    631.987202 |    280.216272 | Steven Traver                                                                                                                                                  |
| 189 |     92.473616 |    452.572980 | Roberto Díaz Sibaja                                                                                                                                            |
| 190 |    642.800076 |     21.674138 | Felix Vaux                                                                                                                                                     |
| 191 |    428.484638 |    679.737961 | NA                                                                                                                                                             |
| 192 |    618.066419 |    709.324982 | Marcos Pérez-Losada, Jens T. Høeg & Keith A. Crandall                                                                                                          |
| 193 |    420.915276 |    258.057713 | Jaime Chirinos (vectorized by T. Michael Keesey)                                                                                                               |
| 194 |    907.815748 |    409.538429 | C. Camilo Julián-Caballero                                                                                                                                     |
| 195 |    835.336989 |    549.408832 | David Orr                                                                                                                                                      |
| 196 |    136.282300 |    393.032236 | Tomas Willems (vectorized by T. Michael Keesey)                                                                                                                |
| 197 |    726.100762 |    697.761595 | Mariana Ruiz Villarreal                                                                                                                                        |
| 198 |   1015.132487 |     98.313799 | Jakovche                                                                                                                                                       |
| 199 |    890.274353 |    474.168161 | Abraão B. Leite                                                                                                                                                |
| 200 |    129.189448 |    587.055039 | Skye M                                                                                                                                                         |
| 201 |    310.505710 |    771.815377 | Ferran Sayol                                                                                                                                                   |
| 202 |    671.998637 |    216.878329 | Steven Traver                                                                                                                                                  |
| 203 |    640.561082 |    158.935783 | FunkMonk                                                                                                                                                       |
| 204 |    435.863460 |    503.668791 | Nobu Tamura and T. Michael Keesey                                                                                                                              |
| 205 |    320.020351 |    468.863772 | Michael Scroggie                                                                                                                                               |
| 206 |    760.767480 |    619.785529 | Jagged Fang Designs                                                                                                                                            |
| 207 |     28.060242 |    487.130707 | FJDegrange                                                                                                                                                     |
| 208 |    213.222628 |    293.422782 | NA                                                                                                                                                             |
| 209 |    432.945294 |    369.307137 | Margot Michaud                                                                                                                                                 |
| 210 |    238.267936 |    488.213130 | Robbie Cada (vectorized by T. Michael Keesey)                                                                                                                  |
| 211 |    228.713064 |    195.904538 | Steve Hillebrand/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                             |
| 212 |    794.286681 |    758.500776 | Michelle Site                                                                                                                                                  |
| 213 |    839.463759 |    681.632786 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 214 |    581.796998 |    316.137664 | Griensteidl and T. Michael Keesey                                                                                                                              |
| 215 |     76.146529 |    717.224836 | Gareth Monger                                                                                                                                                  |
| 216 |    489.976228 |    318.105212 | T. Michael Keesey                                                                                                                                              |
| 217 |    601.230174 |    639.657154 | Chris huh                                                                                                                                                      |
| 218 |    300.161458 |    210.725132 | Milton Tan                                                                                                                                                     |
| 219 |    740.885796 |    174.290950 | Christian A. Masnaghetti                                                                                                                                       |
| 220 |    611.427681 |    231.563197 | Jack Mayer Wood                                                                                                                                                |
| 221 |   1013.505152 |    624.212858 | Jose Carlos Arenas-Monroy                                                                                                                                      |
| 222 |    200.431199 |    651.939788 | Sarah Werning                                                                                                                                                  |
| 223 |    204.129171 |    741.749861 | Fernando Carezzano                                                                                                                                             |
| 224 |    320.522360 |    651.307254 | Mathew Wedel                                                                                                                                                   |
| 225 |    634.519234 |    740.610039 | Chris huh                                                                                                                                                      |
| 226 |    900.103647 |    180.432806 | Matt Crook                                                                                                                                                     |
| 227 |    104.885127 |    752.354039 | Emil Schmidt (vectorized by Maxime Dahirel)                                                                                                                    |
| 228 |    929.153963 |    467.484653 | Ryan Cupo                                                                                                                                                      |
| 229 |    938.300193 |    492.221246 | Tasman Dixon                                                                                                                                                   |
| 230 |    268.364216 |     65.624805 | T. Michael Keesey                                                                                                                                              |
| 231 |    446.579661 |    753.932824 | Dean Schnabel                                                                                                                                                  |
| 232 |    683.294477 |    320.986099 | Michael Scroggie                                                                                                                                               |
| 233 |    206.471508 |    150.550077 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                             |
| 234 |   1012.613579 |    680.682326 | Lukasiniho                                                                                                                                                     |
| 235 |    334.103239 |    537.820598 | Ben Moon                                                                                                                                                       |
| 236 |    855.478068 |    257.655457 | Armelle Ansart (photograph), Maxime Dahirel (digitisation)                                                                                                     |
| 237 |    721.121661 |    537.579496 | Ignacio Contreras                                                                                                                                              |
| 238 |    997.610684 |    306.881726 | Scott Hartman                                                                                                                                                  |
| 239 |    420.645220 |    379.737136 | Milton Tan                                                                                                                                                     |
| 240 |    854.994301 |     89.951206 | Matt Crook                                                                                                                                                     |
| 241 |    689.438602 |    722.626880 | Birgit Lang                                                                                                                                                    |
| 242 |    325.482281 |    783.528883 | Gareth Monger                                                                                                                                                  |
| 243 |    722.885657 |    616.417398 | Markus A. Grohme                                                                                                                                               |
| 244 |   1012.654067 |     90.307421 | Margot Michaud                                                                                                                                                 |
| 245 |    999.955612 |    551.712533 | Steven Traver                                                                                                                                                  |
| 246 |      8.958839 |     67.202490 | Zimices                                                                                                                                                        |
| 247 |    415.042388 |    296.353215 | Mathieu Pélissié                                                                                                                                               |
| 248 |    825.854492 |    697.531964 | Ferran Sayol                                                                                                                                                   |
| 249 |    674.016129 |    722.841091 | xgirouxb                                                                                                                                                       |
| 250 |    201.505737 |    204.803885 | Matt Crook                                                                                                                                                     |
| 251 |    780.697851 |    648.182858 | Chris huh                                                                                                                                                      |
| 252 |    756.246706 |    422.539247 | Margot Michaud                                                                                                                                                 |
| 253 |    944.087439 |    406.177185 | T. Michael Keesey                                                                                                                                              |
| 254 |    374.063919 |    566.364414 | Andy Wilson                                                                                                                                                    |
| 255 |    902.035268 |    432.126237 | Erika Schumacher                                                                                                                                               |
| 256 |    536.342600 |     80.896168 | T. Michael Keesey (vectorization) and Nadiatalent (photography)                                                                                                |
| 257 |   1018.180094 |    453.364925 | NA                                                                                                                                                             |
| 258 |    566.538438 |    321.064968 | T. Michael Keesey (after A. Y. Ivantsov)                                                                                                                       |
| 259 |    290.233600 |    611.583619 | Margot Michaud                                                                                                                                                 |
| 260 |     11.940826 |    483.495793 | Margot Michaud                                                                                                                                                 |
| 261 |    245.824762 |    737.544437 | Collin Gross                                                                                                                                                   |
| 262 |   1011.269180 |    342.879571 | T. Michael Keesey                                                                                                                                              |
| 263 |    990.646203 |    784.094629 | Zimices                                                                                                                                                        |
| 264 |    635.988964 |    422.078397 | Jimmy Bernot                                                                                                                                                   |
| 265 |    301.154901 |    672.665140 | Owen Jones (derived from a CC-BY 2.0 photograph by Paulo B. Chaves)                                                                                            |
| 266 |    997.740005 |    147.193159 | Matt Crook                                                                                                                                                     |
| 267 |    234.032523 |    546.780226 | Margot Michaud                                                                                                                                                 |
| 268 |    336.321032 |     10.507670 | Erika Schumacher                                                                                                                                               |
| 269 |    629.726931 |    690.626508 | Margot Michaud                                                                                                                                                 |
| 270 |    600.252169 |    656.696575 | Joanna Wolfe                                                                                                                                                   |
| 271 |    880.042743 |    589.532041 | Andrew A. Farke                                                                                                                                                |
| 272 |     19.762026 |     51.065848 | Matt Crook                                                                                                                                                     |
| 273 |    396.466225 |    410.565477 | Kamil S. Jaron                                                                                                                                                 |
| 274 |    984.537022 |    765.622295 | Jagged Fang Designs                                                                                                                                            |
| 275 |    549.226822 |    792.912183 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                          |
| 276 |    514.699724 |    269.151378 | Matt Crook                                                                                                                                                     |
| 277 |    461.624625 |    588.427430 | Alex Slavenko                                                                                                                                                  |
| 278 |    899.957680 |     54.938634 | NA                                                                                                                                                             |
| 279 |    875.634959 |    271.839697 | Lily Hughes                                                                                                                                                    |
| 280 |    345.225337 |    591.395675 | Zimices                                                                                                                                                        |
| 281 |     98.771849 |    436.902800 | T. K. Robinson                                                                                                                                                 |
| 282 |    792.113002 |    545.119368 | Steven Traver                                                                                                                                                  |
| 283 |    199.230012 |    428.299897 | Noah Schlottman, photo by Casey Dunn                                                                                                                           |
| 284 |    660.664514 |    247.450307 | Steven Traver                                                                                                                                                  |
| 285 |    310.370313 |    437.053840 | Christoph Schomburg                                                                                                                                            |
| 286 |   1002.284686 |    729.377525 | Ekaterina Kopeykina (vectorized by T. Michael Keesey)                                                                                                          |
| 287 |    381.605525 |    430.742426 | NA                                                                                                                                                             |
| 288 |    785.353218 |    682.838079 | NA                                                                                                                                                             |
| 289 |    703.848047 |    749.602866 | Ferran Sayol                                                                                                                                                   |
| 290 |    527.069409 |     39.706185 | Christoph Schomburg                                                                                                                                            |
| 291 |     37.043960 |    164.664324 | Zimices                                                                                                                                                        |
| 292 |    970.926232 |    444.796595 | Ferran Sayol                                                                                                                                                   |
| 293 |    768.427059 |    435.564494 | Matt Martyniuk                                                                                                                                                 |
| 294 |    323.409338 |     84.250843 | Matt Crook                                                                                                                                                     |
| 295 |    351.455023 |    685.303686 | Yan Wong from SEM by Arnau Sebé-Pedrós (PD agreed by Iñaki Ruiz-Trillo)                                                                                        |
| 296 |    763.579452 |    639.961221 | Alan Manson (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey    |
| 297 |     43.825696 |    629.435254 | Mathilde Cordellier                                                                                                                                            |
| 298 |    901.651759 |    465.126602 | Ferran Sayol                                                                                                                                                   |
| 299 |    687.803709 |    475.975628 | Steven Traver                                                                                                                                                  |
| 300 |    951.839728 |     10.884272 | T. K. Robinson                                                                                                                                                 |
| 301 |     64.964810 |     70.730715 | Emily Willoughby                                                                                                                                               |
| 302 |    892.981208 |    384.666969 | T. Michael Keesey                                                                                                                                              |
| 303 |    499.622788 |    171.666332 | Birgit Lang                                                                                                                                                    |
| 304 |    255.666510 |    318.760482 | Anthony Caravaggi                                                                                                                                              |
| 305 |   1019.781402 |    636.097184 | T. Michael Keesey                                                                                                                                              |
| 306 |    117.949992 |    365.060110 | Michelle Site                                                                                                                                                  |
| 307 |    827.047147 |    789.969817 | Gabriela Palomo-Munoz                                                                                                                                          |
| 308 |    927.379571 |     27.105617 | Yan Wong                                                                                                                                                       |
| 309 |    391.573142 |    398.430592 | Ferran Sayol                                                                                                                                                   |
| 310 |    767.940907 |    393.096107 | Michael Scroggie                                                                                                                                               |
| 311 |    715.393286 |     11.652363 | NASA                                                                                                                                                           |
| 312 |    813.037188 |    584.391372 | Zimices                                                                                                                                                        |
| 313 |    781.036983 |    175.655043 | L. Shyamal                                                                                                                                                     |
| 314 |    761.942380 |    108.204904 | Burton Robert, USFWS                                                                                                                                           |
| 315 |    496.108864 |    531.056498 | FunkMonk                                                                                                                                                       |
| 316 |    559.947542 |    429.040834 | Noah Schlottman, photo by Casey Dunn                                                                                                                           |
| 317 |    218.928408 |    201.441769 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                              |
| 318 |    759.725857 |     60.503580 | Margot Michaud                                                                                                                                                 |
| 319 |     13.690116 |     35.977097 | Matt Crook                                                                                                                                                     |
| 320 |    972.817004 |    274.670241 | Jessica Anne Miller                                                                                                                                            |
| 321 |    335.839900 |    304.107116 | Zimices                                                                                                                                                        |
| 322 |    957.848635 |    324.796735 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                                    |
| 323 |    687.382764 |    741.230654 | Zimices                                                                                                                                                        |
| 324 |    678.181189 |    207.786265 | Scott Hartman                                                                                                                                                  |
| 325 |    175.005595 |    391.511527 | Gabriela Palomo-Munoz                                                                                                                                          |
| 326 |     98.896644 |    153.514405 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 327 |    324.473115 |    333.323210 | Steven Traver                                                                                                                                                  |
| 328 |    785.847748 |    629.130104 | Christoph Schomburg                                                                                                                                            |
| 329 |    732.562350 |      7.190209 | Matt Crook                                                                                                                                                     |
| 330 |    422.391483 |    752.835148 | Scott Hartman                                                                                                                                                  |
| 331 |    647.162976 |    700.105239 | Maija Karala                                                                                                                                                   |
| 332 |    315.352238 |    678.140159 | Maija Karala                                                                                                                                                   |
| 333 |    729.894928 |     45.367759 | Alex Slavenko                                                                                                                                                  |
| 334 |    921.921171 |    582.692371 | Marmelad                                                                                                                                                       |
| 335 |     46.634618 |    607.480504 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                              |
| 336 |    696.657347 |    582.527842 | Carlos Cano-Barbacil                                                                                                                                           |
| 337 |    982.483510 |    575.106950 | NA                                                                                                                                                             |
| 338 |    370.258335 |    543.686215 | Matt Crook                                                                                                                                                     |
| 339 |     94.154851 |    582.261415 | Gabriela Palomo-Munoz                                                                                                                                          |
| 340 |   1019.597460 |    403.472212 | NA                                                                                                                                                             |
| 341 |    552.613895 |    656.850876 | Andy Wilson                                                                                                                                                    |
| 342 |    597.602810 |    114.077788 | Zimices                                                                                                                                                        |
| 343 |    343.261429 |    561.701912 | Lauren Anderson                                                                                                                                                |
| 344 |    237.162267 |    334.183776 | Dean Schnabel                                                                                                                                                  |
| 345 |    941.930424 |    584.606424 | B Kimmel                                                                                                                                                       |
| 346 |    114.048615 |    319.219687 | NA                                                                                                                                                             |
| 347 |     38.264668 |    679.969872 | T. Michael Keesey                                                                                                                                              |
| 348 |    550.859139 |    675.187733 | Joanna Wolfe                                                                                                                                                   |
| 349 |    141.576200 |    386.087206 | Carlos Cano-Barbacil                                                                                                                                           |
| 350 |    915.903601 |    736.245922 | NA                                                                                                                                                             |
| 351 |    805.893998 |    427.016548 | Pete Buchholz                                                                                                                                                  |
| 352 |    442.414465 |    399.987612 | Scott Hartman                                                                                                                                                  |
| 353 |    743.756633 |    197.088284 | Birgit Lang                                                                                                                                                    |
| 354 |    284.020110 |    153.710522 | Andy Wilson                                                                                                                                                    |
| 355 |    331.206436 |    132.585162 | NA                                                                                                                                                             |
| 356 |    600.740425 |    696.977019 | Matt Crook                                                                                                                                                     |
| 357 |    135.996529 |     32.672031 | Kanchi Nanjo                                                                                                                                                   |
| 358 |    535.006600 |    158.674544 | Margot Michaud                                                                                                                                                 |
| 359 |    507.554653 |    238.095908 | T. Michael Keesey (after Marek Velechovský)                                                                                                                    |
| 360 |    843.547028 |    368.183220 | Margot Michaud                                                                                                                                                 |
| 361 |    707.046536 |     44.944204 | James R. Spotila and Ray Chatterji                                                                                                                             |
| 362 |    668.399161 |    567.209992 | T. Tischler                                                                                                                                                    |
| 363 |      3.876662 |    210.791835 | NA                                                                                                                                                             |
| 364 |    171.302922 |    650.376753 | Matt Crook                                                                                                                                                     |
| 365 |    409.322803 |     93.813206 | Christoph Schomburg                                                                                                                                            |
| 366 |    341.990149 |    525.638527 | Arthur S. Brum                                                                                                                                                 |
| 367 |    949.234505 |    461.437563 | Iain Reid                                                                                                                                                      |
| 368 |    508.559087 |    252.186490 | Mathew Wedel                                                                                                                                                   |
| 369 |    250.848463 |    710.074899 | Chris huh                                                                                                                                                      |
| 370 |    166.064545 |    107.467439 | Peileppe                                                                                                                                                       |
| 371 |    620.833573 |    433.958495 | Felix Vaux                                                                                                                                                     |
| 372 |    913.172465 |    308.620644 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 373 |    261.284319 |    157.360039 | Kamil S. Jaron                                                                                                                                                 |
| 374 |    877.000309 |    422.509341 | Mateus Zica (modified by T. Michael Keesey)                                                                                                                    |
| 375 |     39.180718 |    172.484930 | Iain Reid                                                                                                                                                      |
| 376 |    738.190626 |     19.057779 | Markus A. Grohme                                                                                                                                               |
| 377 |    294.798429 |    226.144207 | Gareth Monger                                                                                                                                                  |
| 378 |    567.387496 |    681.787844 | Zimices                                                                                                                                                        |
| 379 |    317.092187 |    595.045742 | Collin Gross                                                                                                                                                   |
| 380 |    873.457390 |    438.148841 | Andrew A. Farke                                                                                                                                                |
| 381 |    103.161597 |    642.347531 | Skye M                                                                                                                                                         |
| 382 |    152.267415 |    263.092988 | Zimices                                                                                                                                                        |
| 383 |    197.372374 |    192.580798 | Scott Hartman                                                                                                                                                  |
| 384 |    238.745979 |    780.664423 | Ferran Sayol                                                                                                                                                   |
| 385 |    702.534088 |     12.091035 | Michael Scroggie                                                                                                                                               |
| 386 |    917.534199 |    118.250056 | Andy Wilson                                                                                                                                                    |
| 387 |    650.527930 |    538.550568 | Benjamint444                                                                                                                                                   |
| 388 |    803.591860 |     85.517642 | Sam Droege (photography) and T. Michael Keesey (vectorization)                                                                                                 |
| 389 |    117.658241 |    295.161677 | Gareth Monger                                                                                                                                                  |
| 390 |    688.877630 |    544.739088 | DW Bapst, modified from Ishitani et al. 2016                                                                                                                   |
| 391 |    415.813250 |    186.777876 | NA                                                                                                                                                             |
| 392 |    265.895096 |    621.908112 | Alexandre Vong                                                                                                                                                 |
| 393 |    260.043688 |    520.157425 | Ingo Braasch                                                                                                                                                   |
| 394 |    588.646773 |     88.975901 | Michelle Site                                                                                                                                                  |
| 395 |    177.163544 |      4.443844 | Hanyong Pu, Yoshitsugu Kobayashi, Junchang Lü, Li Xu, Yanhua Wu, Huali Chang, Jiming Zhang, Songhai Jia & T. Michael Keesey                                    |
| 396 |    622.916598 |    551.142706 | T. Michael Keesey                                                                                                                                              |
| 397 |    444.517239 |    620.420307 | Gabriela Palomo-Munoz                                                                                                                                          |
| 398 |    677.472551 |    436.890152 | Collin Gross                                                                                                                                                   |
| 399 |     34.918776 |    731.969319 | Zimices                                                                                                                                                        |
| 400 |    877.608850 |    251.684695 | T. Michael Keesey                                                                                                                                              |
| 401 |    986.335807 |    587.420797 | Markus A. Grohme                                                                                                                                               |
| 402 |    915.463903 |    383.362230 | Servien (vectorized by T. Michael Keesey)                                                                                                                      |
| 403 |     80.517266 |    168.766116 | NA                                                                                                                                                             |
| 404 |    703.281199 |    264.920604 | Jagged Fang Designs                                                                                                                                            |
| 405 |    663.778712 |    493.803658 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                              |
| 406 |    101.558268 |    599.150227 | Steven Traver                                                                                                                                                  |
| 407 |     80.056468 |    458.674102 | Katie S. Collins                                                                                                                                               |
| 408 |    327.748013 |    511.263652 | Ingo Braasch                                                                                                                                                   |
| 409 |    292.692164 |    504.579462 | NASA                                                                                                                                                           |
| 410 |    454.696352 |    175.827850 | Nobu Tamura, vectorized by Zimices                                                                                                                             |
| 411 |    181.847426 |    367.792322 | Tasman Dixon                                                                                                                                                   |
| 412 |   1015.114905 |    120.953083 | Gabriela Palomo-Munoz                                                                                                                                          |
| 413 |    517.980381 |    601.728125 | Christian A. Masnaghetti                                                                                                                                       |
| 414 |    665.756941 |    552.537733 | Matt Dempsey                                                                                                                                                   |
| 415 |    139.000109 |      7.002362 | NA                                                                                                                                                             |
| 416 |   1006.880693 |     24.270956 | Zimices                                                                                                                                                        |
| 417 |    229.710562 |    241.465822 | Shyamal                                                                                                                                                        |
| 418 |    483.342957 |    136.764788 | Martin R. Smith, from photo by Jürgen Schoner                                                                                                                  |
| 419 |    344.490617 |    628.666723 | Chris huh                                                                                                                                                      |
| 420 |    449.895239 |    736.292332 | Ferran Sayol                                                                                                                                                   |
| 421 |     71.120298 |     47.397455 | Christine Axon                                                                                                                                                 |
| 422 |     58.398556 |    254.944221 | Chris huh                                                                                                                                                      |
| 423 |    416.630646 |     17.426465 | Andy Wilson                                                                                                                                                    |
| 424 |    469.076937 |    359.027421 | Dean Schnabel                                                                                                                                                  |
| 425 |    710.149912 |    704.732606 | Michelle Site                                                                                                                                                  |
| 426 |    712.636694 |    528.390990 | Chris huh                                                                                                                                                      |
| 427 |    553.703535 |    175.921079 | Gareth Monger                                                                                                                                                  |
| 428 |    447.806915 |    596.439272 | Andy Wilson                                                                                                                                                    |
| 429 |    421.962524 |    778.587346 | Zimices                                                                                                                                                        |
| 430 |    301.828296 |    540.372552 | Dexter R. Mardis                                                                                                                                               |
| 431 |    991.480997 |    707.516555 | Oscar Sanisidro                                                                                                                                                |
| 432 |    383.796839 |    516.059969 | Matt Crook                                                                                                                                                     |
| 433 |    736.894118 |    212.128784 | Ben Moon                                                                                                                                                       |
| 434 |    738.297823 |    144.656843 | Juan Carlos Jerí                                                                                                                                               |
| 435 |    526.689054 |    501.698282 | Sarah Werning                                                                                                                                                  |
| 436 |    323.488733 |    359.207085 | Ferran Sayol                                                                                                                                                   |
| 437 |    410.302391 |    586.133256 | Emily Willoughby                                                                                                                                               |
| 438 |    484.631867 |    465.099142 | Caleb M. Brown                                                                                                                                                 |
| 439 |    132.467190 |    256.284811 | NA                                                                                                                                                             |
| 440 |    441.855841 |    165.060618 | Myriam\_Ramirez                                                                                                                                                |
| 441 |    769.204553 |    407.152767 | Margot Michaud                                                                                                                                                 |
| 442 |    137.588630 |    301.349106 | Zimices                                                                                                                                                        |
| 443 |    128.555299 |    211.750610 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 444 |    579.683618 |    665.108899 | Matt Crook                                                                                                                                                     |
| 445 |    526.607142 |    323.209528 | Meyers Konversations-Lexikon 1897 (vectorized: Yan Wong)                                                                                                       |
| 446 |    917.302273 |    490.382484 | Cristopher Silva                                                                                                                                               |
| 447 |    459.472157 |    761.819656 | DW Bapst (modified from Bulman, 1970)                                                                                                                          |
| 448 |    225.505977 |    785.814686 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                              |
| 449 |    885.571448 |    635.119143 | NA                                                                                                                                                             |
| 450 |    207.266282 |    505.619197 | Chris huh                                                                                                                                                      |
| 451 |    611.472811 |    125.214070 | Matt Crook                                                                                                                                                     |
| 452 |    953.410079 |    483.618400 | Lukasiniho                                                                                                                                                     |
| 453 |    540.657930 |    134.265690 | L. Shyamal                                                                                                                                                     |
| 454 |    319.271568 |    271.294158 | Inessa Voet                                                                                                                                                    |
| 455 |    465.233632 |    592.257727 | Jagged Fang Designs                                                                                                                                            |
| 456 |    585.628098 |    105.270841 | NA                                                                                                                                                             |
| 457 |    714.715694 |    684.490613 | Matt Crook                                                                                                                                                     |
| 458 |    712.831449 |    243.294979 | Jagged Fang Designs                                                                                                                                            |
| 459 |    972.973129 |    569.575575 | Matt Crook                                                                                                                                                     |
| 460 |    722.470289 |    159.558112 | Noah Schlottman, photo from Casey Dunn                                                                                                                         |
| 461 |    519.933196 |    533.944322 | NA                                                                                                                                                             |
| 462 |    151.422943 |    101.301922 | Gareth Monger                                                                                                                                                  |
| 463 |    215.341337 |    772.201601 | Tim H. Heupink, Leon Huynen, and David M. Lambert (vectorized by T. Michael Keesey)                                                                            |
| 464 |    960.857447 |    173.495311 | Chris huh                                                                                                                                                      |
| 465 |    897.341818 |    518.044905 | Margot Michaud                                                                                                                                                 |
| 466 |     36.689839 |     48.106695 | Jaime Headden                                                                                                                                                  |
| 467 |    558.938568 |    594.766354 | Danny Cicchetti (vectorized by T. Michael Keesey)                                                                                                              |
| 468 |    735.950863 |    300.975831 | Gabriela Palomo-Munoz                                                                                                                                          |
| 469 |    628.770975 |    564.580278 | E. R. Waite & H. M. Hale (vectorized by T. Michael Keesey)                                                                                                     |
| 470 |    189.384664 |    161.193728 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                       |
| 471 |    718.342696 |    301.891953 | Matt Crook                                                                                                                                                     |
| 472 |    319.819847 |    162.005796 | Cristina Guijarro                                                                                                                                              |
| 473 |    206.593572 |    710.107617 | Sharon Wegner-Larsen                                                                                                                                           |
| 474 |    371.426111 |    712.865725 | Jagged Fang Designs                                                                                                                                            |
| 475 |    950.769425 |    149.690455 | Gareth Monger                                                                                                                                                  |
| 476 |    541.508749 |    615.940842 | André Karwath (vectorized by T. Michael Keesey)                                                                                                                |
| 477 |    806.762280 |    698.285813 | Tasman Dixon                                                                                                                                                   |
| 478 |    941.451160 |    479.835554 | Tracy A. Heath                                                                                                                                                 |
| 479 |    709.194123 |    607.767319 | Margot Michaud                                                                                                                                                 |
| 480 |     20.383743 |    497.406042 | Kai R. Caspar                                                                                                                                                  |
| 481 |    560.418310 |    634.988606 | Matt Crook                                                                                                                                                     |
| 482 |    968.021276 |    411.949832 | NA                                                                                                                                                             |
| 483 |    348.996423 |    729.560434 | Ferran Sayol                                                                                                                                                   |
| 484 |    884.705835 |      9.101827 | NA                                                                                                                                                             |
| 485 |    613.212250 |    368.425149 | NA                                                                                                                                                             |
| 486 |    438.735078 |    305.154019 | T. Michael Keesey (after Heinrich Harder)                                                                                                                      |
| 487 |    176.610505 |     37.196402 | T. Michael Keesey                                                                                                                                              |
| 488 |    348.784346 |    675.866685 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                                  |
| 489 |     11.285369 |    534.224288 | Maxime Dahirel                                                                                                                                                 |
| 490 |    901.961322 |    680.615617 | Tasman Dixon                                                                                                                                                   |
| 491 |    257.432707 |    682.445154 | Matt Crook                                                                                                                                                     |
| 492 |    278.055408 |     44.532850 | Dexter R. Mardis                                                                                                                                               |
| 493 |    542.943852 |    495.461853 | Jagged Fang Designs                                                                                                                                            |
| 494 |    682.800157 |    198.252062 | Michael Scroggie                                                                                                                                               |
| 495 |    552.126232 |    607.418901 | Jagged Fang Designs                                                                                                                                            |
| 496 |    747.015203 |    282.435684 | Ben Liebeskind                                                                                                                                                 |
| 497 |    399.313405 |    380.506774 | Felix Vaux                                                                                                                                                     |
| 498 |      4.814477 |    514.476238 | Ferran Sayol                                                                                                                                                   |
| 499 |     63.763772 |    622.610953 | Margot Michaud                                                                                                                                                 |
| 500 |    630.067548 |    401.058636 | Julio Garza                                                                                                                                                    |
| 501 |    628.430458 |    313.537073 | Sarah Werning                                                                                                                                                  |
| 502 |     38.985692 |    589.427313 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 503 |    769.264349 |      8.063936 | Roule Jammes (vectorized by T. Michael Keesey)                                                                                                                 |
| 504 |     39.196542 |    334.776384 | Margot Michaud                                                                                                                                                 |
| 505 |   1012.102834 |    528.390518 | Melissa Broussard                                                                                                                                              |
| 506 |    998.742188 |    434.204362 | Markus A. Grohme                                                                                                                                               |
| 507 |    177.113082 |    708.869657 | Chris huh                                                                                                                                                      |
| 508 |    640.647438 |    139.446454 | Maija Karala                                                                                                                                                   |
| 509 |    154.642844 |    662.954701 | Mason McNair                                                                                                                                                   |
| 510 |    744.439606 |    347.043816 | Tauana J. Cunha                                                                                                                                                |
| 511 |    458.412315 |    301.593808 | Nobu Tamura, vectorized by Zimices                                                                                                                             |
| 512 |    735.043081 |    317.224416 | Cesar Julian                                                                                                                                                   |
| 513 |    441.504950 |    704.348643 | Gareth Monger                                                                                                                                                  |
| 514 |    309.256565 |    391.031060 | Gareth Monger                                                                                                                                                  |
| 515 |    951.183627 |    618.721513 | Birgit Lang                                                                                                                                                    |
| 516 |    523.077388 |      5.190348 | Steven Traver                                                                                                                                                  |
| 517 |    440.580122 |    389.552719 | Ferran Sayol                                                                                                                                                   |
| 518 |     66.240120 |    206.414907 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                                  |
| 519 |    215.138389 |    585.149877 | Matt Crook                                                                                                                                                     |
| 520 |    128.716838 |    206.994004 | Jagged Fang Designs                                                                                                                                            |
| 521 |    590.811301 |    566.296156 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                                    |
| 522 |    176.301895 |    794.020159 | Sarah Werning                                                                                                                                                  |
| 523 |   1000.990966 |    582.923875 | Noah Schlottman                                                                                                                                                |
| 524 |    968.126575 |    487.708163 | . Original drawing by M. Antón, published in Montoya and Morales 1984. Vectorized by O. Sanisidro                                                              |
| 525 |    713.244885 |    214.828030 | Maky (vectorization), Gabriella Skollar (photography), Rebecca Lewis (editing)                                                                                 |
| 526 |    633.103804 |    262.717078 | Remes K, Ortega F, Fierro I, Joger U, Kosma R, et al.                                                                                                          |
| 527 |    344.580868 |    486.487615 | Gabriela Palomo-Munoz                                                                                                                                          |
| 528 |    200.803680 |    498.656087 | Steven Blackwood                                                                                                                                               |
| 529 |    863.701993 |    430.796976 | Zimices                                                                                                                                                        |
| 530 |    138.012988 |    121.420570 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 531 |    634.105663 |    368.507066 | Sean McCann                                                                                                                                                    |
| 532 |    666.770413 |    199.410372 | Paul O. Lewis                                                                                                                                                  |
| 533 |    533.078204 |    142.566267 | Dexter R. Mardis                                                                                                                                               |
| 534 |    274.509350 |    140.245754 | Andy Wilson                                                                                                                                                    |
| 535 |     69.337225 |    180.232732 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 536 |    404.350840 |     87.570479 | Charles R. Knight (vectorized by T. Michael Keesey)                                                                                                            |
| 537 |   1013.858948 |    352.706709 | Michelle Site                                                                                                                                                  |
| 538 |    335.129489 |    163.801099 | Meliponicultor Itaymbere                                                                                                                                       |
| 539 |    589.697290 |    333.313116 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 540 |    198.993381 |    531.097204 | Maija Karala                                                                                                                                                   |
| 541 |     78.208171 |    250.159337 | Alex Slavenko                                                                                                                                                  |
| 542 |    795.101163 |    692.305674 | Markus A. Grohme                                                                                                                                               |
| 543 |    752.523482 |    533.643184 | Gabriel Lio, vectorized by Zimices                                                                                                                             |
| 544 |     39.510564 |    575.528991 | Melissa Broussard                                                                                                                                              |
| 545 |    153.475901 |    552.212526 | Zimices                                                                                                                                                        |
| 546 |    336.232267 |    353.194622 | Scott Reid                                                                                                                                                     |
| 547 |    822.554977 |    537.250121 | Archaeodontosaurus (vectorized by T. Michael Keesey)                                                                                                           |
| 548 |   1001.014324 |    570.174599 | Tasman Dixon                                                                                                                                                   |
| 549 |    435.796225 |    609.953726 | Scott Hartman                                                                                                                                                  |
| 550 |    644.101843 |    175.755943 | Gabriela Palomo-Munoz                                                                                                                                          |
| 551 |    322.933107 |    726.293546 | Chris huh                                                                                                                                                      |
| 552 |    697.064500 |    208.991460 | Steven Traver                                                                                                                                                  |
| 553 |    893.974903 |    234.456992 | Benjamint444                                                                                                                                                   |
| 554 |    507.185960 |    244.382476 | Sarah Werning                                                                                                                                                  |
| 555 |    197.812336 |    269.651212 | Tasman Dixon                                                                                                                                                   |
| 556 |    161.342434 |    373.257294 | Mathilde Cordellier                                                                                                                                            |
| 557 |    443.634072 |    797.488580 | Margot Michaud                                                                                                                                                 |
| 558 |      7.119484 |    320.281344 | J Levin W (illustration) and T. Michael Keesey (vectorization)                                                                                                 |
| 559 |    422.059523 |    505.719861 | Collin Gross                                                                                                                                                   |
| 560 |    513.829414 |     65.468868 | Francis de Laporte de Castelnau (vectorized by T. Michael Keesey)                                                                                              |
| 561 |    763.648712 |     48.712084 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                |
| 562 |    463.716873 |    182.819492 | Jagged Fang Designs                                                                                                                                            |
| 563 |    613.941934 |    114.389977 | Oren Peles / vectorized by Yan Wong                                                                                                                            |
| 564 |    546.409869 |      6.522079 | Alexander Schmidt-Lebuhn                                                                                                                                       |
| 565 |    464.983629 |    567.939788 | Smokeybjb, vectorized by Zimices                                                                                                                               |
| 566 |    188.196910 |    553.572149 | Ferran Sayol                                                                                                                                                   |
| 567 |    575.038370 |    153.551173 | Emily Willoughby                                                                                                                                               |
| 568 |    539.789337 |    228.483581 | NA                                                                                                                                                             |
| 569 |    742.530958 |    115.685447 | Brockhaus and Efron                                                                                                                                            |
| 570 |    322.693226 |    585.034284 | Dmitry Bogdanov, vectorized by Zimices                                                                                                                         |
| 571 |    111.316315 |    194.221780 | Gabriela Palomo-Munoz                                                                                                                                          |
| 572 |    968.865402 |    786.261319 | Zimices                                                                                                                                                        |
| 573 |    758.964098 |    339.565304 | Harold N Eyster                                                                                                                                                |
| 574 |    428.448048 |    624.990017 | Isaure Scavezzoni                                                                                                                                              |
| 575 |    658.227757 |    378.278042 | NA                                                                                                                                                             |
| 576 |     43.161430 |    525.981128 | Zimices                                                                                                                                                        |
| 577 |    473.715579 |    284.291572 | Kamil S. Jaron                                                                                                                                                 |
| 578 |    278.171112 |    748.590440 | Scott Hartman                                                                                                                                                  |
| 579 |    584.957359 |    173.932494 | Mareike C. Janiak                                                                                                                                              |
| 580 |    578.939830 |    341.559831 | Margot Michaud                                                                                                                                                 |
| 581 |    315.547659 |    483.354064 | Birgit Lang                                                                                                                                                    |
| 582 |    237.384616 |    361.104769 | Becky Barnes                                                                                                                                                   |
| 583 |    769.845513 |    131.112389 | NA                                                                                                                                                             |
| 584 |    166.630166 |    151.359528 | Scott Hartman                                                                                                                                                  |
| 585 |    683.089598 |     33.136081 | Michele M Tobias from an image By Dcrjsr - Own work, CC BY 3.0, <https://commons.wikimedia.org/w/index.php?curid=18059686>                                     |
| 586 |    879.549603 |    410.819795 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                              |
| 587 |    305.004264 |    754.462293 | \[unknown\]                                                                                                                                                    |
| 588 |    517.985342 |    555.222954 | Maija Karala                                                                                                                                                   |
| 589 |     49.916936 |     64.242246 | David Tana                                                                                                                                                     |
| 590 |    786.251157 |    213.303770 | Tasman Dixon                                                                                                                                                   |
| 591 |    968.786490 |    586.218405 | Kai R. Caspar                                                                                                                                                  |
| 592 |    350.654479 |    517.522818 | NA                                                                                                                                                             |
| 593 |    128.761358 |     41.571049 | Zimices                                                                                                                                                        |
| 594 |    745.498020 |    785.704226 | Gareth Monger                                                                                                                                                  |
| 595 |    158.516575 |    382.591760 | Markus A. Grohme                                                                                                                                               |
| 596 |    469.111983 |    320.881641 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 597 |    789.330091 |    420.925061 | Margot Michaud                                                                                                                                                 |
| 598 |    274.833938 |    209.011897 | C. Camilo Julián-Caballero                                                                                                                                     |
| 599 |    513.932054 |    231.111910 | Todd Marshall, vectorized by Zimices                                                                                                                           |
| 600 |    319.268841 |     96.829911 | Scott Hartman                                                                                                                                                  |
| 601 |    160.359920 |    712.026502 | NA                                                                                                                                                             |
| 602 |    313.595127 |    247.376205 | Andy Wilson                                                                                                                                                    |
| 603 |    390.290882 |      4.928130 | Roberto Díaz Sibaja                                                                                                                                            |
| 604 |    675.293154 |     57.681179 | Matt Wilkins (photo by Patrick Kavanagh)                                                                                                                       |
| 605 |    872.870424 |     12.407386 | Markus A. Grohme                                                                                                                                               |
| 606 |    134.190939 |     99.287389 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 607 |    970.004820 |    756.996369 | Rebecca Groom                                                                                                                                                  |
| 608 |    477.793743 |    260.892918 | Matt Crook                                                                                                                                                     |
| 609 |    129.737302 |    554.403677 | Arthur S. Brum                                                                                                                                                 |
| 610 |    620.184089 |    571.170634 | Ingo Braasch                                                                                                                                                   |
| 611 |    770.679523 |    314.674350 | Noah Schlottman, photo by Casey Dunn                                                                                                                           |
| 612 |    892.607551 |    576.293453 | Dean Schnabel                                                                                                                                                  |
| 613 |    967.597504 |    558.879716 | Lukasiniho                                                                                                                                                     |
| 614 |    335.469270 |    485.783962 | Gareth Monger                                                                                                                                                  |
| 615 |    629.978346 |    377.771545 | C. Camilo Julián-Caballero                                                                                                                                     |
| 616 |    589.979994 |    791.973596 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 617 |    596.678630 |     31.517876 | Gabriela Palomo-Munoz                                                                                                                                          |
| 618 |    421.646635 |    358.512375 | Mo Hassan                                                                                                                                                      |
| 619 |     55.665130 |    696.463210 | Kanchi Nanjo                                                                                                                                                   |
| 620 |    562.940397 |    770.770165 | Matt Crook                                                                                                                                                     |
| 621 |    416.919848 |    421.813574 | Scott Hartman                                                                                                                                                  |
| 622 |    495.560780 |    364.047533 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 623 |    781.141499 |    448.245958 | Ignacio Contreras                                                                                                                                              |
| 624 |    279.315135 |    684.863327 | Roberto Díaz Sibaja                                                                                                                                            |
| 625 |    602.642427 |     90.560742 | Matt Crook                                                                                                                                                     |
| 626 |    172.596249 |    488.909775 | C. Camilo Julián-Caballero                                                                                                                                     |
| 627 |    521.306874 |    608.182924 | Ignacio Contreras                                                                                                                                              |
| 628 |    626.187728 |    300.093747 | Margot Michaud                                                                                                                                                 |
| 629 |    999.758115 |    522.861315 | Zimices                                                                                                                                                        |
| 630 |    255.304818 |    674.155964 | Caleb M. Brown                                                                                                                                                 |
| 631 |    166.874182 |    269.293572 | Rebecca Groom                                                                                                                                                  |
| 632 |    217.121235 |    657.541650 | Ferran Sayol                                                                                                                                                   |
| 633 |    483.045523 |    765.894700 | Ferran Sayol                                                                                                                                                   |
| 634 |    835.151370 |    610.672849 | NA                                                                                                                                                             |
| 635 |    855.124647 |    383.012712 | Mali’o Kodis, image from Higgins and Kristensen, 1986                                                                                                          |
| 636 |    354.207042 |    548.340883 | Lauren Anderson                                                                                                                                                |
| 637 |    258.945835 |    140.402636 | Gareth Monger                                                                                                                                                  |
| 638 |    905.406695 |    322.505318 | Eric Moody                                                                                                                                                     |
| 639 |    363.988746 |    744.725437 | Jagged Fang Designs                                                                                                                                            |
| 640 |    526.102015 |    289.582733 | Ricardo Araújo                                                                                                                                                 |
| 641 |   1002.496847 |    438.834639 | NA                                                                                                                                                             |
| 642 |      9.123929 |    253.852524 | T. Michael Keesey (from a photograph by Frank Glaw, Jörn Köhler, Ted M. Townsend & Miguel Vences)                                                              |
| 643 |    163.550775 |    781.022236 | Jagged Fang Designs                                                                                                                                            |
| 644 |    505.039566 |     75.432910 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey        |
| 645 |    571.538028 |    435.227553 | Dmitry Bogdanov                                                                                                                                                |
| 646 |    941.403112 |    338.005092 | Steven Traver                                                                                                                                                  |
| 647 |    221.548691 |    596.165141 | Daniel Stadtmauer                                                                                                                                              |
| 648 |    579.991478 |    600.068073 | Matt Hayes                                                                                                                                                     |
| 649 |     86.502747 |    509.614369 | NA                                                                                                                                                             |
| 650 |    298.935256 |      5.302971 | Zimices                                                                                                                                                        |
| 651 |    115.615977 |    153.059305 | S.Martini                                                                                                                                                      |
| 652 |    611.203256 |     24.305131 | Scott Hartman                                                                                                                                                  |
| 653 |    452.760025 |    409.894748 | Margot Michaud                                                                                                                                                 |
| 654 |    948.575609 |    548.892970 | Noah Schlottman, photo by Antonio Guillén                                                                                                                      |
| 655 |    269.026959 |    222.574629 | Steven Traver                                                                                                                                                  |
| 656 |    445.549763 |    717.017434 | Hans Hillewaert                                                                                                                                                |
| 657 |    197.380931 |    415.722031 | Mali’o Kodis, photograph by Cordell Expeditions at Cal Academy                                                                                                 |
| 658 |    437.706838 |     83.710942 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                            |
| 659 |   1014.922234 |    257.662291 | Chris Jennings (vectorized by A. Verrière)                                                                                                                     |
| 660 |    603.094894 |     12.837116 | Matt Crook                                                                                                                                                     |
| 661 |    281.707139 |    787.266702 | T. Michael Keesey                                                                                                                                              |
| 662 |    417.782656 |    792.070250 | NA                                                                                                                                                             |
| 663 |    998.576999 |     12.125454 | Chris huh                                                                                                                                                      |
| 664 |    693.832418 |    571.983575 | Margot Michaud                                                                                                                                                 |
| 665 |    235.799692 |    593.716022 | Mattia Menchetti / Yan Wong                                                                                                                                    |
| 666 |    917.507603 |    518.797574 | T. Michael Keesey                                                                                                                                              |
| 667 |    696.381594 |    562.721804 | Markus A. Grohme                                                                                                                                               |
| 668 |     27.421018 |    566.890875 | Ferran Sayol                                                                                                                                                   |
| 669 |     90.801084 |    721.529011 | NA                                                                                                                                                             |
| 670 |    685.371640 |     51.710662 | Gareth Monger                                                                                                                                                  |
| 671 |    344.029170 |    124.433314 | Tasman Dixon                                                                                                                                                   |
| 672 |    129.770419 |    655.688148 | Michelle Site                                                                                                                                                  |
| 673 |    724.515481 |    784.267369 | Markus A. Grohme                                                                                                                                               |
| 674 |    242.448025 |    615.142311 | Tasman Dixon                                                                                                                                                   |
| 675 |    570.401115 |      3.164545 | Felix Vaux                                                                                                                                                     |
| 676 |    272.962065 |    307.685112 | Zimices                                                                                                                                                        |
| 677 |    266.830491 |    736.293330 | Gareth Monger                                                                                                                                                  |
| 678 |    233.973475 |    209.828828 | Tracy A. Heath                                                                                                                                                 |
| 679 |    582.179584 |    631.252020 | Birgit Lang                                                                                                                                                    |
| 680 |    610.549275 |    385.994900 | NA                                                                                                                                                             |
| 681 |    909.492258 |    482.200608 | Jagged Fang Designs                                                                                                                                            |
| 682 |    997.009522 |    669.131285 | Maxime Dahirel                                                                                                                                                 |
| 683 |    974.488326 |    323.657196 | T. Michael Keesey                                                                                                                                              |
| 684 |     12.612790 |    156.087204 | NA                                                                                                                                                             |
| 685 |    527.690272 |    555.987222 | Emily Willoughby                                                                                                                                               |
| 686 |    779.569327 |    195.237254 | xgirouxb                                                                                                                                                       |
| 687 |    305.693044 |    229.275561 | Matt Crook                                                                                                                                                     |
| 688 |    796.849744 |    248.735900 | Tasman Dixon                                                                                                                                                   |
| 689 |     60.600291 |    216.649566 | T. Michael Keesey                                                                                                                                              |
| 690 |    336.818839 |    139.659317 | Robert Gay                                                                                                                                                     |
| 691 |    665.096858 |     29.273193 | Raven Amos                                                                                                                                                     |
| 692 |    140.304029 |    566.983841 | Ignacio Contreras                                                                                                                                              |
| 693 |    335.551963 |    565.501952 | Birgit Lang                                                                                                                                                    |
| 694 |    107.963664 |    334.383105 | NA                                                                                                                                                             |
| 695 |    301.902707 |    587.071327 | FunkMonk                                                                                                                                                       |
| 696 |     58.230197 |    704.372122 | Jagged Fang Designs                                                                                                                                            |
| 697 |    120.049731 |    560.626201 | Chris huh                                                                                                                                                      |
| 698 |     10.454011 |    499.097677 | Yan Wong                                                                                                                                                       |
| 699 |    852.766863 |    631.329116 | Milton Tan                                                                                                                                                     |
| 700 |     64.520623 |    144.723988 | Ville-Veikko Sinkkonen                                                                                                                                         |
| 701 |     18.472741 |    786.928088 | Armin Reindl                                                                                                                                                   |
| 702 |    586.227080 |    141.423034 | Gareth Monger                                                                                                                                                  |
| 703 |    924.173573 |    295.132124 | NA                                                                                                                                                             |
| 704 |    859.381166 |    232.991244 | Andy Wilson                                                                                                                                                    |
| 705 |    495.512135 |    293.668437 | Rebecca Groom                                                                                                                                                  |
| 706 |    712.908081 |    577.279953 | Alex Slavenko                                                                                                                                                  |
| 707 |    292.184115 |    653.170409 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                            |
| 708 |    674.448936 |    560.367452 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                   |
| 709 |    113.435102 |    126.512012 | Evan-Amos (vectorized by T. Michael Keesey)                                                                                                                    |
| 710 |    145.000485 |    155.919390 | Walter Vladimir                                                                                                                                                |
| 711 |    741.615931 |    436.707078 | Scott Hartman                                                                                                                                                  |
| 712 |    504.954675 |    317.700694 | Trond R. Oskars                                                                                                                                                |
| 713 |    412.206820 |    275.330040 | Emily Willoughby                                                                                                                                               |
| 714 |    782.757554 |    241.560503 | C. W. Nash (illustration) and Timothy J. Bartley (silhouette)                                                                                                  |
| 715 |    376.180571 |    294.043588 | Gabriela Palomo-Munoz                                                                                                                                          |
| 716 |    811.748889 |    542.466769 | Dean Schnabel                                                                                                                                                  |
| 717 |    229.289841 |    686.626926 | Lafage                                                                                                                                                         |
| 718 |    306.295055 |    735.655441 | T. Michael Keesey                                                                                                                                              |
| 719 |    539.832992 |    664.329226 | Zimices                                                                                                                                                        |
| 720 |    599.559695 |    722.792677 | Zimices                                                                                                                                                        |
| 721 |    999.250915 |    635.021616 | Jaime Headden                                                                                                                                                  |
| 722 |    970.746890 |    339.686638 | Jack Mayer Wood                                                                                                                                                |
| 723 |    116.875603 |    102.023314 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                 |
| 724 |    306.870419 |    790.674456 | Zimices                                                                                                                                                        |
| 725 |    653.167666 |    793.276083 | NA                                                                                                                                                             |
| 726 |    215.850269 |    480.609136 | Erika Schumacher                                                                                                                                               |
| 727 |     54.480696 |    753.708586 | Chase Brownstein                                                                                                                                               |
| 728 |    341.156297 |    157.225867 | Kamil S. Jaron                                                                                                                                                 |
| 729 |    524.057889 |    397.097549 | FunkMonk                                                                                                                                                       |
| 730 |    527.307947 |     48.961751 | Steven Traver                                                                                                                                                  |
| 731 |    660.715248 |    707.249438 | Chris huh                                                                                                                                                      |
| 732 |     92.706024 |    336.364177 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey        |
| 733 |    233.523016 |    304.551404 | Erika Schumacher                                                                                                                                               |
| 734 |     22.496898 |    755.465629 | Zimices                                                                                                                                                        |
| 735 |    473.415498 |    340.784141 | Tasman Dixon                                                                                                                                                   |
| 736 |    175.637941 |    414.165607 | Matt Crook                                                                                                                                                     |
| 737 |    720.624285 |    628.962736 | Juan Carlos Jerí                                                                                                                                               |
| 738 |     14.025831 |    566.145930 | S.Martini                                                                                                                                                      |
| 739 |    637.712769 |    225.443941 | Ignacio Contreras                                                                                                                                              |
| 740 |    286.851052 |     57.803594 | Chris huh                                                                                                                                                      |
| 741 |    563.774363 |    546.410013 | Tasman Dixon                                                                                                                                                   |
| 742 |    609.691940 |    652.071284 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 743 |    460.482568 |    433.307572 | Julien Louys                                                                                                                                                   |
| 744 |    102.659228 |    219.647555 | Margot Michaud                                                                                                                                                 |
| 745 |    359.696281 |     85.187427 | Chris huh                                                                                                                                                      |
| 746 |    537.602561 |    344.229764 | Matt Celeskey                                                                                                                                                  |
| 747 |   1016.046182 |     10.755953 | xgirouxb                                                                                                                                                       |
| 748 |    235.684784 |    375.769253 | Harold N Eyster                                                                                                                                                |
| 749 |    698.889701 |    430.813921 | NA                                                                                                                                                             |
| 750 |    934.220602 |    309.641608 | Sarah Werning                                                                                                                                                  |
| 751 |    800.567601 |    797.514891 | Jagged Fang Designs                                                                                                                                            |
| 752 |    271.412689 |    260.011497 | Jay Matternes (vectorized by T. Michael Keesey)                                                                                                                |
| 753 |    429.859230 |     12.064614 | Smokeybjb (modified by Mike Keesey)                                                                                                                            |
| 754 |    334.903067 |    332.463828 | Tracy A. Heath                                                                                                                                                 |
| 755 |    150.090173 |    372.719449 | Margot Michaud                                                                                                                                                 |
| 756 |    657.210115 |    507.273017 | Roberto Díaz Sibaja                                                                                                                                            |
| 757 |     15.844687 |    607.534010 | Mattia Menchetti                                                                                                                                               |
| 758 |    839.812571 |    746.229763 | Tasman Dixon                                                                                                                                                   |
| 759 |    881.147979 |     83.336276 | Chris huh                                                                                                                                                      |
| 760 |    617.315858 |    266.298209 | NA                                                                                                                                                             |
| 761 |    692.888126 |    680.677806 | Jagged Fang Designs                                                                                                                                            |
| 762 |     58.798335 |    500.227898 | Alexandre Vong                                                                                                                                                 |
| 763 |    421.363920 |    660.031910 | Zimices                                                                                                                                                        |
| 764 |    885.376617 |    523.177370 | Juan Carlos Jerí                                                                                                                                               |
| 765 |    411.903804 |     72.887832 | Dr. Thomas G. Barnes, USFWS                                                                                                                                    |
| 766 |    247.452933 |    254.574308 | NA                                                                                                                                                             |
| 767 |    904.049157 |    424.437260 | Sharon Wegner-Larsen                                                                                                                                           |
| 768 |     39.880906 |    450.309522 | Nobu Tamura                                                                                                                                                    |
| 769 |    772.119425 |    566.573578 | Chuanixn Yu                                                                                                                                                    |
| 770 |    743.965570 |     92.220453 | david maas / dave hone                                                                                                                                         |
| 771 |    977.022314 |    772.340751 | Ignacio Contreras                                                                                                                                              |
| 772 |    143.685323 |     47.625082 | B. Duygu Özpolat                                                                                                                                               |
| 773 |     16.615679 |    645.910801 | Christoph Schomburg                                                                                                                                            |
| 774 |    920.186162 |    418.902974 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 775 |    742.282166 |     71.591685 | Michelle Site                                                                                                                                                  |
| 776 |    333.143868 |    775.752082 | Zimices                                                                                                                                                        |
| 777 |    996.774355 |    740.188079 | Margot Michaud                                                                                                                                                 |
| 778 |    638.010312 |     93.112546 | CNZdenek                                                                                                                                                       |
| 779 |    871.847080 |    676.142332 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 780 |    429.370887 |     25.311290 | Don Armstrong                                                                                                                                                  |
| 781 |    416.846554 |    309.774686 | Matt Crook                                                                                                                                                     |
| 782 |    164.360874 |    646.000951 | Philip Chalmers (vectorized by T. Michael Keesey)                                                                                                              |
| 783 |   1012.303847 |    148.983542 | Danielle Alba                                                                                                                                                  |
| 784 |    721.518122 |    655.208702 | Mathieu Pélissié                                                                                                                                               |
| 785 |    944.714129 |    197.050604 | Erika Schumacher                                                                                                                                               |
| 786 |    138.969927 |    641.597364 | Gareth Monger                                                                                                                                                  |
| 787 |    968.627609 |    303.526020 | xgirouxb                                                                                                                                                       |
| 788 |    977.914167 |    725.637996 | Ferran Sayol                                                                                                                                                   |
| 789 |    143.495549 |    145.009016 | Jake Warner                                                                                                                                                    |
| 790 |    454.493627 |    331.440470 | Scott Hartman (vectorized by T. Michael Keesey)                                                                                                                |
| 791 |    207.327207 |     67.606832 | Jakovche                                                                                                                                                       |
| 792 |    634.405288 |    115.696881 | Tracy A. Heath                                                                                                                                                 |
| 793 |    690.719942 |    555.395162 | Iain Reid                                                                                                                                                      |
| 794 |    657.972246 |    230.446128 | Noah Schlottman, photo by Adam G. Clause                                                                                                                       |
| 795 |     11.764116 |    553.413187 | Matt Martyniuk                                                                                                                                                 |
| 796 |    534.513381 |    509.073518 | Gareth Monger                                                                                                                                                  |
| 797 |    601.857664 |    243.270606 | FunkMonk                                                                                                                                                       |
| 798 |    616.333752 |    683.851900 | NA                                                                                                                                                             |
| 799 |   1013.634525 |    376.802380 | Lindberg (vectorized by T. Michael Keesey)                                                                                                                     |
| 800 |    230.246173 |    155.498293 | Martin R. Smith                                                                                                                                                |
| 801 |     32.807031 |     72.275255 | Francisco Manuel Blanco (vectorized by T. Michael Keesey)                                                                                                      |
| 802 |    897.089222 |    529.952434 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                                  |
| 803 |    415.138297 |     80.513332 | Blanco et al., 2014, vectorized by Zimices                                                                                                                     |
| 804 |    595.275284 |    443.177763 | Andy Wilson                                                                                                                                                    |
| 805 |    733.231945 |    357.629850 | Andy Wilson                                                                                                                                                    |
| 806 |    454.878406 |     81.819795 | Siobhon Egan                                                                                                                                                   |
| 807 |    387.098598 |    280.649537 | Matt Dempsey                                                                                                                                                   |
| 808 |      9.275849 |    740.473685 | Chris huh                                                                                                                                                      |
| 809 |    168.879369 |    447.054065 | Margot Michaud                                                                                                                                                 |
| 810 |    577.258154 |    445.600180 | Scott Hartman                                                                                                                                                  |
| 811 |    292.047264 |      8.385735 | Jagged Fang Designs                                                                                                                                            |
| 812 |    300.092442 |    200.320931 | Collin Gross                                                                                                                                                   |
| 813 |    395.089322 |    794.678143 | Andy Wilson                                                                                                                                                    |
| 814 |     61.897146 |    603.224177 | Gareth Monger                                                                                                                                                  |
| 815 |    631.518336 |    540.354161 | Sarah Werning                                                                                                                                                  |
| 816 |    812.404214 |    440.218908 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                                  |
| 817 |    121.000901 |     35.320840 | Zimices                                                                                                                                                        |
| 818 |    354.147806 |    662.621663 | Christoph Schomburg                                                                                                                                            |
| 819 |     81.806108 |    739.959641 | NA                                                                                                                                                             |
| 820 |    431.294079 |    343.863916 | Wayne Decatur                                                                                                                                                  |
| 821 |    612.852708 |    621.822676 | Zimices                                                                                                                                                        |
| 822 |    861.456950 |    715.898477 | Ferran Sayol                                                                                                                                                   |
| 823 |    926.161496 |    397.548415 | T. Michael Keesey (after Kukalová)                                                                                                                             |
| 824 |    898.448201 |     97.406042 | Jake Warner                                                                                                                                                    |
| 825 |    424.269429 |     89.027239 | Andrew A. Farke                                                                                                                                                |
| 826 |    344.734816 |    234.825311 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 827 |    606.164452 |    739.227046 | CNZdenek                                                                                                                                                       |
| 828 |    686.972702 |    522.579049 | T. Michael Keesey                                                                                                                                              |
| 829 |      9.930365 |    728.355351 | Zimices                                                                                                                                                        |
| 830 |    392.666858 |    696.585609 | (after Spotila 2004)                                                                                                                                           |
| 831 |    310.083090 |    155.643692 | Scott Hartman                                                                                                                                                  |
| 832 |    883.619216 |    350.798400 | Gareth Monger                                                                                                                                                  |
| 833 |    676.343427 |    128.177499 | Scott Hartman                                                                                                                                                  |
| 834 |    659.956887 |    516.529811 | Noah Schlottman                                                                                                                                                |
| 835 |    993.304215 |    129.159291 | Chris huh                                                                                                                                                      |
| 836 |    883.762731 |    362.743868 | Margot Michaud                                                                                                                                                 |
| 837 |    612.350950 |    179.910226 | Ludwik Gasiorowski                                                                                                                                             |
| 838 |   1007.041764 |    541.564835 | Andrew A. Farke                                                                                                                                                |
| 839 |    840.883750 |    562.802625 | Andy Wilson                                                                                                                                                    |
| 840 |    316.315368 |    402.536784 | Ignacio Contreras                                                                                                                                              |
| 841 |    583.478841 |    428.409047 | Louis Ranjard                                                                                                                                                  |
| 842 |    878.862671 |    725.332778 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                    |
| 843 |    523.180152 |    448.893079 | Gareth Monger                                                                                                                                                  |
| 844 |    720.155788 |    461.283003 | Christoph Schomburg                                                                                                                                            |
| 845 |    969.769808 |    739.680356 | NA                                                                                                                                                             |
| 846 |    660.075129 |    269.084806 | Chloé Schmidt                                                                                                                                                  |
| 847 |    692.858013 |    271.564195 | Martin R. Smith, from photo by Jürgen Schoner                                                                                                                  |
| 848 |    758.468841 |    164.943894 | Steven Traver                                                                                                                                                  |
| 849 |    660.217076 |    746.236090 | Natalie Claunch                                                                                                                                                |
| 850 |    537.857984 |    323.143778 | Harold N Eyster                                                                                                                                                |
| 851 |    298.074322 |    777.442826 | Jagged Fang Designs                                                                                                                                            |
| 852 |     88.956214 |    130.092227 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                  |
| 853 |    897.244174 |    739.654641 | Jaime Headden                                                                                                                                                  |
| 854 |    715.724382 |    717.108694 | Arthur Weasley (vectorized by T. Michael Keesey)                                                                                                               |
| 855 |    583.402853 |    120.602229 | Beth Reinke                                                                                                                                                    |
| 856 |    888.713873 |    198.436209 | Margot Michaud                                                                                                                                                 |
| 857 |    388.625338 |    176.777010 | Ignacio Contreras                                                                                                                                              |
| 858 |    753.216569 |    272.806025 | Andrew A. Farke                                                                                                                                                |
| 859 |    325.685586 |    706.408639 | Matt Crook                                                                                                                                                     |
| 860 |    261.316982 |    202.071355 | NA                                                                                                                                                             |
| 861 |    247.738769 |    726.693318 | Matt Crook                                                                                                                                                     |
| 862 |    657.672476 |    719.821781 | Birgit Lang                                                                                                                                                    |
| 863 |    935.480570 |    796.058301 | T. Michael Keesey (after Monika Betley)                                                                                                                        |
| 864 |    202.366997 |    282.979376 | A. R. McCulloch (vectorized by T. Michael Keesey)                                                                                                              |
| 865 |    838.379359 |    354.539498 | NA                                                                                                                                                             |
| 866 |    823.005962 |    745.765995 | Sarah Werning                                                                                                                                                  |
| 867 |    639.634635 |    500.308968 | Alexander Schmidt-Lebuhn                                                                                                                                       |
| 868 |    868.900636 |    484.809010 | Maija Karala                                                                                                                                                   |
| 869 |    607.006693 |    253.465022 | Margot Michaud                                                                                                                                                 |
| 870 |    122.209264 |    246.782778 | FunkMonk                                                                                                                                                       |
| 871 |    769.597952 |    595.027231 | NA                                                                                                                                                             |
| 872 |    760.114513 |    296.238392 | Smokeybjb                                                                                                                                                      |
| 873 |    106.213864 |    309.741865 | Chris huh                                                                                                                                                      |
| 874 |    282.124695 |    725.429037 | NA                                                                                                                                                             |
| 875 |   1016.976619 |    612.102516 | Robert Hering                                                                                                                                                  |
| 876 |    127.275286 |    741.968538 | Tracy A. Heath                                                                                                                                                 |
| 877 |    485.086592 |    458.092278 | Zimices                                                                                                                                                        |
| 878 |    704.136656 |    787.233977 | Mali’o Kodis, image from the Biodiversity Heritage Library                                                                                                     |
| 879 |    158.883232 |    539.205002 | Mihai Dragos (vectorized by T. Michael Keesey)                                                                                                                 |
| 880 |    819.245773 |    681.119870 | Steven Traver                                                                                                                                                  |
| 881 |    510.484582 |     51.456414 | L. Shyamal                                                                                                                                                     |
| 882 |    314.274855 |    492.647663 | Joanna Wolfe                                                                                                                                                   |
| 883 |    186.335209 |    652.221475 | Hanyong Pu, Yoshitsugu Kobayashi, Junchang Lü, Li Xu, Yanhua Wu, Huali Chang, Jiming Zhang, Songhai Jia & T. Michael Keesey                                    |
| 884 |    598.313536 |    135.151931 | Chris huh                                                                                                                                                      |
| 885 |    210.368136 |    795.318308 | T. Michael Keesey (after James & al.)                                                                                                                          |
| 886 |    436.030850 |    184.277804 | Yan Wong                                                                                                                                                       |
| 887 |    875.639913 |    743.055506 | Margot Michaud                                                                                                                                                 |
| 888 |    230.890504 |    728.634250 | Margot Michaud                                                                                                                                                 |
| 889 |    986.754798 |    628.240529 | Jagged Fang Designs                                                                                                                                            |
| 890 |    122.414888 |    500.031036 | Chris huh                                                                                                                                                      |
| 891 |    426.698007 |    277.794377 | Gareth Monger                                                                                                                                                  |
| 892 |    727.092800 |    328.292885 | Andreas Trepte (vectorized by T. Michael Keesey)                                                                                                               |
| 893 |    773.274431 |    615.644621 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                                    |
| 894 |   1005.989897 |    273.866952 | Terpsichores                                                                                                                                                   |
| 895 |    869.769784 |    374.962933 | Rene Martin                                                                                                                                                    |
| 896 |    680.630785 |    705.921370 | Margot Michaud                                                                                                                                                 |
| 897 |    984.988266 |     22.195208 | kreidefossilien.de                                                                                                                                             |
| 898 |    602.950222 |    629.130565 | Jim Bendon (photography) and T. Michael Keesey (vectorization)                                                                                                 |
| 899 |    155.590169 |    239.803337 | Markus A. Grohme                                                                                                                                               |
| 900 |    190.458766 |    732.334828 | NA                                                                                                                                                             |
| 901 |    290.863909 |     15.831736 | Nobu Tamura, vectorized by Zimices                                                                                                                             |
| 902 |    227.556603 |    477.015454 | Steven Coombs                                                                                                                                                  |
| 903 |     78.578452 |    599.823824 | Chris huh                                                                                                                                                      |
| 904 |    438.929669 |    348.895011 | Matt Crook                                                                                                                                                     |
| 905 |    543.690782 |    426.370770 | Shyamal                                                                                                                                                        |
| 906 |    751.413336 |    473.243456 | L. Shyamal                                                                                                                                                     |
| 907 |    608.302476 |    668.865116 | Felix Vaux and Steven A. Trewick                                                                                                                               |
| 908 |    423.711246 |    643.913285 | T. Michael Keesey                                                                                                                                              |
| 909 |    231.638559 |    677.816780 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 910 |    703.327417 |    767.013033 | Zimices                                                                                                                                                        |
| 911 |    571.727280 |    420.050647 | Zimices                                                                                                                                                        |
| 912 |    625.158844 |    415.123989 | Arthur Grosset (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |

    #> Your tweet has been posted!
