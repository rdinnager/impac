
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

Jagged Fang Designs, Steven Traver, Emily Willoughby, NOAA (vectorized
by T. Michael Keesey), Juan Carlos Jerí, Dean Schnabel, Marie Russell,
Gareth Monger, Matt Crook, Rachel Shoop, Zimices, Maija Karala, Steven
Coombs, Kent Elson Sorgon, Ghedoghedo (vectorized by T. Michael Keesey),
Martin R. Smith, Rebecca Groom, Cristopher Silva, Ferran Sayol,
Terpsichores, T. Tischler, Margot Michaud, Jaime Headden, Noah
Schlottman, photo by Reinhard Jahn, Andrew A. Farke, Jonathan Wells,
Robert Bruce Horsfall, vectorized by Zimices, Scott Hartman, C. Camilo
Julián-Caballero, Kai R. Caspar, Eduard Solà (vectorized by T. Michael
Keesey), Matt Martyniuk, NASA, Chris huh, Jan Sevcik (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Christoph
Schomburg, Derek Bakken (photograph) and T. Michael Keesey
(vectorization), Matt Martyniuk (vectorized by T. Michael Keesey), T.
Michael Keesey (after Mauricio Antón), Neil Kelley, Gabriela
Palomo-Munoz, Mali’o Kodis, image from the Smithsonian Institution,
Mathieu Basille, Lee Harding (photo), John E. McCormack, Michael G.
Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb
T. Brumfield & T. Michael Keesey, Joanna Wolfe, Rene Martin, Tasman
Dixon, FunkMonk, Benchill, T. Michael Keesey, Sebastian Stabinger, Felix
Vaux, I. Geoffroy Saint-Hilaire (vectorized by T. Michael Keesey), Tracy
A. Heath, Beth Reinke, Ville-Veikko Sinkkonen, Michael Scroggie, Pedro
de Siracusa, Birgit Lang, LeonardoG (photography) and T. Michael Keesey
(vectorization), Dmitry Bogdanov (vectorized by T. Michael Keesey),
Ludwik Gasiorowski, Alex Slavenko, Becky Barnes, Jan A. Venter, Herbert
H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael
Keesey), Melissa Broussard, Hans Hillewaert (vectorized by T. Michael
Keesey), Oliver Griffith, Ben Liebeskind, Mariana Ruiz (vectorized by T.
Michael Keesey), Oscar Sanisidro, Thibaut Brunet, Robbie N. Cada
(vectorized by T. Michael Keesey), T. Michael Keesey (photo by Darren
Swim), Greg Schechter (original photo), Renato Santos (vector
silhouette), Andreas Hejnol, Crystal Maier, Kamil S. Jaron, Ewald
Rübsamen, Nobu Tamura (vectorized by T. Michael Keesey), Brian
Gratwicke (photo) and T. Michael Keesey (vectorization), Meliponicultor
Itaymbere, Bruno C. Vellutini, Kailah Thorn & Mark Hutchinson, Shyamal,
Alexandre Vong, Frank Förster (based on a picture by Hans Hillewaert),
DW Bapst (Modified from photograph taken by Charles Mitchell), Francesco
“Architetto” Rollandin, James R. Spotila and Ray Chatterji, Michele M
Tobias, Jimmy Bernot, Cesar Julian, Hans Hillewaert, Sean McCann,
Lafage, Josefine Bohr Brask, Lukasiniho, Ghedo (vectorized by T. Michael
Keesey), Yan Wong from photo by Denes Emoke, Bennet McComish, photo by
Hans Hillewaert, Yan Wong, DW Bapst, modified from Figure 1 of Belanger
(2011, PALAIOS)., George Edward Lodge (vectorized by T. Michael Keesey),
Dann Pigdon, Gordon E. Robertson, John Conway, Scott Reid, Harold N
Eyster, Lankester Edwin Ray (vectorized by T. Michael Keesey), Sarah
Alewijnse, Katie S. Collins, Alyssa Bell & Luis Chiappe 2015,
dx.doi.org/10.1371/journal.pone.0141690, Zachary Quigley, Alexander
Schmidt-Lebuhn, Tomas Willems (vectorized by T. Michael Keesey),
FJDegrange, Jake Warner, Robert Gay, modifed from Olegivvit, Brad
McFeeters (vectorized by T. Michael Keesey), xgirouxb, Obsidian Soul
(vectorized by T. Michael Keesey), Mariana Ruiz Villarreal (modified by
T. Michael Keesey), Collin Gross, Dmitry Bogdanov, Sarah Werning,
Michael P. Taylor, Carlos Cano-Barbacil, , Abraão Leite, Falconaumanni
and T. Michael Keesey, Steven Haddock • Jellywatch.org, Christopher
Watson (photo) and T. Michael Keesey (vectorization), Tauana J. Cunha,
Yan Wong from photo by Gyik Toma, David Sim (photograph) and T. Michael
Keesey (vectorization), Ernst Haeckel (vectorized by T. Michael Keesey),
Anthony Caravaggi, Darius Nau, Jesús Gómez, vectorized by Zimices, Aline
M. Ghilardi, Caroline Harding, MAF (vectorized by T. Michael Keesey),
Iain Reid, T. Michael Keesey (vectorization) and HuttyMcphoo
(photography), Mali’o Kodis, image from Higgins and Kristensen, 1986,
Lukas Panzarin, Nobu Tamura, Emil Schmidt (vectorized by Maxime
Dahirel), Mathew Stewart, L. Shyamal, Tyler McCraney, Michael Scroggie,
from original photograph by Gary M. Stolz, USFWS (original photograph in
public domain)., Apokryltaros (vectorized by T. Michael Keesey), M
Kolmann, Stanton F. Fink (vectorized by T. Michael Keesey),
Benjamint444, S.Martini, Danielle Alba, Craig Dylke, U.S. Fish and
Wildlife Service (illustration) and Timothy J. Bartley (silhouette),
Mali’o Kodis, photograph property of National Museums of Northern
Ireland, SecretJellyMan, Didier Descouens (vectorized by T. Michael
Keesey), kotik, Smokeybjb (modified by T. Michael Keesey), Alexis Simon,
Roberto Díaz Sibaja, Sergio A. Muñoz-Gómez, Jessica Anne Miller, George
Edward Lodge, Tony Ayling, Robert Gay, modified from FunkMonk (Michael
B.H.) and T. Michael Keesey., Ingo Braasch, Nobu Tamura, vectorized by
Zimices, Ian Burt (original) and T. Michael Keesey (vectorization), Dein
Freund der Baum (vectorized by T. Michael Keesey), Daniel Stadtmauer, I.
Sácek, Sr. (vectorized by T. Michael Keesey), T. Michael Keesey (after
Mivart), Arthur S. Brum, Mali’o Kodis, photograph from
<http://commons.wikimedia.org/wiki/File:Trichoplax.jpg>, Xavier
Giroux-Bougard, Patrick Strutzenberger, Michelle Site, M. Garfield & K.
Anderson (modified by T. Michael Keesey), Mathew Wedel, H. F. O. March
(vectorized by T. Michael Keesey), RS, Ville Koistinen and T. Michael
Keesey, Luc Viatour (source photo) and Andreas Plank, Robert Gay,
Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja,
SecretJellyMan - from Mason McNair, Chris Jennings (vectorized by A.
Verrière), Andrew A. Farke, modified from original by H. Milne Edwards,
Ryan Cupo, Mr E? (vectorized by T. Michael Keesey), Unknown (photo),
John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G.
Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Danny
Cicchetti (vectorized by T. Michael Keesey), Emily Jane McTavish, from
Haeckel, E. H. P. A. (1904).Kunstformen der Natur. Bibliographisches,
Milton Tan, Noah Schlottman, photo by Casey Dunn, Javiera Constanzo,
Maxime Dahirel, Frank Förster, Campbell Fleming, Duane Raver (vectorized
by T. Michael Keesey), Ben Moon, Smokeybjb, Tim Bertelink (modified by
T. Michael Keesey), Noah Schlottman, Darren Naish (vectorized by T.
Michael Keesey), Darren Naish (vectorize by T. Michael Keesey), Scott D.
Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A.
Forster, Joshua A. Smith, Alan L. Titus, Karkemish (vectorized by T.
Michael Keesey), Jose Carlos Arenas-Monroy, Jerry Oldenettel (vectorized
by T. Michael Keesey), Matthew E. Clapham, Sarefo (vectorized by T.
Michael Keesey), Curtis Clark and T. Michael Keesey, Warren H
(photography), T. Michael Keesey (vectorization), Javier Luque, Caleb M.
Brown, JJ Harrison (vectorized by T. Michael Keesey), Estelle Bourdon,
Joris van der Ham (vectorized by T. Michael Keesey), Chloé Schmidt,
Conty (vectorized by T. Michael Keesey), Nobu Tamura (vectorized by A.
Verrière), Noah Schlottman, photo by Antonio Guillén, Henry Fairfield
Osborn, vectorized by Zimices, Armelle Ansart (photograph), Maxime
Dahirel (digitisation), T. Michael Keesey (after Joseph Wolf), Robert
Bruce Horsfall, from W.B. Scott’s 1912 “A History of Land Mammals in the
Western Hemisphere”, Pranav Iyer (grey ideas), Gustav Mützel, Sidney
Frederic Harmer, Arthur Everett Shipley (vectorized by Maxime Dahirel),
Jaime Headden (vectorized by T. Michael Keesey), Nobu Tamura, modified
by Andrew A. Farke, T. Michael Keesey (after MPF), Lauren Sumner-Rooney,
Mario Quevedo, Tyler Greenfield, John Curtis (vectorized by T. Michael
Keesey), Matt Hayes, A. H. Baldwin (vectorized by T. Michael Keesey),
Maxwell Lefroy (vectorized by T. Michael Keesey), Jakovche, Anilocra
(vectorization by Yan Wong), Claus Rebler, T. Michael Keesey
(vectorization); Thorsten Assmann, Jörn Buse, Claudia Drees,
Ariel-Leib-Leonid Friedman, Tal Levanony, Andrea Matern, Anika Timm, and
David W. Wrase (photography), Oliver Voigt, Richard J. Harris, Plukenet,
Tess Linden, CNZdenek, MPF (vectorized by T. Michael Keesey), Matt
Celeskey, Archaeodontosaurus (vectorized by T. Michael Keesey), Mali’o
Kodis, photograph from Jersabek et al, 2003, Louis Ranjard, Smokeybjb
(vectorized by T. Michael Keesey), Jack Mayer Wood, Mali’o Kodis,
photograph by G. Giribet, Douglas Brown (modified by T. Michael Keesey),
DW Bapst (Modified from Bulman, 1964), Eduard Solà Vázquez, vectorised
by Yan Wong, Sharon Wegner-Larsen, Lily Hughes

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                               |
| --: | ------------: | ------------: | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    779.611652 |    782.336837 | Jagged Fang Designs                                                                                                                                                                  |
|   2 |    203.491136 |    558.806178 | Steven Traver                                                                                                                                                                        |
|   3 |     94.359542 |    619.604403 | NA                                                                                                                                                                                   |
|   4 |    216.575873 |    372.784483 | Emily Willoughby                                                                                                                                                                     |
|   5 |    129.281397 |    130.709175 | NOAA (vectorized by T. Michael Keesey)                                                                                                                                               |
|   6 |    215.741644 |     89.686219 | Steven Traver                                                                                                                                                                        |
|   7 |    905.731913 |    520.250762 | Juan Carlos Jerí                                                                                                                                                                     |
|   8 |    410.370733 |    204.343644 | Steven Traver                                                                                                                                                                        |
|   9 |    961.766442 |     88.117186 | NA                                                                                                                                                                                   |
|  10 |    176.083884 |    230.304759 | Dean Schnabel                                                                                                                                                                        |
|  11 |    904.651269 |    685.234303 | Marie Russell                                                                                                                                                                        |
|  12 |    608.915998 |    321.660527 | Gareth Monger                                                                                                                                                                        |
|  13 |    462.376097 |    568.859928 | Matt Crook                                                                                                                                                                           |
|  14 |    609.811932 |    715.184820 | Steven Traver                                                                                                                                                                        |
|  15 |    101.727294 |    412.882472 | Rachel Shoop                                                                                                                                                                         |
|  16 |    423.919316 |     81.466132 | Zimices                                                                                                                                                                              |
|  17 |    717.990535 |    481.380550 | Maija Karala                                                                                                                                                                         |
|  18 |    919.265284 |    756.196631 | Steven Coombs                                                                                                                                                                        |
|  19 |    851.188514 |    310.662683 | Kent Elson Sorgon                                                                                                                                                                    |
|  20 |    716.627843 |    170.210048 | Matt Crook                                                                                                                                                                           |
|  21 |    836.527525 |    357.343612 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                                         |
|  22 |    419.661386 |    394.346090 | Martin R. Smith                                                                                                                                                                      |
|  23 |    112.289985 |    763.125600 | Rebecca Groom                                                                                                                                                                        |
|  24 |    651.899744 |     43.151843 | Cristopher Silva                                                                                                                                                                     |
|  25 |    300.604470 |    190.584089 | Ferran Sayol                                                                                                                                                                         |
|  26 |    770.961110 |    600.906252 | Terpsichores                                                                                                                                                                         |
|  27 |     84.957642 |    289.771392 | T. Tischler                                                                                                                                                                          |
|  28 |    529.350591 |    764.336358 | Margot Michaud                                                                                                                                                                       |
|  29 |    329.677222 |    300.688109 | Ferran Sayol                                                                                                                                                                         |
|  30 |    566.113840 |    126.358041 | Margot Michaud                                                                                                                                                                       |
|  31 |    293.262163 |    479.014059 | Jaime Headden                                                                                                                                                                        |
|  32 |    849.446443 |    421.926291 | Noah Schlottman, photo by Reinhard Jahn                                                                                                                                              |
|  33 |    427.369390 |    268.185209 | Andrew A. Farke                                                                                                                                                                      |
|  34 |    904.006903 |    163.593882 | Jonathan Wells                                                                                                                                                                       |
|  35 |    328.101418 |    138.988971 | NA                                                                                                                                                                                   |
|  36 |    751.873329 |    735.123615 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                                         |
|  37 |    968.986544 |    224.372361 | Andrew A. Farke                                                                                                                                                                      |
|  38 |    127.825566 |    335.344307 | Scott Hartman                                                                                                                                                                        |
|  39 |    185.019709 |    715.975901 | C. Camilo Julián-Caballero                                                                                                                                                           |
|  40 |    868.912149 |    229.598094 | NA                                                                                                                                                                                   |
|  41 |    317.954181 |    407.173962 | Kai R. Caspar                                                                                                                                                                        |
|  42 |    793.047646 |     52.743025 | Zimices                                                                                                                                                                              |
|  43 |    891.538304 |    619.296958 | Eduard Solà (vectorized by T. Michael Keesey)                                                                                                                                        |
|  44 |    133.366763 |    472.638708 | Matt Crook                                                                                                                                                                           |
|  45 |    963.779938 |    437.067365 | Margot Michaud                                                                                                                                                                       |
|  46 |    580.755847 |    648.867460 | Gareth Monger                                                                                                                                                                        |
|  47 |     82.744231 |     79.804653 | Matt Martyniuk                                                                                                                                                                       |
|  48 |    165.746046 |    493.824485 | C. Camilo Julián-Caballero                                                                                                                                                           |
|  49 |    530.996232 |    206.434097 | Emily Willoughby                                                                                                                                                                     |
|  50 |    184.358708 |     27.176579 | Steven Coombs                                                                                                                                                                        |
|  51 |    997.848210 |    655.299484 | NASA                                                                                                                                                                                 |
|  52 |    338.933028 |    779.019142 | Chris huh                                                                                                                                                                            |
|  53 |    717.367951 |    425.147229 | Zimices                                                                                                                                                                              |
|  54 |    213.868966 |    631.975577 | Jan Sevcik (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                           |
|  55 |    498.566935 |     12.639373 | Scott Hartman                                                                                                                                                                        |
|  56 |    896.312550 |     61.414708 | Christoph Schomburg                                                                                                                                                                  |
|  57 |    593.749050 |     93.620994 | Derek Bakken (photograph) and T. Michael Keesey (vectorization)                                                                                                                      |
|  58 |    240.758924 |    202.709512 | Chris huh                                                                                                                                                                            |
|  59 |    862.138917 |    782.650763 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                                     |
|  60 |    409.013589 |    304.736835 | T. Michael Keesey (after Mauricio Antón)                                                                                                                                             |
|  61 |    690.590871 |    553.509606 | Neil Kelley                                                                                                                                                                          |
|  62 |    788.592949 |    529.439333 | Gabriela Palomo-Munoz                                                                                                                                                                |
|  63 |    207.081526 |    777.264505 | Mali’o Kodis, image from the Smithsonian Institution                                                                                                                                 |
|  64 |    172.486639 |    363.247620 | Matt Crook                                                                                                                                                                           |
|  65 |    296.687278 |    677.798924 | Mathieu Basille                                                                                                                                                                      |
|  66 |    773.976911 |    668.896722 | Lee Harding (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                          |
|  67 |    610.135432 |    778.901167 | Chris huh                                                                                                                                                                            |
|  68 |    849.166017 |    252.801676 | Joanna Wolfe                                                                                                                                                                         |
|  69 |     64.711721 |    480.794427 | Matt Crook                                                                                                                                                                           |
|  70 |    765.055878 |     17.504273 | NA                                                                                                                                                                                   |
|  71 |    311.027666 |     87.333247 | Rene Martin                                                                                                                                                                          |
|  72 |    822.667424 |    509.001396 | Tasman Dixon                                                                                                                                                                         |
|  73 |     66.437151 |    262.812856 | Jaime Headden                                                                                                                                                                        |
|  74 |    997.886509 |    791.258065 | Christoph Schomburg                                                                                                                                                                  |
|  75 |    446.190044 |    656.487607 | Margot Michaud                                                                                                                                                                       |
|  76 |    818.737168 |     86.362348 | FunkMonk                                                                                                                                                                             |
|  77 |     49.799264 |    214.254727 | Benchill                                                                                                                                                                             |
|  78 |     31.873598 |    625.937205 | T. Michael Keesey                                                                                                                                                                    |
|  79 |    518.931357 |    591.025239 | Sebastian Stabinger                                                                                                                                                                  |
|  80 |    976.805512 |    346.237009 | Felix Vaux                                                                                                                                                                           |
|  81 |    478.345883 |    406.982944 | I. Geoffroy Saint-Hilaire (vectorized by T. Michael Keesey)                                                                                                                          |
|  82 |    787.600246 |    457.168416 | Tracy A. Heath                                                                                                                                                                       |
|  83 |    629.395333 |    431.690085 | Ferran Sayol                                                                                                                                                                         |
|  84 |     14.398537 |    130.294721 | Beth Reinke                                                                                                                                                                          |
|  85 |    372.279685 |    121.336815 | Ville-Veikko Sinkkonen                                                                                                                                                               |
|  86 |     20.188386 |    176.171625 | Michael Scroggie                                                                                                                                                                     |
|  87 |     58.176725 |    710.537056 | Beth Reinke                                                                                                                                                                          |
|  88 |     36.259195 |     29.791609 | Pedro de Siracusa                                                                                                                                                                    |
|  89 |    504.128222 |    456.287325 | Scott Hartman                                                                                                                                                                        |
|  90 |    437.535836 |    721.529355 | Zimices                                                                                                                                                                              |
|  91 |    461.642512 |    334.359849 | Gareth Monger                                                                                                                                                                        |
|  92 |    794.193992 |     83.488091 | Birgit Lang                                                                                                                                                                          |
|  93 |    356.042517 |    604.692832 | Tasman Dixon                                                                                                                                                                         |
|  94 |     39.275476 |    220.167907 | Emily Willoughby                                                                                                                                                                     |
|  95 |    586.022786 |    287.957352 | Matt Crook                                                                                                                                                                           |
|  96 |     45.139647 |    508.258352 | LeonardoG (photography) and T. Michael Keesey (vectorization)                                                                                                                        |
|  97 |    828.581478 |    738.753458 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
|  98 |    631.635593 |    571.713163 | Tracy A. Heath                                                                                                                                                                       |
|  99 |     62.803479 |    153.807064 | Andrew A. Farke                                                                                                                                                                      |
| 100 |    667.997188 |    636.537419 | Ludwik Gasiorowski                                                                                                                                                                   |
| 101 |    868.820871 |    245.900393 | Matt Crook                                                                                                                                                                           |
| 102 |    388.899983 |    739.273829 | Alex Slavenko                                                                                                                                                                        |
| 103 |    487.456454 |    343.904213 | Ferran Sayol                                                                                                                                                                         |
| 104 |    802.318977 |     17.318844 | T. Tischler                                                                                                                                                                          |
| 105 |     95.064463 |     10.095250 | Becky Barnes                                                                                                                                                                         |
| 106 |    271.990031 |    586.941447 | Scott Hartman                                                                                                                                                                        |
| 107 |    912.039409 |    394.176074 | Tracy A. Heath                                                                                                                                                                       |
| 108 |    911.640075 |    727.103361 | Gareth Monger                                                                                                                                                                        |
| 109 |    231.352611 |    788.526825 | T. Michael Keesey                                                                                                                                                                    |
| 110 |    211.548694 |    429.608321 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                                  |
| 111 |    953.017206 |     20.739117 | Melissa Broussard                                                                                                                                                                    |
| 112 |     89.766840 |    544.303405 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                                    |
| 113 |    833.745485 |    157.992845 | Matt Crook                                                                                                                                                                           |
| 114 |    707.311116 |    256.369282 | Oliver Griffith                                                                                                                                                                      |
| 115 |     56.446830 |    760.723757 | Gareth Monger                                                                                                                                                                        |
| 116 |    135.208802 |    536.191633 | Ben Liebeskind                                                                                                                                                                       |
| 117 |    391.572475 |    480.231181 | Zimices                                                                                                                                                                              |
| 118 |    338.976777 |    240.752305 | Gareth Monger                                                                                                                                                                        |
| 119 |     19.507554 |    720.922849 | Mariana Ruiz (vectorized by T. Michael Keesey)                                                                                                                                       |
| 120 |    863.751280 |     78.362888 | Oscar Sanisidro                                                                                                                                                                      |
| 121 |     75.430699 |    769.537119 | Emily Willoughby                                                                                                                                                                     |
| 122 |    252.570760 |    513.516004 | Scott Hartman                                                                                                                                                                        |
| 123 |    710.589983 |    165.738200 | Thibaut Brunet                                                                                                                                                                       |
| 124 |    151.015914 |    187.418335 | Matt Crook                                                                                                                                                                           |
| 125 |    241.685645 |    587.746451 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                                     |
| 126 |    747.873704 |    170.874809 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                                         |
| 127 |    190.125112 |    193.874812 | Scott Hartman                                                                                                                                                                        |
| 128 |    731.427959 |     18.392215 | Margot Michaud                                                                                                                                                                       |
| 129 |   1004.467328 |    576.687708 | NA                                                                                                                                                                                   |
| 130 |    483.794663 |    287.783999 | Chris huh                                                                                                                                                                            |
| 131 |     22.668849 |    568.804574 | T. Michael Keesey (photo by Darren Swim)                                                                                                                                             |
| 132 |    967.069485 |    305.130047 | Zimices                                                                                                                                                                              |
| 133 |    510.597077 |    532.761261 | Greg Schechter (original photo), Renato Santos (vector silhouette)                                                                                                                   |
| 134 |     14.987010 |    212.563745 | Andreas Hejnol                                                                                                                                                                       |
| 135 |     45.254973 |    525.027730 | Chris huh                                                                                                                                                                            |
| 136 |     19.838571 |    243.038759 | Crystal Maier                                                                                                                                                                        |
| 137 |    529.526619 |     40.978763 | Kamil S. Jaron                                                                                                                                                                       |
| 138 |    844.522856 |    131.414186 | Ewald Rübsamen                                                                                                                                                                       |
| 139 |     60.550403 |     30.884441 | Emily Willoughby                                                                                                                                                                     |
| 140 |     41.642956 |    418.685147 | Margot Michaud                                                                                                                                                                       |
| 141 |     75.122555 |    227.449906 | Joanna Wolfe                                                                                                                                                                         |
| 142 |     38.588445 |    477.673917 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                                    |
| 143 |    182.655488 |    751.103990 | Zimices                                                                                                                                                                              |
| 144 |    676.303547 |    583.811347 | Tasman Dixon                                                                                                                                                                         |
| 145 |    550.669231 |    401.108196 | Chris huh                                                                                                                                                                            |
| 146 |    225.785714 |     32.408141 | Margot Michaud                                                                                                                                                                       |
| 147 |    987.120282 |    766.171701 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 148 |    782.705324 |    615.871416 | Brian Gratwicke (photo) and T. Michael Keesey (vectorization)                                                                                                                        |
| 149 |     29.926505 |    311.405151 | Matt Crook                                                                                                                                                                           |
| 150 |    708.045967 |    387.289934 | Matt Crook                                                                                                                                                                           |
| 151 |    278.094029 |    530.041280 | Ferran Sayol                                                                                                                                                                         |
| 152 |    333.601694 |     47.818747 | T. Michael Keesey                                                                                                                                                                    |
| 153 |    982.537476 |     21.066271 | Emily Willoughby                                                                                                                                                                     |
| 154 |    217.768495 |    253.138195 | Oscar Sanisidro                                                                                                                                                                      |
| 155 |    827.474552 |    564.957825 | Meliponicultor Itaymbere                                                                                                                                                             |
| 156 |    236.704083 |    316.888579 | Gareth Monger                                                                                                                                                                        |
| 157 |    853.492303 |    522.483742 | Bruno C. Vellutini                                                                                                                                                                   |
| 158 |    152.102893 |    664.501637 | Kailah Thorn & Mark Hutchinson                                                                                                                                                       |
| 159 |    953.312440 |    141.743252 | Jagged Fang Designs                                                                                                                                                                  |
| 160 |    370.290545 |    278.967682 | Shyamal                                                                                                                                                                              |
| 161 |    318.314630 |    750.578451 | Alexandre Vong                                                                                                                                                                       |
| 162 |    173.818744 |    337.097582 | Jagged Fang Designs                                                                                                                                                                  |
| 163 |    719.759032 |    246.067065 | Frank Förster (based on a picture by Hans Hillewaert)                                                                                                                                |
| 164 |     24.154704 |    417.509889 | DW Bapst (Modified from photograph taken by Charles Mitchell)                                                                                                                        |
| 165 |    606.245025 |    416.965474 | Zimices                                                                                                                                                                              |
| 166 |    775.440378 |    688.210229 | Matt Crook                                                                                                                                                                           |
| 167 |    617.324715 |      8.576543 | FunkMonk                                                                                                                                                                             |
| 168 |    880.488576 |     98.684345 | Gareth Monger                                                                                                                                                                        |
| 169 |    336.555815 |    643.311359 | Rene Martin                                                                                                                                                                          |
| 170 |   1012.049182 |    443.800896 | Francesco “Architetto” Rollandin                                                                                                                                                     |
| 171 |   1012.455370 |    603.137522 | Birgit Lang                                                                                                                                                                          |
| 172 |    628.883273 |    245.922695 | Ferran Sayol                                                                                                                                                                         |
| 173 |    985.438978 |    471.438398 | Ferran Sayol                                                                                                                                                                         |
| 174 |    737.694287 |    290.211552 | James R. Spotila and Ray Chatterji                                                                                                                                                   |
| 175 |    749.785950 |    256.280832 | Dean Schnabel                                                                                                                                                                        |
| 176 |    945.172832 |    207.760708 | Jagged Fang Designs                                                                                                                                                                  |
| 177 |     69.447725 |    166.124921 | Margot Michaud                                                                                                                                                                       |
| 178 |    650.872374 |    676.194251 | Michele M Tobias                                                                                                                                                                     |
| 179 |    747.247130 |    618.163826 | Zimices                                                                                                                                                                              |
| 180 |    195.447962 |    614.819457 | Zimices                                                                                                                                                                              |
| 181 |   1002.705576 |    738.272557 | Jimmy Bernot                                                                                                                                                                         |
| 182 |    799.738884 |    739.788936 | Ferran Sayol                                                                                                                                                                         |
| 183 |    979.358021 |    372.549033 | Matt Martyniuk                                                                                                                                                                       |
| 184 |     11.167601 |    559.395127 | T. Michael Keesey                                                                                                                                                                    |
| 185 |    419.146101 |    312.658268 | NA                                                                                                                                                                                   |
| 186 |    759.632419 |    452.972770 | Zimices                                                                                                                                                                              |
| 187 |    608.196348 |    203.181309 | Cesar Julian                                                                                                                                                                         |
| 188 |    545.613858 |    246.703063 | Scott Hartman                                                                                                                                                                        |
| 189 |    368.887777 |    227.316719 | Hans Hillewaert                                                                                                                                                                      |
| 190 |    313.111322 |    568.775766 | Tasman Dixon                                                                                                                                                                         |
| 191 |    529.447818 |    226.891654 | Felix Vaux                                                                                                                                                                           |
| 192 |    731.723800 |    315.867776 | Sean McCann                                                                                                                                                                          |
| 193 |    625.874862 |    496.874571 | Chris huh                                                                                                                                                                            |
| 194 |    912.397746 |    794.572918 | Margot Michaud                                                                                                                                                                       |
| 195 |    172.672548 |     86.781841 | Margot Michaud                                                                                                                                                                       |
| 196 |    559.631570 |    554.013208 | Ferran Sayol                                                                                                                                                                         |
| 197 |    900.618645 |    428.332717 | Lafage                                                                                                                                                                               |
| 198 |    327.750640 |    442.335183 | Josefine Bohr Brask                                                                                                                                                                  |
| 199 |    199.383123 |    435.200534 | Lukasiniho                                                                                                                                                                           |
| 200 |    482.590847 |    310.058126 | Scott Hartman                                                                                                                                                                        |
| 201 |    861.070464 |    179.189287 | Ghedo (vectorized by T. Michael Keesey)                                                                                                                                              |
| 202 |    652.808636 |    472.088626 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 203 |     82.404748 |    699.119331 | Yan Wong from photo by Denes Emoke                                                                                                                                                   |
| 204 |    814.191661 |     95.869497 | FunkMonk                                                                                                                                                                             |
| 205 |    328.362291 |    159.522734 | Gareth Monger                                                                                                                                                                        |
| 206 |    750.551140 |    347.961140 | Gareth Monger                                                                                                                                                                        |
| 207 |     94.489328 |    688.275540 | Margot Michaud                                                                                                                                                                       |
| 208 |    374.665324 |      8.622358 | Christoph Schomburg                                                                                                                                                                  |
| 209 |    331.391929 |    514.440873 | Zimices                                                                                                                                                                              |
| 210 |    553.440319 |    353.456924 | Bennet McComish, photo by Hans Hillewaert                                                                                                                                            |
| 211 |    527.160118 |    577.238390 | Joanna Wolfe                                                                                                                                                                         |
| 212 |    107.484317 |    500.880712 | Scott Hartman                                                                                                                                                                        |
| 213 |    805.825129 |    338.510784 | Dean Schnabel                                                                                                                                                                        |
| 214 |    972.855700 |    579.164388 | Margot Michaud                                                                                                                                                                       |
| 215 |     97.438600 |    313.031164 | Yan Wong                                                                                                                                                                             |
| 216 |    330.852901 |    666.528839 | Margot Michaud                                                                                                                                                                       |
| 217 |    571.586404 |    533.004949 | NA                                                                                                                                                                                   |
| 218 |    286.881456 |    757.878371 | NA                                                                                                                                                                                   |
| 219 |    802.386806 |    485.242284 | DW Bapst, modified from Figure 1 of Belanger (2011, PALAIOS).                                                                                                                        |
| 220 |    615.064219 |    593.211334 | George Edward Lodge (vectorized by T. Michael Keesey)                                                                                                                                |
| 221 |    650.961994 |    784.021000 | Dann Pigdon                                                                                                                                                                          |
| 222 |     79.807927 |    256.404509 | Zimices                                                                                                                                                                              |
| 223 |   1016.319599 |    546.144630 | Gareth Monger                                                                                                                                                                        |
| 224 |    192.368568 |    782.207269 | Ewald Rübsamen                                                                                                                                                                       |
| 225 |   1015.976070 |    526.847415 | Ferran Sayol                                                                                                                                                                         |
| 226 |    930.324045 |    341.059735 | Ferran Sayol                                                                                                                                                                         |
| 227 |    183.858312 |    131.374537 | Gordon E. Robertson                                                                                                                                                                  |
| 228 |    512.933833 |    339.120098 | Ferran Sayol                                                                                                                                                                         |
| 229 |    919.253766 |     94.007922 | Steven Traver                                                                                                                                                                        |
| 230 |    218.347618 |    300.544131 | Zimices                                                                                                                                                                              |
| 231 |    138.870712 |    361.853399 | John Conway                                                                                                                                                                          |
| 232 |    991.055200 |    505.152554 | Steven Traver                                                                                                                                                                        |
| 233 |    304.968146 |    261.423997 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 234 |    744.688839 |    384.640979 | Chris huh                                                                                                                                                                            |
| 235 |    531.414641 |    140.499221 | Tasman Dixon                                                                                                                                                                         |
| 236 |    353.945411 |     64.741645 | Jaime Headden                                                                                                                                                                        |
| 237 |     19.544675 |    286.985881 | NA                                                                                                                                                                                   |
| 238 |   1016.325446 |    376.882625 | Scott Reid                                                                                                                                                                           |
| 239 |     27.145758 |    654.215499 | Margot Michaud                                                                                                                                                                       |
| 240 |    688.648939 |    527.436404 | NA                                                                                                                                                                                   |
| 241 |    913.977814 |    593.419757 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                                         |
| 242 |    686.482317 |     85.524830 | Emily Willoughby                                                                                                                                                                     |
| 243 |    369.433583 |    760.899944 | Harold N Eyster                                                                                                                                                                      |
| 244 |    510.502944 |    164.891165 | NA                                                                                                                                                                                   |
| 245 |    541.523706 |    178.156906 | Dean Schnabel                                                                                                                                                                        |
| 246 |    763.956043 |    670.358726 | Ferran Sayol                                                                                                                                                                         |
| 247 |    723.520665 |    145.558954 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                                                |
| 248 |    938.484553 |     40.507686 | Mali’o Kodis, image from the Smithsonian Institution                                                                                                                                 |
| 249 |    389.974657 |    120.956721 | Sarah Alewijnse                                                                                                                                                                      |
| 250 |    768.506744 |    441.957291 | Matt Crook                                                                                                                                                                           |
| 251 |    291.564561 |    531.109019 | Katie S. Collins                                                                                                                                                                     |
| 252 |    225.887364 |    188.532614 | Michael Scroggie                                                                                                                                                                     |
| 253 |    643.861368 |    616.706846 | Ferran Sayol                                                                                                                                                                         |
| 254 |   1008.865062 |    161.626048 | Jagged Fang Designs                                                                                                                                                                  |
| 255 |    625.062580 |    120.561382 | Jagged Fang Designs                                                                                                                                                                  |
| 256 |    776.045216 |    650.734072 | Tasman Dixon                                                                                                                                                                         |
| 257 |    888.778201 |    105.715894 | Matt Crook                                                                                                                                                                           |
| 258 |    236.322789 |    537.515153 | Margot Michaud                                                                                                                                                                       |
| 259 |    767.049813 |    286.661463 | Alex Slavenko                                                                                                                                                                        |
| 260 |    772.308203 |    224.027916 | Alyssa Bell & Luis Chiappe 2015, dx.doi.org/10.1371/journal.pone.0141690                                                                                                             |
| 261 |    444.082218 |    749.783648 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 262 |    765.808070 |    265.385261 | Emily Willoughby                                                                                                                                                                     |
| 263 |    443.292304 |    528.285324 | Bruno C. Vellutini                                                                                                                                                                   |
| 264 |    747.621366 |    507.147391 | Emily Willoughby                                                                                                                                                                     |
| 265 |    605.561077 |    493.840806 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 266 |    828.203882 |    714.249223 | Matt Crook                                                                                                                                                                           |
| 267 |    621.033217 |    469.634649 | Dean Schnabel                                                                                                                                                                        |
| 268 |    885.530898 |    399.940680 | Zimices                                                                                                                                                                              |
| 269 |    422.850112 |    531.883778 | T. Michael Keesey                                                                                                                                                                    |
| 270 |     13.381098 |     26.701168 | Joanna Wolfe                                                                                                                                                                         |
| 271 |   1009.270928 |    319.877495 | Zachary Quigley                                                                                                                                                                      |
| 272 |    374.089642 |    285.210123 | Scott Hartman                                                                                                                                                                        |
| 273 |   1003.156077 |    770.207982 | Zimices                                                                                                                                                                              |
| 274 |    430.215405 |    229.435155 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 275 |     65.441937 |    637.826709 | Tomas Willems (vectorized by T. Michael Keesey)                                                                                                                                      |
| 276 |    295.000791 |    746.724199 | FJDegrange                                                                                                                                                                           |
| 277 |    182.082548 |    268.402700 | Meliponicultor Itaymbere                                                                                                                                                             |
| 278 |    337.325588 |    497.577682 | Matt Crook                                                                                                                                                                           |
| 279 |    804.319938 |    274.828820 | Jake Warner                                                                                                                                                                          |
| 280 |    355.078610 |    737.276905 | Robert Gay, modifed from Olegivvit                                                                                                                                                   |
| 281 |    619.898761 |    312.790759 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                                     |
| 282 |    116.698034 |    567.359125 | Ferran Sayol                                                                                                                                                                         |
| 283 |    778.389569 |    508.109971 | xgirouxb                                                                                                                                                                             |
| 284 |    318.325251 |    452.995826 | Margot Michaud                                                                                                                                                                       |
| 285 |    716.716746 |    270.751190 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                                      |
| 286 |    683.183976 |    754.050144 | NA                                                                                                                                                                                   |
| 287 |    286.961665 |    440.341837 | Harold N Eyster                                                                                                                                                                      |
| 288 |    421.030895 |    546.802764 | Zimices                                                                                                                                                                              |
| 289 |    880.240401 |    499.386411 | Mariana Ruiz Villarreal (modified by T. Michael Keesey)                                                                                                                              |
| 290 |    237.423766 |    268.347666 | NA                                                                                                                                                                                   |
| 291 |    260.952251 |    776.868135 | Melissa Broussard                                                                                                                                                                    |
| 292 |    792.469728 |    168.200592 | Lafage                                                                                                                                                                               |
| 293 |     92.232258 |    495.206540 | Matt Martyniuk                                                                                                                                                                       |
| 294 |    883.258848 |    644.910155 | Collin Gross                                                                                                                                                                         |
| 295 |    943.864496 |    145.790853 | Dmitry Bogdanov                                                                                                                                                                      |
| 296 |    672.468352 |    566.647497 | Sarah Werning                                                                                                                                                                        |
| 297 |    978.367740 |    299.528577 | Michael P. Taylor                                                                                                                                                                    |
| 298 |    827.061618 |    788.453291 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 299 |    449.474456 |     11.776709 | NA                                                                                                                                                                                   |
| 300 |    877.321858 |    469.704867 |                                                                                                                                                                                      |
| 301 |    490.416355 |    248.546356 | Zimices                                                                                                                                                                              |
| 302 |    717.693641 |    337.250870 | Christoph Schomburg                                                                                                                                                                  |
| 303 |    644.861260 |    209.042643 | Abraão Leite                                                                                                                                                                         |
| 304 |     32.349590 |    682.135823 | Dean Schnabel                                                                                                                                                                        |
| 305 |    351.249992 |    586.336104 | Zimices                                                                                                                                                                              |
| 306 |    369.771322 |    246.369906 | Falconaumanni and T. Michael Keesey                                                                                                                                                  |
| 307 |    777.076515 |    145.070886 | Steven Haddock • Jellywatch.org                                                                                                                                                      |
| 308 |     33.647400 |    246.859723 | Margot Michaud                                                                                                                                                                       |
| 309 |    323.018601 |    698.491324 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                                  |
| 310 |    572.986629 |    618.704866 | Matt Crook                                                                                                                                                                           |
| 311 |    750.363326 |    210.881070 | Christopher Watson (photo) and T. Michael Keesey (vectorization)                                                                                                                     |
| 312 |    289.737200 |    735.097435 | T. Michael Keesey                                                                                                                                                                    |
| 313 |    462.137096 |     27.801914 | Tauana J. Cunha                                                                                                                                                                      |
| 314 |     40.142223 |    336.612084 | Yan Wong from photo by Gyik Toma                                                                                                                                                     |
| 315 |    422.281116 |    764.926511 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 316 |    844.953351 |    677.302852 | Sarah Alewijnse                                                                                                                                                                      |
| 317 |    867.501169 |    628.581821 | Scott Hartman                                                                                                                                                                        |
| 318 |    953.487878 |    779.585708 | xgirouxb                                                                                                                                                                             |
| 319 |    614.535773 |    680.836701 | David Sim (photograph) and T. Michael Keesey (vectorization)                                                                                                                         |
| 320 |    320.497695 |    724.265594 | Matt Crook                                                                                                                                                                           |
| 321 |    469.759839 |    392.959610 | Margot Michaud                                                                                                                                                                       |
| 322 |    326.033080 |    121.814689 | NA                                                                                                                                                                                   |
| 323 |    458.031915 |    320.919755 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                                  |
| 324 |    997.984833 |    546.098360 | Neil Kelley                                                                                                                                                                          |
| 325 |    364.679762 |    290.691003 | Margot Michaud                                                                                                                                                                       |
| 326 |   1012.871012 |    593.673815 | Sebastian Stabinger                                                                                                                                                                  |
| 327 |    744.303114 |     17.434484 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                                      |
| 328 |    682.605030 |    650.898468 | Anthony Caravaggi                                                                                                                                                                    |
| 329 |    767.736592 |    241.153247 | Scott Hartman                                                                                                                                                                        |
| 330 |    227.276734 |    522.008629 | Darius Nau                                                                                                                                                                           |
| 331 |    144.805905 |    595.598496 | Margot Michaud                                                                                                                                                                       |
| 332 |    678.070758 |    788.592565 | Yan Wong from photo by Denes Emoke                                                                                                                                                   |
| 333 |    167.396707 |    142.277597 | Juan Carlos Jerí                                                                                                                                                                     |
| 334 |    801.312355 |      9.159442 | Thibaut Brunet                                                                                                                                                                       |
| 335 |    582.120185 |    200.982006 | Christoph Schomburg                                                                                                                                                                  |
| 336 |     98.306971 |    777.876225 | Jagged Fang Designs                                                                                                                                                                  |
| 337 |    253.064501 |    443.336286 | Margot Michaud                                                                                                                                                                       |
| 338 |    319.956463 |     14.000908 | Jesús Gómez, vectorized by Zimices                                                                                                                                                   |
| 339 |    127.297427 |    243.596050 | Matt Crook                                                                                                                                                                           |
| 340 |    598.808953 |    426.371914 | Gareth Monger                                                                                                                                                                        |
| 341 |    104.397148 |    357.602346 | Alyssa Bell & Luis Chiappe 2015, dx.doi.org/10.1371/journal.pone.0141690                                                                                                             |
| 342 |    285.850339 |    598.740809 | Aline M. Ghilardi                                                                                                                                                                    |
| 343 |    355.301278 |    753.378768 | Caroline Harding, MAF (vectorized by T. Michael Keesey)                                                                                                                              |
| 344 |    797.247319 |    794.988058 | Matt Crook                                                                                                                                                                           |
| 345 |    517.068068 |    290.789122 | Jesús Gómez, vectorized by Zimices                                                                                                                                                   |
| 346 |    180.046046 |    611.551651 | Margot Michaud                                                                                                                                                                       |
| 347 |    442.966390 |    736.684210 | Iain Reid                                                                                                                                                                            |
| 348 |     59.505930 |    515.904339 | T. Michael Keesey (vectorization) and HuttyMcphoo (photography)                                                                                                                      |
| 349 |    387.292031 |     90.637415 | Mali’o Kodis, image from Higgins and Kristensen, 1986                                                                                                                                |
| 350 |    323.002310 |    229.239004 | Lukas Panzarin                                                                                                                                                                       |
| 351 |    875.255572 |    641.628386 | Zimices                                                                                                                                                                              |
| 352 |    289.357432 |     22.520527 | Collin Gross                                                                                                                                                                         |
| 353 |    383.658194 |    595.741505 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 354 |    688.778009 |    686.538774 | Margot Michaud                                                                                                                                                                       |
| 355 |    777.567652 |    600.669862 | Dean Schnabel                                                                                                                                                                        |
| 356 |    812.603425 |    559.580387 | Joanna Wolfe                                                                                                                                                                         |
| 357 |    255.420867 |    197.972146 | Zimices                                                                                                                                                                              |
| 358 |    934.071749 |    774.390619 | Nobu Tamura                                                                                                                                                                          |
| 359 |    297.003318 |    593.515052 | Emil Schmidt (vectorized by Maxime Dahirel)                                                                                                                                          |
| 360 |    812.930960 |    165.759528 | Martin R. Smith                                                                                                                                                                      |
| 361 |    461.059748 |    636.240901 | Kamil S. Jaron                                                                                                                                                                       |
| 362 |    111.356711 |    267.602963 | Lukas Panzarin                                                                                                                                                                       |
| 363 |    135.869722 |    578.526815 | Mathew Stewart                                                                                                                                                                       |
| 364 |    268.194092 |    574.061977 | Ferran Sayol                                                                                                                                                                         |
| 365 |     79.806505 |    207.469470 | Steven Coombs                                                                                                                                                                        |
| 366 |     13.058006 |    770.246901 | Alexandre Vong                                                                                                                                                                       |
| 367 |    410.296030 |    110.062949 | Gareth Monger                                                                                                                                                                        |
| 368 |    602.013231 |    212.023723 | Chris huh                                                                                                                                                                            |
| 369 |    945.519709 |    170.556309 | Sarah Werning                                                                                                                                                                        |
| 370 |    563.132444 |     11.670156 | Michael P. Taylor                                                                                                                                                                    |
| 371 |    134.144715 |    588.779863 | T. Michael Keesey                                                                                                                                                                    |
| 372 |    351.220708 |    727.000408 | Scott Hartman                                                                                                                                                                        |
| 373 |    207.493171 |      1.691355 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 374 |    377.085484 |    400.687346 | Ferran Sayol                                                                                                                                                                         |
| 375 |    413.745549 |     16.164091 | Benchill                                                                                                                                                                             |
| 376 |    449.937969 |    102.864820 | Cesar Julian                                                                                                                                                                         |
| 377 |    773.797637 |    420.142470 | Yan Wong                                                                                                                                                                             |
| 378 |    325.871788 |     74.908128 | NA                                                                                                                                                                                   |
| 379 |    162.981083 |    372.677404 | L. Shyamal                                                                                                                                                                           |
| 380 |    873.690746 |    495.700268 | Shyamal                                                                                                                                                                              |
| 381 |    626.326033 |    327.366115 | Jagged Fang Designs                                                                                                                                                                  |
| 382 |     63.005971 |    680.901656 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 383 |    644.030200 |     84.493092 | Ferran Sayol                                                                                                                                                                         |
| 384 |    263.647973 |     78.505121 | Steven Traver                                                                                                                                                                        |
| 385 |    655.623451 |    193.197646 | Gareth Monger                                                                                                                                                                        |
| 386 |     21.822526 |     62.535025 | Scott Hartman                                                                                                                                                                        |
| 387 |    545.752251 |    695.808077 | Tyler McCraney                                                                                                                                                                       |
| 388 |    774.314435 |    662.934065 | Michael Scroggie                                                                                                                                                                     |
| 389 |    384.745525 |    465.198457 | Emily Willoughby                                                                                                                                                                     |
| 390 |    210.317858 |    202.311898 | Steven Traver                                                                                                                                                                        |
| 391 |    437.646703 |    793.901621 | Rene Martin                                                                                                                                                                          |
| 392 |    480.450214 |    302.135242 | Michael Scroggie, from original photograph by Gary M. Stolz, USFWS (original photograph in public domain).                                                                           |
| 393 |    623.959172 |    338.479475 | Matt Crook                                                                                                                                                                           |
| 394 |   1005.899614 |    271.062969 | Ferran Sayol                                                                                                                                                                         |
| 395 |     25.558934 |    524.590531 | Margot Michaud                                                                                                                                                                       |
| 396 |    651.106574 |    491.935677 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                                       |
| 397 |    708.918657 |    292.816278 | Margot Michaud                                                                                                                                                                       |
| 398 |    907.962683 |    657.290696 | M Kolmann                                                                                                                                                                            |
| 399 |    147.242459 |    514.507216 | Scott Hartman                                                                                                                                                                        |
| 400 |    264.441850 |    112.937706 | Zimices                                                                                                                                                                              |
| 401 |    151.707515 |    637.860465 | NASA                                                                                                                                                                                 |
| 402 |    639.624989 |    159.624051 | Scott Hartman                                                                                                                                                                        |
| 403 |     35.046225 |    579.766499 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                                    |
| 404 |    662.470224 |     94.974884 | Gareth Monger                                                                                                                                                                        |
| 405 |     40.454404 |    165.164640 | Benjamint444                                                                                                                                                                         |
| 406 |    128.575833 |    256.534891 | S.Martini                                                                                                                                                                            |
| 407 |    235.467983 |     32.927680 | Danielle Alba                                                                                                                                                                        |
| 408 |    888.315175 |    361.094153 | Craig Dylke                                                                                                                                                                          |
| 409 |    829.995823 |    520.046057 | U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                                                    |
| 410 |   1016.641318 |    135.157307 | Mali’o Kodis, photograph property of National Museums of Northern Ireland                                                                                                            |
| 411 |    578.091199 |    730.182724 | SecretJellyMan                                                                                                                                                                       |
| 412 |    134.723835 |    389.898902 | Sarah Werning                                                                                                                                                                        |
| 413 |    306.529936 |    727.840970 | Dean Schnabel                                                                                                                                                                        |
| 414 |     64.880890 |    177.981350 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                                   |
| 415 |    359.697917 |     90.193017 | kotik                                                                                                                                                                                |
| 416 |    154.455127 |    202.580719 | Gareth Monger                                                                                                                                                                        |
| 417 |    556.700732 |    484.229462 | Smokeybjb (modified by T. Michael Keesey)                                                                                                                                            |
| 418 |    915.870894 |    429.595110 | Margot Michaud                                                                                                                                                                       |
| 419 |     15.757755 |    443.052093 | Ferran Sayol                                                                                                                                                                         |
| 420 |    868.597384 |    258.193161 | Alexis Simon                                                                                                                                                                         |
| 421 |    845.589192 |    274.063613 | Steven Traver                                                                                                                                                                        |
| 422 |     26.108012 |    501.995855 | Zimices                                                                                                                                                                              |
| 423 |    812.538951 |    401.991314 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 424 |    756.812689 |     15.127756 | Scott Hartman                                                                                                                                                                        |
| 425 |    391.387370 |    504.588689 | Ferran Sayol                                                                                                                                                                         |
| 426 |    449.871419 |    513.349308 | DW Bapst (Modified from photograph taken by Charles Mitchell)                                                                                                                        |
| 427 |    254.313281 |    791.595401 | Gareth Monger                                                                                                                                                                        |
| 428 |     92.330853 |    174.169043 | Sergio A. Muñoz-Gómez                                                                                                                                                                |
| 429 |    810.351887 |    575.987269 | Kai R. Caspar                                                                                                                                                                        |
| 430 |    760.203272 |    215.864839 | Steven Traver                                                                                                                                                                        |
| 431 |    923.979062 |    651.686086 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 432 |    164.609301 |    685.628182 | Margot Michaud                                                                                                                                                                       |
| 433 |    336.752001 |    354.951038 | Scott Hartman                                                                                                                                                                        |
| 434 |    547.757304 |    714.591110 | Zachary Quigley                                                                                                                                                                      |
| 435 |    346.566252 |    252.319187 | Rebecca Groom                                                                                                                                                                        |
| 436 |    701.955369 |    383.686223 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 437 |    483.307636 |    698.014541 | Matt Crook                                                                                                                                                                           |
| 438 |    421.754683 |    161.582131 | Eduard Solà (vectorized by T. Michael Keesey)                                                                                                                                        |
| 439 |     17.593305 |    462.374361 | Beth Reinke                                                                                                                                                                          |
| 440 |    216.132265 |    216.935495 | Michael P. Taylor                                                                                                                                                                    |
| 441 |     47.298683 |    730.685143 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 442 |    157.174156 |    368.764094 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 443 |    257.058705 |     85.443792 | Melissa Broussard                                                                                                                                                                    |
| 444 |    319.266224 |    622.592357 | Alexandre Vong                                                                                                                                                                       |
| 445 |     52.094852 |    141.909593 | Jessica Anne Miller                                                                                                                                                                  |
| 446 |    399.611945 |    120.381362 | George Edward Lodge                                                                                                                                                                  |
| 447 |    625.399485 |    597.194316 | Zimices                                                                                                                                                                              |
| 448 |    319.269009 |    100.388925 | Alex Slavenko                                                                                                                                                                        |
| 449 |   1014.596256 |    578.599725 | Steven Traver                                                                                                                                                                        |
| 450 |   1021.172692 |    505.223452 | NA                                                                                                                                                                                   |
| 451 |     80.440119 |    787.473218 | Tony Ayling                                                                                                                                                                          |
| 452 |    904.852653 |    412.379994 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                                             |
| 453 |    301.050229 |    104.965258 | Ingo Braasch                                                                                                                                                                         |
| 454 |    800.728037 |    576.962996 | Zimices                                                                                                                                                                              |
| 455 |    948.619523 |     33.565872 | Tasman Dixon                                                                                                                                                                         |
| 456 |    270.888540 |    121.610699 | Tasman Dixon                                                                                                                                                                         |
| 457 |     94.811262 |    259.897828 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 458 |     33.877334 |    154.811387 | Andrew A. Farke                                                                                                                                                                      |
| 459 |    125.550018 |     59.240904 | Yan Wong                                                                                                                                                                             |
| 460 |    231.316974 |    165.478895 | Ian Burt (original) and T. Michael Keesey (vectorization)                                                                                                                            |
| 461 |    691.327858 |    577.574326 | Matt Crook                                                                                                                                                                           |
| 462 |     43.378439 |    684.352091 | Dein Freund der Baum (vectorized by T. Michael Keesey)                                                                                                                               |
| 463 |    882.053790 |    388.713938 | Daniel Stadtmauer                                                                                                                                                                    |
| 464 |    153.003804 |    592.713064 | I. Sácek, Sr. (vectorized by T. Michael Keesey)                                                                                                                                      |
| 465 |    316.886707 |    537.609108 | T. Michael Keesey (after Mivart)                                                                                                                                                     |
| 466 |    531.468855 |    363.848320 | Birgit Lang                                                                                                                                                                          |
| 467 |    463.177270 |    641.746170 | Abraão Leite                                                                                                                                                                         |
| 468 |     75.831975 |    655.948837 | Andrew A. Farke                                                                                                                                                                      |
| 469 |    155.678485 |     57.545500 | Gareth Monger                                                                                                                                                                        |
| 470 |    449.149188 |    168.630438 | NA                                                                                                                                                                                   |
| 471 |    599.385311 |    177.579552 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                                  |
| 472 |     10.441232 |    759.753272 | T. Michael Keesey                                                                                                                                                                    |
| 473 |    291.775254 |     75.490011 | NA                                                                                                                                                                                   |
| 474 |    952.538371 |    382.239885 | Joanna Wolfe                                                                                                                                                                         |
| 475 |    585.756771 |    431.047210 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 476 |    472.569782 |    365.806462 | Christoph Schomburg                                                                                                                                                                  |
| 477 |    851.027334 |    505.336261 | Arthur S. Brum                                                                                                                                                                       |
| 478 |     55.855540 |    296.299151 | Christoph Schomburg                                                                                                                                                                  |
| 479 |     54.765787 |    442.622135 | T. Michael Keesey                                                                                                                                                                    |
| 480 |     72.567939 |    495.298849 | Andrew A. Farke                                                                                                                                                                      |
| 481 |    588.281590 |    738.254643 | Steven Traver                                                                                                                                                                        |
| 482 |    828.490955 |    655.385796 | Mali’o Kodis, photograph from <http://commons.wikimedia.org/wiki/File:Trichoplax.jpg>                                                                                                |
| 483 |    947.990488 |    689.457968 | Yan Wong from photo by Gyik Toma                                                                                                                                                     |
| 484 |     78.055815 |      3.486588 | Xavier Giroux-Bougard                                                                                                                                                                |
| 485 |    118.317256 |    277.656111 | Anthony Caravaggi                                                                                                                                                                    |
| 486 |    954.476841 |    345.824008 | Ferran Sayol                                                                                                                                                                         |
| 487 |    572.409832 |    272.178356 | Jagged Fang Designs                                                                                                                                                                  |
| 488 |     79.130736 |    522.384782 | Patrick Strutzenberger                                                                                                                                                               |
| 489 |     36.617362 |    409.650144 | NA                                                                                                                                                                                   |
| 490 |    981.350038 |    728.524888 | Jagged Fang Designs                                                                                                                                                                  |
| 491 |    710.611567 |    282.357045 | Zimices                                                                                                                                                                              |
| 492 |    969.636490 |    602.512940 | Michelle Site                                                                                                                                                                        |
| 493 |     20.242406 |    701.252588 | Chris huh                                                                                                                                                                            |
| 494 |    969.510900 |    322.764402 | Zimices                                                                                                                                                                              |
| 495 |    210.083020 |    187.505791 | Tracy A. Heath                                                                                                                                                                       |
| 496 |    108.843526 |     97.889759 | M. Garfield & K. Anderson (modified by T. Michael Keesey)                                                                                                                            |
| 497 |    146.567872 |    420.787737 | Matt Crook                                                                                                                                                                           |
| 498 |    173.282927 |    370.047264 | Zimices                                                                                                                                                                              |
| 499 |    600.469119 |    671.650066 | Mathew Wedel                                                                                                                                                                         |
| 500 |    726.190332 |    781.915136 | Scott Hartman                                                                                                                                                                        |
| 501 |    958.633293 |    340.681194 | Christoph Schomburg                                                                                                                                                                  |
| 502 |     48.641313 |    165.203996 | Gareth Monger                                                                                                                                                                        |
| 503 |    769.968284 |    455.578881 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 504 |    349.264895 |     81.803683 | FunkMonk                                                                                                                                                                             |
| 505 |    347.282207 |    628.170613 | H. F. O. March (vectorized by T. Michael Keesey)                                                                                                                                     |
| 506 |    369.069378 |     55.202177 | T. Michael Keesey                                                                                                                                                                    |
| 507 |    811.502763 |    636.896423 | NA                                                                                                                                                                                   |
| 508 |    980.259389 |    678.235215 | Matt Crook                                                                                                                                                                           |
| 509 |   1014.391788 |    741.263566 | Christoph Schomburg                                                                                                                                                                  |
| 510 |    610.977066 |     69.913572 | NA                                                                                                                                                                                   |
| 511 |    391.711680 |    745.059208 | T. Michael Keesey                                                                                                                                                                    |
| 512 |     37.375672 |    694.370642 | RS                                                                                                                                                                                   |
| 513 |    162.180566 |    399.285934 | Ville Koistinen and T. Michael Keesey                                                                                                                                                |
| 514 |    362.653862 |    345.525053 | Ferran Sayol                                                                                                                                                                         |
| 515 |     35.426987 |    753.124429 | Luc Viatour (source photo) and Andreas Plank                                                                                                                                         |
| 516 |    594.991141 |    527.465129 | Oscar Sanisidro                                                                                                                                                                      |
| 517 |    199.287446 |    134.413028 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 518 |    815.851599 |    349.967220 | L. Shyamal                                                                                                                                                                           |
| 519 |    481.634770 |    323.316300 | Margot Michaud                                                                                                                                                                       |
| 520 |     38.961797 |    404.907148 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 521 |     33.130922 |    778.668387 | Joanna Wolfe                                                                                                                                                                         |
| 522 |    327.030279 |    471.072539 | Gareth Monger                                                                                                                                                                        |
| 523 |    311.657694 |    116.787669 | Robert Gay                                                                                                                                                                           |
| 524 |    702.015632 |    365.240864 | Terpsichores                                                                                                                                                                         |
| 525 |     88.569282 |    192.886749 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 526 |    159.867356 |    675.761691 | Xavier Giroux-Bougard                                                                                                                                                                |
| 527 |    468.209308 |    474.976991 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                                               |
| 528 |    131.596727 |     65.963779 | Gareth Monger                                                                                                                                                                        |
| 529 |    533.876369 |    660.863331 | Chris huh                                                                                                                                                                            |
| 530 |    513.546247 |    691.119287 | Gareth Monger                                                                                                                                                                        |
| 531 |    796.351615 |    218.615259 | Gareth Monger                                                                                                                                                                        |
| 532 |   1012.269832 |    490.042199 | Shyamal                                                                                                                                                                              |
| 533 |    784.786002 |    494.449604 | Steven Traver                                                                                                                                                                        |
| 534 |    931.869295 |    600.461759 | Kai R. Caspar                                                                                                                                                                        |
| 535 |    738.832943 |    306.860694 | Kai R. Caspar                                                                                                                                                                        |
| 536 |    841.439788 |     64.974986 | Margot Michaud                                                                                                                                                                       |
| 537 |    419.165901 |    377.009688 | Ferran Sayol                                                                                                                                                                         |
| 538 |    435.316169 |    776.789171 | Steven Traver                                                                                                                                                                        |
| 539 |    948.270245 |     41.488574 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                                  |
| 540 |    416.566564 |    532.154660 | SecretJellyMan - from Mason McNair                                                                                                                                                   |
| 541 |    326.518130 |     43.373879 | Chris Jennings (vectorized by A. Verrière)                                                                                                                                           |
| 542 |    572.354963 |    418.446105 | Zimices                                                                                                                                                                              |
| 543 |    140.957611 |    639.750320 | T. Michael Keesey                                                                                                                                                                    |
| 544 |     39.044645 |    371.760670 | Sarah Werning                                                                                                                                                                        |
| 545 |    506.406644 |    177.523741 | Ferran Sayol                                                                                                                                                                         |
| 546 |    144.302046 |    548.340180 | Alex Slavenko                                                                                                                                                                        |
| 547 |    594.771085 |    172.846750 | Margot Michaud                                                                                                                                                                       |
| 548 |    434.110827 |    606.085535 | Terpsichores                                                                                                                                                                         |
| 549 |    560.686502 |    719.807307 | Kamil S. Jaron                                                                                                                                                                       |
| 550 |    995.633905 |    364.403114 | Andrew A. Farke, modified from original by H. Milne Edwards                                                                                                                          |
| 551 |    978.912348 |    594.432685 | Gareth Monger                                                                                                                                                                        |
| 552 |    520.652370 |    428.875934 | Steven Traver                                                                                                                                                                        |
| 553 |    734.463763 |      5.851351 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 554 |    783.497396 |    377.706005 | Eduard Solà (vectorized by T. Michael Keesey)                                                                                                                                        |
| 555 |    246.985341 |    314.863681 | Ryan Cupo                                                                                                                                                                            |
| 556 |    677.304745 |    724.013392 | NA                                                                                                                                                                                   |
| 557 |    683.624827 |     64.213033 | Mr E? (vectorized by T. Michael Keesey)                                                                                                                                              |
| 558 |    463.520311 |    380.469787 | T. Michael Keesey                                                                                                                                                                    |
| 559 |    261.348232 |    762.268686 | NA                                                                                                                                                                                   |
| 560 |    283.681201 |    517.809900 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 561 |    305.815701 |    712.087099 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 562 |    609.278101 |    581.868399 | Alexandre Vong                                                                                                                                                                       |
| 563 |    726.132499 |    678.267006 | Steven Traver                                                                                                                                                                        |
| 564 |    109.106115 |    632.852258 | Dean Schnabel                                                                                                                                                                        |
| 565 |    309.180322 |    690.783500 | Steven Coombs                                                                                                                                                                        |
| 566 |    735.935741 |    379.559877 | Christoph Schomburg                                                                                                                                                                  |
| 567 |    505.947518 |     34.876181 | Sergio A. Muñoz-Gómez                                                                                                                                                                |
| 568 |    928.314260 |    571.255997 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 569 |    817.323134 |    758.347728 | Lukasiniho                                                                                                                                                                           |
| 570 |    344.431683 |    165.423196 | Frank Förster (based on a picture by Hans Hillewaert)                                                                                                                                |
| 571 |    383.356454 |    560.367699 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                              |
| 572 |    665.090544 |    501.773918 | Danny Cicchetti (vectorized by T. Michael Keesey)                                                                                                                                    |
| 573 |    903.928103 |    732.226829 | Matt Crook                                                                                                                                                                           |
| 574 |    424.505391 |    458.069837 | Zimices                                                                                                                                                                              |
| 575 |    977.112497 |    788.836904 | Matt Crook                                                                                                                                                                           |
| 576 |    297.599975 |    181.611156 | Mali’o Kodis, image from the Smithsonian Institution                                                                                                                                 |
| 577 |    930.368517 |    364.125979 | Emily Jane McTavish, from Haeckel, E. H. P. A. (1904).Kunstformen der Natur. Bibliographisches                                                                                       |
| 578 |    401.942452 |    572.548965 | Tasman Dixon                                                                                                                                                                         |
| 579 |    776.210171 |    139.982503 | Ingo Braasch                                                                                                                                                                         |
| 580 |    728.464602 |     90.888989 | Scott Hartman                                                                                                                                                                        |
| 581 |    814.057903 |    665.687042 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 582 |    796.522933 |    463.775319 | Gareth Monger                                                                                                                                                                        |
| 583 |    987.828311 |    378.284287 | Milton Tan                                                                                                                                                                           |
| 584 |    738.671289 |    768.697805 | Tasman Dixon                                                                                                                                                                         |
| 585 |    217.259095 |    753.680278 | Jagged Fang Designs                                                                                                                                                                  |
| 586 |    134.493953 |    784.014629 | Chris huh                                                                                                                                                                            |
| 587 |    119.452840 |    685.196858 | Nobu Tamura                                                                                                                                                                          |
| 588 |     86.098304 |    644.562389 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 589 |    669.993477 |    546.076581 | Gareth Monger                                                                                                                                                                        |
| 590 |   1002.378861 |    281.171595 | Noah Schlottman, photo by Casey Dunn                                                                                                                                                 |
| 591 |    651.580855 |    685.427962 | Matt Crook                                                                                                                                                                           |
| 592 |     85.730293 |     14.904692 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 593 |    818.690666 |    688.611478 | Javiera Constanzo                                                                                                                                                                    |
| 594 |    227.883270 |    459.604439 | Maxime Dahirel                                                                                                                                                                       |
| 595 |     67.983490 |    781.207380 | Michael Scroggie                                                                                                                                                                     |
| 596 |    704.797540 |    375.428278 | Scott Hartman                                                                                                                                                                        |
| 597 |    155.642319 |     74.690096 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                                  |
| 598 |    947.109067 |    362.759404 | Birgit Lang                                                                                                                                                                          |
| 599 |    529.151002 |    151.503736 | NA                                                                                                                                                                                   |
| 600 |    264.502951 |    104.001948 | NA                                                                                                                                                                                   |
| 601 |    174.872933 |    459.812532 | Ferran Sayol                                                                                                                                                                         |
| 602 |    170.353033 |    779.793715 | Tracy A. Heath                                                                                                                                                                       |
| 603 |    166.271884 |    627.133869 | Rebecca Groom                                                                                                                                                                        |
| 604 |    236.059532 |    191.251893 | Kai R. Caspar                                                                                                                                                                        |
| 605 |    253.232240 |    572.202068 | Frank Förster                                                                                                                                                                        |
| 606 |     23.267362 |    259.355628 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 607 |    534.189009 |    511.587236 | Margot Michaud                                                                                                                                                                       |
| 608 |    633.236558 |    488.498800 | Maija Karala                                                                                                                                                                         |
| 609 |   1003.727072 |    764.299912 | Steven Traver                                                                                                                                                                        |
| 610 |    601.761295 |    622.849675 | NA                                                                                                                                                                                   |
| 611 |    285.833164 |    667.679167 | Michelle Site                                                                                                                                                                        |
| 612 |    307.376801 |    237.819096 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                                    |
| 613 |     64.581089 |    347.090210 | Tauana J. Cunha                                                                                                                                                                      |
| 614 |    613.941416 |    434.606650 | M. Garfield & K. Anderson (modified by T. Michael Keesey)                                                                                                                            |
| 615 |    454.792738 |     17.225350 | Campbell Fleming                                                                                                                                                                     |
| 616 |    277.475819 |     43.509378 | Steven Traver                                                                                                                                                                        |
| 617 |    712.987863 |    662.822205 | Duane Raver (vectorized by T. Michael Keesey)                                                                                                                                        |
| 618 |    624.293763 |    613.200319 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 619 |    367.780723 |    592.237153 | Ben Moon                                                                                                                                                                             |
| 620 |    277.721316 |    237.654809 | Zimices                                                                                                                                                                              |
| 621 |    325.150038 |    364.422414 | NA                                                                                                                                                                                   |
| 622 |     90.279054 |    664.597915 | Milton Tan                                                                                                                                                                           |
| 623 |    517.180300 |    704.882097 | Smokeybjb                                                                                                                                                                            |
| 624 |    532.557855 |    124.653595 | Tim Bertelink (modified by T. Michael Keesey)                                                                                                                                        |
| 625 |    665.137458 |    169.529088 | Noah Schlottman                                                                                                                                                                      |
| 626 |    570.418355 |    437.540171 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                                       |
| 627 |    405.113417 |    365.969974 | Gareth Monger                                                                                                                                                                        |
| 628 |    271.325027 |    458.760110 | Margot Michaud                                                                                                                                                                       |
| 629 |   1004.597488 |    760.050996 | Yan Wong                                                                                                                                                                             |
| 630 |    604.436933 |     67.761566 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                                     |
| 631 |    255.755438 |    678.741588 | Zimices                                                                                                                                                                              |
| 632 |    441.715100 |      9.323566 | Katie S. Collins                                                                                                                                                                     |
| 633 |   1004.998819 |     23.674222 | Matt Crook                                                                                                                                                                           |
| 634 |    226.074979 |    602.408110 | Ferran Sayol                                                                                                                                                                         |
| 635 |    843.816718 |    345.813138 | Xavier Giroux-Bougard                                                                                                                                                                |
| 636 |    186.454452 |    627.608622 | Steven Traver                                                                                                                                                                        |
| 637 |    769.581825 |    164.459928 | Christoph Schomburg                                                                                                                                                                  |
| 638 |    505.411286 |    254.137088 | Matt Crook                                                                                                                                                                           |
| 639 |    377.404701 |    109.408585 | Joanna Wolfe                                                                                                                                                                         |
| 640 |   1000.903535 |    744.749803 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                                       |
| 641 |    657.237588 |    570.666620 | Gareth Monger                                                                                                                                                                        |
| 642 |    582.176191 |    628.541509 | Anthony Caravaggi                                                                                                                                                                    |
| 643 |    851.925990 |    487.453000 | Matt Crook                                                                                                                                                                           |
| 644 |    309.905601 |    792.645962 | Katie S. Collins                                                                                                                                                                     |
| 645 |    688.257622 |    496.737246 | Chris huh                                                                                                                                                                            |
| 646 |    313.101454 |     48.697251 | Gareth Monger                                                                                                                                                                        |
| 647 |    223.382049 |    287.475565 | Zimices                                                                                                                                                                              |
| 648 |    407.874273 |    550.100937 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                                        |
| 649 |    900.345512 |    460.793538 | T. Michael Keesey                                                                                                                                                                    |
| 650 |    439.910409 |    344.315913 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 651 |    756.161340 |    450.419631 | Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus                                                             |
| 652 |     43.737741 |    790.052390 | Joanna Wolfe                                                                                                                                                                         |
| 653 |     53.190446 |    647.469268 | T. Michael Keesey (photo by Darren Swim)                                                                                                                                             |
| 654 |    281.479002 |    429.138099 | Ferran Sayol                                                                                                                                                                         |
| 655 |    282.953723 |    104.308554 | Sean McCann                                                                                                                                                                          |
| 656 |    821.992107 |    587.988157 | Scott Hartman                                                                                                                                                                        |
| 657 |    592.558640 |    184.266301 | Karkemish (vectorized by T. Michael Keesey)                                                                                                                                          |
| 658 |    346.134909 |    367.745402 | Birgit Lang                                                                                                                                                                          |
| 659 |    609.237767 |    429.715807 | Zimices                                                                                                                                                                              |
| 660 |    551.568881 |    209.128816 | Jose Carlos Arenas-Monroy                                                                                                                                                            |
| 661 |    859.205902 |    666.523220 | Jagged Fang Designs                                                                                                                                                                  |
| 662 |    688.341164 |    608.839039 | Zimices                                                                                                                                                                              |
| 663 |    781.737502 |    678.741184 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 664 |    524.389594 |    253.786919 | NA                                                                                                                                                                                   |
| 665 |     13.037266 |     11.024024 | Katie S. Collins                                                                                                                                                                     |
| 666 |    476.863551 |    723.806879 | Matt Crook                                                                                                                                                                           |
| 667 |    966.450661 |    165.666163 | Dean Schnabel                                                                                                                                                                        |
| 668 |    704.485638 |    299.356751 | Jerry Oldenettel (vectorized by T. Michael Keesey)                                                                                                                                   |
| 669 |    189.678559 |    404.325143 | Sarah Werning                                                                                                                                                                        |
| 670 |    323.845779 |    560.970855 | Matthew E. Clapham                                                                                                                                                                   |
| 671 |    985.975340 |    495.596317 | Scott Hartman                                                                                                                                                                        |
| 672 |    644.594586 |    124.655379 | Sarefo (vectorized by T. Michael Keesey)                                                                                                                                             |
| 673 |    537.210251 |    346.645606 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 674 |    862.401693 |    648.292533 | Margot Michaud                                                                                                                                                                       |
| 675 |    878.435043 |    481.652951 | Zimices                                                                                                                                                                              |
| 676 |    731.738665 |    696.019678 | Maija Karala                                                                                                                                                                         |
| 677 |    887.837168 |    406.149709 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 678 |    172.618188 |    298.510659 | Ferran Sayol                                                                                                                                                                         |
| 679 |    325.357743 |    793.503510 | FJDegrange                                                                                                                                                                           |
| 680 |    520.396969 |    390.188170 | Margot Michaud                                                                                                                                                                       |
| 681 |    540.251790 |    231.207490 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 682 |    840.035554 |    276.584900 | Margot Michaud                                                                                                                                                                       |
| 683 |    864.305865 |    672.344203 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 684 |    523.873283 |     86.722401 | Zimices                                                                                                                                                                              |
| 685 |    803.325660 |    225.193310 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 686 |   1014.294278 |     31.427286 | Gareth Monger                                                                                                                                                                        |
| 687 |    269.669506 |     10.277627 | Steven Traver                                                                                                                                                                        |
| 688 |    824.781165 |    772.410577 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                                         |
| 689 |    259.008379 |    656.759008 | Curtis Clark and T. Michael Keesey                                                                                                                                                   |
| 690 |    588.555335 |     13.313656 | Warren H (photography), T. Michael Keesey (vectorization)                                                                                                                            |
| 691 |    958.345686 |    282.846335 | Lafage                                                                                                                                                                               |
| 692 |      7.620171 |    505.959967 | Christoph Schomburg                                                                                                                                                                  |
| 693 |    459.043895 |    280.385225 | Scott Hartman                                                                                                                                                                        |
| 694 |     49.291866 |    330.096856 | Sarah Alewijnse                                                                                                                                                                      |
| 695 |    335.943224 |     86.451409 | Javier Luque                                                                                                                                                                         |
| 696 |    923.103220 |    581.503243 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 697 |    795.178800 |    245.357945 | Ferran Sayol                                                                                                                                                                         |
| 698 |     90.380455 |      3.007523 | FunkMonk                                                                                                                                                                             |
| 699 |     44.971838 |    769.303157 | Zimices                                                                                                                                                                              |
| 700 |    298.414262 |    153.569438 | Caleb M. Brown                                                                                                                                                                       |
| 701 |     95.965952 |    241.463197 | JJ Harrison (vectorized by T. Michael Keesey)                                                                                                                                        |
| 702 |    668.904197 |    601.261124 | Estelle Bourdon                                                                                                                                                                      |
| 703 |    334.430298 |     58.468433 | Birgit Lang                                                                                                                                                                          |
| 704 |    411.995536 |    356.253136 | Emily Willoughby                                                                                                                                                                     |
| 705 |    106.543715 |    258.784788 | Matt Crook                                                                                                                                                                           |
| 706 |    526.034053 |    719.862625 | Becky Barnes                                                                                                                                                                         |
| 707 |     23.492837 |    313.431116 | Melissa Broussard                                                                                                                                                                    |
| 708 |    612.316507 |    487.059892 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                                    |
| 709 |    244.941554 |    269.768393 | Steven Haddock • Jellywatch.org                                                                                                                                                      |
| 710 |   1006.081993 |    782.180495 | Michael P. Taylor                                                                                                                                                                    |
| 711 |    211.791112 |    603.147285 | Gareth Monger                                                                                                                                                                        |
| 712 |    156.570840 |    306.735170 | Margot Michaud                                                                                                                                                                       |
| 713 |    556.146329 |     49.191208 | T. Michael Keesey                                                                                                                                                                    |
| 714 |    218.125676 |    569.354111 | Becky Barnes                                                                                                                                                                         |
| 715 |    329.028990 |    252.590517 | Ferran Sayol                                                                                                                                                                         |
| 716 |    150.271017 |    247.980432 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 717 |    785.732330 |    573.736778 | Margot Michaud                                                                                                                                                                       |
| 718 |    704.340616 |    510.540994 | Ludwik Gasiorowski                                                                                                                                                                   |
| 719 |    697.134351 |    102.982511 | T. Michael Keesey                                                                                                                                                                    |
| 720 |    262.678413 |    452.480732 | Matt Crook                                                                                                                                                                           |
| 721 |     44.956497 |     74.527812 | Ferran Sayol                                                                                                                                                                         |
| 722 |    896.213970 |    201.913791 | NA                                                                                                                                                                                   |
| 723 |    993.724000 |     14.416415 | Gareth Monger                                                                                                                                                                        |
| 724 |    467.086533 |    116.614169 | Joris van der Ham (vectorized by T. Michael Keesey)                                                                                                                                  |
| 725 |    266.554101 |    149.259830 | Jagged Fang Designs                                                                                                                                                                  |
| 726 |    693.759699 |     97.646159 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                                    |
| 727 |    141.067851 |    673.745364 | Felix Vaux                                                                                                                                                                           |
| 728 |    551.968204 |    726.218269 | Chloé Schmidt                                                                                                                                                                        |
| 729 |    521.846249 |    676.865525 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 730 |    992.787638 |    310.778120 | NA                                                                                                                                                                                   |
| 731 |    846.773571 |    485.176085 | Francesco “Architetto” Rollandin                                                                                                                                                     |
| 732 |   1013.231985 |     78.834565 | Margot Michaud                                                                                                                                                                       |
| 733 |    740.066490 |    325.201099 | Maija Karala                                                                                                                                                                         |
| 734 |    369.972849 |    754.918378 | Michelle Site                                                                                                                                                                        |
| 735 |    890.380856 |    125.542194 | Matt Crook                                                                                                                                                                           |
| 736 |     42.121643 |    678.721724 | Conty (vectorized by T. Michael Keesey)                                                                                                                                              |
| 737 |    859.174561 |    726.559349 | Beth Reinke                                                                                                                                                                          |
| 738 |    924.105115 |    374.804703 | Scott Hartman                                                                                                                                                                        |
| 739 |     71.286219 |    238.999590 | Tracy A. Heath                                                                                                                                                                       |
| 740 |    840.389400 |     22.360585 | Michelle Site                                                                                                                                                                        |
| 741 |    798.148943 |    409.797999 | NA                                                                                                                                                                                   |
| 742 |    786.384138 |    626.024309 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 743 |    636.253026 |    581.562373 | Emily Willoughby                                                                                                                                                                     |
| 744 |    265.725209 |    682.586506 | Melissa Broussard                                                                                                                                                                    |
| 745 |    662.927758 |    620.111288 | Tasman Dixon                                                                                                                                                                         |
| 746 |    156.030744 |    254.188651 | NA                                                                                                                                                                                   |
| 747 |    570.644009 |    716.937436 | Steven Traver                                                                                                                                                                        |
| 748 |    347.975939 |    517.306925 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                                              |
| 749 |     25.501657 |    480.292630 | NA                                                                                                                                                                                   |
| 750 |     38.800128 |    307.121589 | Steven Traver                                                                                                                                                                        |
| 751 |    432.241025 |    514.895678 | Matt Crook                                                                                                                                                                           |
| 752 |    245.600593 |    505.971279 | Noah Schlottman, photo by Antonio Guillén                                                                                                                                            |
| 753 |     20.702184 |     97.914986 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                                                        |
| 754 |    399.395544 |    789.830667 | Zimices                                                                                                                                                                              |
| 755 |    140.165095 |    242.677080 | Margot Michaud                                                                                                                                                                       |
| 756 |    785.412355 |    435.909208 | Zimices                                                                                                                                                                              |
| 757 |    293.806734 |     14.338343 | NA                                                                                                                                                                                   |
| 758 |    891.654737 |    266.461047 | Armelle Ansart (photograph), Maxime Dahirel (digitisation)                                                                                                                           |
| 759 |    164.369299 |    470.791325 | Noah Schlottman                                                                                                                                                                      |
| 760 |    577.363515 |    113.376400 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                                    |
| 761 |    345.629984 |    184.442395 | NA                                                                                                                                                                                   |
| 762 |    267.916043 |    422.870701 | T. Michael Keesey (after Joseph Wolf)                                                                                                                                                |
| 763 |   1006.359836 |    590.701223 | Robert Bruce Horsfall, from W.B. Scott’s 1912 “A History of Land Mammals in the Western Hemisphere”                                                                                  |
| 764 |    249.983303 |    334.337556 | Zimices                                                                                                                                                                              |
| 765 |    521.629040 |    525.414514 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                                   |
| 766 |    623.888240 |    218.000129 | Pranav Iyer (grey ideas)                                                                                                                                                             |
| 767 |    815.222921 |    480.482693 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 768 |    919.794231 |    123.717769 | John Conway                                                                                                                                                                          |
| 769 |    855.860905 |    570.989380 | Gustav Mützel                                                                                                                                                                        |
| 770 |    175.397509 |    601.736155 | T. Michael Keesey                                                                                                                                                                    |
| 771 |    907.129364 |    358.985981 | Zimices                                                                                                                                                                              |
| 772 |     24.327309 |    758.852765 | Mali’o Kodis, image from the Smithsonian Institution                                                                                                                                 |
| 773 |    878.784239 |    767.722189 | Robert Gay                                                                                                                                                                           |
| 774 |    732.688723 |    393.284644 | Lukasiniho                                                                                                                                                                           |
| 775 |    492.097256 |    149.022047 | NA                                                                                                                                                                                   |
| 776 |    938.028607 |    581.597066 | Margot Michaud                                                                                                                                                                       |
| 777 |    499.165751 |    347.188531 | FunkMonk                                                                                                                                                                             |
| 778 |    741.717514 |    335.755280 | Chris huh                                                                                                                                                                            |
| 779 |    731.611918 |    645.579630 | Matt Crook                                                                                                                                                                           |
| 780 |    470.052346 |    643.060740 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 781 |    563.149674 |     46.849773 | Kamil S. Jaron                                                                                                                                                                       |
| 782 |   1011.931062 |    351.463666 | Beth Reinke                                                                                                                                                                          |
| 783 |     45.482493 |    137.669627 | Steven Traver                                                                                                                                                                        |
| 784 |    356.314004 |    103.390059 | Gareth Monger                                                                                                                                                                        |
| 785 |     78.133796 |    362.187327 | Scott Hartman                                                                                                                                                                        |
| 786 |    825.060487 |    576.504381 | T. Michael Keesey                                                                                                                                                                    |
| 787 |    744.308276 |    280.500109 | Birgit Lang                                                                                                                                                                          |
| 788 |     35.797770 |    167.689630 | Felix Vaux                                                                                                                                                                           |
| 789 |     88.712858 |    625.812481 | Yan Wong                                                                                                                                                                             |
| 790 |    606.333058 |    678.107380 | Matt Crook                                                                                                                                                                           |
| 791 |    462.958056 |    367.191013 | Sidney Frederic Harmer, Arthur Everett Shipley (vectorized by Maxime Dahirel)                                                                                                        |
| 792 |    475.343463 |    115.857072 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 793 |    188.206211 |    597.158014 | Zimices                                                                                                                                                                              |
| 794 |    660.830582 |    659.712138 | T. Michael Keesey                                                                                                                                                                    |
| 795 |    794.559938 |    585.316358 | Jaime Headden (vectorized by T. Michael Keesey)                                                                                                                                      |
| 796 |    855.876455 |    658.618146 | Scott Hartman                                                                                                                                                                        |
| 797 |    193.159774 |    678.698859 | Chris huh                                                                                                                                                                            |
| 798 |   1011.645292 |    193.883222 | Caleb M. Brown                                                                                                                                                                       |
| 799 |    268.972152 |    360.256398 | Matt Crook                                                                                                                                                                           |
| 800 |    670.833368 |    163.946537 | Chloé Schmidt                                                                                                                                                                        |
| 801 |    149.844770 |    386.349743 | Gareth Monger                                                                                                                                                                        |
| 802 |    220.595512 |    261.525864 | Sean McCann                                                                                                                                                                          |
| 803 |    528.141218 |    195.812566 | Nobu Tamura, modified by Andrew A. Farke                                                                                                                                             |
| 804 |    755.388078 |     29.253228 | T. Michael Keesey (after MPF)                                                                                                                                                        |
| 805 |    421.589724 |    167.592909 | Lauren Sumner-Rooney                                                                                                                                                                 |
| 806 |   1013.364102 |     15.764229 | Matthew E. Clapham                                                                                                                                                                   |
| 807 |    467.204097 |    700.566017 | Mario Quevedo                                                                                                                                                                        |
| 808 |    593.238575 |    681.840601 | Melissa Broussard                                                                                                                                                                    |
| 809 |    492.168446 |    734.713154 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 810 |    259.295440 |    642.293642 | Tyler Greenfield                                                                                                                                                                     |
| 811 |    364.731735 |    581.324332 | Zimices                                                                                                                                                                              |
| 812 |     33.701702 |    508.525109 | Margot Michaud                                                                                                                                                                       |
| 813 |     52.793838 |      8.262561 | Melissa Broussard                                                                                                                                                                    |
| 814 |    139.317457 |    295.785886 | Sarah Werning                                                                                                                                                                        |
| 815 |    632.892768 |    221.147004 | Ferran Sayol                                                                                                                                                                         |
| 816 |     94.498429 |    277.055923 | Conty (vectorized by T. Michael Keesey)                                                                                                                                              |
| 817 |    443.056656 |    760.328118 | Matt Crook                                                                                                                                                                           |
| 818 |    278.562236 |    555.953672 | Ingo Braasch                                                                                                                                                                         |
| 819 |     70.347370 |    639.200463 | Jake Warner                                                                                                                                                                          |
| 820 |    301.593406 |    252.015347 | Matt Crook                                                                                                                                                                           |
| 821 |    633.823314 |    501.937073 | T. Michael Keesey                                                                                                                                                                    |
| 822 |    136.794328 |    209.196874 | Gareth Monger                                                                                                                                                                        |
| 823 |    496.534525 |    371.033206 | John Curtis (vectorized by T. Michael Keesey)                                                                                                                                        |
| 824 |    723.446860 |    526.522578 | Steven Traver                                                                                                                                                                        |
| 825 |    810.482301 |    700.543551 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 826 |    109.432993 |    564.065399 | Steven Traver                                                                                                                                                                        |
| 827 |    360.575050 |    615.012988 | Matt Hayes                                                                                                                                                                           |
| 828 |     35.227885 |    552.829218 | T. Michael Keesey                                                                                                                                                                    |
| 829 |    329.199662 |    349.875744 | Iain Reid                                                                                                                                                                            |
| 830 |    376.082675 |    375.845762 | A. H. Baldwin (vectorized by T. Michael Keesey)                                                                                                                                      |
| 831 |    661.202303 |    650.987883 | Tracy A. Heath                                                                                                                                                                       |
| 832 |    881.491907 |    603.669426 | Harold N Eyster                                                                                                                                                                      |
| 833 |    784.867779 |      4.653265 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                                       |
| 834 |    941.316355 |    290.154512 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                                     |
| 835 |    111.839500 |    522.993259 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 836 |      8.270579 |     78.518449 | Kai R. Caspar                                                                                                                                                                        |
| 837 |     14.309674 |    384.141774 | Jakovche                                                                                                                                                                             |
| 838 |    268.281942 |    538.422369 | NA                                                                                                                                                                                   |
| 839 |    608.445473 |    497.790290 | Tasman Dixon                                                                                                                                                                         |
| 840 |    926.852749 |    704.949864 | Margot Michaud                                                                                                                                                                       |
| 841 |      8.018461 |    741.294082 | Margot Michaud                                                                                                                                                                       |
| 842 |    574.185940 |    200.038492 | Matt Crook                                                                                                                                                                           |
| 843 |    583.312038 |    443.420187 | Steven Traver                                                                                                                                                                        |
| 844 |    854.045758 |    100.103786 | Anilocra (vectorization by Yan Wong)                                                                                                                                                 |
| 845 |     43.786454 |    396.312662 | Zimices                                                                                                                                                                              |
| 846 |    377.434848 |     81.781076 | Zimices                                                                                                                                                                              |
| 847 |    306.756915 |    533.763478 | Margot Michaud                                                                                                                                                                       |
| 848 |    789.246124 |    488.831682 | Jaime Headden                                                                                                                                                                        |
| 849 |    181.918922 |    401.644829 | Zimices                                                                                                                                                                              |
| 850 |    837.226711 |    146.597915 | Margot Michaud                                                                                                                                                                       |
| 851 |    960.989307 |    571.187097 | Claus Rebler                                                                                                                                                                         |
| 852 |   1014.443190 |    405.916593 | Ferran Sayol                                                                                                                                                                         |
| 853 |    480.259740 |    128.847597 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                                      |
| 854 |    985.656378 |    156.323684 | Scott Hartman                                                                                                                                                                        |
| 855 |    934.831564 |      6.272560 | Birgit Lang                                                                                                                                                                          |
| 856 |    784.296148 |    258.106181 | T. Michael Keesey (vectorization); Thorsten Assmann, Jörn Buse, Claudia Drees, Ariel-Leib-Leonid Friedman, Tal Levanony, Andrea Matern, Anika Timm, and David W. Wrase (photography) |
| 857 |    674.396445 |     83.160473 | Zimices                                                                                                                                                                              |
| 858 |    537.312998 |    120.909295 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                                         |
| 859 |    788.713251 |    278.234422 | Gareth Monger                                                                                                                                                                        |
| 860 |    637.404356 |    141.699984 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                                      |
| 861 |    151.376397 |    265.968713 | Steven Traver                                                                                                                                                                        |
| 862 |    842.948491 |     14.906150 | Ferran Sayol                                                                                                                                                                         |
| 863 |   1012.691753 |    413.227525 | Zimices                                                                                                                                                                              |
| 864 |    168.803921 |    407.396117 | Caleb M. Brown                                                                                                                                                                       |
| 865 |   1012.157581 |      4.203931 | Matt Martyniuk                                                                                                                                                                       |
| 866 |    919.209353 |    739.749705 | Maija Karala                                                                                                                                                                         |
| 867 |    480.999669 |    386.225539 | Felix Vaux                                                                                                                                                                           |
| 868 |    930.227754 |    282.580679 | Oliver Voigt                                                                                                                                                                         |
| 869 |    952.677070 |    366.408140 | Richard J. Harris                                                                                                                                                                    |
| 870 |    529.673471 |     90.294978 | Matt Crook                                                                                                                                                                           |
| 871 |    727.300081 |    335.440018 | Matt Crook                                                                                                                                                                           |
| 872 |    253.418142 |    701.082185 | Plukenet                                                                                                                                                                             |
| 873 |    791.303319 |    335.230312 | Yan Wong                                                                                                                                                                             |
| 874 |    723.698138 |    517.211606 | Tess Linden                                                                                                                                                                          |
| 875 |    430.792099 |    303.019360 | Zimices                                                                                                                                                                              |
| 876 |    801.227964 |    644.282828 | CNZdenek                                                                                                                                                                             |
| 877 |    565.965579 |    734.384842 | MPF (vectorized by T. Michael Keesey)                                                                                                                                                |
| 878 |    900.247342 |    267.913719 | Scott Hartman                                                                                                                                                                        |
| 879 |    642.272124 |    608.699247 | Ferran Sayol                                                                                                                                                                         |
| 880 |    652.193356 |    425.689535 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                                     |
| 881 |    160.765352 |    518.305287 | Matt Celeskey                                                                                                                                                                        |
| 882 |    848.018750 |    592.574509 | Matt Crook                                                                                                                                                                           |
| 883 |    707.913530 |    651.307496 | Dean Schnabel                                                                                                                                                                        |
| 884 |    429.081750 |    662.175633 | Margot Michaud                                                                                                                                                                       |
| 885 |    420.528527 |    783.159971 | NA                                                                                                                                                                                   |
| 886 |    975.292105 |    545.022200 | Archaeodontosaurus (vectorized by T. Michael Keesey)                                                                                                                                 |
| 887 |    468.605533 |    755.023012 | Mali’o Kodis, photograph from Jersabek et al, 2003                                                                                                                                   |
| 888 |    629.317817 |    151.672021 | Zimices                                                                                                                                                                              |
| 889 |    799.926696 |    625.005577 | Louis Ranjard                                                                                                                                                                        |
| 890 |    379.412521 |    249.534873 | Dean Schnabel                                                                                                                                                                        |
| 891 |   1005.932186 |    502.004965 | Margot Michaud                                                                                                                                                                       |
| 892 |      5.794732 |    199.295531 | Michael Scroggie                                                                                                                                                                     |
| 893 |    953.077764 |    205.042217 | Katie S. Collins                                                                                                                                                                     |
| 894 |    190.316055 |    181.757968 | Chris huh                                                                                                                                                                            |
| 895 |    305.563915 |     35.103501 | Zimices                                                                                                                                                                              |
| 896 |    569.956891 |    413.890783 | Gareth Monger                                                                                                                                                                        |
| 897 |    332.977236 |    376.697847 | Smokeybjb                                                                                                                                                                            |
| 898 |    549.673638 |    422.467072 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                                          |
| 899 |    251.022154 |    524.364174 | Margot Michaud                                                                                                                                                                       |
| 900 |    944.895351 |    730.244477 | Jack Mayer Wood                                                                                                                                                                      |
| 901 |    929.069284 |    720.481963 | Steven Traver                                                                                                                                                                        |
| 902 |    719.327157 |     77.735956 | Michele M Tobias                                                                                                                                                                     |
| 903 |     26.985356 |    727.612541 | Ferran Sayol                                                                                                                                                                         |
| 904 |    795.629344 |    667.076995 | Cesar Julian                                                                                                                                                                         |
| 905 |    318.160687 |    165.244853 | Mali’o Kodis, photograph by G. Giribet                                                                                                                                               |
| 906 |    497.857876 |    385.476282 | James R. Spotila and Ray Chatterji                                                                                                                                                   |
| 907 |    302.956634 |    367.972573 | Zimices                                                                                                                                                                              |
| 908 |    208.185877 |    166.107678 | Arthur S. Brum                                                                                                                                                                       |
| 909 |    765.064079 |    698.261192 | Yan Wong                                                                                                                                                                             |
| 910 |     16.390574 |    495.039980 | Collin Gross                                                                                                                                                                         |
| 911 |     67.081855 |    198.801028 | Emily Willoughby                                                                                                                                                                     |
| 912 |     38.524249 |    353.876941 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 913 |    131.951823 |    557.008842 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                                     |
| 914 |    987.127336 |    793.472655 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 915 |    846.823013 |    119.374633 | Scott Hartman                                                                                                                                                                        |
| 916 |    223.186477 |    257.090934 | Ferran Sayol                                                                                                                                                                         |
| 917 |     33.406437 |    120.761557 | Margot Michaud                                                                                                                                                                       |
| 918 |    766.562311 |    337.502377 | Douglas Brown (modified by T. Michael Keesey)                                                                                                                                        |
| 919 |    673.198628 |    103.248284 | Zimices                                                                                                                                                                              |
| 920 |    685.739369 |    173.997910 | DW Bapst (Modified from Bulman, 1964)                                                                                                                                                |
| 921 |    284.629764 |    747.861636 | Eduard Solà Vázquez, vectorised by Yan Wong                                                                                                                                          |
| 922 |    803.528359 |    393.215212 | Gareth Monger                                                                                                                                                                        |
| 923 |    860.410216 |     15.028794 | NA                                                                                                                                                                                   |
| 924 |    320.969610 |     35.810787 | Sharon Wegner-Larsen                                                                                                                                                                 |
| 925 |    837.178810 |    494.674412 | T. Michael Keesey                                                                                                                                                                    |
| 926 |    772.547790 |    208.234343 | Michelle Site                                                                                                                                                                        |
| 927 |    273.852758 |    797.025303 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                                     |
| 928 |    265.644233 |    509.851594 | T. Michael Keesey                                                                                                                                                                    |
| 929 |    435.063715 |     18.034171 | Gareth Monger                                                                                                                                                                        |
| 930 |    897.208351 |    592.509985 | Hans Hillewaert                                                                                                                                                                      |
| 931 |    528.510727 |    383.000442 | Smokeybjb                                                                                                                                                                            |
| 932 |    571.895154 |    546.883769 | Tasman Dixon                                                                                                                                                                         |
| 933 |     93.235144 |    355.676456 | Chris huh                                                                                                                                                                            |
| 934 |    530.473330 |    270.692231 | Steven Traver                                                                                                                                                                        |
| 935 |     58.751658 |    321.821169 | Lily Hughes                                                                                                                                                                          |
| 936 |   1020.491857 |    728.128695 | Gareth Monger                                                                                                                                                                        |
| 937 |    686.910740 |    696.592150 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 938 |    355.054935 |    611.084230 | Tasman Dixon                                                                                                                                                                         |
| 939 |    958.280410 |    602.140520 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                              |
| 940 |    711.790499 |    451.277047 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 941 |    379.580171 |    461.368300 | Chris huh                                                                                                                                                                            |
