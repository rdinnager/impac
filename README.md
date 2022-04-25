
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

Jagged Fang Designs, Erika Schumacher, Scott Hartman, Andy Wilson, Sarah
Werning, Zimices, Margot Michaud, Matt Crook, Heinrich Harder
(vectorized by T. Michael Keesey), Steven Traver, Mattia Menchetti,
Terpsichores, Felix Vaux, Noah Schlottman, Nobu Tamura (vectorized by T.
Michael Keesey), Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric
M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus, Lily
Hughes, Sergio A. Muñoz-Gómez, Brian Gratwicke (photo) and T. Michael
Keesey (vectorization), L. Shyamal, Gareth Monger, Notafly (vectorized
by T. Michael Keesey), zoosnow, FunkMonk, Kent Elson Sorgon, Crystal
Maier, Sharon Wegner-Larsen, Emily Jane McTavish, from
<http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>,
Tyler Greenfield, Lafage, Pete Buchholz, Anilocra (vectorization by Yan
Wong), Rebecca Groom, John Conway, Kai R. Caspar, Yan Wong, S.Martini,
Timothy Knepp of the U.S. Fish and Wildlife Service (illustration) and
Timothy J. Bartley (silhouette), Smokeybjb, Chris huh, Mark Witton,
xgirouxb, T. Michael Keesey, Julie Blommaert based on photo by
Sofdrakou, Markus A. Grohme, Kamil S. Jaron, T. Michael Keesey (after C.
De Muizon), Inessa Voet, Ferran Sayol, Dean Schnabel, Andrés Sánchez, C.
Camilo Julián-Caballero, Arthur S. Brum, Jose Carlos Arenas-Monroy,
Maija Karala, Anthony Caravaggi, Alexander Schmidt-Lebuhn, Fernando
Carezzano, Birgit Lang, Emily Willoughby, Mason McNair, James Neenan,
Falconaumanni and T. Michael Keesey, Bob Goldstein, Vectorization:Jake
Warner, Craig Dylke, Michael B. H. (vectorized by T. Michael Keesey),
Matt Wilkins, Maxime Dahirel, Unknown (photo), John E. McCormack,
Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C.
Glenn, Robb T. Brumfield & T. Michael Keesey, Noah Schlottman, photo by
Museum of Geology, University of Tartu, Diego Fontaneto, Elisabeth A.
Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia
Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey),
Bennet McComish, photo by Hans Hillewaert, Steven Coombs, Gabriela
Palomo-Munoz, Robert Hering, Noah Schlottman, photo from Casey Dunn,
Pranav Iyer (grey ideas), T. Michael Keesey (vector) and Stuart Halliday
(photograph), Geoff Shaw, Joanna Wolfe, CNZdenek, Dmitry Bogdanov
(vectorized by T. Michael Keesey), Matus Valach, DW Bapst (Modified from
photograph taken by Charles Mitchell), Melissa Broussard, Kanchi Nanjo,
New York Zoological Society, Zimices, based in Mauricio Antón skeletal,
Beth Reinke, Nicolas Mongiardino Koch, Ghedoghedo (vectorized by T.
Michael Keesey), Juan Carlos Jerí, Iain Reid, Archaeodontosaurus
(vectorized by T. Michael Keesey), Tasman Dixon, Courtney Rockenbach, T.
Michael Keesey (vectorization) and Tony Hisgett (photography), Mathieu
Pélissié, Harold N Eyster, Benjamint444, Dein Freund der Baum
(vectorized by T. Michael Keesey), T. Tischler, Owen Jones, Amanda
Katzer, Xavier Giroux-Bougard, Oren Peles / vectorized by Yan Wong, Nobu
Tamura and T. Michael Keesey, George Edward Lodge (modified by T.
Michael Keesey), Original drawing by Antonov, vectorized by Roberto Díaz
Sibaja, Ignacio Contreras, Oscar Sanisidro, Jimmy Bernot, Robbie N. Cada
(vectorized by T. Michael Keesey), Yusan Yang, Darren Naish (vectorized
by T. Michael Keesey), Michelle Site, Collin Gross, Brad McFeeters
(vectorized by T. Michael Keesey), Ewald Rübsamen, Mette Aumala, Noah
Schlottman, photo by Reinhard Jahn, Mareike C. Janiak, Mathilde
Cordellier, Matt Martyniuk, Hans Hillewaert (photo) and T. Michael
Keesey (vectorization), Frank Förster (based on a picture by Hans
Hillewaert), Cagri Cevrim, Chuanixn Yu, Mali’o Kodis, drawing by Manvir
Singh, Jonathan Wells, Michael Scroggie, Mathew Wedel, Robert Gay,
Christoph Schomburg, Becky Barnes, Hans Hillewaert (vectorized by T.
Michael Keesey), Riccardo Percudani, Jan A. Venter, Herbert H. T. Prins,
David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey),
Obsidian Soul (vectorized by T. Michael Keesey), Andreas Preuss /
marauder, Vanessa Guerra, Madeleine Price Ball, B. Duygu Özpolat, Ingo
Braasch, Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz
Sibaja, Mr E? (vectorized by T. Michael Keesey), Shyamal, Jay Matternes,
vectorized by Zimices, E. D. Cope (modified by T. Michael Keesey,
Michael P. Taylor & Matthew J. Wedel), Robert Bruce Horsfall, vectorized
by Zimices, Christine Axon, Jon Hill (Photo by DickDaniels:
<http://en.wikipedia.org/wiki/File:Green_Woodhoopoe_RWD7.jpg>), Tracy A.
Heath, Liftarn, Pollyanna von Knorring and T. Michael Keesey, Carlos
Cano-Barbacil, Mali’o Kodis, photograph by Jim Vargo, Skye McDavid, Nobu
Tamura (modified by T. Michael Keesey), Jessica Anne Miller, Caleb M.
Brown, Tauana J. Cunha, Nicolas Huet le Jeune and Jean-Gabriel Prêtre
(vectorized by T. Michael Keesey), david maas / dave hone, Baheerathan
Murugavel, Didier Descouens (vectorized by T. Michael Keesey), Chloé
Schmidt, H. Filhol (vectorized by T. Michael Keesey), Dianne Bray /
Museum Victoria (vectorized by T. Michael Keesey), Walter Vladimir,
Steven Haddock • Jellywatch.org, RS, Mali’o Kodis, image from Brockhaus
and Efron Encyclopedic Dictionary, Matthew E. Clapham, Elisabeth Östman,
Michele M Tobias from an image By Dcrjsr - Own work, CC BY 3.0,
<https://commons.wikimedia.org/w/index.php?curid=18059686>, terngirl,
David Orr, Roberto Díaz Sibaja, Skye M, Espen Horn (model; vectorized by
T. Michael Keesey from a photo by H. Zell), Вальдимар (vectorized by T.
Michael Keesey), Josefine Bohr Brask, Smokeybjb, vectorized by Zimices,
Darren Naish (vectorize by T. Michael Keesey), Hugo Gruson, Matthew
Hooge (vectorized by T. Michael Keesey), Mariana Ruiz (vectorized by T.
Michael Keesey), Jan Sevcik (photo), John E. McCormack, Michael G.
Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb
T. Brumfield & T. Michael Keesey, Michele M Tobias, Verisimilus, Filip
em, M Kolmann, Jaime Headden, T. Michael Keesey (after MPF), Michael P.
Taylor, Alexandre Vong, Katie S. Collins, Jack Mayer Wood, FunkMonk
(Michael B. H.), Tony Ayling (vectorized by T. Michael Keesey), Nobu
Tamura, Andrew A. Farke, Emil Schmidt (vectorized by Maxime Dahirel),
Lukasiniho, Auckland Museum and T. Michael Keesey, Dinah Challen, Xavier
A. Jenkins, Gabriel Ugueto, Nobu Tamura, vectorized by Zimices, J. J.
Harrison (photo) & T. Michael Keesey, Julio Garza, FJDegrange, Alex
Slavenko, John Curtis (vectorized by T. Michael Keesey), Nicholas J.
Czaplewski, vectorized by Zimices, Joschua Knüppe, Jean-Raphaël
Guillaumin (photography) and T. Michael Keesey (vectorization), Tony
Ayling, Mali’o Kodis, photograph property of National Museums of
Northern Ireland, Conty (vectorized by T. Michael Keesey), Pearson Scott
Foresman (vectorized by T. Michael Keesey), Chris Hay, David Tana, White
Wolf, Andrew A. Farke, modified from original by Robert Bruce Horsfall,
from Scott 1912, Neil Kelley, Ludwik Gąsiorowski, DFoidl (vectorized by
T. Michael Keesey), Kevin Sánchez, Frederick William Frohawk (vectorized
by T. Michael Keesey), U.S. Fish and Wildlife Service (illustration) and
Timothy J. Bartley (silhouette), I. Sáček, Sr. (vectorized by T. Michael
Keesey), Andreas Trepte (vectorized by T. Michael Keesey), Jake Warner,
Ray Simpson (vectorized by T. Michael Keesey), Daniel Jaron, Matt
Dempsey, Todd Marshall, vectorized by Zimices, Ghedo and T. Michael
Keesey, Nina Skinner, T. Michael Keesey (after A. Y. Ivantsov), Danielle
Alba, NOAA Great Lakes Environmental Research Laboratory (illustration)
and Timothy J. Bartley (silhouette), Scott Reid, Maxwell Lefroy
(vectorized by T. Michael Keesey), Bruno Maggia, T. Michael Keesey (from
a photo by Maximilian Paradiz), Adrian Reich, Karla Martinez, Sebastian
Stabinger, Tyler McCraney, Original photo by Andrew Murray, vectorized
by Roberto Díaz Sibaja, Ben Liebeskind, Aviceda (photo) & T. Michael
Keesey, Christopher Chávez, Andrew A. Farke, modified from original by
H. Milne Edwards, Kanako Bessho-Uehara, Young and Zhao (1972:figure 4),
modified by Michael P. Taylor, Dmitry Bogdanov, Raven Amos, Ieuan Jones,
Michael Scroggie, from original photograph by Gary M. Stolz, USFWS
(original photograph in public domain)., DW Bapst, modified from Figure
1 of Belanger (2011, PALAIOS)., Mykle Hoban

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    733.020333 |     36.297812 | Jagged Fang Designs                                                                                                                                                   |
|   2 |     92.643152 |    627.842844 | Erika Schumacher                                                                                                                                                      |
|   3 |    366.343084 |    714.426918 | Scott Hartman                                                                                                                                                         |
|   4 |    441.793494 |    481.048748 | Andy Wilson                                                                                                                                                           |
|   5 |    603.959557 |    644.135032 | NA                                                                                                                                                                    |
|   6 |    201.576615 |    354.692564 | Sarah Werning                                                                                                                                                         |
|   7 |    158.560844 |    193.850698 | Zimices                                                                                                                                                               |
|   8 |    273.156425 |     83.136708 | Margot Michaud                                                                                                                                                        |
|   9 |    692.916839 |    300.334793 | Matt Crook                                                                                                                                                            |
|  10 |    862.787934 |    503.187926 | Margot Michaud                                                                                                                                                        |
|  11 |    894.449527 |     53.052268 | Heinrich Harder (vectorized by T. Michael Keesey)                                                                                                                     |
|  12 |    289.040772 |    592.589713 | Matt Crook                                                                                                                                                            |
|  13 |    440.259451 |    639.367924 | Steven Traver                                                                                                                                                         |
|  14 |    596.484652 |    777.098272 | Scott Hartman                                                                                                                                                         |
|  15 |    219.158783 |    741.409797 | Mattia Menchetti                                                                                                                                                      |
|  16 |    785.466716 |    677.246970 | Terpsichores                                                                                                                                                          |
|  17 |    432.877330 |    241.751098 | Felix Vaux                                                                                                                                                            |
|  18 |    823.045806 |    329.934012 | Noah Schlottman                                                                                                                                                       |
|  19 |    693.344278 |    156.681179 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  20 |    419.253335 |    394.346593 | Zimices                                                                                                                                                               |
|  21 |    627.153212 |     69.384005 | Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus                                              |
|  22 |     83.710391 |    512.421840 | Lily Hughes                                                                                                                                                           |
|  23 |    142.928603 |    420.239854 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
|  24 |    840.952904 |    605.988749 | NA                                                                                                                                                                    |
|  25 |    175.141124 |    516.818818 | Brian Gratwicke (photo) and T. Michael Keesey (vectorization)                                                                                                         |
|  26 |    906.102212 |    409.239894 | Steven Traver                                                                                                                                                         |
|  27 |    754.746679 |    217.453072 | Matt Crook                                                                                                                                                            |
|  28 |    612.203998 |    480.359745 | NA                                                                                                                                                                    |
|  29 |    948.524735 |    171.190591 | L. Shyamal                                                                                                                                                            |
|  30 |    328.196769 |    358.071605 | Gareth Monger                                                                                                                                                         |
|  31 |    512.981625 |    161.815030 | Sarah Werning                                                                                                                                                         |
|  32 |    371.129600 |     72.041895 | Notafly (vectorized by T. Michael Keesey)                                                                                                                             |
|  33 |     69.578081 |    728.799084 | zoosnow                                                                                                                                                               |
|  34 |    512.560191 |     38.132237 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  35 |    588.987764 |    225.671506 | FunkMonk                                                                                                                                                              |
|  36 |    250.208810 |    438.404054 | Zimices                                                                                                                                                               |
|  37 |    251.160534 |    268.515258 | Zimices                                                                                                                                                               |
|  38 |    539.532906 |    613.645983 | Gareth Monger                                                                                                                                                         |
|  39 |    385.681078 |    773.888515 | Kent Elson Sorgon                                                                                                                                                     |
|  40 |     97.209750 |     49.404522 | Matt Crook                                                                                                                                                            |
|  41 |    591.016509 |    353.025336 | Crystal Maier                                                                                                                                                         |
|  42 |    731.212679 |    451.893208 | Sharon Wegner-Larsen                                                                                                                                                  |
|  43 |    482.493649 |    320.442786 | Zimices                                                                                                                                                               |
|  44 |    147.442004 |     86.508944 | Margot Michaud                                                                                                                                                        |
|  45 |    688.195737 |    554.293532 | Emily Jane McTavish, from <http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>                                                           |
|  46 |     12.000644 |    668.843404 | Tyler Greenfield                                                                                                                                                      |
|  47 |    941.136986 |    638.564079 | NA                                                                                                                                                                    |
|  48 |    152.506898 |    252.223505 | Lafage                                                                                                                                                                |
|  49 |    110.432942 |    373.014496 | Steven Traver                                                                                                                                                         |
|  50 |    912.766370 |    750.492578 | Pete Buchholz                                                                                                                                                         |
|  51 |    960.740714 |    331.593469 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  52 |    385.797331 |    177.204556 | Jagged Fang Designs                                                                                                                                                   |
|  53 |    191.898166 |    693.626611 | Scott Hartman                                                                                                                                                         |
|  54 |    425.155568 |     68.963082 | Anilocra (vectorization by Yan Wong)                                                                                                                                  |
|  55 |    393.797274 |    572.950845 | Rebecca Groom                                                                                                                                                         |
|  56 |    582.509829 |    720.183535 | John Conway                                                                                                                                                           |
|  57 |    699.588632 |    368.116288 | Margot Michaud                                                                                                                                                        |
|  58 |     54.706736 |    260.688113 | Kai R. Caspar                                                                                                                                                         |
|  59 |    859.884056 |    157.723811 | Yan Wong                                                                                                                                                              |
|  60 |    481.891956 |    104.620503 | S.Martini                                                                                                                                                             |
|  61 |    738.678532 |     12.193220 | NA                                                                                                                                                                    |
|  62 |    718.365491 |     97.556905 | Gareth Monger                                                                                                                                                         |
|  63 |    996.564986 |    734.868009 | Felix Vaux                                                                                                                                                            |
|  64 |    246.252437 |    553.679703 | Felix Vaux                                                                                                                                                            |
|  65 |    927.569866 |    687.597294 | Scott Hartman                                                                                                                                                         |
|  66 |    822.405816 |    479.873921 | Timothy Knepp of the U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                |
|  67 |    665.458725 |    214.473553 | Smokeybjb                                                                                                                                                             |
|  68 |    954.412884 |    262.557502 | Chris huh                                                                                                                                                             |
|  69 |    954.758544 |    552.836271 | Scott Hartman                                                                                                                                                         |
|  70 |    157.378001 |    646.750280 | Rebecca Groom                                                                                                                                                         |
|  71 |    850.592059 |    718.660899 | Mark Witton                                                                                                                                                           |
|  72 |     71.122443 |    427.932612 | xgirouxb                                                                                                                                                              |
|  73 |    319.125613 |    651.409082 | T. Michael Keesey                                                                                                                                                     |
|  74 |    262.208661 |    171.032014 | Margot Michaud                                                                                                                                                        |
|  75 |    987.046186 |    430.030874 | Gareth Monger                                                                                                                                                         |
|  76 |    671.215441 |    638.052402 | Julie Blommaert based on photo by Sofdrakou                                                                                                                           |
|  77 |    837.366724 |    787.240448 | Markus A. Grohme                                                                                                                                                      |
|  78 |   1002.977325 |    524.353717 | NA                                                                                                                                                                    |
|  79 |    239.088049 |    470.624261 | Kamil S. Jaron                                                                                                                                                        |
|  80 |    190.919236 |    128.818945 | T. Michael Keesey (after C. De Muizon)                                                                                                                                |
|  81 |    988.688568 |    101.574531 | Inessa Voet                                                                                                                                                           |
|  82 |    734.890083 |    502.135084 | Ferran Sayol                                                                                                                                                          |
|  83 |    348.010930 |    284.947646 | Dean Schnabel                                                                                                                                                         |
|  84 |   1007.115492 |    583.806350 | Andrés Sánchez                                                                                                                                                        |
|  85 |    724.809675 |    774.364583 | C. Camilo Julián-Caballero                                                                                                                                            |
|  86 |    734.600334 |    790.782505 | Arthur S. Brum                                                                                                                                                        |
|  87 |    802.099424 |    117.551264 | Ferran Sayol                                                                                                                                                          |
|  88 |    952.210560 |    115.863009 | Zimices                                                                                                                                                               |
|  89 |    175.290060 |    284.793769 | Margot Michaud                                                                                                                                                        |
|  90 |    406.080661 |    303.383167 | Jose Carlos Arenas-Monroy                                                                                                                                             |
|  91 |    996.167925 |     20.643943 | Maija Karala                                                                                                                                                          |
|  92 |    138.158316 |    789.967120 | Steven Traver                                                                                                                                                         |
|  93 |    564.628818 |    177.961194 | Anthony Caravaggi                                                                                                                                                     |
|  94 |    450.355160 |    761.282032 | Dean Schnabel                                                                                                                                                         |
|  95 |    520.745643 |    701.103842 | Alexander Schmidt-Lebuhn                                                                                                                                              |
|  96 |    610.610640 |    249.789146 | Margot Michaud                                                                                                                                                        |
|  97 |    559.956860 |     95.618406 | Fernando Carezzano                                                                                                                                                    |
|  98 |    732.535804 |    743.115831 | Zimices                                                                                                                                                               |
|  99 |    338.051357 |    429.020292 | Jagged Fang Designs                                                                                                                                                   |
| 100 |    647.695649 |     36.201273 | Birgit Lang                                                                                                                                                           |
| 101 |    600.358828 |    187.793943 | Emily Willoughby                                                                                                                                                      |
| 102 |     51.914174 |    148.386232 | T. Michael Keesey                                                                                                                                                     |
| 103 |    182.407480 |    596.491223 | Matt Crook                                                                                                                                                            |
| 104 |    634.851459 |    289.202774 | Mason McNair                                                                                                                                                          |
| 105 |    274.003134 |     41.388167 | James Neenan                                                                                                                                                          |
| 106 |    206.566368 |     78.492139 | Falconaumanni and T. Michael Keesey                                                                                                                                   |
| 107 |     18.078978 |     48.554569 | Bob Goldstein, Vectorization:Jake Warner                                                                                                                              |
| 108 |    466.841942 |    687.588271 | Matt Crook                                                                                                                                                            |
| 109 |    670.030572 |    270.243735 | Craig Dylke                                                                                                                                                           |
| 110 |    750.411958 |    304.246418 | Matt Crook                                                                                                                                                            |
| 111 |    560.412186 |    528.963531 | Matt Crook                                                                                                                                                            |
| 112 |    981.601108 |    206.252730 | Chris huh                                                                                                                                                             |
| 113 |    896.889048 |    233.254906 | Michael B. H. (vectorized by T. Michael Keesey)                                                                                                                       |
| 114 |     82.736684 |    151.818932 | Matt Wilkins                                                                                                                                                          |
| 115 |     89.623754 |    784.212458 | Maxime Dahirel                                                                                                                                                        |
| 116 |    428.982062 |    139.308483 | NA                                                                                                                                                                    |
| 117 |    233.280056 |    327.142477 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
| 118 |    624.459837 |    119.808260 | Gareth Monger                                                                                                                                                         |
| 119 |    916.540980 |     79.433934 | Margot Michaud                                                                                                                                                        |
| 120 |    294.064850 |    494.795988 | Dean Schnabel                                                                                                                                                         |
| 121 |    457.996969 |    187.618651 | Noah Schlottman, photo by Museum of Geology, University of Tartu                                                                                                      |
| 122 |    567.271039 |    674.765777 | Scott Hartman                                                                                                                                                         |
| 123 |    139.047553 |    631.891158 | Matt Crook                                                                                                                                                            |
| 124 |    679.764093 |    748.579010 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 125 |    699.292846 |    336.754133 | Bennet McComish, photo by Hans Hillewaert                                                                                                                             |
| 126 |    615.942603 |    548.007973 | Mattia Menchetti                                                                                                                                                      |
| 127 |    376.814679 |    142.439754 | Jagged Fang Designs                                                                                                                                                   |
| 128 |    457.231555 |    649.511885 | Steven Coombs                                                                                                                                                         |
| 129 |    239.319950 |    682.548950 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 130 |    540.114985 |    577.232704 | Matt Crook                                                                                                                                                            |
| 131 |    288.628481 |    770.109203 | Robert Hering                                                                                                                                                         |
| 132 |    371.842137 |    677.646449 | Zimices                                                                                                                                                               |
| 133 |    813.393266 |     66.312110 | Noah Schlottman, photo from Casey Dunn                                                                                                                                |
| 134 |     60.119549 |    106.366350 | Pranav Iyer (grey ideas)                                                                                                                                              |
| 135 |    218.422393 |    719.430628 | T. Michael Keesey (vector) and Stuart Halliday (photograph)                                                                                                           |
| 136 |   1007.032075 |     59.670607 | Chris huh                                                                                                                                                             |
| 137 |    732.918482 |    661.283471 | Geoff Shaw                                                                                                                                                            |
| 138 |    216.715038 |    480.212987 | Margot Michaud                                                                                                                                                        |
| 139 |    813.939858 |    493.049880 | Chris huh                                                                                                                                                             |
| 140 |    632.424027 |    607.817770 | Joanna Wolfe                                                                                                                                                          |
| 141 |    309.662017 |    774.667436 | Anthony Caravaggi                                                                                                                                                     |
| 142 |    700.117147 |    633.903941 | Markus A. Grohme                                                                                                                                                      |
| 143 |     21.408270 |    151.495676 | CNZdenek                                                                                                                                                              |
| 144 |    482.988418 |    753.554785 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 145 |    635.147093 |    706.049528 | Matus Valach                                                                                                                                                          |
| 146 |    346.786279 |    614.215550 | DW Bapst (Modified from photograph taken by Charles Mitchell)                                                                                                         |
| 147 |    289.958214 |    240.597178 | Matt Crook                                                                                                                                                            |
| 148 |    365.849423 |    539.529026 | Melissa Broussard                                                                                                                                                     |
| 149 |    378.185853 |     45.029907 | Margot Michaud                                                                                                                                                        |
| 150 |    904.229201 |     11.664642 | Kanchi Nanjo                                                                                                                                                          |
| 151 |    797.334378 |    775.523291 | Smokeybjb                                                                                                                                                             |
| 152 |    521.151897 |    780.334442 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 153 |    219.979377 |    294.712470 | New York Zoological Society                                                                                                                                           |
| 154 |    755.372242 |    273.193840 | Zimices, based in Mauricio Antón skeletal                                                                                                                             |
| 155 |     59.637526 |     36.565923 | Sarah Werning                                                                                                                                                         |
| 156 |     40.510631 |    708.806107 | NA                                                                                                                                                                    |
| 157 |    442.859455 |    155.146119 | Joanna Wolfe                                                                                                                                                          |
| 158 |    719.288386 |    588.447315 | Beth Reinke                                                                                                                                                           |
| 159 |    281.320272 |    514.627038 | Jagged Fang Designs                                                                                                                                                   |
| 160 |     37.612344 |    672.247695 | Michael B. H. (vectorized by T. Michael Keesey)                                                                                                                       |
| 161 |    309.100526 |    391.318048 | Nicolas Mongiardino Koch                                                                                                                                              |
| 162 |    691.389286 |    181.337917 | Steven Traver                                                                                                                                                         |
| 163 |    264.471782 |    393.633718 | Birgit Lang                                                                                                                                                           |
| 164 |    729.886337 |    390.779949 | Matt Crook                                                                                                                                                            |
| 165 |    421.766061 |    181.331771 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 166 |    473.874646 |    545.327800 | Juan Carlos Jerí                                                                                                                                                      |
| 167 |    254.224501 |     34.165601 | Iain Reid                                                                                                                                                             |
| 168 |   1011.397770 |    651.557729 | Steven Traver                                                                                                                                                         |
| 169 |    123.728013 |    569.970985 | Zimices                                                                                                                                                               |
| 170 |    297.890833 |     17.232009 | Emily Willoughby                                                                                                                                                      |
| 171 |    378.218676 |    212.301433 | Fernando Carezzano                                                                                                                                                    |
| 172 |    670.516600 |    129.570665 | Zimices                                                                                                                                                               |
| 173 |    640.985105 |    676.862703 | Archaeodontosaurus (vectorized by T. Michael Keesey)                                                                                                                  |
| 174 |    263.548905 |    480.471145 | Zimices, based in Mauricio Antón skeletal                                                                                                                             |
| 175 |    917.747942 |    726.287418 | Andy Wilson                                                                                                                                                           |
| 176 |    724.177014 |    207.290368 | Tasman Dixon                                                                                                                                                          |
| 177 |     31.220946 |     30.457618 | Courtney Rockenbach                                                                                                                                                   |
| 178 |    888.491760 |    193.960459 | Margot Michaud                                                                                                                                                        |
| 179 |    651.600704 |    678.404353 | Kamil S. Jaron                                                                                                                                                        |
| 180 |    112.769947 |    151.889741 | Andy Wilson                                                                                                                                                           |
| 181 |    691.683130 |    348.409377 | NA                                                                                                                                                                    |
| 182 |    866.142637 |    424.140326 | Matt Crook                                                                                                                                                            |
| 183 |    547.363797 |    362.835730 | Timothy Knepp of the U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                |
| 184 |    810.315049 |    627.342154 | Jagged Fang Designs                                                                                                                                                   |
| 185 |    573.502140 |    162.373040 | Gareth Monger                                                                                                                                                         |
| 186 |    542.127772 |    400.506593 | Ferran Sayol                                                                                                                                                          |
| 187 |     16.120639 |    295.881884 | T. Michael Keesey                                                                                                                                                     |
| 188 |    674.247626 |    243.332924 | Sharon Wegner-Larsen                                                                                                                                                  |
| 189 |    318.804818 |     30.708728 | NA                                                                                                                                                                    |
| 190 |    626.057714 |     47.962815 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 191 |    277.425392 |    199.131874 | T. Michael Keesey (vectorization) and Tony Hisgett (photography)                                                                                                      |
| 192 |    225.969500 |    780.751869 | Zimices                                                                                                                                                               |
| 193 |    511.767405 |    747.146464 | Mathieu Pélissié                                                                                                                                                      |
| 194 |    323.563799 |    463.650124 | Harold N Eyster                                                                                                                                                       |
| 195 |     95.333221 |    576.770148 | Benjamint444                                                                                                                                                          |
| 196 |    721.339043 |    548.435651 | Matt Crook                                                                                                                                                            |
| 197 |    675.432328 |     65.677384 | Scott Hartman                                                                                                                                                         |
| 198 |    731.546645 |     62.680897 | FunkMonk                                                                                                                                                              |
| 199 |    762.592330 |    538.417504 | Dein Freund der Baum (vectorized by T. Michael Keesey)                                                                                                                |
| 200 |    538.823329 |    492.868426 | T. Tischler                                                                                                                                                           |
| 201 |    486.114116 |    351.541841 | T. Michael Keesey                                                                                                                                                     |
| 202 |     97.714310 |    299.837605 | Owen Jones                                                                                                                                                            |
| 203 |    494.056559 |    552.877110 | Harold N Eyster                                                                                                                                                       |
| 204 |    871.821580 |    695.783513 | Amanda Katzer                                                                                                                                                         |
| 205 |    325.036175 |    446.274411 | Xavier Giroux-Bougard                                                                                                                                                 |
| 206 |    680.922561 |    377.196467 | Oren Peles / vectorized by Yan Wong                                                                                                                                   |
| 207 |    648.301052 |    724.397700 | Tasman Dixon                                                                                                                                                          |
| 208 |    626.998972 |    585.571900 | Matt Crook                                                                                                                                                            |
| 209 |    884.939432 |    467.955142 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 210 |    811.795488 |     99.476619 | Nobu Tamura and T. Michael Keesey                                                                                                                                     |
| 211 |    112.997069 |    201.580380 | George Edward Lodge (modified by T. Michael Keesey)                                                                                                                   |
| 212 |    205.496432 |    143.837007 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 213 |    770.965356 |    417.603581 | Original drawing by Antonov, vectorized by Roberto Díaz Sibaja                                                                                                        |
| 214 |     72.092725 |    486.577402 | FunkMonk                                                                                                                                                              |
| 215 |    268.740731 |    782.455937 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 216 |    884.015369 |    120.527600 | Ignacio Contreras                                                                                                                                                     |
| 217 |    316.825669 |    285.811749 | Oscar Sanisidro                                                                                                                                                       |
| 218 |    151.099140 |    719.709172 | Markus A. Grohme                                                                                                                                                      |
| 219 |    562.239970 |    753.821900 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 220 |    955.176208 |     14.450385 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 221 |    817.152862 |    695.296864 | Jimmy Bernot                                                                                                                                                          |
| 222 |    824.673306 |    451.794409 | Matt Crook                                                                                                                                                            |
| 223 |    562.253023 |    689.330684 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
| 224 |     20.957918 |    119.892545 | Kamil S. Jaron                                                                                                                                                        |
| 225 |    650.559077 |    694.330858 | Yusan Yang                                                                                                                                                            |
| 226 |   1008.732344 |     84.139499 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 227 |    890.979183 |     75.881876 | Zimices                                                                                                                                                               |
| 228 |    292.626590 |    531.141914 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                        |
| 229 |     35.855824 |    502.516818 | Michelle Site                                                                                                                                                         |
| 230 |    650.723926 |    573.737651 | Steven Traver                                                                                                                                                         |
| 231 |    545.484748 |    249.118909 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 232 |    108.574508 |    236.569603 | Matt Crook                                                                                                                                                            |
| 233 |    694.495594 |    228.354847 | Felix Vaux                                                                                                                                                            |
| 234 |    290.829866 |    752.089704 | Collin Gross                                                                                                                                                          |
| 235 |    749.826615 |    649.549719 | Beth Reinke                                                                                                                                                           |
| 236 |    581.625981 |    545.495978 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 237 |    321.816601 |    499.311860 | Steven Traver                                                                                                                                                         |
| 238 |    302.288542 |    378.122273 | James Neenan                                                                                                                                                          |
| 239 |    270.835271 |    134.868179 | Scott Hartman                                                                                                                                                         |
| 240 |    161.618030 |    612.295272 | Ewald Rübsamen                                                                                                                                                        |
| 241 |    744.780006 |    322.472682 | Mette Aumala                                                                                                                                                          |
| 242 |    278.179926 |    659.107501 | Noah Schlottman, photo by Reinhard Jahn                                                                                                                               |
| 243 |   1009.785645 |    221.050927 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 244 |    234.832878 |    613.155694 | Mareike C. Janiak                                                                                                                                                     |
| 245 |    800.597645 |    144.933114 | Mathilde Cordellier                                                                                                                                                   |
| 246 |    206.891318 |    100.288199 | Matt Martyniuk                                                                                                                                                        |
| 247 |    686.526796 |    279.322032 | Scott Hartman                                                                                                                                                         |
| 248 |   1010.062980 |    288.137500 | Hans Hillewaert (photo) and T. Michael Keesey (vectorization)                                                                                                         |
| 249 |    626.986206 |    247.063032 | Lafage                                                                                                                                                                |
| 250 |    961.243596 |    525.944586 | Frank Förster (based on a picture by Hans Hillewaert)                                                                                                                 |
| 251 |    602.762590 |    413.612451 | Cagri Cevrim                                                                                                                                                          |
| 252 |    378.823020 |    657.064344 | Ignacio Contreras                                                                                                                                                     |
| 253 |     84.517657 |    706.115394 | Matt Crook                                                                                                                                                            |
| 254 |    316.156638 |    795.713518 | Chris huh                                                                                                                                                             |
| 255 |    768.123311 |    381.717327 | Zimices                                                                                                                                                               |
| 256 |    212.063898 |    383.993330 | Margot Michaud                                                                                                                                                        |
| 257 |    158.856628 |    754.257767 | xgirouxb                                                                                                                                                              |
| 258 |    246.405712 |    780.685853 | Chuanixn Yu                                                                                                                                                           |
| 259 |    578.240934 |    128.982490 | Maija Karala                                                                                                                                                          |
| 260 |    603.201882 |    562.834130 | Harold N Eyster                                                                                                                                                       |
| 261 |    191.702441 |    104.136774 | Margot Michaud                                                                                                                                                        |
| 262 |    922.295128 |    434.057907 | Mali’o Kodis, drawing by Manvir Singh                                                                                                                                 |
| 263 |    476.864316 |    699.431822 | Zimices                                                                                                                                                               |
| 264 |    893.725375 |    294.327056 | Zimices                                                                                                                                                               |
| 265 |    296.382077 |    444.976981 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 266 |    992.111057 |    234.547156 | Gareth Monger                                                                                                                                                         |
| 267 |     60.053326 |    722.683126 | Steven Traver                                                                                                                                                         |
| 268 |    564.614449 |     59.027456 | Inessa Voet                                                                                                                                                           |
| 269 |    981.152568 |    295.357606 | Nicolas Mongiardino Koch                                                                                                                                              |
| 270 |    344.671009 |    471.011801 | Jonathan Wells                                                                                                                                                        |
| 271 |    522.874297 |    567.193388 | Margot Michaud                                                                                                                                                        |
| 272 |      7.952862 |    184.478629 | NA                                                                                                                                                                    |
| 273 |    477.587550 |    206.936068 | NA                                                                                                                                                                    |
| 274 |      6.481056 |    408.881604 | NA                                                                                                                                                                    |
| 275 |    271.573417 |    524.623882 | Michael Scroggie                                                                                                                                                      |
| 276 |    503.193653 |    348.564240 | Tasman Dixon                                                                                                                                                          |
| 277 |    418.740492 |      6.062353 | Zimices                                                                                                                                                               |
| 278 |    572.198752 |    192.739936 | Mathew Wedel                                                                                                                                                          |
| 279 |    359.853694 |    340.493769 | Steven Traver                                                                                                                                                         |
| 280 |     56.356206 |    662.413672 | NA                                                                                                                                                                    |
| 281 |    574.689578 |    497.699815 | Matt Martyniuk                                                                                                                                                        |
| 282 |     71.803596 |    396.359403 | Margot Michaud                                                                                                                                                        |
| 283 |    437.176042 |    431.787972 | Robert Gay                                                                                                                                                            |
| 284 |    483.113025 |    375.996597 | Christoph Schomburg                                                                                                                                                   |
| 285 |    614.579661 |    178.723155 | Rebecca Groom                                                                                                                                                         |
| 286 |    516.230941 |    593.281972 | Rebecca Groom                                                                                                                                                         |
| 287 |    754.334449 |    397.760837 | Rebecca Groom                                                                                                                                                         |
| 288 |    335.495791 |    616.678442 | Matt Crook                                                                                                                                                            |
| 289 |    907.529416 |    543.342104 | Markus A. Grohme                                                                                                                                                      |
| 290 |    515.247399 |    214.427514 | Becky Barnes                                                                                                                                                          |
| 291 |    866.659829 |    665.963602 | Margot Michaud                                                                                                                                                        |
| 292 |    311.436128 |    200.872314 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 293 |    851.875518 |    222.666835 | Zimices                                                                                                                                                               |
| 294 |    268.482184 |    567.709767 | Gareth Monger                                                                                                                                                         |
| 295 |    319.848030 |    138.552607 | Riccardo Percudani                                                                                                                                                    |
| 296 |    653.840780 |    544.494836 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 297 |    404.921666 |    322.202085 | Riccardo Percudani                                                                                                                                                    |
| 298 |    750.481452 |    561.728826 | Scott Hartman                                                                                                                                                         |
| 299 |    799.699432 |     86.552457 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 300 |    384.473999 |    325.786901 | Gareth Monger                                                                                                                                                         |
| 301 |    217.818614 |    663.016232 | Gareth Monger                                                                                                                                                         |
| 302 |    919.788504 |    300.046415 | Andreas Preuss / marauder                                                                                                                                             |
| 303 |    605.432242 |    210.944170 | Emily Willoughby                                                                                                                                                      |
| 304 |     56.529973 |    574.211791 | Anthony Caravaggi                                                                                                                                                     |
| 305 |    235.286962 |    767.846846 | NA                                                                                                                                                                    |
| 306 |    446.358722 |    735.352218 | Scott Hartman                                                                                                                                                         |
| 307 |    559.518932 |    662.513118 | Vanessa Guerra                                                                                                                                                        |
| 308 |    485.263382 |    188.286694 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 309 |    504.601263 |    692.301474 | Mette Aumala                                                                                                                                                          |
| 310 |    157.916951 |    577.839411 | Madeleine Price Ball                                                                                                                                                  |
| 311 |     20.317049 |    395.864775 | B. Duygu Özpolat                                                                                                                                                      |
| 312 |     23.745266 |    601.069200 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
| 313 |    954.004889 |    577.309943 | Matt Martyniuk                                                                                                                                                        |
| 314 |    227.690572 |    351.304130 | Zimices                                                                                                                                                               |
| 315 |    202.166181 |    316.930233 | Ingo Braasch                                                                                                                                                          |
| 316 |    753.397731 |    709.677762 | Matt Crook                                                                                                                                                            |
| 317 |    818.233916 |    751.609713 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                                |
| 318 |     39.565970 |    391.143062 | Michael Scroggie                                                                                                                                                      |
| 319 |    239.300211 |     20.043650 | Mr E? (vectorized by T. Michael Keesey)                                                                                                                               |
| 320 |    388.493233 |      9.235828 | Shyamal                                                                                                                                                               |
| 321 |     31.920372 |    450.154514 | Jay Matternes, vectorized by Zimices                                                                                                                                  |
| 322 |    556.223194 |    509.466531 | Zimices                                                                                                                                                               |
| 323 |     27.270331 |    232.258543 | Gareth Monger                                                                                                                                                         |
| 324 |    167.491146 |    481.572550 | Chris huh                                                                                                                                                             |
| 325 |     41.779034 |    686.731268 | Shyamal                                                                                                                                                               |
| 326 |    655.705097 |    746.759714 | Zimices                                                                                                                                                               |
| 327 |    476.840495 |    272.210860 | Jonathan Wells                                                                                                                                                        |
| 328 |    848.758207 |    747.933015 | Melissa Broussard                                                                                                                                                     |
| 329 |    941.626228 |    289.855402 | E. D. Cope (modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel)                                                                                      |
| 330 |    742.400385 |    594.663372 | Steven Traver                                                                                                                                                         |
| 331 |    932.199293 |    231.027834 | NA                                                                                                                                                                    |
| 332 |    259.753676 |    187.058026 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                          |
| 333 |    980.987290 |    150.215838 | CNZdenek                                                                                                                                                              |
| 334 |    985.644869 |    568.997956 | Christine Axon                                                                                                                                                        |
| 335 |    576.441521 |    421.642161 | Matt Crook                                                                                                                                                            |
| 336 |    137.920369 |    718.013540 | Jon Hill (Photo by DickDaniels: <http://en.wikipedia.org/wiki/File:Green_Woodhoopoe_RWD7.jpg>)                                                                        |
| 337 |     31.783566 |    401.845568 | Birgit Lang                                                                                                                                                           |
| 338 |     67.578869 |    684.087877 | Birgit Lang                                                                                                                                                           |
| 339 |    261.932944 |    712.550754 | Tracy A. Heath                                                                                                                                                        |
| 340 |    669.615602 |    108.500550 | Gareth Monger                                                                                                                                                         |
| 341 |     47.291998 |    462.426021 | Margot Michaud                                                                                                                                                        |
| 342 |    214.386760 |    618.598081 | Matt Crook                                                                                                                                                            |
| 343 |    919.695703 |    580.225323 | Liftarn                                                                                                                                                               |
| 344 |    671.872683 |    717.484727 | Matt Crook                                                                                                                                                            |
| 345 |    219.218847 |    520.183041 | Pollyanna von Knorring and T. Michael Keesey                                                                                                                          |
| 346 |   1010.102370 |    276.563079 | Carlos Cano-Barbacil                                                                                                                                                  |
| 347 |     69.799589 |    119.496197 | Tasman Dixon                                                                                                                                                          |
| 348 |    384.440644 |    125.721022 | Mali’o Kodis, photograph by Jim Vargo                                                                                                                                 |
| 349 |    174.344342 |    473.482702 | Ferran Sayol                                                                                                                                                          |
| 350 |    806.464142 |    229.692720 | Skye McDavid                                                                                                                                                          |
| 351 |    396.272092 |     32.176474 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 352 |    394.590712 |    448.731734 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                           |
| 353 |    901.369437 |    589.448067 | Birgit Lang                                                                                                                                                           |
| 354 |   1009.236112 |    154.707363 | Jessica Anne Miller                                                                                                                                                   |
| 355 |    896.075720 |    445.535380 | Tracy A. Heath                                                                                                                                                        |
| 356 |     57.716277 |    126.597280 | Dean Schnabel                                                                                                                                                         |
| 357 |    640.070035 |    785.157743 | Caleb M. Brown                                                                                                                                                        |
| 358 |    672.781863 |    199.003407 | Carlos Cano-Barbacil                                                                                                                                                  |
| 359 |     17.270103 |     11.464517 | Tauana J. Cunha                                                                                                                                                       |
| 360 |    518.061048 |    521.646835 | Nicolas Huet le Jeune and Jean-Gabriel Prêtre (vectorized by T. Michael Keesey)                                                                                       |
| 361 |    545.653976 |    640.401218 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 362 |    173.490605 |    623.824195 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 363 |    219.651212 |    454.310253 | NA                                                                                                                                                                    |
| 364 |    221.979641 |    134.978480 | Kamil S. Jaron                                                                                                                                                        |
| 365 |    409.239124 |    750.901698 | Jagged Fang Designs                                                                                                                                                   |
| 366 |   1012.087375 |    184.919817 | Scott Hartman                                                                                                                                                         |
| 367 |    893.374140 |    421.344400 | Steven Traver                                                                                                                                                         |
| 368 |    277.347999 |    461.335499 | david maas / dave hone                                                                                                                                                |
| 369 |    286.438271 |      6.631629 | Margot Michaud                                                                                                                                                        |
| 370 |    986.181427 |    366.188746 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 371 |    769.364680 |    282.672860 | Emily Willoughby                                                                                                                                                      |
| 372 |    288.483775 |    731.989051 | Zimices                                                                                                                                                               |
| 373 |    315.273110 |    419.409164 | Chris huh                                                                                                                                                             |
| 374 |    991.308124 |    356.345950 | Gareth Monger                                                                                                                                                         |
| 375 |    711.334707 |    200.440675 | Baheerathan Murugavel                                                                                                                                                 |
| 376 |    799.019013 |    559.569413 | T. Michael Keesey                                                                                                                                                     |
| 377 |     24.875213 |    638.277146 | Tauana J. Cunha                                                                                                                                                       |
| 378 |    162.729165 |    565.153082 | Kai R. Caspar                                                                                                                                                         |
| 379 |    639.060713 |     20.104901 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 380 |    637.963673 |    364.308739 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 381 |    706.652936 |    760.196957 | Birgit Lang                                                                                                                                                           |
| 382 |    470.721340 |    788.785744 | Gareth Monger                                                                                                                                                         |
| 383 |    994.875439 |      7.225749 | Liftarn                                                                                                                                                               |
| 384 |    113.232316 |    760.667477 | Chloé Schmidt                                                                                                                                                         |
| 385 |     22.214633 |    277.783334 | Tracy A. Heath                                                                                                                                                        |
| 386 |    284.085149 |     20.543033 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 387 |    444.299976 |    124.141873 | Jagged Fang Designs                                                                                                                                                   |
| 388 |    475.891166 |    568.381892 | T. Michael Keesey                                                                                                                                                     |
| 389 |    343.664702 |    518.438615 | T. Michael Keesey                                                                                                                                                     |
| 390 |    290.842582 |    218.717969 | H. Filhol (vectorized by T. Michael Keesey)                                                                                                                           |
| 391 |    548.797161 |    414.029088 | Pete Buchholz                                                                                                                                                         |
| 392 |    279.246531 |    553.577390 | Tauana J. Cunha                                                                                                                                                       |
| 393 |    587.208302 |    270.972714 | Scott Hartman                                                                                                                                                         |
| 394 |    254.413700 |    113.994299 | Oren Peles / vectorized by Yan Wong                                                                                                                                   |
| 395 |    744.003969 |    193.290797 | Dianne Bray / Museum Victoria (vectorized by T. Michael Keesey)                                                                                                       |
| 396 |    263.544144 |     26.879722 | Walter Vladimir                                                                                                                                                       |
| 397 |    958.741578 |    151.328919 | Steven Haddock • Jellywatch.org                                                                                                                                       |
| 398 |    683.194931 |    256.596200 | Ferran Sayol                                                                                                                                                          |
| 399 |    687.181647 |    288.323605 | RS                                                                                                                                                                    |
| 400 |     26.010975 |    248.354560 | Ignacio Contreras                                                                                                                                                     |
| 401 |    905.995507 |    344.466698 | Gareth Monger                                                                                                                                                         |
| 402 |    913.952669 |    787.697348 | Tasman Dixon                                                                                                                                                          |
| 403 |    530.281545 |    667.869822 | Mali’o Kodis, image from Brockhaus and Efron Encyclopedic Dictionary                                                                                                  |
| 404 |    310.570588 |     22.233636 | Steven Traver                                                                                                                                                         |
| 405 |    461.503396 |    590.314223 | Zimices                                                                                                                                                               |
| 406 |    548.480754 |    326.704721 | Markus A. Grohme                                                                                                                                                      |
| 407 |    157.598312 |    795.828884 | Lafage                                                                                                                                                                |
| 408 |    416.368703 |    552.831017 | Jagged Fang Designs                                                                                                                                                   |
| 409 |    395.578192 |     60.013330 | Zimices                                                                                                                                                               |
| 410 |    993.349718 |    158.679898 | NA                                                                                                                                                                    |
| 411 |    506.569683 |    725.094322 | Markus A. Grohme                                                                                                                                                      |
| 412 |    734.999239 |    568.021706 | Steven Traver                                                                                                                                                         |
| 413 |    316.336186 |    250.170594 | Margot Michaud                                                                                                                                                        |
| 414 |    416.711282 |     23.042683 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 415 |     14.737057 |     32.178199 | Matt Crook                                                                                                                                                            |
| 416 |    739.115871 |    338.605960 | Andy Wilson                                                                                                                                                           |
| 417 |    656.877045 |    434.697839 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 418 |    675.012902 |     44.458179 | Matt Crook                                                                                                                                                            |
| 419 |    230.114159 |    760.601642 | Steven Traver                                                                                                                                                         |
| 420 |    151.687760 |    420.909313 | Markus A. Grohme                                                                                                                                                      |
| 421 |    321.047868 |    279.209746 | Chris huh                                                                                                                                                             |
| 422 |    854.560268 |    445.964111 | Zimices                                                                                                                                                               |
| 423 |    873.723265 |    226.966504 | Ingo Braasch                                                                                                                                                          |
| 424 |    971.891299 |    196.490049 | Markus A. Grohme                                                                                                                                                      |
| 425 |    320.854246 |    766.822861 | Matt Crook                                                                                                                                                            |
| 426 |     13.217596 |     71.605347 | Zimices                                                                                                                                                               |
| 427 |    602.814636 |     24.486517 | Matthew E. Clapham                                                                                                                                                    |
| 428 |    960.109078 |    765.308923 | Margot Michaud                                                                                                                                                        |
| 429 |    129.064680 |    270.842421 | Beth Reinke                                                                                                                                                           |
| 430 |    969.624965 |    786.598181 | Scott Hartman                                                                                                                                                         |
| 431 |    357.513992 |    671.911930 | Matt Crook                                                                                                                                                            |
| 432 |    549.845137 |    623.708579 | Fernando Carezzano                                                                                                                                                    |
| 433 |    208.746890 |    648.127096 | NA                                                                                                                                                                    |
| 434 |    297.597690 |    625.065497 | Zimices                                                                                                                                                               |
| 435 |    306.134849 |    736.793929 | Joanna Wolfe                                                                                                                                                          |
| 436 |     62.268655 |    697.072842 | Jagged Fang Designs                                                                                                                                                   |
| 437 |    493.675334 |    265.045957 | Gareth Monger                                                                                                                                                         |
| 438 |    517.233568 |    268.501176 | Elisabeth Östman                                                                                                                                                      |
| 439 |    780.750122 |    412.604263 | C. Camilo Julián-Caballero                                                                                                                                            |
| 440 |     32.133373 |     13.279092 | Ferran Sayol                                                                                                                                                          |
| 441 |     57.366182 |     53.685551 | Ferran Sayol                                                                                                                                                          |
| 442 |    554.239746 |    294.552502 | NA                                                                                                                                                                    |
| 443 |     29.159183 |    628.520289 | Rebecca Groom                                                                                                                                                         |
| 444 |    545.235043 |    140.323233 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 445 |    160.284378 |    624.813675 | Michele M Tobias from an image By Dcrjsr - Own work, CC BY 3.0, <https://commons.wikimedia.org/w/index.php?curid=18059686>                                            |
| 446 |    809.114941 |    445.646905 | terngirl                                                                                                                                                              |
| 447 |    368.027692 |     16.117361 | Collin Gross                                                                                                                                                          |
| 448 |    949.835302 |    232.228178 | Matt Crook                                                                                                                                                            |
| 449 |    792.301548 |    369.853162 | David Orr                                                                                                                                                             |
| 450 |    516.327138 |    411.502118 | NA                                                                                                                                                                    |
| 451 |    298.845431 |    275.286865 | Zimices                                                                                                                                                               |
| 452 |    890.054010 |    562.278550 | Maija Karala                                                                                                                                                          |
| 453 |    664.545725 |    255.481432 | L. Shyamal                                                                                                                                                            |
| 454 |    296.028207 |    359.722981 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 455 |    481.173406 |     57.301471 | Zimices                                                                                                                                                               |
| 456 |    535.902725 |    280.990519 | Ferran Sayol                                                                                                                                                          |
| 457 |   1012.437204 |    139.510165 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 458 |    636.718016 |    388.839089 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 459 |    214.982637 |    307.511245 | Roberto Díaz Sibaja                                                                                                                                                   |
| 460 |    300.226825 |    264.540364 | NA                                                                                                                                                                    |
| 461 |    526.909490 |    182.038569 | NA                                                                                                                                                                    |
| 462 |    805.862241 |    674.631446 | Skye M                                                                                                                                                                |
| 463 |     31.995381 |    580.750791 | Espen Horn (model; vectorized by T. Michael Keesey from a photo by H. Zell)                                                                                           |
| 464 |     60.937056 |    772.847930 | Вальдимар (vectorized by T. Michael Keesey)                                                                                                                           |
| 465 |    294.824824 |    471.061659 | Anthony Caravaggi                                                                                                                                                     |
| 466 |    766.761327 |    460.194196 | Steven Traver                                                                                                                                                         |
| 467 |    988.394290 |    215.759344 | Iain Reid                                                                                                                                                             |
| 468 |    642.781864 |    555.135027 | Josefine Bohr Brask                                                                                                                                                   |
| 469 |    689.736882 |    411.036739 | Matt Crook                                                                                                                                                            |
| 470 |    890.143650 |    219.789414 | Steven Coombs                                                                                                                                                         |
| 471 |    632.005059 |    343.180729 | Robert Hering                                                                                                                                                         |
| 472 |    620.599706 |     22.637539 | Smokeybjb, vectorized by Zimices                                                                                                                                      |
| 473 |    578.901018 |    154.391366 | Rebecca Groom                                                                                                                                                         |
| 474 |    598.055516 |    115.901675 | Margot Michaud                                                                                                                                                        |
| 475 |   1001.650111 |    173.099746 | Mathilde Cordellier                                                                                                                                                   |
| 476 |    221.598175 |    583.837480 | Terpsichores                                                                                                                                                          |
| 477 |    801.753427 |    745.481220 | Sarah Werning                                                                                                                                                         |
| 478 |    425.435418 |    532.465170 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                         |
| 479 |    342.279552 |     63.145399 | Beth Reinke                                                                                                                                                           |
| 480 |    315.686811 |    185.346933 | Hugo Gruson                                                                                                                                                           |
| 481 |    659.849328 |    599.991967 | Yan Wong                                                                                                                                                              |
| 482 |    323.297041 |    269.752258 | Matthew Hooge (vectorized by T. Michael Keesey)                                                                                                                       |
| 483 |    832.707359 |    668.020710 | Ignacio Contreras                                                                                                                                                     |
| 484 |    924.683657 |    251.345801 | Steven Coombs                                                                                                                                                         |
| 485 |    772.523505 |     74.225607 | Zimices                                                                                                                                                               |
| 486 |    182.362525 |    561.732879 | Markus A. Grohme                                                                                                                                                      |
| 487 |    598.073930 |    734.637911 | Gareth Monger                                                                                                                                                         |
| 488 |    171.709808 |    573.542056 | Christine Axon                                                                                                                                                        |
| 489 |    546.804067 |     97.377385 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
| 490 |    649.006890 |    103.057614 | Chris huh                                                                                                                                                             |
| 491 |    627.978197 |    379.461408 | Chris huh                                                                                                                                                             |
| 492 |    774.830558 |    233.605033 | Kamil S. Jaron                                                                                                                                                        |
| 493 |    888.941686 |    319.559709 | Zimices                                                                                                                                                               |
| 494 |     92.720865 |    663.457365 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 495 |   1011.759476 |      7.948298 | Mariana Ruiz (vectorized by T. Michael Keesey)                                                                                                                        |
| 496 |    862.465794 |    644.983560 | Gareth Monger                                                                                                                                                         |
| 497 |    585.902172 |     19.527231 | Emily Willoughby                                                                                                                                                      |
| 498 |    619.106245 |    756.272252 | Jan Sevcik (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey            |
| 499 |    261.633915 |    354.325037 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 500 |    635.296000 |    756.982036 | Scott Hartman                                                                                                                                                         |
| 501 |    882.584831 |    246.584508 | Zimices                                                                                                                                                               |
| 502 |    204.563690 |     27.211831 | Felix Vaux                                                                                                                                                            |
| 503 |    357.716217 |    387.744043 | T. Michael Keesey                                                                                                                                                     |
| 504 |    543.879653 |     69.946575 | Mathew Wedel                                                                                                                                                          |
| 505 |    520.870773 |    751.289522 | L. Shyamal                                                                                                                                                            |
| 506 |     78.867886 |    129.263639 | Michele M Tobias                                                                                                                                                      |
| 507 |    937.130265 |    793.907828 | Steven Traver                                                                                                                                                         |
| 508 |    654.294010 |    379.404304 | Ferran Sayol                                                                                                                                                          |
| 509 |     82.220903 |    261.358640 | Becky Barnes                                                                                                                                                          |
| 510 |    544.156928 |    136.936764 | Ignacio Contreras                                                                                                                                                     |
| 511 |    593.708555 |    134.605339 | Verisimilus                                                                                                                                                           |
| 512 |    250.155425 |    663.021598 | Filip em                                                                                                                                                              |
| 513 |    644.857115 |    221.249377 | Kanchi Nanjo                                                                                                                                                          |
| 514 |    232.475598 |    711.867373 | Gareth Monger                                                                                                                                                         |
| 515 |    629.498050 |    314.430723 | Steven Coombs                                                                                                                                                         |
| 516 |    973.145096 |    723.478182 | C. Camilo Julián-Caballero                                                                                                                                            |
| 517 |    764.983855 |     31.977441 | Ignacio Contreras                                                                                                                                                     |
| 518 |    653.614213 |    116.880761 | Matt Crook                                                                                                                                                            |
| 519 |    206.309314 |    119.044230 | M Kolmann                                                                                                                                                             |
| 520 |    767.459258 |    182.770051 | NA                                                                                                                                                                    |
| 521 |     20.201499 |    682.241150 | Jaime Headden                                                                                                                                                         |
| 522 |    839.464056 |     96.718363 | Zimices                                                                                                                                                               |
| 523 |     31.125080 |    294.633415 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 524 |    943.725980 |    434.544402 | xgirouxb                                                                                                                                                              |
| 525 |      7.010122 |    202.830103 | T. Michael Keesey (after MPF)                                                                                                                                         |
| 526 |    826.621961 |     80.172343 | FunkMonk                                                                                                                                                              |
| 527 |    498.393985 |    448.021967 | Tasman Dixon                                                                                                                                                          |
| 528 |    100.752227 |    487.561184 | Michelle Site                                                                                                                                                         |
| 529 |    499.121574 |    221.392734 | T. Michael Keesey                                                                                                                                                     |
| 530 |   1016.208134 |    794.935595 | Michael P. Taylor                                                                                                                                                     |
| 531 |    330.633801 |    754.235844 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 532 |    791.342066 |    731.718411 | Alexandre Vong                                                                                                                                                        |
| 533 |    207.250729 |    227.155172 | Katie S. Collins                                                                                                                                                      |
| 534 |    403.078597 |      8.840987 | Amanda Katzer                                                                                                                                                         |
| 535 |    809.580187 |    210.656179 | NA                                                                                                                                                                    |
| 536 |    644.937027 |    275.781362 | Jaime Headden                                                                                                                                                         |
| 537 |    329.582203 |     10.770912 | David Orr                                                                                                                                                             |
| 538 |    663.884097 |    292.122363 | Jagged Fang Designs                                                                                                                                                   |
| 539 |    334.454056 |    286.333418 | Kai R. Caspar                                                                                                                                                         |
| 540 |    877.632165 |    260.325315 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 541 |    554.654756 |    279.184892 | Margot Michaud                                                                                                                                                        |
| 542 |    955.090692 |    198.520824 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 543 |    421.448410 |    209.684332 | Jack Mayer Wood                                                                                                                                                       |
| 544 |    335.961941 |    143.594471 | Gareth Monger                                                                                                                                                         |
| 545 |    537.962369 |    372.945856 | Roberto Díaz Sibaja                                                                                                                                                   |
| 546 |    541.109433 |    146.667840 | FunkMonk (Michael B. H.)                                                                                                                                              |
| 547 |    297.248169 |    318.715822 | Maija Karala                                                                                                                                                          |
| 548 |    927.842075 |    423.599818 | Gareth Monger                                                                                                                                                         |
| 549 |    432.030636 |    284.068817 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 550 |     15.302318 |    161.279930 | NA                                                                                                                                                                    |
| 551 |    813.605928 |    745.426819 | Mathilde Cordellier                                                                                                                                                   |
| 552 |    115.703732 |    470.788002 | Heinrich Harder (vectorized by T. Michael Keesey)                                                                                                                     |
| 553 |    739.885044 |    127.798626 | Dean Schnabel                                                                                                                                                         |
| 554 |    143.486156 |    410.861004 | Zimices                                                                                                                                                               |
| 555 |     27.900417 |    199.425855 | T. Michael Keesey                                                                                                                                                     |
| 556 |    230.199252 |    157.629278 | Matt Crook                                                                                                                                                            |
| 557 |    366.623105 |    732.890091 | Nobu Tamura                                                                                                                                                           |
| 558 |    571.346333 |    143.140947 | Zimices                                                                                                                                                               |
| 559 |     28.242294 |    208.463888 | Collin Gross                                                                                                                                                          |
| 560 |    677.773961 |    101.360122 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 561 |    744.614783 |     31.040671 | Andy Wilson                                                                                                                                                           |
| 562 |    670.063950 |    396.374134 | Matt Crook                                                                                                                                                            |
| 563 |    653.746570 |    421.995513 | Zimices                                                                                                                                                               |
| 564 |     53.205490 |    357.181901 | Jagged Fang Designs                                                                                                                                                   |
| 565 |    261.277858 |     53.963544 | NA                                                                                                                                                                    |
| 566 |    989.362129 |     69.766507 | Scott Hartman                                                                                                                                                         |
| 567 |    350.262431 |    220.968208 | Tasman Dixon                                                                                                                                                          |
| 568 |    180.723451 |    791.212135 | Zimices                                                                                                                                                               |
| 569 |    540.965960 |    266.919673 | Ingo Braasch                                                                                                                                                          |
| 570 |    680.345217 |    698.393103 | NA                                                                                                                                                                    |
| 571 |    388.556415 |    606.609730 | Collin Gross                                                                                                                                                          |
| 572 |   1013.123402 |    338.876522 | Crystal Maier                                                                                                                                                         |
| 573 |    723.815887 |    571.512509 | NA                                                                                                                                                                    |
| 574 |     10.367035 |    265.345039 | Zimices                                                                                                                                                               |
| 575 |     77.309157 |    170.419822 | Noah Schlottman, photo by Reinhard Jahn                                                                                                                               |
| 576 |    975.636988 |    460.825502 | Zimices                                                                                                                                                               |
| 577 |     26.242339 |    469.527181 | Steven Traver                                                                                                                                                         |
| 578 |    566.359838 |    112.129143 | Ferran Sayol                                                                                                                                                          |
| 579 |     75.478730 |    389.687642 | Zimices                                                                                                                                                               |
| 580 |    959.545297 |    505.091238 | Tracy A. Heath                                                                                                                                                        |
| 581 |    989.539428 |    676.406426 | Andrew A. Farke                                                                                                                                                       |
| 582 |    573.598201 |     99.800978 | T. Michael Keesey                                                                                                                                                     |
| 583 |    649.353054 |    399.255820 | Andy Wilson                                                                                                                                                           |
| 584 |    599.927041 |    425.803274 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 585 |    292.455954 |    381.718711 | Jagged Fang Designs                                                                                                                                                   |
| 586 |    526.149043 |    598.393840 | Emil Schmidt (vectorized by Maxime Dahirel)                                                                                                                           |
| 587 |    896.549618 |    153.364020 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 588 |    453.100976 |    720.710582 | Lukasiniho                                                                                                                                                            |
| 589 |    492.464023 |    778.110735 | Katie S. Collins                                                                                                                                                      |
| 590 |    684.629303 |    787.585713 | Matt Crook                                                                                                                                                            |
| 591 |    704.323614 |    469.221543 | Zimices                                                                                                                                                               |
| 592 |     79.928804 |    547.344906 | NA                                                                                                                                                                    |
| 593 |    306.827014 |     47.136545 | Margot Michaud                                                                                                                                                        |
| 594 |    446.799949 |    599.400865 | Smokeybjb                                                                                                                                                             |
| 595 |    208.383543 |    605.538749 | Auckland Museum and T. Michael Keesey                                                                                                                                 |
| 596 |    812.632412 |    165.774206 | Margot Michaud                                                                                                                                                        |
| 597 |    398.660624 |    663.036357 | T. Michael Keesey                                                                                                                                                     |
| 598 |    500.963272 |     70.363287 | Dinah Challen                                                                                                                                                         |
| 599 |     34.418900 |      5.581539 | Jack Mayer Wood                                                                                                                                                       |
| 600 |    579.697781 |     14.181385 | Jagged Fang Designs                                                                                                                                                   |
| 601 |    540.413111 |    173.400536 | Erika Schumacher                                                                                                                                                      |
| 602 |    687.971720 |    755.154101 | Margot Michaud                                                                                                                                                        |
| 603 |     36.825807 |    720.075985 | Xavier A. Jenkins, Gabriel Ugueto                                                                                                                                     |
| 604 |    281.231334 |    709.066076 | Ferran Sayol                                                                                                                                                          |
| 605 |    308.380470 |    359.527902 | Matt Wilkins                                                                                                                                                          |
| 606 |    545.668162 |    381.045266 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 607 |    222.540409 |    202.735847 | Matt Crook                                                                                                                                                            |
| 608 |    305.023806 |    119.170719 | J. J. Harrison (photo) & T. Michael Keesey                                                                                                                            |
| 609 |    352.441205 |    362.514979 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                          |
| 610 |    416.365901 |    593.643648 | Terpsichores                                                                                                                                                          |
| 611 |    352.679918 |    451.155722 | Scott Hartman                                                                                                                                                         |
| 612 |    302.854214 |     35.330959 | Michelle Site                                                                                                                                                         |
| 613 |    290.515286 |    759.756728 | Zimices                                                                                                                                                               |
| 614 |    213.360789 |    562.508703 | Steven Traver                                                                                                                                                         |
| 615 |    818.320949 |    737.774248 | Julio Garza                                                                                                                                                           |
| 616 |    129.938363 |    737.541147 | NA                                                                                                                                                                    |
| 617 |    809.561817 |      4.856892 | Sarah Werning                                                                                                                                                         |
| 618 |    569.156362 |    733.062869 | Tasman Dixon                                                                                                                                                          |
| 619 |    966.054583 |    140.363351 | Xavier Giroux-Bougard                                                                                                                                                 |
| 620 |    749.273738 |    498.433437 | FJDegrange                                                                                                                                                            |
| 621 |    480.261152 |    143.780493 | Alex Slavenko                                                                                                                                                         |
| 622 |    414.811526 |    675.556473 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
| 623 |     91.636711 |    197.154259 | Gareth Monger                                                                                                                                                         |
| 624 |    271.121618 |    679.499783 | John Curtis (vectorized by T. Michael Keesey)                                                                                                                         |
| 625 |    378.957542 |    673.524640 | Matthew Hooge (vectorized by T. Michael Keesey)                                                                                                                       |
| 626 |    347.005336 |    434.546418 | Ferran Sayol                                                                                                                                                          |
| 627 |    183.407782 |    546.656657 | Joanna Wolfe                                                                                                                                                          |
| 628 |   1008.279809 |    613.292085 | NA                                                                                                                                                                    |
| 629 |    313.224635 |    619.831316 | NA                                                                                                                                                                    |
| 630 |     30.213137 |     90.946414 | Gareth Monger                                                                                                                                                         |
| 631 |    964.096020 |    290.964674 | Jagged Fang Designs                                                                                                                                                   |
| 632 |    363.355145 |    565.189840 | Nicholas J. Czaplewski, vectorized by Zimices                                                                                                                         |
| 633 |    768.131545 |    576.817843 | Collin Gross                                                                                                                                                          |
| 634 |    305.229094 |    598.186135 | Joschua Knüppe                                                                                                                                                        |
| 635 |    124.032441 |     75.669057 | Jean-Raphaël Guillaumin (photography) and T. Michael Keesey (vectorization)                                                                                           |
| 636 |    635.703479 |    743.095713 | Zimices                                                                                                                                                               |
| 637 |    165.621507 |    787.633301 | Matt Crook                                                                                                                                                            |
| 638 |    876.199526 |    434.528556 | Tasman Dixon                                                                                                                                                          |
| 639 |     44.022252 |    126.680763 | Steven Traver                                                                                                                                                         |
| 640 |    837.373789 |    174.247346 | Tony Ayling                                                                                                                                                           |
| 641 |    367.381544 |    599.606546 | C. Camilo Julián-Caballero                                                                                                                                            |
| 642 |    315.993999 |    431.314284 | Mali’o Kodis, photograph property of National Museums of Northern Ireland                                                                                             |
| 643 |    192.483989 |    363.707146 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 644 |    354.172412 |    351.522074 | Emily Willoughby                                                                                                                                                      |
| 645 |    374.935121 |    551.144302 | Noah Schlottman, photo by Reinhard Jahn                                                                                                                               |
| 646 |   1015.715231 |    779.728759 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 647 |    630.503365 |    408.430294 | Gareth Monger                                                                                                                                                         |
| 648 |    599.439910 |    751.049721 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 649 |    195.873951 |    560.552715 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                              |
| 650 |   1013.001054 |     35.271868 | Chris Hay                                                                                                                                                             |
| 651 |    748.881975 |    355.188731 | Scott Hartman                                                                                                                                                         |
| 652 |    941.256994 |    531.397348 | Jagged Fang Designs                                                                                                                                                   |
| 653 |    312.502210 |    209.552013 | Chris huh                                                                                                                                                             |
| 654 |    512.407212 |    763.723329 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 655 |    566.358801 |    546.298459 | Matt Crook                                                                                                                                                            |
| 656 |    237.727798 |    304.178285 | Ferran Sayol                                                                                                                                                          |
| 657 |    123.163312 |    631.630233 | Carlos Cano-Barbacil                                                                                                                                                  |
| 658 |    496.267323 |    588.449785 | Erika Schumacher                                                                                                                                                      |
| 659 |    887.744279 |      7.056975 | David Tana                                                                                                                                                            |
| 660 |    216.369399 |    128.769506 | NA                                                                                                                                                                    |
| 661 |      9.319560 |    253.584384 | Chloé Schmidt                                                                                                                                                         |
| 662 |    607.308286 |     14.451700 | Zimices                                                                                                                                                               |
| 663 |    495.469948 |    141.170624 | Beth Reinke                                                                                                                                                           |
| 664 |    375.947235 |    305.433962 | FunkMonk                                                                                                                                                              |
| 665 |    980.613128 |    593.880472 | NA                                                                                                                                                                    |
| 666 |    552.290429 |    315.123694 | Zimices                                                                                                                                                               |
| 667 |    630.602183 |    794.789647 | White Wolf                                                                                                                                                            |
| 668 |    137.903754 |    233.665814 | Steven Traver                                                                                                                                                         |
| 669 |    377.434010 |    338.216220 | Andrew A. Farke, modified from original by Robert Bruce Horsfall, from Scott 1912                                                                                     |
| 670 |    690.478600 |    687.726796 | Neil Kelley                                                                                                                                                           |
| 671 |    332.821462 |    600.369312 | Felix Vaux                                                                                                                                                            |
| 672 |     12.422191 |    309.630192 | NA                                                                                                                                                                    |
| 673 |    507.353310 |    398.425762 | Neil Kelley                                                                                                                                                           |
| 674 |    322.298143 |    227.993179 | Ludwik Gąsiorowski                                                                                                                                                    |
| 675 |     85.377161 |     13.956885 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 676 |     83.638867 |      6.870464 | NA                                                                                                                                                                    |
| 677 |    446.087716 |    454.490845 | NA                                                                                                                                                                    |
| 678 |     26.368173 |    485.988501 | Zimices                                                                                                                                                               |
| 679 |    711.040149 |    671.655113 | Andrew A. Farke                                                                                                                                                       |
| 680 |    903.030876 |    264.266078 | Zimices                                                                                                                                                               |
| 681 |    179.641050 |    114.659014 | Tasman Dixon                                                                                                                                                          |
| 682 |    503.867626 |    528.847782 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 683 |    793.763064 |    169.471196 | Emily Willoughby                                                                                                                                                      |
| 684 |    373.532723 |    739.179569 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 685 |     93.375523 |    282.074265 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 686 |    707.294542 |     20.109635 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 687 |   1011.607602 |    635.027786 | Steven Traver                                                                                                                                                         |
| 688 |    655.764036 |    371.506551 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
| 689 |    261.440052 |    595.409813 | Ferran Sayol                                                                                                                                                          |
| 690 |    823.682406 |    559.550223 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 691 |    442.920841 |    674.873842 | T. Michael Keesey                                                                                                                                                     |
| 692 |   1003.101115 |    453.221686 | DFoidl (vectorized by T. Michael Keesey)                                                                                                                              |
| 693 |    220.993693 |    683.883333 | Gareth Monger                                                                                                                                                         |
| 694 |    490.491565 |    577.057560 | Margot Michaud                                                                                                                                                        |
| 695 |    688.139821 |    706.106815 | Tasman Dixon                                                                                                                                                          |
| 696 |    182.773318 |    444.547733 | Mariana Ruiz (vectorized by T. Michael Keesey)                                                                                                                        |
| 697 |    499.725037 |    736.120537 | Michele M Tobias                                                                                                                                                      |
| 698 |    486.129959 |    721.659324 | Chris huh                                                                                                                                                             |
| 699 |    670.075399 |    375.220871 | Jagged Fang Designs                                                                                                                                                   |
| 700 |    187.628323 |    616.478253 | NA                                                                                                                                                                    |
| 701 |    959.844548 |    217.526522 | Zimices                                                                                                                                                               |
| 702 |    540.389925 |    791.009376 | Kevin Sánchez                                                                                                                                                         |
| 703 |    386.656522 |    290.028420 | David Orr                                                                                                                                                             |
| 704 |    977.812452 |    503.408223 | Zimices                                                                                                                                                               |
| 705 |    820.526436 |    645.347455 | Hans Hillewaert (photo) and T. Michael Keesey (vectorization)                                                                                                         |
| 706 |     30.816161 |    558.803638 | Frederick William Frohawk (vectorized by T. Michael Keesey)                                                                                                           |
| 707 |    865.685316 |    630.323719 | Margot Michaud                                                                                                                                                        |
| 708 |    744.646618 |    548.723572 | Jonathan Wells                                                                                                                                                        |
| 709 |    121.671874 |    295.448488 | L. Shyamal                                                                                                                                                            |
| 710 |    323.323553 |     81.676903 | FunkMonk                                                                                                                                                              |
| 711 |    188.514111 |    150.429776 | Markus A. Grohme                                                                                                                                                      |
| 712 |    761.321216 |    775.155288 | Michelle Site                                                                                                                                                         |
| 713 |     70.322973 |    379.230049 | Margot Michaud                                                                                                                                                        |
| 714 |    645.550696 |    262.901121 | U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                                     |
| 715 |    785.066760 |    391.879857 | Ferran Sayol                                                                                                                                                          |
| 716 |    575.439688 |    715.915739 | I. Sáček, Sr. (vectorized by T. Michael Keesey)                                                                                                                       |
| 717 |    709.436701 |    349.206006 | Chuanixn Yu                                                                                                                                                           |
| 718 |   1012.455408 |    497.882494 | Shyamal                                                                                                                                                               |
| 719 |    113.769537 |    331.113832 | Margot Michaud                                                                                                                                                        |
| 720 |    415.752443 |    663.289268 | NA                                                                                                                                                                    |
| 721 |    203.368306 |    549.375780 | Andreas Trepte (vectorized by T. Michael Keesey)                                                                                                                      |
| 722 |    789.778744 |    378.567448 | FunkMonk                                                                                                                                                              |
| 723 |    410.057276 |     44.953507 | Beth Reinke                                                                                                                                                           |
| 724 |    335.958927 |    569.220776 | Jake Warner                                                                                                                                                           |
| 725 |    371.643178 |    521.577125 | Ray Simpson (vectorized by T. Michael Keesey)                                                                                                                         |
| 726 |    142.739289 |    155.129385 | Matt Crook                                                                                                                                                            |
| 727 |     49.433426 |    793.452101 | Maija Karala                                                                                                                                                          |
| 728 |    772.710237 |    121.980887 | Zimices                                                                                                                                                               |
| 729 |    350.487086 |    418.444493 | Kamil S. Jaron                                                                                                                                                        |
| 730 |    831.186057 |     49.842825 | Steven Haddock • Jellywatch.org                                                                                                                                       |
| 731 |    510.506530 |    540.331312 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 732 |    489.665106 |    681.982989 | Daniel Jaron                                                                                                                                                          |
| 733 |    563.529058 |    637.722965 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                         |
| 734 |    511.400966 |    427.699218 | T. Michael Keesey                                                                                                                                                     |
| 735 |    666.815647 |    792.858610 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 736 |    326.225063 |    454.794069 | Matt Dempsey                                                                                                                                                          |
| 737 |    814.502635 |    659.103690 | NA                                                                                                                                                                    |
| 738 |   1003.510061 |    477.696760 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                         |
| 739 |     17.835810 |    554.342903 | Matt Martyniuk                                                                                                                                                        |
| 740 |    226.514684 |      9.608808 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
| 741 |    208.819951 |    152.888546 | Todd Marshall, vectorized by Zimices                                                                                                                                  |
| 742 |    306.528210 |    469.494745 | Cagri Cevrim                                                                                                                                                          |
| 743 |    913.739086 |    562.825539 | Ghedo and T. Michael Keesey                                                                                                                                           |
| 744 |    501.650868 |    196.087398 | Markus A. Grohme                                                                                                                                                      |
| 745 |    128.370667 |    225.767974 | Christoph Schomburg                                                                                                                                                   |
| 746 |    620.973143 |    698.926173 | C. Camilo Julián-Caballero                                                                                                                                            |
| 747 |    516.024576 |    580.153243 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                         |
| 748 |    724.185717 |    405.576599 | Gareth Monger                                                                                                                                                         |
| 749 |    399.907390 |    137.538876 | Nina Skinner                                                                                                                                                          |
| 750 |     12.200753 |    380.459110 | Maija Karala                                                                                                                                                          |
| 751 |    885.054900 |    455.283520 | NA                                                                                                                                                                    |
| 752 |    138.984204 |    287.529225 | Zimices                                                                                                                                                               |
| 753 |    232.396711 |    382.972805 | Scott Hartman                                                                                                                                                         |
| 754 |    132.852010 |    350.300587 | T. Michael Keesey (after A. Y. Ivantsov)                                                                                                                              |
| 755 |    636.203644 |    420.458953 | Jagged Fang Designs                                                                                                                                                   |
| 756 |    975.746644 |     84.942166 | Chris huh                                                                                                                                                             |
| 757 |     13.810741 |    242.194623 | Scott Hartman                                                                                                                                                         |
| 758 |    428.419454 |    197.946291 | Andrew A. Farke                                                                                                                                                       |
| 759 |    597.446411 |    544.171495 | Danielle Alba                                                                                                                                                         |
| 760 |    627.117005 |    544.542976 | Gareth Monger                                                                                                                                                         |
| 761 |    111.165275 |    193.716040 | John Conway                                                                                                                                                           |
| 762 |    290.241213 |    249.654211 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
| 763 |    897.150271 |    705.450924 | Maija Karala                                                                                                                                                          |
| 764 |     96.370634 |    108.085004 | Maxime Dahirel                                                                                                                                                        |
| 765 |    253.829116 |    676.338345 | Margot Michaud                                                                                                                                                        |
| 766 |    111.170270 |    747.235341 | Margot Michaud                                                                                                                                                        |
| 767 |    898.258945 |    127.319437 | Nobu Tamura                                                                                                                                                           |
| 768 |    922.769859 |    535.367104 | Jagged Fang Designs                                                                                                                                                   |
| 769 |    638.053755 |    644.896355 | Gareth Monger                                                                                                                                                         |
| 770 |    368.888150 |    617.169552 | U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                                     |
| 771 |     82.251814 |    294.951294 | Scott Reid                                                                                                                                                            |
| 772 |    427.301614 |    607.769328 | Scott Hartman                                                                                                                                                         |
| 773 |    486.063302 |    416.231617 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                              |
| 774 |    753.965591 |     52.498375 | Ingo Braasch                                                                                                                                                          |
| 775 |    310.046288 |    610.060327 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                      |
| 776 |    904.409991 |    435.638795 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 777 |    264.792272 |    108.493055 | Maija Karala                                                                                                                                                          |
| 778 |    370.732998 |    282.349831 | Bruno Maggia                                                                                                                                                          |
| 779 |    226.921407 |    551.627791 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 780 |     36.890791 |     65.134692 | Scott Hartman                                                                                                                                                         |
| 781 |    744.476174 |    478.963763 | Andy Wilson                                                                                                                                                           |
| 782 |    519.404471 |    145.642377 | Ignacio Contreras                                                                                                                                                     |
| 783 |    732.242804 |    614.487664 | Scott Reid                                                                                                                                                            |
| 784 |    323.186227 |    672.249762 | Sarah Werning                                                                                                                                                         |
| 785 |    643.011072 |    380.650174 | Beth Reinke                                                                                                                                                           |
| 786 |    772.991890 |     62.166811 | Steven Coombs                                                                                                                                                         |
| 787 |    257.949163 |    248.815293 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 788 |    459.668361 |    332.876596 | Jagged Fang Designs                                                                                                                                                   |
| 789 |    581.141179 |    407.495727 | Lukasiniho                                                                                                                                                            |
| 790 |     90.369293 |    400.945829 | Mattia Menchetti                                                                                                                                                      |
| 791 |    369.960012 |    454.859704 | Robert Gay                                                                                                                                                            |
| 792 |    268.209369 |    406.441171 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 793 |    988.582857 |    141.327623 | NA                                                                                                                                                                    |
| 794 |    363.410156 |    295.502927 | Steven Traver                                                                                                                                                         |
| 795 |    750.852570 |    283.973449 | NA                                                                                                                                                                    |
| 796 |    183.038194 |     38.110058 | L. Shyamal                                                                                                                                                            |
| 797 |    974.187721 |    748.501650 | T. Michael Keesey (from a photo by Maximilian Paradiz)                                                                                                                |
| 798 |    558.658217 |    266.275390 | Falconaumanni and T. Michael Keesey                                                                                                                                   |
| 799 |    784.285425 |    161.445642 | NA                                                                                                                                                                    |
| 800 |    106.693583 |    572.759729 | T. Michael Keesey                                                                                                                                                     |
| 801 |     18.466391 |    583.261803 | Tasman Dixon                                                                                                                                                          |
| 802 |    853.174316 |    459.060641 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 803 |    559.173755 |    555.282140 | Margot Michaud                                                                                                                                                        |
| 804 |     57.200787 |    207.667873 | Gareth Monger                                                                                                                                                         |
| 805 |    558.554130 |    485.149241 | terngirl                                                                                                                                                              |
| 806 |    393.031710 |    796.191131 | Jagged Fang Designs                                                                                                                                                   |
| 807 |    565.082617 |    123.534339 | Adrian Reich                                                                                                                                                          |
| 808 |    422.441180 |    157.221770 | Gareth Monger                                                                                                                                                         |
| 809 |    258.842536 |    208.040026 | Karla Martinez                                                                                                                                                        |
| 810 |     69.594981 |    706.416005 | Sebastian Stabinger                                                                                                                                                   |
| 811 |    469.484748 |    160.910648 | Gareth Monger                                                                                                                                                         |
| 812 |     77.991202 |    481.430661 | Tyler McCraney                                                                                                                                                        |
| 813 |    882.996130 |    400.195714 | Scott Hartman                                                                                                                                                         |
| 814 |     32.582921 |    777.226358 | Original photo by Andrew Murray, vectorized by Roberto Díaz Sibaja                                                                                                    |
| 815 |     26.225665 |    647.973544 | Tauana J. Cunha                                                                                                                                                       |
| 816 |    595.466075 |    280.608537 | Chris huh                                                                                                                                                             |
| 817 |   1004.840658 |    332.458225 | Birgit Lang                                                                                                                                                           |
| 818 |    969.054798 |    226.031411 | Scott Hartman                                                                                                                                                         |
| 819 |    361.796769 |    276.145463 | Anthony Caravaggi                                                                                                                                                     |
| 820 |    402.839652 |    606.110507 | Crystal Maier                                                                                                                                                         |
| 821 |    955.765563 |    721.038468 | Brian Gratwicke (photo) and T. Michael Keesey (vectorization)                                                                                                         |
| 822 |    706.784638 |    389.473732 | Chris huh                                                                                                                                                             |
| 823 |    634.240488 |    717.755773 | T. Michael Keesey                                                                                                                                                     |
| 824 |    350.446307 |    215.066257 | Jagged Fang Designs                                                                                                                                                   |
| 825 |    923.614439 |    533.296653 | Gareth Monger                                                                                                                                                         |
| 826 |    230.403982 |    653.735607 | Markus A. Grohme                                                                                                                                                      |
| 827 |    349.748754 |    789.231989 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 828 |    270.040537 |    343.062260 | NA                                                                                                                                                                    |
| 829 |    498.804570 |    362.930440 | Todd Marshall, vectorized by Zimices                                                                                                                                  |
| 830 |    755.737918 |    582.467654 | Michele M Tobias                                                                                                                                                      |
| 831 |    572.436542 |    702.804915 | NA                                                                                                                                                                    |
| 832 |    919.808452 |    777.685698 | Margot Michaud                                                                                                                                                        |
| 833 |    938.488408 |    563.239176 | Beth Reinke                                                                                                                                                           |
| 834 |    734.529336 |    711.218085 | Matt Crook                                                                                                                                                            |
| 835 |    649.205081 |    411.594259 | NA                                                                                                                                                                    |
| 836 |    124.655130 |    725.432214 | Jagged Fang Designs                                                                                                                                                   |
| 837 |    231.721305 |    143.833384 | NA                                                                                                                                                                    |
| 838 |    112.442896 |    669.355850 | Scott Hartman                                                                                                                                                         |
| 839 |    611.272347 |    781.813156 | NA                                                                                                                                                                    |
| 840 |    394.167092 |    530.871606 | NA                                                                                                                                                                    |
| 841 |    173.196412 |    668.374137 | Ben Liebeskind                                                                                                                                                        |
| 842 |    317.254536 |    518.951346 | Aviceda (photo) & T. Michael Keesey                                                                                                                                   |
| 843 |     23.181908 |    610.472147 | Steven Traver                                                                                                                                                         |
| 844 |     19.393199 |    316.987209 | Markus A. Grohme                                                                                                                                                      |
| 845 |    897.741830 |    607.085163 | Scott Hartman                                                                                                                                                         |
| 846 |     91.875073 |    314.872778 | Steven Traver                                                                                                                                                         |
| 847 |    193.242499 |    216.991554 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 848 |    771.487614 |    492.708054 | NA                                                                                                                                                                    |
| 849 |    883.092274 |    108.060842 | Ferran Sayol                                                                                                                                                          |
| 850 |   1012.093694 |    114.123530 | Kamil S. Jaron                                                                                                                                                        |
| 851 |    994.801670 |     40.191047 | Mattia Menchetti                                                                                                                                                      |
| 852 |    699.873741 |    271.314117 | Owen Jones                                                                                                                                                            |
| 853 |    955.789462 |    411.090978 | Christopher Chávez                                                                                                                                                    |
| 854 |    500.602064 |    374.338995 | Mattia Menchetti                                                                                                                                                      |
| 855 |   1001.594050 |    313.077660 | Andrew A. Farke, modified from original by H. Milne Edwards                                                                                                           |
| 856 |    596.427198 |      8.076261 | Matt Crook                                                                                                                                                            |
| 857 |    889.335530 |    181.011573 | NA                                                                                                                                                                    |
| 858 |    250.321017 |    501.740388 | Birgit Lang                                                                                                                                                           |
| 859 |    161.422818 |    405.713618 | Tasman Dixon                                                                                                                                                          |
| 860 |    204.919508 |    658.788838 | NA                                                                                                                                                                    |
| 861 |    478.316724 |     10.731016 | Matt Crook                                                                                                                                                            |
| 862 |    224.129159 |    634.430422 | Beth Reinke                                                                                                                                                           |
| 863 |     49.038203 |    649.193811 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 864 |    102.842371 |    250.928294 | Kanako Bessho-Uehara                                                                                                                                                  |
| 865 |    461.537049 |    343.336747 | FJDegrange                                                                                                                                                            |
| 866 |    625.412337 |    561.002310 | Steven Haddock • Jellywatch.org                                                                                                                                       |
| 867 |    862.300332 |    109.885947 | Gareth Monger                                                                                                                                                         |
| 868 |    880.506567 |    414.984942 | Matt Crook                                                                                                                                                            |
| 869 |    565.331683 |    602.807053 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 870 |    832.752469 |    221.856214 | Zimices                                                                                                                                                               |
| 871 |    152.141352 |    473.400754 | Scott Hartman                                                                                                                                                         |
| 872 |     16.806119 |    198.253292 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 873 |    566.287394 |    595.729367 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 874 |    431.651486 |    117.065064 | Dean Schnabel                                                                                                                                                         |
| 875 |    310.491167 |    131.414359 | CNZdenek                                                                                                                                                              |
| 876 |     15.517083 |    135.970368 | Margot Michaud                                                                                                                                                        |
| 877 |    963.556947 |    455.342076 | Young and Zhao (1972:figure 4), modified by Michael P. Taylor                                                                                                         |
| 878 |      6.823075 |    588.497922 | NA                                                                                                                                                                    |
| 879 |    144.338821 |    220.763126 | Matt Crook                                                                                                                                                            |
| 880 |    199.179256 |     14.471323 | Lukasiniho                                                                                                                                                            |
| 881 |    757.297849 |    477.944184 | T. Michael Keesey                                                                                                                                                     |
| 882 |    321.504894 |     42.584588 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 883 |    650.721135 |    189.578803 | Jagged Fang Designs                                                                                                                                                   |
| 884 |    558.611527 |    285.438516 | Christoph Schomburg                                                                                                                                                   |
| 885 |    302.211151 |    293.551795 | Dmitry Bogdanov                                                                                                                                                       |
| 886 |    444.160413 |    277.798680 | Tauana J. Cunha                                                                                                                                                       |
| 887 |    640.526607 |    580.144545 | NA                                                                                                                                                                    |
| 888 |    577.783949 |    727.986606 | Chris huh                                                                                                                                                             |
| 889 |    883.673425 |    590.536329 | Andrew A. Farke                                                                                                                                                       |
| 890 |    451.041022 |    129.198391 | Margot Michaud                                                                                                                                                        |
| 891 |    611.292861 |     42.462979 | Matt Crook                                                                                                                                                            |
| 892 |    247.734047 |     27.869029 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 893 |   1010.214102 |    300.367336 | Gareth Monger                                                                                                                                                         |
| 894 |    518.800330 |    368.172297 | C. Camilo Julián-Caballero                                                                                                                                            |
| 895 |    513.989400 |      8.426529 | Andy Wilson                                                                                                                                                           |
| 896 |    776.891244 |    780.625191 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 897 |    873.948942 |    282.366585 | Raven Amos                                                                                                                                                            |
| 898 |     10.886209 |    515.397729 | Lukasiniho                                                                                                                                                            |
| 899 |    759.597130 |    551.910898 | Ieuan Jones                                                                                                                                                           |
| 900 |    732.813613 |    731.436512 | Andrew A. Farke                                                                                                                                                       |
| 901 |     14.649007 |     82.664953 | Matt Martyniuk                                                                                                                                                        |
| 902 |    233.694950 |    399.154729 | Zimices                                                                                                                                                               |
| 903 |     82.335549 |    752.891040 | Erika Schumacher                                                                                                                                                      |
| 904 |    433.174227 |    751.022650 | Steven Traver                                                                                                                                                         |
| 905 |    263.513029 |    371.317927 | Lily Hughes                                                                                                                                                           |
| 906 |    489.245474 |    406.162487 | Gareth Monger                                                                                                                                                         |
| 907 |    629.531543 |    596.927505 | Michael Scroggie, from original photograph by Gary M. Stolz, USFWS (original photograph in public domain).                                                            |
| 908 |    315.512469 |    486.300753 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 909 |    694.185459 |     65.436139 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 910 |    651.746463 |    665.853451 | T. Michael Keesey                                                                                                                                                     |
| 911 |    315.497940 |    586.549450 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 912 |    144.119618 |    697.655331 | DW Bapst, modified from Figure 1 of Belanger (2011, PALAIOS).                                                                                                         |
| 913 |    586.043783 |    752.279926 | Danielle Alba                                                                                                                                                         |
| 914 |    989.648824 |     52.232532 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
| 915 |    310.725564 |    546.905937 | Zimices                                                                                                                                                               |
| 916 |    271.449011 |    793.430255 | Mykle Hoban                                                                                                                                                           |

    #> Your tweet has been posted!
