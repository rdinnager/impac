
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

T. Michael Keesey, Matt Crook, Margot Michaud, Ignacio Contreras, Jagged
Fang Designs, Tom Tarrant (photo), John E. McCormack, Michael G. Harvey,
Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T.
Brumfield & T. Michael Keesey, Brad McFeeters (vectorized by T. Michael
Keesey), Matt Martyniuk (vectorized by T. Michael Keesey), Zimices,
Gareth Monger, Chris huh, Erika Schumacher, Natasha Vitek,
Fir0002/Flagstaffotos (photo), John E. McCormack, Michael G. Harvey,
Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T.
Brumfield & T. Michael Keesey, Skye M, Liftarn, Scott Hartman, Sean
McCann, Anthony Caravaggi, Roberto Díaz Sibaja, Jaime Headden, Michelle
Site, Robert Bruce Horsfall, vectorized by Zimices, Filip em, Ferran
Sayol, David Liao, Tasman Dixon, Emily Willoughby, T. Michael Keesey
(after A. Y. Ivantsov), Danielle Alba, C. Camilo Julián-Caballero,
Brockhaus and Efron, Nobu Tamura (vectorized by T. Michael Keesey),
Maxime Dahirel, Andy Wilson, Chris Jennings (Risiatto), Martin R. Smith,
Lily Hughes, Walter Vladimir, Markus A. Grohme, Sarah Alewijnse, Joanna
Wolfe, Birgit Lang, Dmitry Bogdanov (vectorized by T. Michael Keesey),
Alexander Schmidt-Lebuhn, NASA, Joschua Knüppe, Mihai Dragos (vectorized
by T. Michael Keesey), Meliponicultor Itaymbere, Jonathan Wells,
FunkMonk, T. Michael Keesey (photo by J. M. Garg), Mali’o Kodis,
photograph property of National Museums of Northern Ireland, Raven Amos,
Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela
Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough
(vectorized by T. Michael Keesey), L. Shyamal, Warren H (photography),
T. Michael Keesey (vectorization), xgirouxb, Bennet McComish, photo by
Avenue, Renato Santos, Richard Lampitt, Jeremy Young / NHM
(vectorization by Yan Wong), Sergio A. Muñoz-Gómez, Gabriela
Palomo-Munoz, Air Kebir NRG, George Edward Lodge (vectorized by T.
Michael Keesey), Steven Coombs, Tracy A. Heath, Kamil S. Jaron,
Ville-Veikko Sinkkonen, John Conway, Robert Gay, modified from FunkMonk
(Michael B.H.) and T. Michael Keesey., Matthew E. Clapham, Steven
Traver, Maija Karala, kotik, Plukenet, Shyamal, Jose Carlos
Arenas-Monroy, Kai R. Caspar, Dean Schnabel, Frank Förster (based on a
picture by Hans Hillewaert), Michael Scroggie, Dori <dori@merr.info>
(source photo) and Nevit Dilmen, Renata F. Martins, Chase Brownstein,
Neil Kelley, Sarah Werning, Diana Pomeroy, Steve Hillebrand/U. S. Fish
and Wildlife Service (source photo), T. Michael Keesey (vectorization),
Terpsichores, M Kolmann, Tambja (vectorized by T. Michael Keesey), Tony
Ayling, Ieuan Jones, Christoph Schomburg, Tauana J. Cunha, Nobu Tamura,
vectorized by Zimices, Darren Naish (vectorize by T. Michael Keesey),
Riccardo Percudani, Caleb M. Brown, DW Bapst (modified from Bulman,
1970), Mo Hassan, Chuanixn Yu, Renato de Carvalho Ferreira, Collin
Gross, Chloé Schmidt, Michael P. Taylor, Tyler Greenfield and Scott
Hartman, Lukasiniho, Cristopher Silva, Maxwell Lefroy (vectorized by T.
Michael Keesey), Xavier Giroux-Bougard, Agnello Picorelli, Michael
Scroggie, from original photograph by Gary M. Stolz, USFWS (original
photograph in public domain)., Charles Doolittle Walcott (vectorized by
T. Michael Keesey), Ian Burt (original) and T. Michael Keesey
(vectorization), Mali’o Kodis, image from Higgins and Kristensen, 1986,
Mette Aumala, Rachel Shoop, Archaeodontosaurus (vectorized by T. Michael
Keesey), FunkMonk (Michael B.H.; vectorized by T. Michael Keesey), Jan
A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow
(vectorized by T. Michael Keesey), Esme Ashe-Jepson, Beth Reinke, T.
Tischler, Dmitry Bogdanov, vectorized by Zimices, Heinrich Harder
(vectorized by William Gearty), Hugo Gruson, Lisa Byrne, Melissa Ingala,
Burton Robert, USFWS, Apokryltaros (vectorized by T. Michael Keesey),
Mason McNair, Yan Wong, Mali’o Kodis, image by Rebecca Ritger, Manabu
Sakamoto, Enoch Joseph Wetsy (photo), John E. McCormack, Michael G.
Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb
T. Brumfield & T. Michael Keesey, Peileppe, Margret Flinsch, vectorized
by Zimices, CNZdenek, Ludwik Gąsiorowski, Matt Celeskey, Scott D.
Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A.
Forster, Joshua A. Smith, Alan L. Titus, JJ Harrison (vectorized by T.
Michael Keesey), Hans Hillewaert, Julie Blommaert based on photo by
Sofdrakou, T. Michael Keesey (after MPF), Matt Martyniuk, Servien
(vectorized by T. Michael Keesey), Mario Quevedo, Harold N Eyster, Danny
Cicchetti (vectorized by T. Michael Keesey), Hans Hillewaert (vectorized
by T. Michael Keesey), Robbie N. Cada (vectorized by T. Michael Keesey),
Kimberly Haddrell, Ghedo and T. Michael Keesey, Conty, Yan Wong from SEM
by Arnau Sebé-Pedrós (PD agreed by Iñaki Ruiz-Trillo), James I.
Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and
Jelle P. Wiersma (vectorized by T. Michael Keesey), Konsta Happonen,
from a CC-BY-NC image by sokolkov2002 on iNaturalist, Sebastian
Stabinger, Noah Schlottman, Iain Reid, Smokeybjb, Caleb Brown, Kent
Elson Sorgon, Dave Souza (vectorized by T. Michael Keesey),
Myriam\_Ramirez, Nobu Tamura and T. Michael Keesey, Ghedoghedo
(vectorized by T. Michael Keesey), Sam Droege (photography) and T.
Michael Keesey (vectorization), Todd Marshall, vectorized by Zimices,
Madeleine Price Ball, Nick Schooler, Kanchi Nanjo, Mattia Menchetti,
Scott Hartman, modified by T. Michael Keesey, George Edward Lodge,
Andrew A. Farke, Amanda Katzer, David Orr, A. R. McCulloch (vectorized
by T. Michael Keesey), Allison Pease, Mathew Wedel, M. Garfield & K.
Anderson (modified by T. Michael Keesey), Jiekun He, T. Michael Keesey
(after James & al.), Michael Day, Milton Tan, Ingo Braasch, Melissa
Broussard, George Edward Lodge (modified by T. Michael Keesey),
Baheerathan Murugavel, Noah Schlottman, photo from Casey Dunn, Michael
“FunkMonk” B. H. (vectorized by T. Michael Keesey), Sarefo (vectorized
by T. Michael Keesey), Sharon Wegner-Larsen, Pete Buchholz, Paul O.
Lewis, Pranav Iyer (grey ideas), Tony Ayling (vectorized by T. Michael
Keesey), Noah Schlottman, photo by Reinhard Jahn, Nobu Tamura (modified
by T. Michael Keesey), Elizabeth Parker, Crystal Maier, Cesar Julian,
Rebecca Groom, Mali’o Kodis, photograph by John Slapcinsky, Juan Carlos
Jerí, Stanton F. Fink (vectorized by T. Michael Keesey), Mariana Ruiz
Villarreal (modified by T. Michael Keesey), J Levin W (illustration) and
T. Michael Keesey (vectorization), Didier Descouens (vectorized by T.
Michael Keesey), Lani Mohan, Obsidian Soul (vectorized by T. Michael
Keesey), Robert Hering, NOAA Great Lakes Environmental Research
Laboratory (illustration) and Timothy J. Bartley (silhouette), Mali’o
Kodis, photograph by Bruno Vellutini, Dmitry Bogdanov, Philippe Janvier
(vectorized by T. Michael Keesey), Ghedoghedo, Abraão B. Leite, Michele
M Tobias, david maas / dave hone, Caio Bernardes, vectorized by Zimices,
Dexter R. Mardis, Michael Ströck (vectorized by T. Michael Keesey),
Alexandre Vong, Nancy Wyman (photo), John E. McCormack, Michael G.
Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb
T. Brumfield & T. Michael Keesey, Pedro de Siracusa, T. Michael Keesey
and Tanetahi, Eyal Bartov, Kailah Thorn & Mark Hutchinson, Ellen
Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley
(silhouette), Smokeybjb (modified by Mike Keesey), T. Michael Keesey
(after Masteraah), Tyler Greenfield and Dean Schnabel, U.S. National
Park Service (vectorized by William Gearty), Marcos Pérez-Losada, Jens
T. Høeg & Keith A. Crandall, Steven Blackwood, Alex Slavenko, Emily Jane
McTavish, from
<http://en.wikipedia.org/wiki/File:Coccolithus_pelagicus.jpg>, Fernando
Carezzano, kreidefossilien.de, Carlos Cano-Barbacil, Michael Wolf
(photo), Hans Hillewaert (editing), T. Michael Keesey (vectorization),
Kelly, Y. de Hoev. (vectorized by T. Michael Keesey), Armin Reindl, I.
Geoffroy Saint-Hilaire (vectorized by T. Michael Keesey), Christopher
Laumer (vectorized by T. Michael Keesey), Birgit Lang, based on a photo
by D. Sikes, John Gould (vectorized by T. Michael Keesey), Ville
Koistinen and T. Michael Keesey, Tim H. Heupink, Leon Huynen, and David
M. Lambert (vectorized by T. Michael Keesey), Cristian Osorio & Paula
Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org),
Noah Schlottman, photo by Martin V. Sørensen, Benjamin Monod-Broca, M
Hutchinson, Chris A. Hamilton, Andreas Preuss / marauder, Adrian Reich,
Josep Marti Solans, Scott Reid, U.S. Fish and Wildlife Service
(illustration) and Timothy J. Bartley (silhouette), Sherman Foote Denton
(illustration, 1897) and Timothy J. Bartley (silhouette), Óscar
San−Isidro (vectorized by T. Michael Keesey), Michael Scroggie, from
original photograph by John Bettaso, USFWS (original photograph in
public domain)., Cagri Cevrim, Eduard Solà Vázquez, vectorised by Yan
Wong, Alyssa Bell & Luis Chiappe 2015,
dx.doi.org/10.1371/journal.pone.0141690, Julia B McHugh, Tess Linden,
Rene Martin, Noah Schlottman, photo from National Science Foundation -
Turbellarian Taxonomic Database

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    335.521612 |    573.241429 | NA                                                                                                                                                                    |
|   2 |    708.357118 |    390.285713 | T. Michael Keesey                                                                                                                                                     |
|   3 |    452.712920 |    383.035590 | Matt Crook                                                                                                                                                            |
|   4 |    298.712475 |    367.004617 | Matt Crook                                                                                                                                                            |
|   5 |    565.665023 |    224.541882 | Margot Michaud                                                                                                                                                        |
|   6 |     83.488497 |    304.411004 | Ignacio Contreras                                                                                                                                                     |
|   7 |    409.263662 |    135.408668 | Margot Michaud                                                                                                                                                        |
|   8 |    474.419687 |    680.904988 | Jagged Fang Designs                                                                                                                                                   |
|   9 |     83.600426 |    144.939424 | Tom Tarrant (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
|  10 |    557.249936 |    556.409866 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
|  11 |    875.081358 |    105.340803 | NA                                                                                                                                                                    |
|  12 |    896.333673 |    484.529823 | Matt Crook                                                                                                                                                            |
|  13 |    750.667608 |    134.620986 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                      |
|  14 |    789.512835 |    638.027413 | Zimices                                                                                                                                                               |
|  15 |    928.816877 |    255.693181 | Gareth Monger                                                                                                                                                         |
|  16 |    284.345768 |     23.496157 | Chris huh                                                                                                                                                             |
|  17 |    818.106492 |    737.200579 | Erika Schumacher                                                                                                                                                      |
|  18 |    171.610199 |    633.723857 | Matt Crook                                                                                                                                                            |
|  19 |    260.018833 |    729.425497 | Natasha Vitek                                                                                                                                                         |
|  20 |    525.234639 |    412.558431 | Fir0002/Flagstaffotos (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
|  21 |    864.371814 |    452.408973 | Matt Crook                                                                                                                                                            |
|  22 |    645.242396 |    708.396528 | Skye M                                                                                                                                                                |
|  23 |    193.838774 |    169.713720 | Liftarn                                                                                                                                                               |
|  24 |    914.059871 |    525.261587 | Scott Hartman                                                                                                                                                         |
|  25 |    579.154742 |    107.217868 | Sean McCann                                                                                                                                                           |
|  26 |     56.699605 |    490.553311 | Liftarn                                                                                                                                                               |
|  27 |    796.259122 |    280.541883 | Anthony Caravaggi                                                                                                                                                     |
|  28 |    959.185775 |    348.537514 | Roberto Díaz Sibaja                                                                                                                                                   |
|  29 |    176.042330 |    460.082897 | Margot Michaud                                                                                                                                                        |
|  30 |    417.462933 |    490.232033 | Anthony Caravaggi                                                                                                                                                     |
|  31 |    417.989500 |    224.635681 | Jaime Headden                                                                                                                                                         |
|  32 |     68.192593 |    361.416764 | Ignacio Contreras                                                                                                                                                     |
|  33 |    274.228358 |     73.248429 | T. Michael Keesey                                                                                                                                                     |
|  34 |    255.178861 |    534.654742 | Michelle Site                                                                                                                                                         |
|  35 |    940.242623 |    608.532602 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                          |
|  36 |    569.338988 |    316.449717 | Filip em                                                                                                                                                              |
|  37 |    956.471153 |     90.535066 | Ferran Sayol                                                                                                                                                          |
|  38 |     97.414258 |     54.380732 | Scott Hartman                                                                                                                                                         |
|  39 |    252.561974 |    238.968131 | David Liao                                                                                                                                                            |
|  40 |    356.352472 |    701.951737 | T. Michael Keesey                                                                                                                                                     |
|  41 |    570.777800 |    602.768640 | Tasman Dixon                                                                                                                                                          |
|  42 |    961.335528 |    703.321706 | Emily Willoughby                                                                                                                                                      |
|  43 |    508.580594 |    762.643600 | Jagged Fang Designs                                                                                                                                                   |
|  44 |    559.270901 |     30.262885 | T. Michael Keesey (after A. Y. Ivantsov)                                                                                                                              |
|  45 |    838.277222 |    336.856902 | Danielle Alba                                                                                                                                                         |
|  46 |    481.141078 |     45.471182 | C. Camilo Julián-Caballero                                                                                                                                            |
|  47 |    348.000400 |     75.334513 | Brockhaus and Efron                                                                                                                                                   |
|  48 |     85.959138 |    554.684023 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  49 |    991.148120 |    456.243734 | Maxime Dahirel                                                                                                                                                        |
|  50 |    480.654558 |    630.555547 | Andy Wilson                                                                                                                                                           |
|  51 |    130.279225 |    740.891951 | Chris Jennings (Risiatto)                                                                                                                                             |
|  52 |    731.674574 |     55.167293 | Jagged Fang Designs                                                                                                                                                   |
|  53 |    927.354046 |    186.026217 | Scott Hartman                                                                                                                                                         |
|  54 |    453.154276 |    297.957717 | Scott Hartman                                                                                                                                                         |
|  55 |    834.401660 |    562.510617 | Gareth Monger                                                                                                                                                         |
|  56 |    687.925571 |     21.543124 | Gareth Monger                                                                                                                                                         |
|  57 |    597.825076 |    393.465815 | Emily Willoughby                                                                                                                                                      |
|  58 |    831.033642 |    228.461086 | Zimices                                                                                                                                                               |
|  59 |    337.061142 |    143.784973 | Martin R. Smith                                                                                                                                                       |
|  60 |    678.479564 |    149.302508 | Lily Hughes                                                                                                                                                           |
|  61 |   1005.392778 |    235.704190 | NA                                                                                                                                                                    |
|  62 |     67.616955 |    603.143664 | Walter Vladimir                                                                                                                                                       |
|  63 |     68.058628 |    219.266116 | Jagged Fang Designs                                                                                                                                                   |
|  64 |    108.217199 |    778.987736 | Markus A. Grohme                                                                                                                                                      |
|  65 |    653.625329 |    637.935337 | Chris huh                                                                                                                                                             |
|  66 |    125.821222 |    257.152550 | Sarah Alewijnse                                                                                                                                                       |
|  67 |    629.344381 |    481.072080 | Joanna Wolfe                                                                                                                                                          |
|  68 |    431.057630 |    778.071487 | Birgit Lang                                                                                                                                                           |
|  69 |    133.183196 |    389.323960 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  70 |    522.643062 |    644.484589 | Alexander Schmidt-Lebuhn                                                                                                                                              |
|  71 |    137.210950 |    562.559054 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  72 |     37.820153 |    697.858460 | NASA                                                                                                                                                                  |
|  73 |    529.418807 |    134.831091 | Joschua Knüppe                                                                                                                                                        |
|  74 |    800.220732 |    445.379448 | Mihai Dragos (vectorized by T. Michael Keesey)                                                                                                                        |
|  75 |   1003.003826 |    718.902534 | Meliponicultor Itaymbere                                                                                                                                              |
|  76 |    413.292583 |    603.825957 | Jonathan Wells                                                                                                                                                        |
|  77 |    588.298890 |    768.567174 | Jagged Fang Designs                                                                                                                                                   |
|  78 |    164.682872 |    374.911158 | Ferran Sayol                                                                                                                                                          |
|  79 |    335.634374 |    234.818105 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  80 |    523.303883 |    204.534153 | FunkMonk                                                                                                                                                              |
|  81 |    984.507551 |    521.811708 | Chris huh                                                                                                                                                             |
|  82 |    589.937837 |    154.506741 | T. Michael Keesey (photo by J. M. Garg)                                                                                                                               |
|  83 |    467.095627 |    123.057204 | Mali’o Kodis, photograph property of National Museums of Northern Ireland                                                                                             |
|  84 |    837.166979 |    773.332367 | Raven Amos                                                                                                                                                            |
|  85 |    947.343534 |    514.367074 | Margot Michaud                                                                                                                                                        |
|  86 |    902.038701 |    673.756226 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
|  87 |    962.575391 |    400.427138 | Markus A. Grohme                                                                                                                                                      |
|  88 |    287.598158 |    559.228925 | Chris huh                                                                                                                                                             |
|  89 |    184.810188 |     18.244343 | Margot Michaud                                                                                                                                                        |
|  90 |    184.130942 |    748.382789 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  91 |     52.980122 |    742.426057 | L. Shyamal                                                                                                                                                            |
|  92 |    937.596708 |    128.568611 | Zimices                                                                                                                                                               |
|  93 |    500.105170 |     53.539733 | T. Michael Keesey                                                                                                                                                     |
|  94 |    383.173349 |    784.144211 | Meliponicultor Itaymbere                                                                                                                                              |
|  95 |     28.212396 |    544.902484 | Warren H (photography), T. Michael Keesey (vectorization)                                                                                                             |
|  96 |    277.380594 |    791.026746 | xgirouxb                                                                                                                                                              |
|  97 |    418.904976 |     52.199174 | Bennet McComish, photo by Avenue                                                                                                                                      |
|  98 |    653.052446 |     38.072489 | Gareth Monger                                                                                                                                                         |
|  99 |    821.104949 |    146.285498 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 100 |    328.849062 |    679.218462 | Renato Santos                                                                                                                                                         |
| 101 |     29.995301 |     90.528358 | Richard Lampitt, Jeremy Young / NHM (vectorization by Yan Wong)                                                                                                       |
| 102 |    390.030605 |     25.674040 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 103 |     96.483611 |     85.003393 | Erika Schumacher                                                                                                                                                      |
| 104 |    434.112608 |    562.490459 | Jagged Fang Designs                                                                                                                                                   |
| 105 |    564.837154 |    734.383170 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 106 |    533.892949 |    512.780173 | Air Kebir NRG                                                                                                                                                         |
| 107 |    306.893922 |    487.828850 | George Edward Lodge (vectorized by T. Michael Keesey)                                                                                                                 |
| 108 |    553.739244 |     11.885580 | Steven Coombs                                                                                                                                                         |
| 109 |     17.531524 |    715.346149 | T. Michael Keesey                                                                                                                                                     |
| 110 |   1014.122194 |     78.418669 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 111 |    616.056293 |    283.358556 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 112 |    262.700644 |    140.750113 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 113 |    764.269872 |    365.331055 | Tracy A. Heath                                                                                                                                                        |
| 114 |    416.608722 |    268.640763 | NA                                                                                                                                                                    |
| 115 |    344.471548 |    617.324495 | Gareth Monger                                                                                                                                                         |
| 116 |    101.642843 |    381.844269 | Martin R. Smith                                                                                                                                                       |
| 117 |   1008.371416 |    631.796145 | Zimices                                                                                                                                                               |
| 118 |    782.160350 |    165.811218 | Scott Hartman                                                                                                                                                         |
| 119 |    880.344929 |     39.484607 | Matt Crook                                                                                                                                                            |
| 120 |    830.219150 |    384.515212 | Kamil S. Jaron                                                                                                                                                        |
| 121 |     93.043198 |     32.577186 | Ville-Veikko Sinkkonen                                                                                                                                                |
| 122 |     93.586496 |      7.313810 | John Conway                                                                                                                                                           |
| 123 |    942.750515 |    153.126573 | Kamil S. Jaron                                                                                                                                                        |
| 124 |    600.244295 |    363.913010 | Andy Wilson                                                                                                                                                           |
| 125 |     39.907818 |    123.156004 | Emily Willoughby                                                                                                                                                      |
| 126 |    615.705088 |    332.363578 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                              |
| 127 |    361.466810 |    607.656907 | Margot Michaud                                                                                                                                                        |
| 128 |    969.584491 |    563.758691 | NA                                                                                                                                                                    |
| 129 |    985.434771 |     38.580873 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 130 |    503.216259 |    544.884235 | Matthew E. Clapham                                                                                                                                                    |
| 131 |    166.118892 |    307.460175 | Matt Crook                                                                                                                                                            |
| 132 |    617.453179 |    650.209428 | Margot Michaud                                                                                                                                                        |
| 133 |    907.376535 |     74.565286 | Ferran Sayol                                                                                                                                                          |
| 134 |   1006.104939 |     72.455924 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 135 |    940.035319 |    747.623764 | FunkMonk                                                                                                                                                              |
| 136 |    241.981775 |    763.054941 | Steven Traver                                                                                                                                                         |
| 137 |    489.866119 |    245.864954 | Maija Karala                                                                                                                                                          |
| 138 |    186.622223 |    726.085069 | kotik                                                                                                                                                                 |
| 139 |    464.028640 |    250.233733 | Jaime Headden                                                                                                                                                         |
| 140 |    765.660599 |    505.998352 | Plukenet                                                                                                                                                              |
| 141 |     32.302498 |     33.622408 | Kamil S. Jaron                                                                                                                                                        |
| 142 |    397.191359 |    158.862620 | Zimices                                                                                                                                                               |
| 143 |    977.335233 |    151.773557 | Jaime Headden                                                                                                                                                         |
| 144 |    822.136448 |      9.148526 | Shyamal                                                                                                                                                               |
| 145 |    593.647862 |    781.247301 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 146 |    873.098285 |    785.694729 | Kai R. Caspar                                                                                                                                                         |
| 147 |    493.450864 |    111.972077 | NA                                                                                                                                                                    |
| 148 |     60.792097 |    713.847888 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 149 |     93.683794 |    421.232916 | Matt Crook                                                                                                                                                            |
| 150 |     91.610262 |    445.884618 | NA                                                                                                                                                                    |
| 151 |   1009.666451 |     95.222468 | Dean Schnabel                                                                                                                                                         |
| 152 |    788.681633 |    501.359720 | Frank Förster (based on a picture by Hans Hillewaert)                                                                                                                 |
| 153 |    381.191514 |     60.483408 | Michael Scroggie                                                                                                                                                      |
| 154 |    749.871241 |    349.701747 | Dori <dori@merr.info> (source photo) and Nevit Dilmen                                                                                                                 |
| 155 |    402.432951 |    747.636561 | NA                                                                                                                                                                    |
| 156 |    812.676287 |     67.733841 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 157 |    608.100533 |    402.595848 | Margot Michaud                                                                                                                                                        |
| 158 |    175.829528 |    348.552964 | Ferran Sayol                                                                                                                                                          |
| 159 |    895.309767 |    709.345462 | Renata F. Martins                                                                                                                                                     |
| 160 |    377.350624 |    102.459119 | Matt Crook                                                                                                                                                            |
| 161 |    535.741699 |    531.383308 | Chase Brownstein                                                                                                                                                      |
| 162 |    338.838519 |    253.034972 | Neil Kelley                                                                                                                                                           |
| 163 |    921.963566 |    772.586303 | Ferran Sayol                                                                                                                                                          |
| 164 |    162.712828 |    537.814542 | Sarah Werning                                                                                                                                                         |
| 165 |    319.674180 |    132.741452 | Ville-Veikko Sinkkonen                                                                                                                                                |
| 166 |    412.154778 |    628.040419 | Diana Pomeroy                                                                                                                                                         |
| 167 |    758.401885 |    203.124730 | Matt Crook                                                                                                                                                            |
| 168 |    432.874658 |    762.133853 | Steve Hillebrand/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                                    |
| 169 |    332.865370 |    282.189407 | Scott Hartman                                                                                                                                                         |
| 170 |    334.957821 |    634.962689 | Jagged Fang Designs                                                                                                                                                   |
| 171 |    325.065747 |    171.638409 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 172 |    857.024565 |    292.455931 | NA                                                                                                                                                                    |
| 173 |    229.012080 |    146.195351 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 174 |    948.871467 |    113.482512 | Michael Scroggie                                                                                                                                                      |
| 175 |    102.020883 |    339.048190 | Terpsichores                                                                                                                                                          |
| 176 |    317.314234 |    664.670147 | M Kolmann                                                                                                                                                             |
| 177 |   1002.885071 |    310.631099 | Tambja (vectorized by T. Michael Keesey)                                                                                                                              |
| 178 |    720.088116 |    714.498162 | Tony Ayling                                                                                                                                                           |
| 179 |    772.281095 |     66.658793 | Ieuan Jones                                                                                                                                                           |
| 180 |    488.083392 |    193.753299 | Ignacio Contreras                                                                                                                                                     |
| 181 |    809.104934 |    179.472391 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 182 |    259.149152 |    459.673959 | Scott Hartman                                                                                                                                                         |
| 183 |    591.025736 |    435.388381 | Christoph Schomburg                                                                                                                                                   |
| 184 |    897.607369 |    740.148511 | T. Michael Keesey                                                                                                                                                     |
| 185 |    553.029275 |      1.859644 | Scott Hartman                                                                                                                                                         |
| 186 |    301.848107 |    627.120402 | Jagged Fang Designs                                                                                                                                                   |
| 187 |    658.430770 |    784.519968 | Steven Traver                                                                                                                                                         |
| 188 |    611.712062 |    226.592842 | L. Shyamal                                                                                                                                                            |
| 189 |    471.591477 |    587.954788 | Tauana J. Cunha                                                                                                                                                       |
| 190 |     26.834717 |    205.466689 | T. Michael Keesey                                                                                                                                                     |
| 191 |    767.108186 |    792.784343 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 192 |    746.140170 |    164.298907 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                         |
| 193 |     26.402128 |    275.980708 | Riccardo Percudani                                                                                                                                                    |
| 194 |    910.738135 |    110.362212 | NA                                                                                                                                                                    |
| 195 |    509.149720 |    290.385497 | Birgit Lang                                                                                                                                                           |
| 196 |    771.178705 |    435.320818 | Caleb M. Brown                                                                                                                                                        |
| 197 |    440.248405 |    584.340047 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 198 |    698.512726 |    658.577773 | DW Bapst (modified from Bulman, 1970)                                                                                                                                 |
| 199 |    574.539488 |    666.366143 | Mo Hassan                                                                                                                                                             |
| 200 |    117.252459 |    470.602774 | Margot Michaud                                                                                                                                                        |
| 201 |    204.373048 |    104.097589 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 202 |    145.909971 |    734.202158 | Scott Hartman                                                                                                                                                         |
| 203 |    721.670041 |    574.017957 | Scott Hartman                                                                                                                                                         |
| 204 |    130.955011 |    448.658470 | Maxime Dahirel                                                                                                                                                        |
| 205 |    497.152318 |     93.482048 | Andy Wilson                                                                                                                                                           |
| 206 |    300.850864 |    193.683338 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 207 |    990.204614 |    678.598590 | Tauana J. Cunha                                                                                                                                                       |
| 208 |    426.109506 |    332.160099 | Scott Hartman                                                                                                                                                         |
| 209 |    464.988142 |    170.441609 | Chuanixn Yu                                                                                                                                                           |
| 210 |     12.918223 |     56.178022 | Renato de Carvalho Ferreira                                                                                                                                           |
| 211 |    455.493179 |    590.682455 | Gareth Monger                                                                                                                                                         |
| 212 |    774.521300 |     98.588769 | Collin Gross                                                                                                                                                          |
| 213 |     14.676870 |    285.996142 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 214 |    183.557808 |    238.514161 | Chris huh                                                                                                                                                             |
| 215 |    756.556054 |    468.991472 | Margot Michaud                                                                                                                                                        |
| 216 |     26.834139 |    434.354294 | Ferran Sayol                                                                                                                                                          |
| 217 |    638.150492 |      6.264115 | Ignacio Contreras                                                                                                                                                     |
| 218 |    574.618092 |    485.129610 | Zimices                                                                                                                                                               |
| 219 |    821.983993 |    534.126745 | Margot Michaud                                                                                                                                                        |
| 220 |    765.656009 |    314.941174 | Scott Hartman                                                                                                                                                         |
| 221 |    251.179800 |    680.480594 | Jagged Fang Designs                                                                                                                                                   |
| 222 |    818.737989 |    417.848465 | Scott Hartman                                                                                                                                                         |
| 223 |    518.256041 |     53.691744 | Chuanixn Yu                                                                                                                                                           |
| 224 |    323.059965 |    741.814857 | Chloé Schmidt                                                                                                                                                         |
| 225 |    928.921602 |    646.586483 | L. Shyamal                                                                                                                                                            |
| 226 |    351.645248 |    305.147539 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 227 |    891.928124 |      6.803465 | Michael P. Taylor                                                                                                                                                     |
| 228 |     24.423568 |    642.405875 | Margot Michaud                                                                                                                                                        |
| 229 |    241.654219 |    687.605467 | Zimices                                                                                                                                                               |
| 230 |   1005.836602 |     54.882035 | Tyler Greenfield and Scott Hartman                                                                                                                                    |
| 231 |    750.882889 |    289.896207 | Kamil S. Jaron                                                                                                                                                        |
| 232 |    452.307473 |    320.864995 | Gareth Monger                                                                                                                                                         |
| 233 |    167.773768 |     43.579833 | Sarah Werning                                                                                                                                                         |
| 234 |    127.743328 |    192.753809 | Kamil S. Jaron                                                                                                                                                        |
| 235 |    822.042506 |    407.287588 | Chase Brownstein                                                                                                                                                      |
| 236 |    660.873307 |    524.741916 | Maija Karala                                                                                                                                                          |
| 237 |    522.587613 |    791.888197 | Frank Förster (based on a picture by Hans Hillewaert)                                                                                                                 |
| 238 |    278.774596 |    644.016041 | Michael Scroggie                                                                                                                                                      |
| 239 |    721.115537 |    472.129885 | Birgit Lang                                                                                                                                                           |
| 240 |     89.843238 |    588.822011 | Lukasiniho                                                                                                                                                            |
| 241 |    996.260567 |    667.452331 | Zimices                                                                                                                                                               |
| 242 |    931.019053 |    760.305624 | Margot Michaud                                                                                                                                                        |
| 243 |    722.731598 |    665.567726 | Cristopher Silva                                                                                                                                                      |
| 244 |     21.432424 |    312.790335 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                      |
| 245 |    924.539101 |     69.866382 | Zimices                                                                                                                                                               |
| 246 |    993.670247 |    397.763052 | Roberto Díaz Sibaja                                                                                                                                                   |
| 247 |    648.064983 |    242.224403 | Tracy A. Heath                                                                                                                                                        |
| 248 |    641.562485 |    341.979272 | Margot Michaud                                                                                                                                                        |
| 249 |     92.128543 |     17.224806 | Margot Michaud                                                                                                                                                        |
| 250 |    820.560075 |     37.713068 | Michelle Site                                                                                                                                                         |
| 251 |    559.891648 |    788.892397 | NA                                                                                                                                                                    |
| 252 |    376.347531 |    280.761209 | Xavier Giroux-Bougard                                                                                                                                                 |
| 253 |     98.690970 |    311.619531 | Agnello Picorelli                                                                                                                                                     |
| 254 |      8.929624 |    323.615364 | Matt Crook                                                                                                                                                            |
| 255 |    106.611430 |    213.948280 | Michael Scroggie, from original photograph by Gary M. Stolz, USFWS (original photograph in public domain).                                                            |
| 256 |    791.461649 |    542.175271 | Kamil S. Jaron                                                                                                                                                        |
| 257 |    176.411463 |    791.440434 | Margot Michaud                                                                                                                                                        |
| 258 |    161.483710 |    203.169838 | Charles Doolittle Walcott (vectorized by T. Michael Keesey)                                                                                                           |
| 259 |    629.466408 |     47.205599 | Andy Wilson                                                                                                                                                           |
| 260 |    209.582373 |    750.997383 | Gareth Monger                                                                                                                                                         |
| 261 |    258.189405 |    443.213654 | Zimices                                                                                                                                                               |
| 262 |    627.642920 |    774.801793 | Ian Burt (original) and T. Michael Keesey (vectorization)                                                                                                             |
| 263 |    378.138335 |     20.583113 | Erika Schumacher                                                                                                                                                      |
| 264 |    567.106445 |    413.550089 | Chris huh                                                                                                                                                             |
| 265 |    806.381612 |    107.364567 | Margot Michaud                                                                                                                                                        |
| 266 |    644.642041 |    201.235112 | Mali’o Kodis, image from Higgins and Kristensen, 1986                                                                                                                 |
| 267 |    260.781177 |    500.833518 | Sean McCann                                                                                                                                                           |
| 268 |    212.027490 |     36.309788 | Zimices                                                                                                                                                               |
| 269 |    648.942880 |     73.044951 | Caleb M. Brown                                                                                                                                                        |
| 270 |    872.720142 |     65.668228 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 271 |     79.412656 |    517.512294 | Mette Aumala                                                                                                                                                          |
| 272 |    105.727921 |    180.222062 | Anthony Caravaggi                                                                                                                                                     |
| 273 |    938.290289 |     19.436123 | Rachel Shoop                                                                                                                                                          |
| 274 |    605.245328 |    130.108932 | Archaeodontosaurus (vectorized by T. Michael Keesey)                                                                                                                  |
| 275 |    206.416506 |    779.966684 | Jagged Fang Designs                                                                                                                                                   |
| 276 |    613.526430 |    500.898994 | Zimices                                                                                                                                                               |
| 277 |    409.406291 |    646.736892 | Matt Crook                                                                                                                                                            |
| 278 |    645.940549 |    597.471589 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 279 |     69.186308 |    211.164038 | L. Shyamal                                                                                                                                                            |
| 280 |    388.757942 |    632.494470 | FunkMonk (Michael B.H.; vectorized by T. Michael Keesey)                                                                                                              |
| 281 |    563.135207 |    176.610083 | Ferran Sayol                                                                                                                                                          |
| 282 |    627.386023 |    617.542518 | Emily Willoughby                                                                                                                                                      |
| 283 |    897.420824 |    261.761196 | Scott Hartman                                                                                                                                                         |
| 284 |    414.486502 |    365.164964 | Andy Wilson                                                                                                                                                           |
| 285 |    348.763158 |    169.451176 | Scott Hartman                                                                                                                                                         |
| 286 |    153.558637 |    248.891740 | Christoph Schomburg                                                                                                                                                   |
| 287 |    241.463057 |    776.788465 | Zimices                                                                                                                                                               |
| 288 |    687.944933 |    629.801177 | NA                                                                                                                                                                    |
| 289 |    971.021157 |    792.917462 | Gareth Monger                                                                                                                                                         |
| 290 |    232.670216 |    182.777475 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 291 |    659.053077 |    612.988822 | NA                                                                                                                                                                    |
| 292 |     77.916061 |    703.004187 | Esme Ashe-Jepson                                                                                                                                                      |
| 293 |    844.404533 |    710.850556 | Jagged Fang Designs                                                                                                                                                   |
| 294 |    124.202242 |    399.067971 | Scott Hartman                                                                                                                                                         |
| 295 |    894.673659 |    782.967912 | Matt Crook                                                                                                                                                            |
| 296 |    959.630240 |    192.758208 | Margot Michaud                                                                                                                                                        |
| 297 |    415.611798 |     21.865572 | Beth Reinke                                                                                                                                                           |
| 298 |    530.139841 |    354.143642 | T. Tischler                                                                                                                                                           |
| 299 |    562.570920 |    353.025046 | Lily Hughes                                                                                                                                                           |
| 300 |    917.409249 |    697.082761 | Matt Crook                                                                                                                                                            |
| 301 |    886.753974 |     61.114734 | Dmitry Bogdanov, vectorized by Zimices                                                                                                                                |
| 302 |    904.379728 |     20.119479 | Ignacio Contreras                                                                                                                                                     |
| 303 |    627.551368 |    193.760863 | Heinrich Harder (vectorized by William Gearty)                                                                                                                        |
| 304 |    966.639297 |    256.529321 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 305 |    675.858969 |    106.163806 | NA                                                                                                                                                                    |
| 306 |    247.791543 |    115.601038 | Michelle Site                                                                                                                                                         |
| 307 |    240.115294 |    505.295599 | Hugo Gruson                                                                                                                                                           |
| 308 |   1002.300318 |    574.024114 | NA                                                                                                                                                                    |
| 309 |    962.948601 |    302.753672 | Ferran Sayol                                                                                                                                                          |
| 310 |    828.840825 |    190.517886 | Lisa Byrne                                                                                                                                                            |
| 311 |    808.243231 |     27.660496 | Melissa Ingala                                                                                                                                                        |
| 312 |    137.292344 |     22.735244 | NA                                                                                                                                                                    |
| 313 |      9.357906 |    168.539387 | Sarah Werning                                                                                                                                                         |
| 314 |    749.159317 |      9.357174 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                         |
| 315 |    203.960412 |     14.906237 | Matt Crook                                                                                                                                                            |
| 316 |   1010.393157 |    526.017008 | Margot Michaud                                                                                                                                                        |
| 317 |    440.380495 |    247.632541 | Burton Robert, USFWS                                                                                                                                                  |
| 318 |   1015.121324 |    592.385513 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                        |
| 319 |    936.502686 |    791.466388 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 320 |    532.865089 |    723.057846 | Mason McNair                                                                                                                                                          |
| 321 |    264.230616 |    160.508750 | Cristopher Silva                                                                                                                                                      |
| 322 |    809.788681 |    541.954796 | NA                                                                                                                                                                    |
| 323 |    911.015158 |    277.699881 | Matt Crook                                                                                                                                                            |
| 324 |    459.216985 |    577.434676 | Yan Wong                                                                                                                                                              |
| 325 |    939.050798 |    566.772186 | Steven Traver                                                                                                                                                         |
| 326 |    725.219127 |    703.243301 | Mali’o Kodis, image by Rebecca Ritger                                                                                                                                 |
| 327 |    245.661361 |    787.627417 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 328 |    223.183928 |    794.411709 | Manabu Sakamoto                                                                                                                                                       |
| 329 |    648.216067 |    376.852728 | Chris huh                                                                                                                                                             |
| 330 |    988.940312 |    544.712795 | Enoch Joseph Wetsy (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey    |
| 331 |    427.194626 |    647.431796 | Peileppe                                                                                                                                                              |
| 332 |    578.603309 |    642.883699 | Tasman Dixon                                                                                                                                                          |
| 333 |    214.271962 |    357.507822 | Emily Willoughby                                                                                                                                                      |
| 334 |    897.581314 |    388.632215 | Margret Flinsch, vectorized by Zimices                                                                                                                                |
| 335 |     16.787242 |    394.750234 | Chuanixn Yu                                                                                                                                                           |
| 336 |     80.961491 |    473.605896 | Andy Wilson                                                                                                                                                           |
| 337 |    301.104814 |    141.889344 | Maija Karala                                                                                                                                                          |
| 338 |    663.080278 |    653.588326 | T. Michael Keesey                                                                                                                                                     |
| 339 |    539.111992 |    175.829866 | CNZdenek                                                                                                                                                              |
| 340 |    729.453922 |    772.578772 | Ludwik Gąsiorowski                                                                                                                                                    |
| 341 |    441.460792 |    728.913574 | Steven Traver                                                                                                                                                         |
| 342 |   1012.215227 |    649.481492 | Matt Celeskey                                                                                                                                                         |
| 343 |    447.779947 |    740.765273 | Gareth Monger                                                                                                                                                         |
| 344 |    282.056020 |    181.531714 | Chloé Schmidt                                                                                                                                                         |
| 345 |    475.722830 |    621.640150 | Margot Michaud                                                                                                                                                        |
| 346 |    788.451769 |    422.199196 | Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus                                              |
| 347 |    885.991988 |    352.653765 | Tauana J. Cunha                                                                                                                                                       |
| 348 |    641.841008 |    264.393407 | JJ Harrison (vectorized by T. Michael Keesey)                                                                                                                         |
| 349 |    564.626979 |    558.968514 | Hans Hillewaert                                                                                                                                                       |
| 350 |    826.634274 |    182.380745 | Julie Blommaert based on photo by Sofdrakou                                                                                                                           |
| 351 |    917.883905 |    784.161454 | Jagged Fang Designs                                                                                                                                                   |
| 352 |    381.338641 |    593.959255 | NA                                                                                                                                                                    |
| 353 |    926.841193 |    728.330404 | Gareth Monger                                                                                                                                                         |
| 354 |    760.869893 |    401.882829 | Ferran Sayol                                                                                                                                                          |
| 355 |    341.251270 |    179.596082 | L. Shyamal                                                                                                                                                            |
| 356 |    518.346664 |    176.092719 | Jagged Fang Designs                                                                                                                                                   |
| 357 |    412.971488 |    726.617516 | T. Michael Keesey (after MPF)                                                                                                                                         |
| 358 |   1001.793223 |      8.512029 | Matt Martyniuk                                                                                                                                                        |
| 359 |    803.514737 |    696.468319 | NA                                                                                                                                                                    |
| 360 |    557.065548 |    286.872621 | C. Camilo Julián-Caballero                                                                                                                                            |
| 361 |     82.897046 |    323.468769 | Zimices                                                                                                                                                               |
| 362 |    161.067904 |    743.488649 | Servien (vectorized by T. Michael Keesey)                                                                                                                             |
| 363 |    316.433254 |    725.009531 | Kamil S. Jaron                                                                                                                                                        |
| 364 |    969.832781 |    410.752160 | Matt Crook                                                                                                                                                            |
| 365 |   1012.476191 |     13.839847 | Mario Quevedo                                                                                                                                                         |
| 366 |    449.689801 |    423.262170 | Esme Ashe-Jepson                                                                                                                                                      |
| 367 |    895.506798 |    163.317691 | Harold N Eyster                                                                                                                                                       |
| 368 |    765.085566 |     13.995161 | Ferran Sayol                                                                                                                                                          |
| 369 |    756.754193 |    220.686769 | Margot Michaud                                                                                                                                                        |
| 370 |    582.742315 |      7.050284 | Matt Crook                                                                                                                                                            |
| 371 |    452.283992 |    438.235506 | Mo Hassan                                                                                                                                                             |
| 372 |    377.047304 |     70.989465 | Margot Michaud                                                                                                                                                        |
| 373 |    593.280521 |    560.416653 | Danny Cicchetti (vectorized by T. Michael Keesey)                                                                                                                     |
| 374 |    708.551954 |    625.393134 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 375 |     32.195474 |    758.219867 | Anthony Caravaggi                                                                                                                                                     |
| 376 |    748.849316 |    443.526414 | Margot Michaud                                                                                                                                                        |
| 377 |    856.068395 |    409.979259 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
| 378 |    397.651657 |    707.851080 | Ferran Sayol                                                                                                                                                          |
| 379 |    425.744032 |    627.560623 | Kimberly Haddrell                                                                                                                                                     |
| 380 |    963.393499 |    230.421096 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 381 |    559.068132 |    576.100406 | Matt Crook                                                                                                                                                            |
| 382 |     81.100714 |    209.273307 | Jonathan Wells                                                                                                                                                        |
| 383 |    384.010899 |    270.034456 | Scott Hartman                                                                                                                                                         |
| 384 |    302.466260 |    675.206781 | Ghedo and T. Michael Keesey                                                                                                                                           |
| 385 |    612.898121 |    762.406406 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                        |
| 386 |    982.588157 |    788.337827 | Margot Michaud                                                                                                                                                        |
| 387 |    894.056222 |    251.970220 | Markus A. Grohme                                                                                                                                                      |
| 388 |    922.443821 |    519.148209 | Scott Hartman                                                                                                                                                         |
| 389 |    460.189106 |    271.275980 | Scott Hartman                                                                                                                                                         |
| 390 |    305.729121 |    635.228656 | Conty                                                                                                                                                                 |
| 391 |    500.470200 |    603.890465 | Yan Wong from SEM by Arnau Sebé-Pedrós (PD agreed by Iñaki Ruiz-Trillo)                                                                                               |
| 392 |    404.139872 |    587.273491 | Gareth Monger                                                                                                                                                         |
| 393 |     83.724793 |    125.850345 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                  |
| 394 |    875.469731 |    587.985602 | Collin Gross                                                                                                                                                          |
| 395 |    698.309174 |    757.032889 | C. Camilo Julián-Caballero                                                                                                                                            |
| 396 |    568.974355 |    712.641624 | Yan Wong                                                                                                                                                              |
| 397 |    499.790488 |    792.802956 | Yan Wong                                                                                                                                                              |
| 398 |    163.148261 |     88.776348 | Konsta Happonen, from a CC-BY-NC image by sokolkov2002 on iNaturalist                                                                                                 |
| 399 |    420.753609 |    552.026925 | T. Michael Keesey                                                                                                                                                     |
| 400 |    900.623853 |    699.717159 | NA                                                                                                                                                                    |
| 401 |    741.811207 |    781.540086 | Sebastian Stabinger                                                                                                                                                   |
| 402 |    608.598393 |    350.692979 | Margot Michaud                                                                                                                                                        |
| 403 |     60.489672 |    128.755903 | Noah Schlottman                                                                                                                                                       |
| 404 |    953.465073 |    762.256615 | Matt Crook                                                                                                                                                            |
| 405 |    208.704083 |     57.540090 | Maija Karala                                                                                                                                                          |
| 406 |    873.547368 |    277.374444 | Gareth Monger                                                                                                                                                         |
| 407 |    317.624350 |    221.103852 | Iain Reid                                                                                                                                                             |
| 408 |    749.963117 |     91.710749 | Markus A. Grohme                                                                                                                                                      |
| 409 |    567.949227 |    775.019416 | Zimices                                                                                                                                                               |
| 410 |   1002.526227 |    758.600270 | Smokeybjb                                                                                                                                                             |
| 411 |    998.649745 |     61.777213 | Caleb Brown                                                                                                                                                           |
| 412 |    632.545912 |    217.296657 | Matt Crook                                                                                                                                                            |
| 413 |    896.666097 |    541.947063 | NA                                                                                                                                                                    |
| 414 |    179.677914 |    187.200266 | Michelle Site                                                                                                                                                         |
| 415 |    403.413635 |    758.726026 | Margot Michaud                                                                                                                                                        |
| 416 |    592.017689 |    793.261225 | Zimices                                                                                                                                                               |
| 417 |     12.280512 |    613.875319 | Kent Elson Sorgon                                                                                                                                                     |
| 418 |    977.988324 |    205.767738 | Dave Souza (vectorized by T. Michael Keesey)                                                                                                                          |
| 419 |    636.541656 |     84.506930 | Myriam\_Ramirez                                                                                                                                                       |
| 420 |    794.223718 |    176.100916 | Zimices                                                                                                                                                               |
| 421 |    670.271244 |    551.106431 | Nobu Tamura and T. Michael Keesey                                                                                                                                     |
| 422 |    342.866060 |    766.930617 | Scott Hartman                                                                                                                                                         |
| 423 |    757.070342 |    331.256900 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 424 |    204.946042 |    309.262599 | NA                                                                                                                                                                    |
| 425 |    983.465046 |    773.745971 | Sam Droege (photography) and T. Michael Keesey (vectorization)                                                                                                        |
| 426 |    659.886968 |    395.253204 | Todd Marshall, vectorized by Zimices                                                                                                                                  |
| 427 |    174.886212 |    733.665945 | Dean Schnabel                                                                                                                                                         |
| 428 |    778.544624 |    482.919736 | Matt Crook                                                                                                                                                            |
| 429 |    332.083847 |    198.861862 | Madeleine Price Ball                                                                                                                                                  |
| 430 |    138.601882 |    515.805147 | Michael Scroggie                                                                                                                                                      |
| 431 |     15.477382 |    138.430402 | Nick Schooler                                                                                                                                                         |
| 432 |    985.865764 |    715.641307 | Kanchi Nanjo                                                                                                                                                          |
| 433 |    996.301225 |    184.770921 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 434 |    730.403344 |    190.626352 | Ludwik Gąsiorowski                                                                                                                                                    |
| 435 |    809.184233 |    187.734620 | Kamil S. Jaron                                                                                                                                                        |
| 436 |    787.080295 |    530.943140 | Scott Hartman                                                                                                                                                         |
| 437 |    599.814323 |    665.631152 | Kamil S. Jaron                                                                                                                                                        |
| 438 |    529.852502 |    672.420727 | Gareth Monger                                                                                                                                                         |
| 439 |    470.616477 |    411.970026 | Steven Traver                                                                                                                                                         |
| 440 |    448.227087 |    642.379562 | Margot Michaud                                                                                                                                                        |
| 441 |    749.400712 |    242.682566 | Mattia Menchetti                                                                                                                                                      |
| 442 |      8.242708 |    187.809240 | Chris huh                                                                                                                                                             |
| 443 |    933.121266 |    481.566077 | Scott Hartman, modified by T. Michael Keesey                                                                                                                          |
| 444 |     37.082170 |    662.454771 | Chloé Schmidt                                                                                                                                                         |
| 445 |    644.804131 |    568.135057 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 446 |    551.248685 |    297.149478 | Andy Wilson                                                                                                                                                           |
| 447 |    985.884646 |    283.613962 | L. Shyamal                                                                                                                                                            |
| 448 |    522.517446 |     68.828408 | M Kolmann                                                                                                                                                             |
| 449 |    144.552667 |    134.422647 | Margot Michaud                                                                                                                                                        |
| 450 |    559.120774 |    797.698877 | Dean Schnabel                                                                                                                                                         |
| 451 |     33.546389 |    244.128712 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 452 |     59.838682 |    695.904743 | George Edward Lodge                                                                                                                                                   |
| 453 |    980.681437 |    531.294815 | Margot Michaud                                                                                                                                                        |
| 454 |    462.974119 |    450.123202 | Andrew A. Farke                                                                                                                                                       |
| 455 |    655.335324 |    531.840871 | NA                                                                                                                                                                    |
| 456 |    553.961097 |     90.200694 | Markus A. Grohme                                                                                                                                                      |
| 457 |    395.206823 |    110.310552 | Margot Michaud                                                                                                                                                        |
| 458 |    892.722363 |     52.871637 | Joanna Wolfe                                                                                                                                                          |
| 459 |    973.066151 |    616.834726 | NA                                                                                                                                                                    |
| 460 |    798.664940 |    786.734106 | Markus A. Grohme                                                                                                                                                      |
| 461 |    912.929416 |     13.913283 | Xavier Giroux-Bougard                                                                                                                                                 |
| 462 |    859.979690 |    786.892842 | Smokeybjb                                                                                                                                                             |
| 463 |     16.796521 |    196.920837 | NA                                                                                                                                                                    |
| 464 |    231.476490 |    447.357278 | Kimberly Haddrell                                                                                                                                                     |
| 465 |    702.801213 |    774.114620 | Amanda Katzer                                                                                                                                                         |
| 466 |    187.147896 |    204.657307 | Ferran Sayol                                                                                                                                                          |
| 467 |    887.581426 |    298.417205 | Scott Hartman                                                                                                                                                         |
| 468 |    186.938926 |     70.731983 | Margot Michaud                                                                                                                                                        |
| 469 |    940.557046 |    171.722022 | Ignacio Contreras                                                                                                                                                     |
| 470 |    426.002966 |    346.066715 | Kamil S. Jaron                                                                                                                                                        |
| 471 |    881.537462 |    577.933488 | Zimices                                                                                                                                                               |
| 472 |    998.867853 |    797.718416 | Chris huh                                                                                                                                                             |
| 473 |    909.244337 |    302.116116 | NA                                                                                                                                                                    |
| 474 |    481.032311 |    543.108107 | Gareth Monger                                                                                                                                                         |
| 475 |    964.855027 |    438.129263 | David Orr                                                                                                                                                             |
| 476 |    998.597436 |    551.674267 | A. R. McCulloch (vectorized by T. Michael Keesey)                                                                                                                     |
| 477 |    760.030156 |    765.546167 | Allison Pease                                                                                                                                                         |
| 478 |    593.063814 |    505.609076 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 479 |    926.967887 |    495.209038 | NA                                                                                                                                                                    |
| 480 |    776.218302 |    575.784004 | Zimices                                                                                                                                                               |
| 481 |    479.934990 |    789.522903 | Andrew A. Farke                                                                                                                                                       |
| 482 |    245.234514 |    288.113883 | Mathew Wedel                                                                                                                                                          |
| 483 |    332.499820 |      7.033444 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 484 |    850.277756 |     23.902335 | M. Garfield & K. Anderson (modified by T. Michael Keesey)                                                                                                             |
| 485 |    377.508062 |    539.544178 | Jiekun He                                                                                                                                                             |
| 486 |    757.368772 |     32.274628 | T. Michael Keesey (after James & al.)                                                                                                                                 |
| 487 |    398.760648 |     90.393210 | Ville-Veikko Sinkkonen                                                                                                                                                |
| 488 |    969.406285 |    386.205674 | Agnello Picorelli                                                                                                                                                     |
| 489 |     46.096415 |    280.123193 | Zimices                                                                                                                                                               |
| 490 |    645.102634 |    511.457480 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 491 |    599.962100 |    114.690497 | T. Michael Keesey                                                                                                                                                     |
| 492 |     62.684398 |    730.112321 | Zimices                                                                                                                                                               |
| 493 |    390.848202 |    446.522750 | Roberto Díaz Sibaja                                                                                                                                                   |
| 494 |    843.006923 |    427.201248 | Jagged Fang Designs                                                                                                                                                   |
| 495 |     42.355219 |     10.201168 | Michael Day                                                                                                                                                           |
| 496 |    790.698473 |    342.955082 | Dean Schnabel                                                                                                                                                         |
| 497 |    632.974609 |     31.742369 | Kai R. Caspar                                                                                                                                                         |
| 498 |    167.710901 |     14.247758 | Milton Tan                                                                                                                                                            |
| 499 |     59.376597 |    680.404522 | Matt Crook                                                                                                                                                            |
| 500 |    602.262841 |    726.637597 | T. Michael Keesey                                                                                                                                                     |
| 501 |    203.882139 |    225.036353 | Dean Schnabel                                                                                                                                                         |
| 502 |    847.396907 |    286.577265 | Gareth Monger                                                                                                                                                         |
| 503 |    445.421393 |    613.294835 | Emily Willoughby                                                                                                                                                      |
| 504 |    638.471785 |    783.146913 | T. Michael Keesey                                                                                                                                                     |
| 505 |    917.281171 |    643.280020 | Ingo Braasch                                                                                                                                                          |
| 506 |    707.308162 |    719.211352 | Ignacio Contreras                                                                                                                                                     |
| 507 |    501.283924 |    258.119906 | Dean Schnabel                                                                                                                                                         |
| 508 |    432.297458 |    365.752159 | T. Michael Keesey                                                                                                                                                     |
| 509 |    280.396140 |    609.577463 | Brockhaus and Efron                                                                                                                                                   |
| 510 |    854.602161 |    538.844372 | Roberto Díaz Sibaja                                                                                                                                                   |
| 511 |     26.856320 |    520.497264 | Matt Celeskey                                                                                                                                                         |
| 512 |    135.588878 |    361.696228 | Gareth Monger                                                                                                                                                         |
| 513 |    450.127266 |    526.003731 | Melissa Broussard                                                                                                                                                     |
| 514 |    388.662425 |    734.434312 | George Edward Lodge (modified by T. Michael Keesey)                                                                                                                   |
| 515 |    910.863161 |    243.198409 | Andy Wilson                                                                                                                                                           |
| 516 |   1001.670447 |    514.716392 | Gareth Monger                                                                                                                                                         |
| 517 |    985.210821 |    725.486579 | NA                                                                                                                                                                    |
| 518 |    215.564528 |    192.166612 | NA                                                                                                                                                                    |
| 519 |    139.068606 |    404.433225 | NA                                                                                                                                                                    |
| 520 |    839.449714 |    295.824398 | Baheerathan Murugavel                                                                                                                                                 |
| 521 |     42.026091 |    521.134976 | Noah Schlottman, photo from Casey Dunn                                                                                                                                |
| 522 |    251.666143 |    515.320890 | NA                                                                                                                                                                    |
| 523 |   1020.262033 |    505.607989 | T. Michael Keesey                                                                                                                                                     |
| 524 |    934.920427 |    420.104009 | Matt Crook                                                                                                                                                            |
| 525 |    524.612798 |     15.952924 | Christoph Schomburg                                                                                                                                                   |
| 526 |    780.560108 |    148.200887 | Matt Crook                                                                                                                                                            |
| 527 |    563.348100 |    188.395307 | Steven Traver                                                                                                                                                         |
| 528 |    118.122881 |    375.153847 | Zimices                                                                                                                                                               |
| 529 |    366.759864 |    223.702076 | Michael “FunkMonk” B. H. (vectorized by T. Michael Keesey)                                                                                                            |
| 530 |    767.360597 |    700.426772 | Andy Wilson                                                                                                                                                           |
| 531 |    461.133634 |    765.280287 | Sarefo (vectorized by T. Michael Keesey)                                                                                                                              |
| 532 |    609.491943 |    773.296357 | Sharon Wegner-Larsen                                                                                                                                                  |
| 533 |    113.822513 |    307.436130 | Pete Buchholz                                                                                                                                                         |
| 534 |    982.615111 |    254.997577 | Maija Karala                                                                                                                                                          |
| 535 |    576.373548 |    183.833480 | Steven Traver                                                                                                                                                         |
| 536 |    505.132001 |    733.308907 | NA                                                                                                                                                                    |
| 537 |    909.934268 |    266.420793 | Iain Reid                                                                                                                                                             |
| 538 |    882.587871 |     16.119630 | Margot Michaud                                                                                                                                                        |
| 539 |    657.558422 |    261.328187 | Margot Michaud                                                                                                                                                        |
| 540 |    240.862653 |    130.884891 | NA                                                                                                                                                                    |
| 541 |    487.873335 |    171.141982 | Matt Crook                                                                                                                                                            |
| 542 |    608.734297 |     67.587585 | Zimices                                                                                                                                                               |
| 543 |      8.963809 |     98.201408 | Anthony Caravaggi                                                                                                                                                     |
| 544 |     65.364991 |      8.540541 | Noah Schlottman, photo from Casey Dunn                                                                                                                                |
| 545 |    645.652668 |    368.072236 | Margot Michaud                                                                                                                                                        |
| 546 |    580.081082 |    172.193900 | Paul O. Lewis                                                                                                                                                         |
| 547 |    312.988476 |    780.838620 | Pranav Iyer (grey ideas)                                                                                                                                              |
| 548 |    513.732969 |    196.508705 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 549 |    183.493041 |    528.707508 | Kanchi Nanjo                                                                                                                                                          |
| 550 |    904.669406 |    197.464294 | Kamil S. Jaron                                                                                                                                                        |
| 551 |    739.405679 |    459.339667 | Gareth Monger                                                                                                                                                         |
| 552 |    842.813497 |    412.254604 | Matt Crook                                                                                                                                                            |
| 553 |    841.545659 |    177.701962 | Noah Schlottman, photo by Reinhard Jahn                                                                                                                               |
| 554 |    637.438264 |    244.167412 | Steven Traver                                                                                                                                                         |
| 555 |    625.013160 |    401.596946 | Andy Wilson                                                                                                                                                           |
| 556 |    357.787411 |    175.258891 | Steven Coombs                                                                                                                                                         |
| 557 |    588.468317 |    720.724266 | Roberto Díaz Sibaja                                                                                                                                                   |
| 558 |    280.888565 |    275.831730 | Gareth Monger                                                                                                                                                         |
| 559 |    125.812532 |    244.653919 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                           |
| 560 |    552.869940 |    346.315863 | Gareth Monger                                                                                                                                                         |
| 561 |    740.412577 |     29.590457 | Gareth Monger                                                                                                                                                         |
| 562 |    897.832216 |    318.835980 | NA                                                                                                                                                                    |
| 563 |     45.952163 |    260.947032 | Gareth Monger                                                                                                                                                         |
| 564 |    149.657410 |    391.359253 | Gareth Monger                                                                                                                                                         |
| 565 |    934.739634 |    394.199096 | xgirouxb                                                                                                                                                              |
| 566 |    546.187684 |    363.574024 | Elizabeth Parker                                                                                                                                                      |
| 567 |    959.219462 |    172.719508 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 568 |    174.236013 |    218.889804 | Crystal Maier                                                                                                                                                         |
| 569 |    593.926203 |     60.172736 | Cesar Julian                                                                                                                                                          |
| 570 |    306.204047 |    644.964603 | Gareth Monger                                                                                                                                                         |
| 571 |    463.998260 |    553.260836 | Ignacio Contreras                                                                                                                                                     |
| 572 |    638.627955 |     70.426018 | Rebecca Groom                                                                                                                                                         |
| 573 |    684.412942 |    774.240351 | Steven Traver                                                                                                                                                         |
| 574 |    977.775823 |     18.679506 | NA                                                                                                                                                                    |
| 575 |    544.184074 |    635.571799 | Sarah Werning                                                                                                                                                         |
| 576 |    936.803760 |    105.569431 | Zimices                                                                                                                                                               |
| 577 |    802.560117 |     87.589270 | Zimices                                                                                                                                                               |
| 578 |    830.349683 |    273.988809 | Zimices                                                                                                                                                               |
| 579 |     65.332653 |    281.174368 | Margot Michaud                                                                                                                                                        |
| 580 |    654.845911 |     46.728104 | Scott Hartman                                                                                                                                                         |
| 581 |    428.946058 |     25.999422 | NASA                                                                                                                                                                  |
| 582 |    350.372304 |    495.510614 | Zimices                                                                                                                                                               |
| 583 |     71.048549 |    239.069181 | Margot Michaud                                                                                                                                                        |
| 584 |    447.080456 |    337.486064 | T. Michael Keesey                                                                                                                                                     |
| 585 |    989.522434 |    650.495614 | Mali’o Kodis, photograph by John Slapcinsky                                                                                                                           |
| 586 |    203.691951 |    769.393653 | NA                                                                                                                                                                    |
| 587 |    374.626653 |     82.653028 | Juan Carlos Jerí                                                                                                                                                      |
| 588 |      7.305356 |    579.720152 | Matt Crook                                                                                                                                                            |
| 589 |    405.690331 |    101.364806 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 590 |    640.541696 |    499.831170 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                     |
| 591 |    677.204543 |     76.349282 | Mariana Ruiz Villarreal (modified by T. Michael Keesey)                                                                                                               |
| 592 |    356.041467 |    614.535955 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 593 |    178.233595 |    415.845736 | Ignacio Contreras                                                                                                                                                     |
| 594 |    835.291556 |    312.086087 | NA                                                                                                                                                                    |
| 595 |    119.397749 |    348.514770 | Shyamal                                                                                                                                                               |
| 596 |    773.458651 |     87.292388 | Gareth Monger                                                                                                                                                         |
| 597 |    543.047359 |    713.160057 | Scott Hartman                                                                                                                                                         |
| 598 |    161.960634 |    217.733327 | J Levin W (illustration) and T. Michael Keesey (vectorization)                                                                                                        |
| 599 |    423.596534 |    794.716514 | T. Michael Keesey                                                                                                                                                     |
| 600 |    453.115290 |    106.895170 | Beth Reinke                                                                                                                                                           |
| 601 |    858.820702 |    172.874261 | Chris huh                                                                                                                                                             |
| 602 |    728.634481 |    549.109188 | Jaime Headden                                                                                                                                                         |
| 603 |    195.820293 |    338.725085 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 604 |    840.874853 |    576.320651 | John Conway                                                                                                                                                           |
| 605 |     91.558337 |    212.401816 | Lani Mohan                                                                                                                                                            |
| 606 |    798.855694 |    426.767444 | Gareth Monger                                                                                                                                                         |
| 607 |    590.734281 |    303.674445 | Roberto Díaz Sibaja                                                                                                                                                   |
| 608 |    969.136577 |      7.917379 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 609 |    593.382250 |    290.907605 | Beth Reinke                                                                                                                                                           |
| 610 |    529.586764 |    159.270506 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 611 |    399.407020 |    117.799389 | T. Michael Keesey                                                                                                                                                     |
| 612 |     87.663431 |    400.008176 | Margot Michaud                                                                                                                                                        |
| 613 |    132.031055 |     71.379729 | Robert Hering                                                                                                                                                         |
| 614 |    505.239736 |    267.754753 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
| 615 |    920.137419 |    623.638399 | Matt Crook                                                                                                                                                            |
| 616 |    593.477422 |    485.298734 | Todd Marshall, vectorized by Zimices                                                                                                                                  |
| 617 |    393.063846 |    534.377984 | Ferran Sayol                                                                                                                                                          |
| 618 |     61.438833 |     23.086473 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 619 |   1009.553503 |    435.357837 | Gareth Monger                                                                                                                                                         |
| 620 |   1015.217243 |    310.720672 | Meliponicultor Itaymbere                                                                                                                                              |
| 621 |    288.930982 |    115.299678 | Margot Michaud                                                                                                                                                        |
| 622 |     36.075549 |    674.287542 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 623 |    147.265638 |    793.830224 | Xavier Giroux-Bougard                                                                                                                                                 |
| 624 |     46.302617 |    626.733864 | Maija Karala                                                                                                                                                          |
| 625 |    224.495147 |    515.510828 | Tasman Dixon                                                                                                                                                          |
| 626 |    460.233405 |    655.687388 | Mali’o Kodis, photograph by Bruno Vellutini                                                                                                                           |
| 627 |    562.357555 |    700.410080 | Ieuan Jones                                                                                                                                                           |
| 628 |    393.603797 |    615.664656 | C. Camilo Julián-Caballero                                                                                                                                            |
| 629 |    153.403203 |    273.334165 | Steven Traver                                                                                                                                                         |
| 630 |    352.161814 |    268.027973 | Dmitry Bogdanov                                                                                                                                                       |
| 631 |     26.331334 |    407.255587 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                           |
| 632 |    588.040819 |    533.403627 | M Kolmann                                                                                                                                                             |
| 633 |    843.387915 |    400.387932 | Markus A. Grohme                                                                                                                                                      |
| 634 |    310.368648 |    199.854614 | Harold N Eyster                                                                                                                                                       |
| 635 |   1019.747169 |    281.124446 | Crystal Maier                                                                                                                                                         |
| 636 |    745.513188 |    696.385507 | Matt Crook                                                                                                                                                            |
| 637 |    570.081401 |    361.044255 | Michael Scroggie                                                                                                                                                      |
| 638 |     55.343417 |    643.564276 | Andy Wilson                                                                                                                                                           |
| 639 |    656.089076 |    756.984961 | Michelle Site                                                                                                                                                         |
| 640 |    621.719233 |    598.713930 | Margot Michaud                                                                                                                                                        |
| 641 |    239.531463 |    772.454078 | Scott Hartman                                                                                                                                                         |
| 642 |    249.376720 |     96.800270 | CNZdenek                                                                                                                                                              |
| 643 |    608.326966 |    436.186946 | Gareth Monger                                                                                                                                                         |
| 644 |    965.724976 |     17.898177 | Philippe Janvier (vectorized by T. Michael Keesey)                                                                                                                    |
| 645 |    586.998731 |    262.504391 | Juan Carlos Jerí                                                                                                                                                      |
| 646 |    198.881922 |    398.021132 | Jagged Fang Designs                                                                                                                                                   |
| 647 |    585.167352 |    656.769105 | Sarah Werning                                                                                                                                                         |
| 648 |    458.472619 |    569.128575 | Emily Willoughby                                                                                                                                                      |
| 649 |    477.442565 |    465.024175 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 650 |    404.858791 |    400.735812 | Gareth Monger                                                                                                                                                         |
| 651 |    724.936291 |     96.498797 | Ghedoghedo                                                                                                                                                            |
| 652 |    908.717463 |     93.680774 | Enoch Joseph Wetsy (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey    |
| 653 |    321.023168 |    213.697893 | Christoph Schomburg                                                                                                                                                   |
| 654 |   1014.337942 |    398.451012 | Andy Wilson                                                                                                                                                           |
| 655 |    222.773507 |    506.516719 | Zimices                                                                                                                                                               |
| 656 |    367.872506 |    558.689543 | Margot Michaud                                                                                                                                                        |
| 657 |    847.766374 |    585.788657 | Matt Crook                                                                                                                                                            |
| 658 |    449.269255 |    764.595429 | Rachel Shoop                                                                                                                                                          |
| 659 |    378.704217 |    173.984194 | C. Camilo Julián-Caballero                                                                                                                                            |
| 660 |    266.415930 |    479.843402 | Abraão B. Leite                                                                                                                                                       |
| 661 |    811.555967 |    169.488750 | xgirouxb                                                                                                                                                              |
| 662 |    678.821130 |     45.468034 | Jonathan Wells                                                                                                                                                        |
| 663 |     16.550951 |     14.696416 | Matt Crook                                                                                                                                                            |
| 664 |    405.049746 |    326.379476 | Michael Scroggie                                                                                                                                                      |
| 665 |    417.075785 |    345.578239 | Michele M Tobias                                                                                                                                                      |
| 666 |     97.129520 |    197.732486 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 667 |    777.904818 |    156.757955 | Birgit Lang                                                                                                                                                           |
| 668 |    130.505580 |    155.910139 | Cesar Julian                                                                                                                                                          |
| 669 |    721.068062 |    726.791225 | Scott Hartman                                                                                                                                                         |
| 670 |    585.017397 |    244.894052 | Gareth Monger                                                                                                                                                         |
| 671 |    120.779594 |    279.100742 | Sarah Werning                                                                                                                                                         |
| 672 |   1008.127027 |    171.982143 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 673 |     60.356958 |    631.412717 | Crystal Maier                                                                                                                                                         |
| 674 |   1013.256107 |    787.602881 | NA                                                                                                                                                                    |
| 675 |    412.042721 |    776.144752 | NA                                                                                                                                                                    |
| 676 |    806.157394 |    793.742081 | Todd Marshall, vectorized by Zimices                                                                                                                                  |
| 677 |    585.536540 |    752.464969 | Jagged Fang Designs                                                                                                                                                   |
| 678 |    288.543422 |    159.406090 | Jagged Fang Designs                                                                                                                                                   |
| 679 |    582.244232 |    457.331385 | Sarah Werning                                                                                                                                                         |
| 680 |    859.404338 |     71.174392 | Renata F. Martins                                                                                                                                                     |
| 681 |    469.535594 |    438.303800 | Jiekun He                                                                                                                                                             |
| 682 |    159.959928 |    114.705855 | Ferran Sayol                                                                                                                                                          |
| 683 |    751.039086 |    720.263073 | david maas / dave hone                                                                                                                                                |
| 684 |    286.055814 |    450.359571 | Zimices                                                                                                                                                               |
| 685 |    398.545830 |     65.985443 | Andy Wilson                                                                                                                                                           |
| 686 |    546.128953 |    189.786855 | Ferran Sayol                                                                                                                                                          |
| 687 |      9.990234 |    107.152381 | Matt Martyniuk                                                                                                                                                        |
| 688 |    521.139850 |     60.578255 | Scott Hartman                                                                                                                                                         |
| 689 |    529.032569 |    283.499326 | Xavier Giroux-Bougard                                                                                                                                                 |
| 690 |    363.981231 |    164.468687 | Andy Wilson                                                                                                                                                           |
| 691 |    426.707886 |    573.641798 | Caio Bernardes, vectorized by Zimices                                                                                                                                 |
| 692 |    332.155663 |    532.439010 | Dexter R. Mardis                                                                                                                                                      |
| 693 |    741.807311 |    149.477667 | Christoph Schomburg                                                                                                                                                   |
| 694 |    567.680729 |    259.965913 | Jaime Headden                                                                                                                                                         |
| 695 |    947.971757 |    472.812051 | Tauana J. Cunha                                                                                                                                                       |
| 696 |    597.759232 |    459.632035 | T. Michael Keesey                                                                                                                                                     |
| 697 |    841.514011 |    145.604066 | Zimices                                                                                                                                                               |
| 698 |    654.397951 |    436.087804 | Matt Crook                                                                                                                                                            |
| 699 |    491.726168 |    147.524327 | Steven Traver                                                                                                                                                         |
| 700 |    844.420179 |    722.580743 | Kamil S. Jaron                                                                                                                                                        |
| 701 |    307.255986 |     44.200633 | T. Michael Keesey                                                                                                                                                     |
| 702 |    339.489032 |    525.517973 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 703 |    810.228267 |     52.450740 | Christoph Schomburg                                                                                                                                                   |
| 704 |     97.918785 |    479.871881 | Dexter R. Mardis                                                                                                                                                      |
| 705 |    959.396592 |    427.580725 | Jaime Headden                                                                                                                                                         |
| 706 |    817.106903 |    367.206870 | Michael Ströck (vectorized by T. Michael Keesey)                                                                                                                      |
| 707 |    344.277327 |     40.856329 | Alexandre Vong                                                                                                                                                        |
| 708 |    915.940795 |     98.461778 | Kamil S. Jaron                                                                                                                                                        |
| 709 |    362.242035 |    774.545984 | Matt Crook                                                                                                                                                            |
| 710 |    512.771346 |    785.799758 | Nancy Wyman (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
| 711 |    557.344226 |    514.532607 | Pedro de Siracusa                                                                                                                                                     |
| 712 |    645.458912 |    416.607960 | Renato de Carvalho Ferreira                                                                                                                                           |
| 713 |    469.856018 |    742.275228 | Margot Michaud                                                                                                                                                        |
| 714 |     77.103338 |    402.097783 | Scott Hartman                                                                                                                                                         |
| 715 |   1002.420098 |    696.081528 | T. Michael Keesey and Tanetahi                                                                                                                                        |
| 716 |    753.541466 |    258.559583 | Eyal Bartov                                                                                                                                                           |
| 717 |    370.981736 |    616.019758 | T. Michael Keesey                                                                                                                                                     |
| 718 |    643.447102 |    354.656673 | Kailah Thorn & Mark Hutchinson                                                                                                                                        |
| 719 |    798.022538 |     39.152795 | Zimices                                                                                                                                                               |
| 720 |    997.729665 |    659.349694 | Scott Hartman                                                                                                                                                         |
| 721 |    981.540463 |    209.913006 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                                     |
| 722 |    487.405392 |    575.196657 | Matt Crook                                                                                                                                                            |
| 723 |    362.182090 |    790.171672 | C. Camilo Julián-Caballero                                                                                                                                            |
| 724 |    117.666865 |    440.503297 | Kanchi Nanjo                                                                                                                                                          |
| 725 |    492.768860 |    227.893606 | Smokeybjb (modified by Mike Keesey)                                                                                                                                   |
| 726 |    989.252820 |    684.905809 | Iain Reid                                                                                                                                                             |
| 727 |      9.932352 |    683.388860 | T. Michael Keesey                                                                                                                                                     |
| 728 |    550.769652 |     55.140829 | Smokeybjb                                                                                                                                                             |
| 729 |    719.347028 |    530.154515 | Rebecca Groom                                                                                                                                                         |
| 730 |    841.116304 |    793.069525 | Zimices                                                                                                                                                               |
| 731 |    857.599977 |     46.567937 | Anthony Caravaggi                                                                                                                                                     |
| 732 |    373.524683 |    632.081912 | Zimices                                                                                                                                                               |
| 733 |    828.786751 |    125.693832 | Gareth Monger                                                                                                                                                         |
| 734 |    613.413359 |    750.146654 | T. Michael Keesey (after Masteraah)                                                                                                                                   |
| 735 |    959.041464 |    133.831726 | Tyler Greenfield and Dean Schnabel                                                                                                                                    |
| 736 |    405.178477 |    336.899827 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 737 |    222.662600 |    460.376853 | Steven Traver                                                                                                                                                         |
| 738 |    231.400221 |    163.292045 | U.S. National Park Service (vectorized by William Gearty)                                                                                                             |
| 739 |     95.391906 |    500.308759 | David Orr                                                                                                                                                             |
| 740 |    903.007299 |    653.596358 | Marcos Pérez-Losada, Jens T. Høeg & Keith A. Crandall                                                                                                                 |
| 741 |      4.016918 |    695.154386 | Agnello Picorelli                                                                                                                                                     |
| 742 |     26.185406 |    264.379033 | Zimices                                                                                                                                                               |
| 743 |    926.678286 |    508.583459 | FunkMonk                                                                                                                                                              |
| 744 |      8.537440 |    790.681044 | Sarah Werning                                                                                                                                                         |
| 745 |    328.360203 |    701.084117 | Gareth Monger                                                                                                                                                         |
| 746 |    288.443326 |    325.052267 | Jagged Fang Designs                                                                                                                                                   |
| 747 |     44.885388 |    721.636622 | NA                                                                                                                                                                    |
| 748 |    129.210387 |    215.377817 | Walter Vladimir                                                                                                                                                       |
| 749 |    916.276184 |    213.600142 | Steven Traver                                                                                                                                                         |
| 750 |    766.138005 |    296.697932 | Ferran Sayol                                                                                                                                                          |
| 751 |    866.762910 |    270.403581 | Steven Blackwood                                                                                                                                                      |
| 752 |    313.483382 |    615.507036 | Dean Schnabel                                                                                                                                                         |
| 753 |    754.935501 |    707.162634 | Alex Slavenko                                                                                                                                                         |
| 754 |    445.967560 |    600.427424 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 755 |    659.939887 |    554.015677 | Matt Crook                                                                                                                                                            |
| 756 |    706.393525 |    677.799812 | Ferran Sayol                                                                                                                                                          |
| 757 |    986.868348 |    390.923790 | Chris huh                                                                                                                                                             |
| 758 |    296.410350 |    660.890940 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 759 |    761.068217 |    324.305575 | Ferran Sayol                                                                                                                                                          |
| 760 |    151.164774 |    543.535173 | Juan Carlos Jerí                                                                                                                                                      |
| 761 |    398.677015 |    777.758614 | Emily Jane McTavish, from <http://en.wikipedia.org/wiki/File:Coccolithus_pelagicus.jpg>                                                                               |
| 762 |    105.183188 |    575.505969 | Fernando Carezzano                                                                                                                                                    |
| 763 |    342.733696 |    788.061862 | Noah Schlottman                                                                                                                                                       |
| 764 |    266.341565 |    126.894622 | Noah Schlottman, photo from Casey Dunn                                                                                                                                |
| 765 |    995.417900 |    614.794072 | Gareth Monger                                                                                                                                                         |
| 766 |    414.643680 |    382.308776 | NA                                                                                                                                                                    |
| 767 |    438.542366 |    735.520148 | Smokeybjb                                                                                                                                                             |
| 768 |    583.279098 |    282.010515 | Harold N Eyster                                                                                                                                                       |
| 769 |    196.186616 |    676.363488 | Markus A. Grohme                                                                                                                                                      |
| 770 |    547.841778 |    153.767927 | Tracy A. Heath                                                                                                                                                        |
| 771 |    352.616420 |    510.870189 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 772 |    291.364886 |    681.839562 | Dean Schnabel                                                                                                                                                         |
| 773 |    304.487157 |    260.378801 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                                     |
| 774 |    475.110395 |    234.504165 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 775 |    577.191212 |    292.990490 | Andy Wilson                                                                                                                                                           |
| 776 |    271.778756 |    673.087383 | Tasman Dixon                                                                                                                                                          |
| 777 |    890.490460 |    659.492396 | T. Michael Keesey                                                                                                                                                     |
| 778 |    108.805803 |    414.171124 | Sharon Wegner-Larsen                                                                                                                                                  |
| 779 |    696.245027 |     76.383407 | kreidefossilien.de                                                                                                                                                    |
| 780 |    259.553173 |    507.848410 | Joanna Wolfe                                                                                                                                                          |
| 781 |    947.282349 |    524.614626 | Gareth Monger                                                                                                                                                         |
| 782 |    524.359467 |    725.978285 | C. Camilo Julián-Caballero                                                                                                                                            |
| 783 |    529.878537 |    652.734768 | Steven Traver                                                                                                                                                         |
| 784 |    792.313238 |     87.060726 | Andrew A. Farke                                                                                                                                                       |
| 785 |    233.287642 |    191.475775 | C. Camilo Julián-Caballero                                                                                                                                            |
| 786 |     76.689968 |    272.384676 | Carlos Cano-Barbacil                                                                                                                                                  |
| 787 |    206.449179 |    297.893894 | Gareth Monger                                                                                                                                                         |
| 788 |     46.691942 |     25.839029 | Kamil S. Jaron                                                                                                                                                        |
| 789 |    810.782583 |    383.486840 | Caleb Brown                                                                                                                                                           |
| 790 |    752.045580 |     81.633576 | Michael Wolf (photo), Hans Hillewaert (editing), T. Michael Keesey (vectorization)                                                                                    |
| 791 |    944.896558 |    486.830247 | NA                                                                                                                                                                    |
| 792 |    526.568533 |    337.640407 | Steven Traver                                                                                                                                                         |
| 793 |    957.628940 |    621.625420 | Kelly                                                                                                                                                                 |
| 794 |    608.873517 |    303.104429 | FunkMonk                                                                                                                                                              |
| 795 |    513.453360 |    639.162983 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
| 796 |    640.251061 |    400.915503 | Jagged Fang Designs                                                                                                                                                   |
| 797 |    329.843147 |    719.872965 | NA                                                                                                                                                                    |
| 798 |    991.037498 |    299.407132 | Sarah Werning                                                                                                                                                         |
| 799 |    196.583991 |    512.872451 | Martin R. Smith                                                                                                                                                       |
| 800 |    473.442652 |    385.951414 | Steven Traver                                                                                                                                                         |
| 801 |    225.841366 |    779.266729 | Margot Michaud                                                                                                                                                        |
| 802 |    897.133252 |    553.316277 | Matt Crook                                                                                                                                                            |
| 803 |     79.750741 |    114.010698 | Y. de Hoev. (vectorized by T. Michael Keesey)                                                                                                                         |
| 804 |    133.184637 |    223.267132 | Armin Reindl                                                                                                                                                          |
| 805 |    798.626765 |    680.800340 | I. Geoffroy Saint-Hilaire (vectorized by T. Michael Keesey)                                                                                                           |
| 806 |     10.209661 |    440.115555 | Gareth Monger                                                                                                                                                         |
| 807 |    526.384243 |     76.815458 | Zimices                                                                                                                                                               |
| 808 |    423.691916 |      6.728294 | Esme Ashe-Jepson                                                                                                                                                      |
| 809 |    636.581491 |    312.141228 | Ieuan Jones                                                                                                                                                           |
| 810 |    295.982327 |    133.479449 | Chris huh                                                                                                                                                             |
| 811 |    398.758000 |     76.810891 | Steve Hillebrand/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                                    |
| 812 |    394.486936 |    311.309915 | Gareth Monger                                                                                                                                                         |
| 813 |     26.462485 |    609.196751 | Christopher Laumer (vectorized by T. Michael Keesey)                                                                                                                  |
| 814 |    742.281366 |    430.818478 | Margot Michaud                                                                                                                                                        |
| 815 |    644.897172 |    275.625339 | Pedro de Siracusa                                                                                                                                                     |
| 816 |    502.870345 |    330.790582 | Birgit Lang, based on a photo by D. Sikes                                                                                                                             |
| 817 |    621.157297 |    254.132721 | Emily Willoughby                                                                                                                                                      |
| 818 |     62.712355 |    765.995330 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 819 |     14.180607 |    558.229873 | Zimices                                                                                                                                                               |
| 820 |    540.842578 |    778.806380 | Zimices                                                                                                                                                               |
| 821 |     82.128234 |    582.206762 | Matt Crook                                                                                                                                                            |
| 822 |    310.692361 |    685.060454 | John Gould (vectorized by T. Michael Keesey)                                                                                                                          |
| 823 |     80.863663 |    100.990191 | Ville Koistinen and T. Michael Keesey                                                                                                                                 |
| 824 |    322.476339 |    246.646480 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 825 |    303.787343 |    101.690577 | Andy Wilson                                                                                                                                                           |
| 826 |    785.574821 |    408.181453 | Tim H. Heupink, Leon Huynen, and David M. Lambert (vectorized by T. Michael Keesey)                                                                                   |
| 827 |    326.685224 |    772.482222 | NA                                                                                                                                                                    |
| 828 |   1001.551380 |    783.456297 | Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org)                                                                          |
| 829 |     75.913202 |    612.388017 | Scott Hartman                                                                                                                                                         |
| 830 |    279.066560 |    296.527320 | Noah Schlottman, photo by Martin V. Sørensen                                                                                                                          |
| 831 |     37.789329 |    777.633432 | Gareth Monger                                                                                                                                                         |
| 832 |    630.116064 |    305.692881 | NA                                                                                                                                                                    |
| 833 |    913.846708 |    662.774383 | Matt Crook                                                                                                                                                            |
| 834 |    805.706713 |    657.728254 | Chris huh                                                                                                                                                             |
| 835 |    912.146096 |    791.701737 | Mali’o Kodis, photograph by John Slapcinsky                                                                                                                           |
| 836 |    552.618229 |    168.565217 | Ferran Sayol                                                                                                                                                          |
| 837 |    187.961485 |    373.842446 | Zimices                                                                                                                                                               |
| 838 |    319.446831 |    121.932172 | Ingo Braasch                                                                                                                                                          |
| 839 |    870.706520 |    149.736500 | Benjamin Monod-Broca                                                                                                                                                  |
| 840 |    546.286099 |     19.378734 | T. Michael Keesey                                                                                                                                                     |
| 841 |    241.829892 |    487.807678 | Zimices                                                                                                                                                               |
| 842 |    588.732017 |    353.284004 | M Hutchinson                                                                                                                                                          |
| 843 |    470.748341 |    327.716447 | Margot Michaud                                                                                                                                                        |
| 844 |    146.445656 |     69.068233 | Gareth Monger                                                                                                                                                         |
| 845 |    269.107904 |    168.807242 | Jagged Fang Designs                                                                                                                                                   |
| 846 |    874.298019 |    699.785868 | Chris A. Hamilton                                                                                                                                                     |
| 847 |    781.191320 |    327.582645 | NA                                                                                                                                                                    |
| 848 |     36.171066 |    423.627383 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 849 |    796.381812 |    402.260887 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 850 |    369.349152 |    446.598593 | Ferran Sayol                                                                                                                                                          |
| 851 |    807.673696 |    510.006004 | Steven Traver                                                                                                                                                         |
| 852 |    138.402073 |    276.555803 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 853 |    131.666843 |      8.348640 | Margot Michaud                                                                                                                                                        |
| 854 |     27.535209 |    170.126912 | Sean McCann                                                                                                                                                           |
| 855 |    297.588109 |    616.131701 | Sean McCann                                                                                                                                                           |
| 856 |    600.905011 |    140.912910 | Michelle Site                                                                                                                                                         |
| 857 |    514.169481 |    658.003716 | Andreas Preuss / marauder                                                                                                                                             |
| 858 |    883.659677 |    376.485442 | Adrian Reich                                                                                                                                                          |
| 859 |    156.198929 |     28.187514 | Gareth Monger                                                                                                                                                         |
| 860 |    589.641501 |    334.805303 | Josep Marti Solans                                                                                                                                                    |
| 861 |    191.292842 |    781.359593 | Michelle Site                                                                                                                                                         |
| 862 |   1006.153587 |    143.249827 | Ferran Sayol                                                                                                                                                          |
| 863 |    123.641945 |    501.289244 | Margot Michaud                                                                                                                                                        |
| 864 |    772.092783 |    421.276994 | Steven Traver                                                                                                                                                         |
| 865 |    394.180270 |      4.355638 | Chris huh                                                                                                                                                             |
| 866 |     47.223486 |    212.435540 | Mattia Menchetti                                                                                                                                                      |
| 867 |    995.101352 |    734.281420 | Ferran Sayol                                                                                                                                                          |
| 868 |    809.159564 |      8.046022 | Zimices                                                                                                                                                               |
| 869 |    493.883355 |      4.040487 | Scott Reid                                                                                                                                                            |
| 870 |    563.829594 |    340.591870 | Scott Hartman                                                                                                                                                         |
| 871 |    789.955555 |    588.965307 | Sarah Werning                                                                                                                                                         |
| 872 |    726.757468 |    786.048428 | Jagged Fang Designs                                                                                                                                                   |
| 873 |    158.877803 |    235.535475 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 874 |    357.177831 |    753.919092 | Zimices                                                                                                                                                               |
| 875 |     13.716284 |    628.381009 | U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                                     |
| 876 |    601.903875 |    538.887253 | Sherman Foote Denton (illustration, 1897) and Timothy J. Bartley (silhouette)                                                                                         |
| 877 |    692.089281 |    764.904770 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                          |
| 878 |     77.661732 |    419.257591 | Matt Crook                                                                                                                                                            |
| 879 |    192.588794 |    249.173416 | Óscar San−Isidro (vectorized by T. Michael Keesey)                                                                                                                    |
| 880 |    185.786715 |     55.547887 | Richard Lampitt, Jeremy Young / NHM (vectorization by Yan Wong)                                                                                                       |
| 881 |    919.325842 |     25.936121 | Manabu Sakamoto                                                                                                                                                       |
| 882 |   1017.018481 |    607.626702 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 883 |    517.193155 |    101.109564 | Birgit Lang                                                                                                                                                           |
| 884 |    556.517658 |     96.396114 | Neil Kelley                                                                                                                                                           |
| 885 |    543.561009 |    788.693121 | Pedro de Siracusa                                                                                                                                                     |
| 886 |    724.753542 |    757.166935 | Michael Scroggie, from original photograph by John Bettaso, USFWS (original photograph in public domain).                                                             |
| 887 |    204.904620 |    204.243828 | Beth Reinke                                                                                                                                                           |
| 888 |    992.832926 |    425.356779 | Cagri Cevrim                                                                                                                                                          |
| 889 |    790.852564 |    100.836620 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 890 |    215.674784 |      5.322856 | Zimices                                                                                                                                                               |
| 891 |    902.632165 |    221.851040 | Ferran Sayol                                                                                                                                                          |
| 892 |    401.915894 |    385.297840 | Matt Crook                                                                                                                                                            |
| 893 |    575.491851 |    674.241533 | Jagged Fang Designs                                                                                                                                                   |
| 894 |    787.056797 |    774.526596 | Eduard Solà Vázquez, vectorised by Yan Wong                                                                                                                           |
| 895 |    873.928921 |    773.282288 | NA                                                                                                                                                                    |
| 896 |    312.705565 |    463.090818 | NA                                                                                                                                                                    |
| 897 |    314.123748 |    710.004140 | NA                                                                                                                                                                    |
| 898 |    246.528622 |    646.104711 | Jagged Fang Designs                                                                                                                                                   |
| 899 |    220.519939 |    106.958777 | Margot Michaud                                                                                                                                                        |
| 900 |    932.573392 |    112.819325 | Sarah Werning                                                                                                                                                         |
| 901 |    312.704543 |    447.999249 | Christoph Schomburg                                                                                                                                                   |
| 902 |    272.777410 |    663.378931 | Joanna Wolfe                                                                                                                                                          |
| 903 |    467.826497 |    216.142959 | Matt Crook                                                                                                                                                            |
| 904 |    783.347343 |    701.006797 | Alyssa Bell & Luis Chiappe 2015, dx.doi.org/10.1371/journal.pone.0141690                                                                                              |
| 905 |    877.203396 |    389.725968 | Rebecca Groom                                                                                                                                                         |
| 906 |     47.414133 |    246.095774 | Andy Wilson                                                                                                                                                           |
| 907 |     10.683621 |    333.755779 | NA                                                                                                                                                                    |
| 908 |    587.545450 |    449.458736 | Steven Traver                                                                                                                                                         |
| 909 |    375.315834 |     46.730421 | NA                                                                                                                                                                    |
| 910 |    181.838968 |    341.176404 | Julia B McHugh                                                                                                                                                        |
| 911 |    694.313524 |    785.890515 | Jaime Headden                                                                                                                                                         |
| 912 |    227.666427 |    766.765633 | Kanchi Nanjo                                                                                                                                                          |
| 913 |    276.186826 |    469.894907 | Tess Linden                                                                                                                                                           |
| 914 |    500.304972 |    559.735362 | Scott Hartman                                                                                                                                                         |
| 915 |    562.025929 |    244.450623 | Margot Michaud                                                                                                                                                        |
| 916 |    335.322926 |    511.360597 | Chloé Schmidt                                                                                                                                                         |
| 917 |    512.643408 |    481.013846 | Melissa Broussard                                                                                                                                                     |
| 918 |    639.919419 |    755.188300 | Smokeybjb                                                                                                                                                             |
| 919 |    675.009628 |    612.921061 | Collin Gross                                                                                                                                                          |
| 920 |    505.724820 |    184.254306 | Matt Crook                                                                                                                                                            |
| 921 |    828.857392 |     28.595725 | Rene Martin                                                                                                                                                           |
| 922 |    161.237576 |      7.610497 | Jagged Fang Designs                                                                                                                                                   |
| 923 |     69.634118 |    791.937054 | Markus A. Grohme                                                                                                                                                      |
| 924 |    980.459766 |    173.141250 | Ferran Sayol                                                                                                                                                          |
| 925 |      8.638559 |    250.756640 | Noah Schlottman, photo from National Science Foundation - Turbellarian Taxonomic Database                                                                             |
| 926 |    649.970474 |    666.347046 | Sharon Wegner-Larsen                                                                                                                                                  |
| 927 |    727.803022 |    447.068650 | Margot Michaud                                                                                                                                                        |
| 928 |    286.937959 |    438.660645 | Gabriela Palomo-Munoz                                                                                                                                                 |

    #> Your tweet has been posted!
