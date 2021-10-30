
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
                    function(x) {Sys.sleep(0.5); rphylopic::image_get(x, options = c("credit"))$credit})
```

## Artists whose work is showcased:

Harold N Eyster, Katie S. Collins, Pedro de Siracusa, Nobu Tamura
(vectorized by T. Michael Keesey), Neil Kelley, Florian Pfaff, Nobu
Tamura, vectorized by Zimices, Kamil S. Jaron, Jebulon (vectorized by T.
Michael Keesey), (after McCulloch 1908), Armin Reindl, Andreas Trepte
(vectorized by T. Michael Keesey), Scott Hartman, Steven Traver, Jiekun
He, L. Shyamal, Margot Michaud, Ferran Sayol, Joanna Wolfe, Michael
Scroggie, from original photograph by John Bettaso, USFWS (original
photograph in public domain)., Jagged Fang Designs, Zimices, Nobu
Tamura, SauropodomorphMonarch, Smokeybjb (vectorized by T. Michael
Keesey), Catherine Yasuda, Kai R. Caspar, Aleksey Nagovitsyn (vectorized
by T. Michael Keesey), Tyler Greenfield, Chris huh, Lauren Anderson,
Iain Reid, Scott Reid, New York Zoological Society, Lukas Panzarin,
Arthur Weasley (vectorized by T. Michael Keesey), Dmitry Bogdanov
(vectorized by T. Michael Keesey), Scarlet23 (vectorized by T. Michael
Keesey), Gareth Monger, Joseph J. W. Sertich, Mark A. Loewen, Matthew E.
Clapham, DW Bapst (modified from Bates et al., 2005), Ghedoghedo
(vectorized by T. Michael Keesey), T. Michael Keesey, Maija Karala,
Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela
Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough
(vectorized by T. Michael Keesey), Daniel Stadtmauer, Tasman Dixon, M
Kolmann, Matt Crook, Birgit Lang, Michelle Site, Walter Vladimir, Sharon
Wegner-Larsen, Nobu Tamura (modified by T. Michael Keesey), Andrew A.
Farke, terngirl, Alex Slavenko, Dean Schnabel, Chase Brownstein, Scott
Hartman, modified by T. Michael Keesey, T. Michael Keesey (after
Masteraah), DW Bapst, modified from Ishitani et al. 2016, Collin Gross,
Felix Vaux, Caleb M. Brown, Robert Gay, Wynston Cooper (photo) and
Albertonykus (silhouette), C. Camilo Julián-Caballero, Noah Schlottman,
Frank Förster (based on a picture by Jerry Kirkhart; modified by T.
Michael Keesey), Dr. Thomas G. Barnes, USFWS, Mario Quevedo, Cristina
Guijarro, Lafage, Amanda Katzer, Steven Coombs, Yan Wong from drawing in
The Century Dictionary (1911), Lisa Byrne, Becky Barnes, George Edward
Lodge (vectorized by T. Michael Keesey), Tauana J. Cunha, Dmitry
Bogdanov, James R. Spotila and Ray Chatterji, Matt Hayes, Ludwik
Gasiorowski, Martin R. Smith, after Skovsted et al 2015, Tracy A. Heath,
Mali’o Kodis, photograph by John Slapcinsky, Brad McFeeters (vectorized
by T. Michael Keesey), Metalhead64 (vectorized by T. Michael Keesey),
Didier Descouens (vectorized by T. Michael Keesey), Emily Willoughby,
Martin R. Smith, Fernando Carezzano, Beth Reinke, Kimberly Haddrell, J.
J. Harrison (photo) & T. Michael Keesey, Mali’o Kodis, photograph by P.
Funch and R.M. Kristensen, Jakovche, Christoph Schomburg, Pranav Iyer
(grey ideas), Sarah Werning, T. Michael Keesey (after Joseph Wolf),
CNZdenek, Roberto Díaz Sibaja, Jaime Headden, Sergio A. Muñoz-Gómez,
Mali’o Kodis, photograph by G. Giribet, Vijay Cavale (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Pete Buchholz,
Ingo Braasch, T. Michael Keesey (after C. De Muizon), Hans Hillewaert
(vectorized by T. Michael Keesey), Alexander Schmidt-Lebuhn, Peileppe,
Pearson Scott Foresman (vectorized by T. Michael Keesey), Sibi
(vectorized by T. Michael Keesey), Dmitry Bogdanov (modified by T.
Michael Keesey), Oscar Sanisidro, Haplochromis (vectorized by T. Michael
Keesey), Rebecca Groom, Tony Ayling (vectorized by Milton Tan), Michael
Scroggie, from original photograph by Gary M. Stolz, USFWS (original
photograph in public domain)., Emil Schmidt (vectorized by Maxime
Dahirel), Mathilde Cordellier, Noah Schlottman, photo by Hans De Blauwe,
Abraão Leite, Jose Carlos Arenas-Monroy, Carlos Cano-Barbacil, Tambja
(vectorized by T. Michael Keesey), Gabriela Palomo-Munoz, Rafael Maia,
Anthony Caravaggi, Jimmy Bernot, Antonov (vectorized by T. Michael
Keesey), Craig Dylke, Noah Schlottman, photo by Antonio Guillén, Jan A.
Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized
by T. Michael Keesey), Chris Jennings (Risiatto), Caio Bernardes,
vectorized by Zimices, Zsoldos Márton (vectorized by T. Michael Keesey),
SecretJellyMan, Luc Viatour (source photo) and Andreas Plank,
Lukasiniho, Juan Carlos Jerí, Crystal Maier, Roger Witter, vectorized by
Zimices, Jack Mayer Wood, Steven Haddock • Jellywatch.org, Matt
Martyniuk, Mathew Wedel, Joedison Rocha, Hans Hillewaert, Philippe
Janvier (vectorized by T. Michael Keesey), Owen Jones (derived from a
CC-BY 2.0 photograph by Paulo B. Chaves), Renato Santos, Mali’o Kodis,
photograph by Bruno Vellutini, Mali’o Kodis, image from the Smithsonian
Institution, zoosnow, Tyler McCraney, Michele Tobias, T. Michael Keesey
(after James & al.), Tony Ayling, Matt Martyniuk (vectorized by T.
Michael Keesey), Yan Wong from drawing by T. F. Zimmermann, Pollyanna
von Knorring and T. Michael Keesey, Cesar Julian, Michael Scroggie,
Mareike C. Janiak, Samanta Orellana, Ville-Veikko Sinkkonen, Mali’o
Kodis, photograph by Hans Hillewaert, Christine Axon, Heinrich Harder
(vectorized by T. Michael Keesey), B. Duygu Özpolat, Julio Garza,
Alexandre Vong, Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric
M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus,
Shyamal, T. Michael Keesey (after Mivart), Stanton F. Fink, vectorized
by Zimices, Elizabeth Parker, Ville Koistinen (vectorized by T. Michael
Keesey), Terpsichores, Kailah Thorn & Ben King, Michael Ströck
(vectorized by T. Michael Keesey), JJ Harrison (vectorized by T. Michael
Keesey), Melissa Broussard, U.S. Fish and Wildlife Service
(illustration) and Timothy J. Bartley (silhouette), Andreas Preuss /
marauder, Charles Doolittle Walcott (vectorized by T. Michael Keesey),
Conty (vectorized by T. Michael Keesey), Mike Hanson, Burton Robert,
USFWS, xgirouxb, mystica, Davidson Sodré, Sam Fraser-Smith (vectorized
by T. Michael Keesey), Meyer-Wachsmuth I, Curini Galletti M, Jondelius U
(<doi:10.1371/journal.pone.0107688>). Vectorization by Y. Wong, T.
Michael Keesey (after Heinrich Harder), Joseph Wolf, 1863 (vectorization
by Dinah Challen), Smokeybjb, George Edward Lodge (modified by T.
Michael Keesey), Noah Schlottman, photo by Museum of Geology, University
of Tartu, Mali’o Kodis, drawing by Manvir Singh, Christopher Chávez,
Dori <dori@merr.info> (source photo) and Nevit Dilmen, Sean McCann,
Michael P. Taylor, Matthias Buschmann (vectorized by T. Michael Keesey),
T. Michael Keesey (vectorization); Thorsten Assmann, Jörn Buse, Claudia
Drees, Ariel-Leib-Leonid Friedman, Tal Levanony, Andrea Matern, Anika
Timm, and David W. Wrase (photography), Danielle Alba, Chloé Schmidt,
Nobu Tamura (vectorized by A. Verrière), Bennet McComish, photo by Hans
Hillewaert, Yan Wong, Gopal Murali, Nina Skinner, Hanyong Pu, Yoshitsugu
Kobayashi, Junchang Lü, Li Xu, Yanhua Wu, Huali Chang, Jiming Zhang,
Songhai Jia & T. Michael Keesey, Maxime Dahirel (digitisation), Kees van
Achterberg et al (doi: 10.3897/BDJ.8.e49017)(original publication),
Auckland Museum and T. Michael Keesey, Lankester Edwin Ray (vectorized
by T. Michael Keesey), Jake Warner, David Sim (photograph) and T.
Michael Keesey (vectorization), Baheerathan Murugavel, Javier Luque &
Sarah Gerken, Darren Naish, Nemo, and T. Michael Keesey, Dave Souza
(vectorized by T. Michael Keesey), Scott Hartman (modified by T. Michael
Keesey), Jesús Gómez, vectorized by Zimices, Johan Lindgren, Michael W.
Caldwell, Takuya Konishi, Luis M. Chiappe, Noah Schlottman, photo by
Casey Dunn, Mattia Menchetti, Blanco et al., 2014, vectorized by
Zimices, Nancy Wyman (photo), John E. McCormack, Michael G. Harvey,
Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T.
Brumfield & T. Michael Keesey, Campbell Fleming, JCGiron, Andrew A.
Farke, shell lines added by Yan Wong, Ben Moon, Stanton F. Fink
(vectorized by T. Michael Keesey), Matt Martyniuk (modified by
Serenchia), Rainer Schoch, wsnaccad, Geoff Shaw, Liftarn, T. Michael
Keesey and Tanetahi, FunkMonk, Smokeybjb, vectorized by Zimices, Maxwell
Lefroy (vectorized by T. Michael Keesey), Matt Celeskey, Mo Hassan,
Qiang Ou, Audrey Ely, Daniel Jaron, Darren Naish (vectorized by T.
Michael Keesey), Doug Backlund (photo), John E. McCormack, Michael G.
Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb
T. Brumfield & T. Michael Keesey, Milton Tan, Kanako Bessho-Uehara,
Jaime Headden, modified by T. Michael Keesey

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                               |
| --: | ------------: | ------------: | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    632.841900 |    673.387201 | Harold N Eyster                                                                                                                                                                      |
|   2 |    102.332197 |    618.980566 | Katie S. Collins                                                                                                                                                                     |
|   3 |    311.129453 |    657.918901 | Pedro de Siracusa                                                                                                                                                                    |
|   4 |    549.006687 |    226.064145 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
|   5 |    433.796271 |     51.157288 | Neil Kelley                                                                                                                                                                          |
|   6 |    239.904797 |     88.427336 | NA                                                                                                                                                                                   |
|   7 |    532.173196 |    702.566604 | Florian Pfaff                                                                                                                                                                        |
|   8 |    944.240805 |    263.315697 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
|   9 |    649.156525 |    566.050944 | Kamil S. Jaron                                                                                                                                                                       |
|  10 |    768.844714 |    354.688434 | Jebulon (vectorized by T. Michael Keesey)                                                                                                                                            |
|  11 |    111.756949 |     79.354953 | (after McCulloch 1908)                                                                                                                                                               |
|  12 |    105.499132 |    448.732253 | Armin Reindl                                                                                                                                                                         |
|  13 |    120.328318 |    239.999654 | Andreas Trepte (vectorized by T. Michael Keesey)                                                                                                                                     |
|  14 |    218.152496 |    461.859458 | Scott Hartman                                                                                                                                                                        |
|  15 |    258.102856 |    215.491496 | Steven Traver                                                                                                                                                                        |
|  16 |    588.408209 |     69.185718 | Steven Traver                                                                                                                                                                        |
|  17 |    924.627459 |    554.793063 | NA                                                                                                                                                                                   |
|  18 |    542.470183 |    325.591993 | Jiekun He                                                                                                                                                                            |
|  19 |    605.248553 |    431.650170 | L. Shyamal                                                                                                                                                                           |
|  20 |    957.375614 |    189.386128 | Margot Michaud                                                                                                                                                                       |
|  21 |    682.341638 |    420.236458 | Steven Traver                                                                                                                                                                        |
|  22 |     92.940350 |    737.255178 | Ferran Sayol                                                                                                                                                                         |
|  23 |    425.412286 |    556.399000 | Joanna Wolfe                                                                                                                                                                         |
|  24 |    771.368175 |     64.605752 | Michael Scroggie, from original photograph by John Bettaso, USFWS (original photograph in public domain).                                                                            |
|  25 |    352.784546 |    403.060058 | Steven Traver                                                                                                                                                                        |
|  26 |    541.162015 |    582.562102 | Steven Traver                                                                                                                                                                        |
|  27 |    894.870851 |    718.990418 | Jagged Fang Designs                                                                                                                                                                  |
|  28 |    897.925924 |    657.894085 | Zimices                                                                                                                                                                              |
|  29 |    883.239737 |    465.295134 | Ferran Sayol                                                                                                                                                                         |
|  30 |    888.642276 |    130.266522 | Nobu Tamura                                                                                                                                                                          |
|  31 |    255.483990 |    313.649448 | SauropodomorphMonarch                                                                                                                                                                |
|  32 |    735.145753 |    602.720515 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                                          |
|  33 |    719.204422 |    738.822910 | Steven Traver                                                                                                                                                                        |
|  34 |    484.543044 |    135.963955 | Catherine Yasuda                                                                                                                                                                     |
|  35 |    875.968538 |    235.265110 | Jagged Fang Designs                                                                                                                                                                  |
|  36 |    252.373715 |    575.729371 | Zimices                                                                                                                                                                              |
|  37 |    565.543837 |    485.376971 | Ferran Sayol                                                                                                                                                                         |
|  38 |    751.212915 |    521.494310 | Kai R. Caspar                                                                                                                                                                        |
|  39 |    409.455186 |    704.161345 | Aleksey Nagovitsyn (vectorized by T. Michael Keesey)                                                                                                                                 |
|  40 |    487.221699 |    444.171919 | Jagged Fang Designs                                                                                                                                                                  |
|  41 |     41.537429 |    212.624323 | Tyler Greenfield                                                                                                                                                                     |
|  42 |    255.653131 |     28.813391 | Chris huh                                                                                                                                                                            |
|  43 |    247.456345 |    742.628604 | Steven Traver                                                                                                                                                                        |
|  44 |    654.858601 |    290.978618 | Lauren Anderson                                                                                                                                                                      |
|  45 |    379.201863 |    316.720413 | Iain Reid                                                                                                                                                                            |
|  46 |    863.484428 |    309.134283 | Scott Reid                                                                                                                                                                           |
|  47 |    970.933342 |    457.919573 | Armin Reindl                                                                                                                                                                         |
|  48 |    750.462321 |    134.170557 | NA                                                                                                                                                                                   |
|  49 |    406.199138 |    464.896991 | Zimices                                                                                                                                                                              |
|  50 |    802.717974 |    272.463494 | New York Zoological Society                                                                                                                                                          |
|  51 |    843.522634 |    412.240895 | Lukas Panzarin                                                                                                                                                                       |
|  52 |    597.865879 |    157.312341 | Arthur Weasley (vectorized by T. Michael Keesey)                                                                                                                                     |
|  53 |    877.983988 |    755.418606 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
|  54 |    934.165822 |     43.415824 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                                                          |
|  55 |    368.875441 |    126.711135 | Scott Hartman                                                                                                                                                                        |
|  56 |    479.108977 |    402.091333 | Gareth Monger                                                                                                                                                                        |
|  57 |    326.675249 |    147.574932 | Margot Michaud                                                                                                                                                                       |
|  58 |    437.221218 |    367.468303 | Joseph J. W. Sertich, Mark A. Loewen                                                                                                                                                 |
|  59 |    295.211553 |    503.128969 | Matthew E. Clapham                                                                                                                                                                   |
|  60 |    839.398704 |    190.712142 | Zimices                                                                                                                                                                              |
|  61 |    613.888691 |    582.959451 | DW Bapst (modified from Bates et al., 2005)                                                                                                                                          |
|  62 |    946.450579 |    603.180292 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                                         |
|  63 |    756.135098 |    645.273787 | T. Michael Keesey                                                                                                                                                                    |
|  64 |    985.659183 |    116.116878 | Maija Karala                                                                                                                                                                         |
|  65 |     28.750261 |    523.314606 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey)                |
|  66 |    934.725315 |    376.123599 | Daniel Stadtmauer                                                                                                                                                                    |
|  67 |    315.424154 |    287.801509 | Tasman Dixon                                                                                                                                                                         |
|  68 |    200.049428 |    393.921829 | NA                                                                                                                                                                                   |
|  69 |    478.495207 |    726.565200 | Gareth Monger                                                                                                                                                                        |
|  70 |    605.071004 |     14.591759 | M Kolmann                                                                                                                                                                            |
|  71 |   1002.573759 |    649.948949 | Matt Crook                                                                                                                                                                           |
|  72 |    138.582798 |    182.497769 | Birgit Lang                                                                                                                                                                          |
|  73 |    490.639853 |    112.866897 | Michelle Site                                                                                                                                                                        |
|  74 |    778.042930 |    115.584048 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                                                          |
|  75 |    215.545794 |      9.265583 | Walter Vladimir                                                                                                                                                                      |
|  76 |    800.074271 |    710.728845 | Sharon Wegner-Larsen                                                                                                                                                                 |
|  77 |    168.759185 |    422.749605 | NA                                                                                                                                                                                   |
|  78 |    967.016125 |    297.774851 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
|  79 |    897.786854 |    358.833820 | Scott Hartman                                                                                                                                                                        |
|  80 |     30.090759 |    440.079473 | Katie S. Collins                                                                                                                                                                     |
|  81 |    567.945045 |    432.133598 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                                          |
|  82 |    312.252656 |    364.259434 | Andrew A. Farke                                                                                                                                                                      |
|  83 |    418.103516 |    156.139244 | Michelle Site                                                                                                                                                                        |
|  84 |     25.485117 |    693.693254 | terngirl                                                                                                                                                                             |
|  85 |    617.784265 |    255.089258 | Alex Slavenko                                                                                                                                                                        |
|  86 |    249.506311 |    648.220142 | Dean Schnabel                                                                                                                                                                        |
|  87 |    943.355240 |    284.261682 | Chase Brownstein                                                                                                                                                                     |
|  88 |    973.446843 |    222.922629 | Scott Hartman                                                                                                                                                                        |
|  89 |    814.319197 |    640.606022 | Katie S. Collins                                                                                                                                                                     |
|  90 |    413.537514 |    630.125896 | T. Michael Keesey                                                                                                                                                                    |
|  91 |    341.245958 |    566.560678 | NA                                                                                                                                                                                   |
|  92 |     97.898482 |    171.335174 | Margot Michaud                                                                                                                                                                       |
|  93 |     44.884562 |     48.127322 | Scott Hartman, modified by T. Michael Keesey                                                                                                                                         |
|  94 |    589.864481 |    563.046354 | T. Michael Keesey (after Masteraah)                                                                                                                                                  |
|  95 |    138.155470 |    754.050586 | DW Bapst, modified from Ishitani et al. 2016                                                                                                                                         |
|  96 |    341.041699 |     70.797907 | Collin Gross                                                                                                                                                                         |
|  97 |    730.855645 |    482.913129 | Margot Michaud                                                                                                                                                                       |
|  98 |    734.045725 |    192.047135 | NA                                                                                                                                                                                   |
|  99 |    808.561792 |    781.571157 | Ferran Sayol                                                                                                                                                                         |
| 100 |    338.335954 |    593.066049 | Zimices                                                                                                                                                                              |
| 101 |    362.662283 |     55.503034 | Felix Vaux                                                                                                                                                                           |
| 102 |    167.643220 |    119.887478 | Matt Crook                                                                                                                                                                           |
| 103 |    212.922116 |    507.230701 | Caleb M. Brown                                                                                                                                                                       |
| 104 |     19.061602 |     56.878975 | Robert Gay                                                                                                                                                                           |
| 105 |    943.174974 |    664.954491 | Wynston Cooper (photo) and Albertonykus (silhouette)                                                                                                                                 |
| 106 |    795.684980 |    741.690972 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 107 |    924.775835 |    401.455054 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 108 |    238.937757 |    511.669120 | Noah Schlottman                                                                                                                                                                      |
| 109 |     46.848965 |    343.838838 | Frank Förster (based on a picture by Jerry Kirkhart; modified by T. Michael Keesey)                                                                                                  |
| 110 |    500.781419 |    379.399640 | Ferran Sayol                                                                                                                                                                         |
| 111 |    855.817310 |    587.000023 | Dr. Thomas G. Barnes, USFWS                                                                                                                                                          |
| 112 |     36.452968 |    606.425979 | Matt Crook                                                                                                                                                                           |
| 113 |    884.314474 |     83.962255 | Mario Quevedo                                                                                                                                                                        |
| 114 |    942.410664 |    223.433681 | Dean Schnabel                                                                                                                                                                        |
| 115 |     15.619759 |    349.022923 | Cristina Guijarro                                                                                                                                                                    |
| 116 |    919.539838 |     70.239886 | Lafage                                                                                                                                                                               |
| 117 |    268.095423 |    442.847687 | Amanda Katzer                                                                                                                                                                        |
| 118 |    155.965405 |    718.735013 | Zimices                                                                                                                                                                              |
| 119 |    572.018902 |    704.107842 | Steven Coombs                                                                                                                                                                        |
| 120 |    761.414718 |    413.590566 | Yan Wong from drawing in The Century Dictionary (1911)                                                                                                                               |
| 121 |    953.941329 |    612.178158 | Lisa Byrne                                                                                                                                                                           |
| 122 |     55.021089 |     20.478720 | Michelle Site                                                                                                                                                                        |
| 123 |    971.816132 |    315.335169 | Becky Barnes                                                                                                                                                                         |
| 124 |    460.776000 |    280.547783 | Steven Coombs                                                                                                                                                                        |
| 125 |    519.199887 |    277.613124 | L. Shyamal                                                                                                                                                                           |
| 126 |    231.025966 |    301.456017 | Kai R. Caspar                                                                                                                                                                        |
| 127 |    379.969139 |    775.960355 | George Edward Lodge (vectorized by T. Michael Keesey)                                                                                                                                |
| 128 |    938.229173 |    699.155269 | T. Michael Keesey                                                                                                                                                                    |
| 129 |    789.883546 |    760.716934 | Jagged Fang Designs                                                                                                                                                                  |
| 130 |    937.152420 |     77.856071 | Tauana J. Cunha                                                                                                                                                                      |
| 131 |    709.293799 |     13.707301 | SauropodomorphMonarch                                                                                                                                                                |
| 132 |    431.058979 |    635.083230 | Becky Barnes                                                                                                                                                                         |
| 133 |    147.871207 |    788.748813 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 134 |    922.963715 |    179.567690 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 135 |    642.176474 |    358.704413 | Dmitry Bogdanov                                                                                                                                                                      |
| 136 |    994.372343 |    773.809829 | James R. Spotila and Ray Chatterji                                                                                                                                                   |
| 137 |    335.814929 |    791.547819 | Ferran Sayol                                                                                                                                                                         |
| 138 |    273.569200 |    234.151302 | Matt Hayes                                                                                                                                                                           |
| 139 |    192.947778 |    426.033277 | Steven Traver                                                                                                                                                                        |
| 140 |    822.950928 |    540.793644 | NA                                                                                                                                                                                   |
| 141 |     96.373812 |    287.887970 | Ludwik Gasiorowski                                                                                                                                                                   |
| 142 |    995.207194 |      4.979262 | Martin R. Smith, after Skovsted et al 2015                                                                                                                                           |
| 143 |    210.007805 |    635.948346 | NA                                                                                                                                                                                   |
| 144 |    399.771145 |    517.611368 | Tracy A. Heath                                                                                                                                                                       |
| 145 |    875.422375 |     18.422822 | NA                                                                                                                                                                                   |
| 146 |    878.428607 |    594.912028 | Steven Traver                                                                                                                                                                        |
| 147 |    247.515074 |    617.285625 | Mali’o Kodis, photograph by John Slapcinsky                                                                                                                                          |
| 148 |    166.582978 |    795.829924 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                                     |
| 149 |    177.599794 |    733.156311 | Matt Crook                                                                                                                                                                           |
| 150 |    210.051644 |    144.105301 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 151 |    865.591814 |     96.881811 | Zimices                                                                                                                                                                              |
| 152 |    533.321216 |    533.120837 | Margot Michaud                                                                                                                                                                       |
| 153 |    313.259299 |    727.087680 | Metalhead64 (vectorized by T. Michael Keesey)                                                                                                                                        |
| 154 |    526.770352 |    653.249346 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                                   |
| 155 |    130.880116 |    784.500231 | Ferran Sayol                                                                                                                                                                         |
| 156 |    195.707773 |    612.757684 | Emily Willoughby                                                                                                                                                                     |
| 157 |    247.925085 |    401.669424 | Martin R. Smith                                                                                                                                                                      |
| 158 |    377.324261 |    421.063385 | Steven Traver                                                                                                                                                                        |
| 159 |    663.663313 |    501.536770 | Dmitry Bogdanov                                                                                                                                                                      |
| 160 |    993.981605 |    354.082613 | Scott Hartman                                                                                                                                                                        |
| 161 |    248.452787 |    314.881616 | T. Michael Keesey                                                                                                                                                                    |
| 162 |    940.133934 |    209.448974 | Fernando Carezzano                                                                                                                                                                   |
| 163 |    559.660380 |    744.463798 | Beth Reinke                                                                                                                                                                          |
| 164 |    109.032606 |    684.841228 | Scott Hartman                                                                                                                                                                        |
| 165 |     39.048028 |    767.608442 | Gareth Monger                                                                                                                                                                        |
| 166 |    740.164016 |    380.923211 | Tauana J. Cunha                                                                                                                                                                      |
| 167 |    636.957796 |    459.648576 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 168 |    251.389952 |    140.937838 | Iain Reid                                                                                                                                                                            |
| 169 |    665.618581 |    155.586503 | Margot Michaud                                                                                                                                                                       |
| 170 |    161.521577 |    165.381720 | Jebulon (vectorized by T. Michael Keesey)                                                                                                                                            |
| 171 |    892.255263 |    784.102878 | Kimberly Haddrell                                                                                                                                                                    |
| 172 |    418.491736 |    345.680596 | Scott Hartman                                                                                                                                                                        |
| 173 |    164.836216 |    311.235465 | J. J. Harrison (photo) & T. Michael Keesey                                                                                                                                           |
| 174 |    828.083920 |    572.116474 | Noah Schlottman                                                                                                                                                                      |
| 175 |    794.985936 |    675.551178 | NA                                                                                                                                                                                   |
| 176 |    885.044326 |    281.308341 | Mali’o Kodis, photograph by P. Funch and R.M. Kristensen                                                                                                                             |
| 177 |    691.844416 |    467.630702 | NA                                                                                                                                                                                   |
| 178 |    588.031870 |    611.247179 | Margot Michaud                                                                                                                                                                       |
| 179 |    535.497390 |    273.330484 | Jakovche                                                                                                                                                                             |
| 180 |    909.421344 |     22.950029 | Matt Crook                                                                                                                                                                           |
| 181 |    768.821417 |     19.902710 | Christoph Schomburg                                                                                                                                                                  |
| 182 |    813.477250 |    141.090503 | Scott Hartman                                                                                                                                                                        |
| 183 |    833.937199 |    301.071307 | Pranav Iyer (grey ideas)                                                                                                                                                             |
| 184 |    602.585309 |    666.661166 | NA                                                                                                                                                                                   |
| 185 |     42.666736 |    650.659902 | Sarah Werning                                                                                                                                                                        |
| 186 |     15.874950 |    229.839245 | T. Michael Keesey (after Joseph Wolf)                                                                                                                                                |
| 187 |    510.039373 |     19.130283 | CNZdenek                                                                                                                                                                             |
| 188 |    368.466745 |    317.810270 | Margot Michaud                                                                                                                                                                       |
| 189 |    677.479454 |    318.170120 | Steven Traver                                                                                                                                                                        |
| 190 |    484.965925 |    490.581189 | T. Michael Keesey                                                                                                                                                                    |
| 191 |    452.628556 |    619.315151 | Tracy A. Heath                                                                                                                                                                       |
| 192 |   1016.533843 |    550.524363 | Matt Crook                                                                                                                                                                           |
| 193 |    791.839475 |    135.576934 | Ferran Sayol                                                                                                                                                                         |
| 194 |    546.409237 |    642.111975 | Jagged Fang Designs                                                                                                                                                                  |
| 195 |    389.270452 |    769.218752 | Emily Willoughby                                                                                                                                                                     |
| 196 |    854.586699 |    556.372847 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 197 |    377.042858 |     35.103150 | Jaime Headden                                                                                                                                                                        |
| 198 |     24.715956 |    648.039604 | Sergio A. Muñoz-Gómez                                                                                                                                                                |
| 199 |     18.859492 |    789.207794 | Mali’o Kodis, photograph by G. Giribet                                                                                                                                               |
| 200 |    889.152323 |    106.183815 | Gareth Monger                                                                                                                                                                        |
| 201 |    139.261436 |    291.417334 | Jebulon (vectorized by T. Michael Keesey)                                                                                                                                            |
| 202 |    438.143238 |    780.080998 | Vijay Cavale (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                         |
| 203 |    990.200912 |    539.636403 | Margot Michaud                                                                                                                                                                       |
| 204 |    427.514774 |    784.541015 | Pete Buchholz                                                                                                                                                                        |
| 205 |    156.041804 |     19.803088 | Ingo Braasch                                                                                                                                                                         |
| 206 |    900.747823 |    157.637754 | T. Michael Keesey (after C. De Muizon)                                                                                                                                               |
| 207 |    369.499650 |    284.052631 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 208 |    829.544350 |    782.058840 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                                    |
| 209 |    463.288745 |    607.775615 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 210 |   1000.423546 |    313.633799 | Peileppe                                                                                                                                                                             |
| 211 |    699.164717 |    519.297508 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                                             |
| 212 |    324.898175 |    347.887253 | Sibi (vectorized by T. Michael Keesey)                                                                                                                                               |
| 213 |    485.396155 |    515.814004 | T. Michael Keesey                                                                                                                                                                    |
| 214 |    105.280914 |    324.178134 | Ferran Sayol                                                                                                                                                                         |
| 215 |     22.904861 |    368.316463 | Sarah Werning                                                                                                                                                                        |
| 216 |      9.859337 |    423.626776 | Beth Reinke                                                                                                                                                                          |
| 217 |    608.972582 |    679.408712 | Dmitry Bogdanov (modified by T. Michael Keesey)                                                                                                                                      |
| 218 |    329.350099 |    354.943517 | Scott Hartman                                                                                                                                                                        |
| 219 |   1009.660737 |    219.016577 | Collin Gross                                                                                                                                                                         |
| 220 |    537.412494 |    719.185226 | Steven Traver                                                                                                                                                                        |
| 221 |    924.971202 |    294.849033 | Ludwik Gasiorowski                                                                                                                                                                   |
| 222 |    443.891249 |    645.164119 | Gareth Monger                                                                                                                                                                        |
| 223 |    775.232872 |    436.471992 | Oscar Sanisidro                                                                                                                                                                      |
| 224 |    453.226470 |    784.455572 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                                       |
| 225 |    898.113567 |    277.710802 | Rebecca Groom                                                                                                                                                                        |
| 226 |     19.095905 |     92.292350 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 227 |   1001.777383 |    413.187949 | Margot Michaud                                                                                                                                                                       |
| 228 |    602.939408 |    354.594491 | Scott Hartman                                                                                                                                                                        |
| 229 |    735.251810 |    558.633566 | Tony Ayling (vectorized by Milton Tan)                                                                                                                                               |
| 230 |    817.415506 |    511.141122 | Sergio A. Muñoz-Gómez                                                                                                                                                                |
| 231 |    945.082422 |    345.730095 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                                   |
| 232 |    204.692208 |    200.785472 | Michael Scroggie, from original photograph by Gary M. Stolz, USFWS (original photograph in public domain).                                                                           |
| 233 |    928.120925 |    657.520604 | Emil Schmidt (vectorized by Maxime Dahirel)                                                                                                                                          |
| 234 |    366.131915 |    660.601175 | Ferran Sayol                                                                                                                                                                         |
| 235 |    617.473567 |     29.771245 | Margot Michaud                                                                                                                                                                       |
| 236 |    707.259008 |    447.239508 | Ferran Sayol                                                                                                                                                                         |
| 237 |    594.454197 |    788.778517 | Ferran Sayol                                                                                                                                                                         |
| 238 |    915.428406 |    309.418858 | Steven Coombs                                                                                                                                                                        |
| 239 |    167.042053 |    364.540223 | Chris huh                                                                                                                                                                            |
| 240 |    341.252638 |    662.590277 | Mathilde Cordellier                                                                                                                                                                  |
| 241 |    971.155454 |    337.408453 | Zimices                                                                                                                                                                              |
| 242 |     92.892102 |    307.668548 | Noah Schlottman, photo by Hans De Blauwe                                                                                                                                             |
| 243 |    560.368326 |    572.482060 | Mathilde Cordellier                                                                                                                                                                  |
| 244 |    652.104091 |     32.073496 | Ferran Sayol                                                                                                                                                                         |
| 245 |    420.210866 |    315.921443 | Tasman Dixon                                                                                                                                                                         |
| 246 |     11.525660 |    178.348998 | Gareth Monger                                                                                                                                                                        |
| 247 |    424.578551 |    530.569504 | NA                                                                                                                                                                                   |
| 248 |    503.656619 |    504.027872 | NA                                                                                                                                                                                   |
| 249 |   1005.040669 |    780.937916 | Scott Reid                                                                                                                                                                           |
| 250 |    326.251841 |    769.377892 | Zimices                                                                                                                                                                              |
| 251 |    681.850546 |    525.156356 | Abraão Leite                                                                                                                                                                         |
| 252 |    840.523691 |    112.798550 | Margot Michaud                                                                                                                                                                       |
| 253 |    365.120818 |    620.400499 | Jose Carlos Arenas-Monroy                                                                                                                                                            |
| 254 |    340.985012 |     39.068403 | T. Michael Keesey                                                                                                                                                                    |
| 255 |    966.601514 |    358.452810 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 256 |    999.887744 |     17.295548 | Matt Crook                                                                                                                                                                           |
| 257 |    102.421817 |    673.183970 | Tambja (vectorized by T. Michael Keesey)                                                                                                                                             |
| 258 |    911.655852 |    205.763975 | Zimices                                                                                                                                                                              |
| 259 |    974.294065 |    393.503287 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 260 |    189.297614 |     22.024183 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 261 |    363.564699 |    570.475250 | Gareth Monger                                                                                                                                                                        |
| 262 |    184.503553 |    351.809243 | Rafael Maia                                                                                                                                                                          |
| 263 |    454.021287 |    345.196633 | Matt Crook                                                                                                                                                                           |
| 264 |    189.008064 |    772.853427 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 265 |    334.033128 |    217.828442 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 266 |    669.858573 |    773.445633 | Steven Traver                                                                                                                                                                        |
| 267 |    893.375740 |    679.793354 | NA                                                                                                                                                                                   |
| 268 |    859.287631 |     31.476039 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 269 |    934.915542 |    105.533541 | Zimices                                                                                                                                                                              |
| 270 |    205.197223 |    783.840621 | Dmitry Bogdanov (modified by T. Michael Keesey)                                                                                                                                      |
| 271 |    175.182383 |    242.337735 | Anthony Caravaggi                                                                                                                                                                    |
| 272 |    571.545382 |    661.460642 | T. Michael Keesey                                                                                                                                                                    |
| 273 |    680.427393 |    643.062573 | Gareth Monger                                                                                                                                                                        |
| 274 |    565.394157 |    117.931212 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 275 |    584.635512 |    685.704743 | Christoph Schomburg                                                                                                                                                                  |
| 276 |    698.845084 |    656.336953 | Sarah Werning                                                                                                                                                                        |
| 277 |     87.277747 |    272.829750 | Kamil S. Jaron                                                                                                                                                                       |
| 278 |    366.618679 |    733.163453 | Jimmy Bernot                                                                                                                                                                         |
| 279 |    513.732734 |    170.819943 | Matt Crook                                                                                                                                                                           |
| 280 |    967.494590 |    694.313442 | Zimices                                                                                                                                                                              |
| 281 |    237.041325 |    153.410753 | Zimices                                                                                                                                                                              |
| 282 |    309.862187 |    262.570656 | Antonov (vectorized by T. Michael Keesey)                                                                                                                                            |
| 283 |    592.982848 |    103.969120 | Christoph Schomburg                                                                                                                                                                  |
| 284 |    688.848118 |    661.735814 | Kai R. Caspar                                                                                                                                                                        |
| 285 |    576.762990 |    284.448876 | Margot Michaud                                                                                                                                                                       |
| 286 |    330.700581 |    315.337620 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 287 |    347.453651 |    763.189420 | Craig Dylke                                                                                                                                                                          |
| 288 |    867.829454 |    449.724245 | Steven Traver                                                                                                                                                                        |
| 289 |    376.246291 |    371.664714 | Gareth Monger                                                                                                                                                                        |
| 290 |    279.812551 |    330.790501 | Nobu Tamura                                                                                                                                                                          |
| 291 |    302.302342 |    378.743300 | L. Shyamal                                                                                                                                                                           |
| 292 |    182.518953 |     57.093663 | Noah Schlottman, photo by Antonio Guillén                                                                                                                                            |
| 293 |    454.589145 |    780.005194 | Walter Vladimir                                                                                                                                                                      |
| 294 |    228.263062 |    438.815327 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                                  |
| 295 |    465.013288 |    111.423325 | Steven Traver                                                                                                                                                                        |
| 296 |    254.441836 |    229.086668 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 297 |    446.507892 |    324.826586 | Chris huh                                                                                                                                                                            |
| 298 |    197.375221 |    672.430561 | Matt Crook                                                                                                                                                                           |
| 299 |    746.789386 |    302.597204 | Chris Jennings (Risiatto)                                                                                                                                                            |
| 300 |    140.050590 |    583.108903 | Amanda Katzer                                                                                                                                                                        |
| 301 |    630.909645 |    514.210138 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 302 |    576.250000 |    410.058898 | Caio Bernardes, vectorized by Zimices                                                                                                                                                |
| 303 |    553.860375 |    262.760514 | NA                                                                                                                                                                                   |
| 304 |    332.016406 |     12.337740 | Anthony Caravaggi                                                                                                                                                                    |
| 305 |    500.771398 |     79.952314 | Matt Crook                                                                                                                                                                           |
| 306 |    720.629699 |    545.522207 | Scott Hartman                                                                                                                                                                        |
| 307 |    999.118461 |    218.381397 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                                    |
| 308 |    672.816604 |     33.112079 | Margot Michaud                                                                                                                                                                       |
| 309 |    212.987865 |    264.265435 | Zimices                                                                                                                                                                              |
| 310 |    800.252476 |    457.678452 | Matt Crook                                                                                                                                                                           |
| 311 |    690.165872 |    785.079435 | NA                                                                                                                                                                                   |
| 312 |   1007.348579 |    276.895078 | Zsoldos Márton (vectorized by T. Michael Keesey)                                                                                                                                     |
| 313 |    752.356726 |    676.273451 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 314 |    680.581443 |    576.736993 | Arthur Weasley (vectorized by T. Michael Keesey)                                                                                                                                     |
| 315 |     58.448224 |    284.207502 | SecretJellyMan                                                                                                                                                                       |
| 316 |     70.656052 |    687.169435 | Steven Coombs                                                                                                                                                                        |
| 317 |    477.076537 |    624.601180 | Gareth Monger                                                                                                                                                                        |
| 318 |     44.693999 |    364.878877 | Luc Viatour (source photo) and Andreas Plank                                                                                                                                         |
| 319 |   1000.540698 |    692.325111 | Lukasiniho                                                                                                                                                                           |
| 320 |    380.013157 |     44.117946 | Juan Carlos Jerí                                                                                                                                                                     |
| 321 |     40.490845 |    416.482080 | Birgit Lang                                                                                                                                                                          |
| 322 |    832.940949 |    462.938050 | Crystal Maier                                                                                                                                                                        |
| 323 |    580.889635 |    579.561854 | Roger Witter, vectorized by Zimices                                                                                                                                                  |
| 324 |    846.467505 |    379.970377 | Chris huh                                                                                                                                                                            |
| 325 |    408.243888 |    618.587250 | Tasman Dixon                                                                                                                                                                         |
| 326 |    686.379276 |    496.196728 | Zimices                                                                                                                                                                              |
| 327 |    572.620076 |    273.730722 | Steven Traver                                                                                                                                                                        |
| 328 |    509.882585 |    640.095156 | Birgit Lang                                                                                                                                                                          |
| 329 |    871.561967 |     53.372379 | Zimices                                                                                                                                                                              |
| 330 |    580.292727 |    553.118410 | Jack Mayer Wood                                                                                                                                                                      |
| 331 |    845.199988 |      5.966963 | Zimices                                                                                                                                                                              |
| 332 |    362.393797 |    530.894622 | Steven Haddock • Jellywatch.org                                                                                                                                                      |
| 333 |    604.774360 |    320.797810 | NA                                                                                                                                                                                   |
| 334 |    706.672289 |    249.986966 | Tracy A. Heath                                                                                                                                                                       |
| 335 |    961.948129 |    660.762651 | Birgit Lang                                                                                                                                                                          |
| 336 |    645.928064 |    238.519037 | Steven Traver                                                                                                                                                                        |
| 337 |    189.158225 |    626.162795 | T. Michael Keesey                                                                                                                                                                    |
| 338 |    290.246035 |    104.612703 | Margot Michaud                                                                                                                                                                       |
| 339 |    677.637992 |    160.952941 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 340 |    999.786499 |    397.266797 | NA                                                                                                                                                                                   |
| 341 |    348.683756 |    235.163353 | Zimices                                                                                                                                                                              |
| 342 |    546.094320 |    792.321137 | Matt Martyniuk                                                                                                                                                                       |
| 343 |    279.129393 |     68.946906 | Mathew Wedel                                                                                                                                                                         |
| 344 |     60.394131 |     61.867336 | Zimices                                                                                                                                                                              |
| 345 |   1015.580100 |    388.188311 | Joedison Rocha                                                                                                                                                                       |
| 346 |    486.230633 |    645.753126 | Hans Hillewaert                                                                                                                                                                      |
| 347 |    772.297817 |    477.101124 | NA                                                                                                                                                                                   |
| 348 |    906.395610 |    287.419002 | Philippe Janvier (vectorized by T. Michael Keesey)                                                                                                                                   |
| 349 |    583.726080 |    531.463306 | Zimices                                                                                                                                                                              |
| 350 |    721.387177 |    234.355765 | Zimices                                                                                                                                                                              |
| 351 |    791.026611 |    690.410390 | Zimices                                                                                                                                                                              |
| 352 |    439.181223 |     20.214001 | Margot Michaud                                                                                                                                                                       |
| 353 |    548.310868 |    109.003723 | Gareth Monger                                                                                                                                                                        |
| 354 |    765.604629 |    204.569648 | Steven Traver                                                                                                                                                                        |
| 355 |    396.291184 |    632.569369 | Tracy A. Heath                                                                                                                                                                       |
| 356 |    109.474869 |    153.158339 | Oscar Sanisidro                                                                                                                                                                      |
| 357 |    909.143873 |    101.749728 | Michelle Site                                                                                                                                                                        |
| 358 |    294.537415 |    449.004117 | Zimices                                                                                                                                                                              |
| 359 |   1013.215650 |    741.915445 | Zimices                                                                                                                                                                              |
| 360 |    865.117097 |    112.984507 | Matt Crook                                                                                                                                                                           |
| 361 |    542.075249 |    373.761080 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 362 |    563.466003 |    448.875910 | Matt Martyniuk                                                                                                                                                                       |
| 363 |    679.439075 |    333.101127 | Yan Wong from drawing in The Century Dictionary (1911)                                                                                                                               |
| 364 |    815.233694 |    599.863896 | Owen Jones (derived from a CC-BY 2.0 photograph by Paulo B. Chaves)                                                                                                                  |
| 365 |    395.804665 |     15.260861 | Fernando Carezzano                                                                                                                                                                   |
| 366 |    151.637668 |    581.865041 | Jimmy Bernot                                                                                                                                                                         |
| 367 |    971.359183 |    733.732386 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 368 |    786.298941 |    663.081380 | Scott Reid                                                                                                                                                                           |
| 369 |    580.536213 |    259.180799 | Ingo Braasch                                                                                                                                                                         |
| 370 |    550.018840 |    626.850545 | Chris huh                                                                                                                                                                            |
| 371 |    850.855715 |    465.969704 | Matt Crook                                                                                                                                                                           |
| 372 |     28.185313 |    657.095204 | Michelle Site                                                                                                                                                                        |
| 373 |    248.391349 |    464.869772 | T. Michael Keesey                                                                                                                                                                    |
| 374 |    911.634682 |    782.429967 | Renato Santos                                                                                                                                                                        |
| 375 |    669.976251 |    375.859135 | Steven Traver                                                                                                                                                                        |
| 376 |    479.274572 |    600.954320 | Zimices                                                                                                                                                                              |
| 377 |    162.068669 |    782.374662 | Dmitry Bogdanov                                                                                                                                                                      |
| 378 |    175.042136 |    691.925897 | Matt Hayes                                                                                                                                                                           |
| 379 |     61.904742 |    756.513487 | Mali’o Kodis, photograph by Bruno Vellutini                                                                                                                                          |
| 380 |    166.370977 |    607.345466 | Margot Michaud                                                                                                                                                                       |
| 381 |    354.926584 |    259.504394 | Iain Reid                                                                                                                                                                            |
| 382 |    517.622945 |    545.689630 | Lukasiniho                                                                                                                                                                           |
| 383 |    205.496793 |    285.890263 | terngirl                                                                                                                                                                             |
| 384 |    965.965289 |    638.791419 | Margot Michaud                                                                                                                                                                       |
| 385 |    360.753247 |     11.571177 | Mali’o Kodis, image from the Smithsonian Institution                                                                                                                                 |
| 386 |   1008.211655 |    143.096683 | Tracy A. Heath                                                                                                                                                                       |
| 387 |    354.027871 |    290.229968 | zoosnow                                                                                                                                                                              |
| 388 |    182.185757 |    212.163935 | Tyler McCraney                                                                                                                                                                       |
| 389 |    221.838960 |    678.695217 | Chase Brownstein                                                                                                                                                                     |
| 390 |    922.221657 |    100.223482 | Ferran Sayol                                                                                                                                                                         |
| 391 |    380.029056 |    603.324628 | T. Michael Keesey                                                                                                                                                                    |
| 392 |    567.194147 |    637.983482 | Gareth Monger                                                                                                                                                                        |
| 393 |    683.358591 |    392.459000 | Collin Gross                                                                                                                                                                         |
| 394 |    976.688963 |     58.657130 | Michele Tobias                                                                                                                                                                       |
| 395 |    428.642423 |     12.535443 | T. Michael Keesey (after James & al.)                                                                                                                                                |
| 396 |    639.696802 |    782.735213 | Jagged Fang Designs                                                                                                                                                                  |
| 397 |    439.100070 |    335.849591 | Matt Crook                                                                                                                                                                           |
| 398 |    463.154839 |    423.683819 | Tony Ayling                                                                                                                                                                          |
| 399 |    829.108188 |    478.739583 | NA                                                                                                                                                                                   |
| 400 |    576.461969 |    390.615240 | Matt Crook                                                                                                                                                                           |
| 401 |     15.904647 |    251.334783 | Steven Traver                                                                                                                                                                        |
| 402 |    315.800157 |    760.120209 | Gareth Monger                                                                                                                                                                        |
| 403 |     71.184733 |     86.966272 | Ferran Sayol                                                                                                                                                                         |
| 404 |    271.963780 |    413.232543 | T. Michael Keesey                                                                                                                                                                    |
| 405 |    169.438027 |    138.887690 | Metalhead64 (vectorized by T. Michael Keesey)                                                                                                                                        |
| 406 |    132.150130 |    330.004558 | Dean Schnabel                                                                                                                                                                        |
| 407 |    155.254367 |    690.072582 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                                     |
| 408 |    814.170743 |    115.926846 | Jagged Fang Designs                                                                                                                                                                  |
| 409 |    266.527640 |    602.081889 | L. Shyamal                                                                                                                                                                           |
| 410 |    456.035010 |     96.667372 | Yan Wong from drawing by T. F. Zimmermann                                                                                                                                            |
| 411 |    281.458944 |    427.027280 | Matt Martyniuk                                                                                                                                                                       |
| 412 |    447.409724 |    629.520621 | Pollyanna von Knorring and T. Michael Keesey                                                                                                                                         |
| 413 |    146.357138 |    303.435839 | Steven Traver                                                                                                                                                                        |
| 414 |     64.675416 |    240.168645 | Ferran Sayol                                                                                                                                                                         |
| 415 |    466.406834 |    495.917694 | Maija Karala                                                                                                                                                                         |
| 416 |     66.822555 |    366.420796 | Sarah Werning                                                                                                                                                                        |
| 417 |   1015.852601 |    527.422823 | Christoph Schomburg                                                                                                                                                                  |
| 418 |    674.880643 |    350.033259 | Gareth Monger                                                                                                                                                                        |
| 419 |    154.480101 |    560.613324 | NA                                                                                                                                                                                   |
| 420 |    859.100051 |    778.603397 | Collin Gross                                                                                                                                                                         |
| 421 |    219.893238 |    628.799185 | Iain Reid                                                                                                                                                                            |
| 422 |    567.790784 |    402.099695 | Tracy A. Heath                                                                                                                                                                       |
| 423 |    833.875279 |    330.005086 | Dmitry Bogdanov                                                                                                                                                                      |
| 424 |    677.487680 |    226.383086 | Cesar Julian                                                                                                                                                                         |
| 425 |     20.002412 |    730.590256 | Michael Scroggie                                                                                                                                                                     |
| 426 |    346.418261 |    370.428542 | Scott Hartman                                                                                                                                                                        |
| 427 |    957.418487 |    753.543669 | NA                                                                                                                                                                                   |
| 428 |    286.865103 |    164.645999 | Matt Crook                                                                                                                                                                           |
| 429 |    708.954851 |    332.941600 | Michelle Site                                                                                                                                                                        |
| 430 |     34.404492 |    674.780914 | Gareth Monger                                                                                                                                                                        |
| 431 |    833.635207 |    734.600230 | Margot Michaud                                                                                                                                                                       |
| 432 |     47.313128 |    390.390726 | Mareike C. Janiak                                                                                                                                                                    |
| 433 |    199.786791 |    254.527067 | Samanta Orellana                                                                                                                                                                     |
| 434 |    656.554299 |     77.344223 | Gareth Monger                                                                                                                                                                        |
| 435 |     31.558037 |    398.737390 | Ville-Veikko Sinkkonen                                                                                                                                                               |
| 436 |    572.549053 |    668.536539 | NA                                                                                                                                                                                   |
| 437 |    945.817632 |    144.394287 | Michael Scroggie                                                                                                                                                                     |
| 438 |     25.009244 |    514.193645 | Chris huh                                                                                                                                                                            |
| 439 |    323.969762 |    118.839721 | Zimices                                                                                                                                                                              |
| 440 |    658.162422 |    236.033793 | Maija Karala                                                                                                                                                                         |
| 441 |    320.335671 |     55.533997 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey)                |
| 442 |    985.298332 |    713.288045 | Gareth Monger                                                                                                                                                                        |
| 443 |    760.485467 |    464.809195 | Michael Scroggie                                                                                                                                                                     |
| 444 |   1009.822124 |    710.264299 | Mali’o Kodis, photograph by Hans Hillewaert                                                                                                                                          |
| 445 |    212.976940 |    483.282142 | Jaime Headden                                                                                                                                                                        |
| 446 |     36.544839 |      7.501197 | Maija Karala                                                                                                                                                                         |
| 447 |    177.625563 |    588.714316 | NA                                                                                                                                                                                   |
| 448 |    169.342758 |    562.169657 | Christine Axon                                                                                                                                                                       |
| 449 |    157.227047 |    734.690586 | Heinrich Harder (vectorized by T. Michael Keesey)                                                                                                                                    |
| 450 |     49.880276 |     98.876067 | Zimices                                                                                                                                                                              |
| 451 |    673.142085 |    516.955562 | Matt Crook                                                                                                                                                                           |
| 452 |    428.250116 |    161.215648 | Margot Michaud                                                                                                                                                                       |
| 453 |     50.684098 |    567.953059 | M Kolmann                                                                                                                                                                            |
| 454 |    231.430991 |    682.451823 | B. Duygu Özpolat                                                                                                                                                                     |
| 455 |    743.287816 |    775.052254 | Julio Garza                                                                                                                                                                          |
| 456 |    499.211005 |     98.602715 | Alexandre Vong                                                                                                                                                                       |
| 457 |    181.292692 |    563.024462 | NA                                                                                                                                                                                   |
| 458 |   1012.695559 |    619.078078 | Matt Crook                                                                                                                                                                           |
| 459 |     49.911434 |    691.403490 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 460 |    521.316781 |    130.915966 | Christoph Schomburg                                                                                                                                                                  |
| 461 |    780.913485 |    467.516355 | Matt Crook                                                                                                                                                                           |
| 462 |    330.513967 |     27.874296 | Sarah Werning                                                                                                                                                                        |
| 463 |    860.883087 |    388.303179 | Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus                                                             |
| 464 |    685.899368 |    273.318521 | Tracy A. Heath                                                                                                                                                                       |
| 465 |    950.262788 |    211.180734 | Shyamal                                                                                                                                                                              |
| 466 |    360.400370 |    506.678080 | T. Michael Keesey (after Mivart)                                                                                                                                                     |
| 467 |    270.517686 |    778.404092 | Mathew Wedel                                                                                                                                                                         |
| 468 |    267.207276 |    528.270218 | Jagged Fang Designs                                                                                                                                                                  |
| 469 |    805.473301 |    234.407890 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 470 |    137.914703 |    352.885482 | Gareth Monger                                                                                                                                                                        |
| 471 |    315.459308 |    461.768660 | Rebecca Groom                                                                                                                                                                        |
| 472 |     65.740101 |    110.685886 | Sharon Wegner-Larsen                                                                                                                                                                 |
| 473 |    261.960757 |    771.733258 | Becky Barnes                                                                                                                                                                         |
| 474 |    308.472796 |    589.836344 | Tauana J. Cunha                                                                                                                                                                      |
| 475 |    175.573660 |    402.116493 | Tracy A. Heath                                                                                                                                                                       |
| 476 |    161.492720 |    569.754982 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 477 |    678.624358 |     60.894443 | NA                                                                                                                                                                                   |
| 478 |     61.154445 |    581.004044 | Mathilde Cordellier                                                                                                                                                                  |
| 479 |    158.003762 |    770.072428 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                                   |
| 480 |    610.418876 |    776.421925 | Steven Traver                                                                                                                                                                        |
| 481 |    288.275990 |      8.424055 | Zimices                                                                                                                                                                              |
| 482 |    193.646595 |    791.062012 | Margot Michaud                                                                                                                                                                       |
| 483 |    726.185229 |    569.084854 | T. Michael Keesey                                                                                                                                                                    |
| 484 |    394.625046 |    527.015124 | Stanton F. Fink, vectorized by Zimices                                                                                                                                               |
| 485 |    155.052138 |    202.285609 | Matt Crook                                                                                                                                                                           |
| 486 |    466.102760 |    544.113985 | Tyler McCraney                                                                                                                                                                       |
| 487 |    513.156404 |    527.927856 | T. Michael Keesey                                                                                                                                                                    |
| 488 |    368.623567 |    464.964568 | NA                                                                                                                                                                                   |
| 489 |    662.011433 |    186.045621 | Philippe Janvier (vectorized by T. Michael Keesey)                                                                                                                                   |
| 490 |    574.996547 |     26.253898 | Elizabeth Parker                                                                                                                                                                     |
| 491 |    981.274123 |    758.188567 | Matt Crook                                                                                                                                                                           |
| 492 |    962.247892 |     64.203386 | NA                                                                                                                                                                                   |
| 493 |    863.410408 |    441.489039 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 494 |    357.077537 |    748.166226 | Ville Koistinen (vectorized by T. Michael Keesey)                                                                                                                                    |
| 495 |    923.118106 |    675.537263 | NA                                                                                                                                                                                   |
| 496 |    852.187202 |    369.574286 | T. Michael Keesey                                                                                                                                                                    |
| 497 |    839.065827 |    212.872642 | Dean Schnabel                                                                                                                                                                        |
| 498 |     36.202457 |     36.332442 | Zimices                                                                                                                                                                              |
| 499 |     21.406965 |     10.726038 | Rebecca Groom                                                                                                                                                                        |
| 500 |    626.363507 |    596.785287 | Terpsichores                                                                                                                                                                         |
| 501 |    677.359838 |    603.955824 | Mathilde Cordellier                                                                                                                                                                  |
| 502 |    881.989570 |    698.632193 | Ferran Sayol                                                                                                                                                                         |
| 503 |    283.392928 |    363.509772 | NA                                                                                                                                                                                   |
| 504 |     48.194386 |     82.110826 | Steven Traver                                                                                                                                                                        |
| 505 |    316.137095 |    300.349378 | Kailah Thorn & Ben King                                                                                                                                                              |
| 506 |    667.571756 |    751.169118 | Michael Ströck (vectorized by T. Michael Keesey)                                                                                                                                     |
| 507 |    321.698522 |     98.268555 | JJ Harrison (vectorized by T. Michael Keesey)                                                                                                                                        |
| 508 |    993.435936 |    343.911487 | T. Michael Keesey                                                                                                                                                                    |
| 509 |   1006.132317 |    208.052092 | Melissa Broussard                                                                                                                                                                    |
| 510 |    383.118499 |    264.967536 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 511 |   1001.710858 |    572.805638 | U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                                                    |
| 512 |    968.603112 |    648.079219 | Ingo Braasch                                                                                                                                                                         |
| 513 |    228.959794 |    383.700068 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 514 |    623.974119 |    790.276661 | Kamil S. Jaron                                                                                                                                                                       |
| 515 |    979.284442 |    538.897861 | Zimices                                                                                                                                                                              |
| 516 |   1005.927150 |    594.516133 | Christoph Schomburg                                                                                                                                                                  |
| 517 |    678.782627 |    539.299249 | Andreas Preuss / marauder                                                                                                                                                            |
| 518 |    772.438219 |    261.640427 | Zimices                                                                                                                                                                              |
| 519 |    711.958815 |    183.693759 | Kamil S. Jaron                                                                                                                                                                       |
| 520 |    608.720709 |    648.759629 | Tyler McCraney                                                                                                                                                                       |
| 521 |   1002.383632 |    168.564941 | Gareth Monger                                                                                                                                                                        |
| 522 |    500.130859 |    659.237165 | Juan Carlos Jerí                                                                                                                                                                     |
| 523 |    220.815941 |    641.236782 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 524 |    316.347470 |    330.999249 | Gareth Monger                                                                                                                                                                        |
| 525 |    996.490550 |    156.995551 | Scott Reid                                                                                                                                                                           |
| 526 |    792.169969 |    382.461290 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 527 |    523.382718 |    524.538672 | Charles Doolittle Walcott (vectorized by T. Michael Keesey)                                                                                                                          |
| 528 |    522.686421 |     37.360625 | Pollyanna von Knorring and T. Michael Keesey                                                                                                                                         |
| 529 |    148.853674 |    336.783312 | Conty (vectorized by T. Michael Keesey)                                                                                                                                              |
| 530 |    182.935572 |    202.196629 | NA                                                                                                                                                                                   |
| 531 |   1012.996484 |     52.988377 | T. Michael Keesey                                                                                                                                                                    |
| 532 |    145.635719 |    148.849127 | Birgit Lang                                                                                                                                                                          |
| 533 |    119.004930 |    568.601977 | Becky Barnes                                                                                                                                                                         |
| 534 |    957.327124 |      6.692853 | Amanda Katzer                                                                                                                                                                        |
| 535 |    746.127394 |     11.771337 | Christoph Schomburg                                                                                                                                                                  |
| 536 |    997.487249 |    267.929544 | Jaime Headden                                                                                                                                                                        |
| 537 |    576.771240 |    775.588278 | Alexandre Vong                                                                                                                                                                       |
| 538 |    877.579661 |    166.459726 | NA                                                                                                                                                                                   |
| 539 |    444.590667 |    526.407713 | Mike Hanson                                                                                                                                                                          |
| 540 |   1017.055412 |    418.621016 | Burton Robert, USFWS                                                                                                                                                                 |
| 541 |    999.253683 |    557.872090 | Lukasiniho                                                                                                                                                                           |
| 542 |    710.302280 |    288.964476 | Alexandre Vong                                                                                                                                                                       |
| 543 |   1009.018893 |    673.873252 | Scott Hartman                                                                                                                                                                        |
| 544 |      9.073099 |    673.422487 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 545 |    676.697020 |     77.078235 | Ferran Sayol                                                                                                                                                                         |
| 546 |     95.593977 |    256.069463 | Sharon Wegner-Larsen                                                                                                                                                                 |
| 547 |     30.492577 |     79.948296 | Caleb M. Brown                                                                                                                                                                       |
| 548 |    601.258709 |    277.009722 | Matt Crook                                                                                                                                                                           |
| 549 |    338.529467 |    723.439238 | Matt Crook                                                                                                                                                                           |
| 550 |    514.801977 |    498.163214 | Felix Vaux                                                                                                                                                                           |
| 551 |    282.392833 |    312.921961 | xgirouxb                                                                                                                                                                             |
| 552 |    829.996242 |    656.287252 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 553 |    509.939484 |    303.218987 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 554 |    590.125203 |    472.183843 | Tauana J. Cunha                                                                                                                                                                      |
| 555 |    830.202877 |     11.722040 | Scott Hartman                                                                                                                                                                        |
| 556 |    378.680787 |    432.112063 | Collin Gross                                                                                                                                                                         |
| 557 |    476.284676 |    275.411143 | Scott Hartman                                                                                                                                                                        |
| 558 |    171.296633 |    469.206461 | Matt Crook                                                                                                                                                                           |
| 559 |    262.676482 |    789.057376 | Margot Michaud                                                                                                                                                                       |
| 560 |    624.551932 |    358.956505 | Matt Crook                                                                                                                                                                           |
| 561 |    102.346407 |    780.465542 | mystica                                                                                                                                                                              |
| 562 |    834.409858 |    124.557219 | Gareth Monger                                                                                                                                                                        |
| 563 |     18.442611 |    626.925288 | Davidson Sodré                                                                                                                                                                       |
| 564 |    197.827988 |    130.244827 | Margot Michaud                                                                                                                                                                       |
| 565 |    340.303003 |    472.341013 | Matt Martyniuk                                                                                                                                                                       |
| 566 |    473.521073 |    513.501736 | Matt Crook                                                                                                                                                                           |
| 567 |    981.104287 |    787.086537 | Ferran Sayol                                                                                                                                                                         |
| 568 |     49.028455 |    701.580180 | Ingo Braasch                                                                                                                                                                         |
| 569 |    357.730258 |     40.687530 | Ferran Sayol                                                                                                                                                                         |
| 570 |    584.322489 |    445.811188 | Ludwik Gasiorowski                                                                                                                                                                   |
| 571 |    770.076229 |    245.352917 | Sam Fraser-Smith (vectorized by T. Michael Keesey)                                                                                                                                   |
| 572 |    824.692218 |    219.325356 | NA                                                                                                                                                                                   |
| 573 |   1004.214872 |    609.321698 | NA                                                                                                                                                                                   |
| 574 |    855.255952 |    692.267695 | Harold N Eyster                                                                                                                                                                      |
| 575 |    352.655989 |     96.488142 | NA                                                                                                                                                                                   |
| 576 |     33.496545 |    793.557769 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                                  |
| 577 |    186.956825 |    123.695151 | Meyer-Wachsmuth I, Curini Galletti M, Jondelius U (<doi:10.1371/journal.pone.0107688>). Vectorization by Y. Wong                                                                     |
| 578 |    283.036355 |    588.398407 | Lukas Panzarin                                                                                                                                                                       |
| 579 |     14.827376 |    778.738640 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                                    |
| 580 |    298.675390 |    175.043806 | Emil Schmidt (vectorized by Maxime Dahirel)                                                                                                                                          |
| 581 |     72.426577 |    205.652772 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 582 |    826.747964 |    208.243724 | Michael Scroggie                                                                                                                                                                     |
| 583 |    380.693836 |    636.730743 | Matt Crook                                                                                                                                                                           |
| 584 |   1013.192484 |    256.742150 | Crystal Maier                                                                                                                                                                        |
| 585 |    434.613088 |      7.242711 | Chris huh                                                                                                                                                                            |
| 586 |    681.552571 |    360.037209 | Tasman Dixon                                                                                                                                                                         |
| 587 |    344.470845 |    544.777807 | Lukasiniho                                                                                                                                                                           |
| 588 |    229.966297 |    692.022178 | Gareth Monger                                                                                                                                                                        |
| 589 |     89.082356 |    204.522321 | Gareth Monger                                                                                                                                                                        |
| 590 |    142.568293 |    673.638248 | Ferran Sayol                                                                                                                                                                         |
| 591 |    807.257688 |      4.387979 | NA                                                                                                                                                                                   |
| 592 |     66.197432 |    794.342219 | Kai R. Caspar                                                                                                                                                                        |
| 593 |    495.026789 |    573.125483 | T. Michael Keesey (after Heinrich Harder)                                                                                                                                            |
| 594 |    878.532704 |     47.558658 | Jimmy Bernot                                                                                                                                                                         |
| 595 |    589.820162 |    430.982134 | Rebecca Groom                                                                                                                                                                        |
| 596 |     20.171681 |    276.200773 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 597 |   1017.014037 |    778.599343 | Joseph Wolf, 1863 (vectorization by Dinah Challen)                                                                                                                                   |
| 598 |    870.371765 |     64.271925 | Smokeybjb                                                                                                                                                                            |
| 599 |    727.842451 |    264.848862 | Emily Willoughby                                                                                                                                                                     |
| 600 |     69.515116 |    279.844063 | Gareth Monger                                                                                                                                                                        |
| 601 |    607.624618 |    468.456256 | Matt Crook                                                                                                                                                                           |
| 602 |    841.618004 |    456.007475 | Tracy A. Heath                                                                                                                                                                       |
| 603 |    440.611201 |    764.363228 | Steven Traver                                                                                                                                                                        |
| 604 |     37.344135 |    490.761838 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 605 |      5.333629 |    213.698258 | Gareth Monger                                                                                                                                                                        |
| 606 |    664.518260 |    391.722807 | George Edward Lodge (modified by T. Michael Keesey)                                                                                                                                  |
| 607 |    818.496718 |    685.498438 | Noah Schlottman, photo by Museum of Geology, University of Tartu                                                                                                                     |
| 608 |    854.651957 |    274.033317 | Margot Michaud                                                                                                                                                                       |
| 609 |    605.451380 |    485.681235 | Jagged Fang Designs                                                                                                                                                                  |
| 610 |    899.215044 |    698.195107 | Mali’o Kodis, drawing by Manvir Singh                                                                                                                                                |
| 611 |    962.867698 |    775.243653 | Christopher Chávez                                                                                                                                                                   |
| 612 |     93.600178 |    679.783762 | Alex Slavenko                                                                                                                                                                        |
| 613 |    127.291801 |    297.585776 | L. Shyamal                                                                                                                                                                           |
| 614 |    559.465589 |    417.887989 | Matt Crook                                                                                                                                                                           |
| 615 |    934.316922 |    321.116396 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 616 |    711.937851 |    561.619553 | Steven Traver                                                                                                                                                                        |
| 617 |    595.822652 |    520.327019 | Matt Crook                                                                                                                                                                           |
| 618 |    650.418724 |    466.180540 | Kai R. Caspar                                                                                                                                                                        |
| 619 |    174.231428 |    326.708651 | Tasman Dixon                                                                                                                                                                         |
| 620 |    259.462812 |    314.363172 | Tyler Greenfield                                                                                                                                                                     |
| 621 |    278.387616 |    667.153074 | Birgit Lang                                                                                                                                                                          |
| 622 |    277.968070 |    225.851324 | Gareth Monger                                                                                                                                                                        |
| 623 |    532.243290 |    775.201396 | Zimices                                                                                                                                                                              |
| 624 |     23.816320 |    325.063770 | Matt Crook                                                                                                                                                                           |
| 625 |    193.341862 |    603.622386 | NA                                                                                                                                                                                   |
| 626 |    806.516251 |    209.379378 | Scott Hartman                                                                                                                                                                        |
| 627 |    936.378896 |    734.031957 | Birgit Lang                                                                                                                                                                          |
| 628 |    643.975568 |    419.404120 | Katie S. Collins                                                                                                                                                                     |
| 629 |    134.176100 |    170.781385 | mystica                                                                                                                                                                              |
| 630 |    231.189834 |    471.614748 | T. Michael Keesey                                                                                                                                                                    |
| 631 |    500.727076 |    609.472480 | Zimices                                                                                                                                                                              |
| 632 |    346.782792 |    191.829479 | Dori <dori@merr.info> (source photo) and Nevit Dilmen                                                                                                                                |
| 633 |    466.964908 |    630.491605 | Sean McCann                                                                                                                                                                          |
| 634 |    569.786928 |    198.022764 | Michael P. Taylor                                                                                                                                                                    |
| 635 |    101.003818 |     22.940839 | Chris huh                                                                                                                                                                            |
| 636 |    916.752969 |    164.669680 | Matthias Buschmann (vectorized by T. Michael Keesey)                                                                                                                                 |
| 637 |    583.024284 |    734.410539 | Scott Hartman                                                                                                                                                                        |
| 638 |    195.194840 |     40.624221 | Katie S. Collins                                                                                                                                                                     |
| 639 |      9.493245 |    387.134555 | T. Michael Keesey (vectorization); Thorsten Assmann, Jörn Buse, Claudia Drees, Ariel-Leib-Leonid Friedman, Tal Levanony, Andrea Matern, Anika Timm, and David W. Wrase (photography) |
| 640 |    697.987164 |    533.236392 | Danielle Alba                                                                                                                                                                        |
| 641 |    306.211850 |    103.571063 | NA                                                                                                                                                                                   |
| 642 |    624.648810 |    528.786936 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey)                |
| 643 |      7.999923 |    599.476509 | B. Duygu Özpolat                                                                                                                                                                     |
| 644 |    401.516228 |    786.200373 | Scott Hartman                                                                                                                                                                        |
| 645 |    105.996796 |    555.139444 | Matt Crook                                                                                                                                                                           |
| 646 |    181.264991 |    169.172686 | Ferran Sayol                                                                                                                                                                         |
| 647 |    744.577858 |    493.622959 | Sarah Werning                                                                                                                                                                        |
| 648 |     30.997996 |    542.189572 | Scott Hartman                                                                                                                                                                        |
| 649 |    931.827980 |    140.543106 | Matt Martyniuk                                                                                                                                                                       |
| 650 |    506.485281 |    356.211503 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 651 |    603.512023 |    242.548468 | Chloé Schmidt                                                                                                                                                                        |
| 652 |     66.138114 |    325.917206 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                                    |
| 653 |     60.384003 |    556.231213 | Steven Coombs                                                                                                                                                                        |
| 654 |    157.447512 |    278.119430 | Matt Crook                                                                                                                                                                           |
| 655 |    809.232109 |    263.294217 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                                              |
| 656 |    296.589204 |     55.414836 | Bennet McComish, photo by Hans Hillewaert                                                                                                                                            |
| 657 |    804.444877 |    618.478044 | Ferran Sayol                                                                                                                                                                         |
| 658 |    526.492812 |    759.223889 | Lauren Anderson                                                                                                                                                                      |
| 659 |    366.634716 |    591.179600 | Sergio A. Muñoz-Gómez                                                                                                                                                                |
| 660 |    476.361825 |    174.617540 | Matt Crook                                                                                                                                                                           |
| 661 |    873.634357 |    786.745540 | Matt Crook                                                                                                                                                                           |
| 662 |     14.273580 |     30.934006 | Margot Michaud                                                                                                                                                                       |
| 663 |    816.722054 |    468.243641 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 664 |    321.221574 |    533.608073 | Yan Wong                                                                                                                                                                             |
| 665 |    892.855091 |    595.930138 | Tasman Dixon                                                                                                                                                                         |
| 666 |    203.403394 |    694.830414 | Yan Wong                                                                                                                                                                             |
| 667 |    353.381973 |    733.948902 | Gopal Murali                                                                                                                                                                         |
| 668 |    824.831429 |    260.067283 | Zimices                                                                                                                                                                              |
| 669 |    559.136217 |    369.483679 | T. Michael Keesey                                                                                                                                                                    |
| 670 |    632.236304 |    606.528284 | terngirl                                                                                                                                                                             |
| 671 |    658.113636 |    352.425173 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 672 |    497.608098 |    553.237502 | NA                                                                                                                                                                                   |
| 673 |    811.388656 |    251.472398 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                                    |
| 674 |    779.154451 |    275.228692 | Nina Skinner                                                                                                                                                                         |
| 675 |    218.608116 |     61.779567 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 676 |    781.379953 |    624.663543 | Rebecca Groom                                                                                                                                                                        |
| 677 |    360.530634 |    363.927156 | Jagged Fang Designs                                                                                                                                                                  |
| 678 |    574.946990 |    157.700975 | Zimices                                                                                                                                                                              |
| 679 |    649.939622 |     99.762133 | Melissa Broussard                                                                                                                                                                    |
| 680 |    519.670860 |    113.035398 | NA                                                                                                                                                                                   |
| 681 |    505.041056 |    162.340833 | Matt Crook                                                                                                                                                                           |
| 682 |    698.428576 |    231.123946 | Hanyong Pu, Yoshitsugu Kobayashi, Junchang Lü, Li Xu, Yanhua Wu, Huali Chang, Jiming Zhang, Songhai Jia & T. Michael Keesey                                                          |
| 683 |    599.613784 |    449.803130 | Maxime Dahirel (digitisation), Kees van Achterberg et al (doi: 10.3897/BDJ.8.e49017)(original publication)                                                                           |
| 684 |    769.514406 |    188.014658 | Amanda Katzer                                                                                                                                                                        |
| 685 |    460.001349 |    551.095518 | Auckland Museum and T. Michael Keesey                                                                                                                                                |
| 686 |     41.761555 |    592.022241 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                                                |
| 687 |    731.007206 |    283.264680 | Ferran Sayol                                                                                                                                                                         |
| 688 |     29.870964 |    382.402554 | Ferran Sayol                                                                                                                                                                         |
| 689 |    878.411739 |     31.474228 | Jake Warner                                                                                                                                                                          |
| 690 |    922.825165 |    486.680098 | Alex Slavenko                                                                                                                                                                        |
| 691 |    310.403532 |     71.368804 | Joanna Wolfe                                                                                                                                                                         |
| 692 |    209.763855 |    276.489837 | New York Zoological Society                                                                                                                                                          |
| 693 |    419.016298 |    606.082237 | Alex Slavenko                                                                                                                                                                        |
| 694 |    174.451187 |     42.376976 | Noah Schlottman                                                                                                                                                                      |
| 695 |     72.339176 |    786.803246 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 696 |    701.432143 |    667.532764 | Harold N Eyster                                                                                                                                                                      |
| 697 |    271.738340 |    368.737571 | David Sim (photograph) and T. Michael Keesey (vectorization)                                                                                                                         |
| 698 |    425.951546 |    618.036264 | T. Michael Keesey                                                                                                                                                                    |
| 699 |    569.344493 |    370.171076 | Cristina Guijarro                                                                                                                                                                    |
| 700 |    467.342809 |    653.813725 | Ferran Sayol                                                                                                                                                                         |
| 701 |   1003.790230 |    337.363755 | Sergio A. Muñoz-Gómez                                                                                                                                                                |
| 702 |    276.660238 |    387.846076 | Emily Willoughby                                                                                                                                                                     |
| 703 |    400.956678 |    168.900869 | Zimices                                                                                                                                                                              |
| 704 |    431.823392 |    267.470242 | Scott Reid                                                                                                                                                                           |
| 705 |    317.808543 |    740.284983 | Zimices                                                                                                                                                                              |
| 706 |    613.741411 |    101.236980 | Baheerathan Murugavel                                                                                                                                                                |
| 707 |     38.264650 |    570.627163 | Rebecca Groom                                                                                                                                                                        |
| 708 |    215.799430 |    762.515998 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 709 |    132.506293 |    311.093502 | Javier Luque & Sarah Gerken                                                                                                                                                          |
| 710 |     48.978325 |     33.682143 | Darren Naish, Nemo, and T. Michael Keesey                                                                                                                                            |
| 711 |    505.397778 |    137.932383 | Jaime Headden                                                                                                                                                                        |
| 712 |    772.023117 |    686.308652 | Zimices                                                                                                                                                                              |
| 713 |    551.109970 |    605.794456 | Tasman Dixon                                                                                                                                                                         |
| 714 |     81.591584 |    346.178262 | Zimices                                                                                                                                                                              |
| 715 |     14.681221 |    762.127517 | Kamil S. Jaron                                                                                                                                                                       |
| 716 |    241.939862 |    145.768551 | Zimices                                                                                                                                                                              |
| 717 |    419.588048 |    173.091382 | Dave Souza (vectorized by T. Michael Keesey)                                                                                                                                         |
| 718 |    514.074408 |    537.135342 | Tasman Dixon                                                                                                                                                                         |
| 719 |    825.431609 |    729.082807 | Scott Hartman (modified by T. Michael Keesey)                                                                                                                                        |
| 720 |    491.509322 |     91.091601 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 721 |    365.638124 |    635.998163 | Jesús Gómez, vectorized by Zimices                                                                                                                                                   |
| 722 |    788.185789 |     15.793001 | Sharon Wegner-Larsen                                                                                                                                                                 |
| 723 |    457.417298 |    304.331110 | Margot Michaud                                                                                                                                                                       |
| 724 |    540.012228 |    390.857221 | Margot Michaud                                                                                                                                                                       |
| 725 |    674.841922 |     43.992926 | Matt Crook                                                                                                                                                                           |
| 726 |    165.961532 |    189.170621 | Johan Lindgren, Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe                                                                                                                 |
| 727 |    550.929912 |    733.467204 | Kai R. Caspar                                                                                                                                                                        |
| 728 |    861.204321 |     78.148775 | Emily Willoughby                                                                                                                                                                     |
| 729 |    661.188933 |    485.666457 | Zimices                                                                                                                                                                              |
| 730 |    196.652866 |    753.573786 | T. Michael Keesey                                                                                                                                                                    |
| 731 |     41.337858 |    358.921608 | Noah Schlottman, photo by Casey Dunn                                                                                                                                                 |
| 732 |     22.185109 |    469.444905 | Margot Michaud                                                                                                                                                                       |
| 733 |    244.477829 |    384.524566 | Mattia Menchetti                                                                                                                                                                     |
| 734 |    135.540703 |    203.319892 | Lukasiniho                                                                                                                                                                           |
| 735 |     92.808683 |    545.279940 | Beth Reinke                                                                                                                                                                          |
| 736 |    472.271574 |    303.625958 | Matt Crook                                                                                                                                                                           |
| 737 |    486.431983 |    781.039895 | Jagged Fang Designs                                                                                                                                                                  |
| 738 |    273.596637 |    654.118158 | Ferran Sayol                                                                                                                                                                         |
| 739 |    473.086514 |    782.533926 | Gareth Monger                                                                                                                                                                        |
| 740 |    801.958559 |    506.130461 | Chris huh                                                                                                                                                                            |
| 741 |    642.023999 |     41.599107 | Maija Karala                                                                                                                                                                         |
| 742 |    120.562297 |    319.770960 | Jagged Fang Designs                                                                                                                                                                  |
| 743 |     79.012383 |    673.602834 | Scott Hartman                                                                                                                                                                        |
| 744 |    837.491905 |    616.723247 | Zimices                                                                                                                                                                              |
| 745 |    181.155045 |    745.424260 | Matt Crook                                                                                                                                                                           |
| 746 |    473.542489 |    332.758640 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 747 |    172.714766 |    195.004553 | Julio Garza                                                                                                                                                                          |
| 748 |     85.177901 |    765.598211 | Zimices                                                                                                                                                                              |
| 749 |    105.765595 |    796.190412 | Smokeybjb                                                                                                                                                                            |
| 750 |    862.045919 |    532.609389 | Margot Michaud                                                                                                                                                                       |
| 751 |    322.211234 |    448.219697 | Jagged Fang Designs                                                                                                                                                                  |
| 752 |    876.494968 |      8.686814 | Sarah Werning                                                                                                                                                                        |
| 753 |      9.002613 |    324.235227 | Matt Crook                                                                                                                                                                           |
| 754 |   1009.084070 |     70.195892 | Matt Crook                                                                                                                                                                           |
| 755 |    183.450427 |    508.847365 | Zimices                                                                                                                                                                              |
| 756 |    909.344944 |     95.335993 | Zimices                                                                                                                                                                              |
| 757 |    523.651507 |    386.014298 | Tasman Dixon                                                                                                                                                                         |
| 758 |    570.534556 |    313.394341 | Gareth Monger                                                                                                                                                                        |
| 759 |    512.124452 |    743.120118 | Dean Schnabel                                                                                                                                                                        |
| 760 |    591.863587 |    583.257589 | Gareth Monger                                                                                                                                                                        |
| 761 |    844.899192 |     67.961688 | Zimices                                                                                                                                                                              |
| 762 |    948.259741 |    106.632750 | Tasman Dixon                                                                                                                                                                         |
| 763 |    173.552105 |      7.143294 | Matt Crook                                                                                                                                                                           |
| 764 |    621.771396 |    238.442725 | Jagged Fang Designs                                                                                                                                                                  |
| 765 |    201.309589 |    170.415054 | T. Michael Keesey                                                                                                                                                                    |
| 766 |     15.214024 |    289.964208 | Gareth Monger                                                                                                                                                                        |
| 767 |    611.630013 |    296.802454 | T. Michael Keesey                                                                                                                                                                    |
| 768 |    557.629625 |    717.304692 | NA                                                                                                                                                                                   |
| 769 |    863.837163 |      9.050035 | Scott Hartman                                                                                                                                                                        |
| 770 |    942.455141 |    690.183536 | Zimices                                                                                                                                                                              |
| 771 |    640.858080 |    133.404656 | Collin Gross                                                                                                                                                                         |
| 772 |     90.890075 |    140.871413 | NA                                                                                                                                                                                   |
| 773 |    338.582493 |    769.897140 | Matt Crook                                                                                                                                                                           |
| 774 |    449.615987 |    717.732825 | Ferran Sayol                                                                                                                                                                         |
| 775 |    196.731941 |    653.600460 | Blanco et al., 2014, vectorized by Zimices                                                                                                                                           |
| 776 |    895.993935 |    391.440693 | Margot Michaud                                                                                                                                                                       |
| 777 |    191.971040 |    644.247774 | Caleb M. Brown                                                                                                                                                                       |
| 778 |    803.881298 |    133.288832 | Nancy Wyman (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                          |
| 779 |    610.584752 |    381.651188 | Anthony Caravaggi                                                                                                                                                                    |
| 780 |    747.049900 |    425.055576 | Campbell Fleming                                                                                                                                                                     |
| 781 |    554.609101 |    781.577105 | Jagged Fang Designs                                                                                                                                                                  |
| 782 |    180.789539 |    666.930338 | Metalhead64 (vectorized by T. Michael Keesey)                                                                                                                                        |
| 783 |    833.070559 |    592.260459 | JCGiron                                                                                                                                                                              |
| 784 |     74.072146 |     18.516623 | Zimices                                                                                                                                                                              |
| 785 |    151.509036 |    351.018210 | Matt Crook                                                                                                                                                                           |
| 786 |    299.203821 |     67.010560 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 787 |     58.017637 |      6.596080 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 788 |     45.795718 |    323.788219 | Melissa Broussard                                                                                                                                                                    |
| 789 |    392.325068 |    622.326916 | Michelle Site                                                                                                                                                                        |
| 790 |    795.887153 |    747.532107 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 791 |     57.248632 |    382.532602 | Sharon Wegner-Larsen                                                                                                                                                                 |
| 792 |    598.838545 |    630.815823 | Margot Michaud                                                                                                                                                                       |
| 793 |    409.708994 |     40.250701 | Mathew Wedel                                                                                                                                                                         |
| 794 |    874.413836 |    215.223693 | Steven Traver                                                                                                                                                                        |
| 795 |     15.286059 |    104.875423 | Robert Gay                                                                                                                                                                           |
| 796 |    510.411858 |    763.404137 | Steven Traver                                                                                                                                                                        |
| 797 |    265.424982 |     51.827503 | Steven Haddock • Jellywatch.org                                                                                                                                                      |
| 798 |    158.751412 |    351.707357 | Margot Michaud                                                                                                                                                                       |
| 799 |   1010.533330 |    239.010737 | Sarah Werning                                                                                                                                                                        |
| 800 |    809.799116 |    443.484033 | NA                                                                                                                                                                                   |
| 801 |    839.087778 |    545.539065 | Matt Martyniuk                                                                                                                                                                       |
| 802 |    693.147853 |    257.858650 | Crystal Maier                                                                                                                                                                        |
| 803 |    749.534433 |    220.624782 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 804 |    217.317005 |    424.383827 | Ville-Veikko Sinkkonen                                                                                                                                                               |
| 805 |   1004.486448 |    567.849177 | Smokeybjb                                                                                                                                                                            |
| 806 |    525.411838 |    635.862403 | Sergio A. Muñoz-Gómez                                                                                                                                                                |
| 807 |    935.582652 |    783.761119 | Matt Crook                                                                                                                                                                           |
| 808 |    420.267234 |    428.478940 | Andrew A. Farke, shell lines added by Yan Wong                                                                                                                                       |
| 809 |    584.282712 |    631.436552 | Sarah Werning                                                                                                                                                                        |
| 810 |     33.010533 |    529.713832 | Sean McCann                                                                                                                                                                          |
| 811 |    668.598309 |    729.448160 | Felix Vaux                                                                                                                                                                           |
| 812 |   1012.632527 |    356.256290 | Ben Moon                                                                                                                                                                             |
| 813 |    835.973273 |    687.009249 | NA                                                                                                                                                                                   |
| 814 |    978.054347 |    206.536100 | Tasman Dixon                                                                                                                                                                         |
| 815 |    830.295105 |    268.645615 | Gareth Monger                                                                                                                                                                        |
| 816 |    377.252982 |    136.233752 | Katie S. Collins                                                                                                                                                                     |
| 817 |    667.789731 |    789.664035 | Noah Schlottman, photo by Museum of Geology, University of Tartu                                                                                                                     |
| 818 |    640.305784 |    126.349076 | CNZdenek                                                                                                                                                                             |
| 819 |    233.544510 |    425.887149 | Steven Traver                                                                                                                                                                        |
| 820 |    325.547458 |     49.509153 | NA                                                                                                                                                                                   |
| 821 |    275.875643 |    449.984050 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 822 |    169.762661 |    494.909434 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 823 |    974.053141 |     32.084900 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                                    |
| 824 |    972.326220 |    673.366544 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 825 |    556.502227 |    279.872178 | Steven Traver                                                                                                                                                                        |
| 826 |    975.408323 |    630.196470 | Steven Traver                                                                                                                                                                        |
| 827 |    850.654569 |    263.511759 | Beth Reinke                                                                                                                                                                          |
| 828 |    996.870392 |    724.945348 | Matt Martyniuk (modified by Serenchia)                                                                                                                                               |
| 829 |    181.587636 |    708.897619 | Tyler Greenfield                                                                                                                                                                     |
| 830 |    176.925524 |    543.049583 | Ludwik Gasiorowski                                                                                                                                                                   |
| 831 |    200.584126 |     20.332715 | NA                                                                                                                                                                                   |
| 832 |    252.324424 |    274.396447 | Matt Crook                                                                                                                                                                           |
| 833 |    921.383291 |     86.895835 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                                              |
| 834 |    485.691394 |    135.177467 | Lukasiniho                                                                                                                                                                           |
| 835 |    570.748324 |    439.928118 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 836 |    845.035224 |     23.040206 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 837 |    178.507172 |    531.178550 | Pete Buchholz                                                                                                                                                                        |
| 838 |    491.185774 |     15.832702 | Rainer Schoch                                                                                                                                                                        |
| 839 |    766.372613 |    590.727604 | Rebecca Groom                                                                                                                                                                        |
| 840 |    222.685413 |     22.673565 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 841 |    852.340510 |     43.382990 | Steven Traver                                                                                                                                                                        |
| 842 |    377.563929 |     97.880166 | T. Michael Keesey                                                                                                                                                                    |
| 843 |    226.660527 |    665.834455 | Dean Schnabel                                                                                                                                                                        |
| 844 |    113.884069 |    562.603902 | Sarah Werning                                                                                                                                                                        |
| 845 |    496.788254 |    468.670728 | Ferran Sayol                                                                                                                                                                         |
| 846 |    813.683120 |    586.831953 | Melissa Broussard                                                                                                                                                                    |
| 847 |    559.826612 |    614.185389 | Chris huh                                                                                                                                                                            |
| 848 |     88.577229 |     18.519136 | Michelle Site                                                                                                                                                                        |
| 849 |    466.987854 |    467.581172 | wsnaccad                                                                                                                                                                             |
| 850 |    763.617550 |    386.102532 | NA                                                                                                                                                                                   |
| 851 |    109.934107 |      8.553408 | Ferran Sayol                                                                                                                                                                         |
| 852 |    978.020763 |    288.513890 | Lukas Panzarin                                                                                                                                                                       |
| 853 |    849.348458 |    793.625113 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 854 |    774.660797 |    223.182776 | Geoff Shaw                                                                                                                                                                           |
| 855 |    989.335190 |    554.301087 | Matt Crook                                                                                                                                                                           |
| 856 |    424.478644 |    384.690393 | Liftarn                                                                                                                                                                              |
| 857 |    780.820546 |    452.782397 | Matt Crook                                                                                                                                                                           |
| 858 |    145.217730 |    187.059261 | T. Michael Keesey and Tanetahi                                                                                                                                                       |
| 859 |    781.012971 |    696.062289 | Margot Michaud                                                                                                                                                                       |
| 860 |    746.392332 |    688.274292 | Andrew A. Farke                                                                                                                                                                      |
| 861 |    957.044228 |     27.495541 | Tasman Dixon                                                                                                                                                                         |
| 862 |    878.070627 |    767.529056 | Matt Crook                                                                                                                                                                           |
| 863 |    906.124469 |    228.550664 | Zimices                                                                                                                                                                              |
| 864 |    177.788987 |    226.064506 | FunkMonk                                                                                                                                                                             |
| 865 |    288.915791 |    414.050476 | Jimmy Bernot                                                                                                                                                                         |
| 866 |    940.008181 |    766.243338 | Matt Crook                                                                                                                                                                           |
| 867 |    531.388802 |     92.124398 | Lukasiniho                                                                                                                                                                           |
| 868 |    840.933276 |     53.862365 | Smokeybjb, vectorized by Zimices                                                                                                                                                     |
| 869 |     64.328820 |    667.165181 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                                     |
| 870 |    367.611874 |    425.678033 | Tracy A. Heath                                                                                                                                                                       |
| 871 |    835.612799 |    524.234097 | Ferran Sayol                                                                                                                                                                         |
| 872 |    173.602367 |    158.027583 | Matt Celeskey                                                                                                                                                                        |
| 873 |    938.468805 |    293.814254 | Scott Hartman                                                                                                                                                                        |
| 874 |    700.808289 |    459.136569 | Margot Michaud                                                                                                                                                                       |
| 875 |    820.797975 |    622.797760 | Mo Hassan                                                                                                                                                                            |
| 876 |    845.231997 |    147.266281 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                                       |
| 877 |    449.853654 |    545.021927 | Gareth Monger                                                                                                                                                                        |
| 878 |    829.391593 |    675.127046 | Scott Hartman                                                                                                                                                                        |
| 879 |    791.731049 |    237.240197 | Qiang Ou                                                                                                                                                                             |
| 880 |    832.794320 |    365.007900 | Steven Traver                                                                                                                                                                        |
| 881 |    340.764560 |    521.857596 | Jagged Fang Designs                                                                                                                                                                  |
| 882 |    657.121076 |    172.616258 | Kamil S. Jaron                                                                                                                                                                       |
| 883 |    492.698005 |    528.044069 | Margot Michaud                                                                                                                                                                       |
| 884 |    442.967531 |     34.918287 | NA                                                                                                                                                                                   |
| 885 |    840.266050 |    355.695682 | Tauana J. Cunha                                                                                                                                                                      |
| 886 |    964.627493 |    230.758487 | Audrey Ely                                                                                                                                                                           |
| 887 |    692.894439 |    632.265285 | Maija Karala                                                                                                                                                                         |
| 888 |    901.249282 |    737.396461 | Ferran Sayol                                                                                                                                                                         |
| 889 |    927.391948 |    154.038390 | Scott Hartman                                                                                                                                                                        |
| 890 |    328.058361 |    255.147284 | Daniel Jaron                                                                                                                                                                         |
| 891 |    423.481528 |    546.919460 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                                       |
| 892 |    616.672053 |    518.472014 | Scott Hartman                                                                                                                                                                        |
| 893 |    559.096918 |     29.933940 | Pollyanna von Knorring and T. Michael Keesey                                                                                                                                         |
| 894 |    805.033367 |    433.650191 | Smokeybjb                                                                                                                                                                            |
| 895 |    406.991438 |    790.760987 | Tasman Dixon                                                                                                                                                                         |
| 896 |    405.497847 |    553.073292 | Becky Barnes                                                                                                                                                                         |
| 897 |    352.914378 |    602.166769 | Melissa Broussard                                                                                                                                                                    |
| 898 |    824.871754 |    711.912304 | Matt Crook                                                                                                                                                                           |
| 899 |    687.624846 |    550.465484 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 900 |    983.265424 |    244.485663 | T. Michael Keesey                                                                                                                                                                    |
| 901 |    228.791382 |     55.427169 | Zimices                                                                                                                                                                              |
| 902 |    206.572130 |    618.519512 | Tasman Dixon                                                                                                                                                                         |
| 903 |    841.725377 |     91.620423 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                                       |
| 904 |    276.526998 |    473.115973 | Doug Backlund (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                        |
| 905 |    756.074237 |    397.524131 | NA                                                                                                                                                                                   |
| 906 |    434.616368 |     83.341678 | Blanco et al., 2014, vectorized by Zimices                                                                                                                                           |
| 907 |   1002.700798 |     51.570875 | Steven Traver                                                                                                                                                                        |
| 908 |    796.027749 |    523.029138 | NA                                                                                                                                                                                   |
| 909 |    411.038400 |     82.362583 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                                  |
| 910 |    625.403760 |    117.425957 | Ferran Sayol                                                                                                                                                                         |
| 911 |    526.640017 |    151.593232 | Milton Tan                                                                                                                                                                           |
| 912 |    589.302074 |    288.976162 | Margot Michaud                                                                                                                                                                       |
| 913 |    511.231930 |    100.816091 | Ferran Sayol                                                                                                                                                                         |
| 914 |     46.312112 |    546.905483 | Katie S. Collins                                                                                                                                                                     |
| 915 |    317.748038 |    574.708300 | Matt Crook                                                                                                                                                                           |
| 916 |     74.390326 |    297.049514 | Zimices                                                                                                                                                                              |
| 917 |    573.072669 |    549.020228 | Jagged Fang Designs                                                                                                                                                                  |
| 918 |     23.960765 |    416.149310 | Kanako Bessho-Uehara                                                                                                                                                                 |
| 919 |    371.324320 |    480.020836 | Tracy A. Heath                                                                                                                                                                       |
| 920 |    304.893643 |    320.246373 | Matt Crook                                                                                                                                                                           |
| 921 |    522.144866 |    744.202517 | L. Shyamal                                                                                                                                                                           |
| 922 |    677.122053 |     49.703858 | Gareth Monger                                                                                                                                                                        |
| 923 |    311.838082 |    544.147252 | Jaime Headden, modified by T. Michael Keesey                                                                                                                                         |
| 924 |    525.567113 |    427.211158 | Ferran Sayol                                                                                                                                                                         |

    #> Your tweet has been posted!
