
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

Joanna Wolfe, Didier Descouens (vectorized by T. Michael Keesey),
SecretJellyMan, Antonov (vectorized by T. Michael Keesey), Gabriela
Palomo-Munoz, Terpsichores, Margot Michaud, Kamil S. Jaron, Chris huh,
Steven Coombs, Collin Gross, T. Michael Keesey, Ferran Sayol, Zimices,
Matt Crook, Carlos Cano-Barbacil, Gareth Monger, Dmitry Bogdanov
(vectorized by T. Michael Keesey), xgirouxb, annaleeblysse, Nobu Tamura
(vectorized by T. Michael Keesey), Jiekun He, T. Tischler, Johan
Lindgren, Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe, Shyamal,
Mattia Menchetti / Yan Wong, Iain Reid, Tracy A. Heath, Christopher
Chávez, Andrew R. Gehrke, Andy Wilson, Steven Traver, Sarah Werning,
S.Martini, Jagged Fang Designs, Scott Hartman, Birgit Lang, Armin
Reindl, Tasman Dixon, Matus Valach, FunkMonk, Hans Hillewaert, Markus A.
Grohme, Smokeybjb (modified by Mike Keesey), Andrew A. Farke, shell
lines added by Yan Wong, Duane Raver/USFWS, Erika Schumacher, Rebecca
Groom (Based on Photo by Andreas Trepte), Elizabeth Parker, Crystal
Maier, C. Camilo Julián-Caballero, Robbie N. Cada (vectorized by T.
Michael Keesey), Christoph Schomburg, Mo Hassan, Ignacio Contreras,
Mason McNair, Bryan Carstens, SauropodomorphMonarch, Jaime Headden,
Lukasiniho, Jebulon (vectorized by T. Michael Keesey), V. Deepak, Alex
Slavenko, mystica, Dean Schnabel, Michelle Site, Juan Carlos Jerí, M
Kolmann, Jay Matternes (modified by T. Michael Keesey), Myriam\_Ramirez,
Elisabeth Östman, Alexander Schmidt-Lebuhn, Falconaumanni and T. Michael
Keesey, Jerry Oldenettel (vectorized by T. Michael Keesey), Derek Bakken
(photograph) and T. Michael Keesey (vectorization), Ville-Veikko
Sinkkonen, Emily Willoughby, Tony Ayling, Melissa Broussard, Matt
Wilkins, Madeleine Price Ball, Manabu Sakamoto, Meliponicultor
Itaymbere, Michael Scroggie, from original photograph by John Bettaso,
USFWS (original photograph in public domain)., Matt Martyniuk, Arthur S.
Brum, Harold N Eyster, Esme Ashe-Jepson, Gabriel Lio, vectorized by
Zimices, Joe Schneid (vectorized by T. Michael Keesey), Lip Kee Yap
(vectorized by T. Michael Keesey), Michael B. H. (vectorized by T.
Michael Keesey), Lisa M. “Pixxl” (photo), John E. McCormack, Michael G.
Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb
T. Brumfield & T. Michael Keesey, Hans Hillewaert (vectorized by T.
Michael Keesey), Smokeybjb, Noah Schlottman, photo by Carlos
Sánchez-Ortiz, Noah Schlottman, photo by Martin V. Sørensen,
Griensteidl and T. Michael Keesey, Nina Skinner, Rene Martin, Yan Wong
from photo by Denes Emoke, (after Spotila 2004), Fernando Campos De
Domenico, Maxime Dahirel, Geoff Shaw, Hans Hillewaert (photo) and T.
Michael Keesey (vectorization), Manabu Bessho-Uehara, Gopal Murali, Nick
Schooler, Vanessa Guerra, Estelle Bourdon, Mathew Wedel, Aviceda (photo)
& T. Michael Keesey, Noah Schlottman, photo from Casey Dunn, Kimberly
Haddrell, Jaime Headden, modified by T. Michael Keesey, Felix Vaux,
Timothy Knepp (vectorized by T. Michael Keesey), Skye M, kotik, Blair
Perry, T. Michael Keesey (after MPF), Mali’o Kodis, image from the
Smithsonian Institution, Francesco Veronesi (vectorized by T. Michael
Keesey), Mark Hannaford (photo), John E. McCormack, Michael G. Harvey,
Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T.
Brumfield & T. Michael Keesey, Ellen Edmonson (illustration) and Timothy
J. Bartley (silhouette), Alexandre Vong, Chase Brownstein, Beth Reinke,
Mariana Ruiz Villarreal (modified by T. Michael Keesey), Andrew A.
Farke, Sergio A. Muñoz-Gómez, Liftarn, Ghedoghedo (vectorized by T.
Michael Keesey), Matt Martyniuk (vectorized by T. Michael Keesey),
Verdilak, Yan Wong from photo by Gyik Toma, Tim H. Heupink, Leon Huynen,
and David M. Lambert (vectorized by T. Michael Keesey), Oren Peles /
vectorized by Yan Wong, Kai R. Caspar, Tyler Greenfield, Katie S.
Collins, L. Shyamal, Abraão Leite, Maha Ghazal, Sharon Wegner-Larsen,
Joseph J. W. Sertich, Mark A. Loewen, Fernando Carezzano, Michele
Tobias, Sean McCann, Oliver Voigt, Kelly, Renata F. Martins, Roderic
Page and Lois Page, Robert Gay, Dein Freund der Baum (vectorized by T.
Michael Keesey), Stanton F. Fink (vectorized by T. Michael Keesey),
Conty (vectorized by T. Michael Keesey), Mathieu Pélissié, Henry
Lydecker, Mette Aumala, Roberto Díaz Sibaja, Mario Quevedo, Chuanixn Yu,
Joris van der Ham (vectorized by T. Michael Keesey), David Liao, Mali’o
Kodis, photograph by Derek Keats
(<http://www.flickr.com/photos/dkeats/>), Kanchi Nanjo, Emma Kissling,
Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow
(vectorized by T. Michael Keesey), Mihai Dragos (vectorized by T.
Michael Keesey), Martin R. Smith, Julien Louys, Michael Scroggie, Bruno
Maggia, Steven Haddock • Jellywatch.org, Tauana J. Cunha, Courtney
Rockenbach, Chris Jennings (Risiatto), DW Bapst (modified from Mitchell
1990), Meyer-Wachsmuth I, Curini Galletti M, Jondelius U
(<doi:10.1371/journal.pone.0107688>). Vectorization by Y. Wong, Agnello
Picorelli, T. Michael Keesey (after James & al.), Nobu Tamura,
vectorized by Zimices, Taro Maeda, Xavier Giroux-Bougard, Mali’o Kodis,
photograph property of National Museums of Northern Ireland, Smokeybjb
(vectorized by T. Michael Keesey), FJDegrange, Apokryltaros (vectorized
by T. Michael Keesey), Maija Karala, H. F. O. March (modified by T.
Michael Keesey, Michael P. Taylor & Matthew J. Wedel), JCGiron, Dori
<dori@merr.info> (source photo) and Nevit Dilmen, Darren Naish
(vectorize by T. Michael Keesey), Jack Mayer Wood, Yan Wong, Tony Ayling
(vectorized by T. Michael Keesey), Stacy Spensley (Modified), Francisco
Gascó (modified by Michael P. Taylor), David Orr, Anthony Caravaggi,
Javier Luque, John Gould (vectorized by T. Michael Keesey), Samanta
Orellana, C. W. Nash (illustration) and Timothy J. Bartley (silhouette),
Jean-Raphaël Guillaumin (photography) and T. Michael Keesey
(vectorization), Cristopher Silva, Dmitry Bogdanov, Michael Scroggie,
from original photograph by Gary M. Stolz, USFWS (original photograph in
public domain)., Gustav Mützel, Noah Schlottman, photo by Gustav Paulay
for Moorea Biocode, Lauren Sumner-Rooney, Cesar Julian, Pranav Iyer
(grey ideas), DFoidl (vectorized by T. Michael Keesey), Chris A.
Hamilton, Brockhaus and Efron, Mattia Menchetti, Xvazquez (vectorized by
William Gearty), Mike Hanson, Auckland Museum and T. Michael Keesey,
Darren Naish, Nemo, and T. Michael Keesey, Tyler Greenfield and Dean
Schnabel, I. Sáček, Sr. (vectorized by T. Michael Keesey), Tambja
(vectorized by T. Michael Keesey), Luis Cunha, Dave Angelini, Cathy,
George Edward Lodge (modified by T. Michael Keesey), Ghedo (vectorized
by T. Michael Keesey), Aleksey Nagovitsyn (vectorized by T. Michael
Keesey), Hugo Gruson, Campbell Fleming, Christine Axon, Cristina
Guijarro, Andrew A. Farke, modified from original by Robert Bruce
Horsfall, from Scott 1912, CNZdenek, Ray Simpson (vectorized by T.
Michael Keesey), Robert Gay, modified from FunkMonk (Michael B.H.) and
T. Michael Keesey., Timothy Knepp of the U.S. Fish and Wildlife Service
(illustration) and Timothy J. Bartley (silhouette), B Kimmel, Ingo
Braasch, Steve Hillebrand/U. S. Fish and Wildlife Service (source
photo), T. Michael Keesey (vectorization), FunkMonk (Michael B.H.;
vectorized by T. Michael Keesey), H. F. O. March (vectorized by T.
Michael Keesey), Nobu Tamura, Haplochromis (vectorized by T. Michael
Keesey), Robert Bruce Horsfall, from W.B. Scott’s 1912 “A History of
Land Mammals in the Western Hemisphere”, Jan Sevcik (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Ian Burt
(original) and T. Michael Keesey (vectorization), Tony Ayling
(vectorized by Milton Tan), Kent Elson Sorgon, T. Michael Keesey (after
A. Y. Ivantsov), T. Michael Keesey (vectorization) and Nadiatalent
(photography), Kristina Gagalova, Darius Nau, Stephen O’Connor
(vectorized by T. Michael Keesey), David Tana, Jimmy Bernot, Mariana
Ruiz Villarreal, Milton Tan, Rebecca Groom, Benjamin Monod-Broca, Jake
Warner, Roger Witter, vectorized by Zimices, Martin R. Smith, from photo
by Jürgen Schoner, Becky Barnes, Darren Naish (vectorized by T. Michael
Keesey), Rafael Maia, Davidson Sodré, Original drawing by Nobu Tamura,
vectorized by Roberto Díaz Sibaja, Noah Schlottman, photo by Casey Dunn,
Caleb M. Brown, Neil Kelley, Scott D. Sampson, Mark A. Loewen, Andrew A.
Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L.
Titus, Stanton F. Fink, vectorized by Zimices, J. J. Harrison (photo) &
T. Michael Keesey, Heinrich Harder (vectorized by William Gearty),
Renato Santos, Inessa Voet, Evan Swigart (photography) and T. Michael
Keesey (vectorization), Nicolas Huet le Jeune and Jean-Gabriel Prêtre
(vectorized by T. Michael Keesey)

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                          |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    300.992712 |    424.493216 | Joanna Wolfe                                                                                                                                                    |
|   2 |    466.034671 |    191.679265 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                              |
|   3 |    913.649277 |    239.426496 | SecretJellyMan                                                                                                                                                  |
|   4 |    732.482840 |    696.942790 | Antonov (vectorized by T. Michael Keesey)                                                                                                                       |
|   5 |    846.506144 |    531.714663 | Gabriela Palomo-Munoz                                                                                                                                           |
|   6 |    202.884731 |    422.841952 | Terpsichores                                                                                                                                                    |
|   7 |    127.633316 |    588.385101 | Margot Michaud                                                                                                                                                  |
|   8 |    198.144484 |    160.484689 | Kamil S. Jaron                                                                                                                                                  |
|   9 |    593.494391 |    396.750892 | Chris huh                                                                                                                                                       |
|  10 |    567.675844 |    325.653093 | Steven Coombs                                                                                                                                                   |
|  11 |    639.488893 |    565.547729 | Collin Gross                                                                                                                                                    |
|  12 |    229.852892 |    274.954778 | T. Michael Keesey                                                                                                                                               |
|  13 |    929.112825 |    341.161783 | Ferran Sayol                                                                                                                                                    |
|  14 |    370.798478 |    742.034715 | Margot Michaud                                                                                                                                                  |
|  15 |    507.990639 |    696.949312 | Zimices                                                                                                                                                         |
|  16 |    107.258296 |    420.590083 | Matt Crook                                                                                                                                                      |
|  17 |    738.170568 |    377.474588 | Ferran Sayol                                                                                                                                                    |
|  18 |    278.690448 |    586.455009 | Margot Michaud                                                                                                                                                  |
|  19 |    167.578682 |    656.547826 | NA                                                                                                                                                              |
|  20 |    126.548041 |    311.435355 | Carlos Cano-Barbacil                                                                                                                                            |
|  21 |    153.194464 |    525.132023 | Gareth Monger                                                                                                                                                   |
|  22 |    549.338938 |    586.876061 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                               |
|  23 |    443.903799 |    471.986830 | xgirouxb                                                                                                                                                        |
|  24 |    893.207670 |    683.659585 | annaleeblysse                                                                                                                                                   |
|  25 |    713.087881 |    277.913696 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                   |
|  26 |    101.892989 |     62.753249 | Matt Crook                                                                                                                                                      |
|  27 |    864.923162 |     55.608283 | xgirouxb                                                                                                                                                        |
|  28 |    910.116115 |    120.835185 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                               |
|  29 |    722.906056 |     44.574119 | Jiekun He                                                                                                                                                       |
|  30 |    872.034710 |    304.441236 | Gareth Monger                                                                                                                                                   |
|  31 |    248.620107 |    740.414775 | T. Tischler                                                                                                                                                     |
|  32 |    695.965090 |    150.319603 | Matt Crook                                                                                                                                                      |
|  33 |     98.771935 |    217.617581 | Zimices                                                                                                                                                         |
|  34 |    921.478197 |    448.079039 | Johan Lindgren, Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe                                                                                            |
|  35 |     73.430476 |    722.104039 | NA                                                                                                                                                              |
|  36 |    307.061395 |    688.394136 | Shyamal                                                                                                                                                         |
|  37 |    597.511089 |    492.697353 | Mattia Menchetti / Yan Wong                                                                                                                                     |
|  38 |    319.937185 |    337.193264 | Zimices                                                                                                                                                         |
|  39 |    393.099721 |     25.276287 | Iain Reid                                                                                                                                                       |
|  40 |    332.388976 |    263.027694 | Tracy A. Heath                                                                                                                                                  |
|  41 |    674.453191 |    448.607014 | Christopher Chávez                                                                                                                                              |
|  42 |    359.459886 |    582.862263 | Andrew R. Gehrke                                                                                                                                                |
|  43 |    423.933193 |    399.522591 | Chris huh                                                                                                                                                       |
|  44 |    766.998447 |    182.592538 | Andy Wilson                                                                                                                                                     |
|  45 |    578.409096 |    269.457345 | Steven Traver                                                                                                                                                   |
|  46 |    428.382344 |    610.445587 | Sarah Werning                                                                                                                                                   |
|  47 |    739.131349 |    504.454078 | S.Martini                                                                                                                                                       |
|  48 |    527.385843 |    764.778851 | Jagged Fang Designs                                                                                                                                             |
|  49 |    995.159988 |    738.998896 | T. Michael Keesey                                                                                                                                               |
|  50 |    927.932139 |    507.794871 | Scott Hartman                                                                                                                                                   |
|  51 |     79.557620 |    161.075579 | Birgit Lang                                                                                                                                                     |
|  52 |    626.093651 |    652.432519 | NA                                                                                                                                                              |
|  53 |     89.474604 |    353.680534 | Armin Reindl                                                                                                                                                    |
|  54 |    255.317734 |     51.965987 | Carlos Cano-Barbacil                                                                                                                                            |
|  55 |    511.320872 |    533.644028 | Gareth Monger                                                                                                                                                   |
|  56 |    648.209833 |     63.459790 | Chris huh                                                                                                                                                       |
|  57 |    363.743693 |    291.177584 | NA                                                                                                                                                              |
|  58 |     97.148262 |    622.088103 | Tasman Dixon                                                                                                                                                    |
|  59 |    807.826759 |    239.659109 | Kamil S. Jaron                                                                                                                                                  |
|  60 |    767.992162 |    597.556619 | Matus Valach                                                                                                                                                    |
|  61 |    907.675865 |    769.516023 | FunkMonk                                                                                                                                                        |
|  62 |    832.874471 |    395.483321 | NA                                                                                                                                                              |
|  63 |    884.487385 |    604.769691 | Hans Hillewaert                                                                                                                                                 |
|  64 |    373.274109 |    499.761408 | Markus A. Grohme                                                                                                                                                |
|  65 |    978.806843 |    214.604104 | Andrew R. Gehrke                                                                                                                                                |
|  66 |    571.377356 |    436.807326 | Tracy A. Heath                                                                                                                                                  |
|  67 |    289.007251 |    778.498992 | Smokeybjb (modified by Mike Keesey)                                                                                                                             |
|  68 |    981.467397 |    578.241588 | Ferran Sayol                                                                                                                                                    |
|  69 |    846.091767 |     20.403030 | Markus A. Grohme                                                                                                                                                |
|  70 |    781.064614 |    447.413809 | Andrew A. Farke, shell lines added by Yan Wong                                                                                                                  |
|  71 |    596.470552 |    708.278520 | Duane Raver/USFWS                                                                                                                                               |
|  72 |    422.307318 |    729.427753 | Margot Michaud                                                                                                                                                  |
|  73 |    562.185588 |     87.458933 | Erika Schumacher                                                                                                                                                |
|  74 |    380.515108 |    364.421189 | Jagged Fang Designs                                                                                                                                             |
|  75 |    225.796073 |     99.233531 | Rebecca Groom (Based on Photo by Andreas Trepte)                                                                                                                |
|  76 |    276.195467 |    170.569113 | Gabriela Palomo-Munoz                                                                                                                                           |
|  77 |     23.432952 |    458.493946 | Chris huh                                                                                                                                                       |
|  78 |    674.150653 |    372.644991 | Margot Michaud                                                                                                                                                  |
|  79 |    959.605756 |    704.207575 | Elizabeth Parker                                                                                                                                                |
|  80 |    221.883993 |    473.150409 | Margot Michaud                                                                                                                                                  |
|  81 |    621.335500 |    480.725357 | Margot Michaud                                                                                                                                                  |
|  82 |    363.005596 |     33.343085 | Zimices                                                                                                                                                         |
|  83 |     50.670910 |    254.444211 | Crystal Maier                                                                                                                                                   |
|  84 |    181.801284 |    227.571357 | Scott Hartman                                                                                                                                                   |
|  85 |    159.793444 |    161.222131 | Zimices                                                                                                                                                         |
|  86 |    706.916993 |    618.048342 | Tracy A. Heath                                                                                                                                                  |
|  87 |    168.319021 |    364.301201 | Birgit Lang                                                                                                                                                     |
|  88 |    164.225535 |     17.230508 | Matt Crook                                                                                                                                                      |
|  89 |    389.730970 |    303.843500 | Gareth Monger                                                                                                                                                   |
|  90 |     40.299338 |     50.270586 | T. Michael Keesey                                                                                                                                               |
|  91 |    199.723729 |    540.160019 | Zimices                                                                                                                                                         |
|  92 |     21.001885 |    773.971345 | T. Michael Keesey                                                                                                                                               |
|  93 |    236.942786 |    375.830405 | Zimices                                                                                                                                                         |
|  94 |     61.619458 |     19.220796 | Zimices                                                                                                                                                         |
|  95 |    170.421272 |    189.533772 | C. Camilo Julián-Caballero                                                                                                                                      |
|  96 |    621.148932 |    373.851929 | Andy Wilson                                                                                                                                                     |
|  97 |    980.289032 |    475.174665 | Gareth Monger                                                                                                                                                   |
|  98 |    585.775996 |    361.618367 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                |
|  99 |    845.006569 |    465.643220 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                   |
| 100 |    416.398669 |    715.566493 | Steven Traver                                                                                                                                                   |
| 101 |    919.643276 |    308.541983 | Tasman Dixon                                                                                                                                                    |
| 102 |     12.167372 |    124.027125 | Christoph Schomburg                                                                                                                                             |
| 103 |    231.062540 |    441.349138 | T. Michael Keesey                                                                                                                                               |
| 104 |   1001.216719 |    502.653132 | Mo Hassan                                                                                                                                                       |
| 105 |    998.211208 |    664.191069 | Matt Crook                                                                                                                                                      |
| 106 |    791.818235 |    125.572495 | Gabriela Palomo-Munoz                                                                                                                                           |
| 107 |    968.362810 |    139.436728 | Ignacio Contreras                                                                                                                                               |
| 108 |    374.599519 |    453.212682 | Matt Crook                                                                                                                                                      |
| 109 |    670.408016 |    615.817394 | Margot Michaud                                                                                                                                                  |
| 110 |    637.993618 |    336.458528 | Mason McNair                                                                                                                                                    |
| 111 |     81.618467 |    675.556410 | Scott Hartman                                                                                                                                                   |
| 112 |    534.543731 |    302.489944 | Gabriela Palomo-Munoz                                                                                                                                           |
| 113 |    917.080094 |    477.057076 | C. Camilo Julián-Caballero                                                                                                                                      |
| 114 |     30.144174 |    606.598752 | Matt Crook                                                                                                                                                      |
| 115 |    308.814449 |     11.169398 | Margot Michaud                                                                                                                                                  |
| 116 |    593.646457 |    684.375964 | Bryan Carstens                                                                                                                                                  |
| 117 |    160.343904 |    106.554651 | Gareth Monger                                                                                                                                                   |
| 118 |    992.899252 |     16.975363 | NA                                                                                                                                                              |
| 119 |    991.071722 |    122.893363 | SauropodomorphMonarch                                                                                                                                           |
| 120 |    483.310353 |    450.046046 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                               |
| 121 |   1001.337393 |     63.869238 | Jaime Headden                                                                                                                                                   |
| 122 |    991.693759 |    406.401048 | NA                                                                                                                                                              |
| 123 |    994.902775 |    317.588522 | Andy Wilson                                                                                                                                                     |
| 124 |     60.732277 |    482.359241 | Ferran Sayol                                                                                                                                                    |
| 125 |     49.753148 |    544.960191 | Steven Traver                                                                                                                                                   |
| 126 |     44.633703 |    306.784758 | Lukasiniho                                                                                                                                                      |
| 127 |    246.784985 |    188.573761 | Jebulon (vectorized by T. Michael Keesey)                                                                                                                       |
| 128 |    532.420869 |    520.269581 | Jagged Fang Designs                                                                                                                                             |
| 129 |    394.549607 |    332.348570 | V. Deepak                                                                                                                                                       |
| 130 |     19.803591 |    354.012544 | Alex Slavenko                                                                                                                                                   |
| 131 |    139.231992 |     98.912271 | Margot Michaud                                                                                                                                                  |
| 132 |    850.839263 |    364.790051 | NA                                                                                                                                                              |
| 133 |     11.712430 |     29.010851 | mystica                                                                                                                                                         |
| 134 |    769.140210 |    223.421191 | Sarah Werning                                                                                                                                                   |
| 135 |    597.316343 |     88.764717 | Matt Crook                                                                                                                                                      |
| 136 |    907.314131 |    158.822826 | Dean Schnabel                                                                                                                                                   |
| 137 |    617.773522 |    777.972442 | Gareth Monger                                                                                                                                                   |
| 138 |    945.034824 |    315.304804 | NA                                                                                                                                                              |
| 139 |    249.618981 |      8.156445 | Steven Traver                                                                                                                                                   |
| 140 |    834.281738 |    762.460741 | Gabriela Palomo-Munoz                                                                                                                                           |
| 141 |    873.297796 |    673.609734 | Andy Wilson                                                                                                                                                     |
| 142 |    542.009090 |    640.745647 | Jagged Fang Designs                                                                                                                                             |
| 143 |    762.863472 |    129.145781 | Michelle Site                                                                                                                                                   |
| 144 |      7.756435 |     64.463409 | Juan Carlos Jerí                                                                                                                                                |
| 145 |    394.581190 |     90.540217 | Gabriela Palomo-Munoz                                                                                                                                           |
| 146 |    902.205000 |     77.750542 | M Kolmann                                                                                                                                                       |
| 147 |    670.634925 |     99.219118 | Kamil S. Jaron                                                                                                                                                  |
| 148 |    197.500545 |    613.683295 | Jay Matternes (modified by T. Michael Keesey)                                                                                                                   |
| 149 |     13.533083 |    575.429000 | FunkMonk                                                                                                                                                        |
| 150 |    735.311511 |    589.523224 | Myriam\_Ramirez                                                                                                                                                 |
| 151 |    956.587556 |    455.768548 | Elisabeth Östman                                                                                                                                                |
| 152 |    653.962902 |    354.939749 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                               |
| 153 |    222.996741 |    568.728309 | Alexander Schmidt-Lebuhn                                                                                                                                        |
| 154 |    172.062296 |    497.058119 | Falconaumanni and T. Michael Keesey                                                                                                                             |
| 155 |    451.479128 |    422.553259 | NA                                                                                                                                                              |
| 156 |    569.283768 |     48.009329 | NA                                                                                                                                                              |
| 157 |    446.408630 |    689.146011 | Ferran Sayol                                                                                                                                                    |
| 158 |    956.466288 |    677.864346 | Ferran Sayol                                                                                                                                                    |
| 159 |    787.618900 |    156.887817 | Alexander Schmidt-Lebuhn                                                                                                                                        |
| 160 |    870.874688 |     83.596135 | Margot Michaud                                                                                                                                                  |
| 161 |    208.238097 |    509.202387 | Gabriela Palomo-Munoz                                                                                                                                           |
| 162 |     59.588568 |    585.532040 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                   |
| 163 |    699.387725 |    115.685145 | Jerry Oldenettel (vectorized by T. Michael Keesey)                                                                                                              |
| 164 |    390.140331 |    242.640669 | Armin Reindl                                                                                                                                                    |
| 165 |    351.538980 |     67.967655 | Ignacio Contreras                                                                                                                                               |
| 166 |    858.794347 |    413.226275 | Margot Michaud                                                                                                                                                  |
| 167 |    127.443694 |    495.409692 | Matt Crook                                                                                                                                                      |
| 168 |    492.039712 |     75.455035 | Derek Bakken (photograph) and T. Michael Keesey (vectorization)                                                                                                 |
| 169 |    776.645914 |    289.333894 | Ville-Veikko Sinkkonen                                                                                                                                          |
| 170 |    234.350689 |    453.134888 | annaleeblysse                                                                                                                                                   |
| 171 |    876.302233 |    267.928059 | Steven Traver                                                                                                                                                   |
| 172 |    790.858300 |    310.333018 | Jagged Fang Designs                                                                                                                                             |
| 173 |    987.290868 |    612.547257 | Emily Willoughby                                                                                                                                                |
| 174 |    408.707012 |    682.459465 | Tony Ayling                                                                                                                                                     |
| 175 |    388.992279 |    636.977320 | Kamil S. Jaron                                                                                                                                                  |
| 176 |    770.143719 |    153.939234 | Matt Crook                                                                                                                                                      |
| 177 |    879.372580 |    337.137187 | Andy Wilson                                                                                                                                                     |
| 178 |    207.025205 |     11.209565 | Melissa Broussard                                                                                                                                               |
| 179 |    864.571774 |    143.463505 | Sarah Werning                                                                                                                                                   |
| 180 |    301.050782 |    741.260872 | Matt Wilkins                                                                                                                                                    |
| 181 |    459.202771 |    772.689565 | Chris huh                                                                                                                                                       |
| 182 |    828.827882 |     90.615302 | Margot Michaud                                                                                                                                                  |
| 183 |    358.710228 |     85.672107 | Madeleine Price Ball                                                                                                                                            |
| 184 |     28.982634 |    274.416781 | Andy Wilson                                                                                                                                                     |
| 185 |    871.687042 |    548.125396 | T. Michael Keesey                                                                                                                                               |
| 186 |    424.857464 |    655.965675 | Chris huh                                                                                                                                                       |
| 187 |    461.373203 |    574.809483 | Michelle Site                                                                                                                                                   |
| 188 |    274.500660 |    293.596026 | Emily Willoughby                                                                                                                                                |
| 189 |    278.860923 |    202.874896 | Manabu Sakamoto                                                                                                                                                 |
| 190 |     33.641609 |    263.851695 | Meliponicultor Itaymbere                                                                                                                                        |
| 191 |    858.852421 |    430.394557 | NA                                                                                                                                                              |
| 192 |     14.616566 |    296.362225 | Chris huh                                                                                                                                                       |
| 193 |     39.776380 |    204.640419 | Michael Scroggie, from original photograph by John Bettaso, USFWS (original photograph in public domain).                                                       |
| 194 |    355.057451 |    435.439393 | Matt Crook                                                                                                                                                      |
| 195 |    254.876283 |    639.858412 | Matt Martyniuk                                                                                                                                                  |
| 196 |    291.629431 |    630.849106 | Arthur S. Brum                                                                                                                                                  |
| 197 |     31.393329 |    191.729549 | Zimices                                                                                                                                                         |
| 198 |    330.878842 |    585.990059 | Harold N Eyster                                                                                                                                                 |
| 199 |     22.271674 |    326.592878 | Esme Ashe-Jepson                                                                                                                                                |
| 200 |    629.970166 |    299.520604 | Gareth Monger                                                                                                                                                   |
| 201 |     75.116446 |    644.094911 | Armin Reindl                                                                                                                                                    |
| 202 |    464.967731 |    346.759033 | Gareth Monger                                                                                                                                                   |
| 203 |    483.986102 |    607.142103 | Gabriel Lio, vectorized by Zimices                                                                                                                              |
| 204 |    495.864806 |    509.478880 | Joe Schneid (vectorized by T. Michael Keesey)                                                                                                                   |
| 205 |    547.554128 |    380.163608 | Lip Kee Yap (vectorized by T. Michael Keesey)                                                                                                                   |
| 206 |   1002.827614 |    618.215480 | T. Michael Keesey                                                                                                                                               |
| 207 |    999.140830 |    291.321628 | Scott Hartman                                                                                                                                                   |
| 208 |     89.189046 |    236.082507 | Matt Crook                                                                                                                                                      |
| 209 |     89.008121 |    281.269666 | Chris huh                                                                                                                                                       |
| 210 |    824.073286 |     41.591303 | Michael B. H. (vectorized by T. Michael Keesey)                                                                                                                 |
| 211 |    607.385590 |    632.501940 | Gareth Monger                                                                                                                                                   |
| 212 |    619.620093 |     23.962520 | Jagged Fang Designs                                                                                                                                             |
| 213 |    137.081544 |    252.556318 | Lisa M. “Pixxl” (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
| 214 |    355.666041 |    473.195515 | Matt Crook                                                                                                                                                      |
| 215 |    847.280507 |    143.933940 | Margot Michaud                                                                                                                                                  |
| 216 |     77.241968 |    249.804420 | Christoph Schomburg                                                                                                                                             |
| 217 |    513.120135 |    608.208530 | Matt Crook                                                                                                                                                      |
| 218 |    951.033969 |    692.986953 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                               |
| 219 |    112.532185 |    113.629289 | Smokeybjb                                                                                                                                                       |
| 220 |     18.551558 |    633.171449 | Noah Schlottman, photo by Carlos Sánchez-Ortiz                                                                                                                  |
| 221 |    990.097369 |     99.569441 | NA                                                                                                                                                              |
| 222 |     13.270578 |    269.786423 | Noah Schlottman, photo by Martin V. Sørensen                                                                                                                    |
| 223 |    724.613835 |     83.186788 | Griensteidl and T. Michael Keesey                                                                                                                               |
| 224 |    121.731981 |    186.957564 | Steven Traver                                                                                                                                                   |
| 225 |    530.762421 |    396.132899 | Tracy A. Heath                                                                                                                                                  |
| 226 |    658.819905 |    404.495287 | Christoph Schomburg                                                                                                                                             |
| 227 |     16.937730 |    414.345263 | Matt Crook                                                                                                                                                      |
| 228 |    832.496495 |    131.897051 | Nina Skinner                                                                                                                                                    |
| 229 |    904.092839 |    395.181678 | Rene Martin                                                                                                                                                     |
| 230 |    187.096693 |    563.187253 | Yan Wong from photo by Denes Emoke                                                                                                                              |
| 231 |    193.035053 |     77.306731 | Matt Crook                                                                                                                                                      |
| 232 |     26.051243 |    550.775425 | (after Spotila 2004)                                                                                                                                            |
| 233 |    378.957866 |    426.525141 | Scott Hartman                                                                                                                                                   |
| 234 |    243.425674 |    218.782067 | Gabriela Palomo-Munoz                                                                                                                                           |
| 235 |    425.655377 |    379.180895 | Fernando Campos De Domenico                                                                                                                                     |
| 236 |    546.233492 |    544.527164 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                   |
| 237 |     17.880079 |    734.273007 | Maxime Dahirel                                                                                                                                                  |
| 238 |    149.859644 |    712.765622 | Geoff Shaw                                                                                                                                                      |
| 239 |    558.321958 |     99.380543 | Matt Crook                                                                                                                                                      |
| 240 |    188.325347 |    758.280242 | Tony Ayling                                                                                                                                                     |
| 241 |    751.651104 |    271.032336 | Mason McNair                                                                                                                                                    |
| 242 |    297.859404 |    527.160710 | Matt Crook                                                                                                                                                      |
| 243 |    740.432340 |    601.375928 | Rene Martin                                                                                                                                                     |
| 244 |    273.216113 |    230.005841 | Zimices                                                                                                                                                         |
| 245 |    402.038836 |     52.828199 | Jagged Fang Designs                                                                                                                                             |
| 246 |    601.189881 |    736.168394 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                   |
| 247 |    856.961158 |    450.059901 | Hans Hillewaert (photo) and T. Michael Keesey (vectorization)                                                                                                   |
| 248 |    870.386338 |    280.371938 | Matt Crook                                                                                                                                                      |
| 249 |    813.726573 |    767.773182 | Steven Coombs                                                                                                                                                   |
| 250 |    984.842896 |    445.171819 | Chris huh                                                                                                                                                       |
| 251 |    866.723297 |    202.424816 | Jagged Fang Designs                                                                                                                                             |
| 252 |    154.509871 |    263.973418 | Zimices                                                                                                                                                         |
| 253 |     33.948822 |    440.430598 | Steven Traver                                                                                                                                                   |
| 254 |    757.010420 |    553.420408 | Zimices                                                                                                                                                         |
| 255 |    562.984572 |    526.091037 | NA                                                                                                                                                              |
| 256 |    875.855375 |    250.909801 | NA                                                                                                                                                              |
| 257 |    117.043076 |    264.520523 | T. Michael Keesey                                                                                                                                               |
| 258 |    240.805293 |    412.500870 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                   |
| 259 |     12.364512 |    209.627271 | Manabu Bessho-Uehara                                                                                                                                            |
| 260 |    522.662792 |    485.817184 | NA                                                                                                                                                              |
| 261 |    156.443207 |    424.088347 | Gareth Monger                                                                                                                                                   |
| 262 |   1008.074135 |    348.088514 | Gopal Murali                                                                                                                                                    |
| 263 |    458.492542 |     67.619401 | NA                                                                                                                                                              |
| 264 |    576.720502 |    603.698201 | Jagged Fang Designs                                                                                                                                             |
| 265 |    906.996073 |    427.537890 | NA                                                                                                                                                              |
| 266 |     22.631681 |    286.832743 | Ferran Sayol                                                                                                                                                    |
| 267 |    188.536382 |    793.138105 | Nick Schooler                                                                                                                                                   |
| 268 |    837.432123 |    354.384130 | Gabriela Palomo-Munoz                                                                                                                                           |
| 269 |    277.852468 |    436.390009 | Matt Crook                                                                                                                                                      |
| 270 |    791.509018 |    373.105736 | Geoff Shaw                                                                                                                                                      |
| 271 |    699.342237 |    178.201488 | Gareth Monger                                                                                                                                                   |
| 272 |    691.675572 |    793.779101 | Jagged Fang Designs                                                                                                                                             |
| 273 |    535.240697 |      7.305500 | Vanessa Guerra                                                                                                                                                  |
| 274 |     68.629026 |    789.503772 | Alexander Schmidt-Lebuhn                                                                                                                                        |
| 275 |    120.846247 |    729.332274 | FunkMonk                                                                                                                                                        |
| 276 |    394.786282 |    700.099361 | T. Michael Keesey                                                                                                                                               |
| 277 |    308.180017 |    234.354806 | Estelle Bourdon                                                                                                                                                 |
| 278 |    666.860078 |    516.515636 | NA                                                                                                                                                              |
| 279 |    568.020097 |    104.708137 | Steven Traver                                                                                                                                                   |
| 280 |    106.023668 |    564.997337 | Mathew Wedel                                                                                                                                                    |
| 281 |    359.551488 |    393.989526 | Gareth Monger                                                                                                                                                   |
| 282 |    969.983593 |     66.613132 | NA                                                                                                                                                              |
| 283 |    804.692607 |    272.169327 | Aviceda (photo) & T. Michael Keesey                                                                                                                             |
| 284 |    520.051446 |    343.995883 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                               |
| 285 |     97.280033 |    664.086205 | Matt Crook                                                                                                                                                      |
| 286 |    803.626772 |     71.432787 | Noah Schlottman, photo from Casey Dunn                                                                                                                          |
| 287 |    549.452580 |    349.793333 | Scott Hartman                                                                                                                                                   |
| 288 |     31.588267 |    170.650795 | Kimberly Haddrell                                                                                                                                               |
| 289 |    351.499646 |    653.644761 | Gareth Monger                                                                                                                                                   |
| 290 |   1013.857038 |    602.228736 | Michelle Site                                                                                                                                                   |
| 291 |    839.249877 |    714.754916 | Jaime Headden, modified by T. Michael Keesey                                                                                                                    |
| 292 |     72.772657 |    284.684645 | Juan Carlos Jerí                                                                                                                                                |
| 293 |    236.453569 |    147.209362 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                   |
| 294 |    882.091068 |    658.170414 | Chris huh                                                                                                                                                       |
| 295 |    267.983097 |    252.368672 | Felix Vaux                                                                                                                                                      |
| 296 |    725.774213 |    326.872608 | T. Michael Keesey                                                                                                                                               |
| 297 |    895.968708 |    378.043260 | Timothy Knepp (vectorized by T. Michael Keesey)                                                                                                                 |
| 298 |    334.054092 |    302.550565 | Skye M                                                                                                                                                          |
| 299 |    951.861601 |    274.206234 | kotik                                                                                                                                                           |
| 300 |    357.949193 |    420.091792 | Gabriela Palomo-Munoz                                                                                                                                           |
| 301 |     77.081845 |    264.520836 | Blair Perry                                                                                                                                                     |
| 302 |    590.454490 |    528.097392 | Harold N Eyster                                                                                                                                                 |
| 303 |    860.427836 |    344.568403 | T. Michael Keesey (after MPF)                                                                                                                                   |
| 304 |    381.613935 |     80.057135 | Ferran Sayol                                                                                                                                                    |
| 305 |    273.641872 |    377.134919 | Gareth Monger                                                                                                                                                   |
| 306 |    430.348297 |     96.390332 | Mali’o Kodis, image from the Smithsonian Institution                                                                                                            |
| 307 |     17.457914 |    519.252735 | Francesco Veronesi (vectorized by T. Michael Keesey)                                                                                                            |
| 308 |    472.359710 |     89.934564 | Ferran Sayol                                                                                                                                                    |
| 309 |     46.253495 |    368.043132 | Scott Hartman                                                                                                                                                   |
| 310 |     54.936837 |    428.394419 | Margot Michaud                                                                                                                                                  |
| 311 |    528.704573 |    755.855153 | Matt Crook                                                                                                                                                      |
| 312 |      9.901180 |     20.314439 | Mark Hannaford (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey  |
| 313 |     36.093828 |    388.330407 | NA                                                                                                                                                              |
| 314 |    483.457570 |    319.128566 | Dean Schnabel                                                                                                                                                   |
| 315 |    655.108232 |    386.322027 | Matt Crook                                                                                                                                                      |
| 316 |    943.641984 |    620.841262 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                               |
| 317 |     12.978032 |    765.689313 | Alexandre Vong                                                                                                                                                  |
| 318 |    432.351659 |    790.216125 | Chase Brownstein                                                                                                                                                |
| 319 |   1016.092595 |    645.096526 | Matt Crook                                                                                                                                                      |
| 320 |    608.412090 |    338.119460 | Beth Reinke                                                                                                                                                     |
| 321 |    773.225838 |    561.075888 | Jaime Headden                                                                                                                                                   |
| 322 |    815.850267 |    270.589494 | Ferran Sayol                                                                                                                                                    |
| 323 |    289.303672 |    753.284676 | Mariana Ruiz Villarreal (modified by T. Michael Keesey)                                                                                                         |
| 324 |    422.751806 |    124.612234 | Beth Reinke                                                                                                                                                     |
| 325 |    584.495571 |    786.996568 | Chris huh                                                                                                                                                       |
| 326 |    467.541727 |    511.634931 | Tracy A. Heath                                                                                                                                                  |
| 327 |    713.646197 |    112.407286 | NA                                                                                                                                                              |
| 328 |    896.339285 |     31.326864 | Andrew A. Farke                                                                                                                                                 |
| 329 |    414.453622 |    324.126998 | Sergio A. Muñoz-Gómez                                                                                                                                           |
| 330 |    180.749930 |    709.400558 | Liftarn                                                                                                                                                         |
| 331 |    792.704837 |    556.458053 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                    |
| 332 |    482.364675 |    383.144217 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                |
| 333 |    444.352783 |    138.317470 | Verdilak                                                                                                                                                        |
| 334 |    109.197391 |    681.999287 | Gabriela Palomo-Munoz                                                                                                                                           |
| 335 |    430.115397 |    582.025323 | Yan Wong from photo by Gyik Toma                                                                                                                                |
| 336 |    931.925339 |     25.160569 | Beth Reinke                                                                                                                                                     |
| 337 |    451.703736 |    549.488168 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                               |
| 338 |    142.619924 |    773.260901 | Margot Michaud                                                                                                                                                  |
| 339 |    685.271622 |    390.375909 | NA                                                                                                                                                              |
| 340 |    492.560915 |    112.325481 | Tim H. Heupink, Leon Huynen, and David M. Lambert (vectorized by T. Michael Keesey)                                                                             |
| 341 |    607.015189 |    100.186536 | Dean Schnabel                                                                                                                                                   |
| 342 |    681.243994 |    348.166596 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                               |
| 343 |    401.041527 |    109.440464 | Tasman Dixon                                                                                                                                                    |
| 344 |    261.350692 |    489.670763 | Oren Peles / vectorized by Yan Wong                                                                                                                             |
| 345 |    707.516713 |    781.465548 | Kai R. Caspar                                                                                                                                                   |
| 346 |    838.533300 |    631.711945 | Zimices                                                                                                                                                         |
| 347 |    186.271085 |     12.912129 | Michelle Site                                                                                                                                                   |
| 348 |    243.748711 |    344.975132 | Zimices                                                                                                                                                         |
| 349 |    520.684711 |    743.008888 | Tyler Greenfield                                                                                                                                                |
| 350 |    199.739546 |    352.221702 | Jaime Headden                                                                                                                                                   |
| 351 |    345.937564 |     26.463123 | Ferran Sayol                                                                                                                                                    |
| 352 |    961.812404 |     23.579226 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                              |
| 353 |    202.350340 |    631.167440 | Felix Vaux                                                                                                                                                      |
| 354 |     19.298388 |    490.596439 | Katie S. Collins                                                                                                                                                |
| 355 |    373.580797 |    665.470785 | Michelle Site                                                                                                                                                   |
| 356 |     81.390787 |     57.239451 | L. Shyamal                                                                                                                                                      |
| 357 |    955.073287 |    527.284997 | Abraão Leite                                                                                                                                                    |
| 358 |     88.397386 |    292.840625 | Maha Ghazal                                                                                                                                                     |
| 359 |     95.247442 |    551.788188 | Sharon Wegner-Larsen                                                                                                                                            |
| 360 |    307.294546 |     74.073687 | Joseph J. W. Sertich, Mark A. Loewen                                                                                                                            |
| 361 |    497.498498 |    225.013970 | Gabriela Palomo-Munoz                                                                                                                                           |
| 362 |    954.233498 |    605.240943 | Margot Michaud                                                                                                                                                  |
| 363 |    923.632871 |     31.879335 | Christoph Schomburg                                                                                                                                             |
| 364 |    858.870268 |    179.225641 | Fernando Carezzano                                                                                                                                              |
| 365 |    282.717859 |    308.761772 | Beth Reinke                                                                                                                                                     |
| 366 |    136.305275 |    198.987842 | Tracy A. Heath                                                                                                                                                  |
| 367 |    139.149002 |    461.978367 | Matt Crook                                                                                                                                                      |
| 368 |    421.227686 |    257.482947 | Michele Tobias                                                                                                                                                  |
| 369 |    211.764638 |    642.212630 | Steven Traver                                                                                                                                                   |
| 370 |    578.039192 |    721.478627 | Matt Crook                                                                                                                                                      |
| 371 |    509.417631 |    446.684219 | Gabriela Palomo-Munoz                                                                                                                                           |
| 372 |     52.931292 |    564.900813 | Scott Hartman                                                                                                                                                   |
| 373 |     82.311121 |    555.137118 | Kai R. Caspar                                                                                                                                                   |
| 374 |    663.770951 |    345.071730 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                   |
| 375 |    182.446236 |     41.726867 | Ferran Sayol                                                                                                                                                    |
| 376 |    463.752909 |    438.825017 | Steven Traver                                                                                                                                                   |
| 377 |    894.347519 |    366.062454 | Kamil S. Jaron                                                                                                                                                  |
| 378 |     24.546198 |    124.192044 | Jaime Headden                                                                                                                                                   |
| 379 |    143.615036 |    734.463882 | Sean McCann                                                                                                                                                     |
| 380 |    399.648092 |    374.921884 | Gareth Monger                                                                                                                                                   |
| 381 |    264.429587 |    354.081966 | Gareth Monger                                                                                                                                                   |
| 382 |    492.368494 |     29.949638 | Oliver Voigt                                                                                                                                                    |
| 383 |    211.914232 |    698.902522 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                   |
| 384 |    835.047898 |    485.914938 | Gareth Monger                                                                                                                                                   |
| 385 |   1010.905430 |    134.964235 | Verdilak                                                                                                                                                        |
| 386 |    848.265477 |    211.594165 | T. Michael Keesey                                                                                                                                               |
| 387 |    328.897008 |    232.516370 | Tracy A. Heath                                                                                                                                                  |
| 388 |    717.272902 |    590.341066 | Markus A. Grohme                                                                                                                                                |
| 389 |    391.767435 |    438.984518 | Andrew A. Farke                                                                                                                                                 |
| 390 |    302.016307 |     21.668353 | Kelly                                                                                                                                                           |
| 391 |    437.230007 |    718.956959 | Renata F. Martins                                                                                                                                               |
| 392 |    638.238062 |    694.885848 | Felix Vaux                                                                                                                                                      |
| 393 |    447.031542 |     82.829375 | Zimices                                                                                                                                                         |
| 394 |    386.664797 |    526.482802 | Roderic Page and Lois Page                                                                                                                                      |
| 395 |    804.750102 |    325.665574 | Alexander Schmidt-Lebuhn                                                                                                                                        |
| 396 |    561.362162 |    611.082643 | Robert Gay                                                                                                                                                      |
| 397 |    811.254457 |    102.461479 | NA                                                                                                                                                              |
| 398 |    188.787598 |    266.794317 | Gabriela Palomo-Munoz                                                                                                                                           |
| 399 |    822.596502 |    143.020695 | Steven Traver                                                                                                                                                   |
| 400 |   1016.568711 |    326.476290 | Dein Freund der Baum (vectorized by T. Michael Keesey)                                                                                                          |
| 401 |    982.757122 |    367.330234 | Felix Vaux                                                                                                                                                      |
| 402 |    173.477151 |    772.453166 | Jagged Fang Designs                                                                                                                                             |
| 403 |    959.219361 |    425.966681 | Terpsichores                                                                                                                                                    |
| 404 |    534.905181 |    504.866433 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                               |
| 405 |    261.250163 |     91.265516 | Conty (vectorized by T. Michael Keesey)                                                                                                                         |
| 406 |   1001.003840 |    224.638355 | Maxime Dahirel                                                                                                                                                  |
| 407 |    966.362086 |     56.868593 | NA                                                                                                                                                              |
| 408 |    413.092977 |    234.338473 | Steven Traver                                                                                                                                                   |
| 409 |    318.443346 |    638.357080 | Margot Michaud                                                                                                                                                  |
| 410 |    262.405650 |    230.088368 | Gabriela Palomo-Munoz                                                                                                                                           |
| 411 |    611.358429 |    762.324828 | Birgit Lang                                                                                                                                                     |
| 412 |    645.548225 |     10.241511 | NA                                                                                                                                                              |
| 413 |    566.041419 |    746.561669 | Beth Reinke                                                                                                                                                     |
| 414 |    226.920032 |    637.276920 | NA                                                                                                                                                              |
| 415 |    616.478842 |    339.481695 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                    |
| 416 |    325.057266 |    787.728496 | Mathieu Pélissié                                                                                                                                                |
| 417 |    762.239997 |    138.992200 | Chris huh                                                                                                                                                       |
| 418 |     56.204634 |    171.583458 | Henry Lydecker                                                                                                                                                  |
| 419 |    358.734387 |    773.696195 | Mette Aumala                                                                                                                                                    |
| 420 |    256.743499 |    173.704876 | Matt Crook                                                                                                                                                      |
| 421 |    288.094610 |    281.785850 | Jagged Fang Designs                                                                                                                                             |
| 422 |    972.175908 |    432.415995 | Scott Hartman                                                                                                                                                   |
| 423 |    201.740242 |     36.325671 | Roberto Díaz Sibaja                                                                                                                                             |
| 424 |     82.972518 |    780.895412 | Zimices                                                                                                                                                         |
| 425 |    808.891013 |    358.498864 | Mario Quevedo                                                                                                                                                   |
| 426 |     96.467439 |    595.066473 | Chuanixn Yu                                                                                                                                                     |
| 427 |     60.866090 |    591.944087 | T. Michael Keesey                                                                                                                                               |
| 428 |    255.693056 |    204.391940 | Tasman Dixon                                                                                                                                                    |
| 429 |    682.574925 |    449.172802 | T. Michael Keesey                                                                                                                                               |
| 430 |    142.923394 |    484.091537 | Jaime Headden                                                                                                                                                   |
| 431 |    962.534495 |    747.010621 | NA                                                                                                                                                              |
| 432 |    683.299099 |    501.292692 | Zimices                                                                                                                                                         |
| 433 |    439.807593 |    338.480119 | Zimices                                                                                                                                                         |
| 434 |    806.537629 |    776.966167 | Steven Traver                                                                                                                                                   |
| 435 |    120.978517 |    245.801431 | Sean McCann                                                                                                                                                     |
| 436 |     16.196976 |    379.475251 | Tasman Dixon                                                                                                                                                    |
| 437 |    310.520209 |    767.536946 | Yan Wong from photo by Gyik Toma                                                                                                                                |
| 438 |     25.441533 |    593.563368 | Chris huh                                                                                                                                                       |
| 439 |    765.363265 |     32.250408 | Jagged Fang Designs                                                                                                                                             |
| 440 |    956.800734 |    295.747443 | Scott Hartman                                                                                                                                                   |
| 441 |    431.604290 |    573.496710 | Joris van der Ham (vectorized by T. Michael Keesey)                                                                                                             |
| 442 |    833.601374 |    307.903035 | Chuanixn Yu                                                                                                                                                     |
| 443 |    364.817660 |    783.303997 | Dein Freund der Baum (vectorized by T. Michael Keesey)                                                                                                          |
| 444 |    549.740820 |    604.228832 | Zimices                                                                                                                                                         |
| 445 |     66.084649 |    115.947183 | Tracy A. Heath                                                                                                                                                  |
| 446 |    697.883547 |    202.176643 | Emily Willoughby                                                                                                                                                |
| 447 |    838.072774 |     75.037276 | NA                                                                                                                                                              |
| 448 |   1010.396833 |     42.177568 | Margot Michaud                                                                                                                                                  |
| 449 |   1014.739658 |    270.898491 | David Liao                                                                                                                                                      |
| 450 |    919.319557 |    612.888154 | Mali’o Kodis, photograph by Derek Keats (<http://www.flickr.com/photos/dkeats/>)                                                                                |
| 451 |   1016.142044 |    248.513397 | Steven Traver                                                                                                                                                   |
| 452 |    138.409650 |    236.963782 | Chris huh                                                                                                                                                       |
| 453 |    479.458462 |    655.056266 | Sharon Wegner-Larsen                                                                                                                                            |
| 454 |     79.931252 |    339.208423 | Kanchi Nanjo                                                                                                                                                    |
| 455 |    916.798019 |    505.589432 | Gabriela Palomo-Munoz                                                                                                                                           |
| 456 |    796.959289 |    369.091821 | Iain Reid                                                                                                                                                       |
| 457 |    282.969599 |    666.330199 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                   |
| 458 |    429.757676 |    442.233801 | Emma Kissling                                                                                                                                                   |
| 459 |    582.571103 |     14.236107 | Jagged Fang Designs                                                                                                                                             |
| 460 |    149.823650 |    223.886155 | Matt Crook                                                                                                                                                      |
| 461 |    493.350266 |    637.168105 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                             |
| 462 |    327.362233 |    622.927816 | Mihai Dragos (vectorized by T. Michael Keesey)                                                                                                                  |
| 463 |    465.945369 |     22.315312 | Martin R. Smith                                                                                                                                                 |
| 464 |    512.201933 |    412.779625 | Zimices                                                                                                                                                         |
| 465 |    948.670813 |    753.656384 | Julien Louys                                                                                                                                                    |
| 466 |    885.820622 |    638.431144 | Dean Schnabel                                                                                                                                                   |
| 467 |    483.396492 |    573.477722 | Michael Scroggie                                                                                                                                                |
| 468 |    191.190070 |    628.067710 | Sharon Wegner-Larsen                                                                                                                                            |
| 469 |    621.052537 |     33.107144 | Bruno Maggia                                                                                                                                                    |
| 470 |    949.617067 |    163.651502 | Steven Haddock • Jellywatch.org                                                                                                                                 |
| 471 |     15.777473 |    102.122061 | Matt Crook                                                                                                                                                      |
| 472 |    393.844082 |    539.427309 | Ferran Sayol                                                                                                                                                    |
| 473 |     37.537675 |    787.039967 | Tauana J. Cunha                                                                                                                                                 |
| 474 |    966.601260 |    676.762464 | Mason McNair                                                                                                                                                    |
| 475 |    568.944520 |    718.836826 | T. Michael Keesey                                                                                                                                               |
| 476 |    400.899003 |    786.210075 | Zimices                                                                                                                                                         |
| 477 |    215.080501 |    780.884926 | Courtney Rockenbach                                                                                                                                             |
| 478 |    253.471147 |    702.998892 | Chris Jennings (Risiatto)                                                                                                                                       |
| 479 |    994.701119 |    113.514748 | Matt Crook                                                                                                                                                      |
| 480 |    795.650645 |     38.148703 | Matt Crook                                                                                                                                                      |
| 481 |    847.666758 |    224.225417 | DW Bapst (modified from Mitchell 1990)                                                                                                                          |
| 482 |    400.388129 |    277.150638 | Tasman Dixon                                                                                                                                                    |
| 483 |    159.447391 |    349.780952 | Andy Wilson                                                                                                                                                     |
| 484 |    252.221888 |    249.473282 | Meyer-Wachsmuth I, Curini Galletti M, Jondelius U (<doi:10.1371/journal.pone.0107688>). Vectorization by Y. Wong                                                |
| 485 |    575.804890 |    690.204253 | NA                                                                                                                                                              |
| 486 |    759.038858 |    101.282944 | Zimices                                                                                                                                                         |
| 487 |    848.253834 |    335.112120 | Lukasiniho                                                                                                                                                      |
| 488 |    738.215037 |    219.769836 | Gabriela Palomo-Munoz                                                                                                                                           |
| 489 |    885.835339 |     78.362968 | Scott Hartman                                                                                                                                                   |
| 490 |    104.059595 |    601.516523 | Agnello Picorelli                                                                                                                                               |
| 491 |    944.910827 |    409.642051 | Chuanixn Yu                                                                                                                                                     |
| 492 |    454.407035 |    756.932775 | Christoph Schomburg                                                                                                                                             |
| 493 |    623.877405 |    232.742684 | FunkMonk                                                                                                                                                        |
| 494 |    312.067899 |    792.824843 | T. Michael Keesey (after James & al.)                                                                                                                           |
| 495 |    741.713284 |     81.976473 | Kamil S. Jaron                                                                                                                                                  |
| 496 |    806.640940 |    533.024666 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                               |
| 497 |      7.656730 |    196.048562 | Nobu Tamura, vectorized by Zimices                                                                                                                              |
| 498 |    472.835605 |    553.357487 | Katie S. Collins                                                                                                                                                |
| 499 |    189.938792 |    254.635393 | NA                                                                                                                                                              |
| 500 |    468.940273 |    297.437342 | Taro Maeda                                                                                                                                                      |
| 501 |    946.529154 |    219.286417 | Xavier Giroux-Bougard                                                                                                                                           |
| 502 |    606.118390 |    478.831857 | Melissa Broussard                                                                                                                                               |
| 503 |    609.362592 |    514.999198 | Chris huh                                                                                                                                                       |
| 504 |    429.965319 |    746.754396 | Margot Michaud                                                                                                                                                  |
| 505 |    544.037459 |     74.637278 | Mali’o Kodis, photograph property of National Museums of Northern Ireland                                                                                       |
| 506 |    595.768585 |    104.065529 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                     |
| 507 |    828.776664 |    206.691379 | Gabriela Palomo-Munoz                                                                                                                                           |
| 508 |    507.145675 |    720.309451 | FJDegrange                                                                                                                                                      |
| 509 |    691.975799 |    634.699617 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                  |
| 510 |    817.277104 |    755.630197 | Ignacio Contreras                                                                                                                                               |
| 511 |    656.770673 |    694.165722 | Derek Bakken (photograph) and T. Michael Keesey (vectorization)                                                                                                 |
| 512 |    535.740194 |    365.122515 | Smokeybjb                                                                                                                                                       |
| 513 |    368.745080 |      4.229117 | Maija Karala                                                                                                                                                    |
| 514 |    488.941752 |    789.296181 | H. F. O. March (modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel)                                                                            |
| 515 |   1001.229425 |    448.958327 | JCGiron                                                                                                                                                         |
| 516 |    126.333611 |    380.012785 | Dori <dori@merr.info> (source photo) and Nevit Dilmen                                                                                                           |
| 517 |    634.865190 |    681.520757 | Carlos Cano-Barbacil                                                                                                                                            |
| 518 |    399.797453 |    251.283721 | Margot Michaud                                                                                                                                                  |
| 519 |    664.661230 |    633.942497 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                   |
| 520 |    999.054548 |     88.866044 | Jack Mayer Wood                                                                                                                                                 |
| 521 |    414.450701 |    365.040548 | Gareth Monger                                                                                                                                                   |
| 522 |    899.037184 |    326.121312 | NA                                                                                                                                                              |
| 523 |    454.751805 |     98.630926 | Roberto Díaz Sibaja                                                                                                                                             |
| 524 |    565.492078 |    415.828814 | Yan Wong                                                                                                                                                        |
| 525 |    386.392050 |    261.221773 | Tony Ayling                                                                                                                                                     |
| 526 |    913.730650 |    560.680352 | Mariana Ruiz Villarreal (modified by T. Michael Keesey)                                                                                                         |
| 527 |    745.882389 |     12.921990 | NA                                                                                                                                                              |
| 528 |    742.320328 |    228.471684 | Matt Crook                                                                                                                                                      |
| 529 |    309.165297 |     70.146282 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                   |
| 530 |     63.634760 |    161.478296 | Stacy Spensley (Modified)                                                                                                                                       |
| 531 |    950.475533 |     88.099322 | Scott Hartman                                                                                                                                                   |
| 532 |    987.951620 |    348.385311 | NA                                                                                                                                                              |
| 533 |    168.094067 |    430.674757 | Francisco Gascó (modified by Michael P. Taylor)                                                                                                                 |
| 534 |    878.139946 |    423.244165 | Michael Scroggie                                                                                                                                                |
| 535 |    171.669393 |    336.732818 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                   |
| 536 |     70.428664 |    666.684135 | Chris huh                                                                                                                                                       |
| 537 |    174.468234 |    118.426579 | Steven Traver                                                                                                                                                   |
| 538 |    630.485612 |     92.313824 | Steven Traver                                                                                                                                                   |
| 539 |    545.600069 |    620.355699 | M Kolmann                                                                                                                                                       |
| 540 |     86.886118 |    114.992466 | David Orr                                                                                                                                                       |
| 541 |    435.685578 |    759.606089 | Margot Michaud                                                                                                                                                  |
| 542 |    709.323356 |    593.933815 | Sarah Werning                                                                                                                                                   |
| 543 |    452.056368 |    110.226956 | Gareth Monger                                                                                                                                                   |
| 544 |    553.383354 |     17.146237 | Matt Crook                                                                                                                                                      |
| 545 |    326.361754 |    613.032834 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                   |
| 546 |    298.990750 |    489.390425 | Anthony Caravaggi                                                                                                                                               |
| 547 |    248.664322 |    503.719688 | Ferran Sayol                                                                                                                                                    |
| 548 |    831.583710 |    640.616195 | Javier Luque                                                                                                                                                    |
| 549 |    181.202851 |    278.545069 | Anthony Caravaggi                                                                                                                                               |
| 550 |    421.600770 |    781.631772 | John Gould (vectorized by T. Michael Keesey)                                                                                                                    |
| 551 |    954.432680 |    635.566818 | Christoph Schomburg                                                                                                                                             |
| 552 |    402.460206 |    423.826666 | Samanta Orellana                                                                                                                                                |
| 553 |   1015.499909 |    258.999209 | Michael Scroggie                                                                                                                                                |
| 554 |   1009.217850 |    198.942430 | Andrew A. Farke                                                                                                                                                 |
| 555 |    626.641624 |    755.831832 | Skye M                                                                                                                                                          |
| 556 |     97.639207 |    340.319581 | Gareth Monger                                                                                                                                                   |
| 557 |    831.610109 |    261.741952 | Tasman Dixon                                                                                                                                                    |
| 558 |    644.857309 |    459.769361 | T. Michael Keesey                                                                                                                                               |
| 559 |    300.492730 |    366.085586 | NA                                                                                                                                                              |
| 560 |    275.327816 |    511.293332 | C. W. Nash (illustration) and Timothy J. Bartley (silhouette)                                                                                                   |
| 561 |    928.441305 |    172.817956 | H. F. O. March (modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel)                                                                            |
| 562 |    514.140006 |    734.410814 | NA                                                                                                                                                              |
| 563 |    572.179369 |    559.162173 | Zimices                                                                                                                                                         |
| 564 |    156.695130 |    756.160572 | Zimices                                                                                                                                                         |
| 565 |    520.019679 |    234.998942 | Matt Crook                                                                                                                                                      |
| 566 |    367.992557 |    230.430376 | Scott Hartman                                                                                                                                                   |
| 567 |    996.378459 |    144.107671 | Zimices                                                                                                                                                         |
| 568 |    297.398477 |    233.369700 | Scott Hartman                                                                                                                                                   |
| 569 |     14.462444 |    236.245872 | Felix Vaux                                                                                                                                                      |
| 570 |    763.823200 |     45.424338 | Rene Martin                                                                                                                                                     |
| 571 |    133.422080 |    119.376304 | Matt Crook                                                                                                                                                      |
| 572 |    875.271881 |     93.727505 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                               |
| 573 |    192.425509 |    786.777548 | Tasman Dixon                                                                                                                                                    |
| 574 |    614.108768 |    685.103133 | Jean-Raphaël Guillaumin (photography) and T. Michael Keesey (vectorization)                                                                                     |
| 575 |    956.152614 |    397.079952 | Melissa Broussard                                                                                                                                               |
| 576 |    535.857887 |    784.939239 | NA                                                                                                                                                              |
| 577 |    660.326734 |    294.701138 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                               |
| 578 |    630.093763 |    744.017116 | Kamil S. Jaron                                                                                                                                                  |
| 579 |    430.992627 |    244.637363 | Cristopher Silva                                                                                                                                                |
| 580 |     42.354455 |    111.000254 | NA                                                                                                                                                              |
| 581 |     32.232429 |    581.822482 | Melissa Broussard                                                                                                                                               |
| 582 |      9.787029 |    497.627626 | Andy Wilson                                                                                                                                                     |
| 583 |    361.628049 |     44.506930 | Katie S. Collins                                                                                                                                                |
| 584 |    764.576956 |      6.214116 | Tasman Dixon                                                                                                                                                    |
| 585 |    837.815794 |    788.732093 | Margot Michaud                                                                                                                                                  |
| 586 |    281.807360 |    523.810629 | Jagged Fang Designs                                                                                                                                             |
| 587 |    298.019277 |    637.561061 | Dmitry Bogdanov                                                                                                                                                 |
| 588 |     48.714216 |    467.162672 | Michael Scroggie, from original photograph by Gary M. Stolz, USFWS (original photograph in public domain).                                                      |
| 589 |    154.979567 |    376.252319 | Jiekun He                                                                                                                                                       |
| 590 |    283.852927 |    794.997160 | Markus A. Grohme                                                                                                                                                |
| 591 |    353.337834 |    369.300915 | Ferran Sayol                                                                                                                                                    |
| 592 |    392.886836 |    779.437904 | Emily Willoughby                                                                                                                                                |
| 593 |     13.655880 |    337.564659 | Gustav Mützel                                                                                                                                                   |
| 594 |    131.672239 |    557.845758 | Meyer-Wachsmuth I, Curini Galletti M, Jondelius U (<doi:10.1371/journal.pone.0107688>). Vectorization by Y. Wong                                                |
| 595 |    960.678643 |    367.121967 | Matt Crook                                                                                                                                                      |
| 596 |    618.729499 |    423.825724 | Noah Schlottman, photo by Gustav Paulay for Moorea Biocode                                                                                                      |
| 597 |    504.552042 |    291.310336 | Steven Traver                                                                                                                                                   |
| 598 |    189.923744 |    341.110752 | Jagged Fang Designs                                                                                                                                             |
| 599 |    308.469787 |    223.103057 | Mathew Wedel                                                                                                                                                    |
| 600 |     65.502293 |    196.317871 | Matt Crook                                                                                                                                                      |
| 601 |    332.865813 |    370.399920 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                   |
| 602 |   1013.730007 |    204.124442 | Joanna Wolfe                                                                                                                                                    |
| 603 |     70.678470 |    246.256100 | Jagged Fang Designs                                                                                                                                             |
| 604 |    556.940295 |    644.795589 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                               |
| 605 |    952.371028 |    555.310771 | Dean Schnabel                                                                                                                                                   |
| 606 |     29.758058 |    216.043267 | Lauren Sumner-Rooney                                                                                                                                            |
| 607 |    227.170941 |    789.581300 | Gareth Monger                                                                                                                                                   |
| 608 |    403.137886 |    450.549967 | Matt Crook                                                                                                                                                      |
| 609 |    455.385631 |    591.304145 | Dean Schnabel                                                                                                                                                   |
| 610 |    707.989458 |     96.837115 | Gabriela Palomo-Munoz                                                                                                                                           |
| 611 |    171.798001 |    761.832831 | Cesar Julian                                                                                                                                                    |
| 612 |    103.117429 |    689.934572 | Maija Karala                                                                                                                                                    |
| 613 |    828.156141 |      5.487082 | Gareth Monger                                                                                                                                                   |
| 614 |    483.122863 |    432.991389 | L. Shyamal                                                                                                                                                      |
| 615 |    586.872825 |    301.451559 | Jagged Fang Designs                                                                                                                                             |
| 616 |   1009.585804 |    671.148187 | Matt Crook                                                                                                                                                      |
| 617 |    644.260065 |    165.034606 | Pranav Iyer (grey ideas)                                                                                                                                        |
| 618 |    924.060792 |    426.023473 | Gareth Monger                                                                                                                                                   |
| 619 |    820.957316 |    321.299811 | DFoidl (vectorized by T. Michael Keesey)                                                                                                                        |
| 620 |      9.429221 |    367.266876 | Chris A. Hamilton                                                                                                                                               |
| 621 |    284.048355 |    536.238965 | Cesar Julian                                                                                                                                                    |
| 622 |    945.978776 |    262.266323 | Ferran Sayol                                                                                                                                                    |
| 623 |    854.150738 |    658.298139 | Steven Coombs                                                                                                                                                   |
| 624 |     33.390601 |    655.889180 | Erika Schumacher                                                                                                                                                |
| 625 |    253.846031 |    269.795861 | Brockhaus and Efron                                                                                                                                             |
| 626 |    650.091295 |      7.826022 | Markus A. Grohme                                                                                                                                                |
| 627 |    350.187892 |    515.608224 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                   |
| 628 |    823.305346 |    430.321087 | Chuanixn Yu                                                                                                                                                     |
| 629 |    254.027435 |    120.171370 | T. Michael Keesey                                                                                                                                               |
| 630 |    573.918290 |     21.551702 | L. Shyamal                                                                                                                                                      |
| 631 |    789.706734 |    772.350778 | Matt Crook                                                                                                                                                      |
| 632 |    270.530584 |    143.568704 | Matt Wilkins                                                                                                                                                    |
| 633 |    470.084070 |    793.992381 | Margot Michaud                                                                                                                                                  |
| 634 |     81.106089 |    588.881017 | Tracy A. Heath                                                                                                                                                  |
| 635 |     10.380963 |    664.191189 | Steven Traver                                                                                                                                                   |
| 636 |    723.217520 |    353.393375 | C. Camilo Julián-Caballero                                                                                                                                      |
| 637 |    957.817454 |    250.182212 | Zimices                                                                                                                                                         |
| 638 |    387.775148 |    381.457337 | T. Michael Keesey                                                                                                                                               |
| 639 |    997.845475 |    182.899960 | Gareth Monger                                                                                                                                                   |
| 640 |   1017.813928 |    689.110027 | Mattia Menchetti                                                                                                                                                |
| 641 |    327.139629 |    466.691293 | Matt Crook                                                                                                                                                      |
| 642 |    411.722035 |    538.470432 | Xvazquez (vectorized by William Gearty)                                                                                                                         |
| 643 |    196.489011 |    311.216973 | Mike Hanson                                                                                                                                                     |
| 644 |    931.059636 |    467.699414 | Auckland Museum and T. Michael Keesey                                                                                                                           |
| 645 |    842.393394 |    703.763598 | Gabriela Palomo-Munoz                                                                                                                                           |
| 646 |    254.693599 |    294.648953 | NA                                                                                                                                                              |
| 647 |    236.184524 |    642.754289 | Darren Naish, Nemo, and T. Michael Keesey                                                                                                                       |
| 648 |    301.144946 |    507.367291 | Tyler Greenfield and Dean Schnabel                                                                                                                              |
| 649 |    754.806807 |     88.301721 | I. Sáček, Sr. (vectorized by T. Michael Keesey)                                                                                                                 |
| 650 |    772.782920 |    791.532027 | Emily Willoughby                                                                                                                                                |
| 651 |    572.361839 |    618.470924 | Tracy A. Heath                                                                                                                                                  |
| 652 |    249.207811 |    351.364753 | Tambja (vectorized by T. Michael Keesey)                                                                                                                        |
| 653 |    618.197789 |    604.436888 | Renata F. Martins                                                                                                                                               |
| 654 |    833.460718 |    448.855407 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                               |
| 655 |    667.122232 |    495.983226 | Luis Cunha                                                                                                                                                      |
| 656 |    633.850944 |    319.334115 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                   |
| 657 |    345.022975 |    521.404828 | C. Camilo Julián-Caballero                                                                                                                                      |
| 658 |    613.405310 |     52.894127 | Dave Angelini                                                                                                                                                   |
| 659 |    995.862885 |    330.373262 | Margot Michaud                                                                                                                                                  |
| 660 |    843.715046 |    492.944952 | Chris huh                                                                                                                                                       |
| 661 |     43.335371 |    152.971975 | Chase Brownstein                                                                                                                                                |
| 662 |    777.707792 |     28.861608 | Cathy                                                                                                                                                           |
| 663 |    471.404056 |    317.186536 | Margot Michaud                                                                                                                                                  |
| 664 |    529.057998 |    459.235034 | Ferran Sayol                                                                                                                                                    |
| 665 |    855.179660 |    667.402786 | George Edward Lodge (modified by T. Michael Keesey)                                                                                                             |
| 666 |    422.045795 |    117.621036 | Markus A. Grohme                                                                                                                                                |
| 667 |    777.460835 |     64.010520 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                   |
| 668 |    570.052634 |    594.254680 | NA                                                                                                                                                              |
| 669 |    217.450874 |    623.375320 | Tauana J. Cunha                                                                                                                                                 |
| 670 |    774.291692 |    147.711165 | Javier Luque                                                                                                                                                    |
| 671 |    793.944352 |    519.177681 | Ghedo (vectorized by T. Michael Keesey)                                                                                                                         |
| 672 |   1010.621907 |    107.352322 | Aleksey Nagovitsyn (vectorized by T. Michael Keesey)                                                                                                            |
| 673 |    975.822099 |    755.460232 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                |
| 674 |      7.639479 |    506.601431 | Gabriela Palomo-Munoz                                                                                                                                           |
| 675 |    383.702703 |    549.318046 | Hugo Gruson                                                                                                                                                     |
| 676 |    933.549697 |    561.383612 | Campbell Fleming                                                                                                                                                |
| 677 |    626.606496 |      2.865064 | Markus A. Grohme                                                                                                                                                |
| 678 |    325.427956 |     24.400431 | Margot Michaud                                                                                                                                                  |
| 679 |    563.123217 |    466.821815 | Ferran Sayol                                                                                                                                                    |
| 680 |    793.469016 |     85.702490 | Christine Axon                                                                                                                                                  |
| 681 |    250.910280 |    627.728806 | Ferran Sayol                                                                                                                                                    |
| 682 |    474.131203 |    597.607393 | Jagged Fang Designs                                                                                                                                             |
| 683 |     39.313525 |    517.526460 | Alex Slavenko                                                                                                                                                   |
| 684 |    237.342215 |    160.982989 | Katie S. Collins                                                                                                                                                |
| 685 |    852.568123 |    375.539738 | Gareth Monger                                                                                                                                                   |
| 686 |    214.152395 |    605.834101 | Cristina Guijarro                                                                                                                                               |
| 687 |    695.558715 |    610.636745 | Scott Hartman                                                                                                                                                   |
| 688 |    653.818474 |    280.347540 | Andrew A. Farke                                                                                                                                                 |
| 689 |    279.815664 |    269.947226 | NA                                                                                                                                                              |
| 690 |    449.921443 |    362.786950 | Steven Traver                                                                                                                                                   |
| 691 |     29.102227 |    138.932856 | Matt Crook                                                                                                                                                      |
| 692 |     96.448989 |     71.905358 | Andrew A. Farke, modified from original by Robert Bruce Horsfall, from Scott 1912                                                                               |
| 693 |    188.524993 |     91.326889 | T. Michael Keesey                                                                                                                                               |
| 694 |    673.453373 |    666.682324 | CNZdenek                                                                                                                                                        |
| 695 |    745.523109 |     68.117906 | Ray Simpson (vectorized by T. Michael Keesey)                                                                                                                   |
| 696 |    640.526093 |    791.255999 | Nobu Tamura, vectorized by Zimices                                                                                                                              |
| 697 |    535.495112 |    117.256133 | Bryan Carstens                                                                                                                                                  |
| 698 |    313.223160 |    162.284319 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                        |
| 699 |    259.522626 |    669.350277 | Matt Crook                                                                                                                                                      |
| 700 |    345.997356 |    378.540513 | T. Tischler                                                                                                                                                     |
| 701 |    205.319481 |    592.169223 | NA                                                                                                                                                              |
| 702 |    446.382467 |    331.631146 | Timothy Knepp of the U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                          |
| 703 |    774.823674 |    776.779853 | Scott Hartman                                                                                                                                                   |
| 704 |    669.523863 |    312.443742 | Andrew A. Farke                                                                                                                                                 |
| 705 |    857.469475 |    644.937390 | John Gould (vectorized by T. Michael Keesey)                                                                                                                    |
| 706 |    209.006577 |    666.178108 | Andy Wilson                                                                                                                                                     |
| 707 |    519.126355 |    793.585340 | Markus A. Grohme                                                                                                                                                |
| 708 |    498.818317 |    241.584344 | Chris huh                                                                                                                                                       |
| 709 |    156.178283 |    497.715326 | NA                                                                                                                                                              |
| 710 |    649.914588 |    419.438703 | T. Michael Keesey                                                                                                                                               |
| 711 |     83.895574 |    231.042861 | Erika Schumacher                                                                                                                                                |
| 712 |    836.749134 |    115.306051 | Myriam\_Ramirez                                                                                                                                                 |
| 713 |    787.968204 |    423.757609 | Birgit Lang                                                                                                                                                     |
| 714 |     31.386254 |    339.229545 | Scott Hartman                                                                                                                                                   |
| 715 |    104.591233 |    777.297717 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                   |
| 716 |    570.455095 |    243.038360 | Margot Michaud                                                                                                                                                  |
| 717 |    239.057599 |    402.303023 | Chris huh                                                                                                                                                       |
| 718 |    830.056438 |    342.713692 | Jagged Fang Designs                                                                                                                                             |
| 719 |    456.398460 |    733.939025 | Margot Michaud                                                                                                                                                  |
| 720 |    236.293911 |    115.562790 | Margot Michaud                                                                                                                                                  |
| 721 |    469.076560 |    737.678573 | Falconaumanni and T. Michael Keesey                                                                                                                             |
| 722 |     17.123028 |    180.819444 | Michael Scroggie                                                                                                                                                |
| 723 |    268.686595 |    128.625417 | Kamil S. Jaron                                                                                                                                                  |
| 724 |    676.995852 |    357.864570 | Tracy A. Heath                                                                                                                                                  |
| 725 |    332.489896 |    244.825239 | Ghedo (vectorized by T. Michael Keesey)                                                                                                                         |
| 726 |    200.942800 |    278.040047 | Matt Crook                                                                                                                                                      |
| 727 |    967.429386 |    729.471526 | Mattia Menchetti                                                                                                                                                |
| 728 |    391.891839 |    774.028445 | Chris huh                                                                                                                                                       |
| 729 |    195.534628 |    481.490627 | Julien Louys                                                                                                                                                    |
| 730 |     13.689366 |    717.929173 | Gabriela Palomo-Munoz                                                                                                                                           |
| 731 |    422.470899 |    426.512076 | B Kimmel                                                                                                                                                        |
| 732 |    819.862176 |    784.311286 | Ingo Braasch                                                                                                                                                    |
| 733 |    508.241181 |     95.899475 | Rene Martin                                                                                                                                                     |
| 734 |    247.251160 |    154.302717 | NA                                                                                                                                                              |
| 735 |    186.483639 |    575.724642 | Gareth Monger                                                                                                                                                   |
| 736 |    642.715370 |    101.478148 | Maija Karala                                                                                                                                                    |
| 737 |    445.699868 |    567.336242 | C. Camilo Julián-Caballero                                                                                                                                      |
| 738 |   1011.565546 |    439.202096 | Margot Michaud                                                                                                                                                  |
| 739 |    596.390834 |    344.937011 | Felix Vaux                                                                                                                                                      |
| 740 |    580.089432 |    634.781124 | Margot Michaud                                                                                                                                                  |
| 741 |    564.521290 |    351.734005 | Alex Slavenko                                                                                                                                                   |
| 742 |    434.114185 |    436.212556 | Steve Hillebrand/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                              |
| 743 |    911.069286 |    576.214631 | NA                                                                                                                                                              |
| 744 |    955.800050 |     14.039436 | Matt Crook                                                                                                                                                      |
| 745 |    738.705131 |    241.394660 | FunkMonk (Michael B.H.; vectorized by T. Michael Keesey)                                                                                                        |
| 746 |    830.079662 |     37.078874 | Scott Hartman                                                                                                                                                   |
| 747 |    971.454491 |    664.573053 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                   |
| 748 |    584.830124 |    416.758876 | H. F. O. March (vectorized by T. Michael Keesey)                                                                                                                |
| 749 |    396.959505 |    461.018985 | Nobu Tamura                                                                                                                                                     |
| 750 |    791.204713 |    278.930936 | Melissa Broussard                                                                                                                                               |
| 751 |    216.119558 |    497.151016 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                  |
| 752 |    498.615443 |    751.879539 | Markus A. Grohme                                                                                                                                                |
| 753 |    802.383841 |    538.553659 | Steven Coombs                                                                                                                                                   |
| 754 |    803.244203 |    337.497163 | Sarah Werning                                                                                                                                                   |
| 755 |    942.826165 |     53.175198 | Matt Crook                                                                                                                                                      |
| 756 |    794.603582 |    465.587415 | Markus A. Grohme                                                                                                                                                |
| 757 |    794.056460 |    299.981784 | Markus A. Grohme                                                                                                                                                |
| 758 |    766.310218 |    239.646384 | Ignacio Contreras                                                                                                                                               |
| 759 |    723.872033 |    100.812167 | Robert Bruce Horsfall, from W.B. Scott’s 1912 “A History of Land Mammals in the Western Hemisphere”                                                             |
| 760 |    426.314999 |    686.570096 | Harold N Eyster                                                                                                                                                 |
| 761 |    860.274986 |    728.175620 | NA                                                                                                                                                              |
| 762 |    173.920571 |     59.282689 | Margot Michaud                                                                                                                                                  |
| 763 |    856.239968 |    157.445418 | Jan Sevcik (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey      |
| 764 |    214.333781 |    457.035556 | Conty (vectorized by T. Michael Keesey)                                                                                                                         |
| 765 |    827.036392 |    774.101313 | Ignacio Contreras                                                                                                                                               |
| 766 |     34.587612 |    736.580922 | Matt Crook                                                                                                                                                      |
| 767 |    497.331108 |    612.716221 | Ian Burt (original) and T. Michael Keesey (vectorization)                                                                                                       |
| 768 |    523.987669 |    466.925787 | NA                                                                                                                                                              |
| 769 |    496.533156 |    747.660586 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                               |
| 770 |    168.626762 |    173.310554 | Steven Coombs                                                                                                                                                   |
| 771 |    622.770321 |    507.211060 | Kai R. Caspar                                                                                                                                                   |
| 772 |     47.628123 |     40.459929 | Tony Ayling (vectorized by Milton Tan)                                                                                                                          |
| 773 |    282.848100 |    156.908475 | Jack Mayer Wood                                                                                                                                                 |
| 774 |    238.639190 |    358.260970 | Jagged Fang Designs                                                                                                                                             |
| 775 |    170.766438 |    456.135010 | Andrew A. Farke                                                                                                                                                 |
| 776 |    252.155572 |    365.977904 | Kent Elson Sorgon                                                                                                                                               |
| 777 |    552.565506 |    665.006741 | Lisa M. “Pixxl” (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
| 778 |    617.140671 |     11.157291 | Zimices                                                                                                                                                         |
| 779 |    211.896694 |    716.583212 | David Orr                                                                                                                                                       |
| 780 |    416.923310 |    272.367526 | Mattia Menchetti                                                                                                                                                |
| 781 |    307.575179 |    495.655686 | Scott Hartman                                                                                                                                                   |
| 782 |    609.401584 |     44.536065 | T. Michael Keesey (after A. Y. Ivantsov)                                                                                                                        |
| 783 |    448.009724 |    450.482528 | Scott Hartman                                                                                                                                                   |
| 784 |    108.362660 |    102.176244 | Mathieu Pélissié                                                                                                                                                |
| 785 |    672.761582 |    397.999710 | T. Michael Keesey (vectorization) and Nadiatalent (photography)                                                                                                 |
| 786 |    633.670288 |    605.393362 | Ferran Sayol                                                                                                                                                    |
| 787 |    199.730441 |    106.134176 | Gareth Monger                                                                                                                                                   |
| 788 |    243.550552 |    557.049557 | Margot Michaud                                                                                                                                                  |
| 789 |    497.558750 |    737.900575 | Margot Michaud                                                                                                                                                  |
| 790 |    956.091351 |    189.449605 | Matt Crook                                                                                                                                                      |
| 791 |    185.367456 |    696.326043 | Ferran Sayol                                                                                                                                                    |
| 792 |    507.759498 |     69.591595 | Birgit Lang                                                                                                                                                     |
| 793 |    493.838010 |    421.648049 | Matt Crook                                                                                                                                                      |
| 794 |    704.776478 |    360.589246 | Zimices                                                                                                                                                         |
| 795 |    995.030741 |    643.983838 | Dean Schnabel                                                                                                                                                   |
| 796 |     74.747343 |    659.107854 | Ignacio Contreras                                                                                                                                               |
| 797 |     10.652481 |    610.793092 | Kristina Gagalova                                                                                                                                               |
| 798 |    824.335649 |    584.042688 | T. Michael Keesey                                                                                                                                               |
| 799 |   1011.339272 |    186.991849 | Terpsichores                                                                                                                                                    |
| 800 |    551.265253 |    730.429163 | Andy Wilson                                                                                                                                                     |
| 801 |    175.882548 |    105.190370 | Kamil S. Jaron                                                                                                                                                  |
| 802 |    150.126856 |    186.323820 | Zimices                                                                                                                                                         |
| 803 |    111.705157 |    498.934027 | Campbell Fleming                                                                                                                                                |
| 804 |    474.170678 |     47.678495 | H. F. O. March (vectorized by T. Michael Keesey)                                                                                                                |
| 805 |    692.781104 |    644.096149 | Markus A. Grohme                                                                                                                                                |
| 806 |    681.127712 |    124.386363 | Matt Crook                                                                                                                                                      |
| 807 |    545.630519 |    755.800993 | Darius Nau                                                                                                                                                      |
| 808 |     19.680191 |     76.994017 | NA                                                                                                                                                              |
| 809 |    172.381574 |    506.190043 | Stephen O’Connor (vectorized by T. Michael Keesey)                                                                                                              |
| 810 |    617.098596 |    619.312890 | NA                                                                                                                                                              |
| 811 |    588.684005 |    237.619433 | David Tana                                                                                                                                                      |
| 812 |     47.825127 |    578.780912 | NA                                                                                                                                                              |
| 813 |    668.255381 |    216.774671 | Collin Gross                                                                                                                                                    |
| 814 |    169.015450 |    723.555590 | Jimmy Bernot                                                                                                                                                    |
| 815 |     82.069332 |     36.480373 | Mariana Ruiz Villarreal                                                                                                                                         |
| 816 |    587.588152 |     62.959288 | Matt Crook                                                                                                                                                      |
| 817 |    433.181421 |    670.659129 | Milton Tan                                                                                                                                                      |
| 818 |    199.716062 |    243.208690 | Terpsichores                                                                                                                                                    |
| 819 |    748.367322 |    253.585763 | Margot Michaud                                                                                                                                                  |
| 820 |    504.894698 |    601.822413 | Gareth Monger                                                                                                                                                   |
| 821 |    229.147079 |    196.619550 | Michelle Site                                                                                                                                                   |
| 822 |    239.591704 |    470.108305 | Chris huh                                                                                                                                                       |
| 823 |    607.485185 |    302.527654 | Rebecca Groom                                                                                                                                                   |
| 824 |    657.163413 |    483.243126 | Michelle Site                                                                                                                                                   |
| 825 |   1004.483560 |     77.123851 | Felix Vaux                                                                                                                                                      |
| 826 |    727.968525 |    781.867670 | Benjamin Monod-Broca                                                                                                                                            |
| 827 |    138.025619 |    744.658850 | Maxime Dahirel                                                                                                                                                  |
| 828 |    419.235741 |    300.143065 | Lukasiniho                                                                                                                                                      |
| 829 |    790.810285 |     98.117627 | Margot Michaud                                                                                                                                                  |
| 830 |    407.425124 |    549.748935 | Jake Warner                                                                                                                                                     |
| 831 |    333.339924 |    699.954979 | Roger Witter, vectorized by Zimices                                                                                                                             |
| 832 |    163.934310 |    250.767707 | Margot Michaud                                                                                                                                                  |
| 833 |    606.028211 |    468.338221 | Jagged Fang Designs                                                                                                                                             |
| 834 |    956.247384 |    467.305307 | Martin R. Smith, from photo by Jürgen Schoner                                                                                                                   |
| 835 |    210.738489 |    451.420325 | Zimices                                                                                                                                                         |
| 836 |    693.733010 |    530.435409 | Pranav Iyer (grey ideas)                                                                                                                                        |
| 837 |    205.500436 |    338.474391 | Zimices                                                                                                                                                         |
| 838 |    263.292254 |    658.130225 | Becky Barnes                                                                                                                                                    |
| 839 |    131.512330 |    414.398382 | Nobu Tamura, vectorized by Zimices                                                                                                                              |
| 840 |     23.638370 |    564.299717 | Gareth Monger                                                                                                                                                   |
| 841 |    163.505900 |    748.049877 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                  |
| 842 |    951.101915 |     39.115917 | Gabriela Palomo-Munoz                                                                                                                                           |
| 843 |    144.033195 |    758.319128 | Rafael Maia                                                                                                                                                     |
| 844 |    910.848774 |    633.369621 | Beth Reinke                                                                                                                                                     |
| 845 |    192.586681 |    690.570449 | Andy Wilson                                                                                                                                                     |
| 846 |    565.112625 |    303.571705 | Mihai Dragos (vectorized by T. Michael Keesey)                                                                                                                  |
| 847 |    588.992409 |    609.317595 | Matt Martyniuk                                                                                                                                                  |
| 848 |    521.106384 |    113.905250 | Chris huh                                                                                                                                                       |
| 849 |    703.944396 |     78.371819 | Zimices                                                                                                                                                         |
| 850 |    423.800804 |    526.977972 | Matus Valach                                                                                                                                                    |
| 851 |    670.458696 |    205.472319 | Katie S. Collins                                                                                                                                                |
| 852 |    383.422372 |     26.218395 | Zimices                                                                                                                                                         |
| 853 |    183.155717 |    614.951654 | Markus A. Grohme                                                                                                                                                |
| 854 |    683.474782 |    427.031753 | T. Michael Keesey                                                                                                                                               |
| 855 |     30.206051 |    113.570466 | Lisa M. “Pixxl” (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
| 856 |    455.656412 |     53.843779 | Davidson Sodré                                                                                                                                                  |
| 857 |    883.762888 |    327.462411 | Emily Willoughby                                                                                                                                                |
| 858 |    745.681714 |    289.185249 | Maija Karala                                                                                                                                                    |
| 859 |    330.508370 |    755.915911 | S.Martini                                                                                                                                                       |
| 860 |    269.557852 |    447.532462 | T. Michael Keesey                                                                                                                                               |
| 861 |    268.240405 |    283.556682 | Milton Tan                                                                                                                                                      |
| 862 |     55.821752 |    674.244088 | FunkMonk                                                                                                                                                        |
| 863 |    975.009224 |    504.007338 | Emily Willoughby                                                                                                                                                |
| 864 |    835.349834 |    739.667651 | Original drawing by Nobu Tamura, vectorized by Roberto Díaz Sibaja                                                                                              |
| 865 |    481.936584 |    508.755206 | NA                                                                                                                                                              |
| 866 |    942.143748 |    229.407901 | Sarah Werning                                                                                                                                                   |
| 867 |    292.056100 |    226.585017 | NA                                                                                                                                                              |
| 868 |     44.515255 |    232.951965 | Scott Hartman                                                                                                                                                   |
| 869 |     17.577175 |    389.605277 | Kimberly Haddrell                                                                                                                                               |
| 870 |    707.202594 |    344.262296 | Noah Schlottman, photo by Casey Dunn                                                                                                                            |
| 871 |    226.796109 |    765.825306 | Caleb M. Brown                                                                                                                                                  |
| 872 |    201.047374 |     90.251287 | Matt Crook                                                                                                                                                      |
| 873 |    643.569339 |    620.705711 | T. Michael Keesey                                                                                                                                               |
| 874 |    471.139879 |    490.592109 | Zimices                                                                                                                                                         |
| 875 |    675.997409 |    487.874706 | Kai R. Caspar                                                                                                                                                   |
| 876 |    366.188816 |    694.231693 | Jaime Headden                                                                                                                                                   |
| 877 |    127.067685 |    781.193010 | NA                                                                                                                                                              |
| 878 |    863.364026 |    214.545934 | NA                                                                                                                                                              |
| 879 |    990.324333 |     78.545058 | Matt Crook                                                                                                                                                      |
| 880 |    119.345164 |    200.529079 | Chris huh                                                                                                                                                       |
| 881 |     41.179333 |    774.438306 | Gabriela Palomo-Munoz                                                                                                                                           |
| 882 |    167.621058 |    564.839067 | Tasman Dixon                                                                                                                                                    |
| 883 |    514.761847 |     16.605679 | Neil Kelley                                                                                                                                                     |
| 884 |    739.790735 |    439.104849 | Maija Karala                                                                                                                                                    |
| 885 |     85.997157 |    797.404037 | Markus A. Grohme                                                                                                                                                |
| 886 |    922.077010 |     77.141885 | Matt Crook                                                                                                                                                      |
| 887 |    288.609235 |      5.828754 | Gabriela Palomo-Munoz                                                                                                                                           |
| 888 |    108.098193 |    792.081531 | Tyler Greenfield and Dean Schnabel                                                                                                                              |
| 889 |    933.969806 |    602.754061 | Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus                                        |
| 890 |    956.362663 |    656.051193 | Stanton F. Fink, vectorized by Zimices                                                                                                                          |
| 891 |    853.669324 |    252.996017 | Alexander Schmidt-Lebuhn                                                                                                                                        |
| 892 |    339.595273 |    637.983311 | Gabriela Palomo-Munoz                                                                                                                                           |
| 893 |    956.806598 |    545.635522 | Zimices                                                                                                                                                         |
| 894 |    543.582229 |     91.916169 | L. Shyamal                                                                                                                                                      |
| 895 |    976.844409 |     82.649183 | Andy Wilson                                                                                                                                                     |
| 896 |    544.996567 |    394.163690 | Gabriela Palomo-Munoz                                                                                                                                           |
| 897 |    869.695014 |    648.071536 | J. J. Harrison (photo) & T. Michael Keesey                                                                                                                      |
| 898 |    494.489777 |     58.353848 | Zimices                                                                                                                                                         |
| 899 |    914.962687 |    789.203244 | Zimices                                                                                                                                                         |
| 900 |    890.249624 |    744.461713 | Heinrich Harder (vectorized by William Gearty)                                                                                                                  |
| 901 |    316.621315 |    516.566653 | Markus A. Grohme                                                                                                                                                |
| 902 |    813.849131 |    178.220051 | Renato Santos                                                                                                                                                   |
| 903 |   1013.780095 |    383.743601 | Ferran Sayol                                                                                                                                                    |
| 904 |    165.175779 |    178.779908 | Inessa Voet                                                                                                                                                     |
| 905 |    578.624277 |    344.576212 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                  |
| 906 |    847.004303 |    779.173843 | Tasman Dixon                                                                                                                                                    |
| 907 |    538.093105 |    744.630186 | Steven Traver                                                                                                                                                   |
| 908 |     59.277234 |    390.836506 | Mo Hassan                                                                                                                                                       |
| 909 |   1014.539160 |     15.087859 | Margot Michaud                                                                                                                                                  |
| 910 |    437.410545 |    355.031356 | Ferran Sayol                                                                                                                                                    |
| 911 |    588.745582 |    758.484384 | Gabriel Lio, vectorized by Zimices                                                                                                                              |
| 912 |    615.138469 |    786.379078 | Margot Michaud                                                                                                                                                  |
| 913 |    495.324851 |    622.723602 | Mathew Wedel                                                                                                                                                    |
| 914 |    597.672742 |    691.627251 | Ferran Sayol                                                                                                                                                    |
| 915 |    976.669576 |    750.244772 | Scott Hartman                                                                                                                                                   |
| 916 |   1015.690021 |    162.632219 | Evan Swigart (photography) and T. Michael Keesey (vectorization)                                                                                                |
| 917 |    371.090106 |    254.697325 | Liftarn                                                                                                                                                         |
| 918 |    266.126838 |    744.966149 | Zimices                                                                                                                                                         |
| 919 |    365.463195 |     97.227438 | Ingo Braasch                                                                                                                                                    |
| 920 |     16.187293 |    395.459221 | Zimices                                                                                                                                                         |
| 921 |    152.408168 |    432.360260 | Nicolas Huet le Jeune and Jean-Gabriel Prêtre (vectorized by T. Michael Keesey)                                                                                 |
| 922 |    469.829204 |     35.643750 | Gareth Monger                                                                                                                                                   |
| 923 |    313.081326 |    658.394311 | Ingo Braasch                                                                                                                                                    |

    #> Your tweet has been posted!
