
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

Frank Förster (based on a picture by Jerry Kirkhart; modified by T.
Michael Keesey), Margot Michaud, Gabriela Palomo-Munoz, Scott Hartman,
modified by T. Michael Keesey, Matt Crook, T. Michael Keesey (photo by
Sean Mack), C. Camilo Julián-Caballero, Jaime Headden, Alexander
Schmidt-Lebuhn, Zimices, Pollyanna von Knorring and T. Michael Keesey,
Emily Jane McTavish, from
<http://en.wikipedia.org/wiki/File:Coccolithus_pelagicus.jpg>, Erika
Schumacher, Steven Traver, Cesar Julian, Tracy A. Heath, Dmitry Bogdanov
(vectorized by T. Michael Keesey), Jagged Fang Designs, Yan Wong, Birgit
Lang, Kanchi Nanjo, Dmitry Bogdanov, vectorized by Zimices, Chris huh,
Thibaut Brunet, Mattia Menchetti, Gareth Monger, Nobu Tamura (modified
by T. Michael Keesey), Andy Wilson, Sarah Werning, Hans Hillewaert
(vectorized by T. Michael Keesey), Obsidian Soul (vectorized by T.
Michael Keesey), T. Tischler, Steven Coombs, Michelle Site, Felix Vaux,
Mathilde Cordellier, Armin Reindl, Nobu Tamura (vectorized by T. Michael
Keesey), Falconaumanni and T. Michael Keesey, David Sim (photograph) and
T. Michael Keesey (vectorization), James I. Kirkland, Luis Alcalá, Mark
A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma
(vectorized by T. Michael Keesey), Markus A. Grohme, Steven Haddock
• Jellywatch.org, Christoph Schomburg, (unknown), DW Bapst (modified
from Bates et al., 2005), Tasman Dixon, E. D. Cope (modified by T.
Michael Keesey, Michael P. Taylor & Matthew J. Wedel), T. Michael
Keesey, Beth Reinke, Yan Wong from illustration by Charles Orbigny, Nobu
Tamura, vectorized by Zimices, Kanako Bessho-Uehara, L. Shyamal, Didier
Descouens (vectorized by T. Michael Keesey), Jim Bendon (photography)
and T. Michael Keesey (vectorization), Anthony Caravaggi, FunkMonk
\[Michael B.H.\] (modified by T. Michael Keesey), xgirouxb, Andrew A.
Farke, Joanna Wolfe, Michael P. Taylor, Ferran Sayol, Michael Scroggie,
Kai R. Caspar, Sean McCann, Terpsichores, Smokeybjb, Emily Willoughby,
Scott Hartman, Kamil S. Jaron, Rene Martin, Allison Pease, Nina Skinner,
Jerry Oldenettel (vectorized by T. Michael Keesey), Gordon E. Robertson,
Dean Schnabel, Inessa Voet, Ingo Braasch, Mali’o Kodis, image from the
Smithsonian Institution, Jake Warner, Todd Marshall, vectorized by
Zimices, Frank Förster (based on a picture by Hans Hillewaert), Mathieu
Pélissié, Mali’o Kodis, photograph by Hans Hillewaert, Robbie N. Cada
(modified by T. Michael Keesey), Oscar Sanisidro, Wynston Cooper (photo)
and Albertonykus (silhouette), Carlos Cano-Barbacil, Alexandra van der
Geer, Mette Aumala, Andreas Hejnol, Ignacio Contreras,
\<U+4E8E\>\<U+5DDD\>\<U+4E91\>, Matt Celeskey, Andreas Trepte
(vectorized by T. Michael Keesey), Jonathan Wells, Tyler Greenfield and
Dean Schnabel, Henry Lydecker, Mihai Dragos (vectorized by T. Michael
Keesey), Caleb M. Brown, Espen Horn (model; vectorized by T. Michael
Keesey from a photo by H. Zell), Tyler Greenfield and Scott Hartman,
Jack Mayer Wood, Noah Schlottman, photo by Casey Dunn, Mary Harrsch
(modified by T. Michael Keesey), Renato Santos, Harold N Eyster, Steven
Coombs (vectorized by T. Michael Keesey), Burton Robert, USFWS, Bennet
McComish, photo by Hans Hillewaert, Jose Carlos Arenas-Monroy, Sherman
F. Denton via rawpixel.com (illustration) and Timothy J. Bartley
(silhouette), E. R. Waite & H. M. Hale (vectorized by T. Michael
Keesey), Tim H. Heupink, Leon Huynen, and David M. Lambert (vectorized
by T. Michael Keesey), Robert Bruce Horsfall (vectorized by T. Michael
Keesey), Evan-Amos (vectorized by T. Michael Keesey), Michael Scroggie,
from original photograph by John Bettaso, USFWS (original photograph in
public domain)., Nobu Tamura (vectorized by A. Verrière), Alexandre
Vong, Taro Maeda, B Kimmel,
\<U+0412\>\<U+0430\>\<U+043B\>\<U+044C\>\<U+0434\>\<U+0438\>\<U+043C\>\<U+0430\>\<U+0440\>
(vectorized by T. Michael Keesey), Xavier Giroux-Bougard, Chloé Schmidt,
Iain Reid, Javiera Constanzo, Rebecca Groom, Ellen Edmonson and Hugh
Chrisp (illustration) and Timothy J. Bartley (silhouette), Mali’o Kodis,
image from Higgins and Kristensen, 1986, Shyamal, Darius Nau, Lindberg
(vectorized by T. Michael Keesey), Tom Tarrant (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Lauren Anderson,
annaleeblysse, Chris A. Hamilton, Sharon Wegner-Larsen, Pedro de
Siracusa, Juan Carlos Jerí, Ville-Veikko Sinkkonen, Darren Naish
(vectorize by T. Michael Keesey), TaraTaylorDesign, Mathieu Basille,
CNZdenek, Lily Hughes, FunkMonk, Sergio A. Muñoz-Gómez, Daniel
Stadtmauer, Matt Martyniuk, Neil Kelley, Noah Schlottman, photo from
Casey Dunn, Stemonitis (photography) and T. Michael Keesey
(vectorization), Mathew Stewart, Nicolas Mongiardino Koch, Maija Karala,
DW Bapst (Modified from Bulman, 1964), Javier Luque, Tauana J. Cunha,
Chase Brownstein, Florian Pfaff, Melissa Broussard, Francesco Veronesi
(vectorized by T. Michael Keesey), Bryan Carstens, Heinrich Harder
(vectorized by William Gearty), Emily Jane McTavish, from Haeckel, E. H.
P. A. (1904).Kunstformen der Natur. Bibliographisches, Enoch Joseph
Wetsy (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Nobu Tamura and T. Michael Keesey, Michael “FunkMonk” B. H.
(vectorized by T. Michael Keesey), Ian Burt (original) and T. Michael
Keesey (vectorization), Walter Vladimir, Abraão Leite, Matthew Hooge
(vectorized by T. Michael Keesey), Sibi (vectorized by T. Michael
Keesey), Diana Pomeroy, T. Michael Keesey, from a photograph by Thea
Boodhoo, Brad McFeeters (vectorized by T. Michael Keesey), George Edward
Lodge (modified by T. Michael Keesey), T. Michael Keesey (after Mivart),
Natasha Vitek, Jan A. Venter, Herbert H. T. Prins, David A. Balfour &
Rob Slotow (vectorized by T. Michael Keesey), Matt Dempsey, Matus
Valach, James R. Spotila and Ray Chatterji, Aviceda (vectorized by T.
Michael Keesey), Unknown (photo), John E. McCormack, Michael G. Harvey,
Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T.
Brumfield & T. Michael Keesey, T. Michael Keesey (vectorization); Yves
Bousquet (photography), V. Deepak, Lukas Panzarin, Mali’o Kodis,
photograph by G. Giribet, Craig Dylke, Mo Hassan, Archaeodontosaurus
(vectorized by T. Michael Keesey), Lukasiniho, Becky Barnes, Ludwik
Gasiorowski, Ernst Haeckel (vectorized by T. Michael Keesey), Lisa
Byrne, Tyler Greenfield, André Karwath (vectorized by T. Michael
Keesey), Scott Reid, Mike Hanson, Robert Bruce Horsfall, vectorized by
Zimices, T. Michael Keesey (after Mauricio Antón), Kailah Thorn & Mark
Hutchinson, Mali’o Kodis, photograph by Jim Vargo, Marie Russell, B.
Duygu Özpolat, Stanton F. Fink (vectorized by T. Michael Keesey), DW
Bapst, modified from Figure 1 of Belanger (2011, PALAIOS)., Collin
Gross, T. Michael Keesey (after MPF), T. Michael Keesey (vectorization);
Thorsten Assmann, Jörn Buse, Claudia Drees, Ariel-Leib-Leonid Friedman,
Tal Levanony, Andrea Matern, Anika Timm, and David W. Wrase
(photography), T. Michael Keesey (after Kukalová), Scott D. Sampson,
Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster,
Joshua A. Smith, Alan L. Titus, Tony Ayling (vectorized by Milton Tan),
Robert Bruce Horsfall (vectorized by William Gearty), Apokryltaros
(vectorized by T. Michael Keesey), Geoff Shaw, Michael Scroggie, from
original photograph by Gary M. Stolz, USFWS (original photograph in
public domain)., Mark Witton, Maha Ghazal, Andrés Sánchez, Caroline
Harding, MAF (vectorized by T. Michael Keesey), Mali’o Kodis, image from
the Biodiversity Heritage Library, David Liao, Roberto Díaz Sibaja, Mr
E? (vectorized by T. Michael Keesey), Conty (vectorized by T. Michael
Keesey), Andrew Farke and Joseph Sertich, Christine Axon, Ray Simpson
(vectorized by T. Michael Keesey), Agnello Picorelli, Maxime Dahirel,
Karkemish (vectorized by T. Michael Keesey), Dmitry Bogdanov and
FunkMonk (vectorized by T. Michael Keesey), Christopher Laumer
(vectorized by T. Michael Keesey), Mali’o Kodis, photograph from
<http://commons.wikimedia.org/wiki/File:Trichoplax.jpg>, Ghedo and T.
Michael Keesey, Jonathan Lawley, Raven Amos, Crystal Maier, Thea Boodhoo
(photograph) and T. Michael Keesey (vectorization), \[unknown\], Emma
Hughes, Jaime Headden, modified by T. Michael Keesey, AnAgnosticGod
(vectorized by T. Michael Keesey), Bill Bouton (source photo) & T.
Michael Keesey (vectorization), Pete Buchholz, Qiang Ou, Philip Chalmers
(vectorized by T. Michael Keesey), Milton Tan, Gopal Murali, Rachel
Shoop, Meyer-Wachsmuth I, Curini Galletti M, Jondelius U
(<doi:10.1371/journal.pone.0107688>). Vectorization by Y. Wong, Trond R.
Oskars, David Orr, Noah Schlottman, photo by Museum of Geology,
University of Tartu, H. F. O. March (vectorized by T. Michael Keesey),
Hans Hillewaert, John Conway, Michael Day, Notafly (vectorized by T.
Michael Keesey), Konsta Happonen, Michele M Tobias, Katie S. Collins,
Dmitry Bogdanov, FJDegrange, Eyal Bartov, Mathew Wedel, Eduard Solà
Vázquez, vectorised by Yan Wong, Darren Naish (vectorized by T. Michael
Keesey), \<U+0414\>\<U+0438\>\<U+0411\>\<U+0433\>\<U+0434\> (vectorized
by T. Michael Keesey), Mali’o Kodis, image from Brockhaus and Efron
Encyclopedic Dictionary, Michael B. H. (vectorized by T. Michael
Keesey), Gustav Mützel, SauropodomorphMonarch, Original drawing by
Antonov, vectorized by Roberto Díaz Sibaja, Campbell Fleming, Noah
Schlottman, photo by Martin V. Sørensen, Brian Swartz (vectorized by T.
Michael Keesey), Skye M, Chris Hay

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                               |
| --: | ------------: | ------------: | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    807.100527 |    155.176115 | Frank Förster (based on a picture by Jerry Kirkhart; modified by T. Michael Keesey)                                                                                                  |
|   2 |    920.670360 |    244.357555 | Margot Michaud                                                                                                                                                                       |
|   3 |    409.438722 |    252.324433 | Gabriela Palomo-Munoz                                                                                                                                                                |
|   4 |    877.377413 |    372.040596 | Scott Hartman, modified by T. Michael Keesey                                                                                                                                         |
|   5 |    706.862116 |    595.711357 | Matt Crook                                                                                                                                                                           |
|   6 |    138.459002 |    116.697653 | T. Michael Keesey (photo by Sean Mack)                                                                                                                                               |
|   7 |    531.531308 |    140.896746 | C. Camilo Julián-Caballero                                                                                                                                                           |
|   8 |    290.203154 |    391.654248 | Jaime Headden                                                                                                                                                                        |
|   9 |    323.652955 |    618.509884 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
|  10 |    926.833455 |    609.891725 | Zimices                                                                                                                                                                              |
|  11 |    103.794303 |    327.383036 | NA                                                                                                                                                                                   |
|  12 |     71.706374 |    737.132104 | Pollyanna von Knorring and T. Michael Keesey                                                                                                                                         |
|  13 |    704.577335 |    413.323274 | Emily Jane McTavish, from <http://en.wikipedia.org/wiki/File:Coccolithus_pelagicus.jpg>                                                                                              |
|  14 |    485.920529 |     97.205215 | Erika Schumacher                                                                                                                                                                     |
|  15 |    640.041604 |     99.745017 | Steven Traver                                                                                                                                                                        |
|  16 |    224.635221 |    468.655181 | Zimices                                                                                                                                                                              |
|  17 |    105.155787 |    233.415259 | Margot Michaud                                                                                                                                                                       |
|  18 |    256.938257 |    223.661575 | Cesar Julian                                                                                                                                                                         |
|  19 |    254.981814 |    114.693481 | Tracy A. Heath                                                                                                                                                                       |
|  20 |    489.635920 |    621.643727 | NA                                                                                                                                                                                   |
|  21 |    549.072719 |    448.391046 | Margot Michaud                                                                                                                                                                       |
|  22 |    101.468809 |    386.405125 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
|  23 |    757.667438 |    757.858474 | Zimices                                                                                                                                                                              |
|  24 |    364.156305 |    530.274602 | Jagged Fang Designs                                                                                                                                                                  |
|  25 |    572.163535 |    249.217432 | Yan Wong                                                                                                                                                                             |
|  26 |    562.463114 |     33.508993 | Birgit Lang                                                                                                                                                                          |
|  27 |    135.053216 |    616.233939 | Kanchi Nanjo                                                                                                                                                                         |
|  28 |    675.877111 |    180.353541 | NA                                                                                                                                                                                   |
|  29 |    570.646295 |    692.760336 | NA                                                                                                                                                                                   |
|  30 |    955.304632 |    460.602350 | Dmitry Bogdanov, vectorized by Zimices                                                                                                                                               |
|  31 |    237.192291 |    732.016685 | NA                                                                                                                                                                                   |
|  32 |    759.527586 |    301.578591 | Chris huh                                                                                                                                                                            |
|  33 |    103.157670 |    478.413629 | Thibaut Brunet                                                                                                                                                                       |
|  34 |    804.528738 |    700.548831 | Mattia Menchetti                                                                                                                                                                     |
|  35 |    294.370106 |    295.010445 | Gareth Monger                                                                                                                                                                        |
|  36 |    343.811869 |     34.169127 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                                          |
|  37 |    928.038226 |    354.543402 | C. Camilo Julián-Caballero                                                                                                                                                           |
|  38 |    840.442130 |    528.714526 | Andy Wilson                                                                                                                                                                          |
|  39 |    904.178428 |     55.452365 | Sarah Werning                                                                                                                                                                        |
|  40 |    404.420322 |    735.070201 | Matt Crook                                                                                                                                                                           |
|  41 |    375.860105 |    445.750186 | Margot Michaud                                                                                                                                                                       |
|  42 |    446.376253 |    398.486533 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                                    |
|  43 |    566.980919 |    366.845618 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                                      |
|  44 |    929.969292 |    715.553918 | Steven Traver                                                                                                                                                                        |
|  45 |    728.504121 |    234.393704 | T. Tischler                                                                                                                                                                          |
|  46 |    933.369084 |    117.028973 | NA                                                                                                                                                                                   |
|  47 |    527.576915 |    541.378662 | Steven Coombs                                                                                                                                                                        |
|  48 |    641.353085 |    751.962343 | Michelle Site                                                                                                                                                                        |
|  49 |    748.795872 |    328.156854 | Felix Vaux                                                                                                                                                                           |
|  50 |     31.522423 |    627.336628 | Mathilde Cordellier                                                                                                                                                                  |
|  51 |     36.438472 |    144.856883 | Armin Reindl                                                                                                                                                                         |
|  52 |    961.123329 |     17.306570 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
|  53 |     96.090585 |    282.473081 | Chris huh                                                                                                                                                                            |
|  54 |    388.837544 |     88.507038 | Falconaumanni and T. Michael Keesey                                                                                                                                                  |
|  55 |    934.125504 |    527.636740 | David Sim (photograph) and T. Michael Keesey (vectorization)                                                                                                                         |
|  56 |    755.798932 |     62.994383 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
|  57 |    632.165518 |    273.566416 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                                 |
|  58 |    478.283891 |    732.134807 | Matt Crook                                                                                                                                                                           |
|  59 |    536.593085 |    315.959588 | Chris huh                                                                                                                                                                            |
|  60 |    868.728537 |    652.452682 | Markus A. Grohme                                                                                                                                                                     |
|  61 |    363.835827 |    686.149693 | Steven Haddock • Jellywatch.org                                                                                                                                                      |
|  62 |    768.662366 |     98.916228 | Christoph Schomburg                                                                                                                                                                  |
|  63 |    937.872817 |    181.220727 | Steven Traver                                                                                                                                                                        |
|  64 |    882.663830 |    762.832176 | Chris huh                                                                                                                                                                            |
|  65 |    257.974532 |    664.072299 | Jagged Fang Designs                                                                                                                                                                  |
|  66 |     72.856449 |     64.555027 | (unknown)                                                                                                                                                                            |
|  67 |    139.002349 |    428.700143 | Zimices                                                                                                                                                                              |
|  68 |    112.003586 |     25.092346 | Steven Coombs                                                                                                                                                                        |
|  69 |    624.707743 |    453.089902 | DW Bapst (modified from Bates et al., 2005)                                                                                                                                          |
|  70 |    847.450623 |    418.408849 | Tasman Dixon                                                                                                                                                                         |
|  71 |    138.785248 |    213.767105 | C. Camilo Julián-Caballero                                                                                                                                                           |
|  72 |    137.969863 |    758.659832 | Chris huh                                                                                                                                                                            |
|  73 |    708.266027 |     30.258761 | Sarah Werning                                                                                                                                                                        |
|  74 |    931.992240 |    557.332718 | E. D. Cope (modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel)                                                                                                     |
|  75 |    517.634279 |    183.964645 | Markus A. Grohme                                                                                                                                                                     |
|  76 |    291.463720 |    763.384739 | Chris huh                                                                                                                                                                            |
|  77 |    505.426997 |    783.247441 | T. Michael Keesey                                                                                                                                                                    |
|  78 |    612.956795 |    562.263886 | Gabriela Palomo-Munoz                                                                                                                                                                |
|  79 |    510.478673 |    741.761750 | NA                                                                                                                                                                                   |
|  80 |    222.553585 |    547.495856 | Mattia Menchetti                                                                                                                                                                     |
|  81 |    748.671289 |      8.619034 | Beth Reinke                                                                                                                                                                          |
|  82 |    872.776256 |    686.463324 | NA                                                                                                                                                                                   |
|  83 |     34.120402 |    481.320282 | Yan Wong from illustration by Charles Orbigny                                                                                                                                        |
|  84 |    984.981138 |     63.845591 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
|  85 |     27.139434 |    453.246679 | Kanako Bessho-Uehara                                                                                                                                                                 |
|  86 |     18.853780 |    306.659515 | L. Shyamal                                                                                                                                                                           |
|  87 |    234.019141 |    635.227039 | Birgit Lang                                                                                                                                                                          |
|  88 |    603.777278 |    626.330274 | Zimices                                                                                                                                                                              |
|  89 |    797.146559 |    267.529963 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                                   |
|  90 |    591.636032 |    769.313795 | Tasman Dixon                                                                                                                                                                         |
|  91 |     68.442175 |    260.857457 | Andy Wilson                                                                                                                                                                          |
|  92 |    641.136940 |    374.351191 | Felix Vaux                                                                                                                                                                           |
|  93 |    589.500185 |    589.068054 | Jim Bendon (photography) and T. Michael Keesey (vectorization)                                                                                                                       |
|  94 |    455.481822 |    473.499960 | Anthony Caravaggi                                                                                                                                                                    |
|  95 |    382.848502 |    199.980798 | FunkMonk \[Michael B.H.\] (modified by T. Michael Keesey)                                                                                                                            |
|  96 |    438.662660 |    147.940439 | xgirouxb                                                                                                                                                                             |
|  97 |    669.718938 |    284.813111 | Jagged Fang Designs                                                                                                                                                                  |
|  98 |    301.131646 |    470.002584 | Andy Wilson                                                                                                                                                                          |
|  99 |    975.544469 |    683.232034 | Matt Crook                                                                                                                                                                           |
| 100 |    719.791791 |    146.074905 | Gareth Monger                                                                                                                                                                        |
| 101 |    107.180348 |    189.082716 | Andrew A. Farke                                                                                                                                                                      |
| 102 |    453.785006 |    503.203730 | Joanna Wolfe                                                                                                                                                                         |
| 103 |    795.981335 |    669.691015 | T. Michael Keesey                                                                                                                                                                    |
| 104 |    199.569737 |    385.621408 | Yan Wong                                                                                                                                                                             |
| 105 |    810.475176 |    369.297210 | Michael P. Taylor                                                                                                                                                                    |
| 106 |     47.083147 |    248.090951 | Ferran Sayol                                                                                                                                                                         |
| 107 |    775.308114 |    375.071318 | Gareth Monger                                                                                                                                                                        |
| 108 |    276.420002 |    181.276493 | Michael Scroggie                                                                                                                                                                     |
| 109 |    984.089687 |    581.887657 | Steven Coombs                                                                                                                                                                        |
| 110 |    517.742146 |    209.772294 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 111 |    828.600817 |    338.013515 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 112 |    417.628205 |    672.203817 | Kai R. Caspar                                                                                                                                                                        |
| 113 |     24.389669 |    528.102724 | Gareth Monger                                                                                                                                                                        |
| 114 |    261.677889 |    540.691984 | Sean McCann                                                                                                                                                                          |
| 115 |    131.338188 |    194.857761 | Steven Traver                                                                                                                                                                        |
| 116 |    222.737681 |    298.402126 | Terpsichores                                                                                                                                                                         |
| 117 |    978.184795 |    565.656468 | Smokeybjb                                                                                                                                                                            |
| 118 |    425.483856 |    633.877677 | Matt Crook                                                                                                                                                                           |
| 119 |   1011.563482 |    228.078735 | NA                                                                                                                                                                                   |
| 120 |     22.167873 |    277.983700 | Emily Willoughby                                                                                                                                                                     |
| 121 |    274.895292 |    790.457728 | Scott Hartman                                                                                                                                                                        |
| 122 |    528.996763 |    781.565958 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 123 |    897.495860 |    497.693500 | Kamil S. Jaron                                                                                                                                                                       |
| 124 |    664.232558 |    510.293781 | Rene Martin                                                                                                                                                                          |
| 125 |    212.499389 |    585.821961 | Matt Crook                                                                                                                                                                           |
| 126 |     73.686196 |    188.999399 | Margot Michaud                                                                                                                                                                       |
| 127 |    771.239737 |    498.697432 | Matt Crook                                                                                                                                                                           |
| 128 |    666.771406 |    479.299649 | Jagged Fang Designs                                                                                                                                                                  |
| 129 |    503.579913 |    433.693561 | T. Michael Keesey                                                                                                                                                                    |
| 130 |    360.696664 |    267.525603 | Andy Wilson                                                                                                                                                                          |
| 131 |    947.750484 |    207.284167 | Gareth Monger                                                                                                                                                                        |
| 132 |    859.469425 |    786.441724 | Allison Pease                                                                                                                                                                        |
| 133 |     62.130494 |    559.603781 | Andy Wilson                                                                                                                                                                          |
| 134 |    174.850741 |    790.668136 | Margot Michaud                                                                                                                                                                       |
| 135 |    161.868938 |    265.506238 | Nina Skinner                                                                                                                                                                         |
| 136 |     65.602445 |    241.824389 | Margot Michaud                                                                                                                                                                       |
| 137 |      8.705839 |    168.303144 | Jerry Oldenettel (vectorized by T. Michael Keesey)                                                                                                                                   |
| 138 |    809.249599 |    210.981137 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 139 |    229.856451 |    197.917299 | Zimices                                                                                                                                                                              |
| 140 |    825.207303 |    295.171996 | Scott Hartman                                                                                                                                                                        |
| 141 |    405.611887 |    326.375123 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 142 |    843.375525 |     69.589733 | Gordon E. Robertson                                                                                                                                                                  |
| 143 |    763.874615 |    470.263044 | Dean Schnabel                                                                                                                                                                        |
| 144 |    221.770545 |    362.856407 | Scott Hartman                                                                                                                                                                        |
| 145 |    852.201998 |    574.004729 | Inessa Voet                                                                                                                                                                          |
| 146 |    880.548608 |    578.926828 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 147 |     45.683968 |     42.863211 | Margot Michaud                                                                                                                                                                       |
| 148 |    689.979979 |    301.306832 | Ingo Braasch                                                                                                                                                                         |
| 149 |    421.823698 |    109.040995 | Mali’o Kodis, image from the Smithsonian Institution                                                                                                                                 |
| 150 |    554.461557 |     68.089747 | Steven Coombs                                                                                                                                                                        |
| 151 |    561.789525 |    504.244145 | Matt Crook                                                                                                                                                                           |
| 152 |    668.727560 |    364.290017 | Steven Traver                                                                                                                                                                        |
| 153 |   1006.538119 |    783.356272 | Matt Crook                                                                                                                                                                           |
| 154 |    790.076055 |    646.866425 | Jake Warner                                                                                                                                                                          |
| 155 |    266.995622 |    200.376760 | Steven Traver                                                                                                                                                                        |
| 156 |    237.476108 |    583.208334 | Margot Michaud                                                                                                                                                                       |
| 157 |    162.381717 |    360.544445 | Gareth Monger                                                                                                                                                                        |
| 158 |    869.336247 |    635.960609 | Andrew A. Farke                                                                                                                                                                      |
| 159 |    327.997945 |    685.095480 | Matt Crook                                                                                                                                                                           |
| 160 |    247.190694 |    389.386011 | Todd Marshall, vectorized by Zimices                                                                                                                                                 |
| 161 |    986.362633 |    663.950253 | Frank Förster (based on a picture by Hans Hillewaert)                                                                                                                                |
| 162 |    820.037382 |    340.113432 | Kai R. Caspar                                                                                                                                                                        |
| 163 |      8.432631 |    423.603274 | Zimices                                                                                                                                                                              |
| 164 |    677.244720 |    498.786705 | Mathieu Pélissié                                                                                                                                                                     |
| 165 |    813.814050 |    416.092077 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 166 |    188.023610 |    230.531408 | Mali’o Kodis, photograph by Hans Hillewaert                                                                                                                                          |
| 167 |    217.005786 |    324.115269 | Ingo Braasch                                                                                                                                                                         |
| 168 |   1007.375669 |    126.198659 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                                          |
| 169 |     18.095502 |    131.334831 | Mathieu Pélissié                                                                                                                                                                     |
| 170 |     21.080680 |    369.345992 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                                                       |
| 171 |     37.301032 |    696.016671 | Oscar Sanisidro                                                                                                                                                                      |
| 172 |    256.365222 |    453.156751 | Wynston Cooper (photo) and Albertonykus (silhouette)                                                                                                                                 |
| 173 |    632.005273 |    366.038324 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 174 |    130.249626 |    466.615481 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 175 |     12.570891 |    509.075271 | Chris huh                                                                                                                                                                            |
| 176 |    841.460557 |    785.086495 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 177 |    979.603349 |    700.497922 | NA                                                                                                                                                                                   |
| 178 |   1011.985177 |    636.749529 | Tasman Dixon                                                                                                                                                                         |
| 179 |    858.147670 |    319.572781 | Kamil S. Jaron                                                                                                                                                                       |
| 180 |    445.301349 |    730.578983 | Michael Scroggie                                                                                                                                                                     |
| 181 |     96.381406 |    796.415543 | Alexandra van der Geer                                                                                                                                                               |
| 182 |    473.455153 |     57.572528 | Mette Aumala                                                                                                                                                                         |
| 183 |    894.028925 |    428.874939 | Matt Crook                                                                                                                                                                           |
| 184 |    639.487929 |    169.801860 | Steven Traver                                                                                                                                                                        |
| 185 |    223.488206 |     20.989082 | Steven Traver                                                                                                                                                                        |
| 186 |    903.009505 |     35.325688 | Scott Hartman                                                                                                                                                                        |
| 187 |    394.208846 |    710.625431 | L. Shyamal                                                                                                                                                                           |
| 188 |    972.308905 |    280.419874 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 189 |    107.077987 |    496.002467 | Andreas Hejnol                                                                                                                                                                       |
| 190 |    662.583954 |    705.348553 | Ignacio Contreras                                                                                                                                                                    |
| 191 |    732.375202 |     85.187193 | Matt Crook                                                                                                                                                                           |
| 192 |    290.641513 |    418.649008 | \<U+4E8E\>\<U+5DDD\>\<U+4E91\>                                                                                                                                                       |
| 193 |    386.894753 |    153.810616 | Matt Crook                                                                                                                                                                           |
| 194 |     28.968281 |    214.996746 | Michelle Site                                                                                                                                                                        |
| 195 |    646.884626 |    722.361733 | Chris huh                                                                                                                                                                            |
| 196 |    899.270838 |     47.199024 | T. Michael Keesey                                                                                                                                                                    |
| 197 |    428.401801 |     34.327607 | Sean McCann                                                                                                                                                                          |
| 198 |    114.474832 |    510.586038 | Tracy A. Heath                                                                                                                                                                       |
| 199 |    982.951325 |    640.637509 | Ingo Braasch                                                                                                                                                                         |
| 200 |    844.056295 |    390.894502 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 201 |    886.477884 |    480.186741 | Gareth Monger                                                                                                                                                                        |
| 202 |    947.417193 |    648.561862 | Matt Celeskey                                                                                                                                                                        |
| 203 |    886.931335 |     18.787430 | NA                                                                                                                                                                                   |
| 204 |    513.204984 |      4.212360 | Scott Hartman                                                                                                                                                                        |
| 205 |    553.479294 |    654.187965 | Matt Crook                                                                                                                                                                           |
| 206 |    350.892469 |    274.812060 | Andreas Trepte (vectorized by T. Michael Keesey)                                                                                                                                     |
| 207 |    822.506695 |    271.962351 | Jonathan Wells                                                                                                                                                                       |
| 208 |    419.675170 |    488.990408 | Jake Warner                                                                                                                                                                          |
| 209 |    147.204711 |    356.982752 | Tyler Greenfield and Dean Schnabel                                                                                                                                                   |
| 210 |    398.674247 |    140.154571 | Zimices                                                                                                                                                                              |
| 211 |    380.859958 |    207.251517 | Jagged Fang Designs                                                                                                                                                                  |
| 212 |   1009.007871 |    742.261081 | Henry Lydecker                                                                                                                                                                       |
| 213 |    644.334017 |     51.463206 | Dean Schnabel                                                                                                                                                                        |
| 214 |    909.778457 |    299.865831 | Mihai Dragos (vectorized by T. Michael Keesey)                                                                                                                                       |
| 215 |     28.802820 |    387.397864 | Mathieu Pélissié                                                                                                                                                                     |
| 216 |    223.918055 |    261.124568 | T. Michael Keesey                                                                                                                                                                    |
| 217 |    870.678846 |    672.736543 | Caleb M. Brown                                                                                                                                                                       |
| 218 |    330.503997 |    198.675696 | Ferran Sayol                                                                                                                                                                         |
| 219 |    223.375128 |    601.893043 | Scott Hartman                                                                                                                                                                        |
| 220 |    373.067878 |    347.627402 | Espen Horn (model; vectorized by T. Michael Keesey from a photo by H. Zell)                                                                                                          |
| 221 |    995.534826 |    515.867198 | NA                                                                                                                                                                                   |
| 222 |    307.288504 |    501.201691 | Tyler Greenfield and Scott Hartman                                                                                                                                                   |
| 223 |    866.066645 |    596.396763 | Margot Michaud                                                                                                                                                                       |
| 224 |    950.623831 |    670.126591 | Steven Traver                                                                                                                                                                        |
| 225 |    195.424355 |    507.606906 | L. Shyamal                                                                                                                                                                           |
| 226 |    886.555669 |    120.603836 | T. Michael Keesey                                                                                                                                                                    |
| 227 |    489.071307 |     31.143407 | Smokeybjb                                                                                                                                                                            |
| 228 |   1015.497343 |    102.878123 | Gareth Monger                                                                                                                                                                        |
| 229 |    544.864837 |    639.491255 | Ferran Sayol                                                                                                                                                                         |
| 230 |    187.682624 |     19.755991 | Jack Mayer Wood                                                                                                                                                                      |
| 231 |    180.116223 |    718.311699 | Matt Crook                                                                                                                                                                           |
| 232 |     31.140730 |    708.370949 | Noah Schlottman, photo by Casey Dunn                                                                                                                                                 |
| 233 |     11.530170 |     90.967953 | Mary Harrsch (modified by T. Michael Keesey)                                                                                                                                         |
| 234 |    923.338763 |    467.159866 | NA                                                                                                                                                                                   |
| 235 |    324.412383 |    444.293718 | Jim Bendon (photography) and T. Michael Keesey (vectorization)                                                                                                                       |
| 236 |    366.172706 |    311.185959 | Margot Michaud                                                                                                                                                                       |
| 237 |    232.269922 |    729.293108 | Margot Michaud                                                                                                                                                                       |
| 238 |    667.757379 |    725.551976 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 239 |    118.661831 |    488.236518 | Zimices                                                                                                                                                                              |
| 240 |    818.130943 |    794.748791 | Jaime Headden                                                                                                                                                                        |
| 241 |    213.950443 |    268.107851 | Margot Michaud                                                                                                                                                                       |
| 242 |    304.351243 |    557.035295 | Renato Santos                                                                                                                                                                        |
| 243 |    803.979279 |    706.240301 | Markus A. Grohme                                                                                                                                                                     |
| 244 |    354.688651 |    423.150466 | Margot Michaud                                                                                                                                                                       |
| 245 |    167.188461 |    375.444992 | Zimices                                                                                                                                                                              |
| 246 |     47.991391 |    417.624747 | Harold N Eyster                                                                                                                                                                      |
| 247 |    359.554827 |    192.047559 | Espen Horn (model; vectorized by T. Michael Keesey from a photo by H. Zell)                                                                                                          |
| 248 |     15.900636 |    350.679718 | Andy Wilson                                                                                                                                                                          |
| 249 |    416.100042 |    542.296129 | Jagged Fang Designs                                                                                                                                                                  |
| 250 |    360.739512 |    130.374481 | xgirouxb                                                                                                                                                                             |
| 251 |    417.540895 |    774.427809 | Scott Hartman                                                                                                                                                                        |
| 252 |    123.433552 |    720.928760 | Christoph Schomburg                                                                                                                                                                  |
| 253 |    848.269834 |    458.955089 | Steven Coombs (vectorized by T. Michael Keesey)                                                                                                                                      |
| 254 |     21.439718 |    688.053082 | Burton Robert, USFWS                                                                                                                                                                 |
| 255 |    207.878222 |    250.703114 | Mathieu Pélissié                                                                                                                                                                     |
| 256 |    181.743124 |    366.867845 | Bennet McComish, photo by Hans Hillewaert                                                                                                                                            |
| 257 |    176.771564 |    482.365272 | Jose Carlos Arenas-Monroy                                                                                                                                                            |
| 258 |    265.937878 |     50.495424 | Sherman F. Denton via rawpixel.com (illustration) and Timothy J. Bartley (silhouette)                                                                                                |
| 259 |     31.348370 |    503.061292 | Andrew A. Farke                                                                                                                                                                      |
| 260 |    435.520258 |    509.020177 | Michael Scroggie                                                                                                                                                                     |
| 261 |    648.726247 |    293.106159 | E. R. Waite & H. M. Hale (vectorized by T. Michael Keesey)                                                                                                                           |
| 262 |   1004.185859 |    331.852535 | Matt Crook                                                                                                                                                                           |
| 263 |    907.566432 |    778.983985 | Tim H. Heupink, Leon Huynen, and David M. Lambert (vectorized by T. Michael Keesey)                                                                                                  |
| 264 |    706.670549 |    485.893223 | Robert Bruce Horsfall (vectorized by T. Michael Keesey)                                                                                                                              |
| 265 |    668.984474 |    346.570318 | Margot Michaud                                                                                                                                                                       |
| 266 |    550.163907 |    107.510877 | Evan-Amos (vectorized by T. Michael Keesey)                                                                                                                                          |
| 267 |    907.803175 |    473.267320 | Michael Scroggie, from original photograph by John Bettaso, USFWS (original photograph in public domain).                                                                            |
| 268 |   1012.345332 |    664.940817 | Markus A. Grohme                                                                                                                                                                     |
| 269 |     17.660248 |    561.984362 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                                              |
| 270 |    818.756658 |    204.633555 | Andrew A. Farke                                                                                                                                                                      |
| 271 |    930.490900 |    382.247229 | Anthony Caravaggi                                                                                                                                                                    |
| 272 |    255.405575 |    242.866776 | Smokeybjb                                                                                                                                                                            |
| 273 |    678.559606 |    270.955086 | Steven Traver                                                                                                                                                                        |
| 274 |    841.360042 |    541.293166 | Alexandre Vong                                                                                                                                                                       |
| 275 |    539.980930 |    738.541566 | Ferran Sayol                                                                                                                                                                         |
| 276 |    910.021135 |    623.879217 | Michael Scroggie                                                                                                                                                                     |
| 277 |    430.528831 |    481.167847 | Zimices                                                                                                                                                                              |
| 278 |    828.149238 |    615.969672 | Kamil S. Jaron                                                                                                                                                                       |
| 279 |    820.898436 |     42.773444 | Gareth Monger                                                                                                                                                                        |
| 280 |    791.761436 |    452.466060 | T. Michael Keesey                                                                                                                                                                    |
| 281 |    234.800074 |    523.701707 | Matt Crook                                                                                                                                                                           |
| 282 |     87.461028 |     78.244273 | Ferran Sayol                                                                                                                                                                         |
| 283 |    538.190934 |    693.889579 | Margot Michaud                                                                                                                                                                       |
| 284 |    964.285735 |    397.488550 | Margot Michaud                                                                                                                                                                       |
| 285 |    117.182704 |    735.056277 | NA                                                                                                                                                                                   |
| 286 |    384.181879 |    311.882192 | Steven Coombs                                                                                                                                                                        |
| 287 |    660.824606 |    711.517690 | Andy Wilson                                                                                                                                                                          |
| 288 |    107.275192 |    163.345785 | Taro Maeda                                                                                                                                                                           |
| 289 |    464.298971 |    331.699683 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 290 |     21.338950 |    235.203083 | Zimices                                                                                                                                                                              |
| 291 |    978.881130 |    627.140649 | NA                                                                                                                                                                                   |
| 292 |    270.068331 |    588.445774 | B Kimmel                                                                                                                                                                             |
| 293 |    635.362724 |    156.199223 | Jonathan Wells                                                                                                                                                                       |
| 294 |   1011.492250 |     58.615586 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 295 |    515.808483 |    261.917483 | NA                                                                                                                                                                                   |
| 296 |    789.783357 |      9.671177 | Ferran Sayol                                                                                                                                                                         |
| 297 |    603.170122 |    400.812172 | \<U+0412\>\<U+0430\>\<U+043B\>\<U+044C\>\<U+0434\>\<U+0438\>\<U+043C\>\<U+0430\>\<U+0440\> (vectorized by T. Michael Keesey)                                                         |
| 298 |    522.468030 |    346.662613 | Xavier Giroux-Bougard                                                                                                                                                                |
| 299 |    488.166487 |    748.768322 | Chloé Schmidt                                                                                                                                                                        |
| 300 |     23.879728 |    593.935466 | Emily Willoughby                                                                                                                                                                     |
| 301 |    383.590028 |    781.590924 | Dean Schnabel                                                                                                                                                                        |
| 302 |    584.283340 |    178.041029 | Iain Reid                                                                                                                                                                            |
| 303 |    799.876148 |     39.217146 | Matt Crook                                                                                                                                                                           |
| 304 |    656.625790 |    331.928264 | Pollyanna von Knorring and T. Michael Keesey                                                                                                                                         |
| 305 |    178.280320 |    262.491332 | Javiera Constanzo                                                                                                                                                                    |
| 306 |    792.532555 |    519.149987 | Rebecca Groom                                                                                                                                                                        |
| 307 |    335.558205 |    669.634868 | NA                                                                                                                                                                                   |
| 308 |    434.324779 |    657.238998 | Matt Crook                                                                                                                                                                           |
| 309 |    478.137878 |      2.413007 | Gareth Monger                                                                                                                                                                        |
| 310 |     71.509525 |     93.906373 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 311 |    701.718150 |      5.670836 | Yan Wong                                                                                                                                                                             |
| 312 |    232.797910 |    440.362506 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                                                    |
| 313 |    172.258726 |    731.391274 | Margot Michaud                                                                                                                                                                       |
| 314 |    265.496413 |    439.817049 | Emily Willoughby                                                                                                                                                                     |
| 315 |    766.151104 |    260.799414 | Steven Traver                                                                                                                                                                        |
| 316 |    844.987181 |      9.507474 | Matt Crook                                                                                                                                                                           |
| 317 |    772.907482 |    226.791252 | Mali’o Kodis, image from Higgins and Kristensen, 1986                                                                                                                                |
| 318 |    988.537274 |    390.152666 | Gareth Monger                                                                                                                                                                        |
| 319 |    607.776828 |    576.371774 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 320 |     98.209017 |    348.326175 | Shyamal                                                                                                                                                                              |
| 321 |    177.487971 |    509.730684 | Kanchi Nanjo                                                                                                                                                                         |
| 322 |    306.861759 |    362.363192 | Tracy A. Heath                                                                                                                                                                       |
| 323 |    413.967711 |     42.619989 | Margot Michaud                                                                                                                                                                       |
| 324 |    933.567822 |    405.576357 | Darius Nau                                                                                                                                                                           |
| 325 |    423.711188 |    165.473498 | Birgit Lang                                                                                                                                                                          |
| 326 |    889.127213 |    313.560989 | Lindberg (vectorized by T. Michael Keesey)                                                                                                                                           |
| 327 |    616.111561 |    536.623287 | Tom Tarrant (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                          |
| 328 |    469.468385 |    767.249916 | Zimices                                                                                                                                                                              |
| 329 |    736.325979 |    129.677949 | NA                                                                                                                                                                                   |
| 330 |    656.704112 |    468.550327 | Jagged Fang Designs                                                                                                                                                                  |
| 331 |    885.544800 |    445.605247 | Scott Hartman                                                                                                                                                                        |
| 332 |    892.036698 |     93.512409 | Steven Coombs                                                                                                                                                                        |
| 333 |    384.636183 |    581.968748 | Lauren Anderson                                                                                                                                                                      |
| 334 |    900.958165 |    789.497891 | Andrew A. Farke                                                                                                                                                                      |
| 335 |    216.828030 |    385.932058 | Zimices                                                                                                                                                                              |
| 336 |    257.907939 |    635.227895 | Gareth Monger                                                                                                                                                                        |
| 337 |    641.624271 |    446.493988 | annaleeblysse                                                                                                                                                                        |
| 338 |    967.080677 |    607.106933 | Ferran Sayol                                                                                                                                                                         |
| 339 |    181.792904 |    198.406899 | Chris A. Hamilton                                                                                                                                                                    |
| 340 |    238.172007 |    426.521172 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 341 |    868.408469 |    773.708351 | Sharon Wegner-Larsen                                                                                                                                                                 |
| 342 |   1015.280775 |    347.255733 | Matt Crook                                                                                                                                                                           |
| 343 |    917.794894 |    277.592736 | Ignacio Contreras                                                                                                                                                                    |
| 344 |    169.865285 |    725.263583 | Scott Hartman                                                                                                                                                                        |
| 345 |     26.339953 |    295.575930 | Markus A. Grohme                                                                                                                                                                     |
| 346 |    101.108651 |     84.781283 | Pedro de Siracusa                                                                                                                                                                    |
| 347 |      5.993565 |      7.834278 | Juan Carlos Jerí                                                                                                                                                                     |
| 348 |    228.667108 |    693.925000 | Taro Maeda                                                                                                                                                                           |
| 349 |    270.268452 |    646.778584 | NA                                                                                                                                                                                   |
| 350 |    952.618495 |    403.202082 | Michelle Site                                                                                                                                                                        |
| 351 |    164.674892 |    200.387889 | T. Michael Keesey                                                                                                                                                                    |
| 352 |     98.704757 |    358.877382 | Ville-Veikko Sinkkonen                                                                                                                                                               |
| 353 |     72.925213 |     81.477122 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                                        |
| 354 |    630.938449 |     12.401841 | TaraTaylorDesign                                                                                                                                                                     |
| 355 |    620.492028 |    707.673631 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 356 |    768.391233 |    207.581510 | Mathieu Basille                                                                                                                                                                      |
| 357 |    980.277378 |    422.563283 | T. Michael Keesey                                                                                                                                                                    |
| 358 |    528.254557 |    715.669417 | CNZdenek                                                                                                                                                                             |
| 359 |     24.805791 |    286.574900 | Felix Vaux                                                                                                                                                                           |
| 360 |    981.331519 |    718.178716 | Tasman Dixon                                                                                                                                                                         |
| 361 |    640.890981 |    691.010089 | Lily Hughes                                                                                                                                                                          |
| 362 |    517.237587 |    699.622466 | FunkMonk                                                                                                                                                                             |
| 363 |     15.946872 |    106.160656 | Matt Crook                                                                                                                                                                           |
| 364 |    446.751173 |    271.703995 | Jagged Fang Designs                                                                                                                                                                  |
| 365 |    324.786346 |    354.899230 | Birgit Lang                                                                                                                                                                          |
| 366 |    609.850201 |    156.757611 | Sergio A. Muñoz-Gómez                                                                                                                                                                |
| 367 |    415.838145 |    554.872417 | Ferran Sayol                                                                                                                                                                         |
| 368 |    737.812621 |    258.546522 | Daniel Stadtmauer                                                                                                                                                                    |
| 369 |   1006.558567 |    153.938919 | Matt Martyniuk                                                                                                                                                                       |
| 370 |   1011.480977 |    619.634820 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 371 |    481.127192 |    575.651540 | Jagged Fang Designs                                                                                                                                                                  |
| 372 |    678.030054 |    246.210803 | Matt Crook                                                                                                                                                                           |
| 373 |    661.323864 |    247.054107 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                                      |
| 374 |    623.564179 |    168.939211 | Ferran Sayol                                                                                                                                                                         |
| 375 |    404.395579 |    573.675313 | Scott Hartman                                                                                                                                                                        |
| 376 |    475.505856 |     19.740316 | Cesar Julian                                                                                                                                                                         |
| 377 |    665.722393 |     30.161073 | Steven Coombs                                                                                                                                                                        |
| 378 |    598.908281 |    481.952077 | Jagged Fang Designs                                                                                                                                                                  |
| 379 |    824.333410 |    592.047933 | Tasman Dixon                                                                                                                                                                         |
| 380 |    672.186864 |    482.991292 | Steven Traver                                                                                                                                                                        |
| 381 |    576.163047 |     76.746228 | Gareth Monger                                                                                                                                                                        |
| 382 |    353.988252 |    551.486574 | Neil Kelley                                                                                                                                                                          |
| 383 |    554.096926 |    611.369237 | Ignacio Contreras                                                                                                                                                                    |
| 384 |    866.843899 |      7.115014 | Noah Schlottman, photo from Casey Dunn                                                                                                                                               |
| 385 |    790.762109 |    484.442157 | Stemonitis (photography) and T. Michael Keesey (vectorization)                                                                                                                       |
| 386 |    947.060587 |    772.141502 | Mathew Stewart                                                                                                                                                                       |
| 387 |    578.565264 |    229.288122 | Jagged Fang Designs                                                                                                                                                                  |
| 388 |    668.913676 |    290.744601 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 389 |    827.580827 |    757.314177 | Margot Michaud                                                                                                                                                                       |
| 390 |    892.458117 |    680.418848 | NA                                                                                                                                                                                   |
| 391 |    497.507467 |     19.042919 | Nicolas Mongiardino Koch                                                                                                                                                             |
| 392 |    477.640135 |    782.739591 | NA                                                                                                                                                                                   |
| 393 |    864.215882 |     88.421448 | Maija Karala                                                                                                                                                                         |
| 394 |    254.428064 |    562.407607 | Steven Traver                                                                                                                                                                        |
| 395 |    857.769028 |    793.255835 | Noah Schlottman, photo by Casey Dunn                                                                                                                                                 |
| 396 |    263.123242 |     26.379237 | T. Michael Keesey                                                                                                                                                                    |
| 397 |   1006.678455 |    761.734592 | Scott Hartman                                                                                                                                                                        |
| 398 |    157.233591 |    301.189403 | L. Shyamal                                                                                                                                                                           |
| 399 |    764.276957 |     42.481012 | DW Bapst (Modified from Bulman, 1964)                                                                                                                                                |
| 400 |    828.040762 |    379.765845 | Matt Crook                                                                                                                                                                           |
| 401 |    305.442825 |    457.336510 | Javier Luque                                                                                                                                                                         |
| 402 |    896.592104 |    288.844019 | NA                                                                                                                                                                                   |
| 403 |    480.802342 |    309.784761 | NA                                                                                                                                                                                   |
| 404 |    445.758879 |    775.364394 | Tauana J. Cunha                                                                                                                                                                      |
| 405 |    103.798114 |    782.118310 | Rebecca Groom                                                                                                                                                                        |
| 406 |    980.013955 |     53.607666 | Noah Schlottman, photo from Casey Dunn                                                                                                                                               |
| 407 |    450.634802 |    294.384957 | Scott Hartman                                                                                                                                                                        |
| 408 |    465.144772 |    792.634584 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 409 |    415.626413 |    180.958702 | Smokeybjb                                                                                                                                                                            |
| 410 |    259.501582 |    695.028182 | Chase Brownstein                                                                                                                                                                     |
| 411 |     19.259513 |     22.565965 | Matt Crook                                                                                                                                                                           |
| 412 |    332.408407 |    455.594510 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                                                       |
| 413 |    800.535276 |    354.355385 | Armin Reindl                                                                                                                                                                         |
| 414 |    414.215211 |    581.387091 | Zimices                                                                                                                                                                              |
| 415 |    914.964526 |    573.369285 | Florian Pfaff                                                                                                                                                                        |
| 416 |    688.571513 |     77.717884 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                                      |
| 417 |    531.529703 |    790.447859 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 418 |   1008.758785 |    421.362525 | Scott Hartman                                                                                                                                                                        |
| 419 |    309.036462 |    514.133936 | Melissa Broussard                                                                                                                                                                    |
| 420 |    996.290710 |     40.387368 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 421 |    936.936310 |    288.713466 | Francesco Veronesi (vectorized by T. Michael Keesey)                                                                                                                                 |
| 422 |    644.977869 |     11.891186 | Bryan Carstens                                                                                                                                                                       |
| 423 |    370.718904 |    362.952400 | Emily Willoughby                                                                                                                                                                     |
| 424 |    375.797758 |    546.062805 | NA                                                                                                                                                                                   |
| 425 |    452.279041 |      5.307476 | Heinrich Harder (vectorized by William Gearty)                                                                                                                                       |
| 426 |    271.915785 |    733.777743 | Gareth Monger                                                                                                                                                                        |
| 427 |    870.594529 |    459.262570 | Gareth Monger                                                                                                                                                                        |
| 428 |    247.849589 |    367.399124 | Dean Schnabel                                                                                                                                                                        |
| 429 |    393.649645 |    360.980461 | T. Michael Keesey                                                                                                                                                                    |
| 430 |    450.236488 |    190.389046 | Matt Celeskey                                                                                                                                                                        |
| 431 |    212.304931 |    632.646951 | Matt Crook                                                                                                                                                                           |
| 432 |    963.730082 |    756.556085 | Emily Jane McTavish, from Haeckel, E. H. P. A. (1904).Kunstformen der Natur. Bibliographisches                                                                                       |
| 433 |    275.538798 |    564.221425 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 434 |    519.136042 |    222.617342 | Rebecca Groom                                                                                                                                                                        |
| 435 |     55.746291 |    125.018472 | NA                                                                                                                                                                                   |
| 436 |    754.972953 |     89.541612 | Scott Hartman                                                                                                                                                                        |
| 437 |    349.721961 |    794.916210 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                                    |
| 438 |    143.391035 |     52.308231 | Beth Reinke                                                                                                                                                                          |
| 439 |    537.935523 |     57.823392 | Enoch Joseph Wetsy (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                   |
| 440 |    391.756268 |    186.010019 | Andy Wilson                                                                                                                                                                          |
| 441 |    288.205015 |    360.818334 | Matt Celeskey                                                                                                                                                                        |
| 442 |    629.587642 |    141.924524 | Steven Traver                                                                                                                                                                        |
| 443 |    845.547789 |    344.735078 | Tasman Dixon                                                                                                                                                                         |
| 444 |     84.941687 |    501.633831 | Nobu Tamura and T. Michael Keesey                                                                                                                                                    |
| 445 |    588.653254 |    505.029812 | NA                                                                                                                                                                                   |
| 446 |    864.311295 |     19.479632 | Jagged Fang Designs                                                                                                                                                                  |
| 447 |    844.410233 |    721.120735 | Zimices                                                                                                                                                                              |
| 448 |    688.526445 |    712.803394 | Anthony Caravaggi                                                                                                                                                                    |
| 449 |    704.174752 |    103.767213 | Michael “FunkMonk” B. H. (vectorized by T. Michael Keesey)                                                                                                                           |
| 450 |    139.273887 |    172.425987 | Harold N Eyster                                                                                                                                                                      |
| 451 |     90.695963 |    756.208274 | Andy Wilson                                                                                                                                                                          |
| 452 |    518.789793 |    648.670919 | Ian Burt (original) and T. Michael Keesey (vectorization)                                                                                                                            |
| 453 |    761.039532 |    191.743442 | NA                                                                                                                                                                                   |
| 454 |    348.557587 |    201.272496 | Zimices                                                                                                                                                                              |
| 455 |    139.756657 |    183.085419 | Walter Vladimir                                                                                                                                                                      |
| 456 |    833.295746 |     59.957535 | Ferran Sayol                                                                                                                                                                         |
| 457 |    804.657688 |    493.305045 | L. Shyamal                                                                                                                                                                           |
| 458 |    209.415222 |    198.515299 | Abraão Leite                                                                                                                                                                         |
| 459 |    687.525186 |    316.145684 | Matthew Hooge (vectorized by T. Michael Keesey)                                                                                                                                      |
| 460 |    208.765930 |    563.914068 | Steven Traver                                                                                                                                                                        |
| 461 |    158.445898 |     10.179824 | Sibi (vectorized by T. Michael Keesey)                                                                                                                                               |
| 462 |    321.838379 |    558.531334 | Matt Crook                                                                                                                                                                           |
| 463 |    226.453131 |     45.865569 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 464 |    512.381260 |    297.463400 | Michael Scroggie                                                                                                                                                                     |
| 465 |    281.670388 |    151.617290 | Ferran Sayol                                                                                                                                                                         |
| 466 |     26.959143 |    263.793639 | Diana Pomeroy                                                                                                                                                                        |
| 467 |    491.360511 |    686.057347 | Ignacio Contreras                                                                                                                                                                    |
| 468 |    777.961663 |    382.495050 | Gareth Monger                                                                                                                                                                        |
| 469 |    251.588355 |    748.713467 | T. Michael Keesey, from a photograph by Thea Boodhoo                                                                                                                                 |
| 470 |    835.938799 |    742.320697 | Zimices                                                                                                                                                                              |
| 471 |    302.805599 |    203.372006 | Zimices                                                                                                                                                                              |
| 472 |    497.344901 |    206.430951 | NA                                                                                                                                                                                   |
| 473 |   1000.008076 |    711.891064 | Emily Willoughby                                                                                                                                                                     |
| 474 |    612.516516 |     54.319600 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                                     |
| 475 |    629.818479 |    420.113742 | Dean Schnabel                                                                                                                                                                        |
| 476 |    178.626305 |    535.959114 | Gareth Monger                                                                                                                                                                        |
| 477 |    488.395763 |    459.052557 | Andy Wilson                                                                                                                                                                          |
| 478 |    688.995752 |    770.112140 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 479 |    360.620562 |    392.937521 | Matt Crook                                                                                                                                                                           |
| 480 |    774.787121 |    418.156523 | Steven Traver                                                                                                                                                                        |
| 481 |    172.786763 |    565.978287 | Steven Traver                                                                                                                                                                        |
| 482 |    237.840982 |    354.995493 | Dean Schnabel                                                                                                                                                                        |
| 483 |    795.939040 |    631.401840 | NA                                                                                                                                                                                   |
| 484 |     46.894906 |    305.753524 | George Edward Lodge (modified by T. Michael Keesey)                                                                                                                                  |
| 485 |    277.010604 |    494.223606 | T. Michael Keesey (after Mivart)                                                                                                                                                     |
| 486 |    847.120083 |    671.219996 | Jagged Fang Designs                                                                                                                                                                  |
| 487 |    563.953015 |    493.419272 | Gareth Monger                                                                                                                                                                        |
| 488 |    607.885874 |    235.087978 | Natasha Vitek                                                                                                                                                                        |
| 489 |    808.620030 |    613.772193 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                                  |
| 490 |    606.651424 |    190.324986 | Matt Crook                                                                                                                                                                           |
| 491 |    904.878809 |    390.018487 | Oscar Sanisidro                                                                                                                                                                      |
| 492 |    731.827358 |    761.233481 | Margot Michaud                                                                                                                                                                       |
| 493 |    286.992320 |    739.980611 | Jagged Fang Designs                                                                                                                                                                  |
| 494 |    267.225536 |    748.302511 | T. Michael Keesey                                                                                                                                                                    |
| 495 |     52.050905 |    398.202863 | Matt Dempsey                                                                                                                                                                         |
| 496 |    555.457856 |    569.133953 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                                     |
| 497 |    985.550387 |    709.837574 | Matus Valach                                                                                                                                                                         |
| 498 |    690.365500 |    235.011368 | Kamil S. Jaron                                                                                                                                                                       |
| 499 |    391.663719 |    616.621490 | James R. Spotila and Ray Chatterji                                                                                                                                                   |
| 500 |    424.855313 |    605.549848 | Matt Crook                                                                                                                                                                           |
| 501 |    603.015994 |    714.832393 | Zimices                                                                                                                                                                              |
| 502 |      7.030484 |    505.120269 | Aviceda (vectorized by T. Michael Keesey)                                                                                                                                            |
| 503 |    614.971765 |    353.382708 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 504 |    872.624501 |    479.682604 | Steven Traver                                                                                                                                                                        |
| 505 |    771.099411 |    481.660965 | Matt Crook                                                                                                                                                                           |
| 506 |    370.691937 |    375.768594 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                              |
| 507 |    991.725065 |    317.604284 | Kamil S. Jaron                                                                                                                                                                       |
| 508 |    142.631175 |    786.524576 | T. Michael Keesey (vectorization); Yves Bousquet (photography)                                                                                                                       |
| 509 |    991.522910 |    791.988302 | V. Deepak                                                                                                                                                                            |
| 510 |    713.711883 |    280.783961 | Michelle Site                                                                                                                                                                        |
| 511 |    907.896924 |     76.242615 | Lukas Panzarin                                                                                                                                                                       |
| 512 |    997.351198 |    599.001003 | Jagged Fang Designs                                                                                                                                                                  |
| 513 |     54.978379 |    676.758374 | Scott Hartman                                                                                                                                                                        |
| 514 |      5.848791 |    207.539605 | Michelle Site                                                                                                                                                                        |
| 515 |    217.025916 |    496.210449 | Mali’o Kodis, photograph by G. Giribet                                                                                                                                               |
| 516 |    195.422471 |    290.890390 | Yan Wong                                                                                                                                                                             |
| 517 |    995.706302 |     87.847740 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 518 |    968.064524 |    287.585635 | Jagged Fang Designs                                                                                                                                                                  |
| 519 |    647.896728 |    526.163343 | Craig Dylke                                                                                                                                                                          |
| 520 |    281.934189 |    725.359814 | Mathieu Pélissié                                                                                                                                                                     |
| 521 |    658.140722 |    698.316187 | Birgit Lang                                                                                                                                                                          |
| 522 |    952.701420 |    372.603978 | Steven Traver                                                                                                                                                                        |
| 523 |    753.231356 |    711.927399 | Jagged Fang Designs                                                                                                                                                                  |
| 524 |    459.070177 |    774.146484 | Mo Hassan                                                                                                                                                                            |
| 525 |    805.284442 |    531.615045 | Steven Traver                                                                                                                                                                        |
| 526 |   1015.687636 |    651.744537 | Dean Schnabel                                                                                                                                                                        |
| 527 |    945.865208 |    153.118965 | Steven Traver                                                                                                                                                                        |
| 528 |    671.137901 |    780.552246 | Archaeodontosaurus (vectorized by T. Michael Keesey)                                                                                                                                 |
| 529 |    444.885155 |    313.148523 | Dean Schnabel                                                                                                                                                                        |
| 530 |    218.917598 |    534.700761 | Zimices                                                                                                                                                                              |
| 531 |    594.254063 |    165.127850 | NA                                                                                                                                                                                   |
| 532 |    727.133890 |    273.905541 | Christoph Schomburg                                                                                                                                                                  |
| 533 |    327.457864 |    396.691541 | Lukasiniho                                                                                                                                                                           |
| 534 |     26.738531 |    715.982513 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 535 |    694.895559 |    533.828268 | NA                                                                                                                                                                                   |
| 536 |    409.740220 |    462.489958 | Becky Barnes                                                                                                                                                                         |
| 537 |    347.276166 |    439.964117 | Ferran Sayol                                                                                                                                                                         |
| 538 |    814.633879 |    241.820436 | Tauana J. Cunha                                                                                                                                                                      |
| 539 |    988.290384 |    409.874898 | Gareth Monger                                                                                                                                                                        |
| 540 |    296.361823 |     48.512136 | Jaime Headden                                                                                                                                                                        |
| 541 |    101.221371 |     46.613346 | Andy Wilson                                                                                                                                                                          |
| 542 |    623.052053 |     49.030418 | Ludwik Gasiorowski                                                                                                                                                                   |
| 543 |    953.913650 |    307.176876 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 544 |    809.494562 |    346.388543 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 545 |    122.999166 |    794.994427 | Andrew A. Farke                                                                                                                                                                      |
| 546 |    999.784156 |    545.279552 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                                      |
| 547 |     25.862303 |    731.300999 | Zimices                                                                                                                                                                              |
| 548 |    866.865639 |    309.859059 | Lily Hughes                                                                                                                                                                          |
| 549 |    655.738340 |    790.350890 | Margot Michaud                                                                                                                                                                       |
| 550 |    764.877079 |    692.491173 | Kamil S. Jaron                                                                                                                                                                       |
| 551 |    270.138048 |    673.684825 | Jose Carlos Arenas-Monroy                                                                                                                                                            |
| 552 |    464.203805 |     11.627890 | Lisa Byrne                                                                                                                                                                           |
| 553 |    208.912868 |    183.226596 | Tyler Greenfield                                                                                                                                                                     |
| 554 |    329.027587 |    492.153366 | Henry Lydecker                                                                                                                                                                       |
| 555 |     88.991472 |    251.913480 | André Karwath (vectorized by T. Michael Keesey)                                                                                                                                      |
| 556 |    958.208316 |    784.997979 | Matt Crook                                                                                                                                                                           |
| 557 |     43.934402 |     15.108102 | Steven Traver                                                                                                                                                                        |
| 558 |    145.464199 |    721.194625 | Scott Reid                                                                                                                                                                           |
| 559 |    173.686919 |    223.122599 | Mike Hanson                                                                                                                                                                          |
| 560 |    742.825376 |    476.514737 | Matt Crook                                                                                                                                                                           |
| 561 |    445.197528 |     18.623787 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                                         |
| 562 |    358.144423 |    411.717402 | Harold N Eyster                                                                                                                                                                      |
| 563 |    979.539725 |     32.167007 | Andy Wilson                                                                                                                                                                          |
| 564 |    223.698103 |    720.767822 | Scott Hartman                                                                                                                                                                        |
| 565 |    311.670395 |    697.939510 | T. Michael Keesey (after Mauricio Antón)                                                                                                                                             |
| 566 |     63.657902 |    163.322042 | Markus A. Grohme                                                                                                                                                                     |
| 567 |    593.237258 |    475.944585 | Markus A. Grohme                                                                                                                                                                     |
| 568 |    819.107535 |    604.971514 | Zimices                                                                                                                                                                              |
| 569 |    662.871588 |    321.408364 | Margot Michaud                                                                                                                                                                       |
| 570 |    867.506099 |    104.924824 | Chris huh                                                                                                                                                                            |
| 571 |    660.562007 |    206.566546 | Kailah Thorn & Mark Hutchinson                                                                                                                                                       |
| 572 |     72.157664 |    171.880590 | Zimices                                                                                                                                                                              |
| 573 |    993.364569 |    592.304560 | Mali’o Kodis, photograph by Jim Vargo                                                                                                                                                |
| 574 |    963.136481 |    151.609980 | Birgit Lang                                                                                                                                                                          |
| 575 |    318.151622 |    191.464764 | Matt Crook                                                                                                                                                                           |
| 576 |    587.919914 |    792.103306 | Steven Traver                                                                                                                                                                        |
| 577 |   1009.888011 |    678.645389 | Harold N Eyster                                                                                                                                                                      |
| 578 |    607.696638 |    785.184997 | Margot Michaud                                                                                                                                                                       |
| 579 |    233.593944 |    399.465330 | Joanna Wolfe                                                                                                                                                                         |
| 580 |    875.680846 |    516.048697 | T. Michael Keesey                                                                                                                                                                    |
| 581 |    626.090894 |    614.983376 | Tasman Dixon                                                                                                                                                                         |
| 582 |    204.335968 |    342.115001 | Chris huh                                                                                                                                                                            |
| 583 |    425.129260 |    304.705595 | Mathilde Cordellier                                                                                                                                                                  |
| 584 |     64.585799 |    453.882337 | Marie Russell                                                                                                                                                                        |
| 585 |    543.689111 |    478.028705 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 586 |    811.236223 |    715.124298 | Zimices                                                                                                                                                                              |
| 587 |    982.357415 |    548.404069 | Jagged Fang Designs                                                                                                                                                                  |
| 588 |     34.470326 |     26.235323 | B. Duygu Özpolat                                                                                                                                                                     |
| 589 |    127.523632 |    445.391028 | Tasman Dixon                                                                                                                                                                         |
| 590 |    254.812537 |    599.809764 | Iain Reid                                                                                                                                                                            |
| 591 |    574.451307 |    124.741279 | NA                                                                                                                                                                                   |
| 592 |    554.047132 |    581.695747 | Ferran Sayol                                                                                                                                                                         |
| 593 |    379.352252 |    570.039185 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                                    |
| 594 |    642.005136 |     30.085162 | Matt Crook                                                                                                                                                                           |
| 595 |    243.689245 |     11.797458 | Ferran Sayol                                                                                                                                                                         |
| 596 |    853.704976 |    441.650499 | DW Bapst, modified from Figure 1 of Belanger (2011, PALAIOS).                                                                                                                        |
| 597 |      7.970555 |    573.322005 | Ferran Sayol                                                                                                                                                                         |
| 598 |    724.752476 |    206.638175 | Armin Reindl                                                                                                                                                                         |
| 599 |     11.665893 |     57.423105 | Scott Hartman                                                                                                                                                                        |
| 600 |    935.077478 |    786.652115 | Collin Gross                                                                                                                                                                         |
| 601 |    749.972494 |    351.919210 | Andy Wilson                                                                                                                                                                          |
| 602 |    630.016421 |    343.758195 | Andrew A. Farke                                                                                                                                                                      |
| 603 |    211.781653 |    754.568076 | NA                                                                                                                                                                                   |
| 604 |    954.610486 |    508.049175 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                                         |
| 605 |     11.908888 |    792.442805 | Steven Traver                                                                                                                                                                        |
| 606 |    436.274788 |     58.193042 | Zimices                                                                                                                                                                              |
| 607 |      9.179062 |    588.468323 | Zimices                                                                                                                                                                              |
| 608 |     63.757303 |    154.503864 | Ville-Veikko Sinkkonen                                                                                                                                                               |
| 609 |    907.694684 |    212.599877 | Ferran Sayol                                                                                                                                                                         |
| 610 |    405.370186 |    694.574755 | Zimices                                                                                                                                                                              |
| 611 |     40.515535 |    435.948372 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 612 |    919.438667 |    312.550654 | Joanna Wolfe                                                                                                                                                                         |
| 613 |     65.359916 |    419.679886 | Steven Traver                                                                                                                                                                        |
| 614 |    190.241189 |    730.503331 | T. Michael Keesey (after MPF)                                                                                                                                                        |
| 615 |     52.677633 |     85.177458 | T. Michael Keesey (vectorization); Thorsten Assmann, Jörn Buse, Claudia Drees, Ariel-Leib-Leonid Friedman, Tal Levanony, Andrea Matern, Anika Timm, and David W. Wrase (photography) |
| 616 |    662.595629 |    271.331561 | Pedro de Siracusa                                                                                                                                                                    |
| 617 |    333.252780 |    786.925694 | T. Michael Keesey (after Kukalová)                                                                                                                                                   |
| 618 |   1009.971372 |    513.201100 | Andy Wilson                                                                                                                                                                          |
| 619 |    471.650967 |     46.956058 | Ferran Sayol                                                                                                                                                                         |
| 620 |     45.682033 |    505.752762 | Margot Michaud                                                                                                                                                                       |
| 621 |    349.141131 |    509.778243 | Gareth Monger                                                                                                                                                                        |
| 622 |    507.336937 |    354.843296 | Matt Crook                                                                                                                                                                           |
| 623 |    617.494771 |    369.252384 | Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus                                                             |
| 624 |    248.442834 |     23.388621 | Emily Willoughby                                                                                                                                                                     |
| 625 |    700.833551 |    263.530759 | Tony Ayling (vectorized by Milton Tan)                                                                                                                                               |
| 626 |    329.980382 |    425.406888 | Zimices                                                                                                                                                                              |
| 627 |    148.153652 |    264.128675 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                                  |
| 628 |     11.607924 |    482.327546 | Robert Bruce Horsfall (vectorized by William Gearty)                                                                                                                                 |
| 629 |    874.827722 |    127.502972 | Chris huh                                                                                                                                                                            |
| 630 |      7.846392 |    492.105269 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 631 |   1018.050670 |    505.049684 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                                       |
| 632 |    701.759577 |    293.518136 | Steven Traver                                                                                                                                                                        |
| 633 |     69.938075 |    468.280119 | Mattia Menchetti                                                                                                                                                                     |
| 634 |    509.034704 |    482.954081 | Ferran Sayol                                                                                                                                                                         |
| 635 |    209.331735 |     18.725343 | Collin Gross                                                                                                                                                                         |
| 636 |    464.111888 |    668.742372 | Margot Michaud                                                                                                                                                                       |
| 637 |    886.257426 |    509.825352 | Maija Karala                                                                                                                                                                         |
| 638 |    933.039819 |    669.874962 | Margot Michaud                                                                                                                                                                       |
| 639 |    255.765305 |    264.441247 | NA                                                                                                                                                                                   |
| 640 |    698.129403 |    706.026883 | Ferran Sayol                                                                                                                                                                         |
| 641 |    494.411499 |    340.158306 | Geoff Shaw                                                                                                                                                                           |
| 642 |    776.357965 |    430.997637 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 643 |    208.907734 |    525.442819 | Michael Scroggie, from original photograph by Gary M. Stolz, USFWS (original photograph in public domain).                                                                           |
| 644 |    507.048540 |    767.819721 | T. Michael Keesey                                                                                                                                                                    |
| 645 |    487.770717 |    584.602702 | Sergio A. Muñoz-Gómez                                                                                                                                                                |
| 646 |     51.113391 |    469.925671 | Mark Witton                                                                                                                                                                          |
| 647 |    825.286485 |    744.385768 | Zimices                                                                                                                                                                              |
| 648 |    474.798319 |    691.601976 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                                     |
| 649 |    495.602251 |    127.650369 | Chris huh                                                                                                                                                                            |
| 650 |    783.304672 |     40.607352 | Jack Mayer Wood                                                                                                                                                                      |
| 651 |    975.565430 |    649.425664 | Matt Crook                                                                                                                                                                           |
| 652 |     27.170637 |    250.569341 | CNZdenek                                                                                                                                                                             |
| 653 |    412.002795 |    160.418363 | Joanna Wolfe                                                                                                                                                                         |
| 654 |    787.137621 |    425.150870 | xgirouxb                                                                                                                                                                             |
| 655 |    785.811010 |    405.605312 | NA                                                                                                                                                                                   |
| 656 |    395.614075 |    605.922491 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 657 |    202.894465 |    630.847556 | Collin Gross                                                                                                                                                                         |
| 658 |    343.215825 |    297.603483 | Maha Ghazal                                                                                                                                                                          |
| 659 |    568.911908 |    161.870521 | Andrés Sánchez                                                                                                                                                                       |
| 660 |    137.378357 |    509.227824 | Beth Reinke                                                                                                                                                                          |
| 661 |    644.084311 |    701.519261 | Neil Kelley                                                                                                                                                                          |
| 662 |    849.064943 |     51.716281 | Jagged Fang Designs                                                                                                                                                                  |
| 663 |    603.332207 |    677.219987 | Matt Crook                                                                                                                                                                           |
| 664 |    866.120020 |    703.767977 | Caroline Harding, MAF (vectorized by T. Michael Keesey)                                                                                                                              |
| 665 |     37.770280 |    229.683926 | Gareth Monger                                                                                                                                                                        |
| 666 |    185.602285 |    592.651669 | NA                                                                                                                                                                                   |
| 667 |    430.000922 |    568.003322 | T. Michael Keesey                                                                                                                                                                    |
| 668 |    452.400592 |    195.894435 | Dean Schnabel                                                                                                                                                                        |
| 669 |    983.292294 |    481.361100 | Mali’o Kodis, image from the Biodiversity Heritage Library                                                                                                                           |
| 670 |    347.552005 |    632.263092 | Matt Crook                                                                                                                                                                           |
| 671 |     12.414691 |    732.148630 | David Liao                                                                                                                                                                           |
| 672 |    488.393618 |     39.878324 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 673 |    248.399557 |     36.175870 | Mo Hassan                                                                                                                                                                            |
| 674 |    994.586071 |    639.289951 | Mr E? (vectorized by T. Michael Keesey)                                                                                                                                              |
| 675 |    772.475276 |    314.392510 | Zimices                                                                                                                                                                              |
| 676 |    346.420195 |    210.609485 | Conty (vectorized by T. Michael Keesey)                                                                                                                                              |
| 677 |    597.770656 |    386.857762 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 678 |    535.278086 |    499.185755 | Andrew Farke and Joseph Sertich                                                                                                                                                      |
| 679 |    883.540347 |    428.461277 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 680 |    191.270413 |      4.871745 | Gareth Monger                                                                                                                                                                        |
| 681 |    860.658246 |    286.020543 | T. Michael Keesey                                                                                                                                                                    |
| 682 |    382.910973 |    188.178303 | Christine Axon                                                                                                                                                                       |
| 683 |    969.556711 |    509.053778 | Steven Traver                                                                                                                                                                        |
| 684 |    650.203575 |    479.197831 | Matt Crook                                                                                                                                                                           |
| 685 |    824.205723 |     64.524451 | Tasman Dixon                                                                                                                                                                         |
| 686 |    196.973186 |    569.048175 | Ray Simpson (vectorized by T. Michael Keesey)                                                                                                                                        |
| 687 |    391.950788 |    306.544413 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 688 |    872.633192 |    203.160511 | Agnello Picorelli                                                                                                                                                                    |
| 689 |    534.911112 |     64.046549 | Shyamal                                                                                                                                                                              |
| 690 |    679.284635 |    721.764877 | Margot Michaud                                                                                                                                                                       |
| 691 |    291.629386 |    716.476140 | Scott Hartman                                                                                                                                                                        |
| 692 |    510.414962 |    420.784187 | Andrew Farke and Joseph Sertich                                                                                                                                                      |
| 693 |    201.216272 |     35.372703 | Margot Michaud                                                                                                                                                                       |
| 694 |    518.778034 |    175.261508 | Zimices                                                                                                                                                                              |
| 695 |    574.736778 |    397.676063 | Maxime Dahirel                                                                                                                                                                       |
| 696 |    249.008550 |    530.470824 | Karkemish (vectorized by T. Michael Keesey)                                                                                                                                          |
| 697 |    615.456415 |    314.106477 | Steven Traver                                                                                                                                                                        |
| 698 |    646.293026 |    363.415393 | Dmitry Bogdanov and FunkMonk (vectorized by T. Michael Keesey)                                                                                                                       |
| 699 |    644.332106 |    306.130896 | Margot Michaud                                                                                                                                                                       |
| 700 |    739.173806 |     52.812651 | Christopher Laumer (vectorized by T. Michael Keesey)                                                                                                                                 |
| 701 |    598.055655 |    223.297111 | Matt Crook                                                                                                                                                                           |
| 702 |    161.863359 |    158.619432 | Steven Traver                                                                                                                                                                        |
| 703 |     69.381902 |     42.497283 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                                                       |
| 704 |    113.744012 |    482.157899 | Margot Michaud                                                                                                                                                                       |
| 705 |    836.156672 |    317.849148 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 706 |     46.019706 |    271.672107 | Margot Michaud                                                                                                                                                                       |
| 707 |    645.194589 |    463.226625 | Mali’o Kodis, photograph from <http://commons.wikimedia.org/wiki/File:Trichoplax.jpg>                                                                                                |
| 708 |    370.908128 |    505.409021 | Noah Schlottman, photo by Casey Dunn                                                                                                                                                 |
| 709 |   1015.548309 |    561.758557 | Ghedo and T. Michael Keesey                                                                                                                                                          |
| 710 |    712.424999 |    703.219330 | Jonathan Lawley                                                                                                                                                                      |
| 711 |    171.203848 |    168.236786 | Jose Carlos Arenas-Monroy                                                                                                                                                            |
| 712 |    106.507638 |    529.561686 | Markus A. Grohme                                                                                                                                                                     |
| 713 |    629.720132 |    449.119445 | Anthony Caravaggi                                                                                                                                                                    |
| 714 |    179.667658 |    238.587709 | Collin Gross                                                                                                                                                                         |
| 715 |    246.110018 |    380.934176 | Raven Amos                                                                                                                                                                           |
| 716 |    234.556381 |    783.406783 | T. Michael Keesey                                                                                                                                                                    |
| 717 |   1017.548598 |    776.590456 | Crystal Maier                                                                                                                                                                        |
| 718 |    273.732547 |    367.384961 | Thea Boodhoo (photograph) and T. Michael Keesey (vectorization)                                                                                                                      |
| 719 |      8.382333 |    474.780072 | Markus A. Grohme                                                                                                                                                                     |
| 720 |    523.082740 |    760.372785 | Tyler Greenfield                                                                                                                                                                     |
| 721 |    847.757816 |    202.597434 | Ferran Sayol                                                                                                                                                                         |
| 722 |    946.569081 |    393.968714 | Matt Celeskey                                                                                                                                                                        |
| 723 |    813.008445 |     25.827990 | Gareth Monger                                                                                                                                                                        |
| 724 |    713.027765 |    254.263862 | Yan Wong                                                                                                                                                                             |
| 725 |    828.392830 |     73.719217 | Zimices                                                                                                                                                                              |
| 726 |    134.339498 |    253.769975 | Steven Traver                                                                                                                                                                        |
| 727 |    532.367022 |    758.831956 | Joanna Wolfe                                                                                                                                                                         |
| 728 |    400.932262 |    590.545878 | \[unknown\]                                                                                                                                                                          |
| 729 |    641.989488 |    418.232923 | Andy Wilson                                                                                                                                                                          |
| 730 |     16.579644 |    434.355048 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                                   |
| 731 |    355.968293 |    696.304992 | Tracy A. Heath                                                                                                                                                                       |
| 732 |    724.997421 |    265.681922 | Markus A. Grohme                                                                                                                                                                     |
| 733 |    491.960306 |    199.963386 | Chris huh                                                                                                                                                                            |
| 734 |    230.427344 |    407.018659 | Margot Michaud                                                                                                                                                                       |
| 735 |    407.415794 |     10.339536 | Oscar Sanisidro                                                                                                                                                                      |
| 736 |    186.552088 |    283.801971 | NA                                                                                                                                                                                   |
| 737 |    755.501764 |    286.869515 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 738 |    378.692604 |    556.427626 | Andy Wilson                                                                                                                                                                          |
| 739 |      9.080894 |    620.386759 | Jack Mayer Wood                                                                                                                                                                      |
| 740 |    482.071338 |    136.013060 | NA                                                                                                                                                                                   |
| 741 |    820.502343 |    411.349141 | Chris huh                                                                                                                                                                            |
| 742 |    655.794266 |    122.095756 | Matt Crook                                                                                                                                                                           |
| 743 |    990.522852 |    376.342263 | Chloé Schmidt                                                                                                                                                                        |
| 744 |    514.253324 |    412.274099 | Andy Wilson                                                                                                                                                                          |
| 745 |    293.457781 |    429.085300 | Ferran Sayol                                                                                                                                                                         |
| 746 |    277.990460 |     44.473230 | Emma Hughes                                                                                                                                                                          |
| 747 |    944.704879 |     55.862166 | Gareth Monger                                                                                                                                                                        |
| 748 |    292.164912 |    498.917191 | L. Shyamal                                                                                                                                                                           |
| 749 |    121.890299 |    177.366502 | Zimices                                                                                                                                                                              |
| 750 |    784.456550 |     20.143827 | Steven Traver                                                                                                                                                                        |
| 751 |    822.140429 |    728.403955 | Matt Crook                                                                                                                                                                           |
| 752 |    512.950615 |    565.094852 | NA                                                                                                                                                                                   |
| 753 |    132.071245 |    356.849111 | NA                                                                                                                                                                                   |
| 754 |    756.482713 |    494.277646 | Jaime Headden, modified by T. Michael Keesey                                                                                                                                         |
| 755 |    901.765264 |    564.041261 | Steven Traver                                                                                                                                                                        |
| 756 |     43.060053 |    534.088758 | AnAgnosticGod (vectorized by T. Michael Keesey)                                                                                                                                      |
| 757 |   1012.962395 |    556.047065 | Scott Hartman                                                                                                                                                                        |
| 758 |    422.717493 |     16.967173 | Bill Bouton (source photo) & T. Michael Keesey (vectorization)                                                                                                                       |
| 759 |    613.104010 |    325.761996 | Kai R. Caspar                                                                                                                                                                        |
| 760 |    492.615426 |    119.153071 | Joanna Wolfe                                                                                                                                                                         |
| 761 |    519.978367 |    268.514749 | Pete Buchholz                                                                                                                                                                        |
| 762 |     70.413950 |    437.417711 | Zimices                                                                                                                                                                              |
| 763 |    738.639534 |    484.867412 | Steven Traver                                                                                                                                                                        |
| 764 |    915.442166 |    323.827812 | Jagged Fang Designs                                                                                                                                                                  |
| 765 |    200.501162 |    782.621098 | Qiang Ou                                                                                                                                                                             |
| 766 |    979.964584 |    759.861667 | Philip Chalmers (vectorized by T. Michael Keesey)                                                                                                                                    |
| 767 |    931.332020 |    628.274660 | Ingo Braasch                                                                                                                                                                         |
| 768 |    251.301479 |    609.071578 | Birgit Lang                                                                                                                                                                          |
| 769 |    272.911390 |    258.845098 | Steven Traver                                                                                                                                                                        |
| 770 |     19.030261 |    244.851774 | Milton Tan                                                                                                                                                                           |
| 771 |    733.700817 |    192.749139 | NA                                                                                                                                                                                   |
| 772 |    249.286086 |    794.947100 | Jaime Headden                                                                                                                                                                        |
| 773 |     84.826346 |    661.375539 | Andy Wilson                                                                                                                                                                          |
| 774 |    704.540096 |    274.134184 | Gopal Murali                                                                                                                                                                         |
| 775 |    637.140823 |    402.987555 | Andy Wilson                                                                                                                                                                          |
| 776 |    926.782281 |    149.949835 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 777 |    349.654135 |     96.991515 | T. Michael Keesey                                                                                                                                                                    |
| 778 |    403.310634 |    187.364070 | Rachel Shoop                                                                                                                                                                         |
| 779 |    618.930600 |    377.013135 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 780 |    970.183544 |    575.586877 | Christoph Schomburg                                                                                                                                                                  |
| 781 |    881.009178 |     75.625569 | Matt Crook                                                                                                                                                                           |
| 782 |    730.750978 |    491.247977 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 783 |    170.352291 |    149.798524 | T. Michael Keesey                                                                                                                                                                    |
| 784 |    550.072471 |    782.310874 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                                       |
| 785 |    641.170860 |    188.579082 | NA                                                                                                                                                                                   |
| 786 |    969.665664 |    779.701630 | T. Michael Keesey                                                                                                                                                                    |
| 787 |    937.006691 |    347.584182 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 788 |    419.401082 |     78.419032 | Meyer-Wachsmuth I, Curini Galletti M, Jondelius U (<doi:10.1371/journal.pone.0107688>). Vectorization by Y. Wong                                                                     |
| 789 |    519.139411 |    488.229079 | Matt Crook                                                                                                                                                                           |
| 790 |     34.081500 |    400.614284 | Markus A. Grohme                                                                                                                                                                     |
| 791 |   1013.520222 |     45.557349 | Trond R. Oskars                                                                                                                                                                      |
| 792 |    908.218062 |    419.729119 | Rebecca Groom                                                                                                                                                                        |
| 793 |    509.818300 |    337.460761 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 794 |    493.479102 |    463.821168 | Harold N Eyster                                                                                                                                                                      |
| 795 |     66.862473 |     50.818840 | NA                                                                                                                                                                                   |
| 796 |    301.932168 |    640.183018 | Cesar Julian                                                                                                                                                                         |
| 797 |    848.303740 |    625.550388 | Ferran Sayol                                                                                                                                                                         |
| 798 |    206.597563 |    609.025732 | David Orr                                                                                                                                                                            |
| 799 |    165.866109 |    288.307665 | Dean Schnabel                                                                                                                                                                        |
| 800 |    198.804328 |    750.684812 | Scott Hartman                                                                                                                                                                        |
| 801 |    582.470392 |    458.247781 | Sarah Werning                                                                                                                                                                        |
| 802 |     55.519170 |    665.691061 | Matt Crook                                                                                                                                                                           |
| 803 |    747.759258 |    697.405888 | Kamil S. Jaron                                                                                                                                                                       |
| 804 |    788.871937 |    281.412812 | Chris huh                                                                                                                                                                            |
| 805 |   1002.791921 |    606.441796 | Noah Schlottman, photo by Museum of Geology, University of Tartu                                                                                                                     |
| 806 |    718.055868 |    111.849106 | Zimices                                                                                                                                                                              |
| 807 |    386.740099 |    792.578646 | Maija Karala                                                                                                                                                                         |
| 808 |     93.995259 |    676.723701 | Jagged Fang Designs                                                                                                                                                                  |
| 809 |    751.441103 |     78.309630 | H. F. O. March (vectorized by T. Michael Keesey)                                                                                                                                     |
| 810 |    226.203902 |    371.748293 | Ville-Veikko Sinkkonen                                                                                                                                                               |
| 811 |    330.357928 |    476.836767 | Terpsichores                                                                                                                                                                         |
| 812 |    174.345386 |    742.038612 | Zimices                                                                                                                                                                              |
| 813 |    946.249600 |    657.860067 | Matt Dempsey                                                                                                                                                                         |
| 814 |    645.910803 |    324.597184 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 815 |    677.495863 |    279.075031 | Noah Schlottman, photo from Casey Dunn                                                                                                                                               |
| 816 |    175.609947 |    553.962749 | Tauana J. Cunha                                                                                                                                                                      |
| 817 |    196.854934 |    234.736096 | Gareth Monger                                                                                                                                                                        |
| 818 |     73.043336 |    365.195325 | NA                                                                                                                                                                                   |
| 819 |    413.292186 |    782.589473 | Matt Crook                                                                                                                                                                           |
| 820 |    524.337319 |    296.393691 | Michelle Site                                                                                                                                                                        |
| 821 |    516.135636 |    374.430727 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                                    |
| 822 |    779.028066 |    490.994957 | Ferran Sayol                                                                                                                                                                         |
| 823 |    605.576217 |    662.517423 | Jagged Fang Designs                                                                                                                                                                  |
| 824 |    601.928543 |    636.614106 | Margot Michaud                                                                                                                                                                       |
| 825 |    216.592265 |    209.175863 | Hans Hillewaert                                                                                                                                                                      |
| 826 |    957.422392 |    361.577676 | John Conway                                                                                                                                                                          |
| 827 |    637.896397 |    544.217954 | Birgit Lang                                                                                                                                                                          |
| 828 |    711.784180 |    131.272220 | Sarah Werning                                                                                                                                                                        |
| 829 |     25.433699 |    409.738530 | Michael Day                                                                                                                                                                          |
| 830 |    332.630220 |    287.378210 | Christoph Schomburg                                                                                                                                                                  |
| 831 |     52.473235 |    444.680878 | Emily Willoughby                                                                                                                                                                     |
| 832 |    250.044378 |    345.292813 | Mathilde Cordellier                                                                                                                                                                  |
| 833 |    352.309534 |    346.768706 | Notafly (vectorized by T. Michael Keesey)                                                                                                                                            |
| 834 |    143.365502 |    795.730046 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 835 |    805.037795 |    631.088327 | Margot Michaud                                                                                                                                                                       |
| 836 |    247.017468 |    725.730286 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 837 |     15.935440 |    150.181555 | Konsta Happonen                                                                                                                                                                      |
| 838 |    240.123584 |    552.072969 | Lukasiniho                                                                                                                                                                           |
| 839 |     44.385045 |    357.783476 | Margot Michaud                                                                                                                                                                       |
| 840 |    334.144302 |    513.527110 | Matt Crook                                                                                                                                                                           |
| 841 |    928.906407 |    772.396310 | Jake Warner                                                                                                                                                                          |
| 842 |   1003.797030 |    721.034559 | Matt Crook                                                                                                                                                                           |
| 843 |    872.981362 |    554.806880 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 844 |    134.661414 |    495.109004 | Joanna Wolfe                                                                                                                                                                         |
| 845 |    449.412464 |    132.464203 | Andy Wilson                                                                                                                                                                          |
| 846 |     45.148530 |    516.129568 | FunkMonk                                                                                                                                                                             |
| 847 |    216.340919 |    252.140517 | Michele M Tobias                                                                                                                                                                     |
| 848 |     79.142758 |    665.542597 | Iain Reid                                                                                                                                                                            |
| 849 |     57.824230 |    115.110240 | Katie S. Collins                                                                                                                                                                     |
| 850 |    776.885466 |     36.059348 | Steven Traver                                                                                                                                                                        |
| 851 |    609.381285 |    732.006643 | Jagged Fang Designs                                                                                                                                                                  |
| 852 |    231.906347 |    166.851603 | Dmitry Bogdanov                                                                                                                                                                      |
| 853 |    437.680566 |    559.896268 | FJDegrange                                                                                                                                                                           |
| 854 |    506.113581 |    671.527369 | Margot Michaud                                                                                                                                                                       |
| 855 |    558.781106 |    167.814544 | Eyal Bartov                                                                                                                                                                          |
| 856 |    548.017020 |    664.547292 | Kailah Thorn & Mark Hutchinson                                                                                                                                                       |
| 857 |    944.516504 |    277.325870 | Margot Michaud                                                                                                                                                                       |
| 858 |    960.466360 |     73.577088 | Mathew Wedel                                                                                                                                                                         |
| 859 |     23.223605 |     40.994341 | Emily Jane McTavish, from <http://en.wikipedia.org/wiki/File:Coccolithus_pelagicus.jpg>                                                                                              |
| 860 |    287.194254 |    645.081886 | Joanna Wolfe                                                                                                                                                                         |
| 861 |    482.837542 |     63.886624 | Eduard Solà Vázquez, vectorised by Yan Wong                                                                                                                                          |
| 862 |    548.996510 |    624.739075 | Ignacio Contreras                                                                                                                                                                    |
| 863 |    771.954822 |     24.970546 | Scott Hartman                                                                                                                                                                        |
| 864 |    832.280373 |    108.250570 | Matt Dempsey                                                                                                                                                                         |
| 865 |     92.671507 |    701.341969 | Andy Wilson                                                                                                                                                                          |
| 866 |    795.576529 |    675.950927 | Mathew Wedel                                                                                                                                                                         |
| 867 |    220.952546 |     36.602064 | NA                                                                                                                                                                                   |
| 868 |    461.789907 |    312.784321 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 869 |   1010.230802 |    165.763092 | NA                                                                                                                                                                                   |
| 870 |    513.600959 |    712.819856 | B. Duygu Özpolat                                                                                                                                                                     |
| 871 |    414.870538 |    564.168329 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                                       |
| 872 |     30.921976 |    256.166391 | Gareth Monger                                                                                                                                                                        |
| 873 |    863.854455 |    545.719243 | Michelle Site                                                                                                                                                                        |
| 874 |    605.645558 |    264.252698 | Michelle Site                                                                                                                                                                        |
| 875 |    284.315438 |    573.318295 | Kailah Thorn & Mark Hutchinson                                                                                                                                                       |
| 876 |    785.726911 |     78.293548 | Scott Hartman                                                                                                                                                                        |
| 877 |    408.567073 |    569.939063 | \<U+0414\>\<U+0438\>\<U+0411\>\<U+0433\>\<U+0434\> (vectorized by T. Michael Keesey)                                                                                                 |
| 878 |    505.830470 |    495.287082 | Mali’o Kodis, image from Brockhaus and Efron Encyclopedic Dictionary                                                                                                                 |
| 879 |    751.239007 |    282.057479 | Burton Robert, USFWS                                                                                                                                                                 |
| 880 |    338.970545 |    642.316253 | Melissa Broussard                                                                                                                                                                    |
| 881 |    607.055444 |    172.861227 | Jagged Fang Designs                                                                                                                                                                  |
| 882 |    120.962329 |    742.551706 | Yan Wong                                                                                                                                                                             |
| 883 |    536.073353 |    169.281818 | Matt Crook                                                                                                                                                                           |
| 884 |    178.351210 |    388.839591 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 885 |    115.270254 |     43.957518 | Chloé Schmidt                                                                                                                                                                        |
| 886 |    466.701194 |    455.936120 | Michael B. H. (vectorized by T. Michael Keesey)                                                                                                                                      |
| 887 |   1014.087120 |    427.226897 | Gustav Mützel                                                                                                                                                                        |
| 888 |    484.294074 |    502.970256 | SauropodomorphMonarch                                                                                                                                                                |
| 889 |    535.348405 |    705.222313 | Original drawing by Antonov, vectorized by Roberto Díaz Sibaja                                                                                                                       |
| 890 |     79.334542 |    137.150046 | Campbell Fleming                                                                                                                                                                     |
| 891 |    192.506586 |    268.623306 | Becky Barnes                                                                                                                                                                         |
| 892 |    959.112369 |     38.199726 | T. Michael Keesey                                                                                                                                                                    |
| 893 |    448.291313 |    173.023775 | Matt Crook                                                                                                                                                                           |
| 894 |    837.019700 |    565.615865 | Ferran Sayol                                                                                                                                                                         |
| 895 |    773.827881 |    389.736116 | Gareth Monger                                                                                                                                                                        |
| 896 |    353.513234 |      3.317303 | Gareth Monger                                                                                                                                                                        |
| 897 |    888.614294 |    460.339150 | Noah Schlottman, photo by Martin V. Sørensen                                                                                                                                         |
| 898 |    745.229412 |    723.528106 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 899 |    424.016098 |    499.454693 | Iain Reid                                                                                                                                                                            |
| 900 |    999.640220 |    687.430506 | Jagged Fang Designs                                                                                                                                                                  |
| 901 |    418.673062 |    760.504168 | NA                                                                                                                                                                                   |
| 902 |    536.527410 |    194.229355 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 903 |    684.520498 |    477.995144 | Matt Crook                                                                                                                                                                           |
| 904 |     63.624469 |    533.523568 | Matt Crook                                                                                                                                                                           |
| 905 |     74.020850 |    597.819448 | Mark Witton                                                                                                                                                                          |
| 906 |    759.405814 |     50.297414 | Kamil S. Jaron                                                                                                                                                                       |
| 907 |    688.793525 |    344.462805 | Tasman Dixon                                                                                                                                                                         |
| 908 |    392.631423 |    519.365714 | Ferran Sayol                                                                                                                                                                         |
| 909 |    710.205166 |    343.190635 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 910 |     60.447549 |    590.772603 | Margot Michaud                                                                                                                                                                       |
| 911 |    415.862543 |    142.725057 | Steven Traver                                                                                                                                                                        |
| 912 |    965.838560 |    294.718595 | Steven Traver                                                                                                                                                                        |
| 913 |    219.514353 |    428.562145 | Matt Crook                                                                                                                                                                           |
| 914 |    840.372115 |    533.112471 | Brian Swartz (vectorized by T. Michael Keesey)                                                                                                                                       |
| 915 |    355.862726 |    379.002947 | Skye M                                                                                                                                                                               |
| 916 |    347.382718 |    709.178348 | Gareth Monger                                                                                                                                                                        |
| 917 |     40.374274 |    571.291121 | Chris Hay                                                                                                                                                                            |
| 918 |    799.102997 |    212.286032 | Ferran Sayol                                                                                                                                                                         |
| 919 |    986.174741 |    296.736671 | Tauana J. Cunha                                                                                                                                                                      |
| 920 |    954.625907 |    676.049671 | Maija Karala                                                                                                                                                                         |

    #> Your tweet has been posted!
