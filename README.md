
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

Sarah Werning, Andy Wilson, Roberto Díaz Sibaja, Air Kebir NRG, Dean
Schnabel, Jim Bendon (photography) and T. Michael Keesey
(vectorization), TaraTaylorDesign, Zimices, Michelle Site, T. Michael
Keesey, Ray Simpson (vectorized by T. Michael Keesey), Gareth Monger,
Jagged Fang Designs, Nobu Tamura, Nobu Tamura (vectorized by T. Michael
Keesey), Maija Karala, Bruno Maggia, Matt Crook, Cesar Julian, Robbie N.
Cada (modified by T. Michael Keesey), Noah Schlottman, photo by Casey
Dunn, C. Camilo Julián-Caballero, Scott Hartman, Scott Reid, Birgit
Lang, Mali’o Kodis, photograph by Bruno Vellutini, xgirouxb, Scott D.
Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A.
Forster, Joshua A. Smith, Alan L. Titus, Iain Reid, Chris huh, Margot
Michaud, T. Michael Keesey (after Mivart), Obsidian Soul (vectorized by
T. Michael Keesey), Markus A. Grohme, FJDegrange, FunkMonk, Ferran
Sayol, Kamil S. Jaron, Melissa Broussard, Dmitry Bogdanov (vectorized by
T. Michael Keesey), Duane Raver/USFWS, George Edward Lodge (vectorized
by T. Michael Keesey), I. Geoffroy Saint-Hilaire (vectorized by T.
Michael Keesey), E. R. Waite & H. M. Hale (vectorized by T. Michael
Keesey), Natalie Claunch, Robbie Cada (vectorized by T. Michael Keesey),
Ieuan Jones, Sean McCann, Kanchi Nanjo, Felix Vaux, Christoph Schomburg,
Gabriela Palomo-Munoz, Cyril Matthey-Doret, adapted from Bernard
Chaubet, Becky Barnes, Trond R. Oskars, Martien Brand (original photo),
Renato Santos (vector silhouette), Adrian Reich, Lukasiniho, Tauana J.
Cunha, Ignacio Contreras, Filip em, Beth Reinke, Tasman Dixon, Noah
Schlottman, photo from Casey Dunn, Ingo Braasch, Ghedoghedo (vectorized
by T. Michael Keesey), Chris Jennings (vectorized by A. Verrière), Erika
Schumacher, Didier Descouens (vectorized by T. Michael Keesey), Steven
Traver, Pete Buchholz, Andreas Hejnol, Alexander Schmidt-Lebuhn, Jessica
Anne Miller, Brad McFeeters (vectorized by T. Michael Keesey), Sergio A.
Muñoz-Gómez, Kosta Mumcuoglu (vectorized by T. Michael Keesey), Yan
Wong, Tracy A. Heath, Javier Luque, Lauren Sumner-Rooney, Jaime Headden,
Mathilde Cordellier, Abraão B. Leite, Ralf Janssen, Nikola-Michael Prpic
& Wim G. M. Damen (vectorized by T. Michael Keesey), Amanda Katzer,
Frank Förster, Jose Carlos Arenas-Monroy, Emily Willoughby, Steven
Coombs, François Michonneau, Charles R. Knight, vectorized by Zimices,
Jake Warner, Katie S. Collins, Matthew E. Clapham, Chase Brownstein,
Griensteidl and T. Michael Keesey, Original scheme by ‘Haplochromis’,
vectorized by Roberto Díaz Sibaja, Sharon Wegner-Larsen, Jennifer
Trimble, Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob
Slotow (vectorized by T. Michael Keesey), Shyamal, Alex Slavenko,
Ricardo N. Martinez & Oscar A. Alcober, Anthony Caravaggi, Harold N
Eyster, Claus Rebler, Ville Koistinen (vectorized by T. Michael Keesey),
CNZdenek, Darren Naish (vectorized by T. Michael Keesey), Michael
Scroggie, from original photograph by John Bettaso, USFWS (original
photograph in public domain)., Richard Parker (vectorized by T. Michael
Keesey), Hugo Gruson, Chuanixn Yu, Birgit Lang; original image by
virmisco.org, Ekaterina Kopeykina (vectorized by T. Michael Keesey),
Martin R. Smith, Ellen Edmonson (illustration) and Timothy J. Bartley
(silhouette), Maxime Dahirel, Neil Kelley, Michael Scroggie, Siobhon
Egan, Kai R. Caspar, Haplochromis (vectorized by T. Michael Keesey),
Inessa Voet, Mo Hassan, Hans Hillewaert (vectorized by T. Michael
Keesey), Pedro de Siracusa, Lafage, Karina Garcia, Joanna Wolfe, Sam
Droege (photography) and T. Michael Keesey (vectorization), DW Bapst
(modified from Mitchell 1990), Rebecca Groom, Yan Wong from drawing by
T. F. Zimmermann, Marmelad, Steve Hillebrand/U. S. Fish and Wildlife
Service (source photo), T. Michael Keesey (vectorization), Raven Amos,
Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes
(www.carnivorosaustrales.org), Armin Reindl, Gordon E. Robertson, Daniel
Stadtmauer, Jan Sevcik (photo), John E. McCormack, Michael G. Harvey,
Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T.
Brumfield & T. Michael Keesey, Jon Hill (Photo by Benjamint444:
<http://en.wikipedia.org/wiki/File:Blue-footed-booby.jpg>), Dmitry
Bogdanov, Skye McDavid, Acrocynus (vectorized by T. Michael Keesey),
Dave Angelini, Collin Gross, Noah Schlottman, photo by Reinhard Jahn,
Mali’o Kodis, photograph by P. Funch and R.M. Kristensen, Mattia
Menchetti, Robert Bruce Horsfall, vectorized by Zimices, Oliver Voigt,
T. Michael Keesey (after Tillyard), Mario Quevedo, Michele M Tobias,
Lily Hughes, Henry Lydecker, S.Martini, T. Michael Keesey (after MPF),
Xavier A. Jenkins, Gabriel Ugueto, White Wolf, Alan Manson (photo), John
E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G.
Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Jerry
Oldenettel (vectorized by T. Michael Keesey), (after McCulloch 1908),
Smokeybjb (vectorized by T. Michael Keesey), L.M. Davalos, Zachary
Quigley, Metalhead64 (vectorized by T. Michael Keesey), Enoch Joseph
Wetsy (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Lukas Panzarin (vectorized by T. Michael Keesey), Konsta
Happonen, from a CC-BY-NC image by pelhonen on iNaturalist, Robert
Hering, Michael Wolf (photo), Hans Hillewaert (editing), T. Michael
Keesey (vectorization), Brian Gratwicke (photo) and T. Michael Keesey
(vectorization), Nobu Tamura, vectorized by Zimices, T. Michael Keesey
(vectorization); Thorsten Assmann, Jörn Buse, Claudia Drees,
Ariel-Leib-Leonid Friedman, Tal Levanony, Andrea Matern, Anika Timm, and
David W. Wrase (photography), Steven Haddock • Jellywatch.org, Milton
Tan, T. Michael Keesey (vectorization) and Tony Hisgett (photography),
Robert Gay, Douglas Brown (modified by T. Michael Keesey), terngirl,
Young and Zhao (1972:figure 4), modified by Michael P. Taylor, Martin
Kevil, Emily Jane McTavish, David Tana, Lankester Edwin Ray (vectorized
by T. Michael Keesey), Mali’o Kodis, image by Rebecca Ritger, Ellen
Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley
(silhouette), Zimices, based in Mauricio Antón skeletal, Matt Martyniuk,
Walter Vladimir, Skye M, Jonathan Wells, Abraão Leite, Ramona J Heim,
Noah Schlottman, photo by Adam G. Clause, Jay Matternes (vectorized by
T. Michael Keesey), Sam Droege (photo) and T. Michael Keesey
(vectorization), Pollyanna von Knorring and T. Michael Keesey, Richard
Lampitt, Jeremy Young / NHM (vectorization by Yan Wong), Renata F.
Martins, Carlos Cano-Barbacil, Noah Schlottman, photo by Martin V.
Sørensen, New York Zoological Society, Dann Pigdon, Johan Lindgren,
Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe, Joshua Fowler,
Smokeybjb (modified by Mike Keesey), Matt Martyniuk (vectorized by T.
Michael Keesey), Duane Raver (vectorized by T. Michael Keesey), Jimmy
Bernot, Caleb Brown, Leann Biancani, photo by Kenneth Clifton, Michael
Scroggie, from original photograph by Gary M. Stolz, USFWS (original
photograph in public domain)., (after Spotila 2004), Robert Bruce
Horsfall (vectorized by William Gearty), Xavier Giroux-Bougard, T.
Michael Keesey (vector) and Stuart Halliday (photograph), M Kolmann,
Tyler Greenfield, Darius Nau, L. Shyamal, JJ Harrison (vectorized by T.
Michael Keesey), Frederick William Frohawk (vectorized by T. Michael
Keesey), Maha Ghazal, Matt Wilkins (photo by Patrick Kavanagh), Steven
Blackwood, Noah Schlottman, photo by Gustav Paulay for Moorea Biocode,
Bill Bouton (source photo) & T. Michael Keesey (vectorization),
Jakovche, Chloé Schmidt, Samanta Orellana, Jack Mayer Wood, Konsta
Happonen, from a CC-BY-NC image by sokolkov2002 on iNaturalist, Ludwik
Gąsiorowski, T. Michael Keesey (photo by Sean Mack), Chris Hay, Karl
Ragnar Gjertsen (vectorized by T. Michael Keesey),
SauropodomorphMonarch, NOAA (vectorized by T. Michael Keesey), J. J.
Harrison (photo) & T. Michael Keesey, Kevin Sánchez, Riccardo Percudani,
Oscar Sanisidro, V. Deepak, Jon Hill, Matt Martyniuk (modified by
Serenchia), Nobu Tamura (modified by T. Michael Keesey), Mason McNair,
Tommaso Cancellario, Cristopher Silva, Geoff Shaw, Scott Hartman
(modified by T. Michael Keesey), Rebecca Groom (Based on Photo by
Andreas Trepte), Taro Maeda, Peileppe, Juan Carlos Jerí,
www.studiospectre.com, Andrew A. Farke, Francesco “Architetto”
Rollandin, Michele Tobias, Brian Swartz (vectorized by T. Michael
Keesey), Javiera Constanzo, Terpsichores, Arthur S. Brum, Emil Schmidt
(vectorized by Maxime Dahirel), John Conway, Matt Dempsey

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                               |
| --: | ------------: | ------------: | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    209.327523 |    512.728083 | Sarah Werning                                                                                                                                                                        |
|   2 |    843.956335 |    194.532679 | Andy Wilson                                                                                                                                                                          |
|   3 |    126.670032 |    398.666511 | Roberto Díaz Sibaja                                                                                                                                                                  |
|   4 |    313.721208 |    629.530360 | Air Kebir NRG                                                                                                                                                                        |
|   5 |    675.633758 |    714.421669 | Dean Schnabel                                                                                                                                                                        |
|   6 |    436.429408 |    289.012997 | Jim Bendon (photography) and T. Michael Keesey (vectorization)                                                                                                                       |
|   7 |    160.676951 |    155.293567 | TaraTaylorDesign                                                                                                                                                                     |
|   8 |    894.911549 |     81.791755 | Zimices                                                                                                                                                                              |
|   9 |    827.928058 |    487.843437 | Michelle Site                                                                                                                                                                        |
|  10 |     50.379290 |    240.150845 | T. Michael Keesey                                                                                                                                                                    |
|  11 |    111.135143 |    746.417178 | Ray Simpson (vectorized by T. Michael Keesey)                                                                                                                                        |
|  12 |     82.737219 |    592.534635 | Gareth Monger                                                                                                                                                                        |
|  13 |    949.720049 |    764.818937 | NA                                                                                                                                                                                   |
|  14 |    553.942969 |    688.656237 | Jagged Fang Designs                                                                                                                                                                  |
|  15 |    696.306390 |    308.062370 | Nobu Tamura                                                                                                                                                                          |
|  16 |    570.913886 |    584.395866 | Gareth Monger                                                                                                                                                                        |
|  17 |    531.342551 |    168.614576 | Gareth Monger                                                                                                                                                                        |
|  18 |    456.531657 |    671.930472 | T. Michael Keesey                                                                                                                                                                    |
|  19 |    416.840155 |    485.195487 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
|  20 |    635.474792 |    227.929862 | Jagged Fang Designs                                                                                                                                                                  |
|  21 |    187.992517 |    282.162143 | Maija Karala                                                                                                                                                                         |
|  22 |    573.493345 |     44.848012 | Bruno Maggia                                                                                                                                                                         |
|  23 |    693.721674 |    143.598149 | Matt Crook                                                                                                                                                                           |
|  24 |    580.365415 |    511.866274 | Cesar Julian                                                                                                                                                                         |
|  25 |    576.020855 |    781.533853 | Jagged Fang Designs                                                                                                                                                                  |
|  26 |    952.168597 |    624.136018 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                                                       |
|  27 |    218.395598 |    662.164433 | Noah Schlottman, photo by Casey Dunn                                                                                                                                                 |
|  28 |    382.893217 |    602.646412 | Andy Wilson                                                                                                                                                                          |
|  29 |    949.085936 |    683.163354 | C. Camilo Julián-Caballero                                                                                                                                                           |
|  30 |    613.702785 |    635.016508 | Scott Hartman                                                                                                                                                                        |
|  31 |     87.428442 |    669.723773 | Scott Reid                                                                                                                                                                           |
|  32 |    646.118896 |    196.536325 | Birgit Lang                                                                                                                                                                          |
|  33 |    262.277049 |    356.369945 | Michelle Site                                                                                                                                                                        |
|  34 |    219.423763 |     78.093549 | Mali’o Kodis, photograph by Bruno Vellutini                                                                                                                                          |
|  35 |    334.776514 |     55.631150 | Andy Wilson                                                                                                                                                                          |
|  36 |    786.426992 |    763.696833 | xgirouxb                                                                                                                                                                             |
|  37 |    650.163748 |    400.253537 | Scott Hartman                                                                                                                                                                        |
|  38 |    297.890895 |    745.004098 | Matt Crook                                                                                                                                                                           |
|  39 |    413.495804 |    760.224843 | Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus                                                             |
|  40 |    527.715036 |    484.012439 | Iain Reid                                                                                                                                                                            |
|  41 |     93.850141 |     50.596229 | Dean Schnabel                                                                                                                                                                        |
|  42 |    604.685331 |     71.202990 | Chris huh                                                                                                                                                                            |
|  43 |    490.983807 |     92.054944 | Margot Michaud                                                                                                                                                                       |
|  44 |    700.945094 |    459.839340 | Zimices                                                                                                                                                                              |
|  45 |    991.600770 |    269.635818 | T. Michael Keesey (after Mivart)                                                                                                                                                     |
|  46 |    511.660972 |    531.103635 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                                      |
|  47 |    617.791120 |    267.702670 | Markus A. Grohme                                                                                                                                                                     |
|  48 |    983.450920 |     67.522208 | FJDegrange                                                                                                                                                                           |
|  49 |    699.070667 |     28.636505 | Jagged Fang Designs                                                                                                                                                                  |
|  50 |    763.594137 |    268.147859 | NA                                                                                                                                                                                   |
|  51 |    806.003880 |    708.252812 | FunkMonk                                                                                                                                                                             |
|  52 |    640.690872 |    542.367014 | Ferran Sayol                                                                                                                                                                         |
|  53 |    765.081220 |     32.998885 | Markus A. Grohme                                                                                                                                                                     |
|  54 |    138.124192 |    241.983603 | Kamil S. Jaron                                                                                                                                                                       |
|  55 |    660.287389 |    357.322598 | Melissa Broussard                                                                                                                                                                    |
|  56 |    481.307754 |    562.394820 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
|  57 |    652.046169 |    773.416396 | Duane Raver/USFWS                                                                                                                                                                    |
|  58 |     78.176053 |    469.407512 | Chris huh                                                                                                                                                                            |
|  59 |     93.093481 |    147.823316 | George Edward Lodge (vectorized by T. Michael Keesey)                                                                                                                                |
|  60 |    497.060480 |    205.842367 | I. Geoffroy Saint-Hilaire (vectorized by T. Michael Keesey)                                                                                                                          |
|  61 |    524.827853 |    722.513899 | E. R. Waite & H. M. Hale (vectorized by T. Michael Keesey)                                                                                                                           |
|  62 |    960.434836 |    550.495422 | Kamil S. Jaron                                                                                                                                                                       |
|  63 |     33.443871 |    768.913490 | Natalie Claunch                                                                                                                                                                      |
|  64 |    982.812679 |    351.884600 | Robbie Cada (vectorized by T. Michael Keesey)                                                                                                                                        |
|  65 |    824.256475 |    706.431354 | Markus A. Grohme                                                                                                                                                                     |
|  66 |    827.724383 |    698.622399 | Scott Hartman                                                                                                                                                                        |
|  67 |     34.226535 |    179.357095 | Ieuan Jones                                                                                                                                                                          |
|  68 |    753.721316 |    379.191562 | Sean McCann                                                                                                                                                                          |
|  69 |    533.474896 |    235.936112 | Matt Crook                                                                                                                                                                           |
|  70 |    301.516735 |    446.926857 | Kanchi Nanjo                                                                                                                                                                         |
|  71 |    739.736760 |    686.354440 | Felix Vaux                                                                                                                                                                           |
|  72 |    442.851671 |    584.105766 | Christoph Schomburg                                                                                                                                                                  |
|  73 |    488.127521 |    426.209839 | Gabriela Palomo-Munoz                                                                                                                                                                |
|  74 |    165.346100 |    655.908572 | Gareth Monger                                                                                                                                                                        |
|  75 |    862.236593 |    289.595705 | Cyril Matthey-Doret, adapted from Bernard Chaubet                                                                                                                                    |
|  76 |    122.848353 |    700.473912 | Becky Barnes                                                                                                                                                                         |
|  77 |    398.727596 |     26.413400 | Trond R. Oskars                                                                                                                                                                      |
|  78 |    215.630378 |    549.198932 | Christoph Schomburg                                                                                                                                                                  |
|  79 |    703.711561 |    233.226589 | Martien Brand (original photo), Renato Santos (vector silhouette)                                                                                                                    |
|  80 |    852.958572 |    788.039289 | Adrian Reich                                                                                                                                                                         |
|  81 |    818.926132 |    352.605254 | Lukasiniho                                                                                                                                                                           |
|  82 |     54.780159 |    684.423375 | Birgit Lang                                                                                                                                                                          |
|  83 |    586.731804 |    707.559595 | Zimices                                                                                                                                                                              |
|  84 |    246.207967 |    413.267977 | Zimices                                                                                                                                                                              |
|  85 |    740.036069 |    515.254917 | Tauana J. Cunha                                                                                                                                                                      |
|  86 |    541.585122 |    751.510277 | Margot Michaud                                                                                                                                                                       |
|  87 |    241.863199 |    206.820004 | NA                                                                                                                                                                                   |
|  88 |    726.639921 |    184.394363 | Ignacio Contreras                                                                                                                                                                    |
|  89 |     49.994761 |    704.430692 | Gabriela Palomo-Munoz                                                                                                                                                                |
|  90 |    146.658856 |    586.922911 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
|  91 |    850.881936 |    649.507157 | Matt Crook                                                                                                                                                                           |
|  92 |    735.785915 |    340.027934 | Filip em                                                                                                                                                                             |
|  93 |    590.941677 |    294.515662 | Beth Reinke                                                                                                                                                                          |
|  94 |     82.400377 |    333.427527 | Andy Wilson                                                                                                                                                                          |
|  95 |    334.442587 |    554.904784 | Michelle Site                                                                                                                                                                        |
|  96 |    771.417682 |    412.383177 | Tasman Dixon                                                                                                                                                                         |
|  97 |    510.782284 |    603.624285 | Noah Schlottman, photo from Casey Dunn                                                                                                                                               |
|  98 |    440.094068 |    401.823703 | Ingo Braasch                                                                                                                                                                         |
|  99 |     66.772338 |    321.342692 | T. Michael Keesey                                                                                                                                                                    |
| 100 |    254.313603 |    118.219263 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                                         |
| 101 |    213.665766 |    356.171882 | Chris huh                                                                                                                                                                            |
| 102 |     18.274927 |     93.904574 | Birgit Lang                                                                                                                                                                          |
| 103 |    879.312922 |    671.577263 | Iain Reid                                                                                                                                                                            |
| 104 |    113.559790 |    781.794610 | Chris Jennings (vectorized by A. Verrière)                                                                                                                                           |
| 105 |    229.143414 |    570.579265 | Margot Michaud                                                                                                                                                                       |
| 106 |    222.021737 |    156.723613 | Gareth Monger                                                                                                                                                                        |
| 107 |    926.412943 |     14.083080 | Erika Schumacher                                                                                                                                                                     |
| 108 |    154.874877 |    613.200191 | Jagged Fang Designs                                                                                                                                                                  |
| 109 |    621.739373 |    736.463899 | T. Michael Keesey                                                                                                                                                                    |
| 110 |     80.430733 |    302.126642 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                                   |
| 111 |    266.088478 |    617.073959 | Steven Traver                                                                                                                                                                        |
| 112 |    829.020824 |    314.898732 | NA                                                                                                                                                                                   |
| 113 |    992.729621 |    471.028767 | Pete Buchholz                                                                                                                                                                        |
| 114 |    544.062059 |    638.122204 | Jagged Fang Designs                                                                                                                                                                  |
| 115 |     98.367277 |    253.722940 | Andreas Hejnol                                                                                                                                                                       |
| 116 |    739.040294 |     82.747368 | NA                                                                                                                                                                                   |
| 117 |    682.322648 |    249.075501 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 118 |    454.025217 |    147.618141 | Felix Vaux                                                                                                                                                                           |
| 119 |     16.466604 |    695.641101 | Noah Schlottman, photo from Casey Dunn                                                                                                                                               |
| 120 |     46.492612 |     14.341972 | T. Michael Keesey                                                                                                                                                                    |
| 121 |    568.286253 |    306.840110 | Jessica Anne Miller                                                                                                                                                                  |
| 122 |    656.746007 |    129.000768 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                                     |
| 123 |    955.232223 |    199.325407 | Christoph Schomburg                                                                                                                                                                  |
| 124 |    194.289524 |    588.182642 | Sergio A. Muñoz-Gómez                                                                                                                                                                |
| 125 |    264.001453 |     87.880409 | Kosta Mumcuoglu (vectorized by T. Michael Keesey)                                                                                                                                    |
| 126 |    183.288051 |    735.110174 | Zimices                                                                                                                                                                              |
| 127 |    736.855617 |    230.890550 | Yan Wong                                                                                                                                                                             |
| 128 |    461.917190 |     14.279165 | Sarah Werning                                                                                                                                                                        |
| 129 |    562.229086 |    231.864990 | Tracy A. Heath                                                                                                                                                                       |
| 130 |    968.806137 |    129.697439 | Chris huh                                                                                                                                                                            |
| 131 |    984.574816 |    740.582766 | Javier Luque                                                                                                                                                                         |
| 132 |    379.397162 |    703.870757 | T. Michael Keesey                                                                                                                                                                    |
| 133 |    631.088603 |    114.752954 | Matt Crook                                                                                                                                                                           |
| 134 |    106.905096 |    112.718987 | Ferran Sayol                                                                                                                                                                         |
| 135 |    587.307649 |    115.056456 | NA                                                                                                                                                                                   |
| 136 |    760.687790 |    331.353931 | NA                                                                                                                                                                                   |
| 137 |    748.077995 |    157.556729 | Ferran Sayol                                                                                                                                                                         |
| 138 |    761.815749 |    661.964832 | Lauren Sumner-Rooney                                                                                                                                                                 |
| 139 |    292.194735 |    421.989053 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 140 |    687.923984 |    785.853450 | Jaime Headden                                                                                                                                                                        |
| 141 |     73.869057 |    174.396623 | Matt Crook                                                                                                                                                                           |
| 142 |    960.726620 |    298.073270 | Mathilde Cordellier                                                                                                                                                                  |
| 143 |    469.698072 |    749.503373 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 144 |    503.801525 |    255.698416 | Margot Michaud                                                                                                                                                                       |
| 145 |    581.739677 |    143.872067 | Scott Hartman                                                                                                                                                                        |
| 146 |    598.311984 |    728.687157 | Gareth Monger                                                                                                                                                                        |
| 147 |    538.847664 |    262.906478 | NA                                                                                                                                                                                   |
| 148 |    318.089171 |    369.021118 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 149 |    421.897521 |    510.041122 | Zimices                                                                                                                                                                              |
| 150 |     17.099861 |    493.522387 | Ignacio Contreras                                                                                                                                                                    |
| 151 |     15.109528 |    440.339249 | Abraão B. Leite                                                                                                                                                                      |
| 152 |    397.288378 |    116.937472 | Felix Vaux                                                                                                                                                                           |
| 153 |    958.401550 |    172.706402 | Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael Keesey)                                                                                               |
| 154 |    619.346975 |    574.322178 | Amanda Katzer                                                                                                                                                                        |
| 155 |    580.359976 |    248.626673 | Scott Hartman                                                                                                                                                                        |
| 156 |    152.370183 |    703.510933 | Gareth Monger                                                                                                                                                                        |
| 157 |    632.675766 |    283.996770 | Frank Förster                                                                                                                                                                        |
| 158 |     15.674326 |    463.664726 | Jose Carlos Arenas-Monroy                                                                                                                                                            |
| 159 |    616.360805 |     93.453862 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 160 |    993.736646 |    715.921753 | Felix Vaux                                                                                                                                                                           |
| 161 |   1010.882873 |    737.819452 | Emily Willoughby                                                                                                                                                                     |
| 162 |    948.927543 |    406.862399 | Birgit Lang                                                                                                                                                                          |
| 163 |    626.768856 |     19.259169 | Nobu Tamura                                                                                                                                                                          |
| 164 |    511.250748 |     57.939421 | Andy Wilson                                                                                                                                                                          |
| 165 |    236.913967 |    255.848304 | Ieuan Jones                                                                                                                                                                          |
| 166 |    940.360982 |    346.614477 | Scott Reid                                                                                                                                                                           |
| 167 |    876.835902 |    272.376213 | Ferran Sayol                                                                                                                                                                         |
| 168 |    430.775749 |    529.768255 | Steven Coombs                                                                                                                                                                        |
| 169 |    847.422623 |    711.916634 | Steven Traver                                                                                                                                                                        |
| 170 |    929.826579 |    246.882063 | Jagged Fang Designs                                                                                                                                                                  |
| 171 |    417.759878 |    729.494494 | François Michonneau                                                                                                                                                                  |
| 172 |    421.207020 |    626.878924 | Charles R. Knight, vectorized by Zimices                                                                                                                                             |
| 173 |    921.251167 |    150.802061 | Jake Warner                                                                                                                                                                          |
| 174 |    359.819811 |    487.910571 | Tauana J. Cunha                                                                                                                                                                      |
| 175 |     78.592622 |    501.135553 | Katie S. Collins                                                                                                                                                                     |
| 176 |    632.323229 |    649.037124 | T. Michael Keesey                                                                                                                                                                    |
| 177 |    715.465809 |    201.047074 | Matthew E. Clapham                                                                                                                                                                   |
| 178 |     21.078286 |    508.046290 | Chase Brownstein                                                                                                                                                                     |
| 179 |    312.806339 |    470.418399 | Margot Michaud                                                                                                                                                                       |
| 180 |    560.920258 |    181.344538 | Markus A. Grohme                                                                                                                                                                     |
| 181 |    502.404200 |     12.980781 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 182 |    407.702196 |     61.882759 | Steven Traver                                                                                                                                                                        |
| 183 |    934.996127 |    138.638082 | FunkMonk                                                                                                                                                                             |
| 184 |    199.281402 |     11.642580 | Matt Crook                                                                                                                                                                           |
| 185 |    162.176222 |    684.646300 | Griensteidl and T. Michael Keesey                                                                                                                                                    |
| 186 |    486.479086 |    736.631052 | Original scheme by ‘Haplochromis’, vectorized by Roberto Díaz Sibaja                                                                                                                 |
| 187 |    786.527630 |    343.788357 | Ignacio Contreras                                                                                                                                                                    |
| 188 |    884.067958 |    712.556577 | Sharon Wegner-Larsen                                                                                                                                                                 |
| 189 |    683.169413 |    562.974816 | Chris huh                                                                                                                                                                            |
| 190 |    521.548352 |    616.083145 | Jennifer Trimble                                                                                                                                                                     |
| 191 |    176.056135 |    390.485668 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 192 |    762.831314 |    119.071478 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                                  |
| 193 |    863.648291 |    715.513689 | NA                                                                                                                                                                                   |
| 194 |    177.253618 |    643.844077 | Jaime Headden                                                                                                                                                                        |
| 195 |    700.574110 |    163.455802 | Zimices                                                                                                                                                                              |
| 196 |    898.817871 |    729.148315 | T. Michael Keesey                                                                                                                                                                    |
| 197 |    186.337083 |     92.301783 | Scott Hartman                                                                                                                                                                        |
| 198 |    781.532337 |    671.096078 | Shyamal                                                                                                                                                                              |
| 199 |    155.179728 |    634.343783 | Scott Hartman                                                                                                                                                                        |
| 200 |    314.981931 |    506.470371 | NA                                                                                                                                                                                   |
| 201 |    168.165774 |     12.066542 | Alex Slavenko                                                                                                                                                                        |
| 202 |    890.859103 |    739.315559 | Ricardo N. Martinez & Oscar A. Alcober                                                                                                                                               |
| 203 |    134.978848 |    308.731063 | T. Michael Keesey                                                                                                                                                                    |
| 204 |    597.376165 |    348.551804 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 205 |    766.139602 |    472.825232 | Ferran Sayol                                                                                                                                                                         |
| 206 |    698.595775 |     74.674303 | Anthony Caravaggi                                                                                                                                                                    |
| 207 |    133.909291 |    631.370669 | Harold N Eyster                                                                                                                                                                      |
| 208 |    174.317287 |    470.241234 | Scott Hartman                                                                                                                                                                        |
| 209 |    758.735305 |      5.258070 | Margot Michaud                                                                                                                                                                       |
| 210 |    769.097015 |    400.978613 | NA                                                                                                                                                                                   |
| 211 |    377.888688 |    480.829712 | Claus Rebler                                                                                                                                                                         |
| 212 |    708.102985 |    418.087845 | NA                                                                                                                                                                                   |
| 213 |    943.890800 |    588.268010 | Ville Koistinen (vectorized by T. Michael Keesey)                                                                                                                                    |
| 214 |    680.451465 |     84.403894 | Christoph Schomburg                                                                                                                                                                  |
| 215 |    718.455354 |    502.284750 | Scott Hartman                                                                                                                                                                        |
| 216 |    252.577769 |    288.532019 | Gareth Monger                                                                                                                                                                        |
| 217 |     59.757373 |    445.524455 | Zimices                                                                                                                                                                              |
| 218 |      9.935317 |     51.005783 | Steven Traver                                                                                                                                                                        |
| 219 |    821.546492 |    717.649955 | CNZdenek                                                                                                                                                                             |
| 220 |   1005.267672 |    794.976583 | Ignacio Contreras                                                                                                                                                                    |
| 221 |    827.113305 |    782.502744 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                                       |
| 222 |    719.208705 |    404.908412 | Scott Reid                                                                                                                                                                           |
| 223 |    210.016340 |    763.152253 | Michael Scroggie, from original photograph by John Bettaso, USFWS (original photograph in public domain).                                                                            |
| 224 |    270.803751 |    433.293740 | Richard Parker (vectorized by T. Michael Keesey)                                                                                                                                     |
| 225 |    769.557679 |    680.543943 | NA                                                                                                                                                                                   |
| 226 |    729.819975 |    243.961041 | Hugo Gruson                                                                                                                                                                          |
| 227 |    426.040654 |    613.266655 | NA                                                                                                                                                                                   |
| 228 |     42.846933 |    514.774142 | Chuanixn Yu                                                                                                                                                                          |
| 229 |    802.912386 |    651.130793 | Birgit Lang; original image by virmisco.org                                                                                                                                          |
| 230 |    679.747281 |    610.411123 | Ekaterina Kopeykina (vectorized by T. Michael Keesey)                                                                                                                                |
| 231 |    838.093383 |    310.351062 | Martin R. Smith                                                                                                                                                                      |
| 232 |    202.666011 |    205.054839 | NA                                                                                                                                                                                   |
| 233 |    539.706167 |    190.666998 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 234 |    816.891475 |    112.802809 | T. Michael Keesey                                                                                                                                                                    |
| 235 |    601.572933 |     92.644800 | Gareth Monger                                                                                                                                                                        |
| 236 |     93.630163 |    271.722496 | Sarah Werning                                                                                                                                                                        |
| 237 |    919.440670 |    678.811045 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                                                    |
| 238 |    382.890369 |    445.531794 | Steven Coombs                                                                                                                                                                        |
| 239 |    980.410141 |    787.192792 | Steven Traver                                                                                                                                                                        |
| 240 |    868.011777 |    246.147415 | Matt Crook                                                                                                                                                                           |
| 241 |    980.807631 |    164.827168 | Margot Michaud                                                                                                                                                                       |
| 242 |    207.527122 |    740.727674 | Steven Traver                                                                                                                                                                        |
| 243 |    982.468208 |    380.044162 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 244 |      7.708440 |    173.901586 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 245 |    432.077161 |     24.525402 | Gareth Monger                                                                                                                                                                        |
| 246 |    398.523227 |    644.556528 | Margot Michaud                                                                                                                                                                       |
| 247 |    274.430711 |    414.769000 | Scott Hartman                                                                                                                                                                        |
| 248 |     99.960320 |    228.640999 | Maxime Dahirel                                                                                                                                                                       |
| 249 |    153.440582 |    454.436010 | Markus A. Grohme                                                                                                                                                                     |
| 250 |    868.663320 |    599.282577 | Neil Kelley                                                                                                                                                                          |
| 251 |    752.498467 |    727.423487 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 252 |    949.054973 |    729.089535 | Michael Scroggie                                                                                                                                                                     |
| 253 |      6.822373 |     18.268749 | Maija Karala                                                                                                                                                                         |
| 254 |     18.458964 |    218.171472 | Ferran Sayol                                                                                                                                                                         |
| 255 |    878.962862 |    580.696446 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                                     |
| 256 |    142.795474 |    465.486348 | Siobhon Egan                                                                                                                                                                         |
| 257 |    470.452400 |    509.862071 | Margot Michaud                                                                                                                                                                       |
| 258 |    105.618064 |    572.166173 | NA                                                                                                                                                                                   |
| 259 |    816.537495 |    795.467983 | Christoph Schomburg                                                                                                                                                                  |
| 260 |    931.123297 |    271.326650 | Ferran Sayol                                                                                                                                                                         |
| 261 |    433.725458 |    543.804433 | Gareth Monger                                                                                                                                                                        |
| 262 |    446.531505 |    763.794534 | Emily Willoughby                                                                                                                                                                     |
| 263 |    536.477688 |    445.358065 | Kai R. Caspar                                                                                                                                                                        |
| 264 |    566.000277 |    154.318458 | Pete Buchholz                                                                                                                                                                        |
| 265 |    511.357940 |    232.403114 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                                      |
| 266 |    174.077251 |    462.838896 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                                       |
| 267 |   1015.527240 |    779.536723 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 268 |     73.312370 |    726.153190 | Gareth Monger                                                                                                                                                                        |
| 269 |    716.933484 |    517.088214 | Matt Crook                                                                                                                                                                           |
| 270 |    985.641543 |    402.898477 | Inessa Voet                                                                                                                                                                          |
| 271 |    859.205842 |     15.438859 | Sarah Werning                                                                                                                                                                        |
| 272 |    557.297399 |    251.353532 | Scott Hartman                                                                                                                                                                        |
| 273 |    735.658166 |    363.283112 | Zimices                                                                                                                                                                              |
| 274 |    241.252671 |    107.615375 | Matt Crook                                                                                                                                                                           |
| 275 |    870.484615 |    762.877968 | NA                                                                                                                                                                                   |
| 276 |    803.116056 |    447.302659 | Ferran Sayol                                                                                                                                                                         |
| 277 |    312.979741 |    530.984535 | Mo Hassan                                                                                                                                                                            |
| 278 |    652.354987 |    237.915403 | Zimices                                                                                                                                                                              |
| 279 |    374.906789 |    438.360827 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                                    |
| 280 |    594.805642 |     25.047725 | Ferran Sayol                                                                                                                                                                         |
| 281 |    721.902188 |     62.843216 | Matt Crook                                                                                                                                                                           |
| 282 |    815.351038 |    293.673453 | Emily Willoughby                                                                                                                                                                     |
| 283 |     77.009555 |    521.631044 | Pedro de Siracusa                                                                                                                                                                    |
| 284 |    790.750033 |    478.762587 | Matt Crook                                                                                                                                                                           |
| 285 |    396.295980 |    706.286085 | Lafage                                                                                                                                                                               |
| 286 |    291.573639 |    564.131534 | Gareth Monger                                                                                                                                                                        |
| 287 |    194.722011 |    317.303527 | Jaime Headden                                                                                                                                                                        |
| 288 |     12.132381 |    120.491175 | Matt Crook                                                                                                                                                                           |
| 289 |     98.851797 |    543.511542 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 290 |    158.384806 |    566.814140 | Gareth Monger                                                                                                                                                                        |
| 291 |    925.204177 |    714.107222 | Jake Warner                                                                                                                                                                          |
| 292 |     47.682865 |    154.680054 | Erika Schumacher                                                                                                                                                                     |
| 293 |    946.304863 |    178.059279 | Noah Schlottman, photo from Casey Dunn                                                                                                                                               |
| 294 |     11.753689 |    569.745270 | Karina Garcia                                                                                                                                                                        |
| 295 |    975.330067 |    494.603984 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 296 |    953.624436 |    477.484933 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 297 |   1007.706407 |    413.157883 | Ferran Sayol                                                                                                                                                                         |
| 298 |    446.057587 |    610.037112 | Birgit Lang                                                                                                                                                                          |
| 299 |     39.501108 |    525.481692 | Markus A. Grohme                                                                                                                                                                     |
| 300 |    261.246590 |    596.491139 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 301 |    334.925900 |    483.191669 | Steven Traver                                                                                                                                                                        |
| 302 |    516.278452 |      7.586355 | Margot Michaud                                                                                                                                                                       |
| 303 |   1002.436510 |    405.141462 | Matt Crook                                                                                                                                                                           |
| 304 |    578.990136 |    361.344612 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 305 |    739.189520 |    783.665635 | Steven Traver                                                                                                                                                                        |
| 306 |    112.063027 |    371.977375 | Dean Schnabel                                                                                                                                                                        |
| 307 |     89.075486 |    291.526245 | Iain Reid                                                                                                                                                                            |
| 308 |    469.520750 |    141.595173 | Sarah Werning                                                                                                                                                                        |
| 309 |    966.277739 |    336.244511 | Joanna Wolfe                                                                                                                                                                         |
| 310 |    978.065746 |    653.606537 | Matt Crook                                                                                                                                                                           |
| 311 |    161.359141 |    670.308845 | Birgit Lang                                                                                                                                                                          |
| 312 |      8.251781 |     70.532521 | Andy Wilson                                                                                                                                                                          |
| 313 |    639.634939 |    677.247562 | Sam Droege (photography) and T. Michael Keesey (vectorization)                                                                                                                       |
| 314 |    400.817642 |    659.215095 | DW Bapst (modified from Mitchell 1990)                                                                                                                                               |
| 315 |     58.997781 |     82.660537 | Scott Reid                                                                                                                                                                           |
| 316 |    623.543179 |    307.012287 | Rebecca Groom                                                                                                                                                                        |
| 317 |    449.164711 |    113.905306 | Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus                                                             |
| 318 |    110.553370 |    320.373641 | Yan Wong from drawing by T. F. Zimmermann                                                                                                                                            |
| 319 |    753.238439 |    403.980087 | Nobu Tamura                                                                                                                                                                          |
| 320 |    491.599047 |     32.044738 | Chris huh                                                                                                                                                                            |
| 321 |    911.392291 |    263.607609 | NA                                                                                                                                                                                   |
| 322 |     25.403812 |    376.647964 | Marmelad                                                                                                                                                                             |
| 323 |    534.542165 |    660.386721 | Steve Hillebrand/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                                                   |
| 324 |    721.837815 |     84.554848 | Rebecca Groom                                                                                                                                                                        |
| 325 |    796.054806 |    419.202654 | Raven Amos                                                                                                                                                                           |
| 326 |    619.326166 |    332.959342 | Steven Traver                                                                                                                                                                        |
| 327 |    702.881832 |    746.505017 | NA                                                                                                                                                                                   |
| 328 |    921.115860 |    660.793771 | Michelle Site                                                                                                                                                                        |
| 329 |   1010.370857 |    480.908206 | Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org)                                                                                         |
| 330 |    407.473885 |    100.931175 | NA                                                                                                                                                                                   |
| 331 |    865.115567 |    742.245166 | T. Michael Keesey                                                                                                                                                                    |
| 332 |    393.414562 |    466.871533 | Scott Hartman                                                                                                                                                                        |
| 333 |    435.117282 |    486.998685 | Armin Reindl                                                                                                                                                                         |
| 334 |    683.851756 |    107.285588 | Gordon E. Robertson                                                                                                                                                                  |
| 335 |    185.713536 |    766.441738 | Daniel Stadtmauer                                                                                                                                                                    |
| 336 |    791.552548 |    134.144270 | Maija Karala                                                                                                                                                                         |
| 337 |    129.815329 |     19.164817 | Margot Michaud                                                                                                                                                                       |
| 338 |    555.146138 |     23.225565 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 339 |    910.048590 |    789.274924 | Jan Sevcik (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                           |
| 340 |   1001.490461 |    637.021233 | Erika Schumacher                                                                                                                                                                     |
| 341 |     31.394185 |    445.208118 | Matt Crook                                                                                                                                                                           |
| 342 |    951.581135 |    268.986210 | Jon Hill (Photo by Benjamint444: <http://en.wikipedia.org/wiki/File:Blue-footed-booby.jpg>)                                                                                          |
| 343 |    241.205883 |    306.463718 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 344 |    651.834929 |    480.877709 | Jaime Headden                                                                                                                                                                        |
| 345 |    297.906913 |    699.668616 | Iain Reid                                                                                                                                                                            |
| 346 |     55.091236 |    343.936000 | Dmitry Bogdanov                                                                                                                                                                      |
| 347 |    209.195871 |    780.934952 | Skye McDavid                                                                                                                                                                         |
| 348 |    927.329623 |      6.237106 | Markus A. Grohme                                                                                                                                                                     |
| 349 |    427.872454 |     40.037272 | Scott Hartman                                                                                                                                                                        |
| 350 |    836.240302 |    357.677695 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 351 |    140.640157 |    666.064154 | Emily Willoughby                                                                                                                                                                     |
| 352 |    885.221524 |    655.740572 | Steven Traver                                                                                                                                                                        |
| 353 |    157.949993 |     68.318480 | Sharon Wegner-Larsen                                                                                                                                                                 |
| 354 |    269.520329 |     14.083657 | Noah Schlottman, photo by Casey Dunn                                                                                                                                                 |
| 355 |    967.820164 |    453.695166 | Acrocynus (vectorized by T. Michael Keesey)                                                                                                                                          |
| 356 |    245.999556 |     64.193896 | Zimices                                                                                                                                                                              |
| 357 |    805.404470 |    744.194502 | Ferran Sayol                                                                                                                                                                         |
| 358 |    391.562688 |    105.033515 | Dave Angelini                                                                                                                                                                        |
| 359 |    347.184902 |    575.879897 | Steven Traver                                                                                                                                                                        |
| 360 |    378.015408 |    455.262567 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 361 |    158.534976 |     36.258074 | Collin Gross                                                                                                                                                                         |
| 362 |    644.084022 |    100.003350 | Iain Reid                                                                                                                                                                            |
| 363 |    496.213165 |    128.764190 | Amanda Katzer                                                                                                                                                                        |
| 364 |    438.248411 |    627.404479 | Noah Schlottman, photo by Reinhard Jahn                                                                                                                                              |
| 365 |    429.657452 |    130.910955 | Mali’o Kodis, photograph by P. Funch and R.M. Kristensen                                                                                                                             |
| 366 |    701.632283 |    371.672329 | Chris huh                                                                                                                                                                            |
| 367 |     42.850524 |     85.594670 | Mattia Menchetti                                                                                                                                                                     |
| 368 |    934.967414 |    491.669199 | Chris huh                                                                                                                                                                            |
| 369 |    458.374530 |    475.302818 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                                         |
| 370 |    116.324617 |     21.464800 | Andy Wilson                                                                                                                                                                          |
| 371 |    420.029006 |    417.352449 | Gareth Monger                                                                                                                                                                        |
| 372 |    772.894019 |    737.248509 | Oliver Voigt                                                                                                                                                                         |
| 373 |    245.477847 |    668.358193 | T. Michael Keesey (after Tillyard)                                                                                                                                                   |
| 374 |     28.972736 |    409.041432 | Mario Quevedo                                                                                                                                                                        |
| 375 |     86.181348 |    582.431383 | Michele M Tobias                                                                                                                                                                     |
| 376 |    509.568934 |    546.097355 | Tasman Dixon                                                                                                                                                                         |
| 377 |     76.463318 |     30.474010 | Lily Hughes                                                                                                                                                                          |
| 378 |     11.170033 |      9.632870 | Henry Lydecker                                                                                                                                                                       |
| 379 |    818.363480 |    746.499486 | S.Martini                                                                                                                                                                            |
| 380 |    745.473612 |    412.695653 | Ingo Braasch                                                                                                                                                                         |
| 381 |    762.530108 |     98.410933 | T. Michael Keesey (after MPF)                                                                                                                                                        |
| 382 |    953.372074 |    350.746617 | NA                                                                                                                                                                                   |
| 383 |    771.229155 |    484.209927 | Xavier A. Jenkins, Gabriel Ugueto                                                                                                                                                    |
| 384 |    191.638676 |    539.757109 | Zimices                                                                                                                                                                              |
| 385 |    355.010308 |    508.276560 | NA                                                                                                                                                                                   |
| 386 |    629.530581 |    449.158944 | Chris huh                                                                                                                                                                            |
| 387 |    356.151958 |    791.475031 | White Wolf                                                                                                                                                                           |
| 388 |    390.968222 |    424.606716 | Margot Michaud                                                                                                                                                                       |
| 389 |    382.097517 |    405.240774 | Ferran Sayol                                                                                                                                                                         |
| 390 |    409.875820 |    441.238472 | Markus A. Grohme                                                                                                                                                                     |
| 391 |    117.853301 |     91.239138 | Kamil S. Jaron                                                                                                                                                                       |
| 392 |    647.288835 |     89.608786 | Zimices                                                                                                                                                                              |
| 393 |    914.172987 |    308.719199 | Ferran Sayol                                                                                                                                                                         |
| 394 |    942.824786 |    258.664591 | Erika Schumacher                                                                                                                                                                     |
| 395 |    810.013789 |    403.660053 | Rebecca Groom                                                                                                                                                                        |
| 396 |    345.325608 |    633.220048 | Alan Manson (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                          |
| 397 |    174.529032 |    566.518185 | Matt Crook                                                                                                                                                                           |
| 398 |    375.956412 |    428.764219 | Scott Hartman                                                                                                                                                                        |
| 399 |    961.059715 |    664.675819 | Margot Michaud                                                                                                                                                                       |
| 400 |     78.916033 |    786.969430 | Ignacio Contreras                                                                                                                                                                    |
| 401 |    804.890477 |    361.553136 | Jerry Oldenettel (vectorized by T. Michael Keesey)                                                                                                                                   |
| 402 |     16.860201 |    394.819032 | Gareth Monger                                                                                                                                                                        |
| 403 |    908.414026 |    146.209712 | (after McCulloch 1908)                                                                                                                                                               |
| 404 |    563.000755 |    605.993088 | Skye McDavid                                                                                                                                                                         |
| 405 |    683.751305 |    587.865113 | Erika Schumacher                                                                                                                                                                     |
| 406 |    971.830057 |    680.414983 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 407 |    166.584396 |    337.045568 | Margot Michaud                                                                                                                                                                       |
| 408 |    606.777534 |    168.696825 | Zimices                                                                                                                                                                              |
| 409 |    361.188168 |     18.801067 | NA                                                                                                                                                                                   |
| 410 |    244.781923 |     13.838944 | Matt Crook                                                                                                                                                                           |
| 411 |    727.347129 |    745.614701 | Steven Coombs                                                                                                                                                                        |
| 412 |    658.007456 |    635.869156 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 413 |    674.304154 |    130.372875 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 414 |    327.410648 |    598.884800 | Tracy A. Heath                                                                                                                                                                       |
| 415 |    658.151661 |    606.765349 | Andy Wilson                                                                                                                                                                          |
| 416 |    486.293848 |    457.044373 | Margot Michaud                                                                                                                                                                       |
| 417 |     93.659013 |    483.087986 | Jaime Headden                                                                                                                                                                        |
| 418 |    179.192404 |    710.191128 | NA                                                                                                                                                                                   |
| 419 |    307.525074 |    559.248290 | Matt Crook                                                                                                                                                                           |
| 420 |    985.471931 |    662.735541 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                                          |
| 421 |    912.320640 |    726.684445 | Matt Crook                                                                                                                                                                           |
| 422 |    383.504307 |    556.373209 | Birgit Lang                                                                                                                                                                          |
| 423 |    266.315087 |    642.362388 | NA                                                                                                                                                                                   |
| 424 |    587.275529 |    545.161090 | Tasman Dixon                                                                                                                                                                         |
| 425 |    266.393505 |    550.053586 | L.M. Davalos                                                                                                                                                                         |
| 426 |    767.525627 |    146.935398 | Zachary Quigley                                                                                                                                                                      |
| 427 |     16.667052 |    642.114171 | Gareth Monger                                                                                                                                                                        |
| 428 |    412.897685 |    520.607823 | Jagged Fang Designs                                                                                                                                                                  |
| 429 |     37.142901 |    345.456667 | FunkMonk                                                                                                                                                                             |
| 430 |    431.491788 |    153.767749 | Rebecca Groom                                                                                                                                                                        |
| 431 |    260.893279 |    665.363851 | Ferran Sayol                                                                                                                                                                         |
| 432 |    181.069406 |    791.314320 | Jagged Fang Designs                                                                                                                                                                  |
| 433 |    707.261652 |    380.113365 | Markus A. Grohme                                                                                                                                                                     |
| 434 |    918.758431 |    574.565950 | Tasman Dixon                                                                                                                                                                         |
| 435 |    676.503883 |    660.294214 | Matt Crook                                                                                                                                                                           |
| 436 |    223.833927 |    287.997630 | Yan Wong                                                                                                                                                                             |
| 437 |    243.302910 |    440.212497 | Metalhead64 (vectorized by T. Michael Keesey)                                                                                                                                        |
| 438 |    489.371889 |     52.424988 | Dean Schnabel                                                                                                                                                                        |
| 439 |    237.937922 |    713.813662 | Margot Michaud                                                                                                                                                                       |
| 440 |    491.188666 |    120.065957 | Enoch Joseph Wetsy (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                   |
| 441 |    708.894145 |     54.535615 | Scott Hartman                                                                                                                                                                        |
| 442 |    269.211778 |     32.727351 | NA                                                                                                                                                                                   |
| 443 |     56.090113 |    452.585097 | Lukas Panzarin (vectorized by T. Michael Keesey)                                                                                                                                     |
| 444 |    719.301749 |    681.276922 | Michael Scroggie                                                                                                                                                                     |
| 445 |      8.382488 |    626.597045 | Konsta Happonen, from a CC-BY-NC image by pelhonen on iNaturalist                                                                                                                    |
| 446 |    562.234731 |     11.518351 | Metalhead64 (vectorized by T. Michael Keesey)                                                                                                                                        |
| 447 |    478.233968 |    784.490417 | NA                                                                                                                                                                                   |
| 448 |    584.869247 |    491.787852 | Tracy A. Heath                                                                                                                                                                       |
| 449 |    582.985243 |      6.944992 | Robert Hering                                                                                                                                                                        |
| 450 |    418.837945 |    546.061056 | Beth Reinke                                                                                                                                                                          |
| 451 |    482.736777 |    237.750700 | Scott Hartman                                                                                                                                                                        |
| 452 |    950.299300 |    163.106674 | Ferran Sayol                                                                                                                                                                         |
| 453 |    983.639805 |    582.620213 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 454 |    624.818624 |    422.306036 | Michael Wolf (photo), Hans Hillewaert (editing), T. Michael Keesey (vectorization)                                                                                                   |
| 455 |   1001.464190 |    657.106350 | Brian Gratwicke (photo) and T. Michael Keesey (vectorization)                                                                                                                        |
| 456 |    987.168958 |    135.484668 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 457 |    761.217032 |    435.290795 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 458 |    107.258969 |    208.388927 | T. Michael Keesey (vectorization); Thorsten Assmann, Jörn Buse, Claudia Drees, Ariel-Leib-Leonid Friedman, Tal Levanony, Andrea Matern, Anika Timm, and David W. Wrase (photography) |
| 459 |    185.827653 |     71.009644 | Beth Reinke                                                                                                                                                                          |
| 460 |    393.158559 |    521.963788 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 461 |    496.361449 |    145.953585 | Steven Haddock • Jellywatch.org                                                                                                                                                      |
| 462 |     16.188396 |     84.376853 | Milton Tan                                                                                                                                                                           |
| 463 |     96.688860 |    694.672330 | Tauana J. Cunha                                                                                                                                                                      |
| 464 |    611.055068 |    606.978920 | NA                                                                                                                                                                                   |
| 465 |    881.643635 |    787.537996 | T. Michael Keesey (vectorization) and Tony Hisgett (photography)                                                                                                                     |
| 466 |    637.690182 |     30.475214 | Steven Traver                                                                                                                                                                        |
| 467 |    683.990870 |    641.271990 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 468 |    220.409224 |    594.866085 | Steven Coombs                                                                                                                                                                        |
| 469 |    288.936523 |     25.031955 | Joanna Wolfe                                                                                                                                                                         |
| 470 |    563.710440 |    656.911260 | Robert Gay                                                                                                                                                                           |
| 471 |    762.442008 |    784.729421 | Douglas Brown (modified by T. Michael Keesey)                                                                                                                                        |
| 472 |    704.040326 |    548.124144 | terngirl                                                                                                                                                                             |
| 473 |    413.663006 |    401.286387 | Zimices                                                                                                                                                                              |
| 474 |    396.542994 |    441.858904 | Gareth Monger                                                                                                                                                                        |
| 475 |     18.627127 |    343.441309 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 476 |    993.621295 |    416.046802 | Zimices                                                                                                                                                                              |
| 477 |    466.128744 |     26.605035 | Young and Zhao (1972:figure 4), modified by Michael P. Taylor                                                                                                                        |
| 478 |    313.060313 |    519.604852 | Andy Wilson                                                                                                                                                                          |
| 479 |    663.717428 |    618.601833 | Martin Kevil                                                                                                                                                                         |
| 480 |    927.472030 |    470.777230 | Emily Jane McTavish                                                                                                                                                                  |
| 481 |    880.487815 |    610.427707 | Zimices                                                                                                                                                                              |
| 482 |    453.004027 |    434.195408 | David Tana                                                                                                                                                                           |
| 483 |    692.031727 |    502.985484 | Milton Tan                                                                                                                                                                           |
| 484 |    398.313611 |    562.114654 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                                  |
| 485 |    463.566436 |    469.609870 | Jaime Headden                                                                                                                                                                        |
| 486 |    344.496194 |     10.147247 | Gareth Monger                                                                                                                                                                        |
| 487 |    796.369580 |     44.412540 | Matt Crook                                                                                                                                                                           |
| 488 |     95.017434 |     25.848546 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 489 |    706.704695 |    696.726460 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                                                |
| 490 |    514.709071 |    271.977373 | Matt Crook                                                                                                                                                                           |
| 491 |    699.896044 |    670.582199 | Mali’o Kodis, image by Rebecca Ritger                                                                                                                                                |
| 492 |   1013.778443 |    461.612807 | Andy Wilson                                                                                                                                                                          |
| 493 |    221.398560 |    452.453447 | Gareth Monger                                                                                                                                                                        |
| 494 |    739.495388 |    481.499995 | Katie S. Collins                                                                                                                                                                     |
| 495 |    581.931857 |    329.775960 | Margot Michaud                                                                                                                                                                       |
| 496 |    112.591283 |    510.532295 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 497 |    713.767010 |    785.281255 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                                         |
| 498 |      9.299110 |      3.871568 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                                                    |
| 499 |    146.875874 |    560.174485 | Matt Crook                                                                                                                                                                           |
| 500 |     50.838878 |    732.182743 | Rebecca Groom                                                                                                                                                                        |
| 501 |    459.088253 |    490.888831 | (after McCulloch 1908)                                                                                                                                                               |
| 502 |     29.688813 |    537.729370 | Jaime Headden                                                                                                                                                                        |
| 503 |    420.212385 |    170.809441 | Zimices, based in Mauricio Antón skeletal                                                                                                                                            |
| 504 |    528.794108 |    458.570089 | Scott Hartman                                                                                                                                                                        |
| 505 |    230.275217 |    732.310866 | Margot Michaud                                                                                                                                                                       |
| 506 |    627.650090 |    467.201796 | Steven Traver                                                                                                                                                                        |
| 507 |    279.015610 |    793.238607 | David Tana                                                                                                                                                                           |
| 508 |    318.142132 |    566.619625 | Matt Martyniuk                                                                                                                                                                       |
| 509 |    263.290512 |    314.952727 | Gareth Monger                                                                                                                                                                        |
| 510 |     17.608567 |    655.769243 | Markus A. Grohme                                                                                                                                                                     |
| 511 |     36.860109 |    505.844280 | Walter Vladimir                                                                                                                                                                      |
| 512 |    362.197540 |     86.943978 | Skye M                                                                                                                                                                               |
| 513 |    971.080890 |    400.796670 | Tasman Dixon                                                                                                                                                                         |
| 514 |    248.234396 |    279.040742 | Jonathan Wells                                                                                                                                                                       |
| 515 |    853.936148 |    243.481477 | NA                                                                                                                                                                                   |
| 516 |    138.673037 |    412.586977 | Abraão Leite                                                                                                                                                                         |
| 517 |    436.274166 |    107.595227 | Michael Wolf (photo), Hans Hillewaert (editing), T. Michael Keesey (vectorization)                                                                                                   |
| 518 |    895.938207 |    159.810757 | Sarah Werning                                                                                                                                                                        |
| 519 |    256.985917 |    170.640465 | T. Michael Keesey                                                                                                                                                                    |
| 520 |   1015.092715 |    284.891776 | Ramona J Heim                                                                                                                                                                        |
| 521 |   1011.391432 |    444.347913 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 522 |    761.967339 |     74.659852 | Scott Hartman                                                                                                                                                                        |
| 523 |    509.824251 |    778.393255 | Melissa Broussard                                                                                                                                                                    |
| 524 |    994.031181 |    672.833907 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 525 |     26.733323 |    129.172414 | Margot Michaud                                                                                                                                                                       |
| 526 |    601.056939 |    532.002202 | Scott Hartman                                                                                                                                                                        |
| 527 |    669.676345 |    647.953485 | Noah Schlottman, photo by Adam G. Clause                                                                                                                                             |
| 528 |    978.417620 |    186.742496 | T. Michael Keesey                                                                                                                                                                    |
| 529 |    533.595229 |    131.924711 | Scott Hartman                                                                                                                                                                        |
| 530 |     28.939387 |    197.800195 | Gareth Monger                                                                                                                                                                        |
| 531 |    666.684408 |     96.981651 | Michael Scroggie                                                                                                                                                                     |
| 532 |     82.698221 |    692.107536 | Matt Crook                                                                                                                                                                           |
| 533 |    722.481539 |    730.416596 | Jay Matternes (vectorized by T. Michael Keesey)                                                                                                                                      |
| 534 |     25.450053 |     42.454093 | Armin Reindl                                                                                                                                                                         |
| 535 |    168.962848 |    624.114247 | Armin Reindl                                                                                                                                                                         |
| 536 |    665.329077 |    220.794955 | NA                                                                                                                                                                                   |
| 537 |    421.820896 |    588.287916 | Matt Crook                                                                                                                                                                           |
| 538 |    653.244345 |    639.995399 | Scott Hartman                                                                                                                                                                        |
| 539 |    999.598339 |    204.722378 | Markus A. Grohme                                                                                                                                                                     |
| 540 |    775.242874 |    127.894447 | Erika Schumacher                                                                                                                                                                     |
| 541 |    382.185959 |    669.073087 | Matt Crook                                                                                                                                                                           |
| 542 |    767.907435 |    312.183836 | Matt Crook                                                                                                                                                                           |
| 543 |    345.232389 |    529.985325 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 544 |    695.074420 |    402.141403 | Sam Droege (photo) and T. Michael Keesey (vectorization)                                                                                                                             |
| 545 |    287.307953 |     15.744904 | Neil Kelley                                                                                                                                                                          |
| 546 |     18.393153 |    286.664749 | Lukasiniho                                                                                                                                                                           |
| 547 |    333.417155 |    578.216289 | Pollyanna von Knorring and T. Michael Keesey                                                                                                                                         |
| 548 |     44.331681 |    126.840577 | Richard Lampitt, Jeremy Young / NHM (vectorization by Yan Wong)                                                                                                                      |
| 549 |    544.121994 |    619.333269 | Renata F. Martins                                                                                                                                                                    |
| 550 |    743.047812 |    728.289299 | NA                                                                                                                                                                                   |
| 551 |    426.961942 |     53.416407 | Margot Michaud                                                                                                                                                                       |
| 552 |    220.673940 |     92.852619 | Matt Crook                                                                                                                                                                           |
| 553 |    420.979400 |    108.631727 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 554 |    948.653606 |    218.874606 | Zimices                                                                                                                                                                              |
| 555 |     29.588433 |    211.311648 | Erika Schumacher                                                                                                                                                                     |
| 556 |    554.909793 |    271.243055 | Dean Schnabel                                                                                                                                                                        |
| 557 |    655.547434 |    594.078831 | CNZdenek                                                                                                                                                                             |
| 558 |     17.953691 |    604.252185 | Noah Schlottman, photo by Martin V. Sørensen                                                                                                                                         |
| 559 |    226.550130 |    748.961688 | Matt Martyniuk                                                                                                                                                                       |
| 560 |    575.338294 |     86.550735 | Shyamal                                                                                                                                                                              |
| 561 |    126.059799 |    332.501254 | NA                                                                                                                                                                                   |
| 562 |    660.573644 |    718.109685 | Gareth Monger                                                                                                                                                                        |
| 563 |     12.739436 |    418.321519 | Dean Schnabel                                                                                                                                                                        |
| 564 |    887.981289 |    242.984208 | Birgit Lang                                                                                                                                                                          |
| 565 |     94.309630 |    716.084290 | Joanna Wolfe                                                                                                                                                                         |
| 566 |    582.853136 |    320.278994 | Zimices                                                                                                                                                                              |
| 567 |    695.010352 |    523.872325 | New York Zoological Society                                                                                                                                                          |
| 568 |    216.526038 |    216.091648 | Emily Willoughby                                                                                                                                                                     |
| 569 |    394.653344 |    724.431955 | Jennifer Trimble                                                                                                                                                                     |
| 570 |    395.748517 |    537.389714 | Matt Crook                                                                                                                                                                           |
| 571 |     34.455078 |    270.108431 | Ignacio Contreras                                                                                                                                                                    |
| 572 |    853.630727 |    335.685581 | Dann Pigdon                                                                                                                                                                          |
| 573 |    218.769160 |    584.477907 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 574 |    583.052359 |    378.138775 | T. Michael Keesey                                                                                                                                                                    |
| 575 |    360.866452 |     29.015055 | Johan Lindgren, Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe                                                                                                                 |
| 576 |    675.957061 |     70.616019 | Joshua Fowler                                                                                                                                                                        |
| 577 |    602.394956 |     14.868753 | Smokeybjb (modified by Mike Keesey)                                                                                                                                                  |
| 578 |    155.653465 |     81.099340 | Jonathan Wells                                                                                                                                                                       |
| 579 |    181.287430 |    663.132160 | Michael Scroggie                                                                                                                                                                     |
| 580 |    438.574977 |    429.200231 | Steven Haddock • Jellywatch.org                                                                                                                                                      |
| 581 |    841.895674 |     24.307663 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                                     |
| 582 |    805.557079 |    328.171969 | Scott Hartman                                                                                                                                                                        |
| 583 |    152.501133 |    341.441148 | NA                                                                                                                                                                                   |
| 584 |    226.456832 |     79.265965 | NA                                                                                                                                                                                   |
| 585 |     58.021861 |    636.853506 | NA                                                                                                                                                                                   |
| 586 |    651.340516 |     40.514974 | Kanchi Nanjo                                                                                                                                                                         |
| 587 |    759.119496 |    745.718062 | Margot Michaud                                                                                                                                                                       |
| 588 |    638.790131 |    662.783525 | Duane Raver (vectorized by T. Michael Keesey)                                                                                                                                        |
| 589 |    820.700227 |     39.056653 | Kai R. Caspar                                                                                                                                                                        |
| 590 |    109.667971 |    687.767962 | Harold N Eyster                                                                                                                                                                      |
| 591 |     46.822835 |    492.540256 | Cesar Julian                                                                                                                                                                         |
| 592 |   1005.471057 |    347.343957 | Jimmy Bernot                                                                                                                                                                         |
| 593 |     29.472281 |    318.465869 | T. Michael Keesey                                                                                                                                                                    |
| 594 |     44.579529 |    380.186919 | Margot Michaud                                                                                                                                                                       |
| 595 |    157.553468 |    786.519718 | Kamil S. Jaron                                                                                                                                                                       |
| 596 |    473.957784 |    455.251853 | Gareth Monger                                                                                                                                                                        |
| 597 |    102.462865 |    596.154294 | Iain Reid                                                                                                                                                                            |
| 598 |     13.765933 |    320.124300 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 599 |    795.575512 |    391.684411 | Jaime Headden                                                                                                                                                                        |
| 600 |    632.637557 |    440.977111 | Tauana J. Cunha                                                                                                                                                                      |
| 601 |    574.522622 |    669.593490 | Scott Hartman                                                                                                                                                                        |
| 602 |    202.173520 |     21.953524 | Caleb Brown                                                                                                                                                                          |
| 603 |    239.711661 |    637.862141 | Leann Biancani, photo by Kenneth Clifton                                                                                                                                             |
| 604 |    933.133524 |    203.083530 | Matt Crook                                                                                                                                                                           |
| 605 |    365.316625 |    463.689237 | NA                                                                                                                                                                                   |
| 606 |    827.484333 |    724.654315 | Erika Schumacher                                                                                                                                                                     |
| 607 |    812.221554 |    426.653095 | Tracy A. Heath                                                                                                                                                                       |
| 608 |    961.611147 |    267.853080 | Michael Scroggie, from original photograph by Gary M. Stolz, USFWS (original photograph in public domain).                                                                           |
| 609 |    282.166262 |    646.264374 | Mo Hassan                                                                                                                                                                            |
| 610 |    836.673295 |    248.144784 | T. Michael Keesey                                                                                                                                                                    |
| 611 |    997.158452 |    484.679537 | Jagged Fang Designs                                                                                                                                                                  |
| 612 |    341.018146 |    520.146080 | NA                                                                                                                                                                                   |
| 613 |     34.920043 |    499.165794 | Gareth Monger                                                                                                                                                                        |
| 614 |    714.170572 |    364.442425 | Mathilde Cordellier                                                                                                                                                                  |
| 615 |    326.940918 |    441.453711 | Ferran Sayol                                                                                                                                                                         |
| 616 |    108.740138 |    535.531605 | Kamil S. Jaron                                                                                                                                                                       |
| 617 |    633.204063 |    165.537875 | Matt Crook                                                                                                                                                                           |
| 618 |    556.440773 |    477.942577 | Michael Scroggie, from original photograph by Gary M. Stolz, USFWS (original photograph in public domain).                                                                           |
| 619 |    736.530668 |    422.724890 | (after Spotila 2004)                                                                                                                                                                 |
| 620 |    425.417256 |     94.695882 | Robert Bruce Horsfall (vectorized by William Gearty)                                                                                                                                 |
| 621 |    826.897866 |    299.244783 | Chris huh                                                                                                                                                                            |
| 622 |    443.121795 |    173.879176 | T. Michael Keesey                                                                                                                                                                    |
| 623 |    164.667422 |     52.191057 | Matt Martyniuk                                                                                                                                                                       |
| 624 |    600.588838 |    296.308203 | Xavier Giroux-Bougard                                                                                                                                                                |
| 625 |    410.302553 |    143.610173 | T. Michael Keesey (vector) and Stuart Halliday (photograph)                                                                                                                          |
| 626 |    473.490495 |    603.702945 | Chris huh                                                                                                                                                                            |
| 627 |    501.166386 |    245.943617 | Matt Crook                                                                                                                                                                           |
| 628 |    707.064363 |    285.988022 | M Kolmann                                                                                                                                                                            |
| 629 |    514.512113 |    656.979141 | Mario Quevedo                                                                                                                                                                        |
| 630 |    903.631548 |    272.091578 | Martin R. Smith                                                                                                                                                                      |
| 631 |    985.608393 |    645.794818 | Tyler Greenfield                                                                                                                                                                     |
| 632 |    653.710934 |    702.672223 | T. Michael Keesey                                                                                                                                                                    |
| 633 |    233.734655 |    768.207435 | Michelle Site                                                                                                                                                                        |
| 634 |    262.414659 |     21.009871 | Darius Nau                                                                                                                                                                           |
| 635 |    513.823563 |    732.388179 | Rebecca Groom                                                                                                                                                                        |
| 636 |    895.163530 |    649.536342 | Mathilde Cordellier                                                                                                                                                                  |
| 637 |    581.376711 |    657.088389 | Steven Traver                                                                                                                                                                        |
| 638 |   1010.037288 |    722.456111 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 639 |     21.139505 |     23.794487 | Lily Hughes                                                                                                                                                                          |
| 640 |    135.165876 |    482.773289 | Zimices                                                                                                                                                                              |
| 641 |    291.290706 |    525.871832 | Michelle Site                                                                                                                                                                        |
| 642 |     29.479115 |    591.040470 | Gareth Monger                                                                                                                                                                        |
| 643 |    627.711818 |    688.476025 | L. Shyamal                                                                                                                                                                           |
| 644 |    339.475416 |    698.375545 | Sarah Werning                                                                                                                                                                        |
| 645 |    324.892297 |    485.036808 | JJ Harrison (vectorized by T. Michael Keesey)                                                                                                                                        |
| 646 |     14.113069 |    715.251904 | Maija Karala                                                                                                                                                                         |
| 647 |    688.607690 |    547.012643 | Brian Gratwicke (photo) and T. Michael Keesey (vectorization)                                                                                                                        |
| 648 |    616.636491 |    149.849081 | Gareth Monger                                                                                                                                                                        |
| 649 |    591.600724 |    678.186174 | Frederick William Frohawk (vectorized by T. Michael Keesey)                                                                                                                          |
| 650 |    965.538619 |    220.582975 | Markus A. Grohme                                                                                                                                                                     |
| 651 |    446.957473 |    523.657000 | NA                                                                                                                                                                                   |
| 652 |    964.785778 |    711.983472 | Maha Ghazal                                                                                                                                                                          |
| 653 |    486.202476 |     12.300503 | Melissa Broussard                                                                                                                                                                    |
| 654 |    494.159547 |    152.415724 | Duane Raver (vectorized by T. Michael Keesey)                                                                                                                                        |
| 655 |     66.055841 |    438.797419 | Chris huh                                                                                                                                                                            |
| 656 |    540.253600 |    288.149051 | Zimices                                                                                                                                                                              |
| 657 |    994.426504 |    145.658306 | Scott Hartman                                                                                                                                                                        |
| 658 |    673.757838 |    416.496944 | Matt Wilkins (photo by Patrick Kavanagh)                                                                                                                                             |
| 659 |     87.751627 |    640.586216 | Steven Traver                                                                                                                                                                        |
| 660 |    581.760614 |    201.084354 | Matt Crook                                                                                                                                                                           |
| 661 |    668.365734 |    185.582278 | Emily Jane McTavish                                                                                                                                                                  |
| 662 |     39.094051 |     50.398156 | Margot Michaud                                                                                                                                                                       |
| 663 |    755.261014 |    240.185696 | Steven Blackwood                                                                                                                                                                     |
| 664 |    882.180298 |    747.391145 | Steven Traver                                                                                                                                                                        |
| 665 |    243.944487 |    461.379749 | Matt Crook                                                                                                                                                                           |
| 666 |    847.996541 |    733.676770 | Sean McCann                                                                                                                                                                          |
| 667 |    961.484755 |    152.117540 | Erika Schumacher                                                                                                                                                                     |
| 668 |    186.136223 |     27.498444 | Darius Nau                                                                                                                                                                           |
| 669 |   1014.516580 |    639.235798 | NA                                                                                                                                                                                   |
| 670 |    388.418591 |    684.084027 | Iain Reid                                                                                                                                                                            |
| 671 |    535.912404 |    302.671198 | Noah Schlottman, photo by Gustav Paulay for Moorea Biocode                                                                                                                           |
| 672 |    308.717926 |    423.468373 | Margot Michaud                                                                                                                                                                       |
| 673 |    496.746755 |    785.599127 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 674 |   1000.056299 |    509.600737 | Bill Bouton (source photo) & T. Michael Keesey (vectorization)                                                                                                                       |
| 675 |    521.303487 |    194.470690 | Joanna Wolfe                                                                                                                                                                         |
| 676 |    586.665783 |    230.377168 | Steven Coombs                                                                                                                                                                        |
| 677 |     72.419218 |    639.905142 | L. Shyamal                                                                                                                                                                           |
| 678 |    995.379096 |    433.950361 | Leann Biancani, photo by Kenneth Clifton                                                                                                                                             |
| 679 |    557.243583 |    340.197291 | Jakovche                                                                                                                                                                             |
| 680 |    236.282860 |    693.289185 | NA                                                                                                                                                                                   |
| 681 |    228.344103 |    242.030425 | Birgit Lang                                                                                                                                                                          |
| 682 |    975.837956 |    417.297020 | Margot Michaud                                                                                                                                                                       |
| 683 |    615.541656 |    599.274050 | Chloé Schmidt                                                                                                                                                                        |
| 684 |    611.065112 |    751.366951 | Samanta Orellana                                                                                                                                                                     |
| 685 |    333.478910 |    606.514095 | Jack Mayer Wood                                                                                                                                                                      |
| 686 |    901.363041 |    305.521877 | Konsta Happonen, from a CC-BY-NC image by sokolkov2002 on iNaturalist                                                                                                                |
| 687 |    832.533202 |    685.114542 | Jagged Fang Designs                                                                                                                                                                  |
| 688 |    651.344830 |     58.236921 | Ludwik Gąsiorowski                                                                                                                                                                   |
| 689 |    513.377837 |    518.422770 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 690 |    801.330256 |     97.901347 | Jagged Fang Designs                                                                                                                                                                  |
| 691 |    999.838119 |    393.203451 | Sharon Wegner-Larsen                                                                                                                                                                 |
| 692 |    710.588345 |    110.509423 | Sam Droege (photo) and T. Michael Keesey (vectorization)                                                                                                                             |
| 693 |    863.657628 |    354.056452 | Iain Reid                                                                                                                                                                            |
| 694 |    709.547581 |    153.487104 | Matt Crook                                                                                                                                                                           |
| 695 |    779.550801 |    103.263758 | T. Michael Keesey (photo by Sean Mack)                                                                                                                                               |
| 696 |    186.423738 |    416.977179 | Steven Traver                                                                                                                                                                        |
| 697 |    142.205915 |    684.327411 | T. Michael Keesey                                                                                                                                                                    |
| 698 |    609.868177 |    409.450875 | FunkMonk                                                                                                                                                                             |
| 699 |    792.459873 |    308.958182 | Tyler Greenfield                                                                                                                                                                     |
| 700 |    995.366150 |    175.361744 | Ferran Sayol                                                                                                                                                                         |
| 701 |     40.166199 |     38.436464 | Margot Michaud                                                                                                                                                                       |
| 702 |    695.272083 |    279.025864 | Pedro de Siracusa                                                                                                                                                                    |
| 703 |    257.223559 |    773.624033 | Chris Hay                                                                                                                                                                            |
| 704 |    761.284069 |    149.044185 | Karl Ragnar Gjertsen (vectorized by T. Michael Keesey)                                                                                                                               |
| 705 |    795.058497 |    385.912238 | SauropodomorphMonarch                                                                                                                                                                |
| 706 |    534.390793 |     77.562905 | Frederick William Frohawk (vectorized by T. Michael Keesey)                                                                                                                          |
| 707 |    518.424832 |    140.042039 | Chris huh                                                                                                                                                                            |
| 708 |    107.329807 |      9.464555 | Chris huh                                                                                                                                                                            |
| 709 |    229.179490 |    667.544776 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 710 |    482.004244 |    175.886626 | NOAA (vectorized by T. Michael Keesey)                                                                                                                                               |
| 711 |    264.496748 |     45.597499 | Iain Reid                                                                                                                                                                            |
| 712 |    770.460203 |     25.808307 | Ferran Sayol                                                                                                                                                                         |
| 713 |    963.473479 |    587.748249 | J. J. Harrison (photo) & T. Michael Keesey                                                                                                                                           |
| 714 |     94.216981 |    524.626201 | Sergio A. Muñoz-Gómez                                                                                                                                                                |
| 715 |    194.122351 |    787.532042 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 716 |    596.330853 |    416.205184 | Mattia Menchetti                                                                                                                                                                     |
| 717 |   1015.433550 |     20.289217 | Margot Michaud                                                                                                                                                                       |
| 718 |    204.846193 |    365.306047 | Ferran Sayol                                                                                                                                                                         |
| 719 |    906.433967 |     20.891422 | Zimices                                                                                                                                                                              |
| 720 |    705.795511 |    795.271160 | Kevin Sánchez                                                                                                                                                                        |
| 721 |    720.766202 |    388.403240 | Riccardo Percudani                                                                                                                                                                   |
| 722 |    461.175795 |    786.716476 | Ferran Sayol                                                                                                                                                                         |
| 723 |    215.452144 |      9.981680 | Matthew E. Clapham                                                                                                                                                                   |
| 724 |    855.972314 |    685.086968 | Scott Hartman                                                                                                                                                                        |
| 725 |    483.499641 |    584.969512 | T. Michael Keesey                                                                                                                                                                    |
| 726 |    537.718837 |    151.543675 | Yan Wong                                                                                                                                                                             |
| 727 |    540.561112 |    482.608040 | Oscar Sanisidro                                                                                                                                                                      |
| 728 |    419.383912 |    661.605489 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 729 |    703.639915 |    738.436415 | Ignacio Contreras                                                                                                                                                                    |
| 730 |    937.453238 |    739.928233 | Steven Traver                                                                                                                                                                        |
| 731 |    213.989822 |    459.341838 | Gareth Monger                                                                                                                                                                        |
| 732 |    932.855493 |    220.041169 | Katie S. Collins                                                                                                                                                                     |
| 733 |    503.237229 |    589.027399 | NA                                                                                                                                                                                   |
| 734 |    240.748905 |    786.143480 | Ignacio Contreras                                                                                                                                                                    |
| 735 |    247.062364 |     89.134927 | Jerry Oldenettel (vectorized by T. Michael Keesey)                                                                                                                                   |
| 736 |   1004.124490 |    732.904747 | Steven Traver                                                                                                                                                                        |
| 737 |    593.419970 |    156.715464 | Iain Reid                                                                                                                                                                            |
| 738 |    577.126030 |    198.209136 | Chris huh                                                                                                                                                                            |
| 739 |     32.040456 |    109.809639 | Steven Traver                                                                                                                                                                        |
| 740 |    510.091640 |     31.819427 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 741 |     94.403795 |    442.728553 | V. Deepak                                                                                                                                                                            |
| 742 |    158.227054 |    730.676118 | Margot Michaud                                                                                                                                                                       |
| 743 |    716.102484 |    414.478428 | Chris huh                                                                                                                                                                            |
| 744 |    888.016930 |     11.459102 | Ingo Braasch                                                                                                                                                                         |
| 745 |    787.462171 |    661.995266 | Steven Traver                                                                                                                                                                        |
| 746 |     88.004638 |    223.025483 | Jon Hill                                                                                                                                                                             |
| 747 |    933.714855 |    370.893264 | Steven Traver                                                                                                                                                                        |
| 748 |    319.901889 |    581.783251 | Zimices                                                                                                                                                                              |
| 749 |    174.135335 |    219.155792 | Lukasiniho                                                                                                                                                                           |
| 750 |    651.842332 |    497.945667 | Margot Michaud                                                                                                                                                                       |
| 751 |    752.911004 |    357.615351 | Zimices                                                                                                                                                                              |
| 752 |    416.674460 |     19.240926 | Gareth Monger                                                                                                                                                                        |
| 753 |    205.126585 |    464.565267 | Ferran Sayol                                                                                                                                                                         |
| 754 |    631.471864 |    333.515859 | T. Michael Keesey                                                                                                                                                                    |
| 755 |    946.725526 |    144.342926 | Matt Crook                                                                                                                                                                           |
| 756 |    954.305215 |    366.118858 | NA                                                                                                                                                                                   |
| 757 |    389.576498 |     91.225876 | Matt Martyniuk (modified by Serenchia)                                                                                                                                               |
| 758 |    302.473342 |    534.458442 | Lukasiniho                                                                                                                                                                           |
| 759 |    530.493995 |    607.918442 | Zimices                                                                                                                                                                              |
| 760 |    361.828496 |    718.494117 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                                          |
| 761 |    433.113629 |     35.760118 | Jagged Fang Designs                                                                                                                                                                  |
| 762 |    331.561641 |    490.825039 | Maija Karala                                                                                                                                                                         |
| 763 |    166.862411 |    184.760193 | Margot Michaud                                                                                                                                                                       |
| 764 |      8.276323 |    674.408379 | Jose Carlos Arenas-Monroy                                                                                                                                                            |
| 765 |    555.691359 |    558.337533 | Birgit Lang                                                                                                                                                                          |
| 766 |    484.084731 |    229.823293 | Melissa Broussard                                                                                                                                                                    |
| 767 |    985.696749 |    458.750992 | Neil Kelley                                                                                                                                                                          |
| 768 |    505.131860 |     20.850003 | Jaime Headden                                                                                                                                                                        |
| 769 |   1010.570902 |    524.398950 | NA                                                                                                                                                                                   |
| 770 |    606.302537 |    118.692699 | Mason McNair                                                                                                                                                                         |
| 771 |    483.569734 |    468.449912 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 772 |    354.862296 |    743.409305 | Ferran Sayol                                                                                                                                                                         |
| 773 |    671.706657 |    715.930857 | Tommaso Cancellario                                                                                                                                                                  |
| 774 |    992.002166 |    221.202117 | Maija Karala                                                                                                                                                                         |
| 775 |    225.443280 |    772.890672 | Margot Michaud                                                                                                                                                                       |
| 776 |    933.427050 |    457.110509 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                                          |
| 777 |    488.621028 |     37.746546 | Cristopher Silva                                                                                                                                                                     |
| 778 |    751.362983 |    707.930964 | Geoff Shaw                                                                                                                                                                           |
| 779 |    201.054517 |    550.143746 | Margot Michaud                                                                                                                                                                       |
| 780 |    353.655650 |    683.237190 | NA                                                                                                                                                                                   |
| 781 |    239.275477 |    453.614013 | Jose Carlos Arenas-Monroy                                                                                                                                                            |
| 782 |    581.705219 |    390.362624 | Yan Wong                                                                                                                                                                             |
| 783 |    528.041093 |    437.995030 | Maija Karala                                                                                                                                                                         |
| 784 |    555.105010 |    328.452965 | Ingo Braasch                                                                                                                                                                         |
| 785 |    957.105492 |    226.309695 | Scott Hartman (modified by T. Michael Keesey)                                                                                                                                        |
| 786 |     76.221350 |     95.605717 | Ferran Sayol                                                                                                                                                                         |
| 787 |    617.620116 |    321.718640 | Scott Reid                                                                                                                                                                           |
| 788 |     85.880198 |    104.380644 | Jagged Fang Designs                                                                                                                                                                  |
| 789 |    329.449096 |    450.609019 | Gareth Monger                                                                                                                                                                        |
| 790 |     49.174036 |    327.269354 | Xavier Giroux-Bougard                                                                                                                                                                |
| 791 |    668.831566 |    374.264129 | Jaime Headden                                                                                                                                                                        |
| 792 |    155.153393 |    212.596111 | Katie S. Collins                                                                                                                                                                     |
| 793 |    593.004527 |    241.597524 | Andy Wilson                                                                                                                                                                          |
| 794 |    493.713891 |    506.120838 | Rebecca Groom (Based on Photo by Andreas Trepte)                                                                                                                                     |
| 795 |    694.329238 |    350.307554 | Jagged Fang Designs                                                                                                                                                                  |
| 796 |    125.368974 |    615.561226 | Andy Wilson                                                                                                                                                                          |
| 797 |    421.531636 |    498.986960 | Zachary Quigley                                                                                                                                                                      |
| 798 |    295.944731 |    345.186498 | Matt Crook                                                                                                                                                                           |
| 799 |    455.401802 |    424.408242 | Jagged Fang Designs                                                                                                                                                                  |
| 800 |    698.364403 |    119.499802 | Scott Hartman                                                                                                                                                                        |
| 801 |    992.536782 |    447.694874 | Ferran Sayol                                                                                                                                                                         |
| 802 |    454.495846 |     51.050901 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 803 |    280.962252 |    319.050560 | Matt Crook                                                                                                                                                                           |
| 804 |    657.529298 |    361.315245 | Dean Schnabel                                                                                                                                                                        |
| 805 |    133.871033 |    508.661342 | Ferran Sayol                                                                                                                                                                         |
| 806 |    643.943753 |    631.184347 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 807 |   1014.068429 |    390.045473 | Margot Michaud                                                                                                                                                                       |
| 808 |    708.755846 |    632.211888 | Zimices                                                                                                                                                                              |
| 809 |    728.145509 |    790.748082 | Matt Crook                                                                                                                                                                           |
| 810 |    895.368467 |    269.789190 | Taro Maeda                                                                                                                                                                           |
| 811 |    791.117479 |     88.390276 | Trond R. Oskars                                                                                                                                                                      |
| 812 |    956.591106 |    679.384147 | Peileppe                                                                                                                                                                             |
| 813 |    322.218189 |    541.717116 | Ferran Sayol                                                                                                                                                                         |
| 814 |    635.869427 |    145.810478 | Jagged Fang Designs                                                                                                                                                                  |
| 815 |    163.160122 |    403.305861 | Steven Traver                                                                                                                                                                        |
| 816 |    494.920395 |    704.432445 | Scott Hartman                                                                                                                                                                        |
| 817 |    335.451559 |    736.189234 | Michelle Site                                                                                                                                                                        |
| 818 |    461.353762 |     42.856293 | Steven Traver                                                                                                                                                                        |
| 819 |    253.180376 |    676.917743 | Andy Wilson                                                                                                                                                                          |
| 820 |    726.366610 |    367.145448 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 821 |    468.550335 |    737.384681 | Zimices                                                                                                                                                                              |
| 822 |    379.232382 |     37.393226 | Gareth Monger                                                                                                                                                                        |
| 823 |    153.926978 |    180.026183 | Steven Traver                                                                                                                                                                        |
| 824 |    339.186964 |    461.420787 | Katie S. Collins                                                                                                                                                                     |
| 825 |    111.653751 |    344.980956 | Chris huh                                                                                                                                                                            |
| 826 |    882.243062 |    132.212994 | Steven Traver                                                                                                                                                                        |
| 827 |    125.073020 |    453.984577 | Chuanixn Yu                                                                                                                                                                          |
| 828 |    883.757480 |    638.438915 | Tauana J. Cunha                                                                                                                                                                      |
| 829 |    269.481723 |    562.748499 | Erika Schumacher                                                                                                                                                                     |
| 830 |    196.063088 |    332.190232 | Jose Carlos Arenas-Monroy                                                                                                                                                            |
| 831 |    548.502327 |      7.814686 | Matt Crook                                                                                                                                                                           |
| 832 |    845.178556 |    273.894502 | Sergio A. Muñoz-Gómez                                                                                                                                                                |
| 833 |    300.943399 |     17.541785 | Ferran Sayol                                                                                                                                                                         |
| 834 |     50.368280 |    557.477669 | T. Michael Keesey                                                                                                                                                                    |
| 835 |    955.834299 |    439.480020 | Tracy A. Heath                                                                                                                                                                       |
| 836 |    900.482214 |    134.679620 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 837 |    947.179128 |     30.824260 | Matt Crook                                                                                                                                                                           |
| 838 |    663.150625 |    666.567592 | Juan Carlos Jerí                                                                                                                                                                     |
| 839 |    421.583149 |    649.798314 | Margot Michaud                                                                                                                                                                       |
| 840 |    598.759635 |      8.992337 | www.studiospectre.com                                                                                                                                                                |
| 841 |    406.446049 |     72.232386 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                                          |
| 842 |    606.690291 |    664.684986 | Rebecca Groom                                                                                                                                                                        |
| 843 |    210.566874 |    237.292015 | Matt Crook                                                                                                                                                                           |
| 844 |    742.663355 |    392.453300 | NA                                                                                                                                                                                   |
| 845 |    727.407707 |    754.244165 | Andrew A. Farke                                                                                                                                                                      |
| 846 |     37.816552 |     30.127440 | Francesco “Architetto” Rollandin                                                                                                                                                     |
| 847 |    519.342863 |    631.934973 | Tauana J. Cunha                                                                                                                                                                      |
| 848 |    554.251344 |    598.812312 | Steven Coombs                                                                                                                                                                        |
| 849 |    122.287076 |    553.626104 | Dean Schnabel                                                                                                                                                                        |
| 850 |    961.111502 |      6.407702 | Michele Tobias                                                                                                                                                                       |
| 851 |    731.751965 |     14.504438 | Kamil S. Jaron                                                                                                                                                                       |
| 852 |    282.707088 |    664.768435 | Shyamal                                                                                                                                                                              |
| 853 |    637.772523 |    298.583978 | Maija Karala                                                                                                                                                                         |
| 854 |    997.327171 |    498.692707 | NA                                                                                                                                                                                   |
| 855 |    941.933211 |    472.911769 | Andy Wilson                                                                                                                                                                          |
| 856 |     53.910910 |    356.291983 | Kamil S. Jaron                                                                                                                                                                       |
| 857 |    511.915771 |    504.665657 | Steven Traver                                                                                                                                                                        |
| 858 |    320.346906 |    461.079309 | Brian Swartz (vectorized by T. Michael Keesey)                                                                                                                                       |
| 859 |    373.642083 |    101.352261 | Maxime Dahirel                                                                                                                                                                       |
| 860 |    947.595065 |    454.068679 | Melissa Broussard                                                                                                                                                                    |
| 861 |     48.737394 |    772.553072 | T. Michael Keesey                                                                                                                                                                    |
| 862 |    236.668866 |    270.801862 | Griensteidl and T. Michael Keesey                                                                                                                                                    |
| 863 |    974.910676 |     39.788312 | Gareth Monger                                                                                                                                                                        |
| 864 |    527.054627 |    179.238130 | Javiera Constanzo                                                                                                                                                                    |
| 865 |    588.257636 |     81.316418 | Alex Slavenko                                                                                                                                                                        |
| 866 |      7.690897 |    402.359989 | Terpsichores                                                                                                                                                                         |
| 867 |    627.135757 |    612.306571 | Arthur S. Brum                                                                                                                                                                       |
| 868 |    593.741149 |     37.195606 | Birgit Lang                                                                                                                                                                          |
| 869 |    484.378616 |    770.761954 | NOAA (vectorized by T. Michael Keesey)                                                                                                                                               |
| 870 |    704.830934 |    180.483456 | Steven Traver                                                                                                                                                                        |
| 871 |   1001.557540 |    455.558353 | Andy Wilson                                                                                                                                                                          |
| 872 |    743.698083 |    326.731886 | Jagged Fang Designs                                                                                                                                                                  |
| 873 |    111.386174 |    492.464160 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 874 |    525.709435 |     20.968934 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 875 |    524.626085 |    286.543012 | Sarah Werning                                                                                                                                                                        |
| 876 |    111.745424 |    180.237679 | T. Michael Keesey                                                                                                                                                                    |
| 877 |    633.342273 |    594.256031 | Harold N Eyster                                                                                                                                                                      |
| 878 |    168.631319 |    778.494069 | Dmitry Bogdanov                                                                                                                                                                      |
| 879 |    228.655845 |    370.299756 | Matt Crook                                                                                                                                                                           |
| 880 |    719.577763 |    231.783620 | Harold N Eyster                                                                                                                                                                      |
| 881 |    228.793484 |    261.784983 | Jagged Fang Designs                                                                                                                                                                  |
| 882 |    722.786442 |    322.276025 | Emil Schmidt (vectorized by Maxime Dahirel)                                                                                                                                          |
| 883 |     36.348701 |    281.328870 | NA                                                                                                                                                                                   |
| 884 |    736.844809 |    351.838591 | Lafage                                                                                                                                                                               |
| 885 |    285.607442 |     90.822457 | Gareth Monger                                                                                                                                                                        |
| 886 |    156.364899 |    387.362995 | Johan Lindgren, Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe                                                                                                                 |
| 887 |    750.805157 |    100.538271 | Jimmy Bernot                                                                                                                                                                         |
| 888 |    965.247843 |    159.695368 | Iain Reid                                                                                                                                                                            |
| 889 |    604.236565 |    175.814889 | Jack Mayer Wood                                                                                                                                                                      |
| 890 |    998.349855 |    598.102147 | Ferran Sayol                                                                                                                                                                         |
| 891 |    623.213284 |    293.027548 | Zimices                                                                                                                                                                              |
| 892 |    782.081301 |    293.604595 | Andy Wilson                                                                                                                                                                          |
| 893 |    771.370819 |     15.747167 | Jagged Fang Designs                                                                                                                                                                  |
| 894 |    698.344029 |    648.959374 | Zimices                                                                                                                                                                              |
| 895 |    781.228319 |    378.641163 | Ferran Sayol                                                                                                                                                                         |
| 896 |    250.004330 |    756.481237 | Ferran Sayol                                                                                                                                                                         |
| 897 |   1015.179990 |    189.650805 | Zimices                                                                                                                                                                              |
| 898 |    581.926841 |     21.581926 | Jagged Fang Designs                                                                                                                                                                  |
| 899 |     34.754285 |     94.601743 | Tasman Dixon                                                                                                                                                                         |
| 900 |     26.852552 |    332.566204 | Margot Michaud                                                                                                                                                                       |
| 901 |    226.393058 |    172.131841 | Iain Reid                                                                                                                                                                            |
| 902 |    757.067795 |    353.167187 | Jagged Fang Designs                                                                                                                                                                  |
| 903 |      9.061567 |    200.864887 | S.Martini                                                                                                                                                                            |
| 904 |     77.148691 |    576.270318 | John Conway                                                                                                                                                                          |
| 905 |    835.269730 |     32.977851 | Ferran Sayol                                                                                                                                                                         |
| 906 |    658.806883 |    325.785061 | Markus A. Grohme                                                                                                                                                                     |
| 907 |    506.108940 |    443.632164 | Ferran Sayol                                                                                                                                                                         |
| 908 |    753.468196 |     57.061174 | Matt Dempsey                                                                                                                                                                         |
| 909 |    453.106744 |    740.978274 | Steven Traver                                                                                                                                                                        |
| 910 |    855.942112 |    325.019040 | Jessica Anne Miller                                                                                                                                                                  |
| 911 |    836.796407 |    746.418976 | Riccardo Percudani                                                                                                                                                                   |
| 912 |    898.917997 |    251.076768 | Zimices                                                                                                                                                                              |
| 913 |    641.760332 |    154.487615 | Matt Crook                                                                                                                                                                           |
| 914 |    216.357818 |    348.572421 | Steven Traver                                                                                                                                                                        |
| 915 |    607.862613 |    697.160630 | Felix Vaux                                                                                                                                                                           |
| 916 |     14.826621 |    251.399307 | T. Michael Keesey                                                                                                                                                                    |
| 917 |    749.512546 |    134.368501 | Zimices                                                                                                                                                                              |
| 918 |    950.235257 |    338.006104 | Margot Michaud                                                                                                                                                                       |
| 919 |    230.424475 |    429.024548 | Dean Schnabel                                                                                                                                                                        |
| 920 |    130.166741 |    675.756162 | Tracy A. Heath                                                                                                                                                                       |
| 921 |    677.184224 |    683.904846 | Ferran Sayol                                                                                                                                                                         |
| 922 |    209.096736 |    728.593246 | Scott Hartman                                                                                                                                                                        |

    #> Your tweet has been posted!
