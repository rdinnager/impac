
<!-- README.md is generated from README.Rmd. Please edit that file -->

# immosaic

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/rdinnager/immosaic/workflows/R-CMD-check/badge.svg)](https://github.com/rdinnager/immosaic/actions)
<!-- badges: end -->

The goal of `{immosaic}` is to create packed image mosaics. The main
function `immosaic`, takes a set of images, or a function that generates
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
devtools::install_github("rdinnager/immosaic")
```

## Example

This document and hence the images below are regenerated once a day
automatically. No two will ever be alike.

First we load the packages we need for these examples:

``` r
library(immosaic)
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

Now we feed our function to the `immosaic()` function, which packs the
generated images onto a canvas:

``` r
shapes <- immosaic(generate_platonic, progress = FALSE, show_every = 0, bg = "white")
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

Now we run `immosaic` on our phylopic generating function:

``` r
phylopics <- immosaic(get_phylopic, progress = FALSE, show_every = 0, bg = "white", min_scale = 0.01)
imager::save.image(phylopics$image, "man/figures/phylopic_a_pack.png")
```

![Packed images of organism silhouettes from
Phylopic](man/figures/phylopic_a_pack.png)

Now we extract the artists who made the above images using the uid of
image.

``` r
image_dat <- lapply(phylopics$meta$uuid, 
                    function(x) {Sys.sleep(0.5); rphylopic::image_get(x, options = c("credit"))$credit})
```

## Artists whose work is showcased:

Michelle Site, Matt Crook, C. Camilo Julián-Caballero, Jay Matternes
(vectorized by T. Michael Keesey), Martien Brand (original photo),
Renato Santos (vector silhouette), Steven Traver, Margot Michaud, Raven
Amos, Ferran Sayol, Arthur Weasley (vectorized by T. Michael Keesey),
Juan Carlos Jerí, Emily Willoughby, Tracy A. Heath, Alexander
Schmidt-Lebuhn, Eduard Solà (vectorized by T. Michael Keesey), Nobu
Tamura (vectorized by T. Michael Keesey), Yan Wong from wikipedia
drawing (PD: Pearson Scott Foresman), Mason McNair, Cristina Guijarro,
Scott Hartman, Joanna Wolfe, Gareth Monger, Tasman Dixon, Farelli
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Anthony Caravaggi, Darren Naish (vectorize by T. Michael
Keesey), Dean Schnabel, Mo Hassan, Smokeybjb, vectorized by Zimices,
Zimices, Nicolas Huet le Jeune and Jean-Gabriel Prêtre (vectorized by T.
Michael Keesey), Emily Jane McTavish, from
<http://en.wikipedia.org/wiki/File:Coccolithus_pelagicus.jpg>, Birgit
Lang, Cesar Julian, Xavier Giroux-Bougard, Shyamal, Christoph Schomburg,
Matt Martyniuk (modified by Serenchia), Dave Souza (vectorized by T.
Michael Keesey), Andrew A. Farke, modified from original by Robert Bruce
Horsfall, from Scott 1912, Alex Slavenko, Maija Karala, Arthur S. Brum,
T. Michael Keesey, Michael Scroggie, from original photograph by Gary M.
Stolz, USFWS (original photograph in public domain)., Martin R. Smith,
Yan Wong, Smokeybjb, FunkMonk, Noah Schlottman, photo from Casey Dunn,
Oliver Voigt, Daniel Stadtmauer, Scott Reid, Emily Jane McTavish, from
Haeckel, E. H. P. A. (1904).Kunstformen der Natur. Bibliographisches,
Maxime Dahirel, Jagged Fang Designs, Hans Hillewaert (vectorized by T.
Michael Keesey), Dmitry Bogdanov (vectorized by T. Michael Keesey),
Jaime Headden, Mathew Callaghan, Rebecca Groom, Chris huh,
SauropodomorphMonarch, Lukas Panzarin, T. Michael Keesey (after James &
al.), Lukasiniho, Jose Carlos Arenas-Monroy, Sarah Werning, Mathilde
Cordellier, James R. Spotila and Ray Chatterji, Mali’o Kodis, traced
image from the National Science Foundation’s Turbellarian Taxonomic
Database, Jonathan Lawley, Keith Murdock (photo), John E. McCormack,
Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C.
Glenn, Robb T. Brumfield & T. Michael Keesey, kreidefossilien.de, L.
Shyamal, Kai R. Caspar, Birgit Lang; based on a drawing by C.L. Koch,
Peileppe, Theodore W. Pietsch (photography) and T. Michael Keesey
(vectorization), Lip Kee Yap (vectorized by T. Michael Keesey), Douglas
Brown (modified by T. Michael Keesey), Steven Coombs, Crystal Maier,
David Orr, Ingo Braasch, Nobu Tamura, vectorized by Zimices, Fritz
Geller-Grimm (vectorized by T. Michael Keesey), M Kolmann, Brian Swartz
(vectorized by T. Michael Keesey), Milton Tan, Didier Descouens
(vectorized by T. Michael Keesey), Henry Fairfield Osborn, vectorized by
Zimices, Rene Martin, Pete Buchholz, T. Michael Keesey (from a mount by
Allis Markham), Roberto Díaz Sibaja, Ludwik Gasiorowski, Zachary
Quigley, Cyril Matthey-Doret, adapted from Bernard Chaubet, (unknown),
Carlos Cano-Barbacil, Matt Wilkins, Robbie N. Cada (modified by T.
Michael Keesey), Katie S. Collins, Gabriela Palomo-Munoz, Jon Hill
(Photo by Benjamint444:
<http://en.wikipedia.org/wiki/File:Blue-footed-booby.jpg>), Robert Bruce
Horsfall, vectorized by Zimices, M. Garfield & K. Anderson (modified by
T. Michael Keesey), FJDegrange, Francesco “Architetto” Rollandin, Lily
Hughes, Kanako Bessho-Uehara, François Michonneau, Alexandre Vong, DW
Bapst (Modified from photograph taken by Charles Mitchell), Matthew E.
Clapham, Mark Hofstetter (vectorized by T. Michael Keesey), kotik,
Dmitry Bogdanov, Michael Scroggie, T. Michael Keesey, from a photograph
by Thea Boodhoo, Obsidian Soul (vectorized by T. Michael Keesey), Mykle
Hoban, Manabu Bessho-Uehara, Chloé Schmidt, Conty (vectorized by T.
Michael Keesey), Original drawing by Antonov, vectorized by Roberto Díaz
Sibaja, Kamil S. Jaron, C. Abraczinskas, Karla Martinez, DFoidl
(vectorized by T. Michael Keesey), Andrew A. Farke, Robbie Cada
(vectorized by T. Michael Keesey), Roger Witter, vectorized by Zimices,
Owen Jones, Noah Schlottman, Tony Ayling (vectorized by T. Michael
Keesey), Harold N Eyster, T. Michael Keesey (after Kukalová), Collin
Gross, Yan Wong from drawing in The Century Dictionary (1911), B Kimmel,
Nancy Wyman (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Matt Celeskey, Falconaumanni and T. Michael Keesey,
Sergio A. Muñoz-Gómez, Griensteidl and T. Michael Keesey, Tauana J.
Cunha, Taenadoman, Tommaso Cancellario, Jiekun He, Jake Warner, Siobhon
Egan, Robert Gay, Becky Barnes, Beth Reinke, Meliponicultor Itaymbere,
Cathy, Eyal Bartov, Tyler Greenfield and Dean Schnabel, S.Martini,
Pollyanna von Knorring and T. Michael Keesey, Curtis Clark and T.
Michael Keesey, Jaime A. Headden (vectorized by T. Michael Keesey),
Madeleine Price Ball, ArtFavor & annaleeblysse, T. Michael Keesey (after
Marek Velechovský), T. Michael Keesey (after Ponomarenko), Cristopher
Silva, Tyler Greenfield, Noah Schlottman, photo by David J Patterson,
FunkMonk (Michael B.H.; vectorized by T. Michael Keesey), Noah
Schlottman, photo by Casey Dunn, Smokeybjb (modified by Mike Keesey),
Dennis C. Murphy, after
<https://commons.wikimedia.org/wiki/File:Queensland_State_Archives_2981_Cane_toads_at_the_Meringa_Sugar_Experiment_Station_North_Queensland_c_1935.png>,
Plukenet, Noah Schlottman, photo by Martin V. Sørensen, Mariana Ruiz
Villarreal, Pearson Scott Foresman (vectorized by T. Michael Keesey),
Robbie N. Cada (vectorized by T. Michael Keesey), Abraão Leite, Aviceda
(photo) & T. Michael Keesey, Martin Kevil, Wynston Cooper (photo) and
Albertonykus (silhouette), Iain Reid, Mali’o Kodis, photograph by
Aqua-Photos (<http://www.flickr.com/people/undervannsfotografen/>),
xgirouxb, Mathew Wedel, DW Bapst (Modified from Bulman, 1964), Chris
Hay, CNZdenek, Óscar San-Isidro (vectorized by T. Michael Keesey),
Lindberg (vectorized by T. Michael Keesey), Unknown (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Jessica Anne
Miller, Mark Witton, Matus Valach, Mali’o Kodis, photograph by “Wildcat
Dunny” (<http://www.flickr.com/people/wildcat_dunny/>), Dmitry Bogdanov
and FunkMonk (vectorized by T. Michael Keesey), Ellen Edmonson and Hugh
Chrisp (illustration) and Timothy J. Bartley (silhouette), Oscar
Sanisidro, Ernst Haeckel (vectorized by T. Michael Keesey), Dinah
Challen, Adrian Reich, Arthur Grosset (photo), John E. McCormack,
Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C.
Glenn, Robb T. Brumfield & T. Michael Keesey, Filip em, Jan A. Venter,
Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T.
Michael Keesey), Lani Mohan, Jay Matternes, vectorized by Zimices, Neil
Kelley, Ellen Edmonson (illustration) and Timothy J. Bartley
(silhouette), Rachel Shoop, Andreas Trepte (vectorized by T. Michael
Keesey), Mary Harrsch (modified by T. Michael Keesey), Hans Hillewaert,
Armin Reindl, Walter Vladimir, Ville-Veikko Sinkkonen, Felix Vaux,
Prathyush Thomas, Jon Hill, Cagri Cevrim, Chris Jennings (Risiatto),
Paul O. Lewis, John Conway, Sam Droege (photography) and T. Michael
Keesey (vectorization), I. Geoffroy Saint-Hilaire (vectorized by T.
Michael Keesey), Lafage, Brad McFeeters (vectorized by T. Michael
Keesey), J. J. Harrison (photo) & T. Michael Keesey, NOAA Great Lakes
Environmental Research Laboratory (illustration) and Timothy J. Bartley
(silhouette), Melissa Broussard, Chase Brownstein, Jimmy Bernot, Matt
Dempsey, V. Deepak, Caleb M. Brown, Henry Lydecker, Doug Backlund
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Todd Marshall, vectorized by Zimices, Maky (vectorization),
Gabriella Skollar (photography), Rebecca Lewis (editing), T. Michael
Keesey and Tanetahi, Ghedoghedo (vectorized by T. Michael Keesey),
Sharon Wegner-Larsen, Christopher Laumer (vectorized by T. Michael
Keesey), Michael Scroggie, from original photograph by John Bettaso,
USFWS (original photograph in public domain)., Liftarn, B. Duygu
Özpolat, Scott Hartman (modified by T. Michael Keesey), Cristian Osorio
& Paula Carrera, Proyecto Carnivoros Australes
(www.carnivorosaustrales.org), Sherman F. Denton via rawpixel.com
(illustration) and Timothy J. Bartley (silhouette), Michele M Tobias,
Jack Mayer Wood, Apokryltaros (vectorized by T. Michael Keesey),
Evan-Amos (vectorized by T. Michael Keesey), Francis de Laporte de
Castelnau (vectorized by T. Michael Keesey), Sidney Frederic Harmer,
Arthur Everett Shipley (vectorized by Maxime Dahirel), Tim Bertelink
(modified by T. Michael Keesey), Geoff Shaw, Emily Jane McTavish, Renata
F. Martins, NASA, John Curtis (vectorized by T. Michael Keesey), Philip
Chalmers (vectorized by T. Michael Keesey), Jakovche, Prin Pattawaro
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                          |
| --: | ------------: | ------------: | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
|   1 |    289.634254 |    186.859237 | Michelle Site                                                                                                                                                                   |
|   2 |    634.159656 |    649.472638 | Matt Crook                                                                                                                                                                      |
|   3 |    909.274767 |    647.236011 | C. Camilo Julián-Caballero                                                                                                                                                      |
|   4 |    382.204408 |    427.282159 | Jay Matternes (vectorized by T. Michael Keesey)                                                                                                                                 |
|   5 |    804.040228 |    680.005944 | Martien Brand (original photo), Renato Santos (vector silhouette)                                                                                                               |
|   6 |    880.824401 |    376.895393 | Steven Traver                                                                                                                                                                   |
|   7 |    775.790215 |    491.765263 | Margot Michaud                                                                                                                                                                  |
|   8 |    226.008745 |    643.690551 | Raven Amos                                                                                                                                                                      |
|   9 |    719.720734 |    227.457078 | Ferran Sayol                                                                                                                                                                    |
|  10 |    949.727664 |    139.038938 | Arthur Weasley (vectorized by T. Michael Keesey)                                                                                                                                |
|  11 |    596.918941 |    290.083237 | Juan Carlos Jerí                                                                                                                                                                |
|  12 |    290.934941 |    544.158446 | Steven Traver                                                                                                                                                                   |
|  13 |    242.607624 |    424.170640 | Emily Willoughby                                                                                                                                                                |
|  14 |    673.310046 |    123.566933 | Tracy A. Heath                                                                                                                                                                  |
|  15 |    449.368868 |    266.709327 | Alexander Schmidt-Lebuhn                                                                                                                                                        |
|  16 |    437.181342 |    196.434950 | Eduard Solà (vectorized by T. Michael Keesey)                                                                                                                                   |
|  17 |    451.096576 |    505.284527 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
|  18 |    246.168730 |    776.374753 | Yan Wong from wikipedia drawing (PD: Pearson Scott Foresman)                                                                                                                    |
|  19 |    913.494839 |     79.160180 | Margot Michaud                                                                                                                                                                  |
|  20 |    130.850930 |    193.530920 | Mason McNair                                                                                                                                                                    |
|  21 |     93.307967 |    495.606541 | Cristina Guijarro                                                                                                                                                               |
|  22 |    502.643890 |     29.211816 | Scott Hartman                                                                                                                                                                   |
|  23 |    373.832467 |    649.294869 | Joanna Wolfe                                                                                                                                                                    |
|  24 |    338.411044 |    351.213256 | Gareth Monger                                                                                                                                                                   |
|  25 |    741.898175 |    554.486400 | Tasman Dixon                                                                                                                                                                    |
|  26 |     94.847534 |     78.945776 | Farelli (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                         |
|  27 |    813.574663 |    130.575099 | Anthony Caravaggi                                                                                                                                                               |
|  28 |    320.251193 |    729.194483 | Joanna Wolfe                                                                                                                                                                    |
|  29 |    887.846070 |    246.562503 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                                   |
|  30 |    529.032615 |    548.702480 | Dean Schnabel                                                                                                                                                                   |
|  31 |    151.211479 |     59.609530 | Steven Traver                                                                                                                                                                   |
|  32 |    166.490942 |    397.923358 | Matt Crook                                                                                                                                                                      |
|  33 |     73.060324 |    746.822711 | Mo Hassan                                                                                                                                                                       |
|  34 |     98.697317 |    357.372996 | Smokeybjb, vectorized by Zimices                                                                                                                                                |
|  35 |    984.393045 |    535.636300 | NA                                                                                                                                                                              |
|  36 |    891.468314 |    757.288644 | Zimices                                                                                                                                                                         |
|  37 |    369.258894 |     89.004520 | Ferran Sayol                                                                                                                                                                    |
|  38 |    102.144437 |    245.096094 | Nicolas Huet le Jeune and Jean-Gabriel Prêtre (vectorized by T. Michael Keesey)                                                                                                 |
|  39 |    217.924380 |    261.647079 | Emily Jane McTavish, from <http://en.wikipedia.org/wiki/File:Coccolithus_pelagicus.jpg>                                                                                         |
|  40 |    439.518894 |    732.592187 | Birgit Lang                                                                                                                                                                     |
|  41 |    793.277829 |    329.605820 | Matt Crook                                                                                                                                                                      |
|  42 |    954.935832 |    206.437142 | Cesar Julian                                                                                                                                                                    |
|  43 |    969.230012 |    292.512463 | Xavier Giroux-Bougard                                                                                                                                                           |
|  44 |    822.909490 |     21.695638 | Shyamal                                                                                                                                                                         |
|  45 |    747.124749 |    112.230059 | Christoph Schomburg                                                                                                                                                             |
|  46 |    801.089138 |    292.932778 | Matt Martyniuk (modified by Serenchia)                                                                                                                                          |
|  47 |    218.770445 |    698.503724 | Dave Souza (vectorized by T. Michael Keesey)                                                                                                                                    |
|  48 |    459.812280 |    620.840301 | Andrew A. Farke, modified from original by Robert Bruce Horsfall, from Scott 1912                                                                                               |
|  49 |     75.467172 |    658.942477 | Steven Traver                                                                                                                                                                   |
|  50 |    578.728462 |    513.343426 | Alex Slavenko                                                                                                                                                                   |
|  51 |    700.739902 |     46.663725 | Scott Hartman                                                                                                                                                                   |
|  52 |    710.397901 |    766.309971 | Maija Karala                                                                                                                                                                    |
|  53 |    894.581556 |    690.281548 | Arthur S. Brum                                                                                                                                                                  |
|  54 |    481.989695 |     90.270996 | Emily Willoughby                                                                                                                                                                |
|  55 |    884.396191 |    577.390750 | Margot Michaud                                                                                                                                                                  |
|  56 |    740.934148 |    675.665829 | T. Michael Keesey                                                                                                                                                               |
|  57 |    229.678741 |    494.438190 | Michael Scroggie, from original photograph by Gary M. Stolz, USFWS (original photograph in public domain).                                                                      |
|  58 |    554.773747 |    736.727337 | Martin R. Smith                                                                                                                                                                 |
|  59 |    950.092146 |    521.122629 | Martin R. Smith                                                                                                                                                                 |
|  60 |     23.847476 |    499.581260 | Yan Wong                                                                                                                                                                        |
|  61 |    282.830485 |    605.450189 | Smokeybjb                                                                                                                                                                       |
|  62 |    319.599253 |    292.535629 | Matt Crook                                                                                                                                                                      |
|  63 |    216.570980 |    136.720608 | Alexander Schmidt-Lebuhn                                                                                                                                                        |
|  64 |     44.993573 |    153.187664 | NA                                                                                                                                                                              |
|  65 |    885.955883 |    447.943676 | T. Michael Keesey                                                                                                                                                               |
|  66 |    782.204801 |    389.623104 | Steven Traver                                                                                                                                                                   |
|  67 |    959.385215 |    620.096635 | FunkMonk                                                                                                                                                                        |
|  68 |     43.710881 |    389.757433 | Noah Schlottman, photo from Casey Dunn                                                                                                                                          |
|  69 |    476.546529 |    757.632894 | Maija Karala                                                                                                                                                                    |
|  70 |    357.797358 |    493.487355 | Oliver Voigt                                                                                                                                                                    |
|  71 |    680.767750 |    689.838681 | Tracy A. Heath                                                                                                                                                                  |
|  72 |    840.105068 |    263.764048 | Daniel Stadtmauer                                                                                                                                                               |
|  73 |    997.631113 |    377.493167 | Matt Crook                                                                                                                                                                      |
|  74 |     27.559915 |    287.714104 | Christoph Schomburg                                                                                                                                                             |
|  75 |    790.349015 |    617.783524 | Scott Hartman                                                                                                                                                                   |
|  76 |    982.971982 |     36.508776 | NA                                                                                                                                                                              |
|  77 |    183.825383 |    182.550779 | Gareth Monger                                                                                                                                                                   |
|  78 |    805.278762 |    244.465371 | Tracy A. Heath                                                                                                                                                                  |
|  79 |    990.864301 |    699.158050 | Scott Reid                                                                                                                                                                      |
|  80 |    460.206741 |    132.178423 | Emily Jane McTavish, from Haeckel, E. H. P. A. (1904).Kunstformen der Natur. Bibliographisches                                                                                  |
|  81 |    584.584691 |     34.450559 | Maxime Dahirel                                                                                                                                                                  |
|  82 |    527.219442 |    727.804332 | Jagged Fang Designs                                                                                                                                                             |
|  83 |    672.306575 |    417.851277 | Matt Crook                                                                                                                                                                      |
|  84 |    921.546322 |    532.475837 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                               |
|  85 |    965.544272 |    598.167183 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
|  86 |    595.188740 |     51.016638 | Jaime Headden                                                                                                                                                                   |
|  87 |    221.382731 |    384.229876 | Mathew Callaghan                                                                                                                                                                |
|  88 |    966.279982 |    432.444779 | Rebecca Groom                                                                                                                                                                   |
|  89 |    426.883674 |    158.512582 | Jagged Fang Designs                                                                                                                                                             |
|  90 |     79.038809 |    111.742713 | Chris huh                                                                                                                                                                       |
|  91 |    232.457241 |    725.239274 | Dean Schnabel                                                                                                                                                                   |
|  92 |    858.002586 |    655.190527 | SauropodomorphMonarch                                                                                                                                                           |
|  93 |    278.321638 |     78.320021 | Lukas Panzarin                                                                                                                                                                  |
|  94 |    884.249282 |    490.647551 | T. Michael Keesey (after James & al.)                                                                                                                                           |
|  95 |    170.744575 |    758.562775 | Lukasiniho                                                                                                                                                                      |
|  96 |    156.129207 |     13.364390 | Steven Traver                                                                                                                                                                   |
|  97 |    821.375094 |     82.119949 | NA                                                                                                                                                                              |
|  98 |    449.358720 |    785.073213 | Jose Carlos Arenas-Monroy                                                                                                                                                       |
|  99 |    570.440588 |    630.765067 | Sarah Werning                                                                                                                                                                   |
| 100 |    379.996807 |    560.848369 | Mathilde Cordellier                                                                                                                                                             |
| 101 |    140.571588 |    700.299030 | Zimices                                                                                                                                                                         |
| 102 |    205.426559 |    330.072726 | Zimices                                                                                                                                                                         |
| 103 |    550.259176 |    648.745591 | James R. Spotila and Ray Chatterji                                                                                                                                              |
| 104 |    671.580981 |    275.363993 | Mali’o Kodis, traced image from the National Science Foundation’s Turbellarian Taxonomic Database                                                                               |
| 105 |    877.602138 |    169.906012 | NA                                                                                                                                                                              |
| 106 |    775.753628 |    243.865825 | Jonathan Lawley                                                                                                                                                                 |
| 107 |     34.842385 |    373.068544 | Margot Michaud                                                                                                                                                                  |
| 108 |    881.646253 |    119.947753 | Maija Karala                                                                                                                                                                    |
| 109 |    126.930210 |    687.743634 | Jagged Fang Designs                                                                                                                                                             |
| 110 |   1014.445756 |    343.424885 | Keith Murdock (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                   |
| 111 |    465.016450 |    420.366904 | kreidefossilien.de                                                                                                                                                              |
| 112 |    842.418391 |    105.758630 | L. Shyamal                                                                                                                                                                      |
| 113 |    222.075111 |    566.022587 | Maija Karala                                                                                                                                                                    |
| 114 |    682.185070 |    704.809027 | Kai R. Caspar                                                                                                                                                                   |
| 115 |     18.777932 |    533.762831 | Mathilde Cordellier                                                                                                                                                             |
| 116 |    418.712479 |    384.831330 | Birgit Lang; based on a drawing by C.L. Koch                                                                                                                                    |
| 117 |    683.441690 |    721.163095 | Birgit Lang                                                                                                                                                                     |
| 118 |    541.135598 |    187.671218 | Jagged Fang Designs                                                                                                                                                             |
| 119 |    717.330148 |    321.477012 | Peileppe                                                                                                                                                                        |
| 120 |    629.100482 |    504.933401 | Theodore W. Pietsch (photography) and T. Michael Keesey (vectorization)                                                                                                         |
| 121 |    725.352227 |    743.025697 | Lip Kee Yap (vectorized by T. Michael Keesey)                                                                                                                                   |
| 122 |    616.058392 |    560.413316 | Douglas Brown (modified by T. Michael Keesey)                                                                                                                                   |
| 123 |     66.307577 |    302.950751 | Steven Coombs                                                                                                                                                                   |
| 124 |    535.079315 |    625.483422 | Steven Traver                                                                                                                                                                   |
| 125 |    313.772031 |    433.903169 | Crystal Maier                                                                                                                                                                   |
| 126 |    460.876475 |    165.937368 | David Orr                                                                                                                                                                       |
| 127 |    768.643716 |    133.547604 | Gareth Monger                                                                                                                                                                   |
| 128 |     65.647769 |    130.892237 | Ingo Braasch                                                                                                                                                                    |
| 129 |    539.453169 |    703.259191 | Margot Michaud                                                                                                                                                                  |
| 130 |    986.696850 |    769.505412 | Steven Traver                                                                                                                                                                   |
| 131 |    416.483084 |      6.526143 | Nobu Tamura, vectorized by Zimices                                                                                                                                              |
| 132 |    332.548094 |     79.852712 | Steven Traver                                                                                                                                                                   |
| 133 |    274.390552 |    501.591426 | Zimices                                                                                                                                                                         |
| 134 |    815.875152 |    214.863784 | Margot Michaud                                                                                                                                                                  |
| 135 |     27.891465 |    312.181039 | Gareth Monger                                                                                                                                                                   |
| 136 |    651.977169 |    567.983816 | Margot Michaud                                                                                                                                                                  |
| 137 |    291.764047 |    497.669779 | Daniel Stadtmauer                                                                                                                                                               |
| 138 |    312.081782 |    255.421719 | Gareth Monger                                                                                                                                                                   |
| 139 |    195.930775 |    591.216253 | Fritz Geller-Grimm (vectorized by T. Michael Keesey)                                                                                                                            |
| 140 |     30.786771 |    612.193606 | M Kolmann                                                                                                                                                                       |
| 141 |    894.104394 |    786.485076 | Joanna Wolfe                                                                                                                                                                    |
| 142 |    194.620987 |    150.145178 | Scott Hartman                                                                                                                                                                   |
| 143 |    976.290013 |      5.757232 | Christoph Schomburg                                                                                                                                                             |
| 144 |     61.128720 |    394.184286 | Margot Michaud                                                                                                                                                                  |
| 145 |    442.565602 |    551.043802 | Brian Swartz (vectorized by T. Michael Keesey)                                                                                                                                  |
| 146 |    966.177592 |    710.253313 | Milton Tan                                                                                                                                                                      |
| 147 |    988.698643 |    402.851836 | Dean Schnabel                                                                                                                                                                   |
| 148 |    774.772601 |    157.450467 | NA                                                                                                                                                                              |
| 149 |    558.554826 |     90.668076 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                              |
| 150 |    576.489754 |    787.094949 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                                                   |
| 151 |    324.568349 |    787.097268 | Rene Martin                                                                                                                                                                     |
| 152 |    429.846445 |    565.761413 | Pete Buchholz                                                                                                                                                                   |
| 153 |    516.504735 |    677.858084 | T. Michael Keesey (from a mount by Allis Markham)                                                                                                                               |
| 154 |    437.932152 |     86.564660 | NA                                                                                                                                                                              |
| 155 |    282.648449 |    670.491034 | Steven Traver                                                                                                                                                                   |
| 156 |    700.774740 |    454.831620 | Roberto Díaz Sibaja                                                                                                                                                             |
| 157 |     32.449338 |      9.514245 | Chris huh                                                                                                                                                                       |
| 158 |    823.000968 |    758.499839 | Ludwik Gasiorowski                                                                                                                                                              |
| 159 |    272.939942 |    622.751279 | Zachary Quigley                                                                                                                                                                 |
| 160 |    187.209912 |    157.100241 | NA                                                                                                                                                                              |
| 161 |    785.014586 |    430.340442 | Daniel Stadtmauer                                                                                                                                                               |
| 162 |    592.998545 |    761.466719 | Cyril Matthey-Doret, adapted from Bernard Chaubet                                                                                                                               |
| 163 |    408.887007 |     95.952888 | Gareth Monger                                                                                                                                                                   |
| 164 |    501.810705 |    450.703862 | Steven Traver                                                                                                                                                                   |
| 165 |    218.923895 |     53.142419 | NA                                                                                                                                                                              |
| 166 |    685.289592 |    787.062569 | (unknown)                                                                                                                                                                       |
| 167 |    889.340396 |    200.671821 | Birgit Lang                                                                                                                                                                     |
| 168 |    950.843542 |    182.985408 | Ferran Sayol                                                                                                                                                                    |
| 169 |     52.721519 |    358.795509 | Daniel Stadtmauer                                                                                                                                                               |
| 170 |    772.620796 |     52.172811 | Margot Michaud                                                                                                                                                                  |
| 171 |     89.070859 |    317.986145 | Carlos Cano-Barbacil                                                                                                                                                            |
| 172 |    289.612487 |    478.703953 | Matt Wilkins                                                                                                                                                                    |
| 173 |    932.683049 |    779.877066 | T. Michael Keesey                                                                                                                                                               |
| 174 |      9.473572 |    337.421601 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                                                  |
| 175 |    544.148482 |      2.037975 | Chris huh                                                                                                                                                                       |
| 176 |    528.794643 |    656.939947 | Birgit Lang                                                                                                                                                                     |
| 177 |    451.925398 |     52.013539 | Dean Schnabel                                                                                                                                                                   |
| 178 |    943.549441 |    508.862307 | Steven Traver                                                                                                                                                                   |
| 179 |    690.072228 |    100.686431 | Katie S. Collins                                                                                                                                                                |
| 180 |    692.151521 |    675.434280 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 181 |    832.191960 |    722.675026 | Jon Hill (Photo by Benjamint444: <http://en.wikipedia.org/wiki/File:Blue-footed-booby.jpg>)                                                                                     |
| 182 |    602.063126 |    782.745478 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                                    |
| 183 |    520.912018 |    693.375306 | Jose Carlos Arenas-Monroy                                                                                                                                                       |
| 184 |     66.750204 |    406.413750 | Gareth Monger                                                                                                                                                                   |
| 185 |     97.850085 |    787.058745 | L. Shyamal                                                                                                                                                                      |
| 186 |    251.890195 |    336.955944 | M. Garfield & K. Anderson (modified by T. Michael Keesey)                                                                                                                       |
| 187 |    381.510385 |    147.377883 | FJDegrange                                                                                                                                                                      |
| 188 |    895.648857 |    131.365591 | Steven Coombs                                                                                                                                                                   |
| 189 |    189.348259 |     97.002809 | Francesco “Architetto” Rollandin                                                                                                                                                |
| 190 |    490.106581 |    155.301851 | Mo Hassan                                                                                                                                                                       |
| 191 |    918.803742 |    672.446776 | Smokeybjb                                                                                                                                                                       |
| 192 |    753.729492 |    195.479728 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 193 |    221.522596 |    580.726371 | Lily Hughes                                                                                                                                                                     |
| 194 |    615.174898 |    795.126713 | Kanako Bessho-Uehara                                                                                                                                                            |
| 195 |    116.100722 |     91.395490 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                                                  |
| 196 |     22.189042 |    657.756997 | François Michonneau                                                                                                                                                             |
| 197 |    395.200360 |    489.892028 | Matt Crook                                                                                                                                                                      |
| 198 |    252.079523 |    587.086906 | Alexandre Vong                                                                                                                                                                  |
| 199 |    680.378208 |    195.948968 | Matt Crook                                                                                                                                                                      |
| 200 |     45.614541 |    570.532202 | Gareth Monger                                                                                                                                                                   |
| 201 |    179.053459 |    364.672838 | Maija Karala                                                                                                                                                                    |
| 202 |     94.248632 |    133.267764 | DW Bapst (Modified from photograph taken by Charles Mitchell)                                                                                                                   |
| 203 |    250.733001 |    319.833128 | Matt Crook                                                                                                                                                                      |
| 204 |    511.373842 |    145.515318 | Cristina Guijarro                                                                                                                                                               |
| 205 |    777.638540 |    677.635138 | Matthew E. Clapham                                                                                                                                                              |
| 206 |     53.042817 |    466.129093 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 207 |    164.737876 |    123.343450 | Mark Hofstetter (vectorized by T. Michael Keesey)                                                                                                                               |
| 208 |    797.517024 |    553.326158 | NA                                                                                                                                                                              |
| 209 |    811.373334 |    737.928967 | kotik                                                                                                                                                                           |
| 210 |    335.123653 |    217.543823 | Dmitry Bogdanov                                                                                                                                                                 |
| 211 |    594.472344 |     80.012128 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 212 |    332.519562 |     53.307016 | Gareth Monger                                                                                                                                                                   |
| 213 |    460.998057 |      6.688410 | Tasman Dixon                                                                                                                                                                    |
| 214 |    890.411179 |    424.283805 | Michael Scroggie                                                                                                                                                                |
| 215 |    710.170810 |    670.488706 | Zimices                                                                                                                                                                         |
| 216 |    270.569744 |    480.975706 | T. Michael Keesey, from a photograph by Thea Boodhoo                                                                                                                            |
| 217 |    883.130411 |    302.698276 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                                 |
| 218 |    879.853470 |     50.730191 | Zimices                                                                                                                                                                         |
| 219 |    103.991465 |     75.385783 | NA                                                                                                                                                                              |
| 220 |    183.699560 |    551.197630 | Mykle Hoban                                                                                                                                                                     |
| 221 |    805.261741 |    595.497084 | Margot Michaud                                                                                                                                                                  |
| 222 |    241.688889 |     55.530899 | Zimices                                                                                                                                                                         |
| 223 |    948.356479 |    335.255683 | Manabu Bessho-Uehara                                                                                                                                                            |
| 224 |    956.013538 |    740.906005 | NA                                                                                                                                                                              |
| 225 |    393.594771 |    680.155752 | Zimices                                                                                                                                                                         |
| 226 |    758.051114 |    590.618492 | Ferran Sayol                                                                                                                                                                    |
| 227 |    540.614729 |    604.267305 | Ferran Sayol                                                                                                                                                                    |
| 228 |    395.677875 |     37.331387 | Chris huh                                                                                                                                                                       |
| 229 |    522.267326 |    447.111179 | Noah Schlottman, photo from Casey Dunn                                                                                                                                          |
| 230 |    962.461492 |    276.401983 | Chloé Schmidt                                                                                                                                                                   |
| 231 |    558.666676 |     52.723849 | FunkMonk                                                                                                                                                                        |
| 232 |    944.261725 |     34.868330 | Matt Crook                                                                                                                                                                      |
| 233 |     83.740360 |    615.530961 | NA                                                                                                                                                                              |
| 234 |    765.228048 |    423.700220 | Conty (vectorized by T. Michael Keesey)                                                                                                                                         |
| 235 |    295.967228 |    764.206797 | NA                                                                                                                                                                              |
| 236 |    826.462881 |     52.976345 | Matt Crook                                                                                                                                                                      |
| 237 |    175.555152 |      7.918167 | NA                                                                                                                                                                              |
| 238 |    829.915601 |    790.284344 | Alex Slavenko                                                                                                                                                                   |
| 239 |    326.238168 |    396.841935 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 240 |     80.698792 |    701.223445 | Steven Traver                                                                                                                                                                   |
| 241 |    371.035066 |    698.289504 | T. Michael Keesey                                                                                                                                                               |
| 242 |    776.333375 |     34.266352 | Original drawing by Antonov, vectorized by Roberto Díaz Sibaja                                                                                                                  |
| 243 |    623.790232 |     47.963268 | Kamil S. Jaron                                                                                                                                                                  |
| 244 |    836.803753 |     78.618483 | Margot Michaud                                                                                                                                                                  |
| 245 |    435.336875 |    339.647749 | Chris huh                                                                                                                                                                       |
| 246 |    220.934917 |    553.380684 | Matt Crook                                                                                                                                                                      |
| 247 |    255.749008 |    750.946836 | C. Abraczinskas                                                                                                                                                                 |
| 248 |    981.979440 |    230.900461 | Scott Hartman                                                                                                                                                                   |
| 249 |    698.605832 |     71.549537 | Zimices                                                                                                                                                                         |
| 250 |    670.102118 |    533.344075 | Gareth Monger                                                                                                                                                                   |
| 251 |    849.921862 |    711.706060 | Karla Martinez                                                                                                                                                                  |
| 252 |   1020.236665 |     86.255798 | Kamil S. Jaron                                                                                                                                                                  |
| 253 |    461.562718 |    340.521461 | Margot Michaud                                                                                                                                                                  |
| 254 |    153.107558 |    369.050096 | Ferran Sayol                                                                                                                                                                    |
| 255 |    558.543532 |    764.444391 | Steven Traver                                                                                                                                                                   |
| 256 |    236.980270 |    739.138084 | Zimices                                                                                                                                                                         |
| 257 |    308.470154 |    475.360386 | NA                                                                                                                                                                              |
| 258 |    772.072258 |    785.717439 | Steven Traver                                                                                                                                                                   |
| 259 |     69.670331 |    442.874372 | Matt Crook                                                                                                                                                                      |
| 260 |    918.164217 |    486.794526 | Lukasiniho                                                                                                                                                                      |
| 261 |    966.403660 |     77.988890 | NA                                                                                                                                                                              |
| 262 |    143.983839 |    648.526905 | DFoidl (vectorized by T. Michael Keesey)                                                                                                                                        |
| 263 |    383.395826 |    292.467514 | Michelle Site                                                                                                                                                                   |
| 264 |    383.594794 |     19.922960 | Andrew A. Farke                                                                                                                                                                 |
| 265 |    727.325633 |    265.008868 | Andrew A. Farke                                                                                                                                                                 |
| 266 |    916.507256 |     51.514755 | Martin R. Smith                                                                                                                                                                 |
| 267 |    523.250642 |     59.644095 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 268 |    605.640423 |    595.541813 | Scott Hartman                                                                                                                                                                   |
| 269 |    503.537050 |    203.283026 | Robbie Cada (vectorized by T. Michael Keesey)                                                                                                                                   |
| 270 |    382.344007 |    585.651646 | Roger Witter, vectorized by Zimices                                                                                                                                             |
| 271 |     24.987509 |     78.692696 | Owen Jones                                                                                                                                                                      |
| 272 |     12.004222 |     65.385014 | Michelle Site                                                                                                                                                                   |
| 273 |    634.624321 |    519.197880 | Maija Karala                                                                                                                                                                    |
| 274 |    280.746208 |     48.423251 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                                 |
| 275 |    732.555850 |     34.729660 | Gareth Monger                                                                                                                                                                   |
| 276 |    808.107496 |    786.852868 | T. Michael Keesey                                                                                                                                                               |
| 277 |    507.111724 |    720.439708 | Rebecca Groom                                                                                                                                                                   |
| 278 |    140.557697 |    107.715919 | Gareth Monger                                                                                                                                                                   |
| 279 |    929.381043 |    793.807175 | Noah Schlottman                                                                                                                                                                 |
| 280 |    400.180117 |    226.209628 | Chris huh                                                                                                                                                                       |
| 281 |     22.378345 |    688.532856 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                                   |
| 282 |    227.546149 |    647.870152 | Matt Crook                                                                                                                                                                      |
| 283 |    532.911512 |    158.142660 | Matt Crook                                                                                                                                                                      |
| 284 |   1010.962029 |    694.853399 | NA                                                                                                                                                                              |
| 285 |     13.921771 |     25.116426 | Scott Reid                                                                                                                                                                      |
| 286 |    536.605389 |    481.233566 | FunkMonk                                                                                                                                                                        |
| 287 |    683.347769 |    744.441641 | Alexandre Vong                                                                                                                                                                  |
| 288 |    369.467863 |    184.686711 | T. Michael Keesey                                                                                                                                                               |
| 289 |    534.732154 |    137.235184 | Harold N Eyster                                                                                                                                                                 |
| 290 |    499.780162 |    756.606565 | T. Michael Keesey (after Kukalová)                                                                                                                                              |
| 291 |    170.304369 |    463.199973 | NA                                                                                                                                                                              |
| 292 |    481.638931 |    512.466740 | Collin Gross                                                                                                                                                                    |
| 293 |    433.620570 |     28.928222 | Matt Crook                                                                                                                                                                      |
| 294 |    898.436463 |     41.783621 | Yan Wong from drawing in The Century Dictionary (1911)                                                                                                                          |
| 295 |     16.761958 |    104.915518 | Gareth Monger                                                                                                                                                                   |
| 296 |    716.803717 |    629.569924 | Jagged Fang Designs                                                                                                                                                             |
| 297 |     40.453617 |    694.540633 | B Kimmel                                                                                                                                                                        |
| 298 |    256.451809 |     72.265755 | Margot Michaud                                                                                                                                                                  |
| 299 |    252.572810 |     34.966000 | Chloé Schmidt                                                                                                                                                                   |
| 300 |    811.448332 |    443.825411 | Roberto Díaz Sibaja                                                                                                                                                             |
| 301 |    176.157744 |    568.081311 | Scott Hartman                                                                                                                                                                   |
| 302 |    449.204668 |    673.822564 | Dave Souza (vectorized by T. Michael Keesey)                                                                                                                                    |
| 303 |    245.461188 |    644.854217 | FunkMonk                                                                                                                                                                        |
| 304 |    674.771986 |    460.331817 | Joanna Wolfe                                                                                                                                                                    |
| 305 |    532.629928 |    683.774135 | Nancy Wyman (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                     |
| 306 |    150.384780 |    431.732389 | James R. Spotila and Ray Chatterji                                                                                                                                              |
| 307 |    169.206617 |    479.138486 | NA                                                                                                                                                                              |
| 308 |    769.514099 |    169.836076 | Gareth Monger                                                                                                                                                                   |
| 309 |    701.757066 |    600.736764 | T. Michael Keesey                                                                                                                                                               |
| 310 |    417.325857 |    464.272816 | NA                                                                                                                                                                              |
| 311 |    801.225597 |    417.201762 | Collin Gross                                                                                                                                                                    |
| 312 |    486.442740 |     67.624815 | Scott Hartman                                                                                                                                                                   |
| 313 |    992.322000 |    442.400810 | Katie S. Collins                                                                                                                                                                |
| 314 |    748.683044 |     25.813598 | Zimices                                                                                                                                                                         |
| 315 |   1007.051351 |    735.436349 | Matt Celeskey                                                                                                                                                                   |
| 316 |    336.654853 |     95.920627 | NA                                                                                                                                                                              |
| 317 |    657.634742 |    749.605450 | Falconaumanni and T. Michael Keesey                                                                                                                                             |
| 318 |    768.316183 |    345.606023 | Jagged Fang Designs                                                                                                                                                             |
| 319 |    724.252481 |    605.228377 | Sergio A. Muñoz-Gómez                                                                                                                                                           |
| 320 |    176.182984 |    216.016715 | Griensteidl and T. Michael Keesey                                                                                                                                               |
| 321 |    657.103022 |    510.888665 | NA                                                                                                                                                                              |
| 322 |    960.463083 |    245.982844 | Zimices                                                                                                                                                                         |
| 323 |    400.564166 |     54.352585 | NA                                                                                                                                                                              |
| 324 |    672.695747 |    553.952196 | T. Michael Keesey                                                                                                                                                               |
| 325 |     43.315745 |     28.468095 | Tauana J. Cunha                                                                                                                                                                 |
| 326 |    213.961157 |    468.177504 | Taenadoman                                                                                                                                                                      |
| 327 |    715.169562 |    435.273879 | NA                                                                                                                                                                              |
| 328 |    148.844357 |    321.378767 | Alexander Schmidt-Lebuhn                                                                                                                                                        |
| 329 |     67.018268 |    384.012855 | Gareth Monger                                                                                                                                                                   |
| 330 |    420.059617 |     49.395494 | Birgit Lang                                                                                                                                                                     |
| 331 |    736.182045 |    165.084422 | FunkMonk                                                                                                                                                                        |
| 332 |     77.057374 |    174.235954 | Matt Crook                                                                                                                                                                      |
| 333 |    564.045127 |     31.454244 | Gareth Monger                                                                                                                                                                   |
| 334 |    647.969366 |    782.818842 | Maija Karala                                                                                                                                                                    |
| 335 |    825.360527 |    430.322218 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 336 |    542.557076 |    770.651788 | NA                                                                                                                                                                              |
| 337 |    613.009499 |    757.472794 | NA                                                                                                                                                                              |
| 338 |    188.714489 |    565.789829 | Michelle Site                                                                                                                                                                   |
| 339 |    317.403762 |    485.425260 | Zimices                                                                                                                                                                         |
| 340 |    426.287756 |    351.005705 | Birgit Lang                                                                                                                                                                     |
| 341 |    327.405884 |    583.735874 | Matt Crook                                                                                                                                                                      |
| 342 |    490.281544 |    120.993781 | Maija Karala                                                                                                                                                                    |
| 343 |    878.174270 |    718.602140 | Scott Reid                                                                                                                                                                      |
| 344 |    421.680162 |    137.022903 | Zimices                                                                                                                                                                         |
| 345 |    162.208712 |    437.949651 | Steven Traver                                                                                                                                                                   |
| 346 |    278.872402 |     17.938155 | Tracy A. Heath                                                                                                                                                                  |
| 347 |    888.204679 |    151.115992 | Birgit Lang                                                                                                                                                                     |
| 348 |    124.587240 |     87.641124 | Sarah Werning                                                                                                                                                                   |
| 349 |     68.783273 |    563.586986 | Andrew A. Farke                                                                                                                                                                 |
| 350 |    160.495513 |    655.719328 | Zimices                                                                                                                                                                         |
| 351 |    690.077231 |    444.043740 | Jagged Fang Designs                                                                                                                                                             |
| 352 |    687.001059 |    280.658949 | NA                                                                                                                                                                              |
| 353 |    372.883798 |    226.171481 | Matt Crook                                                                                                                                                                      |
| 354 |    565.030976 |    670.226088 | NA                                                                                                                                                                              |
| 355 |    664.023682 |    738.476377 | Zimices                                                                                                                                                                         |
| 356 |    148.108495 |    554.543000 | Zimices                                                                                                                                                                         |
| 357 |    670.292878 |     89.765397 | Tauana J. Cunha                                                                                                                                                                 |
| 358 |    849.156559 |    534.255537 | Joanna Wolfe                                                                                                                                                                    |
| 359 |    646.053633 |    214.553752 | Tommaso Cancellario                                                                                                                                                             |
| 360 |    955.988653 |     36.878852 | Roberto Díaz Sibaja                                                                                                                                                             |
| 361 |    924.576574 |    180.599171 | Fritz Geller-Grimm (vectorized by T. Michael Keesey)                                                                                                                            |
| 362 |    663.726636 |    556.415412 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                               |
| 363 |     28.772665 |    414.638399 | Jiekun He                                                                                                                                                                       |
| 364 |    320.715998 |    651.908613 | Jake Warner                                                                                                                                                                     |
| 365 |     39.340698 |    241.130577 | Smokeybjb, vectorized by Zimices                                                                                                                                                |
| 366 |    412.722812 |    311.598968 | Birgit Lang                                                                                                                                                                     |
| 367 |    999.482455 |    190.530936 | Siobhon Egan                                                                                                                                                                    |
| 368 |    700.705436 |     90.689234 | Chris huh                                                                                                                                                                       |
| 369 |    357.365493 |    573.433950 | NA                                                                                                                                                                              |
| 370 |    854.279781 |    762.264354 | Ferran Sayol                                                                                                                                                                    |
| 371 |    440.801817 |     40.497917 | Robert Gay                                                                                                                                                                      |
| 372 |    583.946596 |     11.269604 | Becky Barnes                                                                                                                                                                    |
| 373 |    892.117127 |    471.560698 | Beth Reinke                                                                                                                                                                     |
| 374 |    785.033876 |    408.929852 | Jagged Fang Designs                                                                                                                                                             |
| 375 |    513.694361 |    473.947385 | Gareth Monger                                                                                                                                                                   |
| 376 |    176.890481 |    170.153515 | Dmitry Bogdanov                                                                                                                                                                 |
| 377 |    161.743790 |    674.287103 | Chris huh                                                                                                                                                                       |
| 378 |    481.034250 |    327.176850 | Meliponicultor Itaymbere                                                                                                                                                        |
| 379 |    301.308605 |     81.167564 | L. Shyamal                                                                                                                                                                      |
| 380 |    511.372416 |    219.846490 | Matt Crook                                                                                                                                                                      |
| 381 |    787.228912 |    181.386032 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 382 |     16.417503 |    154.804430 | Scott Hartman                                                                                                                                                                   |
| 383 |    608.220369 |     68.830880 | Cathy                                                                                                                                                                           |
| 384 |    136.194696 |    384.621414 | Margot Michaud                                                                                                                                                                  |
| 385 |    509.954535 |    400.744795 | Mo Hassan                                                                                                                                                                       |
| 386 |    580.553340 |    605.991119 | Eyal Bartov                                                                                                                                                                     |
| 387 |    770.649304 |    444.234720 | Smokeybjb                                                                                                                                                                       |
| 388 |    994.001762 |    277.766101 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 389 |    677.250743 |    391.344353 | Tasman Dixon                                                                                                                                                                    |
| 390 |    567.373498 |    601.760236 | Matt Crook                                                                                                                                                                      |
| 391 |    795.262138 |     41.625322 | Zimices                                                                                                                                                                         |
| 392 |    890.767034 |    705.220380 | Zimices                                                                                                                                                                         |
| 393 |    931.476176 |    421.976022 | Tracy A. Heath                                                                                                                                                                  |
| 394 |    297.447525 |    442.391774 | Milton Tan                                                                                                                                                                      |
| 395 |    928.663783 |     26.318331 | T. Michael Keesey (after James & al.)                                                                                                                                           |
| 396 |    410.995572 |     60.789141 | Steven Traver                                                                                                                                                                   |
| 397 |    874.815821 |    793.615531 | Milton Tan                                                                                                                                                                      |
| 398 |    553.558198 |    575.278664 | Steven Traver                                                                                                                                                                   |
| 399 |    813.432038 |    572.026969 | Birgit Lang                                                                                                                                                                     |
| 400 |    259.391948 |     10.907232 | Chris huh                                                                                                                                                                       |
| 401 |     99.191937 |    578.253658 | Ferran Sayol                                                                                                                                                                    |
| 402 |   1010.032369 |    453.971286 | T. Michael Keesey                                                                                                                                                               |
| 403 |    385.699419 |    379.659348 | Tyler Greenfield and Dean Schnabel                                                                                                                                              |
| 404 |    472.497426 |    786.894263 | S.Martini                                                                                                                                                                       |
| 405 |     66.998364 |     12.941208 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 406 |    463.012520 |    518.891979 | NA                                                                                                                                                                              |
| 407 |    897.662180 |    177.000356 | Shyamal                                                                                                                                                                         |
| 408 |     57.958099 |    244.543068 | Crystal Maier                                                                                                                                                                   |
| 409 |     44.765887 |    613.711299 | Matt Crook                                                                                                                                                                      |
| 410 |    782.323360 |    652.043464 | Pollyanna von Knorring and T. Michael Keesey                                                                                                                                    |
| 411 |   1003.182428 |    526.230897 | Jagged Fang Designs                                                                                                                                                             |
| 412 |    101.664549 |    113.748735 | Curtis Clark and T. Michael Keesey                                                                                                                                              |
| 413 |    565.812804 |    692.847506 | NA                                                                                                                                                                              |
| 414 |    229.053373 |    666.676610 | Zimices                                                                                                                                                                         |
| 415 |   1009.920857 |     86.908778 | Ferran Sayol                                                                                                                                                                    |
| 416 |    446.200986 |    419.755683 | Ferran Sayol                                                                                                                                                                    |
| 417 |    768.533905 |    651.559162 | Chris huh                                                                                                                                                                       |
| 418 |    957.181440 |    227.029013 | Zimices                                                                                                                                                                         |
| 419 |    339.353307 |    765.452672 | Steven Traver                                                                                                                                                                   |
| 420 |    547.731918 |    169.490559 | Tasman Dixon                                                                                                                                                                    |
| 421 |     40.785671 |    351.091567 | Margot Michaud                                                                                                                                                                  |
| 422 |    556.107520 |     81.374863 | Katie S. Collins                                                                                                                                                                |
| 423 |    466.253120 |    114.688077 | FunkMonk                                                                                                                                                                        |
| 424 |    909.143065 |    138.581036 | Scott Hartman                                                                                                                                                                   |
| 425 |    371.499441 |    172.783803 | Alexandre Vong                                                                                                                                                                  |
| 426 |    871.353333 |    131.772513 | Steven Coombs                                                                                                                                                                   |
| 427 |    644.268407 |    550.326685 | Chris huh                                                                                                                                                                       |
| 428 |     19.508271 |    168.733428 | Margot Michaud                                                                                                                                                                  |
| 429 |    983.185072 |    672.145681 | Scott Hartman                                                                                                                                                                   |
| 430 |    243.401134 |    662.133540 | Jaime A. Headden (vectorized by T. Michael Keesey)                                                                                                                              |
| 431 |    355.138409 |    386.792402 | Madeleine Price Ball                                                                                                                                                            |
| 432 |    147.524152 |     17.981764 | Zimices                                                                                                                                                                         |
| 433 |    199.860614 |    166.481124 | ArtFavor & annaleeblysse                                                                                                                                                        |
| 434 |    991.391920 |    350.609007 | T. Michael Keesey (after Marek Velechovský)                                                                                                                                     |
| 435 |    125.272845 |    214.469669 | Zimices                                                                                                                                                                         |
| 436 |    295.056435 |    686.733158 | Steven Traver                                                                                                                                                                   |
| 437 |    995.027387 |    116.845055 | Margot Michaud                                                                                                                                                                  |
| 438 |    924.242444 |     80.264931 | T. Michael Keesey (after Ponomarenko)                                                                                                                                           |
| 439 |    763.939805 |    632.616533 | Joanna Wolfe                                                                                                                                                                    |
| 440 |     55.623638 |    209.661836 | Cristopher Silva                                                                                                                                                                |
| 441 |    135.965818 |    758.424364 | Tyler Greenfield                                                                                                                                                                |
| 442 |    725.507984 |    358.952943 | Noah Schlottman, photo by David J Patterson                                                                                                                                     |
| 443 |    715.620734 |    270.318682 | T. Michael Keesey                                                                                                                                                               |
| 444 |    818.901392 |    606.756012 | Zimices                                                                                                                                                                         |
| 445 |    664.819590 |    200.168907 | Matt Crook                                                                                                                                                                      |
| 446 |    777.692421 |    413.675679 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 447 |    501.513922 |    421.876266 | NA                                                                                                                                                                              |
| 448 |     18.462959 |    129.153586 | Jaime Headden                                                                                                                                                                   |
| 449 |    182.958480 |    202.733257 | FunkMonk (Michael B.H.; vectorized by T. Michael Keesey)                                                                                                                        |
| 450 |    417.030684 |    118.841978 | Matt Crook                                                                                                                                                                      |
| 451 |    117.683931 |    671.351174 | Birgit Lang                                                                                                                                                                     |
| 452 |    109.381967 |     29.254858 | Matt Crook                                                                                                                                                                      |
| 453 |    586.570426 |    575.654340 | Margot Michaud                                                                                                                                                                  |
| 454 |    177.620392 |    339.419294 | T. Michael Keesey                                                                                                                                                               |
| 455 |   1003.506711 |     97.622146 | Noah Schlottman, photo by Casey Dunn                                                                                                                                            |
| 456 |    899.358963 |    505.253423 | Beth Reinke                                                                                                                                                                     |
| 457 |    107.521226 |    409.645724 | Matt Crook                                                                                                                                                                      |
| 458 |    416.103310 |    708.810474 | Roberto Díaz Sibaja                                                                                                                                                             |
| 459 |     53.585935 |    526.414390 | Smokeybjb (modified by Mike Keesey)                                                                                                                                             |
| 460 |    257.733424 |    502.728560 | Matt Crook                                                                                                                                                                      |
| 461 |    408.204887 |    699.591348 | Dennis C. Murphy, after <https://commons.wikimedia.org/wiki/File:Queensland_State_Archives_2981_Cane_toads_at_the_Meringa_Sugar_Experiment_Station_North_Queensland_c_1935.png> |
| 462 |     85.156291 |    603.157982 | Jagged Fang Designs                                                                                                                                                             |
| 463 |    691.571060 |    682.033244 | Jagged Fang Designs                                                                                                                                                             |
| 464 |    417.845256 |    572.023111 | Scott Hartman                                                                                                                                                                   |
| 465 |    684.693269 |    607.997771 | Plukenet                                                                                                                                                                        |
| 466 |    507.411145 |    737.026631 | Steven Traver                                                                                                                                                                   |
| 467 |    184.995235 |    737.041753 | Jagged Fang Designs                                                                                                                                                             |
| 468 |    472.350514 |     63.168246 | Dean Schnabel                                                                                                                                                                   |
| 469 |    214.564920 |     29.209005 | Noah Schlottman, photo by Martin V. Sørensen                                                                                                                                    |
| 470 |    268.747515 |    400.088988 | Chris huh                                                                                                                                                                       |
| 471 |    139.812771 |    580.580674 | Ferran Sayol                                                                                                                                                                    |
| 472 |    461.669955 |    533.229639 | Zimices                                                                                                                                                                         |
| 473 |    997.772998 |    228.533504 | Mariana Ruiz Villarreal                                                                                                                                                         |
| 474 |    406.231472 |    169.052925 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                                    |
| 475 |    983.618001 |    723.413758 | Zimices                                                                                                                                                                         |
| 476 |    109.502299 |    704.930134 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                                        |
| 477 |    982.285549 |    104.230539 | Birgit Lang                                                                                                                                                                     |
| 478 |    355.957334 |      5.407958 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                                |
| 479 |    157.223628 |    200.297731 | T. Michael Keesey                                                                                                                                                               |
| 480 |    842.255643 |    774.934062 | NA                                                                                                                                                                              |
| 481 |    294.379045 |     20.705622 | NA                                                                                                                                                                              |
| 482 |    289.005171 |    590.846525 | Zimices                                                                                                                                                                         |
| 483 |    203.588742 |    551.290375 | Scott Reid                                                                                                                                                                      |
| 484 |    120.544995 |    309.299930 | Chris huh                                                                                                                                                                       |
| 485 |    739.651269 |    528.273341 | T. Michael Keesey                                                                                                                                                               |
| 486 |    281.798948 |    412.402092 | T. Michael Keesey                                                                                                                                                               |
| 487 |     14.135077 |    322.079311 | Maija Karala                                                                                                                                                                    |
| 488 |    934.639895 |    501.233934 | Griensteidl and T. Michael Keesey                                                                                                                                               |
| 489 |    372.723468 |    607.473514 | Birgit Lang                                                                                                                                                                     |
| 490 |   1011.657365 |    563.510100 | Emily Willoughby                                                                                                                                                                |
| 491 |    347.715426 |    397.725753 | Zimices                                                                                                                                                                         |
| 492 |     17.592417 |    613.345828 | Alexander Schmidt-Lebuhn                                                                                                                                                        |
| 493 |    692.564848 |    258.494061 | T. Michael Keesey                                                                                                                                                               |
| 494 |    787.052018 |    768.775602 | Scott Hartman                                                                                                                                                                   |
| 495 |   1006.424083 |    601.517603 | Abraão Leite                                                                                                                                                                    |
| 496 |    259.405190 |    355.293553 | Nicolas Huet le Jeune and Jean-Gabriel Prêtre (vectorized by T. Michael Keesey)                                                                                                 |
| 497 |    895.022761 |    335.780131 | Ferran Sayol                                                                                                                                                                    |
| 498 |    857.641015 |    782.202422 | Aviceda (photo) & T. Michael Keesey                                                                                                                                             |
| 499 |     62.467062 |    617.631404 | Scott Reid                                                                                                                                                                      |
| 500 |    159.266011 |    294.009821 | Sarah Werning                                                                                                                                                                   |
| 501 |     17.299419 |    698.408285 | Zimices                                                                                                                                                                         |
| 502 |    317.947218 |     26.070563 | Lukasiniho                                                                                                                                                                      |
| 503 |    271.572599 |     42.263071 | Martin Kevil                                                                                                                                                                    |
| 504 |    303.377389 |    418.668835 | Noah Schlottman, photo by Casey Dunn                                                                                                                                            |
| 505 |    654.929800 |    256.247111 | Roger Witter, vectorized by Zimices                                                                                                                                             |
| 506 |    340.599354 |    586.529939 | Wynston Cooper (photo) and Albertonykus (silhouette)                                                                                                                            |
| 507 |    357.556661 |     20.838577 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 508 |    117.304316 |    566.419198 | Matt Crook                                                                                                                                                                      |
| 509 |    502.963659 |    776.076136 | Matt Crook                                                                                                                                                                      |
| 510 |    977.579689 |    640.416542 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 511 |    876.752192 |    614.765872 | Iain Reid                                                                                                                                                                       |
| 512 |    257.676911 |    386.694462 | Sarah Werning                                                                                                                                                                   |
| 513 |    212.617063 |      8.782466 | Mali’o Kodis, photograph by Aqua-Photos (<http://www.flickr.com/people/undervannsfotografen/>)                                                                                  |
| 514 |     73.173143 |    165.000754 | Joanna Wolfe                                                                                                                                                                    |
| 515 |    667.045765 |    793.412998 | xgirouxb                                                                                                                                                                        |
| 516 |    335.227663 |     12.830500 | Christoph Schomburg                                                                                                                                                             |
| 517 |    514.784951 |    117.661634 | NA                                                                                                                                                                              |
| 518 |    939.074501 |     83.862302 | T. Michael Keesey, from a photograph by Thea Boodhoo                                                                                                                            |
| 519 |      6.978854 |    300.883242 | Matt Crook                                                                                                                                                                      |
| 520 |    178.470291 |    602.243112 | FunkMonk                                                                                                                                                                        |
| 521 |     68.626693 |    154.556509 | Zimices                                                                                                                                                                         |
| 522 |    373.705873 |    577.816108 | Mathew Wedel                                                                                                                                                                    |
| 523 |    150.325524 |    565.435331 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 524 |    654.970294 |     24.095855 | Zimices                                                                                                                                                                         |
| 525 |    918.544365 |    431.784630 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 526 |    540.701801 |    147.432103 | DW Bapst (Modified from Bulman, 1964)                                                                                                                                           |
| 527 |    874.661072 |    624.877259 | NA                                                                                                                                                                              |
| 528 |    929.754097 |    699.112332 | Anthony Caravaggi                                                                                                                                                               |
| 529 |    632.423258 |    584.498174 | FunkMonk                                                                                                                                                                        |
| 530 |   1012.195578 |    489.258529 | Scott Hartman                                                                                                                                                                   |
| 531 |    433.034223 |     19.529824 | Chris huh                                                                                                                                                                       |
| 532 |     11.768269 |    500.255848 | Crystal Maier                                                                                                                                                                   |
| 533 |     11.446643 |    225.780883 | Chris Hay                                                                                                                                                                       |
| 534 |    864.370214 |    316.233458 | NA                                                                                                                                                                              |
| 535 |    871.411276 |    335.793059 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 536 |    899.809330 |     25.002260 | Lukasiniho                                                                                                                                                                      |
| 537 |     42.868799 |    398.521501 | Emily Willoughby                                                                                                                                                                |
| 538 |    881.172687 |    402.754633 | CNZdenek                                                                                                                                                                        |
| 539 |      9.231460 |    254.542090 | Óscar San-Isidro (vectorized by T. Michael Keesey)                                                                                                                              |
| 540 |   1001.813628 |    645.003565 | Ferran Sayol                                                                                                                                                                    |
| 541 |    639.532208 |    734.688227 | Matt Crook                                                                                                                                                                      |
| 542 |    552.669237 |     62.958438 | Lindberg (vectorized by T. Michael Keesey)                                                                                                                                      |
| 543 |    542.647954 |    694.887522 | Margot Michaud                                                                                                                                                                  |
| 544 |    553.978647 |    590.011575 | Rebecca Groom                                                                                                                                                                   |
| 545 |    841.441149 |     90.670152 | Chris huh                                                                                                                                                                       |
| 546 |     70.672310 |    366.586348 | Margot Michaud                                                                                                                                                                  |
| 547 |    600.787430 |    536.036000 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                         |
| 548 |    392.585442 |     63.295193 | Jessica Anne Miller                                                                                                                                                             |
| 549 |     21.570045 |     43.974705 | Zimices                                                                                                                                                                         |
| 550 |    253.820249 |    668.598208 | Chris huh                                                                                                                                                                       |
| 551 |    107.522964 |    285.230516 | Birgit Lang                                                                                                                                                                     |
| 552 |    599.785628 |    590.674850 | Conty (vectorized by T. Michael Keesey)                                                                                                                                         |
| 553 |    369.077321 |    785.162026 | Matt Crook                                                                                                                                                                      |
| 554 |    992.381442 |     55.549767 | Tracy A. Heath                                                                                                                                                                  |
| 555 |    692.588415 |    439.687627 | Mark Witton                                                                                                                                                                     |
| 556 |    278.183657 |    228.028754 | Matus Valach                                                                                                                                                                    |
| 557 |     89.639895 |    444.858554 | Mali’o Kodis, photograph by “Wildcat Dunny” (<http://www.flickr.com/people/wildcat_dunny/>)                                                                                     |
| 558 |    496.347102 |    719.304110 | Ferran Sayol                                                                                                                                                                    |
| 559 |    658.428030 |    448.945124 | Ferran Sayol                                                                                                                                                                    |
| 560 |    194.184182 |    130.803572 | Chris huh                                                                                                                                                                       |
| 561 |    796.975686 |    224.593723 | Dmitry Bogdanov and FunkMonk (vectorized by T. Michael Keesey)                                                                                                                  |
| 562 |     93.063810 |     16.190582 | Margot Michaud                                                                                                                                                                  |
| 563 |    316.025040 |    672.924429 | Birgit Lang                                                                                                                                                                     |
| 564 |    713.563476 |    709.286820 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                                               |
| 565 |    345.074756 |    695.330869 | Oscar Sanisidro                                                                                                                                                                 |
| 566 |   1000.035454 |    666.795996 | Matt Crook                                                                                                                                                                      |
| 567 |    100.273082 |    617.449454 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                                 |
| 568 |   1011.001518 |    585.616565 | Alex Slavenko                                                                                                                                                                   |
| 569 |    946.580985 |     12.741779 | NA                                                                                                                                                                              |
| 570 |     16.808953 |    594.598468 | Chris huh                                                                                                                                                                       |
| 571 |    944.664370 |    536.647011 | Tauana J. Cunha                                                                                                                                                                 |
| 572 |    359.586858 |    765.744750 | Tyler Greenfield                                                                                                                                                                |
| 573 |    144.256192 |    596.213996 | Birgit Lang; based on a drawing by C.L. Koch                                                                                                                                    |
| 574 |    538.219614 |     43.608998 | Matt Crook                                                                                                                                                                      |
| 575 |    520.967348 |    188.885627 | Mathilde Cordellier                                                                                                                                                             |
| 576 |    812.777549 |    586.180929 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 577 |    694.222662 |    579.632426 | NA                                                                                                                                                                              |
| 578 |    981.215559 |    792.237935 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 579 |     52.203719 |    286.496129 | Chris Hay                                                                                                                                                                       |
| 580 |    677.922164 |     72.627880 | Dinah Challen                                                                                                                                                                   |
| 581 |    286.323730 |    698.381347 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 582 |    861.260488 |    500.709164 | Margot Michaud                                                                                                                                                                  |
| 583 |    404.342681 |     22.029787 | Adrian Reich                                                                                                                                                                    |
| 584 |    183.747587 |    519.767837 | Tasman Dixon                                                                                                                                                                    |
| 585 |    962.572671 |    587.568659 | Margot Michaud                                                                                                                                                                  |
| 586 |     17.293700 |    351.159117 | Matt Crook                                                                                                                                                                      |
| 587 |    622.696296 |     22.060983 | Collin Gross                                                                                                                                                                    |
| 588 |    354.466305 |    601.984108 | T. Michael Keesey                                                                                                                                                               |
| 589 |    561.475648 |    788.495365 | Beth Reinke                                                                                                                                                                     |
| 590 |    176.280272 |    125.163043 | Gareth Monger                                                                                                                                                                   |
| 591 |    874.864351 |    329.963375 | Dmitry Bogdanov                                                                                                                                                                 |
| 592 |    416.853412 |    729.129890 | T. Michael Keesey                                                                                                                                                               |
| 593 |    238.496632 |    498.401063 | Birgit Lang                                                                                                                                                                     |
| 594 |    479.668602 |    653.965802 | Sarah Werning                                                                                                                                                                   |
| 595 |    386.723598 |    275.566324 | Arthur Grosset (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                  |
| 596 |    242.638304 |     22.128806 | T. Michael Keesey                                                                                                                                                               |
| 597 |   1005.579797 |     15.610789 | Filip em                                                                                                                                                                        |
| 598 |    808.261723 |    409.955134 | Maija Karala                                                                                                                                                                    |
| 599 |   1017.468339 |    154.385227 | L. Shyamal                                                                                                                                                                      |
| 600 |    289.385471 |     41.067097 | Birgit Lang                                                                                                                                                                     |
| 601 |    829.960087 |     43.025270 | Filip em                                                                                                                                                                        |
| 602 |    402.882575 |    667.136420 | Tasman Dixon                                                                                                                                                                    |
| 603 |    866.701606 |    110.137108 | Steven Traver                                                                                                                                                                   |
| 604 |    337.284860 |    447.572536 | Ferran Sayol                                                                                                                                                                    |
| 605 |    523.491585 |    474.546830 | Zimices                                                                                                                                                                         |
| 606 |    561.843574 |      4.488003 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 607 |    964.317699 |    382.042593 | Iain Reid                                                                                                                                                                       |
| 608 |    397.395630 |    726.258273 | Matt Crook                                                                                                                                                                      |
| 609 |   1013.989175 |    427.806954 | Matt Crook                                                                                                                                                                      |
| 610 |     18.761188 |    200.220571 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                             |
| 611 |     78.382729 |    118.189352 | Conty (vectorized by T. Michael Keesey)                                                                                                                                         |
| 612 |    935.199445 |    293.638198 | Gareth Monger                                                                                                                                                                   |
| 613 |    165.389689 |    780.948960 | Jagged Fang Designs                                                                                                                                                             |
| 614 |    503.566474 |     12.274138 | Becky Barnes                                                                                                                                                                    |
| 615 |    965.995300 |    259.124544 | Margot Michaud                                                                                                                                                                  |
| 616 |    994.003596 |     69.180783 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                             |
| 617 |    715.269986 |    643.070448 | Margot Michaud                                                                                                                                                                  |
| 618 |   1016.828569 |    670.422526 | Lani Mohan                                                                                                                                                                      |
| 619 |    406.145547 |    344.568305 | Jay Matternes, vectorized by Zimices                                                                                                                                            |
| 620 |    957.618851 |    371.883321 | Matt Crook                                                                                                                                                                      |
| 621 |    769.819864 |    534.180166 | Neil Kelley                                                                                                                                                                     |
| 622 |    220.489865 |    532.270430 | Andrew A. Farke                                                                                                                                                                 |
| 623 |    626.911231 |     98.664204 | Margot Michaud                                                                                                                                                                  |
| 624 |    202.948617 |    748.266911 | Zimices                                                                                                                                                                         |
| 625 |    509.431092 |     65.150992 | Zimices                                                                                                                                                                         |
| 626 |     79.690909 |    795.509034 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                                               |
| 627 |    498.186131 |     52.089312 | Matt Crook                                                                                                                                                                      |
| 628 |    783.629727 |    198.783396 | Rachel Shoop                                                                                                                                                                    |
| 629 |    533.160419 |    235.231086 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                                 |
| 630 |    436.263253 |    368.007386 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                                               |
| 631 |    426.082574 |    717.197321 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 632 |    805.512573 |    254.945888 | Steven Traver                                                                                                                                                                   |
| 633 |    865.565495 |    731.108741 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 634 |     62.904745 |    786.943786 | Scott Hartman                                                                                                                                                                   |
| 635 |    652.980802 |    226.870629 | NA                                                                                                                                                                              |
| 636 |    801.244117 |    436.967257 | Scott Hartman                                                                                                                                                                   |
| 637 |    230.360148 |    461.406115 | Andreas Trepte (vectorized by T. Michael Keesey)                                                                                                                                |
| 638 |    637.052601 |    773.182251 | NA                                                                                                                                                                              |
| 639 |    456.935044 |    551.043029 | Matt Crook                                                                                                                                                                      |
| 640 |    717.842175 |    186.491679 | Mary Harrsch (modified by T. Michael Keesey)                                                                                                                                    |
| 641 |    792.429937 |    582.709891 | Birgit Lang                                                                                                                                                                     |
| 642 |    824.297479 |    475.042556 | Ferran Sayol                                                                                                                                                                    |
| 643 |    641.725456 |    708.159943 | Ferran Sayol                                                                                                                                                                    |
| 644 |    591.602988 |    709.346710 | NA                                                                                                                                                                              |
| 645 |    304.187369 |     47.835917 | Kai R. Caspar                                                                                                                                                                   |
| 646 |    227.547933 |    349.401021 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 647 |    431.684595 |    676.182103 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 648 |    709.361614 |    101.765596 | Crystal Maier                                                                                                                                                                   |
| 649 |    601.364591 |    526.130119 | Siobhon Egan                                                                                                                                                                    |
| 650 |    487.313832 |    439.654245 | Chloé Schmidt                                                                                                                                                                   |
| 651 |    287.618924 |    429.027625 | Steven Coombs                                                                                                                                                                   |
| 652 |    241.225727 |    757.629985 | Steven Traver                                                                                                                                                                   |
| 653 |    564.376936 |    717.946848 | T. Michael Keesey                                                                                                                                                               |
| 654 |    851.475594 |    250.718880 | Hans Hillewaert                                                                                                                                                                 |
| 655 |    809.469044 |    226.329361 | Matt Crook                                                                                                                                                                      |
| 656 |    100.944069 |    685.546107 | Armin Reindl                                                                                                                                                                    |
| 657 |    945.216996 |    361.820114 | T. Michael Keesey                                                                                                                                                               |
| 658 |    897.565072 |    190.538268 | Kai R. Caspar                                                                                                                                                                   |
| 659 |    952.346094 |    713.977683 | Scott Hartman                                                                                                                                                                   |
| 660 |    366.312545 |    775.344452 | Walter Vladimir                                                                                                                                                                 |
| 661 |    244.741478 |    791.476869 | Ville-Veikko Sinkkonen                                                                                                                                                          |
| 662 |    398.314401 |    387.288600 | Jagged Fang Designs                                                                                                                                                             |
| 663 |    117.160512 |    627.346237 | L. Shyamal                                                                                                                                                                      |
| 664 |    854.992746 |     51.167255 | C. Camilo Julián-Caballero                                                                                                                                                      |
| 665 |    323.042433 |    239.508225 | Gareth Monger                                                                                                                                                                   |
| 666 |    139.632960 |     20.198706 | T. Michael Keesey                                                                                                                                                               |
| 667 |    484.837186 |    739.132443 | Zimices                                                                                                                                                                         |
| 668 |    167.982440 |    375.414022 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                                                  |
| 669 |    285.287684 |    313.540352 | Gareth Monger                                                                                                                                                                   |
| 670 |    715.995161 |     61.994334 | Felix Vaux                                                                                                                                                                      |
| 671 |    520.494115 |    417.136425 | Mason McNair                                                                                                                                                                    |
| 672 |    440.551375 |    329.403682 | Zimices                                                                                                                                                                         |
| 673 |    522.526614 |    784.713183 | C. Camilo Julián-Caballero                                                                                                                                                      |
| 674 |    125.160133 |     16.273741 | NA                                                                                                                                                                              |
| 675 |    574.446893 |     72.922530 | Matt Crook                                                                                                                                                                      |
| 676 |    869.731390 |    138.953188 | Zimices                                                                                                                                                                         |
| 677 |    407.682188 |     83.854763 | Jessica Anne Miller                                                                                                                                                             |
| 678 |    671.527255 |    189.323448 | Alex Slavenko                                                                                                                                                                   |
| 679 |    820.263385 |    197.657239 | Emily Willoughby                                                                                                                                                                |
| 680 |    367.297111 |    587.729596 | NA                                                                                                                                                                              |
| 681 |    524.384986 |     49.926903 | Shyamal                                                                                                                                                                         |
| 682 |     50.083552 |    487.884293 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 683 |    190.794934 |    720.244639 | Prathyush Thomas                                                                                                                                                                |
| 684 |    866.298753 |     40.609657 | T. Michael Keesey                                                                                                                                                               |
| 685 |    866.244912 |    212.512920 | NA                                                                                                                                                                              |
| 686 |    906.430504 |    107.723284 | Jon Hill                                                                                                                                                                        |
| 687 |    369.815191 |    530.088236 | Margot Michaud                                                                                                                                                                  |
| 688 |    234.739189 |     72.496039 | Steven Traver                                                                                                                                                                   |
| 689 |    771.188619 |    261.099790 | Jagged Fang Designs                                                                                                                                                             |
| 690 |     81.097298 |     55.282340 | Birgit Lang                                                                                                                                                                     |
| 691 |    580.890144 |    761.090554 | Armin Reindl                                                                                                                                                                    |
| 692 |    243.641870 |    361.488477 | Tasman Dixon                                                                                                                                                                    |
| 693 |     83.548565 |    401.813178 | Cagri Cevrim                                                                                                                                                                    |
| 694 |    520.927484 |    714.696218 | Chris Jennings (Risiatto)                                                                                                                                                       |
| 695 |    235.048988 |     40.393248 | Tyler Greenfield                                                                                                                                                                |
| 696 |    995.615653 |    476.958631 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 697 |    605.614124 |    611.548444 | Paul O. Lewis                                                                                                                                                                   |
| 698 |    452.019320 |     68.558707 | Margot Michaud                                                                                                                                                                  |
| 699 |    877.332341 |    727.457472 | Jagged Fang Designs                                                                                                                                                             |
| 700 |    180.583829 |    748.831691 | John Conway                                                                                                                                                                     |
| 701 |    643.622806 |     64.735409 | Steven Traver                                                                                                                                                                   |
| 702 |    124.158672 |    227.024317 | Zimices                                                                                                                                                                         |
| 703 |    383.068411 |    241.702846 | Sam Droege (photography) and T. Michael Keesey (vectorization)                                                                                                                  |
| 704 |    502.841229 |    228.037973 | Roberto Díaz Sibaja                                                                                                                                                             |
| 705 |    363.234924 |    164.874802 | Harold N Eyster                                                                                                                                                                 |
| 706 |    689.235722 |    525.433316 | Michelle Site                                                                                                                                                                   |
| 707 |    913.295138 |    161.477943 | Becky Barnes                                                                                                                                                                    |
| 708 |    291.116536 |     12.765749 | Zimices                                                                                                                                                                         |
| 709 |     25.393463 |    143.997046 | T. Michael Keesey                                                                                                                                                               |
| 710 |    912.358452 |     35.482034 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 711 |    925.357488 |    725.076752 | NA                                                                                                                                                                              |
| 712 |    914.261750 |      7.308769 | I. Geoffroy Saint-Hilaire (vectorized by T. Michael Keesey)                                                                                                                     |
| 713 |    172.677082 |     94.392401 | Gareth Monger                                                                                                                                                                   |
| 714 |    692.087858 |    319.192427 | Jessica Anne Miller                                                                                                                                                             |
| 715 |    852.840991 |    468.708418 | Zimices                                                                                                                                                                         |
| 716 |    484.180397 |    787.432960 | Chris huh                                                                                                                                                                       |
| 717 |    352.873933 |    196.298760 | Ferran Sayol                                                                                                                                                                    |
| 718 |    318.206335 |     64.582207 | Gareth Monger                                                                                                                                                                   |
| 719 |    651.537469 |    182.207418 | Steven Traver                                                                                                                                                                   |
| 720 |    343.819591 |    178.766038 | T. Michael Keesey                                                                                                                                                               |
| 721 |    183.348590 |    580.180551 | Zimices                                                                                                                                                                         |
| 722 |    696.694810 |    404.659215 | Arthur S. Brum                                                                                                                                                                  |
| 723 |    558.744375 |    677.541476 | Maija Karala                                                                                                                                                                    |
| 724 |    208.417608 |    445.334709 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 725 |    849.897222 |     59.178856 | Lukasiniho                                                                                                                                                                      |
| 726 |    405.535018 |    714.431054 | Pete Buchholz                                                                                                                                                                   |
| 727 |    334.119793 |    671.841658 | Zimices                                                                                                                                                                         |
| 728 |   1001.763474 |    164.334202 | Christoph Schomburg                                                                                                                                                             |
| 729 |    174.663233 |    417.590512 | Lafage                                                                                                                                                                          |
| 730 |     40.642844 |    521.880966 | Scott Hartman                                                                                                                                                                   |
| 731 |    682.150256 |    168.586284 | Margot Michaud                                                                                                                                                                  |
| 732 |    645.144422 |    556.692037 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                                |
| 733 |    795.348036 |    212.433707 | Chris huh                                                                                                                                                                       |
| 734 |     10.186167 |    435.613798 | Matt Crook                                                                                                                                                                      |
| 735 |      7.120714 |    544.804116 | J. J. Harrison (photo) & T. Michael Keesey                                                                                                                                      |
| 736 |    901.253859 |    797.619965 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                           |
| 737 |    611.301286 |     85.385027 | Zimices                                                                                                                                                                         |
| 738 |     66.742096 |    587.880422 | Tasman Dixon                                                                                                                                                                    |
| 739 |    815.596313 |    309.425043 | Melissa Broussard                                                                                                                                                               |
| 740 |    520.509335 |    202.966932 | Andrew A. Farke                                                                                                                                                                 |
| 741 |    162.042885 |    304.952824 | Zimices                                                                                                                                                                         |
| 742 |    660.182573 |      5.863167 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 743 |    640.576093 |     52.564378 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 744 |    761.773297 |    618.049728 | Chase Brownstein                                                                                                                                                                |
| 745 |    411.093030 |    369.376644 | Zimices                                                                                                                                                                         |
| 746 |    511.441479 |    300.238685 | Jagged Fang Designs                                                                                                                                                             |
| 747 |    353.440357 |     80.791163 | Gareth Monger                                                                                                                                                                   |
| 748 |    108.839128 |    296.480625 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                                                   |
| 749 |     32.899664 |    333.821623 | Ferran Sayol                                                                                                                                                                    |
| 750 |    266.321059 |    676.584389 | Jimmy Bernot                                                                                                                                                                    |
| 751 |    838.027353 |    114.962375 | Matt Dempsey                                                                                                                                                                    |
| 752 |    362.988163 |    137.250787 | V. Deepak                                                                                                                                                                       |
| 753 |    584.764063 |    772.486355 | Zimices                                                                                                                                                                         |
| 754 |    278.451742 |     34.617961 | Caleb M. Brown                                                                                                                                                                  |
| 755 |    171.715282 |    326.914896 | Maxime Dahirel                                                                                                                                                                  |
| 756 |    511.827956 |    592.244833 | CNZdenek                                                                                                                                                                        |
| 757 |    802.699691 |    537.590454 | Margot Michaud                                                                                                                                                                  |
| 758 |    178.135133 |    139.725494 | Ferran Sayol                                                                                                                                                                    |
| 759 |     57.400256 |    604.494611 | Henry Lydecker                                                                                                                                                                  |
| 760 |    994.912356 |    177.615676 | Dinah Challen                                                                                                                                                                   |
| 761 |    254.097222 |    548.370354 | Shyamal                                                                                                                                                                         |
| 762 |    445.091353 |    116.357398 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 763 |    952.533876 |     25.246457 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 764 |    658.612042 |    217.304116 | Kamil S. Jaron                                                                                                                                                                  |
| 765 |    923.872392 |    285.409940 | Tauana J. Cunha                                                                                                                                                                 |
| 766 |    764.010857 |     40.866996 | T. Michael Keesey (after James & al.)                                                                                                                                           |
| 767 |    550.799831 |    161.279223 | Zimices                                                                                                                                                                         |
| 768 |    850.957127 |    626.411659 | Michael Scroggie                                                                                                                                                                |
| 769 |    356.162337 |    709.326213 | Matt Crook                                                                                                                                                                      |
| 770 |    171.491044 |    145.870543 | Chase Brownstein                                                                                                                                                                |
| 771 |    235.846935 |    750.950976 | Steven Traver                                                                                                                                                                   |
| 772 |    957.187795 |    683.008641 | Armin Reindl                                                                                                                                                                    |
| 773 |    509.410857 |    107.934601 | Ferran Sayol                                                                                                                                                                    |
| 774 |    404.390107 |    619.947013 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 775 |     46.839967 |    424.350052 | Doug Backlund (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                   |
| 776 |    872.861729 |    517.125148 | Ingo Braasch                                                                                                                                                                    |
| 777 |    991.201484 |    662.184952 | Todd Marshall, vectorized by Zimices                                                                                                                                            |
| 778 |    737.896920 |    613.098250 | Smokeybjb                                                                                                                                                                       |
| 779 |    159.650413 |    274.818227 | Ferran Sayol                                                                                                                                                                    |
| 780 |    360.001193 |    686.366576 | Zimices                                                                                                                                                                         |
| 781 |     17.369979 |    112.269651 | Steven Traver                                                                                                                                                                   |
| 782 |    913.263772 |    505.501570 | Ferran Sayol                                                                                                                                                                    |
| 783 |    211.914839 |    596.580953 | Gareth Monger                                                                                                                                                                   |
| 784 |    144.650925 |    440.640738 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                                |
| 785 |    778.088779 |    686.510983 | Jagged Fang Designs                                                                                                                                                             |
| 786 |    137.843602 |    371.516316 | Matt Crook                                                                                                                                                                      |
| 787 |    405.971464 |    737.201416 | V. Deepak                                                                                                                                                                       |
| 788 |    724.682060 |      8.119158 | Maky (vectorization), Gabriella Skollar (photography), Rebecca Lewis (editing)                                                                                                  |
| 789 |    105.186773 |    391.987749 | T. Michael Keesey and Tanetahi                                                                                                                                                  |
| 790 |    649.320044 |    164.955253 | Noah Schlottman, photo by Casey Dunn                                                                                                                                            |
| 791 |    834.435455 |    234.000304 | L. Shyamal                                                                                                                                                                      |
| 792 |    425.233789 |    394.800070 | NA                                                                                                                                                                              |
| 793 |    486.849826 |    101.860608 | Scott Hartman                                                                                                                                                                   |
| 794 |    291.586889 |    610.461375 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                                    |
| 795 |      8.180933 |    623.979425 | Raven Amos                                                                                                                                                                      |
| 796 |    721.767947 |    657.750085 | Sharon Wegner-Larsen                                                                                                                                                            |
| 797 |    513.215495 |    503.271288 | Katie S. Collins                                                                                                                                                                |
| 798 |     65.280878 |    145.956857 | Gareth Monger                                                                                                                                                                   |
| 799 |    319.310832 |    459.452752 | Steven Traver                                                                                                                                                                   |
| 800 |    295.850336 |    703.497366 | Steven Traver                                                                                                                                                                   |
| 801 |    879.201531 |    666.411521 | Sarah Werning                                                                                                                                                                   |
| 802 |    350.178839 |    455.280671 | Melissa Broussard                                                                                                                                                               |
| 803 |    733.793194 |    181.250123 | Jaime Headden                                                                                                                                                                   |
| 804 |    714.392921 |    611.499219 | Margot Michaud                                                                                                                                                                  |
| 805 |    932.742655 |    545.162443 | Emily Willoughby                                                                                                                                                                |
| 806 |    702.063115 |    739.690439 | Christopher Laumer (vectorized by T. Michael Keesey)                                                                                                                            |
| 807 |    764.561398 |    305.438773 | Yan Wong                                                                                                                                                                        |
| 808 |    815.842854 |    527.530843 | Gareth Monger                                                                                                                                                                   |
| 809 |    168.367131 |    668.825372 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 810 |    799.408245 |     61.090233 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 811 |    753.128403 |    609.576292 | Andrew A. Farke                                                                                                                                                                 |
| 812 |    183.888272 |    321.994565 | Michael Scroggie, from original photograph by John Bettaso, USFWS (original photograph in public domain).                                                                       |
| 813 |    449.739115 |    378.225898 | Manabu Bessho-Uehara                                                                                                                                                            |
| 814 |    304.778303 |     13.961149 | L. Shyamal                                                                                                                                                                      |
| 815 |   1009.540159 |    621.524575 | Liftarn                                                                                                                                                                         |
| 816 |    272.947529 |    795.015046 | Tracy A. Heath                                                                                                                                                                  |
| 817 |    467.817241 |    358.516766 | Liftarn                                                                                                                                                                         |
| 818 |    693.336006 |    201.376260 | Scott Hartman                                                                                                                                                                   |
| 819 |    749.859752 |    786.020844 | Zimices                                                                                                                                                                         |
| 820 |    994.379520 |     82.036436 | NA                                                                                                                                                                              |
| 821 |    937.475316 |    720.733743 | Gareth Monger                                                                                                                                                                   |
| 822 |    518.897412 |      6.208654 | Matt Crook                                                                                                                                                                      |
| 823 |    432.761664 |    148.480139 | Chloé Schmidt                                                                                                                                                                   |
| 824 |    702.937759 |    632.398594 | Matt Crook                                                                                                                                                                      |
| 825 |     27.809921 |    489.707412 | T. Michael Keesey                                                                                                                                                               |
| 826 |    684.740806 |    298.862983 | Ferran Sayol                                                                                                                                                                    |
| 827 |    698.688447 |    615.149441 | Birgit Lang                                                                                                                                                                     |
| 828 |    149.462077 |    756.682169 | Ferran Sayol                                                                                                                                                                    |
| 829 |    822.366843 |    466.778173 | B. Duygu Özpolat                                                                                                                                                                |
| 830 |    345.738309 |     19.527298 | Armin Reindl                                                                                                                                                                    |
| 831 |    699.391723 |    782.981340 | Scott Hartman (modified by T. Michael Keesey)                                                                                                                                   |
| 832 |    267.837412 |    618.375402 | Felix Vaux                                                                                                                                                                      |
| 833 |    439.892710 |    400.680709 | Tracy A. Heath                                                                                                                                                                  |
| 834 |    935.023574 |    138.021775 | Jagged Fang Designs                                                                                                                                                             |
| 835 |    946.597299 |    280.259002 | L. Shyamal                                                                                                                                                                      |
| 836 |    300.623246 |    461.557911 | Matt Crook                                                                                                                                                                      |
| 837 |    722.125275 |    445.150848 | Sergio A. Muñoz-Gómez                                                                                                                                                           |
| 838 |    309.813920 |    588.913297 | T. Michael Keesey                                                                                                                                                               |
| 839 |    769.859544 |    717.419953 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                               |
| 840 |    640.974786 |    790.005176 | Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org)                                                                                    |
| 841 |    382.987691 |    778.160408 | NA                                                                                                                                                                              |
| 842 |    887.693237 |    389.801999 | Sherman F. Denton via rawpixel.com (illustration) and Timothy J. Bartley (silhouette)                                                                                           |
| 843 |    495.432630 |     98.980055 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 844 |     64.876162 |    426.467782 | Maija Karala                                                                                                                                                                    |
| 845 |    899.117217 |    540.073740 | Joanna Wolfe                                                                                                                                                                    |
| 846 |    678.814121 |    399.532075 | Brian Swartz (vectorized by T. Michael Keesey)                                                                                                                                  |
| 847 |   1015.021445 |    652.373684 | Michele M Tobias                                                                                                                                                                |
| 848 |    287.015573 |    504.917222 | Tasman Dixon                                                                                                                                                                    |
| 849 |    758.488866 |    410.659962 | Beth Reinke                                                                                                                                                                     |
| 850 |    893.886088 |    604.151441 | Steven Traver                                                                                                                                                                   |
| 851 |    182.668332 |    110.329319 | Felix Vaux                                                                                                                                                                      |
| 852 |    737.642413 |    449.375048 | Jack Mayer Wood                                                                                                                                                                 |
| 853 |    128.369634 |    122.554637 | Dean Schnabel                                                                                                                                                                   |
| 854 |    921.597465 |    274.452906 | Scott Hartman                                                                                                                                                                   |
| 855 |    894.597988 |    525.277273 | Gareth Monger                                                                                                                                                                   |
| 856 |    144.561621 |    732.579653 | Mason McNair                                                                                                                                                                    |
| 857 |    157.284147 |    255.528352 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                                  |
| 858 |    837.816898 |    484.348808 | Zimices                                                                                                                                                                         |
| 859 |    738.878214 |    587.577441 | Ferran Sayol                                                                                                                                                                    |
| 860 |    948.390512 |    627.640210 | Manabu Bessho-Uehara                                                                                                                                                            |
| 861 |    773.359394 |    143.340000 | Zimices                                                                                                                                                                         |
| 862 |    547.957728 |    547.747127 | Chris huh                                                                                                                                                                       |
| 863 |    956.807680 |    790.706343 | Ingo Braasch                                                                                                                                                                    |
| 864 |    527.773099 |    761.178880 | Gareth Monger                                                                                                                                                                   |
| 865 |    137.736120 |     82.732198 | Jaime Headden                                                                                                                                                                   |
| 866 |    168.999956 |    589.703560 | Nobu Tamura, vectorized by Zimices                                                                                                                                              |
| 867 |    109.524685 |     13.375472 | Mary Harrsch (modified by T. Michael Keesey)                                                                                                                                    |
| 868 |    221.538399 |    517.440895 | Ferran Sayol                                                                                                                                                                    |
| 869 |    861.364606 |    179.356849 | Sharon Wegner-Larsen                                                                                                                                                            |
| 870 |    165.736308 |    236.088533 | Steven Traver                                                                                                                                                                   |
| 871 |     12.496238 |    583.872884 | Evan-Amos (vectorized by T. Michael Keesey)                                                                                                                                     |
| 872 |    967.694191 |    752.514763 | Francis de Laporte de Castelnau (vectorized by T. Michael Keesey)                                                                                                               |
| 873 |    773.675483 |    191.782522 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 874 |    786.934642 |    549.731051 | Sidney Frederic Harmer, Arthur Everett Shipley (vectorized by Maxime Dahirel)                                                                                                   |
| 875 |    973.672761 |    367.330650 | Zimices                                                                                                                                                                         |
| 876 |    920.017301 |    171.438141 | Zimices                                                                                                                                                                         |
| 877 |    444.225658 |    579.441990 | Margot Michaud                                                                                                                                                                  |
| 878 |    787.630979 |    757.315961 | Tim Bertelink (modified by T. Michael Keesey)                                                                                                                                   |
| 879 |     65.847475 |    542.689519 | Zimices                                                                                                                                                                         |
| 880 |    924.632937 |     14.701400 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 881 |    836.643335 |    648.832848 | Alexander Schmidt-Lebuhn                                                                                                                                                        |
| 882 |    371.234894 |    362.773537 | Gareth Monger                                                                                                                                                                   |
| 883 |     17.076168 |    600.669912 | Maxime Dahirel                                                                                                                                                                  |
| 884 |    914.093564 |    418.489378 | Juan Carlos Jerí                                                                                                                                                                |
| 885 |    192.409885 |    505.686483 | Roberto Díaz Sibaja                                                                                                                                                             |
| 886 |    666.035643 |    586.298112 | Zimices                                                                                                                                                                         |
| 887 |    409.987373 |    481.997708 | Geoff Shaw                                                                                                                                                                      |
| 888 |    734.716466 |    199.879292 | Scott Hartman                                                                                                                                                                   |
| 889 |    863.559583 |    624.403006 | Emily Jane McTavish                                                                                                                                                             |
| 890 |    392.535370 |    709.966383 | Renata F. Martins                                                                                                                                                               |
| 891 |    424.424379 |    336.255864 | Zimices                                                                                                                                                                         |
| 892 |    386.230375 |    168.038392 | T. Michael Keesey                                                                                                                                                               |
| 893 |    971.039503 |    683.692214 | Caleb M. Brown                                                                                                                                                                  |
| 894 |    729.152168 |    286.983678 | NASA                                                                                                                                                                            |
| 895 |    992.649844 |    451.166129 | Chris huh                                                                                                                                                                       |
| 896 |    439.016624 |    361.381601 | Iain Reid                                                                                                                                                                       |
| 897 |    274.997582 |    491.277661 | Mathew Wedel                                                                                                                                                                    |
| 898 |    320.076678 |    614.859568 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                                |
| 899 |    112.628205 |    789.389003 | Beth Reinke                                                                                                                                                                     |
| 900 |    129.557400 |    396.588160 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 901 |    988.566615 |    240.121274 | Michelle Site                                                                                                                                                                   |
| 902 |    433.548145 |    177.340901 | Matt Crook                                                                                                                                                                      |
| 903 |    371.326725 |    156.416130 | NA                                                                                                                                                                              |
| 904 |    504.960789 |    701.745982 | Steven Traver                                                                                                                                                                   |
| 905 |    330.344620 |    494.256364 | John Curtis (vectorized by T. Michael Keesey)                                                                                                                                   |
| 906 |    903.443178 |    296.796863 | Tasman Dixon                                                                                                                                                                    |
| 907 |    648.780842 |    141.177775 | Gareth Monger                                                                                                                                                                   |
| 908 |    694.549803 |    247.637534 | Matt Celeskey                                                                                                                                                                   |
| 909 |     93.184584 |    289.847543 | Philip Chalmers (vectorized by T. Michael Keesey)                                                                                                                               |
| 910 |    787.901613 |    602.899352 | Margot Michaud                                                                                                                                                                  |
| 911 |    668.310449 |    675.960188 | Jake Warner                                                                                                                                                                     |
| 912 |   1000.264267 |     61.641467 | Smokeybjb                                                                                                                                                                       |
| 913 |   1009.284215 |    501.287277 | Zimices                                                                                                                                                                         |
| 914 |    735.652493 |    141.344382 | Zimices                                                                                                                                                                         |
| 915 |    623.395481 |      7.564096 | Matt Crook                                                                                                                                                                      |
| 916 |    761.746950 |    181.965829 | Jakovche                                                                                                                                                                        |
| 917 |   1008.699667 |    195.866338 | Chris huh                                                                                                                                                                       |
| 918 |    979.020724 |     88.430709 | Prin Pattawaro (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                  |
| 919 |    186.580793 |    481.345987 | Matt Dempsey                                                                                                                                                                    |
| 920 |     15.694354 |    365.698615 | T. Michael Keesey                                                                                                                                                               |
| 921 |    698.258797 |    699.222771 | Matt Crook                                                                                                                                                                      |
| 922 |   1001.730912 |    143.141561 | Jagged Fang Designs                                                                                                                                                             |
| 923 |   1016.203268 |    392.184523 | Daniel Stadtmauer                                                                                                                                                               |
| 924 |    625.392336 |    769.100029 | Jagged Fang Designs                                                                                                                                                             |

    #> Your tweet has been posted!
